#pragma once

#include "metawear/core/metawearboard_fwd.h"
#include "metawear/processor/processor_common.h"

#ifdef    __cplusplus
extern "C" {
#endif

METAWEAR_API void mbl_mw_settings_stop_advertising(const MblMwMetaWearBoard *board);
    
METAWEAR_API MblMwDataSignal* mbl_mw_make_id_data_signal(MblMwMetaWearBoard *board, MblMwDataSignal *signal, uint8_t idx);
    
METAWEAR_API int32_t mbl_mw_dataprocessor_quaternion_average_create(MblMwDataSignal *source, uint8_t depth, uint8_t filterId, void *context, MblMwFnDataProcessor processor_created);

METAWEAR_API MblMwDataSignal* mbl_mw_settings_get_charger_status_read_data_signal(MblMwMetaWearBoard *board);    
METAWEAR_API void mbl_mw_event_erase_commands(MblMwEvent *event);
    
#ifdef    __cplusplus
}
#endif
