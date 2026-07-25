package PluginWorkBench

import "base:runtime"

import "core:fmt"
import "core:dynlib"
import "core:strings"
import "core:slice"

import vst3 "../deps/vst3_odin/vst3"

VST3_Entry_Proc :: proc "system" () -> bool
VST3_Get_Factory_Proc :: proc "system" () -> ^vst3.IPluginFactory3

Vst_Host :: struct {
    host_interface: vst3.IHostApplication,

    component_interface: ^vst3.IComponent, 
    editor_interface: ^vst3.IEditController,
    audio_proc_interface: ^vst3.IAudioProcessor,    
}

vst_host_vtbl := vst3.IHostApplicationVtbl {
    query_interface = proc "system" (this: rawptr, iid: [^]u8, obj: ^rawptr) -> vst3.Result { 
        
        context = runtime.default_context()
        
        host_app_uuid, err := vst3.parse_uuid(vst3.IHostApplication_iid)
        assert(err == .Ok)
        
        // the iid is defined to be 16 bytes long
        if slice.equal(iid[0:16], host_app_uuid[:]) {
            
            host := transmute(^vst3.IHostApplication)this
            obj^ = transmute(rawptr)(host)
            
            return .Ok 
        }
        
        return .NoInterface
    },
    
    add_ref = proc "system" (this: rawptr) -> u32 { 
        return 0 
    },
    
    release = proc "system" (this: rawptr) -> u32 { 
        return 0 
    },
    
    get_name = proc "system"(this: rawptr, name_buffer: [^]u16) -> vst3.Result {
        host_name: string16 = "PluginWorkBench Host"
        copy(name_buffer[0:len(host_name)], host_name)
        
        return .Ok
    },

    create_instance = nil,
    
}


vst_load_plugin :: proc(main_host: ^Plugin_Host, plugin_path: string) {
    
    vst_host := &main_host.vst_host
    vst_host.host_interface.vtbl = &vst_host_vtbl

    ok: bool
    main_host.dll_handle, ok = dynlib.load_library(plugin_path)
    
    if !ok {
        fmt.println(dynlib.last_error())
        return
    }

    address, found := dynlib.symbol_address(main_host.dll_handle, "InitDll")

    if !found {
        fmt.println("Procedure address not found")
        return
    }
    
    init_proc := cast(VST3_Entry_Proc)address
    if !init_proc() {
        fmt.println("Error during plugin moule init")
        return 
    }
    
    
    address, found = dynlib.symbol_address(main_host.dll_handle, "GetPluginFactory")

    if !found {
        fmt.println("Procedure address not found")
        return
    }
    
    get_fact_proc := cast(VST3_Get_Factory_Proc)address
    vst_factory: ^vst3.IPluginFactory3 = get_fact_proc()
    defer vst_factory->release()
    
    assert(vst_factory != nil)        
    
    num_classes := vst_factory->count_classes()
    // assert(num_classes == 1)
    
    class_infos := make([]vst3.PClassInfo, num_classes)
    defer delete(class_infos)

    for index in 0..<num_classes {
        vst_factory->get_class_info(index, &class_infos[index])
    }
    
    
    component_id, _ := vst3.parse_uuid(vst3.IComponent_iid)
    result := vst_factory->create_instance(raw_data(class_infos[0].cid[:]), 
                                           raw_data(component_id[:]), 
                                           transmute(^rawptr)&vst_host.component_interface)
    assert(result == .Ok)
    
    
    result = vst_host.component_interface->initialize(transmute(^vst3.FUnknown)(&vst_host.host_interface))
    assert(result == .Ok) 
    

    controller_id, _ := vst3.parse_uuid(vst3.IEditController_iid)
    result = vst_host.component_interface->query_interface(raw_data(controller_id[:]), transmute(^rawptr)&vst_host.editor_interface)
    if result != .Ok {
        // editor is separate from processor (juce plugins do this)
    
        result = vst_factory->create_instance(raw_data(class_infos[1].cid[:]), 
                                              raw_data(controller_id[:]), 
                                              transmute(^rawptr)&vst_host.editor_interface)
        
        if result == .Ok {
            result = vst_host.editor_interface->initialize(transmute(^vst3.FUnknown)(&vst_host.host_interface))
            
            assert(result == .Ok)
        
        }
    
    } else {
        // single component (clap-wrapper does this)
        // result = vst_host.editor_interface->initialize(transmute(^vst3.FUnknown)&vst_host.host_interface)
        // assert(result == .Ok)
    
    }
    
    
    audio_processor_iid, _ := vst3.parse_uuid(vst3.IAudioProcessor_iid)
    result = vst_host.component_interface->query_interface(raw_data(audio_processor_iid[:]), 
                                                           transmute(^rawptr)&vst_host.audio_proc_interface)
    
}

vst_prepare_plugin_process :: proc(vst_host: ^Vst_Host, samplerate: f64, buffer_size: i32) {

    result: vst3.Result

    process_setup := vst3.ProcessSetup { process_mode = i32(vst3.ProcessMode.Realtime), 
                                         symbolic_sample_size = i32(vst3.SymbolicSampleSize.Sample32), 
                                         max_samples_per_block = buffer_size,
                                         sample_rate = samplerate }
    
    vst_host.audio_proc_interface->setup_processing(&process_setup)
    
    bus_arrangement := [1]vst3.SpeakerArrangement {.StereoSpeaker}
    result = vst_host.audio_proc_interface->set_bus_arrangements(raw_data(bus_arrangement[:]), 1, raw_data(bus_arrangement[:]), 1)
    assert(result == .Ok)
    
    result = vst_host.component_interface->activate_bus(.Audio, .Input, 0, u8(true))
    assert(result == .Ok)
    result = vst_host.component_interface->activate_bus(.Audio, .Output, 0, u8(true))
    assert(result == .Ok)
    
    vst_host.component_interface->set_active(u8(true))
    vst_host.audio_proc_interface->set_processing(u8(true))

}


vst_close_plugin :: proc(main_host: ^Plugin_Host) {

    main_host.vst_host.audio_proc_interface->set_processing(u8(false))
    main_host.vst_host.component_interface->set_active(u8(false))
    
    main_host.vst_host.audio_proc_interface->release()
    main_host.vst_host.editor_interface->terminate()
    main_host.vst_host.editor_interface->release()    
    main_host.vst_host.component_interface->terminate()
    main_host.vst_host.component_interface->release()

    dynlib.unload_library(main_host.dll_handle)
}
