function mcu_com_write(kwargs)

    arguments
        kwargs.value (1,:) double = 0
        kwargs.channel (1,:) double = 0
        kwargs.command (1,:) char = 'chdigout'
        kwargs.serial (1,:) {mustBeA(kwargs.serial, {'double', 'internal.Serialport'})} = []
        kwargs.tag (1,:) char = 'MCU' % logger tag
        kwargs.log parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
    end

    param.(kwargs.command).value = {kwargs.value}; param.(kwargs.command).index = {kwargs.channel};
    packet = jsonencode(param);
    if ~isempty(kwargs.serial)
        writeline(kwargs.serial, packet)
        send(kwargs.log, strcat(kwargs.tag, strcat(": send packet ", packet)));
    else
        send(kwargs.log, strcat(kwargs.tag, ": serial port had not been selected"));
    end
end