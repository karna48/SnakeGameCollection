import org.lwjgl.*;
import org.lwjgl.glfw.*;
import org.lwjgl.opengl.*;
import org.lwjgl.system.*;

import java.nio.*;
import java.util.*;

import static org.lwjgl.glfw.Callbacks.*;
import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL11.*;
import static org.lwjgl.system.MemoryStack.*;
import static org.lwjgl.system.MemoryUtil.*;

public class Snake {
    final int WINDOW_WIDTH = 1200;
    final int WINDOW_HEIGHT = 800;
    
    final String[][] IMG_NAMES = {
        {"head_up", "head_right", "head_down", "head_left"}, 
        {"tail_up", "tail_right", "tail_down", "tail_left"},
        {"turn_1", "turn_2", "turn_3", "turn_4"},
        {"vertical", "horizontal", "rabbit", "grass"}
    };

    private long window;  // window handle

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
            System.out.println("Key pressed: " + key);
            switch(key) {
                case GLFW_KEY_LEFT:

                break;
                case GLFW_KEY_ESCAPE:
                    glfwSetWindowShouldClose(window, true);
                break;
            }
        }
    }

    private void init() {
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

        glShadeModel(GL_SMOOTH);
        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);
        glEnable(GL_CULL_FACE);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT, 1, -1);
        glMatrixMode(GL_MODELVIEW);
    }

    private void loop() {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

        while ( !glfwWindowShouldClose(window) ) {
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // clear the framebuffer

            int x = 35, y=60, SPRITE_WIDTH=300, SPRITE_HEIGHT= 300; 
            glBegin(GL_QUADS);
            glColor3f(1, 0, 0);
            glVertex2f(x, y);
            glColor3f(0, 1, 0);
            glVertex2f(x+SPRITE_WIDTH, y);
            glColor3f(0, 0, 1);
            glVertex2f(x+SPRITE_WIDTH, y+SPRITE_HEIGHT);
            glColor3f(1, 1, 1);
            glVertex2f(x, y+SPRITE_HEIGHT);
            glEnd();

            glfwSwapBuffers(window); // swap the color buffers

            // Poll for window events. The key callback above will only be
            // invoked during this call.
            glfwPollEvents();
        }
    }

    public static void main(String[] args) {
        new Snake().run();
    }

}
