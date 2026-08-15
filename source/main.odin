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

Plugin_Host :: struct {

    samplerate: f64, 
    buffer_size: u32, 
    audio_buffer: [2][]f32,

    audio_thread_status: Audio_Thread_Status,
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


Audio_Thread_Status :: enum {
    Stopped,
    Running, 
    RequestToStop,
}

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

audio_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, nsamples: u32) {    
    context = runtime.default_context()
    
    host := transmute(^Plugin_Host)device.pUserData

    thread_status := intrin.atomic_load(&host.audio_thread_status)
    audio_file_status := intrin.atomic_load(&host.audio_file_status)

    if thread_status != .Running { 
        return 
    }

    // audio data is interleaved so we have to convert it before sending it to plugins    
    in_buffer := transmute([^]f32)input
    // for now we only read a wav file so we don't care about the input buffer
    out_buffer := transmute([^]f32)output

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
    for _, index in host.audio_buffer[0] {
        out_buffer[index*2] = host.audio_buffer[0][index]
        out_buffer[index*2 + 1] = host.audio_buffer[1][index]
    }
}

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
    
    // miniaudio init
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
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 14)
        
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

    host.audio_thread_status = .Running
    host.audio_file_status = .Playing
    ma.device_start(&host.audio_device)

    rewind_button_pressed: bool
    samplerate_box_active: i32 = 1
    samplerate_box_edit := false
    panel_scroll := rl.Vector2 { 0, 0 }
    

    input_select_active: i32
    input_select_edit: bool = false
    
    info_panel_pos := rl.Rectangle {0, 0, 300, 150}
    input_panel_pos := rl.Rectangle {info_panel_pos.width, 0, window_width-info_panel_pos.width, info_panel_pos.height}
    plugin_param_pos := rl.Rectangle {0, info_panel_pos.height, 450, window_height-info_panel_pos.height}
    scopes_pos := rl.Rectangle {plugin_param_pos.width, plugin_param_pos.y, window_width-plugin_param_pos.x, window_height-info_panel_pos.height}

    
    scope_box_active: i32
    scope_box_edit: bool = false
    
    for !rl.WindowShouldClose() {
    
        // Handle GUI state update and events         
        if rewind_button_pressed {
            
            intrin.atomic_store(&host.audio_file_status, .RequestRewind)
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
                rl.GuiPanel(info_panel_pos, "top panel")
                if cast(bool)rl.GuiDropdownBox({5, info_panel_pos.y + 30, 100, 30}, "44100;48000;96000", &samplerate_box_active, samplerate_box_edit) { 
                    samplerate_box_edit = !samplerate_box_edit 
                }
                
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

    host.audio_thread_status = .Stopped
    ma_result = ma.device_stop(&host.audio_device)
    // ma.device_uninit(&host.audio_device)
    // ma.context_uninit(&ma_context)
        
    vst_close_plugin(&host)

}
