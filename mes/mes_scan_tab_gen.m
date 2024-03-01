function voltage_grid = mes_scan_tab_gen(mes_tab_param, kwargs)
    arguments
        mes_tab_param struct
        kwargs.queueEventLogger parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
    end

    voltage_grid = [];
    try 
        channel = mes_tab_param.index;
        amplitude = mes_tab_param.voltage(:);
        channel = channel + 1; n = 16; d = zeros(1, n); d(channel) = 1; d = diag(d);
        voltage_grid = reshape(reshape(d, [], 1) .* amplitude', n, []); voltage_grid = unique(voltage_grid', 'rows')';
        send(kwargs.queueEventLogger, 'MES: grid gereration is succeed');
    catch
        send(kwargs.queueEventLogger, 'MES: grid gereration is failed');
    end
end