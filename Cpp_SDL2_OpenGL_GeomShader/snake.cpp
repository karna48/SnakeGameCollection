
/*
    intermediate mode and GL_QUADS are deprecated;
    must use glDrawElements
    must NOT use SDL2 renderer which falls back to OpenGL 2.1

    TODO: SDL_ttf  length label, FPS counter
*/

#include <iostream>
#include <set>
#include <vector>
#include <unordered_map>
#include <string>
#include <random>
#include <algorithm>
#include <chrono>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#if defined(__WIN32__) || defined(__WIN64__)
#   include <glad/glad.h>
#else
#   ifndef GL_GLEXT_PROTOTYPES
#   define GL_GLEXT_PROTOTYPES
#   endif
#endif // defined

#include <SDL.h>
#include <SDL_image.h>
#include <SDL_mixer.h>

#include "audiosystem.h"
#include "loadshader.h"

constexpr int WINDOW_WIDTH = 1200, WINDOW_HEIGHT = 800;
constexpr int SPRITE_IMG_WIDTH = 16, SPRITE_IMG_HEIGHT = 16;
constexpr int SPRITE_SCALE = 5;
constexpr int SPRITE_WIDTH = SPRITE_SCALE * SPRITE_IMG_WIDTH, SPRITE_HEIGHT = SPRITE_SCALE * SPRITE_IMG_HEIGHT;
constexpr int ROWS = WINDOW_HEIGHT / SPRITE_HEIGHT, COLUMNS = WINDOW_WIDTH / SPRITE_HEIGHT;

const std::string DIR_RIGHT{"right"};
const std::string DIR_LEFT{"left"};
const std::string DIR_UP{"up"};
const std::string DIR_DOWN{"down"};

const std::vector<std::vector<std::string>> IMG_NAMES{
    {"head_up", "head_right", "head_down", "head_left"},
    {"tail_up", "tail_right", "tail_down", "tail_left"},
    {"turn_1", "turn_2", "turn_3", "turn_4"},
    {"vertical", "horizontal", "rabbit", "grass"}
};

glm::mat4 setup_opengl( int width, int height );
GLuint load_texture(const std::string &filename);

const auto g_img_rc = [](){
    std::unordered_map<std::string, std::pair<int, int>> img_rc;
    int i = 0;
    for(auto const& names_row : IMG_NAMES)
    {
        int j = 0;
        for(auto const& name : names_row) {
            img_rc[name] = std::pair<int, int>(i, j);
            j++;
        }
        i++;
    }
    return img_rc;
}();

struct SpriteVAO
{
    GLuint points_vertexbuffer, points_vertexarrayobject;

    std::vector<GLfloat> points;

    SpriteVAO()
    {
        glGenBuffers(1, &points_vertexbuffer);
        glGenVertexArrays(1, &points_vertexarrayobject);
    }

    ~SpriteVAO()
    {
        // TODO: delete VAO properly? (... but the app is ending anyway!)
    }
    void next_frame(size_t keep) {
        if(points.size() < keep*3) {
            std::cerr << "ERROR: SpriteVAO::next_frame  points.size() < keep*3" << std::endl;
        }
        points.resize(keep*3);
    }
    void add_point(float x1, float y1, int img_index)
    {
        points.push_back(x1);
        points.push_back(y1);
        points.push_back(img_index);
    }
    void draw()
    {
        // transfer data to VAO object
        glBindVertexArray(points_vertexarrayobject);
        glBindBuffer(GL_ARRAY_BUFFER, points_vertexbuffer);
        glBufferData(GL_ARRAY_BUFFER, points.size()*sizeof(GLfloat), (const void*)points.data(), GL_DYNAMIC_DRAW);

        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, points_vertexbuffer);
        glVertexAttribPointer(
            0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
            3,                  // size;  x,y,img_index
            GL_FLOAT,           // type
            GL_FALSE,           // normalized?
            0,                  // stride
            (void*)0            // array buffer offset
        );

