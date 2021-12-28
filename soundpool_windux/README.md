# soundpool_windux
**WARNING: This plugin is an experimental implementation as it uses FFI to the implementation written in non-native language. Author takes no responsibility for any damage caused by the implementation.**.

A Soundpool plugin implementation for Windows and Linux platforms.
It contains pre-compiled native dynamic libraries for Windows, Linux (and MacOS) systems.
The source code for native implementation is contained in `rust` folder. Instructions on how to build the Rust code to native library can be found below. 
In case of any troubles with building or using the plugin, please, do not hesitate to reach out to me (author). 

### Supported formats:
- MP3, 
- WAV, 
- Vorbis,
- Flac.

### Supported features:
- load
- play
    - with rate (changes the play speed)
- stop
- pause
- resume
- set_volume

### Unsupported features:
- play with repeat (repeat parameter is ignored)
- set rate while playing


---

## Getting Started

### Build steps
1. Install Rust and Cargo following [official instructions](https://www.rust-lang.org/tools/install).
2. Install LLVM required for `ffigen`. See `ffigen` plugin [documentation](https://pub.dev/packages/ffigen#installing-llvm). Update `pubspec.yaml` to match your local environment.
3. (Linux) Install required `libasound2` library with command: `sudo apt-get install libasound2-dev`.
4. In `/` folder run command `cargo build --lib --all-targets --release`.
   1. The compiled native library can be found in `target/release` folder.
   2. The C binding header file is generated in `rust/target` folder.
   3. Dart FFI bindings is generated in `lib/generated_bindings.dart` file.


#### MacOS project setup (experimental, for development)
The "Copy Files" section has to be added to the "Target>Build Phases" that copies the *libs/libsoundpool.dylib* from plugin *macos* folder
