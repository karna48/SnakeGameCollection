use std::{self, io::Read};
use std::fs::File;
use std::io::{BufReader, Cursor};
use rodio::{Decoder, OutputStream, Source, OutputStreamHandle};


fn play_sound(sample_data: &Vec<u8>, stream_handle: &OutputStreamHandle) {
    // TODO: avoid sample_data.clone
    let cursor = Cursor::new(sample_data.clone());
    let sound_source = Decoder::new(cursor).unwrap();
    stream_handle.play_raw(sound_source.convert_samples());
}

fn main() {
    // resource locations
    let working_dir_pbf = std::env::current_dir().expect("current working directory should be accessible");
    let working_dir = working_dir_pbf.as_path();
    let data_dir = working_dir.parent().expect("common_data directory should be accessible").join("common_data");

    // sound system
    let (_stream, stream_handle) = OutputStream::try_default().unwrap();

    let mut die_wav_file = File::open(data_dir.join("die.wav")).unwrap();
    let mut die_wav_buf = Vec::new();
    die_wav_file.read_to_end(&mut die_wav_buf).unwrap();

    //let image = image::load(Cursor::new(&include_bytes!("/path/to/image.png")),
    let image = 
        image::load(
            BufReader::new(File::open(data_dir.join("Snake.png")).unwrap()),
            image::ImageFormat::Png).unwrap().to_rgba8();
    let image_dimensions = image.dimensions();
    let image = glium::texture::RawImage2d::from_raw_rgba_reversed(&image.into_raw(), image_dimensions);

    play_sound(&die_wav_buf, &stream_handle);

    std::thread::sleep(std::time::Duration::from_secs(5));

    play_sound(&die_wav_buf, &stream_handle);

    std::thread::sleep(std::time::Duration::from_secs(5));

    println!("{}", working_dir.display());
    println!("{:?}", image_dimensions);
/*     println!("{}", die_sound_source.);
    println!("{}", eat_sound_source.display());
    println!("{}", image.display());
    */
    
}

