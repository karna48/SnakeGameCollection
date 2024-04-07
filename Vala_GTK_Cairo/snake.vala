class SnakePart {
    public int row;
    public int col;
    public string dir;
    public string image_name;
}

struct Rabbit {
    int row;
    int col;
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
    Rabbit rabbit;

    public SnakeGame()
    {
        var snake_pixbuf = new Gdk.Pixbuf.from_file("../common_data/Snake.png");

        images = new Gee.HashMap<string, Gdk.Pixbuf>();

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
            }
        }

        snake = new Gee.ArrayList<SnakePart>();
        rabbit = Rabbit();
    }

    public void redraw_da (Gtk.DrawingArea drawing_area, Cairo.Context cr, int width, int height)
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
}


int main (string[] argv) {
    var app = new Gtk.Application ("com.SnakeGameCollection.GtkApplication", GLib.ApplicationFlags.FLAGS_NONE);

    var snake_game = new SnakeGame();

    app.activate.connect (() => {
        var window = new Gtk.ApplicationWindow (app);
        window.set_default_size(SnakeGame.WINDOW_WIDTH, SnakeGame.WINDOW_HEIGHT);
        window.set_resizable(false);

        var drawing_area = new Gtk.DrawingArea();
        drawing_area.set_content_width(SnakeGame.WINDOW_WIDTH);
        drawing_area.set_content_width(SnakeGame.WINDOW_HEIGHT);

        drawing_area.set_draw_func(snake_game.redraw_da);

        window.set_child (drawing_area);
        window.present ();
    });

    return app.run (argv);
}
