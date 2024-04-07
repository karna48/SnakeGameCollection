using System;
using System.Data;
using System.Xml;
using OpenTK.Graphics.OpenGL4;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;
using StbImageSharp;



public class Constants
{
    public const int WINDOW_WIDTH = 1200, WINDOW_HEIGHT = 800, SPRITE_IMG_WIDTH = 16, SPRITE_IMG_HEIGHT = 16;
    public const int SPRITE_SCALE = 5;
    public const int SPRITE_WIDTH = SPRITE_SCALE * SPRITE_IMG_WIDTH, SPRITE_HEIGHT = SPRITE_SCALE * SPRITE_IMG_HEIGHT;
    public const int ROWS = WINDOW_HEIGHT / SPRITE_HEIGHT, COLUMNS = WINDOW_WIDTH / SPRITE_HEIGHT;    
    public static string[,] IMG_NAMES = {
        {"head_up", "head_right", "head_down", "head_left"}, 
        {"tail_up", "tail_right", "tail_down", "tail_left"},
        {"turn_1", "turn_2", "turn_3", "turn_4"},
        {"vertical", "horizontal", "rabbit", "grass"}
    };
    public static Dictionary<string, int[]>? img_rc;

    public static void init() 
    {
        img_rc = new Dictionary<string, int[]>();
        for (int i = 0; i < IMG_NAMES.GetLength(0); i++) {
            for (int j = 0; j < IMG_NAMES.GetLength(1); j++) {
                //Console.Write(IMG_NAMES[i, j]+" ");
                img_rc.Add(IMG_NAMES[i, j], new int[2] {i, j});
            }
            //Console.WriteLine();
        }
    }
}

public class SpriteVAO
{
    int num_quads;
    int quads_vertexbuffer, quads_vertexarrayobject, quads_triangle_index_buffer;
    //List<float> quads;
    float[] quads;
    UInt32 [] indicies;

    public SpriteVAO()
    {
        quads = new float[(Constants.ROWS*Constants.COLUMNS*2+1)*16];
        indicies = new UInt32[(Constants.ROWS*Constants.COLUMNS*2+1)*6];
        num_quads = 0;
    }

    public void init_GL()
    {
        quads_vertexbuffer = GL.GenBuffer();
        quads_vertexarrayobject = GL.GenVertexArray();
        quads_triangle_index_buffer = GL.GenBuffer();
    }

    public void next_frame(int keep)
    {
        if(num_quads < keep) {
            Console.WriteLine("ERROR: SpriteVAO::next_frame num_quads < keep");
        }
        num_quads = keep;
    }

    public void quad(
        float x1, float y1, 
        float x2, float y2, 
        float u1, float v1, 
        float u2, float v2)
    {
        uint offset = (uint)(num_quads) * 4;
        int ioffset = num_quads * 6;
        /*quads.Add(x1); quads.Add(y1); quads.Add(u1); quads.Add(v1);
        quads.Add(x2); quads.Add(y1); quads.Add(u2); quads.Add(v1);
        quads.Add(x2); quads.Add(y2); quads.Add(u2); quads.Add(v2);
        quads.Add(x1); quads.Add(y2); quads.Add(u1); quads.Add(v2);*/
        quads[num_quads*16 +  0] = x1; quads[num_quads*16 +  1] = y1; quads[num_quads*16 +  2] = u1; quads[num_quads*16 +  3] = v1;
        quads[num_quads*16 +  4] = x2; quads[num_quads*16 +  5] = y1; quads[num_quads*16 +  6] = u2; quads[num_quads*16 +  7] = v1;
        quads[num_quads*16 +  8] = x2; quads[num_quads*16 +  9] = y2; quads[num_quads*16 + 10] = u2; quads[num_quads*16 + 11] = v2;
        quads[num_quads*16 + 12] = x1; quads[num_quads*16 + 13] = y2; quads[num_quads*16 + 14] = u1; quads[num_quads*16 + 15] = v2;
        num_quads++;

        indicies[ioffset+0] = offset+0;
        indicies[ioffset+1] = offset+1;
        indicies[ioffset+2] = offset+2;
        indicies[ioffset+3] = offset+2;
        indicies[ioffset+4] = offset+3;
        indicies[ioffset+5] = offset+0;

        //Console.WriteLine(String.Format("{0} {1} {2} {3} {4} {5} {6} {7}", x1, y1, x2, y2, u1, v1, u1, v1));
    }

