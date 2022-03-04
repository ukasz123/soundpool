mod message;
use crate::soundpool::message::*;
use crate::soundpool::InternalMessages::StreamFinished;
use crate::soundpool::RequestMessage::*;
use rodio::source::SamplesConverter;
use rodio::Decoder;
use rodio::OutputStream;
use rodio::Source;
use std::collections::HashMap;
use std::io::Cursor;
use std::iter::FromIterator;
use std::sync::mpsc;
use std::sync::mpsc::Receiver;
use std::sync::mpsc::Sender;
use std::sync::Arc;
use std::sync::Mutex;
use std::thread;
use std::thread::JoinHandle;
use std::time::Duration;

const RECEIVE_WAITING_TIMEOUT: Duration = Duration::from_millis(16);

#[repr(C)]
pub struct Soundpool {
    handle: JoinHandle<()>,
    tx: Sender<RequestMessage>,
}
impl Drop for Soundpool {
    fn drop(&mut self) {
        println!("dropping Soundpool with sounds");
    }
}

impl std::fmt::Debug for Soundpool {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Soundpool").finish()
    }
}

fn pool_event_loop(rx: Receiver<RequestMessage>) {
    let mut sounds = HashMap::<u32, Arc<Sound>>::new();
    let mut streams_tx = HashMap::<u32, Stream>::new();
    let (internal_tx, internal_rx) = mpsc::channel::<InternalMessages>();
    loop {
        if let Ok(message) = rx.recv_timeout(RECEIVE_WAITING_TIMEOUT * 5) {
            match message {
                Dispose => {
                    println!("disposing the pool thread!");
                    for stream_id in streams_tx.keys() {
                        stop(*stream_id, &streams_tx);
                    }
                    break;
                }
                Load(m) => {
                    load(&mut sounds, m);
                }
                Play(content) => {
                    play(
                        &sounds,
                        content.sound_id,
                        content.callback,
                        &mut streams_tx,
                        &internal_tx,
                        content.repeat,
                        content.rate,
                    );
                }
                StopBySound(sound_id) => {
                    for (stream_id, s) in &streams_tx {
                        if s.sound_id == sound_id {
                            stop(*stream_id, &streams_tx)
                        }
                    }
                }
                Stop(stream_id) => {
                    println!("stop triggered for {}", stream_id);
                    stop(stream_id, &streams_tx);
                }
                Pause(stream_id) => {
                    println!("pause triggered for {}", stream_id);
                    pause(stream_id, &streams_tx);
                }
                Resume(stream_id) => {
                    println!("resume triggered for {}", stream_id);
                    resume(stream_id, &streams_tx);
                }
                SetVolume(sound_id, volume) => {
                    set_volume(&mut sounds, &streams_tx, sound_id, volume);
                }
            }
        }
        if let Ok(internal_message) = internal_rx.recv_timeout(RECEIVE_WAITING_TIMEOUT) {
            match internal_message {
                StreamFinished(stream_id) => {
                    if let Some(_) = streams_tx.remove(&stream_id) {
                        //TODO cleanup maybe?
                        println!("Removed stream {}", stream_id);
                    }
                }
            }
        }
    }
}
fn load(sounds: &mut HashMap<u32, Arc<Sound>>, load: LoadMessage) {
    println!("in load");
    let buf = load.data;
    let mut vector: Vec<u8> = Vec::with_capacity(buf.len());
    vector.resize(buf.len(), 0);
    vector.clone_from(&buf);
    let sound_id = match sounds.keys().max() {
        Some(id) => id + 1,
        _ => 1,
    };
    let sound = Sound::new(vector, 1.0);
    sounds.insert(sound_id, Arc::new(sound));
    println!("in load returning {}", sound_id);
    let cb = load.callback;
    cb(Ok(sound_id));
}

fn play(
    sounds: &HashMap<u32, Arc<Sound>>,
    id: SoundId,
    callback: Callback<StreamId>,
    streams_tx: &mut HashMap<u32, Stream>,
    internal_tx: &Sender<InternalMessages>,
    _repeat: i32,
    rate: f32,
) {
    let cached = &sounds.get(&id);
    if let Some(cached) = cached {
        println!("Trying to play the sound {}", id);
        let stream_id = match streams_tx.keys().max() {
            Some(id) => id + 1,
            _ => 1,
        };
        let internal_tx_clone = internal_tx.clone();
        let (tx, rx) = mpsc::channel::<StreamControlMessage>();
        let cached = Arc::clone(cached);
        let _handle = thread::spawn(move || {
            let cursor = cached.cursor();
            let (_stream, stream_handle) = OutputStream::try_default().unwrap();
            let sink = rodio::Sink::try_new(&stream_handle).unwrap();
            let id = thread::current().id();
            let decoder = Decoder::new(cursor).unwrap();
            let samples: SamplesConverter<Decoder<Cursor<Vec<u8>>>, i16> =
                decoder.convert_samples();

            //TODO: figure out how to play repeated sounds
            // let repeated_sound = if repeat == -1 {
            //     samples.repeat_infinite()
            // } else {
            //     samples
            // }
            let source = samples.speed(rate);
            sink.append(source);
            sink.play();
            {
                let volume = *cached.volume.lock().unwrap();
                sink.set_volume(volume);
            }

            println!("{:?} Sound played: {:?}", id, !sink.is_paused());
            loop {
                if let Ok(message) = rx.recv_timeout(RECEIVE_WAITING_TIMEOUT) {
                    //TODO match
                    match message {
                        StreamControlMessage::Stop => {
                            println!("{:?} Stoping sound on stream {:?}", id, stream_id);
                            sink.stop();
                        }
                        StreamControlMessage::SetVolume(volume) => {
                            sink.set_volume(volume);
                        }
                        StreamControlMessage::Pause => {
                            sink.pause();
                        }
                        StreamControlMessage::Resume => {
                            sink.play();
                        }
                    }
                }
                if sink.empty() {
                    println!("{:?} Finishing playing sound on stream {:?}", id, stream_id);
                    internal_tx_clone.send(StreamFinished(stream_id)).unwrap();
                    break;
                }
            }
        });
        let stream = Stream {
            tx,
            handle: _handle,
            sound_id: id,
        };
        streams_tx.insert(stream_id, stream);
        callback(Ok(stream_id))
    } else {
        callback(Ok(0))
    }
}

