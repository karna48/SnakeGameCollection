#__pragma__('skip')
from stubs import *
from stubs import __new__
#__pragma__('noskip')
import random
from itertools import product


class Rabbit:
    def __init__(self, row, col, images, rows):
        self.row = row
        self.rows = rows
        self.col = col
        self.images = images

    def draw_grass(self, scale, ctx):
        self.images['grass'].draw_rc(self.rows-self.row-1, self.col, scale, ctx)

    def draw(self, scale, ctx):
        self.draw_grass(scale, ctx)
        self.images['rabbit'].draw_rc(self.rows-self.row-1, self.col, scale, ctx)


class SnakePart:
    def __init__(self, row, col, dir, images, rows):
        self.row = row
        self.col = col
        self.dir = dir
        self.images = images
        self.rows = rows

    def draw(self, img_name, scale, ctx):
        self.images[img_name].draw_rc(self.rows-self.row-1, self.col, scale, ctx)

    def draw_head(self, scale, ctx):
        self.draw_grass(scale, ctx)
        self.images['head_'+self.dir].draw_rc(self.rows-self.row-1, self.col, scale, ctx)

    def draw_second(self, scale, ctx, head_dir):
        if head_dir == self.dir:
            img_name = 'horizontal' if head_dir in ('left', 'right') else 'vertical'
        elif self.dir == 'down':
            img_name = 'turn_4' if head_dir == 'left' else 'turn_1'
        elif self.dir == 'up':
            img_name = 'turn_3' if head_dir == 'left' else 'turn_2'
        elif self.dir == 'left':
            img_name = 'turn_1' if head_dir == 'up' else 'turn_2'
        elif self.dir == 'right':
            img_name = 'turn_4' if head_dir == 'up' else 'turn_3'
        else:
            raise ValueError(f'unknown second snake part direction: {self.dir}')

        self.draw_grass(scale, ctx)
        self.images[img_name].draw_rc(self.rows-self.row-1, self.col, scale, ctx)

    def draw_tail(self, scale, ctx, prev_dir):
        self.draw_grass(scale, ctx)
        tail = self.images['tail_'+prev_dir]
        tail.draw_rc(self.rows-self.row-1, self.col, scale, ctx)

    def draw_grass(self, scale, ctx):
        self.images['grass'].draw_rc(self.rows-self.row-1, self.col, scale, ctx)


class SubImage:
    def __init__(self, image, x, y, width, height):
        self.image = image
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    def draw(self, x, y, scale, ctx):
        ctx.drawImage(
            self.image,
            self.x, self.y, self.width, self.height,  # source
            x, y, self.width*scale, self.height*scale  # destination
        )

    def draw_rc(self, row, col, scale, ctx):
        self.draw(col*self.width*scale, row*self.height*scale, scale, ctx)


class SnakeGame:
    def __init__(self):
        self.sound_die = __new__(Audio("data/die.wav"))
        self.sound_eat = __new__(Audio("data/eat.wav"))
        self.sprite_w = 16
        self.sprite_h = 16
        self.img = document.getElementById('Snake.png')
        self.canvas = document.getElementById("the-canvas")

        # cut tiles
        self.images = {
            name:
            SubImage(self.img, j * self.sprite_w, i * self.sprite_h, self.sprite_w, self.sprite_h)

            for i, names_row in enumerate(
                (('head_up', 'head_right', 'head_down', 'head_left'),
                 ('tail_up', 'tail_right', 'tail_down', 'tail_left'),
                 ('turn_1', 'turn_2', 'turn_3', 'turn_4'),
                 ('vertical', 'horizontal', 'rabbit', 'grass'))
            )
            for j, name in enumerate(names_row)
        }

        self.snake_dir_next = 'right'
        self.snake = []
        self.score = 0
        self.rabbit = None

        self.set_all_squares = set()
        self.columns = 15
        self.scale = 0
        self.rows = 0
        self.resize()

        window.addEventListener('resize', self.resize)
        window.addEventListener('keydown', self.handle_key_press)
        self.interval_id = setInterval(self.step, 200)

    def resize(self):
        self.scale = window.innerWidth / (self.columns * self.sprite_w)
        new_rows = window.innerHeight // (self.scale * self.sprite_w)
        restart_game = new_rows != self.rows
        self.rows = new_rows

        ctx = self.canvas.getContext("2d")
        ctx.canvas.width = window.innerWidth
        ctx.canvas.height = window.innerHeight
        ctx.imageSmoothingEnabled = False

        self.set_all_squares = set()

        for i, j in product(range(self.rows), range(self.columns)):
            self.set_all_squares.add((i, j))
            self.images['grass'].draw(
                j*self.sprite_w*self.scale, i*self.sprite_w*self.scale,
                self.scale, ctx)

        if restart_game:
            self.restart(ctx)

    def restart(self, ctx):
        for s in self.snake:
            s.draw_grass(self.scale, ctx)

        if self.rabbit is not None:
            self.rabbit.draw_grass(self.scale, ctx)

        self.snake = []
        # init head position
        row, col = self.rows // 3, self.columns // 3

        for i, name in enumerate(('head_right', 'horizontal', 'tail_right')):
            self.snake.append(SnakePart(row, col-i, 'right', self.images, self.rows))
            self.snake[len(self.snake)-1].draw(name, self.scale, ctx)

        self.snake_dir_next = 'right'
        self.score = 0

        self.place_rabbit(ctx)

    def place_rabbit(self, ctx, r=None, c=None):
        if r is None or c is None:
            set_snake_squares = {(s.row, s.col) for s in self.snake}
            square = random.choice(list(self.set_all_squares.difference(set_snake_squares)))
        else:
            square = (r, c)

        self.rabbit = Rabbit(*square, self.images, self.rows)
        self.rabbit.draw(self.scale, ctx)

    def step(self):
        ctx = self.canvas.getContext("2d")
        ctx.imageSmoothingEnabled = False

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

        rabbit_eaten = row == self.rabbit.row and col == self.rabbit.col

        if not rabbit_eaten:
            old_tail = self.snake[len(self.snake) - 1]
            old_tail.draw_grass(self.scale, ctx)
            self.snake.pop()  # del self.snake[-1]
            tail: SnakePart = self.snake[len(self.snake)-1]
            tail.draw_tail(self.scale, ctx, self.snake[len(self.snake)-2].dir)
        else:  # rabbit_eaten
            # [TODO] setInterval smaller delay
            #self.snake_move_t -= 0.005
            #if self.snake_move_t < 0.01:
            #    self.snake_move_t = 0.01
            self.sound_eat.play()
            self.place_rabbit(ctx)

        # insert head to front
        new_head = SnakePart(row, col, head_dir, self.images, self.rows)
        self.snake.insert(0, new_head)
        new_head.draw_head(self.scale, ctx)

        self.snake[1].draw_second(self.scale, ctx, head_dir)


        # new head collision with body
        for snake_part in self.snake[1:]:
            if row == snake_part.row and col == snake_part.col:
                self.sound_die.play()
                self.restart(ctx)


    def handle_key_press(self, e):
        if len(self.snake):
            head_dir = self.snake[0].dir
        else:
            head_dir = 'right'

        if e.code == 'ArrowLeft':
            if head_dir != 'right':
                self.snake_dir_next = 'left'
        elif e.code == 'ArrowRight':
            if head_dir != 'left':
                self.snake_dir_next = 'right'
        elif e.code == 'ArrowUp':
            if head_dir != 'down':
                self.snake_dir_next = 'up'
        elif e.code == 'ArrowDown':
            if head_dir != 'up':
                self.snake_dir_next = 'down'

