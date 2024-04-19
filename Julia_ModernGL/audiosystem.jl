import WAV

struct Sound
    fs
    y
    function Sound(filename::String)
        y, fs = WAV.wavread(filename)
        new(fs, y)
    end
end

function play(sound::Sound)
    # BLOCKING, no luck using threads :(
    WAV.wavplay(sound.y, sound.fs)
end

sound_die = Sound(joinpath("..", "common_data", "die.wav"))
sound_eat = Sound(joinpath("..", "common_data", "eat.wav"))
