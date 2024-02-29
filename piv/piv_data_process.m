function piv_data_process(packet, param, queueEventProcessed, queueEventDisplay)

    arguments
        packet struct % contains accumulated data and identificator
        param struct % contains processing parameters
        queueEventProcessed parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler at data processing is fulfilled
        queueEventDisplay parallel.pool.DataQueue = parallel.pool.DataQueue % to call event handler at figure building is fulfilled
    end

    function win = build_win_bin(ln_lim, ws, sz)
        %% skew 2D window function
        win = false(sz);
        ln = round(linspace(ln_lim(1), ln_lim(2), sz(2)));
        for k = 1:size(win, 2)
            win(ln(k):ln(k) + ws - 1, k) = ones(1, ws);
        end    
    end

    procstageval = {}; procstagelab = {}; procstagetype = {};

    procstageval = cat(1, procstageval, packet.data(:,:,end));
    procstagetype = cat(1, procstagetype, 'imagesc');
    procstagelab = cat(1, procstagelab, 'instantaneous');

    % fill missing values
    if param.fill ~= "none"
        packet.data(packet.data == 0) = nan;
        for i = 1:size(packet.data, 3)
            packet.data(:, :, i) = fillmissing2(packet.data(:, :, i), char(param.fill));
        end
        procstageval = cat(1, procstageval, packet.data(:,:,end));
        procstagetype = cat(1, procstagetype, 'imagesc');
        procstagelab = cat(1, procstagelab, 'fill missing');
    end

    % apply time filter
    if param.timefilt
        packet.data(abs(normalize(packet.data, 3, 'center')) - param.timefiltker*var(packet.data, 0, 3) > 0) = nan;    
        procstageval = cat(1, procstageval, packet.data(:,:,end));
        procstagetype = cat(1, procstagetype, 'imagesc');
        procstagelab = cat(1, procstagelab, 'time filter');
    end

    % sample averaging field
    packet.data = mean(packet.data, 3, 'omitnan');

    procstageval = cat(1, procstageval, packet.data);
    procstagetype = cat(1, procstagetype, 'imagesc');
    procstagelab = cat(1, procstagelab, 'time averaging');

    % apply spatial filter
    switch param.spatfilt
        case 'gaussian'
            packet.data = imfilter(packet.data, fspecial('gaussian', param.spatfiltker), 'symmetric');
        case 'average'
            packet.data = imfilter(packet.data, fspecial('average', param.spatfiltker), 'symmetric');
        case 'median'
            packet.data = medfilt2(packet.data, param.spatfiltker, 'symmetric');
        case 'wiener'
            packet.data = wiener2(packet.data, param.spatfiltker);
    end

    if param.spatfilt ~= "none"
        procstageval = cat(1, procstageval, packet.data);
        procstagetype = cat(1, procstagetype, 'imagesc');
        procstagelab = cat(1, procstagelab, 'spatial filtering');
    end

    % apply motion filter
    if param.motionfilt
        packet.data = imfilter(packet.data, fspecial('motion', param.motionfiltker, param.motionfiltdeg), 'replicate');
        procstageval = cat(1, procstageval, packet.data);
        procstagetype = cat(1, procstagetype, 'imagesc');
        procstagelab = cat(1, procstagelab, 'motion filtering');
    end

    % apply shift mask
    if param.shift
        winb = build_win_bin(param.shiftker(1:2), param.shiftker(3), size(packet.data));
        packet.data = reshape(packet.data(winb), [], size(packet.data, 2));
        procstageval = cat(1, procstageval, packet.data);
        procstagetype = cat(1, procstagetype, 'imagesc');
        procstagelab = cat(1, procstagelab, 'shift');
    end

    % longitudinal averaging
    packet.data = mean(packet.data, 2, 'omitnan');
        
    procstageval = cat(1, procstageval, packet.data);
    procstagetype = cat(1, procstagetype, 'plot');
    procstagelab = cat(1, procstagelab, 'longitudinal averaging');

    % substract trend
    velspanavg = nan(size(packet.data));
    switch param.subtrend
        case 'poly1'
            [x, y] = prepareCurveData(1:numel(packet.data), packet.data);
            ft = fit(x, y, 'poly1');
            velspanavg = ft(x);
            packet.data = packet.data - velspanavg;
        case 'moving'
            velspanavg = smooth(packet.data, param.subtrendker);
            packet.data = packet.data - velspanavg;
        case 'mean'
            velspanavg = ones(size(packet.data))*mean(packet.data, 'omitnan');
            packet.data = packet.data - velspanavg;
    end

    procstageval{end} = cat(2, procstageval{end}, velspanavg);

    procstageval = cat(1, procstageval, packet.data);
    procstagetype = cat(1, procstagetype, 'plot');
    procstagelab = cat(1, procstagelab, 'substract trend; weighting');

    % weighting by window function
    packet.data = packet.data .* tukeywin(numel(packet.data), param.tukeywin);

    procstageval{end} = cat(2, procstageval{end}, packet.data);

    % send processed data to main worker
    send(queueEventProcessed, packet);

    % plot processing stages
    tile = tiledlayout('flow');
    for i = 1:numel(procstageval)
        ax = nexttile(tile);
        switch procstagetype{i}
            case 'imagesc'
                imagesc(ax, procstageval{i}); clim(ax, param.clim); axis(ax, 'image');
                colorbar(ax); colormap(ax, 'turbo'); xlabel(ax, 'x_n'); ylabel(ax, 'z_n')
            case 'plot'
                hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
                plot(ax, procstageval{i}); 
                xlabel(ax, 'z_n'); ylabel(ax, '<u>');
        end
        title(ax, strcat(procstagelab{i}, {' '}, jsonencode(size(procstageval{i}))), 'FontWeight', 'Normal')
    end

    % send figure to main worker
    send(queueEventDisplay, tile);
end