package PluginWorkBench 

import "base:runtime"
import "core:dynlib"
import "core:strings"
import "core:fmt"
import "core:c"
import "core:os"

import ma "vendor:miniaudio"

import clap "../deps/clap-odin"
import clap_ext "../deps/clap-odin/ext"
import clap_factory "../deps/clap-odin/factory"

Clap_Host :: struct {

    host_params_ext: clap_ext.Host_Params,
    plugin_params_ext: ^clap_ext.Plugin_Params,
    plugin_params: []clap_ext.Param_Info,
    plugin_param_values: []f64,
    
    samplerate: f64,
    min_buffer_size: u32,
    max_buffer_size: u32,
    
    plugin: ^clap.Plugin,
}

clap_host_get_extension :: proc "c" (host: ^clap.Host, extension_id: cstring) -> rawptr {
    context = runtime.default_context()
    
    host_data := transmute(^Clap_Host)host.host_data
    
    switch extension_id {
        case clap_ext.EXT_PARAMS: { return &host_data.plugin_params_ext }
    }
    
    return nil    
}

clap_plugin_rescan_params :: proc "c" (host: ^clap.Host, flags: u32) {}
clap_plugin_clean_params :: proc "c" (host: ^clap.Host, param_id: clap.Clap_Id, flags: u32) {}
clap_plugin_request_flush :: proc "c" (host: ^clap.Host) {}

draft_clap_loader :: proc(plugin_path: string) {
    library, ok := dynlib.load_library(plugin_path)
    defer dynlib.unload_library(library)
    
    if !ok {
        fmt.println(dynlib.last_error())
        return
    }

    address, found := dynlib.symbol_address(library, "clap_entry")
    if !found {
        fmt.println("Procedure address not found")
        return
    }
    plugin_entry := transmute(^clap.Plugin_Entry)address
    plugin_entry.init(strings.clone_to_cstring(plugin_path))
    
    plugin_factory := transmute(^clap_factory.Plugin_Factory)plugin_entry.get_factory(clap_factory.PLUGIN_FACTORY_ID)
    plugin_count := plugin_factory->get_plugin_count()
    
    
    plugin_desc := plugin_factory->get_plugin_descriptor(0)

    fmt.println("plugin description")
    fmt.println(plugin_desc.id)
    fmt.println(plugin_desc.name)
    fmt.println(plugin_desc.vendor)
 
    if !clap.clap_version_is_compatible(plugin_desc.clap_version) {
        fmt.printfln("plugin's clap version not compatible: %d %d %d", plugin_desc.clap_version.major,
                                                                       plugin_desc.clap_version.minor,
                                                                       plugin_desc.clap_version.revision)
        return
    }
    
    host_data := Clap_Host {
        host_params_ext = {
            rescan = clap_plugin_rescan_params,
            clear = clap_plugin_clean_params, 
            request_flush = clap_plugin_request_flush,
        }
    }
    
    clap_host := clap.Host {
        clap_version = clap.CLAP_VERSION,
        host_data = &host_data,
        name = "Plugin Workbench",
        vendor = "FDN Seeker",
        url = "", 
        version = "0.0.0",
        
        get_extension = clap_host_get_extension,
        
        request_restart = proc "c" (host: ^clap.Host) {
            context = runtime.default_context()
            unimplemented()
        },
        
        request_process = proc "c" (host: ^clap.Host) {
            context = runtime.default_context()
            unimplemented()
        },
        
        request_callback = proc "c" (host: ^clap.Host) {
            context = runtime.default_context()
            unimplemented()
        },
    }
    
    host_data.plugin = plugin_factory->create_plugin(&clap_host, plugin_desc.id)
    
    ok = host_data.plugin->init()
    
    if !ok {
        host_data.plugin->destroy()
        return
    }

    { // parameter scaning 
        host_data.plugin_params_ext = transmute(^clap_ext.Plugin_Params)host_data.plugin.get_extension(host_data.plugin, clap_ext.EXT_PARAMS)
        
        param_count: u32 = host_data.plugin_params_ext.count(host_data.plugin)
        
        host_data.plugin_params = make([]clap_ext.Param_Info, param_count)
        host_data.plugin_param_values = make([]f64, param_count)
        
        for param_index in 0..<param_count {
            ok = host_data.plugin_params_ext.get_info(host_data.plugin, param_index, &host_data.plugin_params[param_index])
            assert(ok)
        } 
        
        for param_index in 0..<param_count {
            ok = host_data.plugin_params_ext.get_value(host_data.plugin, param_index, &host_data.plugin_param_values[param_index])
            assert(ok)
        }
    }
    
    host_data.samplerate = 48000.0
    host_data.min_buffer_size = 8
    host_data.max_buffer_size = 128
    host_data.plugin->activate(host_data.samplerate, host_data.min_buffer_size, host_data.max_buffer_size)

    // init les audio ports 
    // créer une liste d'event avec des event de process audio
    // créer la boucle temps réel avec miniaudio
    
    
    // process_context := clap.Process {
    //     steady_time = 0,
    //     frames_count = host_data.max_buffer_size,
    //     transport = ,
    //     audio_inputs = 
    //     audio_outputs
    //     audio_inputs_counts = 2,
    //     audio_outputs_counts = 2
        
        
    // }
}
