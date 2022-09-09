import org.lwjgl.*;
import org.lwjgl.glfw.*;
import org.lwjgl.opengl.*;
import org.lwjgl.system.*;
import org.lwjgl.openal.*;

import java.nio.*;
import java.util.*;

import static org.lwjgl.glfw.Callbacks.*;
import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL11.*;
import static org.lwjgl.system.MemoryStack.*;
import static org.lwjgl.system.MemoryUtil.*;
import static org.lwjgl.stb.STBImage.stbi_load;
import static org.lwjgl.openal.AL10.*;
import static org.lwjgl.openal.ALC11.*;


public class Snake {
    public static final int WINDOW_WIDTH = 1200, WINDOW_HEIGHT = 800;
    public static final int SPRITE_IMG_WIDTH = 16, SPRITE_IMG_HEIGHT = 16;
    public static final int SPRITE_SCALE = 5;
    public static final int SPRITE_WIDTH = SPRITE_SCALE * SPRITE_IMG_WIDTH;
    public static final int SPRITE_HEIGHT = SPRITE_SCALE * SPRITE_IMG_HEIGHT;
    public static final int ROWS = WINDOW_HEIGHT / SPRITE_HEIGHT;
    public static final int COLUMNS = WINDOW_WIDTH / SPRITE_HEIGHT;

    public static final String[][] IMG_NAMES = {
        {"head_up", "head_right", "head_down", "head_left"}, 
        {"tail_up", "tail_right", "tail_down", "tail_left"},
        {"turn_1", "turn_2", "turn_3", "turn_4"},
        {"vertical", "horizontal", "rabbit", "grass"}
    };

    public static final Map<String, int[]> IMG_RC;
    static {
        
        IMG_RC = new HashMap<>();
        int i = 0;
        for(String[] names_row : IMG_NAMES) {
            int j = 0;
            for(String name : names_row) {
                int[] rc = {i, j};
                IMG_RC.put(name, rc);
                j++;
            }
            i++;
        }
    }

    public static final String DIR_RIGHT = "right", DIR_LEFT = "left", DIR_UP = "up",  DIR_DOWN = "down";

    static class Sprite {  // nested class to avoid multiple files
        public float x, y;
        public float u1, v1, u2, v2;
        Sprite(int row, int column, String img_name)
        {
            move(row, column);
            set_image(img_name);
        }
        void set_image(String img_name)
        {
            int[] row_col = IMG_RC.get(img_name);
            int i = row_col[0], j = row_col[1];
            u1 = 0.25f * j;
            v1 = 0.25f * (i+1);
            u2 = 0.25f * (j+1);
            v2 = 0.25f * i;
        }
        void move(int row, int column)
        {
            x = column * SPRITE_WIDTH;
            y = row * SPRITE_HEIGHT;
        }
        void draw()
        {
            //std::cout << "Draw sprite:" << x << ", " <<  y << ", " << u1 << ", " << v1 << ", " << u2 << ", " << v2 << "\n";
            glColor3f(1, 1, 1);
    
            glBegin(GL_QUADS);
            glTexCoord2f(u1, v1);
            glVertex2f(x, y);
    
            glTexCoord2f(u2, v1);
            glVertex2f(x+SPRITE_WIDTH, y);
    
            glTexCoord2f(u2, v2);
            glVertex2f(x+SPRITE_WIDTH, y+SPRITE_HEIGHT);
    
            glTexCoord2f(u1, v2);
            glVertex2f(x, y+SPRITE_HEIGHT);
            glEnd();
        }
    }

    static class SnakePart {  // nested class to avoid multiple files
        public int row, col;
        public String dir;
        public Sprite sprite;
        SnakePart(int row, int col, String dir, String img_name) 
        {
            this.row = row;
            this.col = col;
            this.dir = dir;
            sprite = new Sprite(row, col, img_name);
        }
    }

    static class Rabbit {  // nested class to avoid multiple files
        public int row, col;
        public Sprite sprite;
        Rabbit(int row, int col) 
        {
            this.row = row;
            this.col = col;
            sprite = new Sprite(row, col, "rabbit");
        }
        void move(int row, int col)
        {
            this.row = row;
            this.col = col;
            sprite.move(row, col);
        }
    }

    private long window;  // window handle
    // graphics
    private int textureId;
    private Sprite[] background;
    // game logic + sprites
    private ArrayList<SnakePart> snake;
    private Rabbit rabbit;
    private String snake_dir_next;
    private float snake_move_t, snake_move_t_rem;

    private Random rnd_generator;

    private static final HashSet<Map.Entry<Integer, Integer>> set_all_squares;
    static {
        set_all_squares = new HashSet<Map.Entry<Integer, Integer>>();

        for(int i=0; i<ROWS; i++) {
            for(int j=0; j<COLUMNS; j++) {
                set_all_squares.add(Map.entry(i, j));
            }
        }
    }
    

