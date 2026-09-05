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
import rl "vendor:raylib"

import "asio"

/*
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

Plugin_Host :: struct {

    samplerate: f64, 
    buffer_size: u32, 
    audio_buffer: [2][]f32,

    audio_thread_status: ma.device_state,
    audio_file_status: Audio_File_Playback_Status,            
    // miniaudio stuff
    audio_device: ma.device,
    wav_decoder: ma.decoder,
    
    // plugin data
    dll_handle: dynlib.Library,
    
    vst_host: Vst_Host,
    clap_host: Clap_Host,
    
    parameters: []Parameter,
    param_event_fifo: EventFIFO,
}

Parameter :: struct {
    min: f64,                   // clap/Faust only
    max: f64,                   // clap/Faust only
    default_value: f64,
    default_value_norm: f64,    // VST3 only
    current_value: f32,         
    current_value_norm: f32,    // VST3 only
    step_count: i32,             // VST3 only
    id: u32,
    
    label: cstring, 
    unit: cstring,    // VST3 only
}

ParameterEvent :: struct {
    param_id: u32,
    value: f64,
}

FIFO_SIZE :: 64
EventFIFO :: struct {
    events: [FIFO_SIZE]ParameterEvent,
    head: i32,
    tail: i32
}

Asio_Backend :: struct {
    
    asio_callbacks: asio.Callbacks,
    buffer_infos: []asio.BufferInfo,

    miniaudio_context: ma.context_type,

    driver_names: [8]cstring,
    ndrivers: i32,

    audio_device: ^ma.device,
    input_interleaved_buffer: []u8,
    output_interleaved_buffer: []u8,
    
    sample_format: ma.format,
    ninput_channels: i32,
    noutput_channels: i32,
    samplerate: f64,
    frame_size_bytes: i32,
    block_size: i32,
}

// Audio_Thread_Status :: enum {
//     Stopped,
//     Running, 
//     RequestToStop,
// }

Audio_File_Playback_Status :: enum {
    Stopped, 
    Paused,
    Playing,
    RequestRewind
}

Plugin_Type :: enum {
    Vst,
    Clap, 
    // Faust,
    // OdinPlug,
}



main_allocator: runtime.Allocator 
audio_allocator: runtime.Allocator


set_odin_context :: proc "contextless" () -> runtime.Context {
    context = runtime.default_context()
    context.allocator = main_allocator
    
    return context
}

init_miniaudio_device :: proc(host: ^Plugin_Host, samplerate: f64, buffer_size: u32) -> ma.result {

    device_config := ma.device_config_init(.duplex)
    device_config.capture.format = .f32
    device_config.capture.channels = 2
    device_config.capture.shareMode = .shared
    device_config.playback.format = .f32
    device_config.playback.channels = 2
    device_config.playback.shareMode = .shared
    device_config.sampleRate = u32(samplerate)
    device_config.periodSizeInFrames = buffer_size
    device_config.dataCallback = main_audio_procedure
    device_config.pUserData = host

    ma_result := ma.device_init(&asio_backend.miniaudio_context, &device_config, &host.audio_device)
    assert(ma_result == .SUCCESS)
    
    return ma_result
}

stop_audio_stream :: proc(host: ^Plugin_Host) {
    host.audio_thread_status = .stopping
    ma.device_stop(&host.audio_device)
    host.audio_thread_status = .stopped
}

destroy_audio_stream :: proc(host: ^Plugin_Host) {
    host.audio_thread_status = .stopping
    ma.device_uninit(&host.audio_device)
    host.audio_thread_status = .stopped    
}

main_audio_procedure :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, nsamples: u32) {    
    context = runtime.default_context()
        
    host := transmute(^Plugin_Host)device.pUserData

    thread_status := intrin.atomic_load(&host.audio_thread_status)
    audio_file_status := intrin.atomic_load(&host.audio_file_status)

    if thread_status != .started { 
        return 
    }

    // audio data is interleaved so we have to convert it before sending it to plugins    
    in_buffer := transmute([^]f32)input
    // for now we only read a wav file so we don't care about the input buffer
    out_buffer := transmute([^]f32)output
    
    when true {
        frames_decoded: u64
    
        if audio_file_status == .RequestRewind {
            result := ma.decoder_seek_to_pcm_frame(&host.wav_decoder, 0)
            
            if result == .SUCCESS {
                audio_file_status = .Playing
                intrin.atomic_store(&host.audio_file_status, audio_file_status)
            }
        }
        
        mem.zero_slice(host.audio_buffer[0])
        mem.zero_slice(host.audio_buffer[1])
        
        read_frames_result: ma.result
        if audio_file_status == .Playing {
            read_frames_result = ma.decoder_read_pcm_frames(&host.wav_decoder, raw_data(host.audio_buffer[0]), u64(nsamples), &frames_decoded)
        }
    
        if read_frames_result == .AT_END {
            intrin.atomic_store(&host.audio_file_status, audio_file_status)
            audio_file_status = .Stopped
            mem.zero_slice(host.audio_buffer[0][frames_decoded:])
        }
    } else {
    
        for index in 0..<nsamples {
            host.audio_buffer[0][index] = in_buffer[index*2]
            host.audio_buffer[1][index] = in_buffer[index*2+1]
        } 
        
    }
    
    

    // input parameter changes
    
    param_changes: Vst_Parameter_Changes
    param_changes.interface.vtbl = &parameter_changes_vtbl
    param_changes.param_count = 0
    
    param_fifo := &host.param_event_fifo
    fifo_head := intrin.atomic_load(&param_fifo.head)
    fifo_tail := intrin.atomic_load(&param_fifo.tail)
                
    parameter_events_transfer_scope: {
        for fifo_tail != fifo_head {
            
            event := &param_fifo.events[fifo_tail]
            
            value_queue_index := 0
            for (param_changes.param_queues[value_queue_index].parameter_id != event.param_id
                && param_changes.param_queues[value_queue_index].parameter_id != 0)
            {
                value_queue_index += 1
                if value_queue_index == VALUE_QUEUE_LENGTH {
                    break parameter_events_transfer_scope
                }
            }
            
            param_queue := &param_changes.param_queues[value_queue_index]
            param_queue.interface.vtbl = &param_value_queue_vtbl
            param_queue.parameter_id = event.param_id
            
            if param_queue.index < len(param_queue.points) {
                param_queue.points[param_queue.index] = event.value
                param_queue.index += 1
            }
            
            fifo_tail += 1
            fifo_tail &= (FIFO_SIZE-1)
        }
    }
    
    intrin.atomic_store(&param_fifo.tail, fifo_tail)

    for &queue, _ in param_changes.param_queues {
        if queue.parameter_id != 0 {
            param_changes.param_count += 1
        }
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
        inputParameterChanges = &param_changes.interface, //  ^IParameterChanges,
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
    for index in 0..<nsamples {
        out_buffer[index*2] = host.audio_buffer[0][index]
        out_buffer[index*2 + 1] = host.audio_buffer[1][index]
    }
}


asio_backend: Asio_Backend

switch_asio_buffers :: proc "c" (doubleBufferIndex: c.long, directProcess: asio.Bool) {}

switch_asio_buffers_with_time_info :: proc "c" (params: ^asio.Time, doubleBufferIndex: c.long, directProcess: asio.Bool) -> ^asio.Time { 
    // callback audio principal si kAsioSupportsTimeInfo == true
    return nil 
}

asio_samplerate_did_change :: proc "c" (samplerate: asio.SampleRate) {
    asio_backend.samplerate = f64(samplerate)
}

process_asio_message :: proc "c" (selector: asio.MessageSelector, value: c.long, message: rawptr, opt: ^f64) -> c.long { 
    context = set_odin_context()
    
    switch selector {
        case .SelectorSupported: { 
                    
            #partial switch asio.MessageSelector(value) {
                case .EngineVersion, .ResetRequest, .SupportsTimeInfo, .SupportsInputMonitor: {
                    return 1
                }
                case: { return 0 }
            }
        }
        case .EngineVersion: { return 2 }
        case .ResetRequest: { 
            unimplemented()
            // return 1 
        }
        case .BufferSizeChange: { return 0 }
        case .ResyncRequest: { return 0 }
        case .LatenciesChanged: { return 1 }
        case .SupportsTimeInfo: { return c.long(true) }
        case .SupportsTimeCode: { return 0 }
        case .MMCCommand: { unimplemented("unused by the asio API") }
        case .SupportsInputMonitor: { return 1 }
        case .SupportsInputGain: { unreachable() }
        case .SupportsInputMeter: { unreachable() }
        case .SupportsOutputGain: { unreachable() }
        case .SupportsOutputMeter: { unreachable() }
        case .Overload: { return c.long(true) }
        case: {}
    }
    
    return 0 
} 


// Asio va appeler le callback de process, dedans on appelle ma.device_handle_backend_data_callback
// qui ensuite va appeler la fonction de process miniaudio qu'on passe au device_config
init_asio_backend_context :: proc "c" (pContext: ^ma.context_type, pConfig: ^ma.context_config, callbacks: ^ma.backend_callbacks) -> ma.result {
    // le passer au context_config.custom.oncontextinit
    // ici on init le driver ASIO, et on récupère tous les devices dispos
    context = set_odin_context()
        
    asio.asioDrivers = asio.driversAllocate()
    
    for &name in asio_backend.driver_names {
        name = cstring(raw_data(make([]u8, 32)))
    }
    
    asio_backend.ndrivers = asio.getDriverNames(asio.asioDrivers, raw_data(asio_backend.driver_names[:]), len(asio_backend.driver_names))
    
    
    callbacks.onContextInit             = init_asio_backend_context
    callbacks.onContextUninit           = uninit_asio_backend_context
    callbacks.onContextEnumerateDevices = enumerate_asio_devices
    callbacks.onContextGetDeviceInfo    = get_asio_context_device_info
    callbacks.onDeviceInit              = init_asio_device
    callbacks.onDeviceUninit            = uninit_asio_device
    callbacks.onDeviceStart             = start_asio_device
    callbacks.onDeviceStop              = stop_asio_device
        
    return .SUCCESS 
}

uninit_asio_backend_context :: proc "c" (pContext: ^ma.context_type) -> ma.result {
    context = set_odin_context()
        
    asio.driversDestroy(asio.asioDrivers)
    asio.asioDrivers = nil
    
    return .SUCCESS 
}

enumerate_asio_devices :: proc "c" (pContext: ^ma.context_type, enum_callback: ma.enum_devices_callback_proc, pUserData: rawptr) -> ma.result {
    // donner les devices récupérés dans onContextInit
    context = set_odin_context()
    
    for driver_index in 0..<asio_backend.ndrivers {
        
        type := ma.device_type.playback
        info: ma.device_info
        
        name := asio_backend.driver_names[driver_index]
        
        mem.copy(raw_data(info.id.custom.s[:]), transmute([^]u8)name, len(name))
        mem.copy(raw_data(info.name[:]), transmute([^]u8)name, len(name))
        result := enum_callback(pContext, type, &info, pUserData)
        
        if !result { break }
    }
    
    return .SUCCESS 
}

get_asio_context_device_info :: proc "c" (ma_context: ^ma.context_type, device_type: ma.device_type, device_id: ^ma.device_id, device_info: ^ma.device_info) -> ma.result {
    
    context = set_odin_context()
    
    if asio_backend.audio_device == nil { return .NO_DEVICE }

    mem.zero_item(device_info)
    
    if !asio.getCurrentDriverName(&asio.asioDrivers, cstring(raw_data(device_info.name[:]))) { return .NO_DEVICE }
    
    device_info.nativeDataFormatCount = 1
    // device_info.nativedataFormats[0] = { format = .f32, channels = 2}

    return .SUCCESS 
}

init_asio_device :: proc "c" (device: ^ma.device, config: ^ma.device_config, playback_descriptor, capture_descriptor: ^ma.device_descriptor) -> ma.result {
    // ici on initialise tout ce qu'on peut du moteur asio 
    // Init,  ASIOCreateBuffers
    
    context = set_odin_context()
    
    asio_error: asio.Error

    driver_info: asio.DriverInfo
    driver_info.sysRef = asio_backend.miniaudio_context.dsound.hWnd
        
    fmt.printf("asioVersion:   %d\n driverVersion: %d\n Name:          %s\n ErrorMessage:  %s\n",
               driver_info.asioVersion, driver_info.driverVersion,
               string(driver_info.name[:]), string(driver_info.errorMessage[:]))
    

    driver_name := asio_backend.driver_names[3]

    if !asio.loadDriver(asio.asioDrivers, driver_name) { return .ERROR }
    
    if asio.Init(&driver_info) != .OK {
        asio.Exit()
        return .ERROR
    }

    if asio.GetChannels(&asio_backend.ninput_channels, &asio_backend.noutput_channels) != .OK {
        asio.Exit()
        return .ERROR
    }
    
    min_size, max_size, preffered_size, granularity: i32
    if asio.GetBufferSize(&min_size, &max_size, &preffered_size, &granularity) != .OK {
        asio.Exit()
        return .ERROR
    }
    
    asio_backend.block_size = min_size
    
    samplerate := f32(config.sampleRate)
    if asio.SetSampleRate(samplerate) != .OK {
        asio.Exit()
        return .ERROR
    }
    
    asio_backend.samplerate = f64(samplerate)
    
    if asio.GetSampleRate(&samplerate) == .OK && samplerate > 0.0 {
        asio_backend.samplerate = f64(samplerate)
    }
    
    fmt.println("Asio samplerate at init time: ", asio_backend.samplerate, "Hz")
    
    
    channel_info: asio.ChannelInfo;
    asio.GetChannelInfo(&channel_info)
    
    switch channel_info.type {
    
        case .Int16MSB, .Int16LSB: {
            asio_backend.frame_size_bytes = 2
            asio_backend.sample_format = .s16
        }
        case .Int24MSB, .Int24LSB: {
            asio_backend.frame_size_bytes = 3
            asio_backend.sample_format = .s24
        }
        case .Int32MSB, .Int32MSB16..=.Int32MSB24, .Int32LSB, .Int32LSB16..=.Int32LSB24: {
            asio_backend.frame_size_bytes = 4
            asio_backend.sample_format = .s32
        }
        
        case .Float32MSB, .Float32LSB: {
            asio_backend.frame_size_bytes = 4
            asio_backend.sample_format = .f32
        }

        case .Float64MSB, .Float64LSB, .DSDInt8LSB1, .DSDInt8MSB1, .DSDInt8NER8: {
            panic("Does not support 64 bit and DSDInt samples")
        }
    }
    
    total_num_channels := asio_backend.ninput_channels + asio_backend.noutput_channels
    
    asio_backend.buffer_infos = make([]asio.BufferInfo, total_num_channels)
    
    
    for index in 0..<asio_backend.ninput_channels {
        buffer := &asio_backend.buffer_infos[index]
        
        buffer.isInput = asio.True
        buffer.channelNum = index
        buffer.buffers = {nil, nil}
    }
    
    for index in 0..<asio_backend.noutput_channels {
        buffer := &asio_backend.buffer_infos[index + asio_backend.ninput_channels]

        buffer.isInput = asio.False
        buffer.channelNum = index
        buffer.buffers = {nil, nil}
    }
        
    asio_backend.asio_callbacks.bufferSwitch = switch_asio_buffers
    asio_backend.asio_callbacks.sampleRateDidChange = asio_samplerate_did_change
    asio_backend.asio_callbacks.asioMessage = process_asio_message
    asio_backend.asio_callbacks.bufferSwitchTimeInfo = switch_asio_buffers_with_time_info
    
    if asio.CreateBuffers(raw_data(asio_backend.buffer_infos[:]), total_num_channels, 
                         asio_backend.block_size, &asio_backend.asio_callbacks) != .OK
    {
        asio.DisposeBuffers()
        asio.Exit()
        return .ERROR
    }

    asio_backend.input_interleaved_buffer = make([]u8, asio_backend.block_size * asio_backend.frame_size_bytes * asio_backend.ninput_channels)

    capture_descriptor.format = asio_backend.sample_format
    capture_descriptor.channels = cast(u32)asio_backend.ninput_channels
    capture_descriptor.sampleRate = cast(u32)asio_backend.samplerate
    capture_descriptor.periodSizeInFrames = cast(u32)asio_backend.block_size
    
    ma.channel_map_init_standard(.default, raw_data(capture_descriptor.channelMap[:]), ma.MAX_CHANNELS, cast(u32)asio_backend.ninput_channels)


    asio_backend.output_interleaved_buffer = make([]u8, asio_backend.block_size * asio_backend.frame_size_bytes * asio_backend.noutput_channels)

    playback_descriptor.format = asio_backend.sample_format
    playback_descriptor.channels = cast(u32)asio_backend.noutput_channels
    playback_descriptor.sampleRate = cast(u32)asio_backend.samplerate
    playback_descriptor.periodSizeInFrames = cast(u32)asio_backend.block_size
    
    ma.channel_map_init_standard(.default, raw_data(playback_descriptor.channelMap[:]), ma.MAX_CHANNELS, cast(u32)asio_backend.noutput_channels)
    
    input_latency, output_latency: c.long
    
    asio.GetLatencies(&input_latency, &output_latency)
    fmt.printfln("Input ASIO latency: %d samples \nOutput ASIO latency: %d samlples", input_latency, output_latency)
    
    asio_backend.audio_device = device

    return .SUCCESS 
}

uninit_asio_device :: proc "c" (pDevice: ^ma.device) -> ma.result {

    asio.Stop()
    asio.DisposeBuffers()
    asio.Exit()
    
    asio_backend.audio_device = nil

    return .SUCCESS 
}

start_asio_device :: proc "c" (device: ^ma.device) -> ma.result {
    // Start 
    context = set_odin_context()
    
    for channel_index in 0..<asio_backend.noutput_channels {
        info := &asio_backend.buffer_infos[asio_backend.ninput_channels + channel_index]
                
        if info.buffers[0] != nil { mem.zero(info.buffers[0], int(asio_backend.block_size * asio_backend.frame_size_bytes)) }
        if info.buffers[1] != nil { mem.zero(info.buffers[1], int(asio_backend.block_size * asio_backend.frame_size_bytes)) }
    }
    
    error := asio.Start() 
    if error != .OK {
        fmt.println("asio.Start failed with error: ", error)
        return .ERROR
    }    
    
    fmt.println("Starting ASIO processing")
    
    return .SUCCESS 
}

stop_asio_device :: proc "c" (pDevice: ^ma.device) -> ma.result {
    // Stop
    
    return asio.Stop() == .OK ? .SUCCESS : .ERROR
}

// read_from_asio_device :: proc "c" (pDevice: ^ma.device, pFrames: rawptr, frameCount: u32, pFramesRead: ^u32) -> ma.result {
//     return .SUCCESS 
// }

// write_to_asio_device :: proc "c" (pDevice: ^ma.device, pFrames: rawptr, frameCount: u32, pFramesWritten: ^u32) -> ma.result {
//     return .SUCCESS 
// }

// asio_device_data_loop :: proc "c" (pDevice: ^ma.device) -> ma.result {
//     return .SUCCESS 
// }

// asio_device_data_loop_wakeup :: proc "c" (pDevice: ^ma.device) -> ma.result {
//     return .SUCCESS 
// }

// get_asio_device_info :: proc "c" (pDevice: ^ma.device, type: ma.device_type, device_info: ^ma.device_info) -> ma.result {
//     return .SUCCESS 
// }


Command_Line_Arguments :: struct {
    plugin_path: string          `args:"name=plugin" usage:"The plugin do open"`,
    test_audio_file_path: string `args:"name=audio-file" usage:"The audio file to use with the plugin"`,
    run_audio: bool              `args:"name=run-audio" usage:"Sets the audio processing to begin directly"`, 
    show_plugin_gui: bool        `args:"name=show-plugin-gui" usage: "To automaticaly show the plugin gui"`,
}


main :: proc() {
        
    // assert(len(os.args) >= 2)
    // plugin_path := os.args[1]
    // plugin_path := "../clap/clap_ambient/build/cmake/Debug/clap_ambient.vst3"
    // plugin_path := "W:/AmpModeler/build/AmpModeler_artefacts/Debug/VST3/AmpModeler.vst3/Contents/x86_64-win/AmpModeler.vst3"
    // test_audio_filepath : cstring = "Deliverance2 DI.wav"

    
    arena: vmem.Arena
    arena_err := vmem.arena_init_growing(&arena)
    assert(arena_err == nil)
    context.allocator = vmem.arena_allocator(&arena)
    defer vmem.arena_destroy(&arena)

    main_allocator = context.allocator

    arguments: Command_Line_Arguments
    err := flags.parse(&arguments, os.args[1:])

    flags.write_usage(os.to_stream(os.stdout), Command_Line_Arguments)

    
    fmt.println("plugin_path: ", arguments.plugin_path)
    fmt.println("audio-file: ", arguments.test_audio_file_path)

    plugin_path := arguments.plugin_path
    test_audio_filepath := arguments.test_audio_file_path
    plugin_extension := ""

    dir, plugin_filename := os.split_path(plugin_path)
    plugin_filename, plugin_extension = os.split_filename(plugin_filename)

    binary_path := ""
    plugin_type: Plugin_Type
    
    switch plugin_extension {    
        case "vst3": { 
            if os.is_directory(plugin_path) {
                
                when ODIN_OS == .Windows {
                    binary_path = fmt.aprint(plugin_path, "/Contents/x86_64-win/", plugin_filename, ".vst3", sep = "")
                }
                else when ODIN_OS == .Darwin {
                    binary_path = fmt.aprint(plugin_path, "/Contents/MacOS/", plugin_filename, sep = "")
                }
                else when ODIN_OS == .Linux {
                    binary_path = fmt.aprint(plugin_path, "/Contents/x86_64-linux/", plugin_filename, ".so", sep = "")
                }
            } else {
                binary_path = plugin_path
            }
            plugin_type = .Vst 
        }
        case "clap": {
            plugin_type = .Clap 
            unimplemented("CLAP loader not yet implemented")
        }
        case: {
            unimplemented("Plugin type not supported")
        }
    }    
    
    
    host: Plugin_Host
    host.samplerate = 48000.0
    host.buffer_size = 512
    
    // miniaudio init
    ma_result: ma.result
    
    miniaudio_backends := []ma.backend { .custom } 
    
    context_config := ma.context_config_init()
    context_config.custom.onContextInit = init_asio_backend_context
    context_config.pUserData = &host

    ma_result = ma.context_init(raw_data(miniaudio_backends[:]), cast(u32)len(miniaudio_backends), &context_config, &asio_backend.miniaudio_context)
    assert(ma_result == .SUCCESS)
    asio_backend.miniaudio_context.backend = .custom

    
    play_back_infos: [^]ma.device_info
    play_back_count: u32
    capture_infos: [^]ma.device_info
    capture_count: u32
    
    ma_result = ma.context_get_devices(&asio_backend.miniaudio_context, &play_back_infos, &play_back_count, &capture_infos, &capture_count)
    assert(ma_result == .SUCCESS)
        
    for device_index in 0..<play_back_count {
        fmt.printf("%d - %s\n", device_index, play_back_infos[device_index].name)
    }
    
    
    init_result := init_miniaudio_device(&host, host.samplerate, host.buffer_size)

    host.buffer_size = host.audio_device.playback.internalPeriodSizeInFrames
    host.audio_buffer = { make([]f32, host.buffer_size), make([]f32, host.buffer_size) }
    
    decoder_config := ma.decoder_config_init(.f32, 1, 48000)
    ma_result = ma.decoder_init_file(strings.clone_to_cstring(test_audio_filepath), &decoder_config, &host.wav_decoder)
    assert(ma_result == .SUCCESS, "Could not init wav decoder")
    defer ma.decoder_uninit(&host.wav_decoder)



    // raylib init
    window_width :: 1200
    window_height :: 800
    
    rl.InitWindow(window_width, window_height, "PluginWorkBench")
    defer rl.CloseWindow()
    
    rl.SetTargetFPS(60)

    gui_font_filepath :: "resources/Roboto-Regular.ttf"
    gui_font := rl.LoadFont(gui_font_filepath)
    defer rl.UnloadFont(gui_font)
    
    if gui_font.glyphCount == 0 {
        fmt.println("Could not find font file: ", gui_font_filepath)
        fmt.println("Falling back to default raylib font")
    }            

    rl.GuiSetFont(gui_font)
    font_size :: 14
    font_spacing :: 1
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), font_size)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SPACING), font_spacing)
        
    // plugin load and init     
    res := vst_load_plugin(&host, binary_path)
    if res != .OK {
        fmt.println("Error during plugin loading Exiting")
        return 
    }

    vst_prepare_plugin_process(&host.vst_host, host.samplerate, i32(host.buffer_size))
    vst_get_parameter_infos(&host)

    num_params := host.vst_host.editor->get_parameter_count()    
    for index in 0..<num_params {
        info: vst3.ParameterInfo
        result := host.vst_host.editor->get_parameter_info(index, &info)
        
        fmt.println(info.id, " - ", 
                    u16_array_to_string16(info.title[:]), " - ", 
                    u16_array_to_string16(info.short_title[:]), " - ",
                    u16_array_to_string16(info.units[:]), " - ", 
                    info.default_normalised_value)
    }

    host.audio_file_status = .Stopped
    ma.device_start(&host.audio_device)
    host.audio_thread_status = .started

    rewind_button_pressed: bool
    
    samplerate_box_active: i32 = 1
    samplerate_box_edit := false
    selected_samplerate: f64 = host.samplerate
    available_samplerates := [3]f64 { 44100.0, 48000.0, 96000.0 }
    
    panel_scroll := rl.Vector2 { 0, 0 }
    

    input_select_active: i32
    input_select_edit: bool = false
    
    audio_is_running: bool = false
    
    info_panel_pos := rl.Rectangle {0, 0, 300, 150}
    input_panel_pos := rl.Rectangle {info_panel_pos.width, 0, window_width-info_panel_pos.width, info_panel_pos.height}
    plugin_param_pos := rl.Rectangle {0, info_panel_pos.height, 450, window_height-info_panel_pos.height}
    scopes_pos := rl.Rectangle {plugin_param_pos.width, plugin_param_pos.y, window_width-plugin_param_pos.x, window_height-info_panel_pos.height}

    
    scope_box_active: i32
    scope_box_edit: bool = false
    audio_running_checked: bool = true
    
    
    for !rl.WindowShouldClose() {
    
        // Handle GUI state update and events         
        if rewind_button_pressed {
            
            intrin.atomic_store(&host.audio_file_status, .RequestRewind)
        }
        
        if audio_running_checked != audio_is_running {
            audio_is_running = audio_running_checked
            
            if audio_is_running {
                // start
                ma.device_start(&host.audio_device)
                host.audio_thread_status = .started
            } else {
                // stop
                stop_audio_stream(&host)
            }
        }
        
        if selected_samplerate != host.samplerate {
            host.samplerate = selected_samplerate
            
            // stop and uninit audio stream
            destroy_audio_stream(&host)            
            
            // reset plugin
            
            vst_update_processing_setup(&host.vst_host, host.samplerate, cast(i32)host.buffer_size)
            
            // restart audio stream
            init_miniaudio_device(&host, host.samplerate, host.buffer_size)
            ma.device_start(&host.audio_device)
            host.audio_thread_status = .started
            
        }
        
        // Draw GUI
        {
            rl.BeginDrawing()
            defer rl.EndDrawing()
            
            rl.ClearBackground(rl.RAYWHITE)
            

            slider_height :: 20
            margin :: 10
            panel_view: rl.Rectangle
            panel_content_rect := rl.Rectangle {0, 0, plugin_param_pos.width, f32(len(host.parameters)*(slider_height + margin))}
            value_text_padding :: 85
            slider_pos := [2]f32{5.0 + value_text_padding, 30.0}
            
            value_text_buffer: [128]u8
            value_text_buffer_w: [128]u16
            
            rl.GuiScrollPanel(plugin_param_pos, "Parameter Panel", panel_content_rect, &panel_scroll, &panel_view)
            {
                rl.BeginScissorMode(rect_to_i32_args(panel_view))
                defer rl.EndScissorMode()
                
                for &param, param_index in host.parameters {
                
                    host.vst_host.editor->get_parameter_string_by_value(param.id, f64(param.current_value_norm), raw_data(value_text_buffer_w[:]))
                    u16_array_to_u8_array(value_text_buffer_w[:], value_text_buffer[:])
                                    
                    value_unit_string := rl.TextFormat("%s %s", cast(cstring)raw_data(value_text_buffer[:]), param.unit)
                    
                    old_value := param.current_value_norm
                    rl.GuiSliderBar({plugin_param_pos.x + panel_scroll.x + slider_pos.x, 
                                    plugin_param_pos.y + panel_scroll.y + slider_pos.y, 
                                    200, 20}, 
                                    value_unit_string, 
                                    param.label, &param.current_value_norm, 0.0, 1.0)
                    
                    if old_value != param.current_value_norm {
                        fifo := &host.param_event_fifo
                        
                        head := intrin.atomic_load(&fifo.head)
                        tail := intrin.atomic_load(&fifo.tail)
                        
                        fifo.events[head] = { param.id, f64(param.current_value_norm) }
                        head += 1
                        head &= (VALUE_QUEUE_LENGTH-1)
                        
                        intrin.atomic_store(&fifo.head, head)

                        host.vst_host.editor->set_param_normalised(param.id, f64(param.current_value_norm))
                    }
                                        
                    slider_pos.y += 30
                }                                
            }
            
            {
                rl.GuiPanel(scopes_pos, "scopes")
                
                switch scope_box_active {
                    case 0: {
                        rl.GuiLabel({scopes_pos.x +5, scopes_pos.y + 30, 100, 20}, "Scope panel")
                    }
                    case 1: {
                        rl.GuiLabel({scopes_pos.x +5, scopes_pos.y + 30, 100, 20}, "FFT panel")
                    }
                    case 2: {
                        rl.GuiLabel({scopes_pos.x +5, scopes_pos.y + 30, 100, 20}, "Spectrogram panel")
                    }
                    case 3: {
                        rl.GuiLabel({scopes_pos.x +5, scopes_pos.y + 30, 100, 20}, "Freq response panel")
                    }
                    case 4: {
                        rl.GuiLabel({scopes_pos.x +5, scopes_pos.y + 30, 100, 20}, "Phase response panel")
                    }
                    case: {
                        unreachable()
                    }
                }

                if cast(bool)rl.GuiDropdownBox({scopes_pos.x + 80, scopes_pos.y+2, 150, 20}, "#124#scope;#189#spectrum;#189#spectrogram;#125#freq response;#125#phase response", &scope_box_active, scope_box_edit) { 
                    scope_box_edit = !scope_box_edit 
                }
                        
            }

            { // draw master settings window
                rl.GuiPanel(info_panel_pos, "Infos panel")
                
                label_string := rl.TextFormat("Plugin: %s", host.vst_host.plugin_class_infos[0].name)
                str_size := rl.MeasureTextEx(gui_font, label_string, font_size, font_spacing)
                rl.GuiLabel({5, info_panel_pos.y + 25, str_size.x, 20}, label_string)

                label_string = rl.TextFormat("Code: %s", host.vst_host.plugin_class_infos[0].cid[8:])
                str_size = rl.MeasureTextEx(gui_font, label_string, font_size, font_spacing)
                rl.GuiLabel({5, info_panel_pos.y + 25 + 20, str_size.x, 20}, label_string)

                label_string = rl.TextFormat("Vendor: %s", host.vst_host.factory_infos.vendor)
                str_size = rl.MeasureTextEx(gui_font, label_string, font_size, font_spacing)
                rl.GuiLabel({5, info_panel_pos.y + 25 + 20 + 20, str_size.x, 20}, label_string)

                label_string = rl.TextFormat("Buffer size: %d", host.audio_device.playback.internalPeriodSizeInFrames)
                str_size = rl.MeasureTextEx(gui_font, label_string, font_size, font_spacing)
                rl.GuiLabel({5, info_panel_pos.y + 25 + 60, str_size.x, 20}, label_string)

                samplerate_box_pos := rl.Rectangle {5, info_panel_pos.height - 30 - 10, 80, 30}
                if cast(bool)rl.GuiDropdownBox(samplerate_box_pos, "44100;48000;96000", &samplerate_box_active, samplerate_box_edit) { 
                    samplerate_box_edit = !samplerate_box_edit
                    
                    selected_samplerate = available_samplerates[samplerate_box_active]
                }
            
                rl.GuiCheckBox({samplerate_box_pos.width + 10, samplerate_box_pos.y, 20, 20}, "Audio Stream", &audio_running_checked)

                /* si jechange samplerate {
                    couper proprement l'audio stream,
                    réouvrir un nouvel audio stream avec les nouveaux settings 
                }
                
                
                */
            }
            
            { // draw input settings
                rl.GuiPanel(input_panel_pos, "input settings")
                
                switch input_select_active {
                    case 0: {
                        rewind_button_pressed = rl.GuiButton({input_panel_pos.x+5, input_panel_pos.y+30 + 30 +5, 100, 30}, "#131#Play")
                    }
                    case 1: {
                        rl.GuiLabel({input_panel_pos.x+5, input_panel_pos.y+30 + 30 +5, 100, 20}, "ADC window")
                    }
                    case 2: {
                        rl.GuiLabel({input_panel_pos.x+5, input_panel_pos.y+30 + 30 +5, 100, 20}, "Synth window")
                    }
                    case: {
                        unreachable()
                    }
                }

                if cast(bool)rl.GuiDropdownBox({input_panel_pos.x+100, input_panel_pos.y+2, 80, 20}, "Sample;ADC;Synth", &input_select_active, input_select_edit) {
                    input_select_edit = !input_select_edit
                }


            }

            // status_bar_height :: f32(40)
            // status_bar_y :: f32(window_height - status_bar_height) 
            
            // status_str := rl.TextFormat("Samplerate: %d Hz | Buffer Size: %d | Plugin: %s", 
            //                             int(host.samplerate), host.buffer_size, host.vst_host.plugin_class_infos[0].name)
            // rl.GuiStatusBar({0, status_bar_y, f32(window_width), status_bar_height}, status_str)
    
        }
        
        
        free_all(context.temp_allocator)
    }

    host.audio_thread_status = .stopped
    ma_result = ma.device_stop(&host.audio_device)
    ma.device_uninit(&host.audio_device)
    ma.context_uninit(&asio_backend.miniaudio_context)
        
    vst_close_plugin(&host)

}
