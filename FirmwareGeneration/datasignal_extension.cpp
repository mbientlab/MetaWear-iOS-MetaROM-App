#include "metawear/core/module.h"

#include "metawear/core/settings.h"
#include "metawear/core/cpp/settings_private.h"
#include "metawear/core/debug.h"
#include "metawear/core/status.h"

#include "metawear/sensor/switch.h"
#include "metawear/sensor/cpp/switch_register.h"

#include "metawear/processor/cpp/dataprocessor_config.h"
#include "metawear/processor/cpp/dataprocessor_private.h"

#include "metawear/core/cpp/constant.h"
#include "metawear/core/cpp/datasignal_private.h"
#include "metawear/core/cpp/event_private.h"
#include "metawear/core/cpp/metawearboard_def.h"
#include "metawear/core/cpp/metawearboard_macro.h"
#include "metawear/core/cpp/register.h"
#include "metawear/core/cpp/responseheader.h"
#include "metawear/core/cpp/settings_register.h"
#include "metawear/core/cpp/logging_register.h"
#include "metawear/core/cpp/event_register.h"

#include "datasignal_extension.h"

#include <cstring>
#include <vector>

using std::memcpy;
using std::stringstream;
using std::vector;
using std::forward_as_tuple;
using std::piecewise_construct;

const ResponseHeader
    POWER_STATUS_READ_RESPONSE_HEADER(MBL_MW_MODULE_SETTINGS, READ_REGISTER(ORDINAL(0x11)));

void mbl_mw_settings_stop_advertising(const MblMwMetaWearBoard *board) {
    uint8_t command[2]= {MBL_MW_MODULE_SETTINGS, 0x17};
    SEND_COMMAND;
}

MblMwDataSignal* mbl_mw_make_id_data_signal(MblMwMetaWearBoard *board, MblMwDataSignal *signal, uint8_t idx) {
    ResponseHeader header = ResponseHeader(signal->header.module_id, signal->header.register_id, idx);
    auto it = board->module_events.find(header);
    if (it != board->module_events.end()) {
        return dynamic_cast<MblMwDataSignal*>(it->second);
    }
    MblMwDataSignal *sig = new MblMwDataSignal(header, board, DataInterpreter::UINT32, 0, 0, 0, 0);
    board->module_events[header] = sig;
    board->responses[header] = response_handler_data_with_id;
    return sig;
}

static const uint8_t LAST_TYPE = static_cast<uint8_t>(DataProcessorType::FUSER);
static const DataProcessorType QUATERNION_AVERAGE_TYPE = static_cast<DataProcessorType>(LAST_TYPE + 1);

int32_t mbl_mw_dataprocessor_quaternion_average_create(MblMwDataSignal *source, uint8_t depth, uint8_t filterId, void *context, MblMwFnDataProcessor processor_created) {
    auto processor = new MblMwDataProcessor(*source);
    processor->config = malloc(sizeof(uint8_t));
    memcpy(processor->config, &depth, sizeof(uint8_t));
    processor->config_size = sizeof(uint8_t);
    type_to_id[QUATERNION_AVERAGE_TYPE] = filterId;
    processor->type = QUATERNION_AVERAGE_TYPE;
    
    processor->is_signed = 1;
    processor->interpreter = DataInterpreter::SENSOR_FUSION_QUATERNION;
    processor->set_channel_attr(4, 4);
    processor->converter = FirmwareConverter::DEFAULT;
    
    create_processor(source, processor, context, processor_created);
    return MBL_MW_STATUS_OK;
}

MblMwDataSignal* mbl_mw_settings_get_charger_status_read_data_signal(MblMwMetaWearBoard *board) {
    if (!board->module_events.count(POWER_STATUS_READ_RESPONSE_HEADER)) {
        board->module_events[POWER_STATUS_READ_RESPONSE_HEADER] = new MblMwDataSignal(POWER_STATUS_READ_RESPONSE_HEADER, board, DataInterpreter::UINT32, 1, 1, 0, 0);
    }
    board->responses[POWER_STATUS_READ_RESPONSE_HEADER] = response_handler_data_no_id;
    GET_DATA_SIGNAL(POWER_STATUS_READ_RESPONSE_HEADER);
}

void mbl_mw_event_erase_commands(MblMwEvent *event) {
    uint8_t command[3]= {MBL_MW_MODULE_EVENT, ORDINAL(EventRegister::REMOVE)};
    
    for(auto it: event->event_command_ids) {
        command[2]= it;
        SEND_COMMAND_BOARD(event->owner);
    }
}
