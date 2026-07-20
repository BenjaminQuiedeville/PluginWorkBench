package vst3

FUnknownVtbl :: struct #packed {
    query_interface: proc "system" (rawptr, [^]u8, ^rawptr) -> Result,
    add_ref: proc "system" (rawptr) -> u32,
    release: proc "system" (rawptr) -> u32,
}

FUnknown :: struct #packed {
    using vtbl: ^FUnknownVtbl 
}

FUnknown_iid :: "00000000-0000-0000-c000-000000000046"

IPlugViewContentScaleSupportVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_content_scale_factor: proc "system"(rawptr, f32) -> Result,
}

IPlugViewContentScaleSupport :: struct #packed {
    using vtbl: ^IPlugViewContentScaleSupportVtbl,
}

IPlugViewContentScaleSupport_iid :: "65ed9690-8ac4-4525-8aad-ef7a72ea703f"

IPlugViewVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    is_platform_type_supported: proc "system" (rawptr, cstring) -> Result,
    attached: proc "system" (rawptr, rawptr, cstring) -> Result,
    removed: proc "system" (rawptr) -> Result,
    on_wheel: proc "system" (rawptr, f32) -> Result,
    on_key_down: proc "system" (rawptr, u16, i16, i16) -> Result,
    on_key_up: proc "system" (rawptr, u16, i16, i16) -> Result,
    get_size: proc "system" (rawptr, ^ViewRect) -> Result,
    on_size: proc "system" (rawptr, ^ViewRect) -> Result,
    on_focus: proc "system" (rawptr, u8) -> Result,
    set_frame: proc "system" (rawptr, ^IPlugFrame) -> Result,
    can_resize: proc "system" (rawptr) -> Result,
    check_size_constraint: proc "system" (rawptr, ^ViewRect) -> Result,
}

IPlugView :: struct #packed {
    using vtbl: ^IPlugViewVtbl,
}

IPlugView_iid :: "5bc32507-d060-49ea-a615-1b522b755b29"

IPlugFrameVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    resize_view: proc "system" (rawptr, ^IPlugView, ^ViewRect) -> Result,
}

IPlugFrame :: struct #packed {
    using vtbl: ^IPlugFrameVtbl,
}

IPlugFrame_iid :: "367faf01-afa9-4693-8d4d-a2a0ed0882a3"

IBStreamVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    read: proc "system" (rawptr, rawptr, i32, ^i32) -> Result,
    write: proc "system" (rawptr, rawptr, i32, ^i32) -> Result,
    seek: proc "system" (rawptr, i64, IStreamSeekMode, ^i64) -> Result,
    tell: proc "system" (rawptr, ^i64) -> Result,
}

IBStream :: struct #packed {
    using vtbl: ^IBStreamVtbl,
} 

IBStream_iid :: "c3bf6ea2-3099-4752-9b6b-f9901ee33e9b"

ISizeableStreamVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_stream_size: proc "system" (rawptr, ^i64) -> Result,
    set_stream_size: proc "system" (rawptr, i64) -> Result,
}

ISizeableStream :: struct #packed {
    using vtbl: ^ISizeableStreamVtbl,
}

ISizeableStream_iid :: "04f9549e-e02f-4e6e-87e8-6a8747f4e17f"


INoteExpressionControllerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_note_expression_count: proc "system" (rawptr, i32, i16) -> i32,
    get_note_expression_info: proc "system" (rawptr, i32, i16, i32, ^NoteExpressionTypeInfo) -> Result,
    get_note_expression_string_by_value: proc "system" (rawptr, i32, i16, NoteExpressionTypeID, ^NoteExpressionTypeInfo, f64, [^]u16) -> Result,
    get_note_expression_value_by_string: proc "system" (rawptr, i32, i16, NoteExpressionTypeID, ^u16, f64) -> Result,
}

INoteExpressionController :: struct #packed {
    using vtbl: ^INoteExpressionControllerVtbl,
}

INoteExpressionController_iid :: "b7f8f859-4123-4872-9116-95814f3721a3"

IKeyswitchControllerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_keyswitch_count: proc "system" (rawptr, i32, i16) -> i32,
    get_keyswitch_info: proc "system" (rawptr, i32, i16, i32, ^KeyswitchInfo) -> Result,
}

