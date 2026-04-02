package vst3

import "core:encoding/uuid"

parse_uuid :: proc (id: string) -> (uuid.Identifier, Result) {
    factory_id, err :=  uuid.read (id) 
    when ODIN_OS == .Windows {
        for chunk  in 0..<2 {
            bytes := factory_id[chunk * size_of(u32) : (chunk + 1) * size_of(u32)]
            a := bytes[0]
            b := bytes[1]
            c := bytes[2]
            d := bytes[3]
            if chunk == 0 {
                bytes[0] = d
                bytes[1] = c
                bytes[2] = b
                bytes[3] = a
            } else if chunk == 1 {
                bytes[0] = b
                bytes[1] = a
                bytes[2] = d
                bytes[3] = c
            } 
        }
    }
    if err != nil {
        return {}, .False
    }
    return factory_id, nil
}
