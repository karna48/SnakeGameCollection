/* NOTE: I wanted to try Vala for so long it became 
         almost dead and compared to other languages 
         I did not find the syntax and facilities that nice;
         also Cairo is very old-style drawing library, not a fan, sorry...
*/

class Square {
    public int row;
    public int col;
    public Square(int r, int c)
    {
        row = r; 
        col = c;
    }
}


class SnakePart {
    public int row;
    public int col;
    public string dir;
    public string image_name;
    public SnakePart(int r, int c, string dir, string image_name)
    {
        row = r;
        col = c;
        this.dir = dir;
        this.image_name = image_name;
    }
}


class SnakeGame {
    public const int WINDOW_WIDTH = 1200;
    public const int WINDOW_HEIGHT = 800;
    const int SPRITE_SCALE = 5;
    const int SPRITE_WIDTH = 16;
    const int SPRITE_HEIGHT = 16;
    const int ROWS = WINDOW_HEIGHT / (SPRITE_HEIGHT * SPRITE_SCALE);
    const int COLUMNS = WINDOW_WIDTH / (SPRITE_WIDTH * SPRITE_SCALE);

    Gee.HashMap<string, Gdk.Pixbuf> images;
    Gee.ArrayList<SnakePart> snake;
    string snake_next_dir;
    Square rabbit;

    float snake_move_t;
    float snake_move_t_rem;

    Gtk.ApplicationWindow window;
    Gtk.DrawingArea drawing_area;
    Gtk.EventControllerKey eventControllerKey;

    Gtk.MediaFile sound_eat;
    Gtk.MediaFile sound_die;

    public SnakeGame()
    {
        var snake_pixbuf = new Gdk.Pixbuf.from_file("../common_data/Snake.png");
        
        /*
        // Linux Mint 21.3
        //  GLib-GIO-CRITICAL **: 07:46:17.301: g_io_extension_point_get_extensions: assertion 'extension_point != NULL' failed
        //  Gtk-ERROR **: 07:46:17.301: GTK was run without any GtkMediaFile extension being present. This must not happen.
        sound_eat = Gtk.MediaFile.for_filename("../common_data/eat.wav");
        sound_die = Gtk.MediaFile.for_filename("../common_data/die.wav");
        */
        
    
        images = new Gee.HashMap<string, Gdk.Pixbuf>();
        set_all_squares = new Gee.HashSet<Square>();

        string [,] image_names = {
            {"head_up", "head_right", "head_down", "head_left"},
            {"tail_up", "tail_right", "tail_down", "tail_left"},
            {"turn_1", "turn_2", "turn_3", "turn_4"},
            {"vertical", "horizontal", "rabbit", "grass"}
        };

        for(int i = 0; i < image_names.length[0]; i++) {
            for(int j = 0; j < image_names.length[1]; j++) {
                var name = image_names[i, j];
                images[name] = new Gdk.Pixbuf.subpixbuf(snake_pixbuf, j*SPRITE_WIDTH, i*SPRITE_HEIGHT, SPRITE_WIDTH, SPRITE_HEIGHT);
                set_all_squares.add(new Square(i, j));
            }
        }

        snake = new Gee.ArrayList<SnakePart>();
        rabbit = new Square(0, 0);

        reset_snake();
        place_rabbit();
    }

    void place_rabbit()
    {
        rabbit.row = GLib.Random.int_range(0, ROWS);
        rabbit.col = GLib.Random.int_range(0, COLUMNS);

        var squares = Gee.List<Square>();

        for(int row = 0; row < ROWS; row++) {
            for(int col = 0; col < COLUMNS; col++) {
                var contains = false;
                foreach(var part in snake) { // not very efficient
                    if(part.col == col && part.row == row) {
                        contains = true;
                        break;
                    }
                }
                if(!contains) {
                    squares.add(Square(row, col));
                }        
            }
        }
        // TODO no squares left
        rabbit = squares[GLib.Random.int_range(0, squares.size())];
    }