IKeyswitchController :: struct #packed {
    using vtbl: ^IKeyswitchControllerVtbl,
}

IKeyswitchController_iid :: "1f2f76d3-bffb-4b96-b995-27a55ebccef4"

INoteExpressionPhysicalUIMappingVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_physical_ui_mapping: proc "system" (rawptr, i32, i16, ^PhysicalUIMapList) -> Result,
}

INoteExpressionPhysicalUIMapping :: struct #packed {
    using vtbl: ^INoteExpressionPhysicalUIMappingVtbl,
}

INoteExpressionPhysicalUIMapping_iid :: "b03078ff-94d2-4ac8-90cc-d303d4133324"


IPluginBaseVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    initialize: proc "system" (rawptr, ^FUnknown) -> Result,
    terminate: proc "system" (rawptr) -> Result,
} 

IPluginBase :: struct #packed {
    using vtbl: ^IPluginBaseVtbl,
}

IPluginBase_iid :: "22888ddb-156e-45ae-8358-b34808190625"

IPluginFactoryVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_factory_info: proc "system" (rawptr, ^PFactoryInfo) ->  Result,
    count_classes: proc "system" (rawptr) -> i32,
    get_class_info: proc "system" (rawptr, i32, ^PClassInfo) -> Result,
    create_instance: proc "system" (rawptr, [^]u8, [^]u8, ^rawptr) -> Result,
} 

IPluginFactory :: struct #packed {
    using vtbl: ^IPluginFactoryVtbl,
} 

IPluginFactory_iid :: "7a4d811c-5211-4a1f-aed9-d2ee0b43bf9f"

IPluginFactory2Vtbl :: struct #packed {
    using factory: IPluginFactoryVtbl,
    get_class_info_2: proc "system" (rawptr, i32, ^PClassInfo2) -> Result,
}

IPluginFactory2 :: struct #packed {
    using vtbl: ^IPluginFactory2Vtbl,
} 

IPluginFactory2_iid :: "0007b650-f24b-4c0b-a464-edb9f00b2abb"

IPluginFactory3Vtbl :: struct #packed {
    using factory_2: IPluginFactory2Vtbl,
    get_class_info_unicode: proc "system" (rawptr, i32, ^PClassInfoW) -> Result,
    set_host_context: proc "system" (rawptr, ^FUnknown) -> Result
}

IPluginFactory3 :: struct #packed {
    using vtbl: ^IPluginFactory3Vtbl,
}

IPluginFactory3_iid :: "4555a2ab-c123-4e57-9b12-291036878931"

IComponentVtbl :: struct #packed {
    using plugin_base: IPluginBaseVtbl,
    get_controller_class_id: proc "system" (rawptr, [^]u8) -> Result,
    set_io_mode: proc "system" (rawptr, IoMode) -> Result,
    get_bus_count: proc "system" (rawptr, MediaType, BusDirection) -> i32,
    get_bus_info: proc "system" (rawptr, MediaType, BusDirection, i32, ^BusInfo) -> Result,
    get_routing_info: proc "system" (rawptr, ^RoutingInfo, ^RoutingInfo) -> Result,
    activate_bus: proc "system" (rawptr, MediaType, BusDirection, i32, u8) -> Result,
    set_active: proc "system" (rawptr, u8) -> Result,
    set_state: proc "system" (rawptr, ^IBStream) -> Result,
    get_state: proc "system" (rawptr, ^IBStream) -> Result,
}

IComponent :: struct #packed {
    using vtbl: ^IComponentVtbl
}

IComponent_iid :: "e831ff31-f2d5-4301-928e-bbee25697802"

IAttributeListVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_int: proc "system" (rawptr, cstring, i64) -> Result,
    get_int: proc "system" (rawptr, cstring, ^i64) -> Result,
    set_float: proc "system" (rawptr, cstring, f64) -> Result,
    get_float: proc "system" (rawptr, cstring, ^f64) -> Result,
    set_string: proc "system" (rawptr, cstring, ^u16) -> Result,
    get_string: proc "system" (rawptr, cstring, ^u16, u32) -> Result,
    set_binary: proc "system" (rawptr, cstring, rawptr, u32) -> Result,
    get_binary: proc "system" (rawptr, cstring, ^rawptr, ^u32) -> Result,
}

