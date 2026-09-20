package asio

import "core:c"

foreign import lib { 
    "asio.lib",
    "system:ole32.lib",
    "system:user32.lib",
    "system:advapi32.lib",
}

Samples :: c.longlong
TimeStamp :: c.longlong
SampleRate :: f64
Bool :: c.long

True :: Bool(true)
False :: Bool(false)

SampleType :: enum c.long {
    Int16MSB   = 0,
    Int24MSB   = 1,         // used for 20 bits as well
    Int32MSB   = 2,
    Float32MSB = 3,         // IEEE 754 32 bit float
    Float64MSB = 4,         // IEEE 754 64 bit double float

    // these are used for 32 bit data buffer, with different alignment of the data inside
    // 32 bit PCI bus systems can be more easily used with these
    Int32MSB16 = 8,         // 32 bit data with 16 bit alignment
    Int32MSB18 = 9,         // 32 bit data with 18 bit alignment
    Int32MSB20 = 10,        // 32 bit data with 20 bit alignment
    Int32MSB24 = 11,        // 32 bit data with 24 bit alignment
    
    Int16LSB   = 16,
    Int24LSB   = 17,        // used for 20 bits as well
    Int32LSB   = 18,
    Float32LSB = 19,        // IEEE 754 32 bit float, as found on Intel x86 architecture
    Float64LSB = 20,        // IEEE 754 64 bit double float, as found on Intel x86 architecture

    // these are used for 32 bit data buffer, with different alignment of the data inside
    // 32 bit PCI bus systems can more easily used with these
    Int32LSB16 = 24,        // 32 bit data with 18 bit alignment
    Int32LSB18 = 25,        // 32 bit data with 18 bit alignment
    Int32LSB20 = 26,        // 32 bit data with 20 bit alignment
    Int32LSB24 = 27,        // 32 bit data with 24 bit alignment

    //    ASIO DSD format.
    DSDInt8LSB1   = 32,        // DSD 1 bit data, 8 samples per byte. First sample in Least significant bit.
    DSDInt8MSB1   = 33,        // DSD 1 bit data, 8 samples per byte. First sample in Most significant bit.
    DSDInt8NER8   = 40,        // DSD 8 bit data, 1 sample per byte. No Endianness required.
}

/*-----------------------------------------------------------------------------
// DSD operation and buffer layout
// Definition by Steinberg/Sony Oxford.
//
// We have tried to treat DSD as PCM and so keep a consistant structure across
// the ASIO interface.
//
// DSD's sample rate is normally referenced as a multiple of 44.1Khz, so
// the standard sample rate is refered to as 64Fs (or 2.8224Mhz). We looked
// at making a special case for DSD and adding a field to the Future that
// would allow the user to select the Over Sampleing Rate (OSR) as a seperate
// entity but decided in the end just to treat it as a simple value of
// 2.8224Mhz and use the standard interface to set it.
//
// The second problem was the "word" size, in PCM the word size is always a
// greater than or equal to 8 bits (a byte). This makes life easy as we can
// then pack the samples into the "natural" size for the machine.
// In DSD the "word" size is 1 bit. This is not a major problem and can easily
// be dealt with if we ensure that we always deal with a multiple of 8 samples.
//
// DSD brings with it another twist to the Endianness religion. How are the
// samples packed into the byte. It would be nice to just say the most significant
// bit is always the first sample, however there would then be a performance hit
// on little endian machines. Looking at how some of the processing goes...
// Little endian machines like the first sample to be in the Least Significant Bit,
//   this is because when you write it to memory the data is in the correct format
//   to be shifted in and out of the words.
// Big endian machine prefer the first sample to be in the Most Significant Bit,
//   again for the same reasion.
//
// And just when things were looking really muddy there is a proposed extension to
// DSD that uses 8 bit word sizes. It does not care what endianness you use.
//
// Switching the driver between DSD and PCM mode
// Future allows for extending the ASIO API quite transparently.
// See SetIoFormat, GetIoFormat, CanDoIoFormat
//
//-----------------------------------------------------------------------------*/


//- - - - - - - - - - - - - - - - - - - - - - - - -
// Error codes
//- - - - - - - - - - - - - - - - - - - - - - - - -


