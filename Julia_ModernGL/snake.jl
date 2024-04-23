
# uses geometry shader
# GLFW.GetKey did not work for me

import Images
using ModernGL, GeometryTypes, GLAbstraction, GLFW

include("audiosystem.jl")

const GLA = GLAbstraction

common_data_dir = joinpath("..", "common_data")

sound_die = Sound(joinpath(common_data_dir, "die.wav"))
sound_eat = Sound(joinpath(common_data_dir, "eat.wav"))

const RESOLUTION = (1200, 800)
const SPRITE_IMG_WIDTH = 16
const SPRITE_IMG_HEIGHT = 16
const SPRITE_SCALE = 5
const SPRITE_WIDTH = SPRITE_SCALE * SPRITE_IMG_WIDTH
const SPRITE_HEIGHT = SPRITE_SCALE * SPRITE_IMG_HEIGHT
const ROWS = div(RESOLUTION[2], SPRITE_HEIGHT)
const COLUMNS = div(RESOLUTION[1], SPRITE_WIDTH)

const IMG_NAMES = [
    "head_up" "head_right" "head_down" "head_left";
    "tail_up" "tail_right" "tail_down" "tail_left";
    "turn_1" "turn_2" "turn_3" "turn_4";
    "vertical" "horizontal" "rabbit" "grass"
]

const g_img_rc = Dict(IMG_NAMES[i, j] => (i, j) for i in 1:size(IMG_NAMES, 1), j in 1:size(IMG_NAMES, 2))

function img_idx(name)
    i, j = g_img_rc[name]
    (i-1)*size(IMG_NAMES, 1) + j-1
end

mutable struct SnakePart
    row::Int
    col::Int
    dir::String
    sprite_name::String
end

mutable struct Rabbit
    row::Int
    col::Int
end

mutable struct Snake
    parts::Vector{SnakePart}
    dir_next::String
    move_t_rem::Float32
    move_t::Float32
    function Snake()
        new(Vector{SnakePart}(), "right", 3, 0.2)
    end
end

snake = Snake()
rabbit = Rabbit(0, 0)

function reset_snake()
    empty!(snake.parts)
    row = div(ROWS, 3)
    col = div(COLUMNS, 3)
    for (i, s) in enumerate(["head_right" "horizontal" "tail_right"])
        sp = SnakePart(row, col - i + 1, "right", s)
        push!(snake.parts, sp)
    end
    snake.move_t = 0.2
    snake.move_t_rem = 3
end

reset_snake()

g_keys = Dict()  # GLFW.GetKey did not work for me

snake_img = Images.load(joinpath(common_data_dir, "Snake.png"))

window = GLFW.Window(name="Snake game (Julia, ModernGL, GLAbstraction)", resolution=RESOLUTION)
GLA.set_context!(window)

background_idx = img_idx("grass")
points = Point{3,Float32}[]
for i in 0:ROWS-1, j in 0:COLUMNS-1  # cannot do comprehension, that produces a matrix
    push!(points, (j*SPRITE_HEIGHT, i*SPRITE_WIDTH, background_idx))
end

include("init_utils.jl")



while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    resize!(points, ROWS*COLUMNS)
    push!(points, (rabbit.col*SPRITE_WIDTH, rabbit.row*SPRITE_HEIGHT, img_idx("rabbit")))
    for sp in snake.parts
        push!(points, (sp.col*SPRITE_WIDTH, sp.row*SPRITE_HEIGHT, img_idx(sp.sprite_name)))
    end

    GLA.upload!(vao, pos_img = points)
    vao.nverts = length(points)
    
    GLA.bind(shader_program)
    GLA.bind(vao)
    GLA.draw(vao)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if get(g_keys, GLFW.KEY_ESCAPE, false)
        GLFW.SetWindowShouldClose(window, true)
    end

    if get(g_keys, GLFW.KEY_P, false)
        @Threads.spawn load_play(joinpath("..", "common_data", "die.wav"))
        g_keys[GLFW.KEY_P] = false
    end

    if get(g_keys, GLFW.KEY_K, false)
        @Threads.spawn play(sound_die)
        g_keys[GLFW.KEY_K] = false
    end


    if get(g_keys, GLFW.KEY_O, false)
        #@Threads.spawn play(sound_eat)
        @Threads.spawn load_play(joinpath("..", "common_data", "eat.wav"))
        g_keys[GLFW.KEY_O] = false
    end

    if get(g_keys, GLFW.KEY_L, false)
        @Threads.spawn play(sound_eat)
        #@Threads.spawn load_play(joinpath("..", "common_data", "eat.wav"))
        g_keys[GLFW.KEY_L] = false
    end


    if get(g_keys, GLFW.KEY_X, false)
        snake.parts[1].col += 1
        g_keys[GLFW.KEY_X] = false
    end
    
end
GLFW.DestroyWindow(window)
