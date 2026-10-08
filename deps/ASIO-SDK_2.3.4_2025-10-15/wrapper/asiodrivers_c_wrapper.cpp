#include <windows.h>
#include <assert.h>

#include "../host/pc/asiolist.h"
#include "../host/asiodrivers.h"

extern AsioDrivers *asioDrivers;

bool loadAsioDriver(char *name);

#ifdef __cplusplus
extern "C" {
#endif

typedef void* pAsioDrivers;

pAsioDrivers AsioDrivers_allocate() {
    
    AsioDrivers *drivers = new AsioDrivers();
    asioDrivers = drivers;

    return (pAsioDrivers)drivers; 
}

void AsioDrivers_destroy(pAsioDrivers ptr) {

    assert(ptr == asioDrivers && "asioDrivers ptr passed not corresponding to global value");

    delete (AsioDrivers*)ptr; 
    asioDrivers = nullptr;
}

bool getCurrentDriverName(pAsioDrivers ptr, char *name) { 
    AsioDrivers *drivers = (AsioDrivers*)ptr;
    return drivers->getCurrentDriverName(name); 
}

long getDriverNames(pAsioDrivers ptr, char **names, long maxDrivers) { 
    AsioDrivers *drivers = (AsioDrivers*)ptr;
    return drivers->getDriverNames(names, maxDrivers); 
}

bool loadDriver(pAsioDrivers ptr, char *name) { 
    AsioDrivers *drivers = (AsioDrivers*)ptr;
    return drivers->loadDriver(name); 
}

void removeCurrentDriver(pAsioDrivers ptr) { 
    AsioDrivers *drivers = (AsioDrivers*)ptr;
    drivers->removeCurrentDriver(); 
}

long getCurrentDriverIndex(pAsioDrivers ptr) { 
    AsioDrivers *drivers = (AsioDrivers*)ptr;
    return drivers->getCurrentDriverIndex(); 
}

bool c_loadAsioDriver(char *name) {
    return loadAsioDriver(name);
}


#ifdef __cplusplus
}
#endif