    public void run() {
        System.out.println("LWJGL version:" + Version.getVersion());

        init();
        loop();

        // Free the window callbacks and destroy the window
        glfwFreeCallbacks(window);
        glfwDestroyWindow(window);

        // Terminate GLFW and free the error callback
        glfwTerminate();
        glfwSetErrorCallback(null).free();
    }

    private void key_pressed(long target_window, int key, int scancode, int action, int mods)
    {  // target_window should be this.window
        if(action == GLFW_PRESS) {
            String key_name = glfwGetKeyName(key, scancode);
            if(key_name == null) {
                key_name = "(a non printable key with code " + key + ")";
            }
            System.out.println("Key pressed: " + key_name);
            switch(key) {
                case GLFW_KEY_LEFT:
                    if(snake.get(0).dir != DIR_RIGHT) {
                        snake_dir_next = DIR_LEFT;
                    }
                break;
                case GLFW_KEY_RIGHT:
                    if(snake.get(0).dir != DIR_LEFT) {
                        snake_dir_next = DIR_RIGHT;
                    }
                break;
                case GLFW_KEY_UP:
                    if(snake.get(0).dir != DIR_DOWN) {
                        snake_dir_next = DIR_UP;
                    }
                break;
                case GLFW_KEY_DOWN:
                    if(snake.get(0).dir != DIR_UP) {
                        snake_dir_next = DIR_DOWN;
                    }
                break;
                case GLFW_KEY_ESCAPE:
                    glfwSetWindowShouldClose(window, true);
                break;
            }
        }
    }

