package PluginWorkBench

import "base:runtime"

import "core:fmt"
import "core:dynlib"
import "core:strings"
import "core:slice"
import "core:encoding/uuid"

import vst3 "../deps/vst3_odin/vst3"

VST3_Entry_Proc :: proc "system" () -> bool
VST3_Get_Factory_Proc :: proc "system" () -> ^vst3.IPluginFactory3


PLUGIN_PROCESSOR_UUID: []u8

Vst_Message :: struct {
    interface: vst3.IMessage,
    attributes: vst3.IAttributeList,

    value_int: i64,
    value_f64: f64,
}

Vst_Connection_Point :: struct #packed {
    host: vst3.IConnectionPoint,
    plugin_editor: ^vst3.IConnectionPoint,
    plugin_component: ^vst3.IConnectionPoint,
    
    message: Vst_Message,
    parent: ^Vst_Host
}

Vst_Host :: struct {
    host_interface: vst3.IHostApplication,

    component: ^vst3.IComponent, 
    audio_proc: ^vst3.IAudioProcessor,

    editor: ^vst3.IEditController,
    component_handler: vst3.IComponentHandler,

    connection_point: Vst_Connection_Point,

    plugin_class_infos: []vst3.PClassInfo,
}

host_query_interface :: proc "system" (this: rawptr, iid: [^]u8, obj: ^rawptr) -> vst3.Result { 
    
    context = runtime.default_context()
    
    host_app_uuid, _ := vst3.parse_uuid(vst3.IHostApplication_iid)
    audio_processor_uuid, _ := vst3.parse_uuid(vst3.IAudioProcessor_iid)
    
    // the iid is defined to be 16 bytes long
    if slice.equal(iid[0:16], host_app_uuid[:]) {
        
        host := transmute(^vst3.IHostApplication)this
        obj^ = host
        
        return .Ok 
    } 
    // else if slice.equal(iid[0:16], audio_processor_uuid[:]) {
        
    //     connection_point := transmute(^vst3.IConnectionPoint)this
    //     obj^ = this
    // }
    
    return .NoInterface
}

host_add_ref :: proc "system" (this: rawptr) -> u32 { return 0 }
host_release :: proc "system" (this: rawptr) -> u32 { return 0 }


comp_handler_vtbl := vst3.IComponentHandlerVtbl {

    query_interface = host_query_interface,
    add_ref = host_add_ref,
    release = host_release,

    begin_edit = proc "system" (rawptr, u32) -> vst3.Result { return .Ok },
    perform_edit = proc "system" (rawptr, u32, f64) -> vst3.Result { return .Ok },
    end_edit = proc "system" (rawptr, u32) -> vst3.Result { return .Ok },
    restart_component = proc "system" (rawptr, i32) -> vst3.Result { return .Ok },
}

host_connection_point_vtbl := vst3.IConnectionPointVtbl {    
// probably unused
    query_interface = proc "system" (this: rawptr, iid: [^]u8, obj: ^rawptr) -> vst3.Result {
        context = runtime.default_context()
        
        // the plugin is querying its own processor
        connection_point := transmute(^Vst_Connection_Point)this
        vst_host := connection_point.parent

        obj^ = vst_host.audio_proc
        
        
        return .Ok
    },
    
    add_ref = host_add_ref,
    release = host_release,
    
    connect = proc "system" (rawptr, ^vst3.IConnectionPoint) -> vst3.Result {
        return .Ok    
    },
    
    disconnect = proc "system" (rawptr, ^vst3.IConnectionPoint) -> vst3.Result {
        return .Ok
    },
    
    notify = proc "system" (rawptr, ^vst3.IMessage) -> vst3.Result {
        return .Ok
    },
}

message_attribute_list_vbtl := vst3.IAttributeListVtbl {

    query_interface = host_query_interface,
    add_ref = host_add_ref,
    release = host_release,

    set_int = proc "system" (this: rawptr, id: cstring, value: i64) -> vst3.Result { 
    
        return .Ok 
    },
    get_int = proc "system" (this: rawptr, id: cstring, value: ^i64) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
    set_float = proc "system" (this: rawptr, id: cstring, value: f64) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
    get_float = proc "system" (this: rawptr, id: cstring, value: ^f64) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
    set_string = proc "system" (this: rawptr, id: cstring, str: ^u16) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
    get_string = proc "system" (this: rawptr, id: cstring, str: ^u16, size_bytes: u32) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
    set_binary = proc "system" (this: rawptr, id: cstring, data: rawptr, size_bytes: u32) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
    get_binary = proc "system" (this: rawptr, id: cstring, data: ^  rawptr, size_bytes: ^u32) -> vst3.Result { 
        context = runtime.default_context()
        assert(false, "not implemented")
        return .Ok 
    },
}

host_message_vtbl := vst3.IMessageVtbl {

    query_interface = host_query_interface,
    add_ref = host_add_ref,
    release = host_release,
    
    get_message_id = proc "system" (this: rawptr) -> cstring {
        return "HostMessage"
    },
    
    set_message_id = proc "system" (this: rawptr, id: cstring) {
        
    },
    
    get_attributes = proc "system" (this: rawptr) -> ^vst3.IAttributeList {
        message := transmute(^Vst_Message)this
        
        return &message.attributes
    },
}


