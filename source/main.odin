package PluginWorkBench

import "core:fmt"
import "core:c"
import "core:os"
import "core:dynlib"
import "core:strings"
import "base:runtime"

import ma "vendor:miniaudio"

Plugin_Host :: struct {

    samplerate: f64, 
    
    // miniaudio stuff
    
    vst_host: Vst_Host,
    clap_host: Clap_host,

}

main :: proc() {
        
    // assert(len(os.args) >= 2)
    // plugin_path := os.args[1]
    // plugin_path := "../clap/clap_ambient/build/cmake/Debug/clap_ambient.vst3"
    plugin_path := "W:/AmpModeler/build/AmpModeler_artefacts/Debug/VST3/AmpModeler.vst3/Contents/x86_64-win/AmpModeler.vst3"
    

    /*
        grosse struct avec toutes les données
        dans cette struct, les sous-struct dépendant des backends (clap, vst, odin, faust)
        
        - allouer
        - load minimal du plugin
        - setup miniaudio
        - setup plugin processing
        - lancer la boucle audio
    */
    
    host: Plugin_Host
    host.samplerate = 48000.0
    host.vst_host.host_interface.vtbl = &vst_host_vtbl
    
    load_vst3(&host, plugin_path)
    
    
    
}