Error :: enum c.long {
    OK = 0,                  // This value will be returned whenever the call succeeded
    SUCCESS = 0x3f4847a0,    // unique success return value for Future calls
    NotPresent = -1000,      // hardware input or output is not present or available
    HWMalfunction,           // hardware is malfunctioning (can be returned by any ASIO function)
    InvalidParameter,        // input parameter invalid
    InvalidMode,             // hardware is in a bad mode or used in a bad mode
    SPNotAdvancing,          // hardware is not running when sample position is inquired
    NoClock,                 // sample clock or rate cannot be determined or is not present
    NoMemory                 // not enough memory for completing the request
}


//- - - - - - - - - - - - - - - - - - - - - - - - -
// Time Info support
//- - - - - - - - - - - - - - - - - - - - - - - - -

TimeCode :: struct {
    speed: f64,                 // speed relation (fraction of nominal speed)
                                // optional; set to 0. or 1. if not supported
    timeCodeSamples: Samples,   // time in samples
    flags: TimeCodeFlags,       // some information flags (see below)
    future: [64]u8,
}

TimeCodeFlags :: enum c.ulong {
    Valid                = 1,
    Running              = 1 << 1,
    Reverse              = 1 << 2,
    Onspeed              = 1 << 3,
    Still                = 1 << 4,
    
    SpeedValid           = 1 << 8
}

TimeInfo :: struct {
    speed: f64,                     // absolute speed (1. = nominal)
    systemTime: TimeStamp,          // system time related to samplePosition, in nanoseconds
                                    // on mac, must be derived from Microseconds() (not UpTime()!)
                                    // on windows, must be derived from timeGetTime()
    samplePosition: Samples,
    sampleRate: SampleRate,         // current rate
    flags: TimeInfoFlags,           // (see below)
    reserved: [12]u8,
}

TimeInfoFlags :: enum c.ulong
{
    SystemTimeValid        = 1,            // must always be valid
    SamplePositionValid    = 1 << 1,       // must always be valid
    SampleRateValid        = 1 << 2,
    SpeedValid             = 1 << 3,
    
    SampleRateChanged      = 1 << 4,
    ClockSourceChanged     = 1 << 5
} 

Time :: struct {               // both input/output
    reserved: [4]c.long,       // must be 0
    timeInfo: TimeInfo,        // required
    timeCode: TimeCode,        // optional, evaluated if (timeCode.flags & kTcValid)
} 




//- - - - - - - - - - - - - - - - - - - - - - - - -
// application's audio stream handler callbacks
//- - - - - - - - - - - - - - - - - - - - - - - - -

Callbacks :: struct{
    bufferSwitch: proc "c" (doubleBufferIndex: c.long, directProcess: Bool), 
        // bufferSwitch indicates that both input and output are to be processed.
        // the current buffer half index (0 for A, 1 for B) determines
        // - the output buffer that the host should start to fill. the other buffer
        //   will be passed to output hardware regardless of whether it got filled
        //   in time or not.
        // - the input buffer that is now filled with incoming data. Note that
        //   because of the synchronicity of i/o, the input always has at
        //   least one buffer latency in relation to the output.
        // directProcess suggests to the host whether it should immedeately
        // start processing (directProcess == ASIOTrue), or whether its process
        // should be deferred because the call comes from a very low level
        // (for instance, a high level priority interrupt), and direct processing
        // would cause timing instabilities for the rest of the system. If in doubt,
        // directProcess should be set to ASIOFalse.0
        // Note: bufferSwitch may be called at interrupt time for highest efficiency.

    sampleRateDidChange: proc "c" (samplerate: SampleRate),
        // gets called when the AudioStreamIO detects a sample rate change
        // If sample rate is unknown, 0 is passed (for instance, clock loss
        // when externally synchronized).

    asioMessage: proc "c" (selector: MessageSelector, value: c.long, message: rawptr, opt: ^f64) -> c.long,
        // generic callback for various purposes, see selectors below.
        // note this is only present if the asio version is 2 or higher

    bufferSwitchTimeInfo: proc "c" (params: ^Time, doubleBufferIndex: c.long, directProcess: Bool) -> ^Time,
        // new callback with time info. makes GetSamplePosition() and various
        // calls to GetSampleRate obsolete,
        // and allows for timecode sync etc. to be preferred; will be used if
        // the driver calls asioMessage with selector SupportsTimeInfo.
}

