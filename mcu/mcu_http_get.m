function data = mcu_http_get(kwargs)
    arguments
        kwargs.address (1,:) char = '192.168.1.1'
        kwargs.port (1,1) double = 8090
        kwargs.command (1,:) char = '/get-param'
        kwargs.url (1,:) char = []
        kwargs.tag (1,:) char = 'MCU' % logger tag
        kwargs.log parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
        kwargs.units struct = struct(dac = 'V', fm = 'kHz') % units of vector value
    end
    data = []; 
    if isempty(kwargs.url)
        kwargs.url = strcat('http://', kwargs.address, ':', num2str(kwargs.port), kwargs.command);
    end
    try
        request = matlab.net.http.RequestMessage;
        response = request.send(kwargs.url);
        data = response.Body.Data;
        switch kwargs.units.dac
            case 'V'
                data.dac.value = round(1e-3*data.dac.value, 3);
        end
        send(kwargs.log, strcat(kwargs.tag, ": HTTP GET request: ", jsonencode(data)));
    catch
        send(kwargs.log, strcat(kwargs.tag, ": HTTP GET request failed"));
    end
end