IAttributeList :: struct #packed {
    using vtbl: ^IAttributeListVtbl,
}

IAttributeList_iid :: "1e5f0aeb-cc7f-4533-a254-401138ad5ee4"

IStreamAttributesVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_file_name: proc "system" (rawptr, [^]u16) -> Result,
    get_attributes: proc "system" (rawptr) -> ^IAttributeList,
}

IStreamAttributes :: struct #packed {
    using vtbl: ^IStreamAttributesVtbl,
}

IStreamAttributes_iid :: "d6ce2ffc-efaf-4b8c-9e74-f1bb12da44b4"


IRemapParamIDVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_compatible_param_id: proc "system" (rawptr, [^]u8, u32, ^u32) -> Result,
}

IRemapParamID :: struct #packed {
    using vtbl: ^IRemapParamIDVtbl,
}

IRemapParamID_iid :: "2b88021e-6286-b646-b49d-f76a5663061c"

IComponentHandlerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    begin_edit: proc "system" (rawptr, u32) -> Result,
    perform_edit: proc "system" (rawptr, u32, f64) -> Result,
    end_edit: proc "system" (rawptr, u32) -> Result,
    restart_component: proc "system" (rawptr, i32) -> Result,
}

IComponentHandler :: struct #packed {
    using vtbl: ^IComponentHandlerVtbl,
}

IComponentHandler_iid :: "93a0bea3-0bd0-45db-8e89-0b0cc1e46ac6"

IComponentHandler2Vtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_dirty: proc "system" (rawptr, u8) -> Result,
    request_open_editor: proc "system" (rawptr, cstring) -> Result,
    start_group_edit: proc "system" (rawptr) -> Result,
    finish_group_edit: proc "system" (rawptr) -> Result,
}

IComponentHandler2 :: struct #packed {
    using vtbl: ^IComponentHandler2Vtbl,
}

IComponentHandler2_iid :: "f040b4b3-a360-45ec-abcd-c045b4d5a2cc"

IComponentHandlerBusActivationVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    request_bus_activation: proc "system" (rawptr, MediaType, BusDirection, i32, u8) -> Result,
}

IComponentHandlerBusActivation :: struct #packed {
    using vtbl: ^IComponentHandlerBusActivationVtbl,
}

IComponentHandlerBusActivation_iid :: "067d02c1-5b4e-274d-a92d-90fd6eaf7240"

IProgressVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    start: proc "system" (rawptr, ProgressType, ^u16, u64) -> Result,
    update: proc "system" (rawptr, u64, f64) -> Result,
    finish: proc "system" (rawptr, u64) -> Result,
}

IProgress :: struct #packed {
    using vtbl: ^IProgressVtbl,
}

IProgress_iid :: "00c9dc5b-9d90-4254-91a3-88c8b4e91b69"

IEditControllerVtbl :: struct #packed {
    using plugin_base: IPluginBaseVtbl,
    set_component_state: proc "system" (rawptr, ^IBStream) -> Result,
    set_state: proc "system" (rawptr, ^IBStream) -> Result,
    get_state: proc "system" (rawptr, ^IBStream) -> Result,
    get_parameter_count: proc "system" (rawptr) -> i32,
    get_parameter_info: proc "system" (rawptr, i32, ^ParameterInfo) -> Result,
    get_parameter_string_by_value: proc "system" (rawptr, u32, f64, [^]u16) -> Result,
    get_parameter_value_by_string: proc "system" (rawptr, u32, cstring, ^f64) -> Result,
    normalised_param_to_plain: proc "system" (rawptr, u32, f64) -> f64,
    plain_param_to_normalised: proc "system" (rawptr, u32, f64) -> f64,
    get_param_normalised: proc "system" (rawptr, u32) -> f64,
    set_param_normalised: proc "system" (rawptr, u32, f64) -> Result,
    set_component_handler: proc "system" (rawptr, ^IComponentHandler) -> Result,
    create_view: proc "system" (rawptr, cstring) -> ^IPlugView,
}

IEditController :: struct #packed {
    using vtbl: ^IEditControllerVtbl,
}

IEditController_iid :: "dcd7bbe3-7742-448d-a874-aacc979c759e"

IEditController2Vtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_knob_mode: proc "system" (rawptr, KnobMode) -> Result,
    open_help: proc "system" (rawptr, u8) -> Result,
    open_about_box: proc "system" (rawptr, u8) -> Result,
}

