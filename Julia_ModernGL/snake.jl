
# playing sound in other thread did not work! (only via load_play(Sound))
# GLFW.GetKey did not work for me therefore g_keys::Dict
# uses geometry shader

import Images
using ModernGL, GeometryTypes, GLAbstraction, GLFW

include("audiosystem.jl")

const GLA = GLAbstraction

common_data_dir = joinpath("..", "common_data")

# not working in other thread!
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
const ALL_SQUARES_SET = Set((i, j) for i in 0:ROWS-1, j in 0:COLUMNS-1)

const IMG_NAMES = [
    "head_up" "head_right" "head_down" "head_left";
    "tail_up" "tail_right" "tail_down" "tail_left";
    "turn_1" "turn_2" "turn_3" "turn_4";
    "vertical" "horizontal" "rabbit" "grass"
]

const g_img_rc = Dict(
    IMG_NAMES[i, j] => (i, j) 
    for i in 1:size(IMG_NAMES, 1), j in 1:size(IMG_NAMES, 2))

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

function reset(snake::Snake)
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

function place(rabbit::Rabbit)
    snake_squares = Set((sp.row, sp.col) for sp in snake.parts)
    free_squares = setdiff(ALL_SQUARES_SET, snake_squares)
    rabbit.row, rabbit.col = rand(free_squares)
end

include("init_utils.jl")

begin
    snake = Snake()
    rabbit = Rabbit(0, 0)

    reset(snake)
    place(rabbit)
    

    background_idx = img_idx("grass")
    points = Point{3,Float32}[]
    for i in 0:ROWS-1, j in 0:COLUMNS-1  # cannot do comprehension, that produces a matrix
        push!(points, (j*SPRITE_HEIGHT, i*SPRITE_WIDTH, background_idx))
    end

    t_last = time()
    while !GLFW.WindowShouldClose(window)
        t_now = time()
        dt = t_now - t_last
        global t_last = t_now

        snake.move_t_rem -= dt
        if snake.move_t_rem <= 0
            snake.move_t_rem = snake.move_t
            head_dir = snake.dir_next
            old_head = snake.parts[1]
            row, col = old_head.row, old_head.col
            if head_dir == "left"
                col -= 1
            elseif head_dir == "right"
                col += 1
            elseif head_dir == "up"
                row += 1
            elseif head_dir == "down"
                row -= 1
            else
                error("unknown snake direction")
            end
            
            row = mod(row, 0 : ROWS-1)
            col = mod(col, 0 : COLUMNS-1)
        
            if head_dir == old_head.dir
                img_name = if (head_dir in ("left", "right")) "horizontal" else "vertical" end
            elseif old_head.dir == "down"
                img_name = if head_dir == "left" "turn_4" else "turn_1" end
            elseif old_head.dir == "up"
                img_name = if head_dir == "left" "turn_3" else "turn_2" end
            elseif old_head.dir == "left"
                img_name = if head_dir == "up" "turn_1" else "turn_2" end
            elseif old_head.dir == "right"
                img_name = if head_dir == "up" "turn_4" else "turn_3" end
            else
                error("unknown snake direction")            
            end

            old_head.sprite_name = img_name

            insert!(snake.parts, 1, SnakePart(row, col, head_dir, "head_"*head_dir))
            
            rabbit_eaten = row == rabbit.row && col == rabbit.col
            if !rabbit_eaten
                pop!(snake.parts)
                snake.parts[end].sprite_name = "tail_"*snake.parts[end-1].dir
            else
                snake.move_t -= 0.005
                if snake.move_t < 0.01
                    snake.move_t = 0.01
                end
                # TODO: play(sound_eat): why it freezes the thread????
                @Threads.spawn load_play(joinpath(common_data_dir, "eat.wav"))
                place(rabbit)
            end

            for sp in snake.parts[2:end]
                if row == sp.row && col == sp.col
                    # TODO: play(sound_eat): why it freezes the thread????
                    @Threads.spawn load_play(joinpath(common_data_dir, "die.wav"))
                    reset(snake)
                    place(rabbit)
                end
            end
        end

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

        for key in (GLFW.KEY_UP, GLFW.KEY_KP_8, GLFW.KEY_W)
            if get(g_keys, key, false)
                g_keys[key] = false
                if head_dir != "down"
                    snake.dir_next = "up"
                end
            end
        end

        for key in (GLFW.KEY_DOWN, GLFW.KEY_KP_5, GLFW.KEY_KP_2, GLFW.KEY_W)
            if get(g_keys, key, false)
                g_keys[key] = false
                if head_dir != "up"
                    snake.dir_next = "down"
                end
            end
        end

        for key in (GLFW.KEY_LEFT, GLFW.KEY_KP_4, GLFW.KEY_A)
            if get(g_keys, key, false)
                g_keys[key] = false
                if head_dir != "right"
                    snake.dir_next = "left"
                end
            end
        end

        for key in (GLFW.KEY_RIGHT, GLFW.KEY_KP_6, GLFW.KEY_D)
            if get(g_keys, key, false)
                g_keys[key] = false
                if head_dir != "left"
                    snake.dir_next = "right"
                end
            end
        end

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
end
