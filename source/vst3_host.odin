package PluginWorkBench

import "base:runtime"

import "core:fmt"
import "core:dynlib"
import "core:strings"
import "core:slice"

import vst3 "../deps/vst3_odin/vst3"

VST3_Entry_Proc :: proc "system" () -> bool
VST3_Get_Factory_Proc :: proc "system" () -> ^vst3.IPluginFactory3

VstHost :: struct {
    host_context: vst3.IHostApplication,

}

host_context_vtbl := vst3.IHostApplicationVtbl {
    query_interface = proc "system" (this: rawptr, iid: [^]u8, obj: ^rawptr) -> vst3.Result { 
        
        context = runtime.default_context()
        
        host_app_uuid, err := vst3.parse_uuid(vst3.IHostApplication_iid)
        assert(err == .Ok)
        
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


draft_vst3_loader :: proc(plugin_path: string) {
    
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
    vst_factory: ^vst3.IPluginFactory3 = get_fact_proc()
    
    assert(vst_factory != nil)        
    
    num_classes := vst_factory->count_classes()
    assert(num_classes == 1)
    
    class_info: vst3.PClassInfo
    vst_factory->get_class_info(0, &class_info)
    
    processor_component: ^vst3.IComponent
    
    component_id, _ := vst3.parse_uuid(vst3.IComponent_iid)
    result := vst_factory->create_instance(raw_data(class_info.cid[:]), raw_data(component_id[:]), transmute(^rawptr)&processor_component)
    assert(result == .Ok)
    
    host: VstHost
    host.host_context.vtbl = &host_context_vtbl
    
    processor_component->initialize(transmute(^vst3.FUnknown)(&host.host_context))
    
    processor_component->terminate()
    vst_factory->release()
}