IEditController2 :: struct #packed {
    using vtbl: ^IEditController2Vtbl,
}

IEditController2_iid :: "7f4efe59-f320-4967-ac27-a3aeafb63038"


IMidiMappingVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_midi_controller_assignment: proc "system" (rawptr, i32, i16, ControllerNumber, ^u32) -> Result,
}

IMidiMapping :: struct #packed {
    using vtbl: ^IMidiMappingVtbl,
}

IMidiMapping_iid :: "df0ff9f7-49b7-4669-b63a-b7327adbf5e5"

IEditControllerHostEditingVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    begin_edit_from_host: proc "system" (rawptr, u32) -> Result,
    end_edit_from_host: proc "system" (rawptr, u32) -> Result,
}

IEditControllerHostEditing :: struct #packed {
    using vtbl: ^IEditControllerHostEditingVtbl
}

IEditControllerHostEditing_iid :: "c1271208-7059-4098-b9dd-34b36bb0195e"

IComponentHandlerSystemTimeVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_system_time: proc "system" (rawptr, ^i64) -> Result,
}

IComponentHandlerSystemTime :: struct #packed {
    using vtbl: ^IComponentHandlerSystemTimeVtbl,
}

IComponentHandlerSystemTime_iid :: "f9e53056-d155-4cd5-b769-5e1b7b0f7745"

IEventListVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    get_event_count: proc "system" (rawptr) -> i32,
    get_event: proc "system" (rawptr, i32, ^Event) -> Result,
    add_event: proc "system" (rawptr, ^Event) -> Result,
}

IEventList :: struct #packed {
    using vtbl: ^IEventListVtbl,
}

IEventList_iid :: "3a2c4214-3463-49fe-b2c4-f397b9695a44"

IMessageVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    get_message_id: proc "system" (rawptr) -> cstring,
    set_message_id: proc "system" (rawptr, cstring),
    get_attributes: proc "system" (rawptr) -> ^IAttributeList,
}

IMessage :: struct #packed {
    using vtbl: ^IMessageVtbl,
}

IMessage_iid :: "936f033b-c6c0-47db-bb08-82f813c1e613"

IConnectionPointVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    connect: proc "system" (rawptr, ^IConnectionPoint) -> Result,
    disconnect: proc "system" (rawptr, ^IConnectionPoint) -> Result,
    notify: proc "system" (rawptr, ^IMessage) -> Result,
}

IConnectionPoint :: struct #packed {
    using vtbl: ^IConnectionPoint,
}

IConnectionPoint_iid :: "70a4156f-6e6e-4026-9891-48bfaa60d8d1"


IXmlRepresentationControllerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_xml_representation_stream: proc "system" (rawptr, ^RepresentationInfo, ^IBStream) -> Result,
}

IXmlRepresentationController :: struct #packed {
    using vtbl: IXmlRepresentationControllerVtbl,
}

IXmlRepresentationController_iid :: "a81a0471-48c3-4dc4-ac30-c9e13c8393d5"


IComponentHandler3Vtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    create_context_menu: proc "system" (rawptr, ^IPlugView, ^u32) -> ^IContextMenu,
}

IComponentHandler3 :: struct #packed {
    using vtbl: ^IComponentHandler3Vtbl,
}

IComponentHandler3_iid :: "69f11617-d26b-400d-a4b6-b9647b6ebbab"


IContextMenuTargetVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    execute_menu_item: proc "system" (rawptr, i32) -> Result,
}

IContextMenuTarget :: struct #packed {
    using vtbl: ^IContextMenuTargetVtbl,
}

IContextMenuTarget_iid :: "3cdf2e75-85d3-4144-bf86-d36bd7c4894d"

IContextMenuVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_item_count: proc "system" (rawptr) -> i32,
    get_item: proc "system" (rawptr, i32, ^IContextMenuItem, ^^IContextMenuTarget) -> Result,
    remove_item: proc "system" (rawptr, ^IContextMenuItem, ^IContextMenuTarget) -> Result,
    popup: proc "system" (rawptr, i32, i32) -> Result,
}

IContextMenu :: struct #packed {
    using vtbl: ^IContextMenuVtbl,
}

IContextMenu_iid :: "2e93c863-0c9c-4588-97db-ecf5ad17817d"

IMidiLearnVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    on_live_midi_controller_input: proc "system" (rawptr, i32, i16, ControllerNumber) -> Result,
}

IMidiLearn :: struct #packed {
    using vtbl: ^IMidiLearnVtbl,
}

IMidiLearn_iid :: "6b2449cc-4197-40b5-ab3c-79dac5fe5c86"

IInfoListenerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_channel_context_infos: proc "system" (rawptr, ^IAttributeList) -> Result,
}

IInfoListener :: struct #packed {
    using vtbl: ^IInfoListenerVtbl,
}

IInfoListener_iid :: "0f194781-8d98-4ada-bba0-c1efc011d8d0"

IPrefetchableSupportVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_prefetchable_support: proc "system" (rawptr, PrefetchableSupport) -> Result,
}

IPrefetchableSupport :: struct #packed {
    using vtbl: ^IPrefetchableSupportVtbl,
}

IPrefetchableSupport_iid :: "8ae54fda-e930-46b9-a285-55bcdc98e21e"

IDataExchangeHandlerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    open_queue: proc "system" (rawptr, ^IAudioProcessor, u32, u32, u32, u32, ^u32) -> Result,
    close_queue: proc "system" (rawptr, u32) -> Result,
    lock_block: proc "system" (rawptr, u32, ^DataExchangeBlock) -> Result,
    free_block: proc "system" (rawptr, u32, u32, u8) -> Result,
} 

IDataExchangeHandler :: struct #packed {
    using vtbl: ^IDataExchangeHandlerVtbl,
}

IDataExchangeHandler_iid :: "36d551bd-6ff5-4f08-b48e-830d8bd5a03b"

IDataExchangeReceiverVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    queue_opened: proc "system" (rawptr, u32, u32, ^u8),
    queue_closed: proc "system" (rawptr, u32),
    on_data_exchange_blocks_received: proc "system" (rawptr, u32, u32, ^DataExchangeBlock, u8),
}

IDataExchangeReceiver :: struct #packed {
    using vtbl: ^IDataExchangeReceiverVtbl
}

IDataExchangeReceiver_iid :: "45a759dc-84fa-4907-abcb-61752fc786b6"

IAutomationStateVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_automation_state: proc "system" (rawptr, i32) -> Result,
}

IAutomationState :: struct #packed {
    using vtbl: ^IAutomationStateVtbl,
}

IAutomationState_iid :: "b4e8287f-1bb3-46aa-83a4-666768937bab"

IInterAppAudioHostVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_screen_size: proc "system" (rawptr, ^ViewRect, ^f32) -> Result,
    connected_to_host: proc "system" (rawptr) -> Result,
    switch_to_host: proc "system" (rawptr) -> Result,
    send_remote_control_event: proc "system" (rawptr, u32) -> Result,
    get_host_icon: proc "system" (rawptr, ^rawptr) -> Result,
    schedule_event_from_ui: proc "system" (rawptr, ^Event) -> Result,
    create_preset_manager: proc "system" (rawptr, ^[^]u8) -> ^IInterAppAudioPresetManager,
    show_settings_view: proc "system" (rawptr) -> Result,
}

IInterAppAudioHost :: struct #packed {
    using vtbl: ^IInterAppAudioHostVtbl,
}

IInterAppAudioHost_iid :: "0ce5743d-68df-415e-ae28-5bd4e2cdc8fd"

IInterAppAudioConnectionNotificationVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    on_inter_app_audio_connection_state_change: proc "system" (rawptr, u8),
}

IInterAppAudioConnectionNotification :: struct #packed {
    using vtbl: ^IInterAppAudioConnectionNotificationVtbl,
}

IInterAppAudioConnectionNotification_iid :: "6020c72d-5fc2-4aa1-b095-0db5d7d6d5cf"

IInterAppAudioPresetManagerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    run_load_preset_browser: proc "system" (rawptr) -> Result,
    run_save_preset_browser: proc "system" (rawptr) -> Result,
    load_next_preset: proc "system" (rawptr) -> Result,
    load_previous_preset: proc "system" (rawptr) -> Result,
}

IInterAppAudioPresetManager :: struct #packed {
    using vtbl: ^IInterAppAudioPresetManagerVtbl,
}

