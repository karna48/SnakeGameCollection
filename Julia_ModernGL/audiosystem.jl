import WAV

struct Sound
    fs
    y
    filename
    function Sound(filename::String)
        y, fs = WAV.wavread(filename)
        new(fs, y, filename)
    end
end

function play(sound::Sound)
    println("start playing ", sound.filename)
    #WAV.wavplay(sound.y, sound.fs)
    sleep(2)
    println("end playing ", sound.filename)
end

function load_play(filename::String)
    y, fs = WAV.wavread(filename)
    WAV.wavplay(y, fs)
end

