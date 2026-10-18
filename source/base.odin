package PluginWorkBench

import "core:math"

import rl "vendor:raylib"

Result :: enum {
    OK,
    ERROR,
}

u16_array_to_cstring :: proc(chars: []u16, allocator := context.temp_allocator) -> cstring {
    string_size := 0
    
    for char, index in chars {
        if char == 0 {
            break
        }
        string_size += 1
    }
    
    if string_size == 0 { return "" }
    
    str_data := make([]u8, string_size+1)
    
    for &char, index in str_data {
        char = u8(chars[index])
    }
    
    return cstring(raw_data(str_data))
}

u16_array_to_u8_array :: proc(input: []u16, output: []u8) {
    // this is for C wstring (u16 chars) truncation to utf8 for raylib
    
    for char, index in input {
        output[index] = u8(char)
    }
}

u16_array_to_string16 :: proc(chars: []u16) -> string16 {
    string_size := 0
    
    for char, index in chars {
        if char == 0 {
            break
        }
        string_size += 1
    }
    
    if string_size == 0 { return "" }
    
    return string16(chars[:string_size])
}


rect_to_i32_args :: proc(rect: rl.Rectangle) -> (i32, i32, i32, i32) {
    return i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)
}

wrap_index :: proc(n, max: int) -> int {
    return cast(int)math.wrap(cast(f64)n, cast(f64)max)
}

scale :: proc(x, min, max, newmin, newmax, curve: f32) -> f32 {
    return math.pow((x - min) / (max - min), curve) * (newmax - newmin) + newmin
}

atodb :: proc(amp: f32) -> f32 {
    return 20.0 * math.log10(amp)
}

dbtoa :: proc(db: f32) -> f32 {
    return math.pow(10.0, db/20.0)
}

buffer_abs_average :: proc(buffer: []f32) -> f32 {
    sum: f32 = 0.0
    
    for sample in buffer {
        sum += abs(sample)
    }
    
    return sum/f32(len(buffer))
}

buffer_rms :: proc(buffer: []f32) -> f32 {
    sum: f32 = 0.0
    
    for sample in buffer {
        sum += sample*sample
    }
    
    return math.sqrt(sum/f32(len(buffer)))
}

deinterleave_buffers :: proc(input: []f32, output: [][]f32, nchannels: u32) {

    #no_bounds_check for sample_index in 0..<len(output[0]) {
        for channel_index in 0..<nchannels {
           output[channel_index][sample_index] = input[u32(sample_index)*nchannels+channel_index]
        }
    }
}

interleave_buffers :: proc(input: [][]f32, output: []f32, nchannels: u32) {

    #no_bounds_check for sample_index in 0..<len(input[0]) {
        for channel_index in 0..<nchannels {
            output[u32(sample_index)*nchannels + channel_index] = input[channel_index][sample_index]
        }
    }
}