IInterAppAudioPresetManager_iid :: "ade6fcc4-46c9-4e1d-b3b4-9a80c93fefdd"

IAudioProcessorVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_bus_arrangements: proc "system" (rawptr, [^]SpeakerArrangement, i32, [^]SpeakerArrangement, i32) -> Result,
    get_bus_arrangements: proc "system" (rawptr, BusDirection, i32, ^SpeakerArrangement) -> Result,
    can_process_sample_size: proc "system" (rawptr, SymbolicSampleSize) -> Result,
    get_latency_samples: proc "system" (rawptr) -> u32,
    setup_processing: proc "system" (rawptr, ^ProcessSetup) -> Result,
    set_processing: proc "system" (rawptr, u8) -> Result,
    process: proc "system" (rawptr, ^ProcessData) -> Result,
    get_tail_samples: proc "system" (rawptr) -> u32,
}

IAudioProcessor :: struct #packed {
    using vtbl: ^IAudioProcessorVtbl, 
}

IAudioProcessor_iid :: "42043f99-b7da-453c-a569-e79d9aaec33d"

IAudioPresentationLatencyVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_audio_presentation_latency_samples: proc "system" (rawptr, BusDirection, i32, u32) -> Result,
}

IAudioPresentationLatency :: struct #packed {
    using vtbl: ^IAudioPresentationLatencyVtbl,
}

IAudioPresentationLatency_iid :: "309ece78-eb7d-4fae-8b22-25d909fd08b6"

IProcessContextRequirementsVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_process_context_requirements: proc "system" (rawptr) -> u32,
}

IProcessContextRequirements :: struct #packed {
    using vtbl: ^IProcessContextRequirementsVtbl,
}

IProcessContextRequirements_iid :: "2a654303-ef76-4e3d-95b5-fe83730ef6d0"

IHostApplicationVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_name: proc "system" (rawptr, [^]u16) -> Result,
    create_instance: proc "system" (rawptr, [^]u8, [^]u8, ^rawptr) -> Result,
}

IHostApplication :: struct #packed {
    using vtbl: ^IHostApplicationVtbl,
}

IHostApplication_iid :: "58e595cc-db2d-4969-8b6a-af8c36a664e5"

IVst3ToVst2WrapperVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
}

IVst3ToVst2Wrapper :: struct #packed {
    vtbl: ^IVst3ToVst2WrapperVtbl,
}

IVst3ToVst2Wrapper_iid :: "29633aec-1d1c-47e2-bb85-b97bd36eac61"

IVst3ToAUWrapperVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
}

IVst3ToAUWrapper :: struct #packed {
    using vtbl: ^IVst3ToAUWrapperVtbl,
}

IVst3ToAUWrapper_iid :: "a3b8c6c5-c095-4688-b091-6f0bb697aa44"

IVst3ToAAXWrapperVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
}

IVst3ToAAXWrapper :: struct #packed {
    using vtbl: ^IVst3ToAAXWrapper,
}

IVst3ToAAXWrapper_iid :: "6d319dc6-60c5-6242-b32c-951b93bef4c6"

IVst3WrapperMPESupportVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    enable_mpe_input_processing: proc "system" (rawptr, u8) -> Result,
    set_mpe_input_device_settings: proc "system" (rawptr, i32, i32, i32) -> Result,
}

IVst3WrapperMPESupport :: struct #packed {
    using vtbl: ^IVst3WrapperMPESupportVtbl,
}

IVst3WrapperMPESupport_iid :: "44149067-42cf-4bf9-8800-b750f7359fe3"

IParameterFinderVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    find_parameter: proc "system" (rawptr, i32, i32, ^u32) -> Result,
}

IParameterFinder :: struct #packed {
    vtbl: ^IParameterFinderVtbl,
}

IParameterFinder_iid :: "0f618302-215d-4587-a512-073c77b9d383"

IUnitHandlerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    notify_unit_selection: proc "system" (rawptr, u32) -> Result,
    notify_program_list_change: proc "system" (rawptr, u32, i32) -> Result,
}

IUnitHandler :: struct #packed {
    using vtbl: ^IUnitHandlerVtbl,
}

IUnitHandler_iid :: "4b5147f8-4654-486b-8dab-30ba163a3c56"

IUnitHandler2Vtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    notify_unit_by_bus_change: proc "system" (rawptr) -> Result,
}

