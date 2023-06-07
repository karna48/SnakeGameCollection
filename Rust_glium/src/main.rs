use std::{self, io::Read};
use std::fs::File;
use std::io::{BufReader, Cursor};
use rodio::{Decoder, OutputStream, Source, OutputStreamHandle};


fn play_sound(sample_data: &Vec<u8>, stream_handle: &OutputStreamHandle) {
    // TODO: avoid sample_data.clone
    let cursor = Cursor::new(sample_data.clone());
    let sound_source = Decoder::new(cursor).unwrap();
    stream_handle.play_raw(sound_source.convert_samples()).unwrap();
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

    let mut eat_wav_file = File::open(data_dir.join("eat.wav")).unwrap();
    let mut eat_wav_buf = Vec::new();
    eat_wav_file.read_to_end(&mut eat_wav_buf).unwrap();

    let mut event_loop = glium::glutin::event_loop::EventLoop::new();
    let window_builder = glium::glutin::window::WindowBuilder::new();
    let context_builder = glium::glutin::ContextBuilder::new();
    let display = glium::Display::new(window_builder, context_builder, &event_loop).unwrap();

    //let image = image::load(Cursor::new(&include_bytes!("/path/to/image.png")),
    let image = 
        image::load(
            BufReader::new(File::open(data_dir.join("Snake.png")).unwrap()),
            image::ImageFormat::Png).unwrap().to_rgba8();
    let image_dimensions = image.dimensions();
    let image = glium::texture::RawImage2d::from_raw_rgba_reversed(&image.into_raw(), image_dimensions);

    println!("{}", working_dir.display());
    println!("{:?}", image_dimensions);

    event_loop.run(move |ev, _, control_flow| {
        /*let next_frame_time = std::time::Instant::now() +
            std::time::Duration::from_nanos(16_666_667);
        *control_flow = glutin::event_loop::ControlFlow::WaitUntil(next_frame_time);*/
        match ev {
            glium::glutin::event::Event::WindowEvent { event, .. } => match event {
                glium::glutin::event::WindowEvent::KeyboardInput { device_id, input, .. } => {
                    if input.state == glium::glutin::event::ElementState::Pressed {
                        println!("KeyboardInput pressed scancode {}", input.scancode);

                        if let Some(key) = input.virtual_keycode {
                            println!("VirtualKeyCode {}", key);
                            match key {
                                glium::glutin::event::VirtualKeyCode::S => {
                                    play_sound(&die_wav_buf, &stream_handle);
                                },
                                glium::glutin::event::VirtualKeyCode::X => {
                                    play_sound(&eat_wav_buf, &stream_handle);
                                },
                              _ => {}
                            }
                      }                        
                    }
                },
                glium::glutin::event::WindowEvent::CloseRequested => {
                    *control_flow = glium::glutin::event_loop::ControlFlow::Exit;
                    return;
                },
                _ => return,
            },
            _ => (),
        }
    });
   
}

