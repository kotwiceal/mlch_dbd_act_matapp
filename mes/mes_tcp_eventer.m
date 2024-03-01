function server = mes_tcp_eventer(kwargs)
    arguments
        kwargs.address (1,:) char = [] % address of TCP server
        kwargs.port (1,1) double = 5050 % port TCP server
        kwargs.tag (1,:) char = 'MES' % logger tag
        kwargs.value (:,:) double = []
        kwargs.queueEventPost parallel.pool.DataQueue = parallel.pool.DataQueue % to send voltage vector to MCU
        kwargs.queueEventPreview parallel.pool.DataQueue = parallel.pool.DataQueue % to preview stage
        kwargs.queueEventTerminate parallel.pool.DataQueue = parallel.pool.DataQueue % to terminate
        kwargs.queueEventLogger parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
    end
    
    function callback(src, ~)
        %% function handler when the client connects
        if src.Connected
            try
                if (src.UserData.i <= size(src.UserData.value, 2))
                    send(kwargs.queueEventPost, src.UserData.value(:, src.UserData.i));
                    send(kwargs.queueEventPreview, src.UserData.i);
                    send(kwargs.queueEventLogger, strcat("MES: i = ", num2str(src.UserData.i)));
                    src.UserData.i = src.UserData.i + 1;
                else
                    send(kwargs.queueEventTerminate, true);
                end
            catch
                send(kwargs.queueEventTerminate, true);
            end
        end
    end
    if isempty(kwargs.address)
        [~, hostname] = system('hostname'); hostname = string(strtrim(hostname));
        kwargs.address = resolvehost(hostname, 'address');
    end
    server = tcpserver(kwargs.address, kwargs.port, ConnectionChangedFcn = @callback);

    % set custom parameters
    server.UserData = struct(value = kwargs.value, i = 1);

    send(kwargs.queueEventLogger, strcat(kwargs.tag, ": start the TCP server ", server.ServerAddress, ":", num2str(server.ServerPort))); 
end