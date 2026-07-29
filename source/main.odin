package PluginWorkBench

import "base:runtime"
import intrin "base:intrinsics"

import "core:fmt"
import "core:c"
import "core:os"
import "core:dynlib"
import "core:strings"
import "core:time"
import "core:flags"
import "core:mem"
import vmem "core:mem/virtual"

import vst3 "../deps/vst3_odin/vst3"

import ma "vendor:miniaudio"

Plugin_Host :: struct {

    samplerate: f64, 
    buffer_size: u32, 
    audio_buffer: [2][]f32,

    audio_thread_status: Audio_Thread_Status,
            
    // miniaudio stuff
    audio_device: ma.device,
    wav_decoder: ma.decoder,
    
    // plugin data
    dll_handle: dynlib.Library,
    
    vst_host: Vst_Host,
    clap_host: Clap_Host,

}

Audio_Thread_Status :: enum {
    Stopped,
    Running, 
    RequestToStop,
}

Plugin_Type :: enum {
    Vst,
    Clap, 
    // Faust,
    // OdinPlug,
}

audio_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, nsamples: u32) {    
    context = runtime.default_context()
    
    host := transmute(^Plugin_Host)device.pUserData

    if intrin.atomic_load(&host.audio_thread_status) != .Running { 
        return 
    }

    // audio data is interleaved so we have to convert it before sending it to plugins    
    in_buffer := transmute([^]f32)input
    // for now we only read a wav file so we don't care about the input buffer
    out_buffer := transmute([^]f32)output

    frames_decoded: u64
    read_frames_result := ma.decoder_read_pcm_frames(&host.wav_decoder, raw_data(host.audio_buffer[0]), u64(nsamples), &frames_decoded)
    
    if read_frames_result == .AT_END {
        mem.zero_slice(host.audio_buffer[0][frames_decoded:])
    }


    audio_channels := [][^]f32 { raw_data(host.audio_buffer[0]), raw_data(host.audio_buffer[1]) }
    
    audio_bus := vst3.AudioBusBuffers {
        num_channels = 2,
        silence_flags = 0,
        buffers_32 = raw_data(audio_channels[:])
    }
    
    process_context := vst3.ProcessContext {
        state = 0,
        sample_rate = host.samplerate,
    }
    
    process_data := vst3.ProcessData {
        process_mode = .Realtime,
        symbolic_sample_size = .Sample32,
        num_samples = i32(nsamples),
        num_inputs = 1,
        num_outputs = 1,
        inputs = &audio_bus,
        outputs = &audio_bus,
        inputParameterChanges = nil, //  ^IParameterChanges,
        outputParameterChanges = nil, // ^IParameterChanges,
        input_events = nil, // ^IEventList,
        output_events = nil, // ^IEventList,
        process_context = &process_context,
    }
    
    
    vst_result := host.vst_host.audio_proc->process(&process_data)
    assert(vst_result == .Ok)

    
    for &sample, index in host.audio_buffer[0] {
        sample = clamp(sample, -1.0, 1.0)
    }
    
    copy_slice(host.audio_buffer[1], host.audio_buffer[0])
    
    // interleave audio in output buffer
    for _, index in host.audio_buffer[0] {
        out_buffer[index*2] = host.audio_buffer[0][index]
        out_buffer[index*2 + 1] = host.audio_buffer[1][index]
    }

    if read_frames_result == .AT_END {
        intrin.atomic_store(&host.audio_thread_status, .RequestToStop)
    }
}