// asioMessage selectors
MessageSelector :: enum c.long
{
    SelectorSupported = 1,      // selector in <value>, returns 1L if supported,
                                // 0 otherwise
    EngineVersion,              // returns engine (host) asio implementation version,
                                // 2 or higher
    ResetRequest,               // request driver reset. if accepted, this
                                // will close the driver (ASIO_Exit() ) and
                                // re-open it again (ASIO_Init() etc). some
                                // drivers need to reconfigure for instance
                                // when the sample rate changes, or some basic
                                // changes have been made in ASIO_ControlPanel().
                                // returns 1L; note the request is merely passed
                                // to the application, there is no way to determine
                                // if it gets accepted at this time (but it usually
                                // will be).
    BufferSizeChange,           // not yet supported, will currently always return 0L.
                                // for now, use ResetRequest instead.
                                // once implemented, the new buffer size is expected
                                // in <value>, and on success returns 1L
    ResyncRequest,              // the driver went out of sync, such that
                                // the timestamp is no longer valid. this
                                // is a request to re-start the engine and
                                // slave devices (sequencer). returns 1 for ok,
                                // 0 if not supported.
    LatenciesChanged,           // the drivers latencies have changed. The engine
                                // will refetch the latencies.
    SupportsTimeInfo,           // if host returns true here, it will expect the
                                // callback bufferSwitchTimeInfo to be called instead
                                // of bufferSwitch
    SupportsTimeCode,           // 
    MMCCommand,                 // unused - value: number of commands, message points to mmc commands
    SupportsInputMonitor,       // SupportsXXX return 1 if host supports this
    SupportsInputGain,          // unused and undefined
    SupportsInputMeter,         // unused and undefined
    SupportsOutputGain,         // unused and undefined
    SupportsOutputMeter,        // unused and undefined
    Overload,                   // driver detected an overload
}

//---------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------

//- - - - - - - - - - - - - - - - - - - - - - - - -
// (De-)Construction
//- - - - - - - - - - - - - - - - - - - - - - - - -

DriverInfo :: struct {
    asioVersion: c.long,              // currently, 2
    driverVersion: c.long,            // driver specific
    name: [32]u8,
    errorMessage: [124]u8,
    sysRef: rawptr,                   // on input: system reference
                                      // (Windows: application main window handle, Mac & SGI: 0)
}

ClockSource :: struct {
    index: c.long,                    // as used for SetClockSource()
    associatedChannel: c.long,        // for instance, S/PDIF or AES/EBU
    associatedGroup: c.long,          // see channel groups (GetChannelInfo())
    isCurrentSource: Bool,            // ASIOTrue if this is the current clock source
    name: [32]u8,                     // for user selection
}


ChannelInfo :: struct {
    channel: c.long,                  // on input, channel index
    isInput: Bool,                    // on input
    isActive: Bool,                   // on exit
    channelGroup: c.long,             // dto
    type: SampleType,                 // dto
    name: [32]u8,                     // dto
}

BufferInfo :: struct {
    isInput: Bool,                    // on input:  ASIOTrue: input, else output
    channelNum: c.long,               // on input:  channel index
    buffers: [2]rawptr,               // on output: double buffer addresses
}


