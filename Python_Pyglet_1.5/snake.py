import pyglet
from pyglet.window import key, mouse
from pyglet.gl import *
import random
from pathlib import Path
from itertools import product
from collections import namedtuple

WINDOW_SIZE = (1200, 800)
SPRITE_SCALE = 5
data_dir = Path(__file__).parent.parent / 'common_data'

Rabbit = namedtuple('Rabbit', ('row', 'col', 'sprite'))
SnakePart = namedtuple('SnakePart', ('row', 'col', 'dir', 'sprite'))

# keep pixelated, avoid borders
pyglet.image.Texture.default_min_filter = GL_NEAREST
pyglet.image.Texture.default_mag_filter = GL_NEAREST


class MySprite(pyglet.sprite.Sprite):
    def __init__(self, img,
                 x=0, y=0, scale=1, scale_x=1, scale_y=1,
                 blend_src=GL_SRC_ALPHA,
                 blend_dest=GL_ONE_MINUS_SRC_ALPHA,
                 batch=None,
                 group=None,
                 usage='dynamic',
                 subpixel=False):
        super().__init__(img, x, y,
                         blend_src, blend_dest,
                         batch, group,
                         usage, subpixel)
        self.scale = scale
        self.scale_x = scale_x
        self.scale_y = scale_y


