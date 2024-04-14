#ifndef AudioSystem_H__
#define AudioSystem_H__

struct AudioSystem
{
    Mix_Chunk *eat, *die;
    AudioSystem():
        eat(Mix_LoadWAV("../common_data/eat.wav")),
        die(Mix_LoadWAV("../common_data/die.wav"))
    {
        if(!eat) {
            std::cerr << "cannot load 'eat' sound!" << std::endl;
        }
        if(!die) {
            std::cerr << "cannot load 'die' sound!" << std::endl;
        }
    }
    ~AudioSystem()
    {
        if(die) { Mix_FreeChunk(die); }
        if(eat) { Mix_FreeChunk(eat); }
    }

    void play_eat()
    {
        Mix_PlayChannel(-1, eat, 0);
    }
    void play_die()
    {
        Mix_PlayChannel(-1, die, 0);
    }
};

#endif  // AudioSystem_H__
