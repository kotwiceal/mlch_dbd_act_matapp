function [result, state] = ximc_get_state(device_name)
    arguments
        device_name (1,:) char
    end
    result = -1;
    device_id = calllib('libximc', 'open_device', device_name);
    if (device_id == -1)
        return;
    end
    [result, state] = calllib('libximc', 'get_status', device_id, libpointer('status_t', struct('Flags', 999)));
    calllib('libximc', 'close_device', libpointer('int32Ptr', device_id));
end