class SnakeGame:
    def __init__(self):
        self.frame_counter = 0
        self.one_second_counter = 0

        self.main_window = pyglet.window.Window(*WINDOW_SIZE)
        self.main_window.push_handlers(self)

        # pyglet.clock causes on_draw event
        pyglet.clock.schedule_interval(self.update, 1/60)

        # text labels
        self.fps_label = pyglet.text.Label(
            '??? FPS', font_name='Arial', font_size=20,
            x=10, y=self.main_window.height, anchor_x='left', anchor_y='top')

        self.len_label = pyglet.text.Label(
            'Length: X', font_name='Arial', font_size=20,
            x=10, y=self.main_window.height-35, anchor_x='left', anchor_y='top')

        # SFX
        self.eat_sound = pyglet.media.load(data_dir / 'eat.wav', streaming=False)
        self.die_sound = pyglet.media.load(data_dir / 'die.wav', streaming=False)

        # GFX
        snake_png = pyglet.image.load(data_dir / 'Snake.png')
        self.sprite_w, self.sprite_h = snake_png.width // 4, snake_png.height // 4

        self.images = {
            name: snake_png.get_region(
                j * self.sprite_w, (3-i) * self.sprite_h,
                self.sprite_w, self.sprite_h
            )
            for i, names_row in enumerate(
                (('head_up', 'head_right', 'head_down', 'head_left'),
                 ('tail_up', 'tail_right', 'tail_down', 'tail_left'),
                 ('turn_1', 'turn_2', 'turn_3', 'turn_4'),
                 ('vertical', 'horizontal', 'rabbit', 'grass'))
            )
            for j, name in enumerate(names_row)
        }

        self.columns = self.main_window.width // (SPRITE_SCALE * self.sprite_w)
        self.rows = self.main_window.height // (SPRITE_SCALE * self.sprite_h)

        self.background_batch = pyglet.graphics.Batch()
        self.background_sprites = [
            MySprite(self.images['grass'],
                     *self.square_lb(i, j),  # x, y
                     scale=SPRITE_SCALE,
                     batch=self.background_batch)
            for i, j in product(range(self.rows), range(self.columns))
        ]

        self.snake_batch = pyglet.graphics.Batch()
        self.snake = []  # snake's parts: list of SnakePart
        self.snake_dir_next = 'right'
        self.reset_snake()

        self.snake_move_t = 0.2  # cesovy interval pohybu hada
        self.snake_move_t_rem = self.snake_move_t  # zbyvajici cas do pohybu

        self.set_all_squares = set(product(range(self.rows), range(self.columns)))

        self.rabbit = Rabbit(0, 0, MySprite(self.images['rabbit'], scale=SPRITE_SCALE))
        self.place_rabbit()

    def square_lb(self, row, column):
        """ square left bottom point x, y """
        return column * self.sprite_w * SPRITE_SCALE, row * self.sprite_h * SPRITE_SCALE

    def place_rabbit(self, r=None, c=None):
        if r is None or c is None:
            set_snake_squares = set((s[0], s[1]) for s in self.snake)
            square = random.choice(list(self.set_all_squares-set_snake_squares))
        else:
            square = (r, c)

        self.rabbit = Rabbit(*square, self.rabbit.sprite)
        self.rabbit.sprite.position = self.square_lb(*square)

    def reset_snake(self):
        self.snake_move_t = 0.2
        self.snake.clear()  # delete old snake parts

        # init head position
        row, col = self.rows // 3, self.columns // 3

        self.snake.extend(
            SnakePart(row, col-i, 'right',
                      MySprite(self.images[name],
                               *self.square_lb(row, col-i),
                               scale=SPRITE_SCALE,
                               batch=self.snake_batch)
                      )
            for i, name in enumerate(('head_right', 'horizontal', 'tail_right'))
        )

        self.snake_dir_next = 'right'

    def update(self, dt):
        self.snake_move_t_rem -= dt
        if self.snake_move_t_rem <= 0:
            self.snake_move_t_rem = self.snake_move_t
            head_dir = self.snake_dir_next
            row = self.snake[0].row
            col = self.snake[0].col
            if head_dir == 'left':
                col -= 1
            elif head_dir == 'right':
                col += 1
            elif head_dir == 'up':
                row += 1
            elif head_dir == 'down':
                row -= 1
            else:
                raise ValueError(f'unknown snake_dir {head_dir}')

            row %= self.rows
            col %= self.columns

            self.snake.insert(
                0,  # insert head to front
                SnakePart(
                    row, col, head_dir,
                    MySprite(
                        self.images['head_'+head_dir],
                        *self.square_lb(row, col),  # x, y
                        scale=SPRITE_SCALE,
                        batch=self.snake_batch)))

            old_dir = self.snake[1].dir
            if head_dir == old_dir:
                img_name = 'horizontal' if head_dir in ('left', 'right') else 'vertical'
            elif old_dir == 'down':
                img_name = 'turn_4' if head_dir == 'left' else 'turn_1'
            elif old_dir == 'up':
                img_name = 'turn_3' if head_dir == 'left' else 'turn_2'
            elif old_dir == 'left':
                img_name = 'turn_1' if head_dir == 'up' else 'turn_2'
            elif old_dir == 'right':
                img_name = 'turn_4' if head_dir == 'up' else 'turn_3'
            else:
                raise ValueError(f'unknown second snake part direction: {old_dir}')

            self.snake[1].sprite.image = self.images[img_name]

            rabbit_eaten = row == self.rabbit.row and col == self.rabbit.col

            if not rabbit_eaten:
                self.snake.pop()   # del self.snake[-1]
                tail = self.snake[-1]
                tail.sprite.image = self.images['tail_'+self.snake[-2].dir]
            else:  # rabbit_eaten
                self.snake_move_t -= 0.005
                if self.snake_move_t < 0.01:
                    self.snake_move_t = 0.01
                self.eat_sound.play()
                self.place_rabbit()

            # new head collision with body
            for snake_part in self.snake[1:]:
                if row == snake_part.row and col == snake_part.col:
                    self.die_sound.play()
                    self.reset_snake()
                    self.place_rabbit()
                    self.snake_move_t_rem = 3

        self.frame_counter += 1
        self.one_second_counter += dt
        if self.one_second_counter >= 1:
            self.fps_label.text = f'{self.frame_counter/self.one_second_counter:.2f} FPS'
            self.frame_counter = 0
            self.one_second_counter -= 1

        self.len_label.text = f'Length: {len(self.snake)}'

    def on_draw(self):
        self.main_window.clear()

        self.background_batch.draw()
        self.rabbit.sprite.draw()
        self.snake_batch.draw()

        self.fps_label.draw()
        self.len_label.draw()

    def on_key_press(self, symbol, _modifiers):
        print('A key was pressed, code: ', symbol)
        try:
            head_dir = self.snake[0].dir
        except IndexError:
            head_dir = 'right'

        if symbol == key.LEFT:
            if head_dir != 'right':
                self.snake_dir_next = 'left'
        elif symbol == key.RIGHT:
            if head_dir != 'left':
                self.snake_dir_next = 'right'
        elif symbol == key.UP:
            if head_dir != 'down':
                self.snake_dir_next = 'up'
        elif symbol == key.DOWN:
            if head_dir != 'up':
                self.snake_dir_next = 'down'

    def on_mouse_press(self, x, y, b, _mod):
        if b == mouse.LEFT:
            print('left mouse button pressed on position:', x, y)
            col = x // (self.sprite_w * SPRITE_SCALE)
            row = y // (self.sprite_h * SPRITE_SCALE)
            self.place_rabbit(row, col)


game_state = SnakeGame()
pyglet.app.run()