vst_host_vtbl := vst3.IHostApplicationVtbl {
    query_interface = host_query_interface,
    add_ref = host_add_ref,
    release = host_release,
    
    get_name = proc "system" (this: rawptr, name_buffer: [^]u16) -> vst3.Result {
        host_name: string16 = "PluginWorkBench Host"
        copy(name_buffer[0:len(host_name)], host_name)
        
        return .Ok
    },

    create_instance = proc "system" (this: rawptr, class_id: [^]u8, iid: [^]u8, msg: ^rawptr) -> vst3.Result {
        context = runtime.default_context() 
               
        message_iid, _ := vst3.parse_uuid(vst3.IMessage_iid)
        
        // only implement IMessage for now
        if slice.equal(iid[0:16], message_iid[:]) {
            host := transmute(^Vst_Host)this
            message := transmute(^^vst3.IMessage)msg
            
            message^ = &host.connection_point.message.interface
        } else {
            assert(false, "not implemented")
        }    
        return .Ok
    },
}


vst_load_plugin :: proc(main_host: ^Plugin_Host, plugin_path: string) {
    
    vst_host := &main_host.vst_host
    vst_host.host_interface.vtbl = &vst_host_vtbl
    vst_host.connection_point.parent = vst_host
    vst_host.connection_point.host.vtbl = &host_connection_point_vtbl
    vst_host.connection_point.message.interface.vtbl = &host_message_vtbl    
    vst_host.connection_point.message.attributes.vtbl = &message_attribute_list_vbtl
    vst_host.component_handler.vtbl = &comp_handler_vtbl
    
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
    
    vst_host.plugin_class_infos = make([]vst3.PClassInfo, num_classes)
    PLUGIN_PROCESSOR_UUID = slice.clone(vst_host.plugin_class_infos[0].cid[0:16])

    for index in 0..<num_classes {
        vst_factory->get_class_info(index, &vst_host.plugin_class_infos[index])
    }
    
    
    component_id, _ := vst3.parse_uuid(vst3.IComponent_iid)
    result := vst_factory->create_instance(raw_data(vst_host.plugin_class_infos[0].cid[:]), 
                                           raw_data(component_id[:]), 
                                           transmute(^rawptr)&vst_host.component)
    assert(result == .Ok)
    
    
    result = vst_host.component->initialize(transmute(^vst3.FUnknown)(&vst_host.host_interface))
    assert(result == .Ok) 
    

    controller_id, _ := vst3.parse_uuid(vst3.IEditController_iid)
    result = vst_host.component->query_interface(raw_data(controller_id[:]), transmute(^rawptr)&vst_host.editor)
    if result != .Ok {
        // editor is separate from processor (juce plugins do this)
    
        result = vst_factory->create_instance(raw_data(vst_host.plugin_class_infos[1].cid[:]), 
                                              raw_data(controller_id[:]), 
                                              transmute(^rawptr)&vst_host.editor)
        
        if result == .Ok {
            result = vst_host.editor->initialize(transmute(^vst3.FUnknown)&vst_host.host_interface)
            assert(result == .Ok)
        }
    
    } else {
        // single component (clap-wrapper does this)
        // result = vst_host.editor->initialize(transmute(^vst3.FUnknown)&vst_host.host_interface)
        // assert(result == .Ok)
    
    }

    
    connection_point_iid, _ := vst3.parse_uuid(vst3.IConnectionPoint_iid)
    result = vst_host.editor->query_interface(raw_data(connection_point_iid[:]), 
                                                        transmute(^rawptr)&vst_host.connection_point.plugin_editor)
    // assert(result == .Ok)
    
    result = vst_host.component->query_interface(raw_data(connection_point_iid[:]), 
                                                 transmute(^rawptr)&vst_host.connection_point.plugin_component)
    
    audio_processor_iid, _ := vst3.parse_uuid(vst3.IAudioProcessor_iid)
    result = vst_host.component->query_interface(raw_data(audio_processor_iid[:]), 
                                                           transmute(^rawptr)&vst_host.audio_proc)
    
    result = vst_host.connection_point.plugin_editor->connect(vst_host.connection_point.plugin_component)
    assert(result == .Ok)

}

vst_prepare_plugin_process :: proc(vst_host: ^Vst_Host, samplerate: f64, buffer_size: i32) {

    result: vst3.Result

    process_setup := vst3.ProcessSetup { process_mode = i32(vst3.ProcessMode.Realtime), 
                                         symbolic_sample_size = i32(vst3.SymbolicSampleSize.Sample32), 
                                         max_samples_per_block = buffer_size,
                                         sample_rate = samplerate }
    
    vst_host.audio_proc->setup_processing(&process_setup)
    
    bus_arrangement := [1]vst3.SpeakerArrangement {.StereoSpeaker}
    result = vst_host.audio_proc->set_bus_arrangements(raw_data(bus_arrangement[:]), 1, raw_data(bus_arrangement[:]), 1)
    assert(result == .Ok)
    
    result = vst_host.component->activate_bus(.Audio, .Input, 0, u8(true))
    assert(result == .Ok)
    result = vst_host.component->activate_bus(.Audio, .Output, 0, u8(true))
    assert(result == .Ok)
    
    vst_host.component->set_active(u8(true))
    vst_host.audio_proc->set_processing(u8(true))


    // result = vst_host.component->set_state(nil)
    result = vst_host.editor->set_component_state(nil)
    
    result = vst_host.editor->set_component_handler(&vst_host.component_handler)
    assert(result == .Ok)

}


vst_close_plugin :: proc(main_host: ^Plugin_Host) {

    vst_host := &main_host.vst_host

    vst_host.audio_proc->set_processing(u8(false))
    vst_host.component->set_active(u8(false))

    vst_host.connection_point.plugin_editor->disconnect(&vst_host.connection_point.host)
    vst_host.connection_point.plugin_editor->release()
    vst_host.connection_point.plugin_component->release()
    
    vst_host.audio_proc->release()
    vst_host.editor->terminate()
    vst_host.editor->release()    
    vst_host.component->terminate()
    vst_host.component->release()

    dynlib.unload_library(main_host.dll_handle)
}
