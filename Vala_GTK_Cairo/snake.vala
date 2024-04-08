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

    GLib.Timer timer;

    double snake_move_t;
    double snake_move_t_rem;

    Gtk.ApplicationWindow window;
    Gtk.DrawingArea drawing_area;
    Gtk.EventControllerKey eventControllerKey;

    Gtk.MediaFile sound_eat;
    Gtk.MediaFile sound_die;

    public SnakeGame()
    {
        timer = new GLib.Timer();
        var snake_pixbuf = new Gdk.Pixbuf.from_file("../common_data/Snake.png");
        
        /*
        // Linux Mint 21.3
        //  GLib-GIO-CRITICAL **: 07:46:17.301: g_io_extension_point_get_extensions: assertion 'extension_point != NULL' failed
        //  Gtk-ERROR **: 07:46:17.301: GTK was run without any GtkMediaFile extension being present. This must not happen.
        sound_eat = Gtk.MediaFile.for_filename("../common_data/eat.wav");
        sound_die = Gtk.MediaFile.for_filename("../common_data/die.wav");
        */
        
    
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
        rabbit = new Square(0, 0);
        
        snake_move_t_rem = 3;

        reset_snake();
        place_rabbit();
    }

    void place_rabbit()
    {
        rabbit.row = GLib.Random.int_range(0, ROWS);
        rabbit.col = GLib.Random.int_range(0, COLUMNS);

        var squares = new Gee.ArrayList<Square>();

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
                    squares.add(new Square(row, col));
                }        
            }
        }

        if(squares.size == 0) {
            reset_snake();
            place_rabbit();
        } else {
            rabbit = squares[GLib.Random.int_range(0, squares.size)];
        }
    }

    void reset_snake()
    {
        snake_move_t = 0.2;
        snake.clear();
        var row = 2*ROWS / 3; // this version is flipped vertically
        var col = COLUMNS / 3;
        var p = new SnakePart(row, col, "right", "head_right");
        snake.add(p);
        p = new SnakePart(row, col-1, "right", "horizontal");
        snake.add(p);
        p = new SnakePart(row, col-2, "right", "tail_right");
        snake.add(p);
        snake_next_dir = "right";
    }

    public bool update()
    {
        double dt = 0.0;
        if(!timer.is_active()) {
            timer.start();
        } else {
            dt = timer.elapsed();
            timer.start();
            //stdout.printf("%lf\n", dt);
        }
        snake_move_t_rem -= dt;
        if(snake_move_t_rem <= 0) {
            snake_move_t_rem = snake_move_t;
            var head_dir = snake_next_dir;
            int row = snake[0].row;
            int col = snake[0].col;
            if (head_dir == "left") {
                col -= 1;
            } else if (head_dir == "right") {
                col += 1;
            } else if (head_dir == "up") { // flipped version
                row -= 1;
            } else if (head_dir == "down") {
                row += 1;
            } else {
                print("WARING: unknown head_dir!\n");
                return window.get_visible();
            }

            // NOTE: %= operator did not work properly even when using uint!

            if(row < 0) {
                row = ROWS-1;
            } else if(row >= ROWS) {
                row = 0;
            }

            if(col < 0) {
                col = COLUMNS-1;
            } else if(col >= COLUMNS) {
                col = 0;
            }

            snake.insert(0, new SnakePart((int)row, (int)col, head_dir, "head_"+head_dir));

            var old_dir = snake[1].dir;
            var img_name = "";

            if (head_dir == old_dir) {
                snake[1].image_name = (head_dir == "left" || head_dir == "right") ? "horizontal" : "vertical";
            } else if (old_dir == "right") {
                snake[1].image_name = (head_dir == "up") ? "turn_4" : "turn_3";
            } else if (old_dir == "left") {
                snake[1].image_name = (head_dir == "up") ? "turn_1" : "turn_2";
            } else if (old_dir == "up") {
                snake[1].image_name = (head_dir == "left") ? "turn_3" : "turn_2";
            } else if (old_dir == "down") {
                snake[1].image_name = (head_dir == "left") ? "turn_4" : "turn_1";
            } else {
                print("WARING: unknown second snake part direction!\n");
                return window.get_visible();
            }

            var rabbit_eaten = row == rabbit.row && col == rabbit.col;

            if(!rabbit_eaten) {
                snake.remove_at(snake.size - 1);
                snake.last().image_name = "tail_"+snake[snake.size-2].dir;
            } else {
                snake_move_t -= 0.005;
                if(snake_move_t < 0.01) {
                    snake_move_t = 0.01;
                }
                // sound_eat.play();
                place_rabbit();
            }

            for(int i=1; i<snake.size; i++) {
                if(row == snake[i].row && col == snake[i].col) {
                    // sound_die.play();
                    reset_snake();
                    place_rabbit();
                    snake_move_t_rem = 3;
                    break;
                 }
            }
            

            drawing_area.queue_draw();
        }

        return window.get_visible(); // stop calling the function -> can end the application
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
        var head_dir = snake.size>0 ? snake[0].dir : "right";

        switch(keyval) {
            case Gdk.Key.a:
            case Gdk.Key.A:
            case Gdk.Key.Left:
                if (head_dir != "right") {
                    snake_next_dir = "left";
                }
            break;

            case Gdk.Key.d:
            case Gdk.Key.D:
            case Gdk.Key.Right:
            if (head_dir != "left") {
                snake_next_dir = "right";
            }
        break;

            case Gdk.Key.w:
            case Gdk.Key.W:
            case Gdk.Key.Up:
            if (head_dir != "down") {
                snake_next_dir = "up";
            }
            break;

            case Gdk.Key.s:
            case Gdk.Key.S:
            case Gdk.Key.Down:
            if (head_dir != "up") {
                snake_next_dir = "down";
            }
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

        GLib.Idle.add(update);
    }
}


int main (string[] argv) {
    var app = new Gtk.Application ("com.SnakeGameCollection.GtkApplication", GLib.ApplicationFlags.FLAGS_NONE);
    var snake_game = new SnakeGame();

    app.activate.connect (() => { snake_game.init_gui(app); });

    return app.run (argv);
}
