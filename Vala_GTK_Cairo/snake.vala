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
    Gee.HashSet<Square> set_all_squares;
    string snake_next_dir;
    Square rabbit;

    float snake_move_t;
    float snake_move_t_rem;


    public SnakeGame()
    {
        var snake_pixbuf = new Gdk.Pixbuf.from_file("../common_data/Snake.png");

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
    }

    void reset_snake()
    {
        snake_move_t = 0.2f;
        snake_move_t_rem = snake_move_t;        
        snake.clear();
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

    }

    public bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType state)
    {
        stdout.printf("keyval=%u, keycode=%u\n", keyval, keycode);
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
        }
        
        return true;
    }
}


int main (string[] argv) {
    var app = new Gtk.Application ("com.SnakeGameCollection.GtkApplication", GLib.ApplicationFlags.FLAGS_NONE);

    var snake_game = new SnakeGame();

    app.activate.connect (() => {
        var window = new Gtk.ApplicationWindow (app);
        window.title = "Snake Game (Vala, GTK+, Cairo)";
        window.set_default_size(SnakeGame.WINDOW_WIDTH, SnakeGame.WINDOW_HEIGHT);
        window.set_resizable(false);

        var drawing_area = new Gtk.DrawingArea();
        drawing_area.set_content_width(SnakeGame.WINDOW_WIDTH);
        drawing_area.set_content_width(SnakeGame.WINDOW_HEIGHT);

        drawing_area.set_draw_func(snake_game.redraw);

        var eventControllerKey = new Gtk.EventControllerKey();
        drawing_area.add_controller(eventControllerKey);
        eventControllerKey.key_pressed.connect(snake_game.key_pressed);

        window.set_child (drawing_area);
        window.present ();
        drawing_area.set_focusable(true);
        drawing_area.grab_focus();
    });

    return app.run (argv);
}
