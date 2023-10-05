use rustyline::{Editor, DefaultEditor};
use std::fs::File;

use std::io::*;
use std::sync::mpsc;
use std::thread;

mod soundpool;
use crate::soundpool::Soundpool;

fn main() {
    let (tx, rx) = mpsc::channel::<String>();
    println!(
        r#"
    Available commands:
    l (d) - loads audio file (optional d uses "do-you-like-it.wav", "example.mp3" is used otherwise)
    p [sound_id] - plays sound with id of "sound_id"
    s [stream_id] - stops stream "stream_id"
    a [stream_id] - pauses stream "stream_id"
    r [stream_id] - resumes stream "stream_id"
    v [sound_id] [volume] - sets volume for sound of "sound_id"
    d - disposes pool
    q - quit
    "#
    );

    thread::spawn(move || {
        let id = thread::current().id();
        let mut soundpool = Soundpool::new();
        loop {
            let message = rx.recv().unwrap();
            if message.starts_with("q") {
                soundpool.dispose();
                break;
            }
            if message.starts_with("l") {
                let filename = if message.len() > 1 && message[2..].starts_with("d") {
                    "do-you-like-it.wav"
                } else {
                    "example.mp3"
                };
                let mut file = File::open(filename).unwrap();
                // let mut file = File::open("../../soundpool/example/sounds/do-you-like-it.wav").unwrap();

                let mut buf = Vec::new();
                file.read_to_end(&mut buf).unwrap();
                let sound_id = soundpool.load(&buf);
                println!("{:?}: sound loaded: {:?} from {}", id, sound_id, filename);
            }
            if message.starts_with("p") {
                // play?
                let message = &message[2..];
                let mut params = message.split_whitespace();

                let sound_id = params.next().unwrap();
                let sound_id = sound_id.parse::<u32>().unwrap();

                let mut repeat: i32 = 0;
                let mut rate: f32 = 1.0;
                if let Some(next_param) = params.next() {
                    if next_param.starts_with("repeat:") {
                        repeat = next_param
                            .split(":")
                            .nth(1)
                            .unwrap_or_else(|| "0")
                            .parse::<i32>()
                            .unwrap();
                    } else {
                        rate = next_param.parse::<f32>().unwrap();
                    }
                }

                let stream_id = soundpool.play(sound_id, repeat, rate);
                println!("{:?}: playing on stream: {:?}", id, stream_id);
            }
            if message.starts_with("d") {
                soundpool.dispose();
            }
            if message.starts_with("s") {
                let message = &message[2..];
                let stream_id = message.parse::<u32>().unwrap();
                soundpool.stop(stream_id);
            }
            if message.starts_with("v") {
                let message = &message[2..];
                let mut data = message.split_whitespace();
                let first = data.next().unwrap();
                let sound_id = first.parse::<u32>().unwrap();

                let second = data.next().unwrap();
                let volume = second.parse::<f32>().unwrap();
                soundpool.set_volume(sound_id, volume);
            }
            if message.starts_with("a") {
                let message = &message[2..];
                let stream_id = message.parse::<u32>().unwrap();
                soundpool.pause(stream_id);
            }
            if message.starts_with("r") {
                let message = &message[2..];
                let stream_id = message.parse::<u32>().unwrap();
                soundpool.resume(stream_id);
            }
        }
    });
    let mut rl = DefaultEditor::new().unwrap();
    let id = thread::current().id();
    loop {
        let readline = rl.readline(">> ");
        match readline {
            Ok(line) => {
                if tx.send(line).is_err() {
                    println!("{:?} Finishing!", id);
                    break;
                }
            }
            Err(_) => {
                println!("{:?} Finishing!", id);
                break;
            }
        }
    }
}
