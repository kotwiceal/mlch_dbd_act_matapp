function [scan, mask] = mes_scan_tab_gen(kwargs)
arguments
        kwargs.position (1,:) double = []
        kwargs.voltage (:,:) double = []
        kwargs.channel (1,:) double = []
        kwargs.amplitude (1,:) double = []
        kwargs.period (1,:) double = []
        kwargs.queueEventLogger parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler that logs messages
    end

    scan = []; mask = [];

    if isempty(kwargs.voltage)
        if isempty(kwargs.amplitude) || isempty(kwargs.channel); return; end
        if sum(kwargs.amplitude == 0) >= 1; kwargs.amplitude = [0, kwargs.amplitude]; end
        kwargs.amplitude = kwargs.amplitude(:);
        n = 16; d = zeros(1, n); d(kwargs.channel + 1) = 1; d = diag(d);
        kwargs.voltage = reshape(reshape(d, [], 1) .* kwargs.amplitude', n, []); 
        kwargs.voltage = unique(kwargs.voltage', 'rows');
    else
        if iscolumn(kwargs.voltage); kwargs.voltage = kwargs.voltage'; end
        kwargs.voltage = [zeros(1, 16); kwargs.voltage];
    end

    if isempty(kwargs.position)
        np = 1;
        kwargs.position = zeros(size(kwargs.voltage, 1), 2);
    else
        if isvector(kwargs.position)
            np = numel(kwargs.position);
            kwargs.position = repelem(kwargs.position, size(kwargs.voltage, 1));
            kwargs.position = kwargs.position(:);
            kwargs.position = repmat(kwargs.position, 1, 2);
        else
            
        end
    end

    kwargs.voltage = repmat(kwargs.voltage, np, 1);
    
    kwargs.seeding = zeros(size(kwargs.voltage, 1), 1); 
    if ~isempty(kwargs.period)
        kwargs.seeding(kwargs.period:kwargs.period:end) = 1;
    end
    
    scan = cat(2, kwargs.position, kwargs.seeding, kwargs.voltage);

end