fn send_stream_strl_message(
    stream_id: u32,
    streams_tx: &HashMap<u32, Stream>,
    message: StreamControlMessage,
) -> Option<()> {
    let stream = streams_tx.get(&stream_id);
    if let Some(stream) = stream {
        let info = format!("{}", &message);
        match stream.tx.send(message) {
            Ok(_) => Some(()),
            Err(_) => {
                eprintln!("Error sending message {} to {}", info, stream_id);
                None
            }
        }
    } else {
        None
    }
}

fn stop(stream_id: u32, streams_tx: &HashMap<u32, Stream>) {
    send_stream_strl_message(stream_id, streams_tx, StreamControlMessage::Stop);
}

fn pause(stream_id: u32, streams_tx: &HashMap<u32, Stream>) {
    send_stream_strl_message(stream_id, streams_tx, StreamControlMessage::Pause);
}
fn resume(stream_id: u32, streams_tx: &HashMap<u32, Stream>) {
    send_stream_strl_message(stream_id, streams_tx, StreamControlMessage::Resume);
}

fn set_volume(
    sounds: &mut HashMap<u32, Arc<Sound>>,
    streams_tx: &HashMap<u32, Stream>,
    sound_id: SoundId,
    volume: VolumeValue,
) {
    let cached = Arc::clone(&sounds[&sound_id]);
    {
        let mut v = cached.volume.lock().unwrap();
        *v = volume;
    }
    println!("Trying to set volume for the sound {}", sound_id);
    for (_, stream) in streams_tx {
        if stream.sound_id == sound_id {
            let tx = &stream.tx;
            tx.send(StreamControlMessage::SetVolume(volume)).unwrap();
        }
    }
}

struct Sound {
    data: Vec<u8>,
    volume: Mutex<VolumeValue>,
}

impl Sound {
    fn new(data: Vec<u8>, volume: VolumeValue) -> Sound {
        Sound {
            data: data,
            volume: Mutex::new(volume),
        }
    }
    fn cursor(self: &Self) -> Cursor<Vec<u8>> {
        Cursor::new(self.data.clone())
    }

    fn decoder(self: &Self) -> rodio::Decoder<Cursor<Vec<u8>>> {
        rodio::Decoder::new(self.cursor()).unwrap()
    }
}

impl AsRef<[u8]> for Sound {
    fn as_ref(&self) -> &[u8] {
        &self.data
    }
}

#[derive(Debug)]
struct Stream {
    tx: Sender<StreamControlMessage>,
    handle: JoinHandle<()>,
    sound_id: SoundId,
}

impl Soundpool {
    pub fn new() -> Soundpool {
        let (tx, rx) = mpsc::channel::<RequestMessage>();
        let thread_handle = thread::spawn(move || pool_event_loop(rx));
        Soundpool {
            handle: thread_handle,
            tx: tx,
        }
    }

    pub fn load(&mut self, buf: &[u8]) -> u32 {
        let (tx_answer, rx_answer) = mpsc::channel();

        let callback: Callback<SoundId> = Box::new(move |result| {
            tx_answer.send(result).unwrap();
        });

        let vector = Vec::from_iter(buf.iter().cloned());

        self.tx
            .send(Load(LoadMessage::new(vector, callback)))
            .unwrap();
        if let Ok(id) = rx_answer.recv() {
            if let Ok(id) = id {
                return id;
            }
        }
        0
    }

    pub fn play_once(&self, index: SoundId) -> u32 {
        self.play(index, 0, 1.0)
    }

    pub fn play(&self, index: SoundId, repeat: i32, rate: f32) -> u32 {
        let (tx_answer, rx_answer) = mpsc::channel();

        let callback: Callback<SoundId> = Box::new(move |result| {
            tx_answer.send(result).unwrap();
        });

        self.tx
            .send(Play(PlayContent::new(index, callback, repeat, rate)))
            .unwrap();
        if let Ok(id) = rx_answer.recv() {
            if let Ok(id) = id {
                return id;
            }
        }
        0
    }

    pub fn stop(&self, stream_id: StreamId) {
        self.tx.send(Stop(stream_id)).unwrap();
    }

    pub fn stop_by_sound(&self, sound_id: SoundId) {
        self.tx.send(Stop(sound_id)).unwrap();
    }

    pub fn pause(&self, stream_id: StreamId) {
        self.tx.send(Pause(stream_id)).unwrap();
    }

    pub fn resume(&self, stream_id: StreamId) {
        self.tx.send(Resume(stream_id)).unwrap();
    }

    pub fn dispose(&self) {
        self.tx.send(Dispose).unwrap();
    }

    pub fn set_volume(&self, sound_id: SoundId, value: VolumeValue) {
        self.tx.send(SetVolume(sound_id, value)).unwrap();
    }
}
