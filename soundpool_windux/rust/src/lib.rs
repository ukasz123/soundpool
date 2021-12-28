use crate::soundpool::*;
use std::mem;
use std::os::raw::c_void;

#[no_mangle]
pub extern "C" fn load_buffer(pool_ptr: *mut c_void, buf: *mut u8, length: usize) -> u32 {
    println!("in load_buffer <- {:?}, {:?}", pool_ptr, length);
    let mut pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    let slice_buf = unsafe { std::slice::from_raw_parts_mut(buf, length) };

    let id = pool.load(slice_buf);

    mem::forget(pool);
    id
}

#[no_mangle]
pub extern "C" fn play(pool_ptr: *mut c_void, index: u32, repeat: i32, rate: f32) -> u32 {
    let pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    let result = pool.play(index, repeat, rate);

    mem::forget(pool);

    result
}

#[no_mangle]
pub extern "C" fn stop(pool_ptr: *mut c_void, stream_index: u32) {
    let pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    pool.stop(stream_index);

    mem::forget(pool);
}

#[no_mangle]
pub extern "C" fn stop_by_sound_id(pool_ptr: *mut c_void, sound_id: u32) {
    let pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    pool.stop_by_sound(sound_id);

    mem::forget(pool);
}

#[no_mangle]
pub extern "C" fn pause(pool_ptr: *mut c_void, index: u32) {
    let pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    pool.pause(index);

    mem::forget(pool);
}

#[no_mangle]
pub extern "C" fn resume(pool_ptr: *mut c_void, index: u32) {
    let pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    pool.resume(index);

    mem::forget(pool);
}

#[no_mangle]
pub extern "C" fn destroy_sink(sink_ptr: *mut c_void) {
    let _ = unsafe { Box::from_raw(sink_ptr as *mut rodio::Sink) };
}

#[no_mangle]
pub extern "C" fn create_pool() -> *mut c_void {
    let pool = Soundpool::new();
    let boxed_pool = Box::new(pool);
    let pointer = Box::into_raw(boxed_pool);
    println!("Returning a pointer: {:?}", pointer);
    pointer as *mut c_void
}

#[no_mangle]
pub extern "C" fn destroy_pool(pool_ptr: *mut c_void) {
    println!("Destroying a pool");
    let _ = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };
}

#[no_mangle]
pub extern "C" fn set_volume(pool_ptr: *mut c_void, index: u32, volume: f32) {
    println!("Setting volume for sound {} to {}", index, volume);
    let pool = unsafe { Box::from_raw(pool_ptr as *mut Soundpool) };

    pool.set_volume(index, volume);

    mem::forget(pool);
}

mod soundpool;
