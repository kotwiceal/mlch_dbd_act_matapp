function server = piv_tcp_receiver(kwargs)

    arguments
        kwargs.address (1,:) char = [] % address of TCP server
        kwargs.port (1,1) double = 6060 % port TCP server
        kwargs.tag (1,:) char = 'PIV' % logger tag
        kwargs.number (1,1) double = 5 % number of samples
        kwargs.queueEventAccumulate parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler at data accumulation is fulfilled
        kwargs.queueEventPreview parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler at packet received
        kwargs.queueEventLogger parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
    end

    function callback(src, ~)
        %% function handler when the client connects and transmits the packet
        if src.Connected
            try
                % read packet and transform from JSON to double
                packet = jsondecode(read(src, src.NumBytesAvailable, 'string'));
                
                % accumulate data
                src.UserData.stack = cat(3, src.UserData.stack, packet);
                
                % send packet to main worker that will call a function handler to visualize it
                send(kwargs.queueEventPreview, struct(data = src.UserData.stack, size = size(src.UserData.stack)));
                if (size(src.UserData.stack, 3) >= src.UserData.number)
                    src.UserData.toc = toc(src.UserData.tic); src.UserData.tic = tic;
                    src.UserData.data = src.UserData.stack;

                    % send accumulated data to main worker that will call a function handler to process data in background worker
                    send(kwargs.queueEventAccumulate, struct(data = src.UserData.data, id = src.UserData.id));
                    
                    % reset accumulated data
                    src.UserData.stack = [];
                end
            catch
                % send(kwargs.queueEventLogger, strcat(kwargs.tag, ": packet receiving is failed"))
            end
        end
    end

    if isempty(kwargs.address)
        [~, hostname] = system('hostname'); hostname = string(strtrim(hostname));
        kwargs.address = resolvehost(hostname, 'address');
    end
    server = tcpserver(kwargs.address, kwargs.port, ConnectionChangedFcn = @callback);

    % set custom parameters
    server.UserData = struct(data = [], stack = [], number = 5, tic = tic, toc = [], id = 0);

    send(kwargs.queueEventLogger, strcat(kwargs.tag, ": start the TCP server ", server.ServerAddress, ":", num2str(server.ServerPort))); 
end