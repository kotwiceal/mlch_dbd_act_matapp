function state = mcu_http_post(type, value, index, kwargs)
    arguments
        type (1,:) char {mustBeMember(type, {'dac', 'fm'})} % subcommand
        value (1,:) double % voltage or frequency vector
        index (1,:) double {mustBeInteger, mustBeGreaterThanOrEqual(index, 0), mustBeLessThanOrEqual(index, 15)} % channel vector
        kwargs.address (1,:) char = '192.168.1.1'
        kwargs.port (1,1) double = 8090
        kwargs.command (1,:) char = '/set-param'
        kwargs.url (1,:) char = []
        kwargs.tag (1,:) char = 'MCU' % logger tag
        kwargs.log parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
        kwargs.units struct = struct(dac = 'V', fm = 'kHz') % units of vector value
    end
    state = false;
    if isempty(kwargs.url)
        kwargs.url = strcat('http://', kwargs.address, ':', num2str(kwargs.port), kwargs.command);
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
        request = matlab.net.http.RequestMessage('POST', [matlab.net.http.field.ContentTypeField('application/json'), ...
            matlab.net.http.field.AcceptField('application/json')], message);
        request.send(kwargs.url);
        state = true;
        send(kwargs.log, strcat(kwargs.tag, ": HTTP POST request: ", message));
    catch
        send(kwargs.log, strcat(kwargs.tag, ": HTTP POST request failed"));
    end
end