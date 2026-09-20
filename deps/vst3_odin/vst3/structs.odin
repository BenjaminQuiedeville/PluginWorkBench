package vst3

import "core:c"

ViewRect :: struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
}

NoteExpressionValueDescription :: struct {
    default_value: f64,
    minimum: f64,
    maximum: f64,
    step_count: i32,
}

NoteExpressionValueEvent :: struct {
    type_id: NoteExpressionTypeID,
    note_id: i32,
    value: f64,
}

NoteExpressionTextEvent :: struct {
    type_id: NoteExpressionTypeID,
    note_id: i32,
    text_len: u32,
    text: ^u16,
}

NoteExpressionTypeInfo :: struct {
    type_id: NoteExpressionTypeID,
    title: [128]u16,
    short_title: [128]u16,
    units: [128]u16,
    unit_id: i32,
    value_desc: NoteExpressionValueDescription,
    associated_parameter_id: u32,
    flags: i32,
}

KeyswitchInfo :: struct #packed
{
    type_id: KeyswitchTypeID,
    title: [128]u16,
    short_title: [128]u16,
    keyswitch_min: i32,
    keyswitch_max: i32,
    key_remapped: i32,
    unit_id: i32,
    flags: i32,
}

PhysicalUIMap :: struct {
    physical_ui_type_id: PhysicalUITypeID,
    note_expression_type_id: NoteExpressionTypeID,
}

PhysicalUIMapList :: struct {
    count: u32,
    ui_map: ^PhysicalUIMap,
}

PFactoryInfo :: struct {
    vendor: [64]u8,
    url: [256]u8,
    email: [128]u8,
    flags: i32,
    
}

PClassInfo :: struct {
    cid: [16]u8,
    cardinality: i32,
    category: [32]u8,
    name: [64]u8,
}

PClassInfo2 :: struct {
    cid: [16]u8,
    cardinality: i32,
    category: [32]u8,
    name: [64]u8,
    class_flags: u32,
    sub_categories: [128]u8,
    vendor: [64]u8,
    version: [64]u8,
    sdk_version: [64]u8,
}

PClassInfoW :: struct {
    cid: [16]u8,
    cardinality: i32,
    category: [32]u8,
    name: [64]u16,
    class_flags: u32,
    sub_categories: [128]u8,
    vendor: [64]u16,
    version: [64]u16,
    sdk_version: [64]u16,
}

BusInfo :: struct {
    media_type: MediaType,
    direction: BusDirection,
    channel_count: i32,
    name: [128]u16,
    bus_type: BusType,
    flags: BusFlags,
}

RoutingInfo :: struct {
    media_type: MediaType,
    bus_index: i32,
    channel: i32,
}

ParameterInfo :: struct {
    id: u32,
    title: [128]u16,
    short_title: [128]u16,
    units: [128]u16,
    step_count: i32,
    default_normalised_value: f64,
    unit_id: UnitID,
    flags: i32,
}

FrameRate :: struct {
    framesPerSecond: u32,
    flags: u32,
}

Chord :: struct {
    key_note: u8,
    root_note: u8,
    chord_mask: i16,
}

ProcessContext :: struct {
    state: u32,
    sample_rate: f64,
    project_time_samples: i64,
    system_time: i64,
    continous_time_samples: i64,
    project_time_music: f64,
    bar_position_music: f64,
    cycle_start_music: f64,
    cycle_end_music: f64,
    tempo: f64,
    time_sig_numerator: i32,
    time_sig_denominator: i32, 
    chord: Chord,
    smpte_offset_subframes: i32,
    frame_rate: FrameRate,
    samples_to_next_clock: i32,
}

NoteOnEvent :: struct {
    channel: i16,
    pitch: i16,
    tuning: f32,
    velocity: f32,
    length: i32,
    noteId: i32,
}

NoteOffEvent :: struct {
    channel: i16,
    pitch: i16,
    velocity: f32,
    noteId: i32,
    tuning: f32,
}

DataEvent :: struct {
    size: u32,
    type: u32,
    bytes: ^u8,
}

PolyPressureEvent :: struct {
    channel: i16,
    pitch: i16,
    pressure: f32,
    note_id: i32,
}

ChordEvent :: struct {
    root: i16,
    bassNote: i16,
    mask: i16,
    textLen: u16,
    text: ^u16,
}

ScaleEvent :: struct {
    root: i16,
    mask: i16,
    textLen: u16,
    text: ^u16,
}

LegacyMIDICCOutEvent :: struct {
    controlNumber: u8,
    channel: i8,
    value: i8,
    value2: i8,
}

EventVariant :: struct #raw_union {
    note_on: NoteOnEvent,
    note_off: NoteOffEvent,
    data: DataEvent,
    poly_pressure: PolyPressureEvent,
    note_expression_value: NoteExpressionValueEvent,
    note_expression_text: NoteExpressionTextEvent,
    chord: ChordEvent,
    scale: ScaleEvent,
    midi_cc_out: LegacyMIDICCOutEvent,
}

Event :: struct {
    bus_index: i32,
    sample_offset: i32,
    ppq_position: f64,
    flags: EventFlag,
    type: EventType,
    using event: EventVariant,
}

RepresentationInfo :: struct {
    vendor: [64]u8,
    name: [64]u8,
    version: [64]u8,
    host: [64]u8,
}

IContextMenuItem :: struct {
    name: [128]u16,
    tag: i32,
    flags: i32,
}

DataExchangeBlock :: struct {
    data: rawptr,
    size: u32,
    block_id: u32,
}

ProcessSetup :: struct {
    process_mode: i32,
    symbolic_sample_size: i32,
    max_samples_per_block: i32,
    sample_rate: f64,
}

AudioBusBufferVariant :: struct #raw_union {
    buffers_32: [^][^]f32,
    buffers_64: [^][^]f64,
}

AudioBusBuffers :: struct {
    num_channels: i32,
    silence_flags: u64,
    using buffers: AudioBusBufferVariant,
}

ProcessData :: struct {
    process_mode: ProcessMode,
    symbolic_sample_size: SymbolicSampleSize,
    num_samples: i32,
    num_inputs: i32,
    num_outputs: i32,
    inputs: [^]AudioBusBuffers,
    outputs: [^]AudioBusBuffers,
    inputParameterChanges:  ^IParameterChanges,
    outputParameterChanges: ^IParameterChanges,
    input_events: ^IEventList,
    output_events: ^IEventList,
    process_context: ^ProcessContext,
}

UnitInfo :: struct {
    id: UnitID,
    parent_unit_id: UnitID,
    name: [128]u16,
    program_list_id: i32,
}

ProgramListInfo :: struct {
    id: i32,
    name: [128]u16,
    program_count: i32,
}

