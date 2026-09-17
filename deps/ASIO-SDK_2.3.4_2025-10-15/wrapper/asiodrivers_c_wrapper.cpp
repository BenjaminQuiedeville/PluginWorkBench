
#include <windows.h>
#include "../host/pc/asiolist.h"
#include "../host/asiodrivers.h"

extern AsioDrivers *asioDrivers;

bool loadAsioDriver(char *name);

#ifdef __cplusplus
extern "C" {
#endif

typedef void* pAsioDrivers;

void *c_asioDrivers = (void*)asioDrivers;
// void *c_theAsioDriver = (void*)theAsioDriver; 

pAsioDrivers AsioDrivers_allocate() { 
    return (pAsioDrivers)(new AsioDrivers()); 
}

void AsioDrivers_destroy(pAsioDrivers ptr) { 
    delete (AsioDrivers*)ptr; 
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
