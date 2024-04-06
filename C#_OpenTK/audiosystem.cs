// based on https://github.com/mono/opentk/blob/main/Source/Examples/OpenAL/1.1/Playback.cs
// https://github.com/dang-gun/DotNetTest/blob/main/Net6LinuxTest2/Program.cs
using System;
using System.Runtime.InteropServices;
using OpenTK.Audio;
using OpenTK.Audio.OpenAL;

public class AudioSystem
{
    int[] buffer = {-1, 1}, source = {-1, 1};
    IntPtr[] unmanagedPointer = {0, 0};
    ALDevice device;
    ALContext context;

    public unsafe AudioSystem()
    {
			//Initialize
        device = ALC.OpenDevice(null);
        context = ALC.CreateContext(device, (int*)null);

        ALC.MakeContextCurrent(context);

        var version = AL.Get(ALGetString.Version);
        var vendor = AL.Get(ALGetString.Vendor);
        var renderer = AL.Get(ALGetString.Renderer);
        Console.WriteLine("OpenAL info:");
        Console.WriteLine(version);
        Console.WriteLine(vendor);
        Console.WriteLine(renderer);

        string[] filenames = {"../common_data/die.wav", "../common_data/eat.wav"};
        int channels, bits_per_sample, sample_rate;

        for(int i = 0; i < filenames.Length; i++) {
            buffer[i] = AL.GenBuffer();
            source[i] = AL.GenSource();
            byte[] sound_data = LoadWave(File.Open(filenames[i], FileMode.Open), out channels, out bits_per_sample, out sample_rate);
            unmanagedPointer[i] = Marshal.AllocHGlobal(sound_data.Length);
            Marshal.Copy(sound_data, 0, unmanagedPointer[i], sound_data.Length);            
            AL.BufferData(buffer[i], GetSoundFormat(channels, bits_per_sample), unmanagedPointer[i], sound_data.Length, sample_rate);
            AL.Source(source[i], ALSourcei.Buffer, buffer[i]);
        }

    }
    public void close()
    {
        ALC.DestroyContext(context);
        var success = ALC.CloseDevice(device);
        foreach(IntPtr uP in unmanagedPointer) {
            Marshal.FreeHGlobal(uP);
        }
    }

    // DESTRUCTOR: Marshal.FreeHGlobal(unmanagedPointer);

    public void play_die()
    {
        AL.SourcePlay(source[0]);
    }

    public void play_eat()
    {
        AL.SourcePlay(source[1]);
    }

    // Loads a wave/riff audio file.
    public static byte[] LoadWave(Stream stream, out int channels, out int bits, out int rate)
    {
        if (stream == null)
            throw new ArgumentNullException("stream");

        using (BinaryReader reader = new BinaryReader(stream))
        {
            // RIFF header
            string signature = new string(reader.ReadChars(4));
            if (signature != "RIFF")
                throw new NotSupportedException("Specified stream is not a wave file.");

            int riff_chunck_size = reader.ReadInt32();

            string format = new string(reader.ReadChars(4));
            if (format != "WAVE")
                throw new NotSupportedException("Specified stream is not a wave file.");

            // WAVE header
            string format_signature = new string(reader.ReadChars(4));
            if (format_signature != "fmt ")
                throw new NotSupportedException("Specified wave file is not supported.");

            int format_chunk_size = reader.ReadInt32();
            int audio_format = reader.ReadInt16();
            int num_channels = reader.ReadInt16();
            int sample_rate = reader.ReadInt32();
            int byte_rate = reader.ReadInt32();
            int block_align = reader.ReadInt16();
            int bits_per_sample = reader.ReadInt16();

            string data_signature = new string(reader.ReadChars(4));
            if (data_signature != "data")
                throw new NotSupportedException("Specified wave file is not supported.");

            int data_chunk_size = reader.ReadInt32();

            channels = num_channels;
            bits = bits_per_sample;
            rate = sample_rate;

            return reader.ReadBytes((int)reader.BaseStream.Length);
        }
    }    
    public static ALFormat GetSoundFormat(int channels, int bits)
    {
        switch (channels)
        {
            case 1: return bits == 8 ? ALFormat.Mono8 : ALFormat.Mono16;
            case 2: return bits == 8 ? ALFormat.Stereo8 : ALFormat.Stereo16;
            default: throw new NotSupportedException("The specified sound format is not supported.");
        }
    }        
}