FutureSelector :: enum c.long {
    EnableTimeCodeRead = 1,           // no arguments
    DisableTimeCodeRead,              // no arguments
    SetInputMonitor,                  // InputMonitor* in params
    Transport,                        // TransportParameters* in params
    SetInputGain,                     // ChannelControls* in params, apply gain
    GetInputMeter,                    // ChannelControls* in params, fill meter
    SetOutputGain,                    // ChannelControls* in params, apply gain
    GetOutputMeter,                   // ChannelControls* in params, fill meter
    CanInputMonitor,                  // no arguments for CanXXX selectors
    CanTimeInfo,
    CanTimeCode,
    CanTransport,
    CanInputGain,
    CanInputMeter,
    CanOutputGain,
    CanOutputMeter,
    OptionalOne,
    
    //    DSD support
    //    The following extensions are required to allow switching
    //    and control of the DSD subsystem.
    SetIoFormat            = 0x23111961,          /* ASIOIoFormat * in params.            */
    GetIoFormat            = 0x23111983,          /* ASIOIoFormat * in params.            */
    CanDoIoFormat            = 0x23112004,        /* ASIOIoFormat * in params.            */
    
    // Extension for drop out detection
    CanReportOverload            = 0x24042012,    /* return ASE_SUCCESS if driver can detect and report overloads */
    
    GetInternalBufferSamples    = 0x25042012      /* ASIOInternalBufferInfo * in params. Deliver size of driver internal buffering, return ASE_SUCCESS if supported */
}

InputMonitor :: struct {
    input: c.long,        // this input was set to monitor (or off), -1: all
    output: c.long,       // suggested output for monitoring the input (if so)
    gain: c.long,         // suggested gain, ranging 0 - 0x7fffffffL (-inf to +12 dB)
    state: Bool,          // ASIOTrue => on, ASIOFalse => off
    pan: c.long,          // suggested pan, 0 => all left, 0x7fffffff => right
}

ChannelControls :: struct {
    channel: c.long,      // on input, channel index
    isInput: Bool,        // on input
    gain: c.long,         // on input,  ranges 0 thru 0x7fffffff
    meter: c.long,        // on return, ranges 0 thru 0x7fffffff
    future: [32]u8,
}

TransportParameters :: struct {
    command: TransportParameterType,        // see enum below
    samplePosition: Samples,
    track: c.long,
    trackSwitches: [16]c.long,              // 512 tracks on/off
    future: [64]u8,
}

TransportParameterType :: enum c.long
{
    Start = 1,
    Stop,
    Locate,             // to samplePosition
    PunchIn,
    PunchOut,
    ArmOn,              // track
    ArmOff,             // track
    MonitorOn,          // track
    MonitorOff,         // track
    Arm,                // trackSwitches
    Monitor             // trackSwitches
}

/*
// DSD support
//    Some notes on how to use IoFormatType.
//
//    The caller will fill the format with the request types.
//    If the board can do the request then it will leave the
//    values unchanged. If the board does not support the
//    request then it will change that entry to Invalid (-1)
//
//    So to request DSD then
//
//    ASIOIoFormat NeedThis={kASIODSDFormat};
//
//    if(ASE_SUCCESS != Future(SetIoFormat,&NeedThis) ){
//        // If the board did not accept one of the parameters then the
//        // whole call will fail and the failing parameter will
//        // have had its value changes to -1.
//    }
//
// Note: Switching between the formats need to be done before the "prepared"
// state (see ASIO 2 documentation) is entered.
*/
IoFormatType :: enum c.long {
    FormatInvalid = -1,
    PCMFormat = 0,
    DSDFormat = 1,
}

IoFormat :: struct {
    FormatType: IoFormatType, 
    future: [512-size_of(IoFormatType)]u8, // size of the int representing ASIOIOFormatType (8)
}

// Extension for drop detection
// Note: Refers to buffering that goes beyond the double buffer e.g. used by USB driver designs
InternalBufferInfo :: struct {
    inputSamples: c.long,            // size of driver's internal input buffering which is included in getLatencies
    outputSamples: c.long,            // size of driver's internal output buffering which is included in getLatencies
}

