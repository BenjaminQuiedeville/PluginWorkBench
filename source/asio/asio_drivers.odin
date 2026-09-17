package asio

import "core:c"

foreign import lib {
    "asio.lib",
    "system:ole32.lib",
    "system:user32.lib",
    "system:advapi32.lib",
}

// utility to list and load a driver before launching the ASIO machinery

@(default_calling_convention = "c")
foreign lib {
    
    @(link_name = "c_asioDrivers")
    asioDrivers: rawptr
    
    theAsioDriver: rawptr

    @(link_name = "AsioDrivers_allocate")
    driversAllocate :: proc() -> rawptr ---
    
    @(link_name = "AsioDrivers_destroy")
    driversDestroy :: proc(this: rawptr) ---
    
    // the name cstring has to be preallocated (32 characters max)
    getCurrentDriverName :: proc(this: rawptr, name: cstring) -> bool ---
    
    // the names have to be preallocated (32 characters max)
    getDriverNames :: proc(this: rawptr, names: [^]cstring, maxDrivers: c.long) -> c.long ---
    
    loadDriver :: proc(this: rawptr, name: cstring) -> bool ---
    
    removeCurrentDriver :: proc(this: rawptr) ---
    
    getCurrentDriverIndex :: proc(this: rawptr) -> c.long ---

    @(link_name = "c_loadAsioDriver")
    loadAsioDriver :: proc(name: cstring) -> bool ---
}