    private void init() {
        System.out.println("IMG_RC:");
        for(Map.Entry<String, int[]> rc : IMG_RC.entrySet()) {
            System.out.println(
                "   " + rc.getKey() + 
                ": " + rc.getValue()[0] + ", " + rc.getValue()[1]);
        }

        rnd_generator = new Random();

        // Setup an error callback. The default implementation
        // will print the error message in System.err.
        GLFWErrorCallback.createPrint(System.err).set();

        // Initialize GLFW. Most GLFW functions will not work before doing this.
        if ( !glfwInit() )
            throw new IllegalStateException("Unable to initialize GLFW");

        // Configure GLFW
        glfwDefaultWindowHints(); // optional, the current window hints are already the default
        glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE); // the window will stay hidden after creation
        glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE); // the window will be resizable

        // Create the window
        window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Snake game (Java with LWJGL)", NULL, NULL);
        if ( window == NULL )
            throw new RuntimeException("Failed to create the GLFW window");

        // Setup a key callback. It will be called every time a key is pressed, repeated or released.
		glfwSetKeyCallback(window, (window, key, scancode, action, mods) -> { key_pressed(window, key, scancode, action, mods); });

        // Get the thread stack and push a new frame
        try ( MemoryStack stack = stackPush() ) {
            IntBuffer pWidth = stack.mallocInt(1); // int*
            IntBuffer pHeight = stack.mallocInt(1); // int*

            // Get the window size passed to glfwCreateWindow
            glfwGetWindowSize(window, pWidth, pHeight);

            // Get the resolution of the primary monitor
            GLFWVidMode vidmode = glfwGetVideoMode(glfwGetPrimaryMonitor());

            // Center the window
            glfwSetWindowPos(
                window,
                (vidmode.width() - pWidth.get(0)) / 2,
                (vidmode.height() - pHeight.get(0)) / 2
            );
        } // the stack frame is popped automatically

        // Make the OpenGL context current
        glfwMakeContextCurrent(window);
        // Enable v-sync
        glfwSwapInterval(1);

        // Make the window visible
        glfwShowWindow(window);

        GL.createCapabilities();

        load_texture();

        glShadeModel(GL_SMOOTH);
        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);
        glEnable(GL_CULL_FACE);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT, 1, -1);
        glMatrixMode(GL_MODELVIEW);

        ArrayList<Sprite> sprites = new ArrayList<>();
        for(int i=0; i<ROWS; i++) {
            for(int j=0; j<COLUMNS; j++) {
                sprites.add(new Sprite(i, j, "grass"));
            }
        }
        background = new Sprite[sprites.size()];
        sprites.toArray(background);

        snake = new ArrayList<SnakePart>();
        reset_snake();

        rabbit = new Rabbit(0, 0);
        place_rabbit();
    }

    void reset_snake()
    {
        snake.clear();
        List<String> names = List.of("head_right", "horizontal", "tail_right");
        ListIterator<String> it = names.listIterator();
        int row = ROWS / 3, col = COLUMNS / 3;
        while(it.hasNext()) {
            snake.add(new SnakePart(row, col-it.nextIndex(), DIR_RIGHT, it.next()));
        }
        snake_dir_next = DIR_RIGHT;
        snake_move_t = 0.2f;
    }

    void place_rabbit()
    {
        HashSet<Map.Entry<Integer, Integer>> free_squares = (HashSet)set_all_squares.clone();
        snake.forEach((sp) -> free_squares.remove(Map.entry(sp.row, sp.col)));
        
        if(free_squares.size() == 0) {
            System.out.println("victory !!!");
            reset_snake();
            place_rabbit();
        } else {
            ArrayList<int[]> free_squares_array = new ArrayList<int[]>();
            free_squares.forEach((fs) -> free_squares_array.add(new int[]{fs.getKey(), fs.getValue()}));
            int i = rnd_generator.nextInt(free_squares.size());
            int[] rc = free_squares_array.get(i);
            rabbit.move(rc[0], rc[1]);
        }
    }

    void update(float dt)
    {
        snake_move_t_rem -= dt;
        if(snake_move_t_rem <= 0) {
            snake_move_t_rem += snake_move_t;
            int row = snake.get(0).row;
            int col = snake.get(0).col;
            String head_dir = snake_dir_next;
            if(head_dir == DIR_LEFT) {
                col--;
            } else if(head_dir == DIR_RIGHT) {
                col++;
            } else if(head_dir == DIR_UP) {
                row++;
            } else if(head_dir == DIR_DOWN) {
                row--;
            }
            row %= ROWS;
            col %= COLUMNS;
            if(row < 0) {
                row = ROWS - 1;
            }
            if(col < 0) {
                col = COLUMNS - 1;
            }
            
            { // insert new head to front
                SnakePart sp = new SnakePart(row, col, head_dir, "head_"+head_dir);
                snake.add(0, sp);
            }

            String old_dir = snake.get(1).dir;
            if(head_dir == old_dir) {
                if(head_dir == DIR_LEFT || head_dir == DIR_RIGHT) {
                    snake.get(1).sprite.set_image("horizontal");
                } else {
                    snake.get(1).sprite.set_image("vertical");
                }
            } else if(old_dir == DIR_DOWN) {
                if(head_dir == DIR_LEFT) {
                    snake.get(1).sprite.set_image("turn_4");
                } else {
                    snake.get(1).sprite.set_image("turn_1");
                }
            } else if(old_dir == DIR_UP) {
                if(head_dir == DIR_LEFT) {
                    snake.get(1).sprite.set_image("turn_3");
                } else {
                    snake.get(1).sprite.set_image("turn_2");
                }
            } else if(old_dir == DIR_LEFT) {
                if(head_dir == DIR_UP) {
                    snake.get(1).sprite.set_image("turn_1");
                } else {
                    snake.get(1).sprite.set_image("turn_2");
                }
            } else if(old_dir == DIR_RIGHT) {
                if(head_dir == DIR_UP) {
                    snake.get(1).sprite.set_image("turn_4");
                } else {
                    snake.get(1).sprite.set_image("turn_3");
                }
            }

            Boolean rabbit_eaten = rabbit.row == row && rabbit.col == col;

            if(!rabbit_eaten) {
                snake.remove(snake.size()-1);
                String dir = (snake.get(snake.size()-2)).dir;
                snake.get(snake.size()-1).sprite.set_image("tail_"+dir);
            } else {
                //audio_system.play_eat();
                place_rabbit();
            }            

            // test self collision
            Iterator<SnakePart> spIt = snake.listIterator(1);
            while(spIt.hasNext()) {
                SnakePart sp = spIt.next();
                if(sp.col == col && sp.row == row) {
                    //audio_system.play_die();
                    reset_snake();
                    place_rabbit();
                    break;
                }
            }
        }
    }
    
    private void loop() {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

        glfwSetTime(0.0);
        while ( !glfwWindowShouldClose(window) ) {
            float dt = (float)glfwGetTime();
            glfwSetTime(0.0); // reset the timer every frame

            update(dt);

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // clear the framebuffer

            glEnable(GL_TEXTURE_2D);

            for(Sprite sprite : background) {
                sprite.draw();
            }

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
            for(SnakePart part : snake) {
                part.sprite.draw();
            }
            
            rabbit.sprite.draw();

            glDisable(GL_BLEND);

            glfwSwapBuffers(window); // swap the color buffers

            // Poll for window events. The key callback above will only be
            // invoked during this call.
            glfwPollEvents();
        }
    }

    private void load_texture()
    {
        textureId = glGenTextures();
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        IntBuffer width = BufferUtils.createIntBuffer(1);
        IntBuffer height = BufferUtils.createIntBuffer(1);
        IntBuffer channels = BufferUtils.createIntBuffer(1);
        ByteBuffer image = stbi_load("../common_data/Snake.png", width, height, channels, 0);
        if (image == null) {
            throw new RuntimeException("stbi_load failed");
        }
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width.get(0), height.get(0), 0, GL_RGBA, GL_UNSIGNED_BYTE, image);
    }

    public static void main(String[] args) {
        long device = alcOpenDevice(args.length == 0 ? null : args[0]);
        if (device == NULL) {
            throw new IllegalStateException("Failed to open an OpenAL device.");
        }
                
        new Snake().run();
    }

}