    public void draw()
    {
        // transfer data to VAO object
        GL.BindBuffer(BufferTarget.ArrayBuffer, quads_vertexbuffer);
        GL.BufferData(BufferTarget.ArrayBuffer, quads.Length*sizeof(float), quads, BufferUsageHint.DynamicDraw);
        GL.BindVertexArray(quads_vertexarrayobject);

        //Console.WriteLine(num_quads);

        GL.EnableVertexAttribArray(0);
        GL.BindBuffer(BufferTarget.ArrayBuffer, quads_vertexbuffer);
        GL.VertexAttribPointer(
            0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
            4,                  // size;  x,y,u,v
            VertexAttribPointerType.Float,           // type
            false,           // normalized?
            0,                  // stride
            0            // array buffer offset
        );

        GL.BindBuffer(BufferTarget.ElementArrayBuffer, quads_triangle_index_buffer);
        GL.BufferData(BufferTarget.ElementArrayBuffer, indicies.Length*sizeof(UInt32), indicies, BufferUsageHint.DynamicDraw);

        
        GL.DrawElements(PrimitiveType.Triangles, num_quads*6, DrawElementsType.UnsignedInt, 0);
        GL.DisableVertexAttribArray(0);
    }
}

public class Sprite
{
    float x, y;
    float u1, v1, u2, v2;
    public Sprite(int row, int column, string img_name)
    {
        move(row, column);
        set_image(img_name);
    }
    public void set_image(string img_name)
    {
        var irc  = Constants.img_rc[img_name];
        var i = irc[0];
        var j = irc[1];
        u1 = 0.25f * j;
        v1 = 0.25f * (i+1);
        u2 = 0.25f * (j+1);
        v2 = 0.25f * i;
    }
    public void move(int row, int column)
    {
        x = column * Constants.SPRITE_WIDTH;
        y = row * Constants.SPRITE_HEIGHT;
    }
    public void draw(SpriteVAO sprite_vao)
    {
        sprite_vao.quad(x, y, x+Constants.SPRITE_WIDTH, y+Constants.SPRITE_WIDTH, u1, v1, u2, v2);
    }    
}

public class SnakePart
{
    public int row, col;
    public string dir;
    public Sprite sprite;
    public SnakePart(int row_, int col_, string dir_, string img_name)
    {
        row = row_;
        col = col_;
        dir = dir_;
        sprite = new Sprite(row_, col_, img_name);
    }
}

public class Rabbit
{
    public int row, col;
    public Sprite sprite;
    public Rabbit(int row_, int col_)
    {
        row = row_;
        col = col_;
        sprite = new Sprite(row, col, "rabbit");
    }
    public void move(int row_, int col_)
    {
        row = row_;
        col = col_;
        sprite.move(row, col);
    }
}

public class SnakeGame : GameWindow
{
    public const string DIR_RIGHT = "right";
    public const string DIR_LEFT = "left";
    public const string DIR_UP = "up";
    public const string DIR_DOWN = "down";
    Random rng;
    AudioSystem audioSystem;
    // GL handles
    int texture, VertexShaderID, FragmentShaderID, ShaderProgramID;
    int uniformProjectionID, uniformTex0ID;
    List<SnakePart> snake;
    List<Sprite> background;
    float snake_move_t, snake_move_t_rem;
    HashSet<Tuple<int, int>> set_all_squares;
    string snake_dir_next = DIR_RIGHT;
    Rabbit rabbit;
    SpriteVAO spriteVAO;
    Matrix4 projection;
    public SnakeGame(GameWindowSettings gameWindowSettings, NativeWindowSettings nativeWindowSettings)
        : base(gameWindowSettings, nativeWindowSettings)
    {
        rng = new Random();

        audioSystem = new AudioSystem();
        spriteVAO = new SpriteVAO();
        snake = new List<SnakePart>();
        background = new List<Sprite>();

        set_all_squares = new HashSet<Tuple<int, int>>();
        
        rabbit = new Rabbit(0, 0);

        //Console.Out.WriteLine(fragment_shader_text);
        //Console.Out.WriteLine(vertex_shader_text);

        //audioSystem.play_die();
        //audioSystem.play_eat();
    }