    void reset_snake()
    {
        snake_move_t = 0.2f;
        snake_move_t_rem = snake_move_t;        
        snake.clear();
        var row = 2*ROWS / 3; // this version is flipped vertically
        var col = COLUMNS / 3;
        var p = new SnakePart(row, col, "right", "head_right");
        snake.add(p);
        p = new SnakePart(row, col-1, "right", "horizontal");
        snake.add(p);
        p = new SnakePart(row, col-2, "right", "tail_right");
        snake.add(p);
    }

    public void redraw(Gtk.DrawingArea drawing_area, Cairo.Context cr, int width, int height)
    {
        cr.scale(SPRITE_SCALE, SPRITE_SCALE);
        
        for(int row = 0; row < ROWS; row++) {
            for(int col = 0; col < COLUMNS; col++) {
                Gdk.cairo_set_source_pixbuf(cr, images["grass"], col*SPRITE_WIDTH, row*SPRITE_HEIGHT);
                cr.get_source().set_filter(Cairo.Filter.NEAREST);
                cr.paint();
            }
        }

        foreach(var part in snake) {
            Gdk.cairo_set_source_pixbuf(
                cr, images[part.image_name], 
                part.col*SPRITE_WIDTH, part.row*SPRITE_HEIGHT);
            cr.get_source().set_filter(Cairo.Filter.NEAREST);
            cr.paint();
        }

        Gdk.cairo_set_source_pixbuf(
            cr, images["rabbit"], 
            rabbit.col*SPRITE_WIDTH, rabbit.row*SPRITE_HEIGHT);
        cr.get_source().set_filter(Cairo.Filter.NEAREST);
        cr.paint();
    }

    public bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType state)
    {
        //stdout.printf("keyval=%u, keycode=%u\n", keyval, keycode);
        switch(keyval) {
            case Gdk.Key.a:
            case Gdk.Key.A:
            case Gdk.Key.Left:
                print("left\n");
            break;

            case Gdk.Key.d:
            case Gdk.Key.D:
            case Gdk.Key.Right:
                print("right\n");
            break;

            case Gdk.Key.w:
            case Gdk.Key.W:
            case Gdk.Key.Up:
                print("up\n");
            break;

            case Gdk.Key.s:
            case Gdk.Key.S:
            case Gdk.Key.Down:
                print("down\n");
            break;

            case Gdk.Key.F5:
                //sound_eat.play();
                print("sorry, no sound: EAT!\n");
            break;
            case Gdk.Key.F6:
                //sound_die.play();
                print("sorry, no sound: DIE!\n");
            break;

            case Gdk.Key.Escape:
                window.close();
            break;
        }
        
        return true;
    }

    public void init_gui(Gtk.Application app)
    {
        window = new Gtk.ApplicationWindow (app);
        window.title = "Snake Game (Vala, GTK+, Cairo)";
        window.set_default_size(SnakeGame.WINDOW_WIDTH, SnakeGame.WINDOW_HEIGHT);
        window.set_resizable(false);

        drawing_area = new Gtk.DrawingArea();
        drawing_area.set_content_width(SnakeGame.WINDOW_WIDTH);
        drawing_area.set_content_width(SnakeGame.WINDOW_HEIGHT);

        drawing_area.set_draw_func(redraw);

        eventControllerKey = new Gtk.EventControllerKey();
        drawing_area.add_controller(eventControllerKey);
        eventControllerKey.key_pressed.connect(key_pressed);

        window.set_child (drawing_area);
        window.present ();
        drawing_area.set_focusable(true);
        drawing_area.grab_focus();
    }
}


int main (string[] argv) {
    var app = new Gtk.Application ("com.SnakeGameCollection.GtkApplication", GLib.ApplicationFlags.FLAGS_NONE);
    var snake_game = new SnakeGame();

    app.activate.connect (() => { snake_game.init_gui(app); });

    return app.run (argv);
}
