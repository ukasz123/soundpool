use std::fmt::Display;
use std::io::Result;

pub type Callback<T> = Box<dyn Fn(Result<T>) + Send + 'static>;

pub type SoundId = u32;
pub type StreamId = u32;
pub type VolumeValue = f32;

pub enum RequestMessage {
    Load(LoadMessage),
    Play(PlayContent),
    Stop(StreamId),
    StopBySound(SoundId),
    Pause(StreamId),
    Resume(StreamId),
    SetVolume(SoundId, VolumeValue),
    Dispose,
}

impl Display for RequestMessage {
    fn fmt(&self, fmt: &mut std::fmt::Formatter<'_>) -> std::result::Result<(), std::fmt::Error> {
        fmt.write_str(match self {
            RequestMessage::Load(_) => "Load",
            RequestMessage::Play(_) => "Play",
            RequestMessage::Stop(_) => "Stop",
            RequestMessage::StopBySound(_) => "StopBySound",
            RequestMessage::Pause(_) => "Pause",
            RequestMessage::Resume(_) => "Resume",
            RequestMessage::Dispose => "Dispose",
            RequestMessage::SetVolume(_, __) => "SetVolume",
        })
    }
}

pub enum InternalMessages {
    StreamFinished(StreamId),
}

pub struct LoadMessage {
    pub data: Vec<u8>,
    pub callback: Callback<SoundId>,
}
impl LoadMessage {
    pub fn new(data: Vec<u8>, callback: Callback<SoundId>) -> LoadMessage {
        LoadMessage {
            data: data,
            callback: callback,
        }
    }
}
pub struct PlayContent {
    pub sound_id: SoundId,
    pub repeat: i32,
    pub rate: f32,
    pub callback: Callback<StreamId>,
}

impl PlayContent {
    pub fn new(sound_id: SoundId,callback: Callback<StreamId>, repeat: i32, rate: f32) -> PlayContent {
        PlayContent { sound_id: sound_id, callback: callback, repeat: repeat, rate: rate }
    }
    pub fn new_with_defaults(sound_id: SoundId,callback: Callback<StreamId>, repeat: Option<i32>, rate: Option<f32>) -> PlayContent {
        PlayContent::new(sound_id, callback, repeat.unwrap_or(0), rate.unwrap_or(1.0))
    }
    pub fn new_once(sound_id: SoundId) -> PlayContent {
        PlayContent::new_with_defaults(sound_id, Box::new(|_|{}), None, None)
    }
}

#[derive(Debug)]
pub enum StreamControlMessage {
    Pause,
    Resume,
    Stop,
    SetVolume(f32),
}

impl Display for StreamControlMessage {
    fn fmt(&self, fmt: &mut std::fmt::Formatter<'_>) -> std::result::Result<(), std::fmt::Error> {
        fmt.write_str("SCM:")?;
        let name = match self {
            StreamControlMessage::Stop => String::from("Stop"),
            StreamControlMessage::Pause => String::from("Pause"),
            StreamControlMessage::Resume => String::from("Resume"),
            StreamControlMessage::SetVolume(volume) => String::from(format!("SetVolume:{}", volume)),
        };
        let scm_name = &name[..];
        fmt.write_str(&scm_name)
    }
}
