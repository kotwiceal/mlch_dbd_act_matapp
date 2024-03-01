function result = ximc_move(device_name, position, kwargs)
    arguments
        device_name (1,:) char
        position (1,1) double
        kwargs.queueEventLogger parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
    end
    result = -1;
    device_id = calllib('libximc', 'open_device', device_name);
    if (device_id == -1)
        send(kwargs.queueEventLogger, ['SM: device name ', device_name, ' is not found']);
        return;
    end

    [result, state] = ximc_get_status(device_id);
    if (result ~= 0)
        calllib('libximc', 'close_device', libpointer('int32Ptr', device_id));
        send(kwargs.queueEventLogger, ['SM: error at getting status of device ', num2str(device_id), ' with code', num2str(result)])
        return;
    end

    result = calllib('libximc','command_move', device_id, position, state.uCurPosition);
    if (result ~= 0)
        calllib('libximc', 'close_device', libpointer('int32Ptr', device_id));
        send(kwargs.queueEventLogger, ['SM: error at moving device ', num2str(device_id), ' with code', num2str(result)]);
        return;
    end

    result = calllib('libximc','command_wait_for_stop', device_id, 100);
    if (result ~= 0)
        calllib('libximc', 'close_device', libpointer('int32Ptr', device_id));
        send(kwargs.queueEventLogger, ['SM: error at waiting device ', num2str(device_id), ' with code', num2str(result)]);
        return;
    end

    calllib('libximc', 'close_device', libpointer('int32Ptr', device_id));
    result = 0;
end