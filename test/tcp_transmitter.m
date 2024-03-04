function tcp_transmitter(kwargs)

    arguments
        kwargs.address (1,:) char = '192.168.0.176'
        kwargs.port (1,1) double {mustBeInteger} = 6060
        kwargs.timeout (1,1) double {mustBeInteger} = 60
        kwargs.pause (1,1) double = 0.4
    end

    function z = gencfi()
        [x, y] = meshgrid(linspace(0, 1, 20), linspace(0, 1, 100));
        z = sin(20*x+50*y)+3+rand(size(x));
        z = z.*randi([0, 1], size(x));
        z = jsonencode(z);
    end

    while true
        try
            client = tcpclient(kwargs.address, kwargs.port, 'Timeout', kwargs.timeout);
            write(client, gencfi());
            clear client;
            pause(kwargs.pause);
        catch
        end
    end

end