    protected override void OnLoad()
    {
        base.OnLoad();

        var renderer = GL.GetString(StringName.Renderer);
        var vendor = GL.GetString(StringName.Vendor);
        var version = GL.GetString(StringName.Version);
        var glslversion = GL.GetString(StringName.ShadingLanguageVersion);
        
        Console.WriteLine(string.Format("OpenGL info:\n\tRenderer: {0}\n\tVendor: {1}\n\tGL Version: {2}\n\tGLSL Version:{3}\n", renderer, vendor, version, glslversion));

        GL.ClearColor(0.7f, 0.7f, 1.0f, 0.0f);
        GL.CullFace(CullFaceMode.Back);
        GL.FrontFace(FrontFaceDirection.Ccw);
        GL.Enable(EnableCap.CullFace);

        StbImage.stbi_set_flip_vertically_on_load(0);
        texture = GL.GenTexture();
        GL.ActiveTexture(TextureUnit.Texture0);
        GL.BindTexture(TextureTarget.Texture2D, texture);
        using (Stream stream = File.OpenRead("../common_data/Snake.png"))     
        {
            ImageResult image = ImageResult.FromStream(stream, ColorComponents.RedGreenBlueAlpha);
            GL.TexImage2D(TextureTarget.Texture2D, 0, PixelInternalFormat.Rgba, image.Width, image.Height, 0, PixelFormat.Rgba, PixelType.UnsignedByte, image.Data);
        }
        GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (int)TextureMinFilter.Nearest);
        GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (int)TextureMagFilter.Nearest);

        spriteVAO.init_GL();

        LoadShaders();

        for(int i=0; i<Constants.ROWS; i++) {
            for(int j=0; j<Constants.COLUMNS; j++) {
                Sprite s = new Sprite(i, j, "grass");
                background.Add(s);
                s.draw(spriteVAO);
                set_all_squares.Add(new Tuple<int, int>(i, j));
            }
        }

        reset_snake();
        place_rabbit();
    }

    public void place_rabbit()
    {
        var set_all_squares_copy = new HashSet<Tuple<int, int>>(set_all_squares);
        var snake_squares = new List<Tuple<int, int>>();

        foreach(SnakePart part in snake) {
            snake_squares.Add(new Tuple<int, int>(part.row, part.col));
        }
        set_all_squares_copy.ExceptWith(snake_squares);

        var free_squares = new Tuple<int, int>[set_all_squares_copy.Count()];
        set_all_squares_copy.CopyTo(free_squares);

        if(free_squares.Length > 0) {
            var square = free_squares[rng.Next(free_squares.Length)];
            rabbit.move(square.Item1, square.Item2);
        } else {
            reset_snake();
            place_rabbit();
        }
    }

    public void reset_snake()
    {
        snake.Clear();

        int row = Constants.ROWS / 3, col = Constants.COLUMNS / 3;

        snake.Add(new SnakePart(row, col, "right", "head_right"));
        snake.Add(new SnakePart(row, col-1, "right", "horizontal"));
        snake.Add(new SnakePart(row, col-2, "right", "tail_right"));
        snake_move_t = 0.2f;
        snake_move_t_rem = snake_move_t;
        snake_dir_next = DIR_RIGHT;
    }

    protected override void OnRenderFrame(FrameEventArgs e)
    {
        base.OnRenderFrame(e);

        OpenTK.Graphics.OpenGL4.ErrorCode errorCode = GL.GetError();
        if (errorCode != OpenTK.Graphics.OpenGL4.ErrorCode.NoError)
        {
            Console.WriteLine("OnRenderFrame error code in queue: ", errorCode.ToString());
        }

        GL.Clear(ClearBufferMask.ColorBufferBit);
        GL.UseProgram(ShaderProgramID);
        GL.UniformMatrix4(uniformProjectionID, false, ref projection);
        GL.ActiveTexture(TextureUnit.Texture0);
        GL.BindTexture(TextureTarget.Texture2D, texture);
        GL.Uniform1(uniformTex0ID, 0);

        GL.Enable(EnableCap.Blend);
        GL.BlendFunc(BlendingFactor.SrcAlpha, BlendingFactor.OneMinusSrcAlpha);

        spriteVAO.next_frame(background.Count()); // clear quads except for background

        rabbit.sprite.draw(spriteVAO); // add quad to spriteVAO

        foreach(SnakePart part in snake) {
            part.sprite.draw(spriteVAO); // add quad to spriteVAO
        }

        spriteVAO.draw(); // actual drawing of all sprite quads

        SwapBuffers();
    }

    protected override void OnUpdateFrame(FrameEventArgs e)
    {
        base.OnUpdateFrame(e);
        float dt = (float)e.Time;

        snake_move_t_rem -= dt;
        if(snake_move_t_rem <= 0) {
            snake_move_t_rem += snake_move_t;
            int row = snake[0].row;
            int col = snake[0].col;
            string head_dir = snake_dir_next;
            if(head_dir == DIR_LEFT) {
                col--;
            } else if(head_dir == DIR_RIGHT) {
                col++;
            } else if(head_dir == DIR_UP) {
                row++;
            }else if(head_dir == DIR_DOWN) {
                row--;
            }
            row %= Constants.ROWS;
            col %= Constants.COLUMNS;
            if(row < 0) {
                row = Constants.ROWS - 1;
            }
            if(col < 0) {
                col = Constants.COLUMNS - 1;
            }
            snake.Insert(0, new SnakePart(row, col, head_dir, "head_"+head_dir));
            var old_dir = snake[1].dir;
            if(head_dir == old_dir) {
                if(head_dir == DIR_LEFT || head_dir == DIR_RIGHT) {
                    snake[1].sprite.set_image("horizontal");
                } else {
                    snake[1].sprite.set_image("vertical");
                }
            } else if(old_dir == DIR_DOWN) {
                if(head_dir == DIR_LEFT) {
                    snake[1].sprite.set_image("turn_4");
                } else {
                    snake[1].sprite.set_image("turn_1");
                }
            } else if(old_dir == DIR_UP) {
                if(head_dir == DIR_LEFT) {
                    snake[1].sprite.set_image("turn_3");
                } else {
                    snake[1].sprite.set_image("turn_2");
                }
            } else if(old_dir == DIR_LEFT) {
                if(head_dir == DIR_UP) {
                    snake[1].sprite.set_image("turn_1");
                } else {
                    snake[1].sprite.set_image("turn_2");
                }
            } else if(old_dir == DIR_RIGHT) {
                if(head_dir == DIR_UP) {
                    snake[1].sprite.set_image("turn_4");
                } else {
                    snake[1].sprite.set_image("turn_3");
                }
            }

            bool rabbit_eaten = rabbit.row == row && rabbit.col == col;

            if(!rabbit_eaten) {
                snake.RemoveAt(snake.Count - 1);
                var dir = snake[snake.Count - 2].dir;
                snake.Last().sprite.set_image("tail_"+dir);
            } else {
                audioSystem.play_eat();
                place_rabbit();
            }

            // test self collision
            foreach(var part in snake.GetRange(1, snake.Count - 1)) {
                if(part.col == col && part.row == row) {
                    audioSystem.play_die();
                    reset_snake();
                    place_rabbit();
                    break;
                }
            }
        }        
    }

    public void key_input(string dir)
    {
        if(dir == DIR_LEFT) {
            if(snake[0].dir != DIR_RIGHT) {
                snake_dir_next = dir;
            }
        } else if(dir == DIR_RIGHT)
        {
            if(snake[0].dir != DIR_LEFT) {
                snake_dir_next = dir;
            }
        } else if(dir == DIR_UP)
        {
            if(snake[0].dir != DIR_DOWN) {
                snake_dir_next = dir;
            }
        }
        else if(dir == DIR_DOWN)
        {
            if(snake[0].dir != DIR_UP) {
                snake_dir_next = dir;
            }
        }
    }

    protected override void OnKeyDown(KeyboardKeyEventArgs e)
    {
        switch(e.Key) {
            case Keys.Escape:
                Close();
                break;
            case Keys.A:
                goto case Keys.Left;
            case Keys.Left:
                key_input(DIR_LEFT);
                break;
            case Keys.D:
                goto case Keys.Right;
            case Keys.Right:
                key_input(DIR_RIGHT);
                break;
            case Keys.W:
                goto case Keys.Up;
            case Keys.Up:
                key_input(DIR_UP);
                break;
            case Keys.S:
                goto case Keys.Down;
            case Keys.Down:
                key_input(DIR_DOWN);
                break;
            default:
                break;
        }
    }
    
    protected override void OnResize(ResizeEventArgs e)
    {
        base.OnResize(e);
        Console.WriteLine(String.Format("OnResize {0}, {1}", e.Width, e.Height));
        GL.Viewport(0, 0, e.Width, e.Height);
        projection = Matrix4.CreateOrthographicOffCenter(0, e.Width, 0, e.Height, -1, 1);
    }

    private void LoadShaders()
    {
        string vertex_shader_text = File.ReadAllText("shader_vertex.glsl");
        string fragment_shader_text = File.ReadAllText("shader_fragment.glsl");
        VertexShaderID =  GL.CreateShader(ShaderType.VertexShader);
	    FragmentShaderID =  GL.CreateShader(ShaderType.FragmentShader);
        GL.ShaderSource(VertexShaderID, vertex_shader_text);
        GL.ShaderSource(FragmentShaderID, fragment_shader_text);

        GL.CompileShader(VertexShaderID);
        GL.GetShader(VertexShaderID, ShaderParameter.CompileStatus, out int success);
        if (success == 0) {
            string infoLog = GL.GetShaderInfoLog(VertexShaderID);
            Console.WriteLine(infoLog);
        }

        GL.CompileShader(FragmentShaderID);
        GL.GetShader(FragmentShaderID, ShaderParameter.CompileStatus, out success);
        if (success == 0) {
            string infoLog = GL.GetShaderInfoLog(FragmentShaderID);
            Console.WriteLine(infoLog);
        }

        ShaderProgramID = GL.CreateProgram();
        GL.AttachShader(ShaderProgramID, VertexShaderID);
        GL.AttachShader(ShaderProgramID, FragmentShaderID);

        GL.LinkProgram(ShaderProgramID);

        GL.GetProgram(ShaderProgramID, GetProgramParameterName.LinkStatus, out success);
        if (success == 0)
        {
            string infoLog = GL.GetProgramInfoLog(ShaderProgramID);
            Console.WriteLine(infoLog);
        }

        GL.UseProgram(ShaderProgramID);

        uniformProjectionID = GL.GetUniformLocation(ShaderProgramID, "projection");
        uniformTex0ID = GL.GetUniformLocation(ShaderProgramID, "tex0");

        Console.WriteLine(String.Format("uniformProjectionID={0}, uniformTex0ID={1}", uniformProjectionID, uniformTex0ID));
    }

    protected override void OnUnload()
    {
        audioSystem.close();
        GL.DetachShader(ShaderProgramID, VertexShaderID);
        GL.DetachShader(ShaderProgramID, FragmentShaderID);
        GL.DeleteShader(FragmentShaderID);
        GL.DeleteShader(VertexShaderID);
        GL.DeleteProgram(ShaderProgramID);
    }
}

class Program
{
    static void Main(string[] args)
    {
        Constants.init();
        
        var nativeWindowSettings = new NativeWindowSettings()
            {
                Size = new Vector2i(Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT),
                Title = "Snake Game (C# + OpenTK)",
                // This is needed to run on macos
                Flags = ContextFlags.ForwardCompatible,
            };

        using (var game = new SnakeGame(GameWindowSettings.Default, nativeWindowSettings))
        {
            game.Run();
        }
    }
}
