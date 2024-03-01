function [result, state] = ximc_get_status(device_id)
    arguments
        device_id (1,1) double
    end
    [result, state] = calllib('libximc', 'get_status', device_id, libpointer('status_t', struct('Flags', 999)));
end