IUnitHandler2 :: struct #packed {
    using vtbl: IUnitHandler2Vtbl,
}

IUnitHandler2_iid :: "f89f8cdf-699e-4ba5-96aa-c9a481452b01"

IUnitInfoVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_unit_count: proc "system" (rawptr) -> i32,
    get_unit_info: proc "system" (rawptr, i32, ^UnitInfo) -> Result,
    get_program_list_count: proc "system" (rawptr) -> i32,
    get_program_list_info: proc "system" (rawptr, i32, ^ProgramListInfo) -> Result,
    get_program_name: proc "system" (rawptr, i32, i32, [^]u16) -> Result,
    get_program_info: proc "system" (rawptr, i32, i32, ^u16, [^]u16) -> Result,
    has_program_pitch_names: proc "system" (rawptr, i32, i32) -> Result,
    get_program_pitch_names: proc "system" (rawptr, i32, i32, i16, [^]u16) -> Result,
    get_selected_unit: proc "system" (rawptr) -> i32,
    select_unit: proc "system" (rawptr, i32) -> Result,
    get_unit_by_bus: proc "system" (rawptr, MediaType, BusDirection, i32, i32, ^i32) -> Result,
    set_unit_program_data: proc "system" (rawptr, i32, i32, ^IBStream) -> Result,
}

IUnitInfo :: struct #packed {
    using vtbl: ^IUnitInfoVtbl,
}

IUnitInfo_iid :: "3d4bd6b5-913a-4fd2-a886-e768a5eb92c1"

IProgramListDataVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    program_data_supported: proc "system" (rawptr, i32) -> Result,
    get_program_data: proc "system" (rawptr, i32, i32, ^IBStream) -> Result,
    set_program_data: proc "system" (rawptr, i32, i32, ^IBStream) -> Result,
}

IProgramListData :: struct #packed {
    using vtbl: ^IProgramListDataVtbl,
}

IProgramListData_iid :: "8683b01f-7b35-4f70-a265-1dec353af4ff"

IUnitDataVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    unit_data_supported: proc "system" (rawptr, i32) -> Result,
    get_unit_data: proc "system" (rawptr, i32, ^IBStream) -> Result,
    set_unit_data: proc "system" (rawptr, i32, ^IBStream) -> Result,
}

IUnitData :: struct #packed {
    using vtbl: ^IUnitInfoVtbl,
}

IUnitData_iid :: "6c389611-d391-455d-b870-b83394a0efdd"

IPlugInterfaceSupportVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    is_plug_interface_supported: proc "system" (rawptr, [^]u8) -> Result,
}

IPlugInterfaceSupport :: struct #packed {
    using vtbl: ^IPlugInterfaceSupportVtbl,
}

IPlugInterfaceSupport_iid :: "4fb58b9e-9eaa-4e0f-ab36-1c1cccb56fea"

IParameterFunctionNameVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_parameter_id_from_function_name: proc "system" (rawptr, i32, cstring, ^u32) -> Result,
}

Vst_IParameterFunctionName :: struct #packed {
    using vtbl: ^IParameterFunctionNameVtbl,
}

IParameterFunctionName_iid :: "6d21e1dc-9119-9d4b-a2a0-2fef6c1ae55c"

IParamValueQueueVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_parameter_id: proc "system" (rawptr) -> u32,
    get_point_count: proc "system" (rawptr) -> i32,
    get_point: proc "system" (rawptr, i32, ^i32, ^f64) -> Result,
    add_point: proc "system" (rawptr, i32, f64, ^i32) -> Result,
}

IParamValueQueue :: struct #packed {
    using vtbl: ^IParamValueQueueVtbl,
}

IParamValueQueue_iid :: "01263a18-ed07-4f6f-98c9-d3564686f9ba"

IParameterChangesVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_parameter_count: proc "system" (rawptr) -> i32,
    get_parameter_data: proc "system" (rawptr, i32) -> ^IParamValueQueue,
    add_parameter_data: proc "system" (rawptr, ^u32, ^i32) -> ^IParamValueQueue,
}

IParameterChanges :: struct #packed {
    using vtbl: ^IParameterChangesVtbl,
}

IParameterChanges_iid :: "a4779663-0bb6-4a56-b443-84a8466feb9d"
