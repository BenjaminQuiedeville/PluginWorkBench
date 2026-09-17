package experiments

import "base:runtime"
import "core:c"
import "core:sys/windows"

import ma "vendor:miniaudio"

import "../source/asio"

main :: proc() {

    samplerate := 48000.0
    
    asio_result: asio.Error
    asio_drivers := asio.driversAllocate()
    // ndrivers := asio.getDriverNames(asio_drivers, raw_data(asio_backend.driver_names[:]), len(asio_backend.driver_names))
    loaded := asio.loadDriver(asio_drivers, "ASIO4ALL v2")
    
    driver_info: asio.DriverInfo
    driver_info.asioVersion = 2
    
    if asio.Init(&driver_info) != .OK {
        panic("")
    }
    
    ninput_channels, noutput_channels: c.long
    asio.GetChannels(&ninput_channels, &noutput_channels)

    min_buffer_size, max_buffer_size, preferred_buffer_size, granularity: c.long
    asio.GetBufferSize(&min_buffer_size, &max_buffer_size, &preferred_buffer_size, &granularity)

    asio_result = asio.CanSampleRate(samplerate)
    asio_result = asio.SetSampleRate(samplerate)
    
    current_samplerate: f64
    asio_result = asio.GetSampleRate(&current_samplerate)
    
    
    
    
    asio.Exit()
    
}
