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
    ninput_channels: i32,
    noutput_channels: i32,
    input_buffers: [][]f32,
    output_buffers: [][]f32,

    audio_thread_status: ma.device_state,
    audio_file_status: Audio_File_Playback_Status,
    
    // miniaudio stuff
    miniaudio_context: ma.context_type,
    miniaudio_context_config: ma.context_config,
    audio_device: ma.device,
    wav_decoder: ma.decoder,

    audio_device_list: [10]cstring,
    num_audio_devices: int,

    // plugin data
    dll_handle: dynlib.Library,

    vst_host: Vst_Host,
    clap_host: Clap_Host,

    parameters: []Parameter,
    param_event_fifo: EventFIFO,
}

Info_Panel_State :: struct {}
Input_Panel_State :: struct {}
Parameter_Panel_State :: struct {}
Scopes_Panel_State :: struct {}


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

    arena: vmem.Arena,
    host: ^Plugin_Host,

    asio_callbacks: asio.Callbacks,
    buffer_infos: []asio.BufferInfo,

    driver_names: [8]cstring,
    ndrivers: i32,
    driver_index: c.long,

    drivers: rawptr,
    audio_device: ^ma.device,
    
    sample_format: ma.format,
    ninput_channels: i32,
    noutput_channels: i32,
    samplerate: f64,
    frame_size_bytes: i32,
    buffer_size: i32,
    input_latency: c.long,
    output_latency: c.long,
    uses_output_ready_notification: bool,
}

// Audio_Thread_Status :: enum {
//     Stopped,
//     Running,
//     RequestToStop,
// }

Audio_Backend_Type :: enum { None, Asio, Miniaudio }

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


set_odin_context_main_allocator :: proc "contextless" () -> runtime.Context {
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
    device_config.dataCallback = miniaudio_data_callback
    device_config.pUserData = host

    // ma_result := ma.device_init(&asio_backend.miniaudio_context, &device_config, &host.audio_device)
    // assert(ma_result == .SUCCESS, "Error during initialisation of miniaudio device")

    return .SUCCESS
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

miniaudio_data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, nsamples: u32) {
    context = runtime.default_context()

    host := transmute(^Plugin_Host)device.pUserData



    // audio data is interleaved so we have to convert it before sending it to plugins
    in_buffer := transmute([^]f32)input
    // for now we only read a wav file so we don't care about the input buffer
    out_buffer := transmute([^]f32)output


    deinterleave_buffers(in_buffer[:host.audio_device.capture.channels*nsamples], host.input_buffers, host.audio_device.capture.channels)

    // main_audio_procedure(host, nsamples)

    // interleave audio in output buffer

    interleave_buffers(host.output_buffers, out_buffer[:host.audio_device.playback.channels*nsamples], host.audio_device.playback.channels)

}

