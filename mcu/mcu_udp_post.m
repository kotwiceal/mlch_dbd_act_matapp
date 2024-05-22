function mcu_udp_post(type, value, index, kwargs)
    arguments
        type (1,:) char {mustBeMember(type, {'dac', 'fm'})} % subcommand
        value (1,:) double % voltage or frequency vector
        index (1,:) double {mustBeInteger, mustBeGreaterThanOrEqual(index, 0), mustBeLessThanOrEqual(index, 15)} % channel vector
        kwargs.address (1,:) char = '192.168.1.1'
        kwargs.port (1,1) double = 8080
        kwargs.tag (1,:) char = 'MCU' % logger tag
        kwargs.log parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
        kwargs.units struct = struct(dac = 'V', fm = 'kHz') % units of vector value
    end
    try
        switch type
            case 'dac'
                switch kwargs.units.(type)
                    case 'V'
                        value = round(1e3*value);
                end
            case 'fm'
                switch kwargs.units.(type)
                    case 'kHz'
                        value = round(value,1);
                end
        end
        parameters = struct();
        if (size(value, 1) == 1) && (size(value, 2) == 1)
            parameters.(type).value = {value};
            parameters.(type).index = {index};  
        else
            parameters.(type).value = value;
            parameters.(type).index = index;   
        end         
        message = jsonencode(parameters);
        udp_socket = udpport;
        write(udp_socket, message, 'string', kwargs.address, kwargs.port);
        send(kwargs.log, strcat(kwargs.tag, ": UDP sending packet ", message));
    catch
        send(kwargs.log, strcat(kwargs.tag, ": UDP sending packet failed"));
    end
end