        glDrawArrays(GL_POINTS, 0, points.size()/3);
//        glDrawElements(GL_TRIANGLES, indicies.size(), GL_UNSIGNED_INT, nullptr);

        glDisableVertexAttribArray(0);
    }
};

struct Sprite
{
    float x, y; // corner position
    float img_index;
    Sprite(int row, int column, const std::string& img_name)
    {
        move(row, column);
        set_image(img_name);
    }
    void set_image(const std::string& img_name)
    {
        auto [i, j] = g_img_rc.at(img_name);
        img_index = i * 4 + j;
    }
    void move(int row, int column)
    {
        x = column * SPRITE_WIDTH;
        y = row * SPRITE_HEIGHT;
    }
    void draw(SpriteVAO& sprite_vao)
    {
        sprite_vao.add_point(x, y, img_index);
    }
};

struct SnakePart
{
    int row, col;
    std::string dir;
    Sprite sprite;
    SnakePart(int row, int col, const std::string& dir, const std::string& img_name):
        row(row), col(col), dir(dir), sprite(row, col, img_name)
    {}
};

struct Rabbit
{
    int row, col;
    Sprite sprite;
    Rabbit(int row, int col):
        row(row), col(col), sprite(row, col, "rabbit")
    {}
    void move(int row_, int col_)
    {
        row = row_;
        col = col_;
        sprite.move(row, col);
    }
};

class SnakeGame
{
    std::vector<SnakePart> snake;
    std::vector<Sprite> background;

    float snake_move_t, snake_move_t_rem;
    std::set<std::pair<int, int>> set_all_squares;
    std::string snake_dir_next;
    Rabbit rabbit;

    AudioSystem &audio_system;
    SpriteVAO &sprite_vao;

    std::default_random_engine rnd_generator;
public:
    SnakeGame(AudioSystem &audio_system, SpriteVAO &sprite_vao):
        rabbit(0, 0),
        audio_system(audio_system),
        sprite_vao(sprite_vao),
        rnd_generator(std::chrono::high_resolution_clock::now().time_since_epoch().count())
    {

        for(int i=0; i<ROWS; i++) {
            for(int j=0; j<COLUMNS; j++) {
                background.push_back(Sprite(i, j, "grass"));
                set_all_squares.insert(std::pair<int, int>(i, j));
            }
        }

        reset_snake();
        place_rabbit();
    }

    void place_rabbit()
    {
        std::set<std::pair<int, int>> set_snake_squares;
        for(auto& part : snake) {
            set_snake_squares.insert(std::pair<int, int>(part.row, part.col));
        }
        std::vector<std::pair<int, int>> free_squares(ROWS*COLUMNS);

        // std::set is sorted, don't need to make a copy in std::vector and sort

        auto it=std::set_difference
            (set_all_squares.begin(), set_all_squares.end(),
             set_snake_squares.begin(), set_snake_squares.end(),
             free_squares.begin());

        free_squares.resize(it-free_squares.begin());

        //std::cout << "place_rabbit  free_squares.size(): " << free_squares.size() << "\n";

        if(free_squares.size() > 0) {
            int i = std::uniform_int_distribution<int>(0, free_squares.size()-1)(rnd_generator);
            auto [row, col] = free_squares[i];
            //std::cout << "place_rabbit  i: " << i << "  row: " << row << "  col: " << col << "\n";
            rabbit.move(row, col);
        } else {
            reset_snake();
            place_rabbit();
        }
    }

    void reset_snake()
    {
        snake.clear();
        int i=0;
        int row = ROWS / 3, col = COLUMNS / 3;
        for(auto const& name : {"head_right", "horizontal", "tail_right"}) {
            snake.push_back(SnakePart(row, col-i, DIR_RIGHT, name));
            i++;
        }
        snake_move_t = 0.2;
        snake_dir_next = DIR_RIGHT;
    }