main_audio_procedure :: proc(host: ^Plugin_Host, nsamples: u32) {

    thread_status := intrin.atomic_load(&host.audio_thread_status)
    audio_file_status := intrin.atomic_load(&host.audio_file_status)

    if thread_status != .started {
        return
    }


    when false {
        frames_decoded: u64

        if audio_file_status == .RequestRewind {
            result := ma.decoder_seek_to_pcm_frame(&host.wav_decoder, 0)

            if result == .SUCCESS {
                audio_file_status = .Playing
                intrin.atomic_store(&host.audio_file_status, audio_file_status)
            }
        }
    
        for channel, _ in host.input_buffers {
            mem.zero_slice(channel)
        }

        read_frames_result: ma.result
        if audio_file_status == .Playing {
            read_frames_result = ma.decoder_read_pcm_frames(&host.wav_decoder, raw_data(host.input_buffers[0]), u64(nsamples), &frames_decoded)
        }

        if read_frames_result == .AT_END {
            intrin.atomic_store(&host.audio_file_status, audio_file_status)
            audio_file_status = .Stopped
            mem.zero_slice(host.input_buffers[0][frames_decoded:])
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



    input_audio_channels := [][^]f32 { raw_data(host.input_buffers[0]), raw_data(host.input_buffers[1]) }

    input_audio_bus := vst3.AudioBusBuffers {
        num_channels = 2,
        silence_flags = 0,
        buffers_32 = raw_data(input_audio_channels[:])
    }


    output_audio_channels := [][^]f32 { raw_data(host.output_buffers[0]), raw_data(host.output_buffers[1]) }

    output_audio_bus := vst3.AudioBusBuffers {
        num_channels = 2,
        silence_flags = 0,
        buffers_32 = raw_data(output_audio_channels[:])
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
        inputs = &input_audio_bus,
        outputs = &output_audio_bus,
        inputParameterChanges = &param_changes.interface, //  ^IParameterChanges,
        outputParameterChanges = nil, // ^IParameterChanges,
        input_events = nil, // ^IEventList,
        output_events = nil, // ^IEventList,
        process_context = &process_context,
    }


    vst_result := host.vst_host.audio_proc->process(&process_data)
    assert(vst_result == .Ok)


    for channel_index in 0..<host.noutput_channels {
        for &sample, index in host.output_buffers[channel_index][:nsamples] {
            sample = clamp(sample, -1.0, 1.0)
        }
    }

}


asio_backend: Asio_Backend

get_asio_allocator :: proc() -> runtime.Allocator {

    // check if arena is initialised
    if asio_backend.arena.total_reserved == 0 {
        error := vmem.arena_init_growing(&asio_backend.arena)
        assert(error == nil, " [ASIO] - Error during the creation of the arena allocator")
    }

    return vmem.arena_allocator(&asio_backend.arena)
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


switch_asio_buffers :: proc "c" (doubleBufferIndex: c.long, directProcess: asio.Bool) {

    time_info: asio.Time

    if asio.GetSamplePosition(&time_info.timeInfo.samplePosition, &time_info.timeInfo.systemTime) == .OK {
        time_info.timeInfo.flags = .SystemTimeValid | .SamplePositionValid
    }

    switch_asio_buffers_with_time_info(&time_info, doubleBufferIndex, directProcess)
}

switch_asio_buffers_with_time_info :: proc "c" (time: ^asio.Time, dma_buffer_index: c.long, directProcess: asio.Bool) -> ^asio.Time {
    context = runtime.default_context()
    // callback audio principal si kAsioSupportsTimeInfo == true

    // interlrave

    // interleave_buffers(asio_backend.buffer)

    host := asio_backend.host

    for channel_index in 0..<asio_backend.ninput_channels {
    
        asio_buffer := (cast([^]f32)asio_backend.buffer_infos[channel_index].buffers[dma_buffer_index])[:asio_backend.buffer_size]        
        host.input_buffers[channel_index] = asio_buffer

        ma.pcm_convert(raw_data(asio_buffer[:]), .f32,
                       raw_data(asio_buffer[:]), asio_backend.sample_format,
                       cast(u64)(asio_backend.buffer_size), .triangle)
    }

    for channel_index in 0..<asio_backend.noutput_channels {
        asio_buffer := (cast([^]f32)asio_backend.buffer_infos[channel_index + asio_backend.ninput_channels].buffers[dma_buffer_index])[:asio_backend.buffer_size]
        host.output_buffers[channel_index] = asio_buffer
    }
    
    main_audio_procedure(host, cast(u32)asio_backend.buffer_size)

    for channel_index in asio_backend.ninput_channels..<(asio_backend.noutput_channels+asio_backend.ninput_channels) {
        
        asio_buffer: rawptr = asio_backend.buffer_infos[channel_index].buffers[dma_buffer_index]
    
        ma.pcm_convert(asio_buffer, asio_backend.sample_format,
                       asio_buffer, .f32,
                       cast(u64)(asio_backend.buffer_size), .triangle)
    }

    if asio_backend.uses_output_ready_notification {
        asio.OutputReady()
    }

    return nil
}

asio_samplerate_did_change :: proc "c" (samplerate: asio.SampleRate) {
    asio_backend.samplerate = f64(samplerate)
}

process_asio_message :: proc "c" (selector: asio.MessageSelector, value: c.long, message: rawptr, opt: ^f64) -> c.long {
    context = runtime.default_context()
    context.allocator = get_asio_allocator()

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

            uninit_asio_stream()
            init_asio_stream(asio_backend.samplerate)
            asio.Start()

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
    context = set_odin_context_main_allocator()

    asio_backend.drivers = asio.driversAllocate()

    for &name in asio_backend.driver_names {
        name = cstring(raw_data(make([]u8, 32)))
    }

    asio_backend.ndrivers = asio.getDriverNames(asio_backend.drivers, raw_data(asio_backend.driver_names[:]), len(asio_backend.driver_names))


    callbacks.onContextInit             = init_asio_backend_context
    callbacks.onContextUninit           = uninit_asio_backend_context
    callbacks.onContextEnumerateDevices = enumerate_asio_devices
    callbacks.onContextGetDeviceInfo    = get_asio_context_device_info
    callbacks.onDeviceInit              = init_asio_device
    callbacks.onDeviceUninit            = uninit_asio_device
    callbacks.onDeviceStart             = start_asio_device
    callbacks.onDeviceStop              = stop_asio_device

    asio.driversDestroy(asio_backend.drivers)

    return .SUCCESS
}


uninit_asio_backend_context :: proc "c" (pContext: ^ma.context_type) -> ma.result {
    context = set_odin_context_main_allocator()

    asio.driversDestroy(asio_backend.drivers)
    asio_backend.drivers = nil

    return .SUCCESS
}

enumerate_asio_devices :: proc "c" (pContext: ^ma.context_type, enum_callback: ma.enum_devices_callback_proc, pUserData: rawptr) -> ma.result {
    // donner les devices récupérés dans onContextInit
    context = set_odin_context_main_allocator()

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
    context = set_odin_context_main_allocator()

    if asio_backend.audio_device == nil { return .NO_DEVICE }

    mem.zero_item(device_info)

    mem.copy(raw_data(device_info.name[:]),
            transmute([^]u8)(asio_backend.driver_names[asio_backend.driver_index]), 32)

    device_info.nativeDataFormatCount = 1
    // device_info.nativedataFormats[0] = { format = .f32, channels = 2}

    return .SUCCESS
}

init_asio_stream :: proc(wanted_samplerate: f64) -> ma.result {
    asio_error: asio.Error

    driver_info: asio.DriverInfo
    driver_info.asioVersion = 2

    fmt.printf("[ASIO] - asioVersion:   %d\n driverVersion: %d\n Name:          %s\n ErrorMessage:  %s\n",
               driver_info.asioVersion, driver_info.driverVersion,
               string(driver_info.name[:]), string(driver_info.errorMessage[:]))


    driver_name := asio_backend.driver_names[2]
    // driver_name := asio_backend.driver_names[3]

    // asio_backend.drivers = asio.driversAllocate()
    // if !asio.loadDriver(asio_backend.drivers, driver_name) { return .ERROR }

    asio_backend.driver_index = asio.getCurrentDriverIndex(asio_backend.drivers)

    if asio.Init(&driver_info) != .OK {
        asio.Exit()
        return .ERROR
    }

    asio_backend.asio_callbacks.bufferSwitch = switch_asio_buffers
    asio_backend.asio_callbacks.sampleRateDidChange = asio_samplerate_did_change
    asio_backend.asio_callbacks.asioMessage = process_asio_message
    asio_backend.asio_callbacks.bufferSwitchTimeInfo = switch_asio_buffers_with_time_info


    if asio.GetChannels(&asio_backend.ninput_channels, &asio_backend.noutput_channels) != .OK {
        asio.Exit()
        return .ERROR
    }

    asio_backend.host.ninput_channels = asio_backend.ninput_channels 
    asio_backend.host.noutput_channels = asio_backend.noutput_channels

    min_size, max_size, prefered_size, granularity: i32
    if asio.GetBufferSize(&min_size, &max_size, &prefered_size, &granularity) != .OK {
        asio.Exit()
        return .ERROR
    }

    asio_backend.buffer_size = prefered_size

    clock_sources: [4]asio.ClockSource
    num_sources: i32 = len(clock_sources)

    if asio.GetClockSources(raw_data(clock_sources[:]), &num_sources) == .NotPresent {
        panic("Error during gathering of asio clock sources")
    }

    if num_sources == 1 {
        if asio.SetClockSource(0) != .OK {
            assert(false, "Error during asio.SetClockSource")
        }
    }


    asio_backend.samplerate = wanted_samplerate
    if asio.CanSampleRate(asio_backend.samplerate) == .OK {
        asio.SetSampleRate(asio_backend.samplerate)

        current_samplerate: f64
        asio.GetSampleRate(&current_samplerate)
        assert(current_samplerate == asio_backend.samplerate, "error during asio samplerate setup")
    } else {

        assert(asio.CanSampleRate(44100.0) == .OK)
        asio.SetSampleRate(44100.0)

        current_samplerate: f64
        asio.GetSampleRate(&current_samplerate)
        assert(current_samplerate == 44100.0)

        asio_backend.samplerate = 44100.0
    }

    //asio_backend.samplerate
    fmt.println("[ASIO] - samplerate at init time: ", asio_backend.samplerate, "Hz")

    if asio.OutputReady() == .OK {
        asio_backend.uses_output_ready_notification = true
    } else {
        asio_backend.uses_output_ready_notification = false
    }

    // setup buffers
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

    if asio.CreateBuffers(raw_data(asio_backend.buffer_infos[:]), total_num_channels,
                         asio_backend.buffer_size, &asio_backend.asio_callbacks) != .OK
    {
        asio.DisposeBuffers()
        asio.Exit()
        return .ERROR
    }

    for &buffer_info in asio_backend.buffer_infos {
        mem.zero(buffer_info.buffers[0], cast(int)(asio_backend.buffer_size * asio_backend.frame_size_bytes))
        mem.zero(buffer_info.buffers[1], cast(int)(asio_backend.buffer_size * asio_backend.frame_size_bytes))
    }

    { // get device sample format

        sample_input_channel := asio.ChannelInfo {
            channel = 0,
            isInput = asio.True,
        }

        asio.GetChannelInfo(&sample_input_channel)

        switch sample_input_channel.type {

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
    }


    asio.GetLatencies(&asio_backend.input_latency, &asio_backend.output_latency)
    fmt.printfln("Input ASIO latency: %d samples \nOutput ASIO latency: %d samlples", asio_backend.input_latency, asio_backend.output_latency)

    return .SUCCESS
}

uninit_asio_stream :: proc() {

    asio.Stop()
    asio.DisposeBuffers()
    asio.Exit()

    asio_backend.audio_device = nil

    vmem.arena_destroy(&asio_backend.arena)
}

init_asio_device :: proc "c" (device: ^ma.device, config: ^ma.device_config, playback_descriptor, capture_descriptor: ^ma.device_descriptor) -> ma.result {
    // ici on initialise tout ce qu'on peut du moteur asio
    // Init,  ASIOCreateBuffers

    context = runtime.default_context()
    context.allocator = get_asio_allocator()


    // -------

    init_asio_stream(cast(f64)config.sampleRate)

    config.sampleRate = cast(u32)asio_backend.samplerate
    config.periodSizeInFrames = cast(u32)asio_backend.buffer_size


    // asio_backend.input_interleaved_buffer = make([]u8, asio_backend.buffer_size * asio_backend.frame_size_bytes * asio_backend.ninput_channels)

    capture_descriptor.shareMode = .shared
    capture_descriptor.format = asio_backend.sample_format
    capture_descriptor.channels = cast(u32)asio_backend.ninput_channels
    capture_descriptor.sampleRate = cast(u32)asio_backend.samplerate
    capture_descriptor.periodSizeInFrames = cast(u32)asio_backend.buffer_size

    ma.channel_map_init_standard(.default, raw_data(capture_descriptor.channelMap[:]), ma.MAX_CHANNELS, cast(u32)asio_backend.ninput_channels)



    // asio_backend.output_interleaved_buffer = make([]u8, asio_backend.buffer_size * asio_backend.frame_size_bytes * asio_backend.noutput_channels)

    playback_descriptor.shareMode = .shared
    playback_descriptor.format = asio_backend.sample_format
    playback_descriptor.channels = cast(u32)asio_backend.noutput_channels
    playback_descriptor.sampleRate = cast(u32)asio_backend.samplerate
    playback_descriptor.periodSizeInFrames = cast(u32)asio_backend.buffer_size

    ma.channel_map_init_standard(.default, raw_data(playback_descriptor.channelMap[:]), ma.MAX_CHANNELS, cast(u32)asio_backend.noutput_channels)

    asio_backend.audio_device = device

    return .SUCCESS
}

uninit_asio_device :: proc "c" (pDevice: ^ma.device) -> ma.result {

    context = runtime.default_context()
    context.allocator = get_asio_allocator()

    uninit_asio_stream()

    return .SUCCESS
}

start_asio_stream :: proc() -> ma.result {
    for channel_index in 0..<asio_backend.noutput_channels {
        info := &asio_backend.buffer_infos[asio_backend.ninput_channels + channel_index]

        if info.buffers[0] != nil { mem.zero(info.buffers[0], int(asio_backend.buffer_size * asio_backend.frame_size_bytes)) }
        if info.buffers[1] != nil { mem.zero(info.buffers[1], int(asio_backend.buffer_size * asio_backend.frame_size_bytes)) }
    }

    error := asio.Start()
    if error != .OK {
        fmt.println("[ASIO] - asio.Start failed with error: ", error)
        return .ERROR
    }

    fmt.println("[ASIO] - Starting processing")
    return .SUCCESS
}

start_asio_device :: proc "c" (device: ^ma.device) -> ma.result {
    // Start
    context = set_odin_context_main_allocator()


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
    // set default sample rate and audio block size
    host.samplerate = 48000.0
    host.buffer_size = 128


    // miniaudio init
    ma_result: ma.result
    miniaudio_backends := []ma.backend { .wasapi, .jack, .dsound, .winmm  }    
    host.miniaudio_context_config = ma.context_config_init()
    // context_config.custom.onContextInit = init_asio_backend_context
    host.miniaudio_context_config.pUserData = &host

    ma_result = ma.context_init(raw_data(miniaudio_backends[:]), cast(u32)len(miniaudio_backends), &host.miniaudio_context_config, &host.miniaudio_context)

    if ma_result == .NO_BACKEND {
        panic("[Miniaudio] - Found no drivers on this machine")
    } else if ma_result != .SUCCESS {
        fmt.println("[Miniaudio] - Error during context_init, error: ", ma_result)
        panic("")
    }
    
    #partial switch host.miniaudio_context.backend {
        case .wasapi: { 
            host.audio_device_list[host.num_audio_devices] = "Wasapi"
            host.num_audio_devices += 1 
        }
        case .dsound: {
            host.audio_device_list[host.num_audio_devices] = "Direct Sound"
            host.num_audio_devices += 1 
        }
        case .jack: {
            host.audio_device_list[host.num_audio_devices] = "Jack"
            host.num_audio_devices += 1 
        }
        case .winmm: {
            host.audio_device_list[host.num_audio_devices] = "Winmm"
            host.num_audio_devices += 1 
        }
        case .coreaudio: {
            host.audio_device_list[host.num_audio_devices] = "Core Audio"
            host.num_audio_devices += 1 
        }
        case: {
            panic("[Miniaudio] - Unsupported backend")
        }
    }

    
    // ASIO init
    asio_backend.host = &host
    
    asio_backend.drivers = asio.driversAllocate()
    defer asio.driversDestroy(asio_backend.drivers)

    for &name in asio_backend.driver_names {
        name = cstring(raw_data(make([]u8, 32)))
    }

    asio_backend.ndrivers = asio.getDriverNames(asio_backend.drivers, raw_data(asio_backend.driver_names[:]), len(asio_backend.driver_names))
    
    if asio_backend.ndrivers == 0 {
        fmt.println("[ASIO] - No Asio driver present on this machine, fallback to miniaudio")
    } else {    
        for index in 0..<asio_backend.ndrivers {
            host.audio_device_list[host.num_audio_devices] = asio_backend.driver_names[index] 
            host.num_audio_devices += 1
        }
    }

    fmt.printfln("\n----- Found %d audio devices -----", host.num_audio_devices)

    for name_index in 0..<host.num_audio_devices {
        fmt.printfln("%d - %s", name_index, host.audio_device_list[name_index])
    }
    

    // asio.loadDriver(asio_backend.drivers, "Focusrite USB ASIO")
    // init_asio_result := init_asio_stream(48000.0)

        

    // play_back_infos: [^]ma.device_info
    // play_back_count: u32
    // capture_infos: [^]ma.device_info
    // capture_count: u32

    // ma_result = ma.context_get_devices(&host.miniaudio_context, &play_back_infos, &play_back_count, &capture_infos, &capture_count)
    // assert(ma_result == .SUCCESS)


    // init_result := init_miniaudio_device(&host, host.samplerate, host.buffer_size)

    // host.buffer_size = host.audio_device.playback.internalPeriodSizeInFrames
    // host.samplerate = f64(host.audio_device.sampleRate)

    host.input_buffers = make([][]f32, host.ninput_channels)
    // for channel_index in 0..<host.audio_device.capture.channels {
    //     host.input_buffers[channel_index] = make([]f32, host.buffer_size)
    // }

    host.output_buffers = make([][]f32, host.noutput_channels)
    // for channel_index in 0..<host.audio_device.playback.channels {
    //     host.output_buffers[channel_index] = make([]f32, host.buffer_size)
    // }

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
    // ma.device_start(&host.audio_device)
    // host.audio_thread_status = .started


    // gui state variables
    
    /*
    définir dans des variables les positions dont on a besoin pour calculer des positions relatives
    si une position n'est pas utilisée comme réféence pour une autre position -> inline
    ne pas forcément faire des structs pour les states récurrents
    sauf si j'ai besoin de factoriser certaines fonctions du gui dans des fonctions, là peut etre faire des structs
    
    */

    rewind_button_pressed: bool

    selected_samplerate: f64 = host.samplerate
    available_samplerates := [3]f64 { 44100.0, 48000.0, 96000.0 }

    panel_scroll := rl.Vector2 { 0, 0 }


    input_select_active: i32
    input_select_edit: bool = false

    info_panel_pos := rl.Rectangle {0, 0, 300, 150}
    input_panel_pos := rl.Rectangle {info_panel_pos.width, 0, window_width-info_panel_pos.width, info_panel_pos.height}
    plugin_param_pos := rl.Rectangle {0, info_panel_pos.height, 450, window_height-info_panel_pos.height}
    scopes_pos := rl.Rectangle {plugin_param_pos.width, plugin_param_pos.y, window_width-plugin_param_pos.x, window_height-info_panel_pos.height}

    samplerate_box_text: cstring = "44100;48000;96000"
    selected_samplerate_index: c.int = 1
    samplerate_box_edit := false

    audio_device_box_text: cstring = ""
    selected_audio_device: c.int = 1
    audio_device_box_edit := false

    device_list_builder := strings.builder_make(0, 500)
    
    for name_index in 0..<host.num_audio_devices {
        
        name := transmute([^]u8)(host.audio_device_list[name_index])
        
        for char_index := 0; name[char_index] != 0; char_index += 1 {
            strings.write_byte(&device_list_builder, name[char_index])
        }
        
        if name_index != host.num_audio_devices-1 { strings.write_byte(&device_list_builder, ';') }
    }

    audio_device_box_text = strings.to_cstring(&device_list_builder)

    scope_box_active: i32
    scope_box_edit: bool = false
    audio_is_running := false
    audio_running_checked := audio_is_running


    for !rl.WindowShouldClose() {

        // Handle GUI state update and events
        if rewind_button_pressed {

            intrin.atomic_store(&host.audio_file_status, .RequestRewind)
        }

        if audio_running_checked != audio_is_running {
            audio_is_running = audio_running_checked

            if audio_is_running {
                // start
                // ma.device_start(&host.audio_device)
                if start_asio_stream() == .SUCCESS {
                    host.audio_thread_status = .started

                } else {
                    audio_is_running = false
                    audio_running_checked = false
                }

            } else {
                // stop
                stop_audio_stream(&host)
                host.audio_thread_status = .stopped

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



                audio_running_label: cstring = audio_running_checked ? "Audio On" : "Audio Off"
                rl.GuiCheckBox({info_panel_pos.width -100, info_panel_pos.y+30, 20, 20}, audio_running_label, &audio_running_checked)

                if cast(bool)rl.GuiDropdownBox({5, info_panel_pos.height - 40 , 200, 30}, audio_device_box_text, &selected_audio_device, audio_device_box_edit) {
                    audio_device_box_edit = !audio_device_box_edit
                }

                // samplerate dropdown box
                if cast(bool)rl.GuiDropdownBox({info_panel_pos.width - 90, info_panel_pos.height - 40, 80, 30}, samplerate_box_text, &selected_samplerate_index, samplerate_box_edit) {
                    samplerate_box_edit = !samplerate_box_edit
                    selected_samplerate = available_samplerates[selected_samplerate_index]
                }
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
    asio.Stop()
    asio.DisposeBuffers()
    asio.Exit()

    ma_result = ma.device_stop(&host.audio_device)
    ma.device_uninit(&host.audio_device)
    ma.context_uninit(&host.miniaudio_context)

    vst_close_plugin(&host)

}
