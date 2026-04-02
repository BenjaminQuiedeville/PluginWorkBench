package PluginWorkBench

import "core:fmt"
import "core:dynlib"

import vst3 "../deps/vst3_odin/vst3"

VST3_Entry_Proc :: proc "system" () -> bool
VST3_Get_Factory_Proc :: proc "system" () -> ^vst3.IPluginFactory3

draft_vst3_loader :: proc() {
    plugin_path := "C:/Program Files/Common Files/VST3/AmpModeler.vst3/Contents/x86_64-win/AmpModeler.vst3"
    // plugin_path := "D:/Dev/clap/clap_ambient/build/cmake/Debug/clap_ambient.vst3"
    
    library, ok := dynlib.load_library(plugin_path)
    defer dynlib.unload_library(library)
    
    if !ok {
        fmt.println(dynlib.last_error())
        return
    }

    address, found := dynlib.symbol_address(library, "InitDll")

    if !found {
        fmt.println("Procedure address not found")
        return
    }
    
    init_proc := cast(VST3_Entry_Proc)address
    if !init_proc() {
        fmt.println("Error during plugin moule init")
        return 
    }
    
    
    address, found = dynlib.symbol_address(library, "GetPluginFactory")

    if !found {
        fmt.println("Procedure address not found")
        return
    }
    
    get_fact_proc := cast(VST3_Get_Factory_Proc)address
    plugin_factory: ^vst3.IPluginFactory3 = get_fact_proc()
    
    assert(plugin_factory != nil)        
    
    class_info: vst3.PClassInfo
    plugin_factory->get_class_info(0, &class_info)
    
    processor_component: ^vst3.IComponent
    
    component_id, _ := vst3.parse_uuid(vst3.IComponent_iid)
    result := plugin_factory->create_instance(raw_data(class_info.cid[:]), raw_data(component_id[:]), transmute(^rawptr)&processor_component)
    assert(result == .Ok)
    
    
    host_context: vst3.IHostApplication
    host_context.get_name = proc "system"(this: rawptr, name_buffer: [^]u16) -> vst3.Result {
        host_name: string16 = "PluginWorkBench Host"
        copy(name_buffer[0:len(host_name)], host_name)
        
        return .Ok
    }
    
    host_context.unknown.query_interface = proc "system" (this: rawptr, iid: [^]u8, obj: ^rawptr) -> vst3.Result { 
        obj^ = cast(^vst3.IHostApplication)this
        return .Ok 
    }
    
    host_context.unknown.add_ref = proc "system" (this: rawptr) -> u32 { return 0 }
    host_context.unknown.release = proc "system" (this: rawptr) -> u32 { return 0 }

    
    processor_component.plugin_base.initialize(processor_component, transmute(^vst3.FUnknown)&host_context.vtbl.unknown)
    
    
    
    processor_component->release()
    
    plugin_factory->release()
}