    void draw()
    {
        if(sprite_vao.points.size() == 0) {
            for(auto &sprite : background) {
                sprite.draw(sprite_vao);
            }
        }
        else {
            sprite_vao.next_frame(background.size());
        }

        rabbit.sprite.draw(sprite_vao);

        for(auto &part : snake) {
            part.sprite.draw(sprite_vao);
        }

        sprite_vao.draw();
    }
    void update(float dt)
    {
        snake_move_t_rem -= dt;
        if(snake_move_t_rem <= 0) {
            snake_move_t_rem += snake_move_t;
            int row = snake[0].row;
            int col = snake[0].col;
            std::string head_dir(snake_dir_next);
            if(head_dir == DIR_LEFT) {
                col--;
            } else if(head_dir == DIR_RIGHT) {
                col++;
            } else if(head_dir == DIR_UP) {
                row++;
            }else if(head_dir == DIR_DOWN) {
                row--;
            }
            row %= ROWS;
            col %= COLUMNS;
            if(row < 0) {
                row = ROWS - 1;
            }
            if(col < 0) {
                col = COLUMNS - 1;
            }
            snake.insert(snake.begin(), SnakePart(row, col, head_dir, "head_"+head_dir));
            auto old_dir = snake[1].dir;
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
                snake.pop_back();
                auto &dir = (snake.end()-2)->dir;
                snake.back().sprite.set_image("tail_"+dir);
            } else {
                audio_system.play_eat();
                place_rabbit();
            }

            // test self collision
            for(auto it = snake.begin()+1; it!=snake.end(); it++) {
                if(it->col == col && it->row == row) {
                    audio_system.play_die();
                    reset_snake();
                    place_rabbit();
                    break;
                }
            }
        }
    }

    void key_input(const std::string& dir)
    {
        // enum would be better
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
};

