package PluginWorkBench

import rl "vendor:raylib"

Result :: enum {
    OK,
    ERROR,
}



u16_array_to_cstring :: proc(chars: []u16, allocator := context.temp_allocator) -> cstring {
    string_size := 0
    
    for char, index in chars {
        if char == 0 {
            break;
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
            break;
        }
        string_size += 1
    }
    
    if string_size == 0 { return "" }
    
    return string16(chars[:string_size])
}


rect_to_i32_args :: proc(rect: rl.Rectangle) -> (i32, i32, i32, i32) {
    return i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)
}