from_u16_array_to_string16 :: proc(chars: []u16) -> string16 {
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

main :: proc() {
        
    // assert(len(os.args) >= 2)
    // plugin_path := os.args[1]
    // plugin_path := "../clap/clap_ambient/build/cmake/Debug/clap_ambient.vst3"
    plugin_path := "W:/AmpModeler/build/AmpModeler_artefacts/Debug/VST3/AmpModeler.vst3/Contents/x86_64-win/AmpModeler.vst3"
    
    test_audio_filepath : cstring = "Deliverance2 DI.wav"
    

    /*
        - ce que je veux faire pendant les vacances dans l'ordre pour vst3 : 
        avoir un gui qui load un fichier, qui permet de faire play pause dans la lecture (en laissant tourner le dsp)
        afficher les paramètres du plugin dans un layout générique
        prendre le nom du plugin et du fichier audio dans les arguments de command line
        afficher le gui du plugin
        (avec tout ca j'ai de quoi développer pas mal)
        ploter le signal de sortie 
        
        une fois que je peux faire ca pour vst3, refactorer pour abstraire et refaire avec clap, puis avec Faust ?
        

        grosse struct avec toutes les données
        dans cette struct, les sous-struct dépendant des backends (clap, vst, odin, faust)
        
        - init raylib 
        - if on a un path de plugin dans les arguments {
            load le plugin 
        } else {
            continuer 
        }
        
        - setup miniaudio 
        
        boucle raylib main thread {
        
            afficher l'interface {
                - choix du driver
                - choix de la samplerate si possible         
                - reload du plugin
                - bouton d'affichage de l'interface du plugin {
                    gérer l'initialisation et l'affichage (par glfw ???)
                }
            }
        
            réception des messages depuis le plugin
        
            - tracer l'interface du plugin {
                - pugl 
                - gérer et dispatch les messages pour la fenetres
                
            }
        }
    
        boucle miniaudio real time audio {
            en pause (controlé depuis le main thread)
        
            process simplement l'audio quand on lui dit
        }
        
    */
    
    arena: vmem.Arena
    arena_err := vmem.arena_init_growing(&arena)
    assert(arena_err == nil)
    
    context.allocator = vmem.arena_allocator(&arena)
    defer vmem.arena_destroy(&arena)
    
    host: Plugin_Host
    host.samplerate = 48000.0
    
    ma_result: ma.result

    ma_context: ma.context_type
    ma_result = ma.context_init(nil, 0, nil, &ma_context)
    assert(ma_result == .SUCCESS)
    
    ma_context.backend = .wasapi

    play_back_infos: [^]ma.device_info
    play_back_count: u32
    capture_infos: [^]ma.device_info
    capture_count: u32
    
    ma_result = ma.context_get_devices(&ma_context, &play_back_infos, &play_back_count, &capture_infos, &capture_count)
    assert(ma_result == .SUCCESS)
    
    
    for device_index in 0..<play_back_count {
        fmt.printf("%d - %s\n", device_index, play_back_infos[device_index].name)
    }
    
    device_config := ma.device_config_init(.duplex)
    device_config.capture.format = .f32
    device_config.capture.channels = 2
    device_config.capture.shareMode = .shared
    device_config.playback.format = .f32
    device_config.playback.channels = 2
    device_config.playback.shareMode = .shared
    device_config.sampleRate = u32(host.samplerate)
    device_config.dataCallback = audio_callback
    device_config.pUserData = &host

    ma_result = ma.device_init(nil, &device_config, &host.audio_device)
    assert(ma_result == .SUCCESS)

    host.buffer_size = host.audio_device.playback.internalPeriodSizeInFrames

    host.audio_buffer = { make([]f32, host.buffer_size), make([]f32, host.buffer_size) }
    defer {
        delete(host.audio_buffer[0])
        delete(host.audio_buffer[1])
    }
    
    decoder_config := ma.decoder_config_init(.f32, 1, 48000)
    ma_result = ma.decoder_init_file(test_audio_filepath, &decoder_config, &host.wav_decoder)
    assert(ma_result == .SUCCESS)
    defer ma.decoder_uninit(&host.wav_decoder)


    vst_load_plugin(&host, plugin_path)

    vst_prepare_plugin_process(&host.vst_host, host.samplerate, i32(host.buffer_size))

    when false {
        host.audio_thread_status = .Running    
        ma.device_start(&host.audio_device)
    
    
        for intrin.atomic_load(&host.audio_thread_status) != .RequestToStop {
            time.sleep(100 * time.Millisecond)
        }
        
        host.audio_thread_status = .Stopped
        ma_result = ma.device_stop(&host.audio_device)
    }
    

    {
        // print tous les params
        vst_host := &host.vst_host
        
        num_params := vst_host.editor->get_parameter_count()
        
        for index in 0..<num_params {
            info: vst3.ParameterInfo
            result := vst_host.editor->get_parameter_info(index, &info)
            
            fmt.println(info.id, " - ", 
                        from_u16_array_to_string16(info.title[:]), " - ", 
                        from_u16_array_to_string16(info.short_title[:]), " - ",
                        from_u16_array_to_string16(info.units[:]), " - ", 
                        info.default_normalised_value)
        }
            
    }
    
    vst_close_plugin(&host)

    // closing the device crashes for some reason (may be solved in miniaudio 0.12)
    // so for now we just exit the program and let the OS handle everything
    // ma.device_uninit(&host.audio_device)
    // ma.context_uninit(&ma_context)
}