int main(int argc, char *argv[])
{
    if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS)) {
         std::cerr << "SDL initialization failed: " << SDL_GetError() << std::endl;
         return 1;
    }

    SDL_version compiled, linked;

    SDL_VERSION(&compiled);
    SDL_GetVersion(&linked);
    std::cout << "SDL Version:\n";
    std::cout << "      compiled: " << int(compiled.major) << "." << int(compiled.minor) << "." << int(compiled.patch) << "\n";
    std::cout << "        linked: " << int(linked.major) << "." << int(linked.minor) << "." << int(linked.patch) << std::endl;

    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 2 );
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );


    IMG_Init(IMG_INIT_PNG);

    SDL_Window *window = SDL_CreateWindow(
        "Snake game (C++ with SDL2/OpenGL [geometry shader])",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        WINDOW_WIDTH, WINDOW_HEIGHT,
        SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_OPENGL);

    if(!window) {
        std::cerr << "Cannot create window: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    // we need to create context without SDL renderer -> cannot use IMG_LoadTexture
    SDL_GLContext glcontext = SDL_GL_CreateContext(window);
    if(!glcontext) {
        std::cerr << "Cannot create GL context: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_GL_MakeCurrent(window, glcontext);

#   if defined(__WIN32__) || defined(__WIN64__)
    {
        int error_code=gladLoadGLLoader(SDL_GL_GetProcAddress);
        if(error_code <= 0) {
            std::cout << "Failed to initialize GLAD, error code=" << error_code << std::endl;
            return -1;
        }
    }
#   endif

    glm::mat4 projection_matrix = setup_opengl(WINDOW_WIDTH, WINDOW_HEIGHT);
    std::cout << "opengl setup with projection matrix done" << std::endl;

    // we need to create context without SDL2 renderer -> cannot use IMG_LoadTexture
    // because SDL2 renderer uses OpenGL 2.1 and we need modern 3.2 context

    GLuint texture = 0;
    try {
        texture = load_texture("../common_data/Snake.png");
    } catch(const std::exception &e) {
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    GLuint programId = LoadShaders("shader_vertex.glsl", "shader_fragment.glsl", "shader_geom.glsl");
    GLuint uniformProjectionId = glGetUniformLocation(programId, "projection");
    GLuint uniformSpriteSizeId = glGetUniformLocation(programId, "sprite_size");
    GLuint uniformTex0Id = glGetUniformLocation(programId, "tex0");

    if( Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 2048 ) < 0 )
    {
        std::cerr << "Cannot open audio:" << Mix_GetError() << std::endl;
        return 1;
    }

    // TODO: newer SDL2 version has SDL_GetTicks64

    { // game and audio system scope
        AudioSystem audio_system;
        SpriteVAO sprite_vao;
        SnakeGame snake_game(audio_system, sprite_vao);
        Uint32 last_ticks = SDL_GetTicks();
        bool done = false;
        while(!done) {
            SDL_Event event;
            while(SDL_PollEvent(&event)) {

                switch( event.type ) {
                    case SDL_KEYDOWN:
                        std::cout << SDL_GetKeyName(event.key.keysym.sym) << std::endl;
                        switch(event.key.keysym.sym)
                        {
                            case SDLK_LEFT:  snake_game.key_input(DIR_LEFT);  break;
                            case SDLK_RIGHT: snake_game.key_input(DIR_RIGHT);  break;
                            case SDLK_UP:    snake_game.key_input(DIR_UP);  break;
                            case SDLK_DOWN:  snake_game.key_input(DIR_DOWN);  break;
                            case SDLK_ESCAPE:
                                done = true;
                            default:
                                ;
                        }
                        break;
                    case SDL_QUIT:
                        done = true;
                    default:
                        ;
                }
            }

            Uint32 now_ticks = SDL_GetTicks();
            float dt = (now_ticks-last_ticks) / 1000.0f;
            if(now_ticks < last_ticks) {
                // rollover detection, dt is bad
                Uint32 ticks_repaired = now_ticks + (4294967295 - last_ticks);
                dt = ticks_repaired / 1000.0f;
            }

            last_ticks = now_ticks;

            snake_game.update(dt);

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

            glUseProgram(programId); // where it should be ??

            glUniformMatrix4fv(uniformProjectionId, 1, GL_FALSE, &projection_matrix[0][0]);

            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, texture);
            glUniform1i(uniformTex0Id, 0);

            glUniform1f(uniformSpriteSizeId, SPRITE_IMG_WIDTH*SPRITE_SCALE);  // NOTE: assuming is the same as SPRITE_IMG_HEIGHT

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            snake_game.draw();
            SDL_GL_SwapWindow(window);
        }
    }

    SDL_DestroyWindow(window);

    Mix_Quit();
    IMG_Quit();
    SDL_Quit();
    return 0;
}

glm::mat4 setup_opengl( int width, int height )
{
    glCullFace( GL_BACK );
    glFrontFace( GL_CCW );
    glEnable( GL_CULL_FACE );

    glClearColor( 0.7, 0.7, 1, 0 );
    glDepthMask(GL_FALSE);

    glViewport( 0, 0, width, height );

    return glm::ortho<float>(0, width, 0, height, -1, 1);
}

GLuint load_texture(const std::string &filename)
{
    SDL_Surface *surface = IMG_Load(filename.c_str());
    if (!surface) {
        std::cerr << "Cannot load texture:" << IMG_GetError() << std::endl;
        throw  std::runtime_error("cannot open texture file");
    }

    GLuint texture;
    GLenum textureFormat;

    switch (surface->format->BytesPerPixel) {
        case 4:
            if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
                textureFormat = GL_BGRA;
            } else {
                textureFormat = GL_RGBA;
            }
        break;

        case 3:
            if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
                textureFormat = GL_BGR;
            } else {
                textureFormat = GL_RGB;
            }
        break;

        default: {
            std::cerr << "Wrong texture format, bytes per pixel=" << int(surface->format->BytesPerPixel) << std::endl;
            throw std::runtime_error("wrong texture format, wrong Bpp");
        }
    }

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, textureFormat, surface->w, surface->h,
        0, textureFormat, GL_UNSIGNED_BYTE, surface->pixels);

    SDL_FreeSurface(surface);

    return texture;
}