@(default_calling_convention = "c", link_prefix = "ASIO")
foreign lib {

    Init :: proc(info: ^DriverInfo) -> Error ---
    /* Purpose:
          Initialize the AudioStreamIO.
        Parameter:
          info: pointer to an ASIODriver structure:
            - asioVersion:
                - on input, the host version. *** Note *** this is 0 for earlier asio
                implementations, and the asioMessage callback is implemeted
                only if asioVersion is 2 or greater. sorry but due to a design fault
                the driver doesn't have access to the host version in Init :-(
                added selector for host (engine) version in the asioMessage callback
                so we're ok from now on.
                - on return, asio implementation version.
                  older versions are 1
                  if you support this version (namely, ASIO_outputReady() )
                  this should be 2 or higher. also see the note in
                  ASIO_getTimeStamp() !
            - version: on return, the driver version (format is driver specific)
            - name: on return, a null-terminated string containing the driver's name
            - error message: on return, should contain a user message describing
              the type of error that occured during Init(), if any.
            - sysRef: platform specific
        Returns:
          If neither input nor output is present ASE_NotPresent
          will be returned.
          ASE_NoMemory, ASE_HWMalfunction are other possible error conditions
    */

    Exit :: proc() -> Error ---
    /* Purpose:
          Terminates the AudioStreamIO.
        Parameter:
          None.
        Returns:
          If neither input nor output is present ASE_NotPresent
          will be returned.
        Notes: this implies Stop() and DisposeBuffers(),
          meaning that no host callbacks must be accessed after Exit().
    */
    
    //- - - - - - - - - - - - - - - - - - - - - - - - -
    // Start/Stop
    //- - - - - - - - - - - - - - - - - - - - - - - - -
    
    Start :: proc() -> Error ---
    /* Purpose:
          Start input and output processing synchronously.
          This will
          - reset the sample counter to zero
          - start the hardware (both input and output)
            The first call to the hosts' bufferSwitch(index == 0) then tells
            the host to read from input buffer A (index 0), and start
            processing to output buffer A while output buffer B (which
            has been filled by the host prior to calling Start())
            is possibly sounding (see also GetLatencies()) 
        Parameter:
          None.
        Returns:
          If neither input nor output is present, ASE_NotPresent
          will be returned.
          If the hardware fails to start, ASE_HWMalfunction will be returned.
        Notes:
          There is no restriction on the time that Start() takes
          to perform (that is, it is not considered a realtime trigger).
    */
    
    Stop :: proc() -> Error ---
    /* Purpose:
          Stops input and output processing altogether.
        Parameter:
          None.
        Returns:
          If neither input nor output is present ASE_NotPresent
          will be returned.
        Notes:
          On return from Stop(), the driver must in no
          case call the hosts' bufferSwitch() routine.
    */
    
    //- - - - - - - - - - - - - - - - - - - - - - - - -
    // Inquiry methods and sample rate
    //- - - - - - - - - - - - - - - - - - - - - - - - -
    
    GetChannels :: proc (numInputChannels: ^c.long, numOutputChannels: ^c.long) -> Error ---
    /* Purpose:
          Returns number of individual input/output channels.
        Parameter:
          numInputChannels will hold the number of available input channels
          numOutputChannels will hold the number of available output channels
        Returns:
          If no input/output is present ASE_NotPresent will be returned.
          If only inputs, or only outputs are available, the according
          other parameter will be zero, and ASE_OK is returned.
    */
    
    GetLatencies :: proc(inputLatency: ^c.long, outputLatency: ^c.long) -> Error ---
    /* Purpose:
          Returns the input and output latencies. This includes
          device specific delays, like FIFOs etc.
        Parameter:
          inputLatency will hold the 'age' of the first sample frame
          in the input buffer when the hosts reads it in bufferSwitch()
          (this is theoretical, meaning it does not include the overhead
          and delay between the actual physical switch, and the time
          when bufferSitch() enters).
          This will usually be the size of one block in sample frames, plus
          device specific latencies.
    
          outputLatency will specify the time between the buffer switch,
          and the time when the next play buffer will start to sound.
          The next play buffer is defined as the one the host starts
          processing after (or at) bufferSwitch(), indicated by the
          index parameter (0 for buffer A, 1 for buffer B).
          It will usually be either one block, if the host writes directly
          to a dma buffer, or two or more blocks if the buffer is 'latched' by
          the driver. As an example, on Start(), the host will have filled
          the play buffer at index 1 already; when it gets the callback (with
          the parameter index == 0), this tells it to read from the input
          buffer 0, and start to fill the play buffer 0 (assuming that now
          play buffer 1 is already sounding). In this case, the output
          latency is one block. If the driver decides to copy buffer 1
          at that time, and pass it to the hardware at the next slot (which
          is most commonly done, but should be avoided), the output latency
          becomes two blocks instead, resulting in a total i/o latency of at least
          3 blocks. As memory access is the main bottleneck in native dsp processing,
          and to acheive less latency, it is highly recommended to try to avoid
          copying (this is also why the driver is the owner of the buffers). To
          summarize, the minimum i/o latency can be acheived if the input buffer
          is processed by the host into the output buffer which will physically
          start to sound on the next time slice. Also note that the host expects
          the bufferSwitch() callback to be accessed for each time slice in order
          to retain sync, possibly recursively; if it fails to process a block in
          time, it will suspend its operation for some time in order to recover.
        Returns:
          If no input/output is present ASE_NotPresent will be returned.
    */
    
    GetBufferSize :: proc(minSize: ^c.long, maxSize: ^c.long, preferredSize: ^c.long, granularity: ^c.long) -> Error ---
    /* Purpose:
          Returns min, max, and preferred buffer sizes for input/output
        Parameter:
          minSize will hold the minimum buffer size
          maxSize will hold the maxium possible buffer size
          preferredSize will hold the preferred buffer size (a size which
          best fits performance and hardware requirements)
          granularity will hold the granularity at which buffer sizes
          may differ. Usually, the buffer size will be a power of 2;
          in this case, granularity will hold -1 on return, signalling
          possible buffer sizes starting from minSize, increased in
          powers of 2 up to maxSize.
        Returns:
          If no input/output is present ASE_NotPresent will be returned.
        Notes:
          When minimum and maximum buffer size are equal,
          the preferred buffer size has to be the same value as well; granularity
          should be 0 in this case.
    */
    
    CanSampleRate :: proc(sampleRate: SampleRate) -> Error ---
    /* Purpose:
          Inquires the hardware for the available sample rates.
        Parameter:
          sampleRate is the rate in question.
        Returns:
          If the inquired sample rate is not supported, ASE_NoClock will be returned.
          If no input/output is present ASE_NotPresent will be returned.
    */
    GetSampleRate :: proc(currentRate: ^SampleRate) -> Error ---
    /* Purpose:
          Get the current sample Rate.
        Parameter:
          currentRate will hold the current sample rate on return.
        Returns:
          If sample rate is unknown, sampleRate will be 0 and ASE_NoClock will be returned.
          If no input/output is present ASE_NotPresent will be returned.
        Notes:
    */
    
    SetSampleRate :: proc(sampleRate: SampleRate) -> Error ---
    /* Purpose:
          Set the hardware to the requested sample Rate. If sampleRate == 0,
          enable external sync.
        Parameter:
          sampleRate: on input, the requested rate
        Returns:
          If sampleRate  is unknown ASE_NoClock will be returned.
          If the current clock is external, and sampleRate is != 0,
          ASE_InvalidMode will be returned
          If no input/output is present ASE_NotPresent will be returned.
        Notes:
    */
    
    GetClockSources :: proc(clocks: [^]ClockSource, numSources: ^c.long) -> Error ---
    /* Purpose:
          Get the available external audio clock sources
        Parameter:
          clocks points to an array of ClockSource structures:
            - index: this is used to identify the clock source
              when SetClockSource() is accessed, should be
              an index counting from zero
            - associatedInputChannel: the first channel of an associated
              input group, if any.
            - associatedGroup: the group index of that channel.
              groups of channels are defined to seperate for
              instance analog, S/PDIF, AES/EBU, ADAT connectors etc,
              when present simultaniously. Note that associated channel
              is enumerated according to numInputs/numOutputs, means it
              is independant from a group (see also GetChannelInfo())
              inputs are associated to a clock if the physical connection
              transfers both data and clock (like S/PDIF, AES/EBU, or
              ADAT inputs). if there is no input channel associated with
              the clock source (like Word Clock, or internal oscillator), both
              associatedChannel and associatedGroup should be set to -1.
            - isCurrentSource: on exit, ASIOTrue if this is the current clock
              source, ASIOFalse else
            - name: a null-terminated string for user selection of the available sources.
          numSources:
              on input: the number of allocated array members
              on output: the number of available clock sources, at least
              1 (internal clock generator).
        Returns:
          If no input/output is present ASE_NotPresent will be returned.
        Notes:
    */
    
    SetClockSource :: proc(index: c.long) -> Error ---
    /* Purpose:
          Set the audio clock source
        Parameter:
          index as obtained from an inquiry to GetClockSources()
        Returns:
          If no input/output is present ASE_NotPresent will be returned.
          If the clock can not be selected because an input channel which
          carries the current clock source is active, ASE_InvalidMode
          *may* be returned (this depends on the properties of the driver
          and/or hardware).
        Notes:
          Should *not* return ASE_NoClock if there is no clock signal present
          at the selected source; this will be inquired via GetSampleRate().
          It should call the host callback procedure sampleRateHasChanged(),
          if the switch causes a sample rate change, or if no external clock
          is present at the selected source.
    */
    
    GetSamplePosition :: proc (sPos: ^Samples, tStamp: ^TimeStamp) -> Error ---
    /* Purpose:
          Inquires the sample position/time stamp pair.
        Parameter:
          sPos will hold the sample position on return. The sample
          position is reset to zero when Start() gets called.
          tStamp will hold the system time when the sample position
          was latched.
        Returns:
          If no input/output is present, ASE_NotPresent will be returned.
          If there is no clock, ASE_SPNotAdvancing will be returned.
        Notes:
    
          in order to be able to synchronise properly,
          the sample position / time stamp pair must refer to the current block,
          that is, the engine will call GetSamplePosition() in its bufferSwitch()
          callback and expect the time for the current block. thus, when requested
          in the very first bufferSwitch after ASIO_Start(), the sample position
          should be zero, and the time stamp should refer to the very time where
          the stream was started. it also means that the sample position must be
          block aligned. the driver must ensure proper interpolation if the system
          time can not be determined for the block position. the driver is responsible
          for precise time stamps as it usually has most direct access to lower
          level resources. proper behaviour of ASIO_GetSamplePosition() and ASIO_GetLatencies()
          are essential for precise media synchronization!
    */
    
    GetChannelInfo :: proc(info: ^ChannelInfo) -> Error ---
    /* Purpose:
          retreive information about the nature of a channel
        Parameter:
          info: pointer to a ChannelInfo structure with
            - channel: on input, the channel index of the channel in question.
            - isInput: on input, ASIOTrue if info for an input channel is
              requested, else output
            - channelGroup: on return, the channel group that the channel
              belongs to. For drivers which support different types of
              channels, like analog, S/PDIF, AES/EBU, ADAT etc interfaces,
              there should be a reasonable grouping of these types. Groups
              are always independant form a channel index, that is, a channel
              index always counts from 0 to numInputs/numOutputs regardless
              of the group it may belong to.
              There will always be at least one group (group 0). Please
              also note that by default, the host may decide to activate
              channels 0 and 1; thus, these should belong to the most
              useful type (analog i/o, if present).
            - type: on return, contains the sample type of the channel
            - isActive: on return, ASIOTrue if channel is active as it was
              installed by CreateBuffers(), ASIOFalse else
            - name:  describing the type of channel in question. Used to allow
              for user selection, and enabling of specific channels. examples:
              "Analog In", "SPDIF Out" etc
        Returns:
          If no input/output is present ASE_NotPresent will be returned.
        Notes:
          If possible, the string should be organised such that the first
          characters are most significantly describing the nature of the
          port, to allow for identification even if the view showing the
          port name is too small to display more than 8 characters, for
          instance.
    */
    
    //- - - - - - - - - - - - - - - - - - - - - - - - -
    // Buffer preparation
    //- - - - - - - - - - - - - - - - - - - - - - - - -
    
    
    CreateBuffers :: proc(bufferInfos: [^]BufferInfo, numChannels: c.long, bufferSize: c.long, callbacks: ^Callbacks) -> Error ---
    /* Purpose:
          Allocates input/output buffers for all input and output channels to be activated.
        Parameter:
          bufferInfos is a pointer to an array of BufferInfo structures:
            - isInput: on input, ASIOTrue if the buffer is to be allocated
              for an input, output buffer else
            - channelNum: on input, the index of the channel in question
              (counting from 0)
            - buffers: on exit, 2 pointers to the halves of the channels' double-buffer.
              the size of the buffer(s) of course depend on both the SampleType
              as obtained from GetChannelInfo(), and bufferSize
          numChannels is the sum of all input and output channels to be created;
          thus bufferInfos is a pointer to an array of numChannels BufferInfo
          structures.
          bufferSize selects one of the possible buffer sizes as obtained from
          ASIOGetBufferSizes().
          callbacks is a pointer to an Callbacks structure.
        Returns:
          If not enough memory is available ASE_NoMemory will be returned.
          If no input/output is present ASE_NotPresent will be returned.
          If bufferSize is not supported, or one or more of the bufferInfos elements
          contain invalid settings, ASE_InvalidMode will be returned.
        Notes:
          If individual channel selection is not possible but requested,
          the driver has to handle this. namely, bufferSwitch() will only
          have filled buffers of enabled outputs. If possible, processing
          and buss activities overhead should be avoided for channels which
          were not enabled here.
    */
    
    DisposeBuffers :: proc() -> Error ---
    /* Purpose:
          Releases all buffers for the device.
        Parameter:
          None.
        Returns:
          If no buffer were ever prepared, ASE_InvalidMode will be returned.
          If no input/output is present ASE_NotPresent will be returned.
        Notes:
          This implies Stop().
    */
    
    ControlPanel :: proc() -> Error ---
    /* Purpose:
          request the driver to start a control panel component
          for device specific user settings. This will not be
          accessed on some platforms (where the component is accessed
          instead).
        Parameter:
          None.
        Returns:
          If no panel is available ASE_NotPresent will be returned.
          Actually, the return code is ignored.
        Notes:
          if the user applied settings which require a re-configuration
          of parts or all of the enigine and/or driver (such as a change of
          the block size), the asioMessage callback can be used (see
          ASIO_Callbacks).
    */
    
    Future :: proc(selector: FutureSelector, params: rawptr) -> Error ---
    /* Purpose:
          various
        Parameter:
          selector: operation Code as to be defined. zero is reserved for
          testing purposes.
          params: depends on the selector; usually pointer to a structure
          for passing and retreiving any type and amount of parameters.
        Returns:
          the return value is also selector dependant. if the selector
          is unknown, ASE_InvalidParameter should be returned to prevent
          further calls with this selector. on success, ASE_SUCCESS
          must be returned (note: ASE_OK is *not* sufficient!)
        Notes:
          see selectors defined below.      
    */
    
    
    
    OutputReady :: proc() -> Error ---
    /* Purpose:
          this tells the driver that the host has completed processing
          the output buffers. if the data format required by the hardware
          differs from the supported asio formats, but the hardware
          buffers are DMA buffers, the driver will have to convert
          the audio stream data; as the bufferSwitch callback is
          usually issued at dma block switch time, the driver will
          have to convert the *previous* host buffer, which increases
          the output latency by one block.
          when the host finds out that OutputReady() returns
          true, it will issue this call whenever it completed
          output processing. then the driver can convert the
          host data directly to the dma buffer to be played next,
          reducing output latency by one block.
          another way to look at it is, that the buffer switch is called
          in order to pass the *input* stream to the host, so that it can
          process the input into the output, and the output stream is passed
          to the driver when the host has completed its process.
        Parameter:
            None
        Returns:
          only if the above mentioned scenario is given, and a reduction
          of output latency can be acheived by this mechanism, should
          ASE_OK be returned. otherwise (and usually), ASE_NotPresent
          should be returned in order to prevent further calls to this
          function. note that the host may want to determine if it is
          to use this when the system is not yet fully initialized, so
          ASE_OK should always be returned if the mechanism makes sense.      
        Notes:
          please remeber to adjust GetLatencies() according to
          whether OutputReady() was ever called or not, if your
          driver supports this scenario.
          also note that the engine may fail to call ASIO_OutputReady()
          in time in overload cases. as already mentioned, bufferSwitch
          should be called for every block regardless of whether a block
          could be processed in time.
    */
}
