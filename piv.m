classdef piv < matlab.apps.AppBase
%   PIV class aims to accumulate and to process sended by DaViS software PIV data by TPC socket and 
%   contains GUI implementation to adjust processing setup and to browse results.

    properties (Access = public)
        % define UI properties
        MainGridLayout       matlab.ui.container.GridLayout
        ActionPanel          matlab.ui.container.Panel
        ActionGridLayout     matlab.ui.container.GridLayout
        RestartButton        matlab.ui.control.StateButton
        OutputPanel          matlab.ui.container.Panel
        OutputGridLayout     matlab.ui.container.GridLayout
        OutputUITable        matlab.ui.control.Table
        ParameterPanel       matlab.ui.container.Panel
        ParameterGridLayout  matlab.ui.container.GridLayout
        ParameterUITable     matlab.ui.control.Table
        DisplayFigurePanel         matlab.ui.container.Panel
        DisplayTablePanel         matlab.ui.container.Panel
        DisplayTableGridLayout    matlab.ui.container.GridLayout
        DisplayUITable       matlab.ui.control.Table
        
        % define specific properties
        parent_ui % to put there all UI objects of present class

        tcp_server % to store instance of TCP server
        tcp_server_port = 6060 % listening port of TCP server

        % define default fields of parameter table
        var_tab_param = struct('statistic', 5, 'crop', [5, 5, 5, 5], 'fill', categorical({'off'}, {'2d'; '3d'; 'off'}), 'kernelavg', 1, 'filter2d', categorical({'off'}, {'gaussian'; 'off'}), ...
            'kernel2d', [3, 1], 'shift', [1, 1, 70], 'filter1d', categorical({'moving'}, {'moving'; 'off'}), 'kernel1d', 20, 'scale', 3.037, 'tukeywin', 1, ...
            'display', categorical({'process'}, {'surf'; 'table'; 'process'}), 'clim', [0, 10])
        var_tab_param_def

        var_proc = struct() % to store process results

        % send and listen for data between client and workers
        queue_pool = struct('received', parallel.pool.DataQueue, 'accumulated', parallel.pool.DataQueue, 'processed', parallel.pool.DataQueue, ...
            'display_processed', parallel.pool.DataQueue, 'disp', parallel.pool.DataQueue);

        % handle function at compliting processing
        event_processed = @(src, data) []
    end

    methods
        function obj = piv(parent_ui, queue_pool)
            % assign arguments
            obj.parent_ui = parent_ui;
            obj.queue_pool.log = queue_pool.log;
            obj.queue_pool.disp = queue_pool.disp;

            % build content
            obj.create_components();
            obj.init_components();
            obj.init_server();
        end

        %% Supporting functnios

        % Define a function of table cells initialization
        function init_tab_param(~, tab_struct, tab_obj)
            % INPUT:
            %   tab_struct - structure that fields are assigned as first column of table, value - second column;
            %   tab_obj - table UI object;
            labels = {};
            values = {};
            fn = fieldnames(tab_struct);
            for i = 1:size(fn, 1)
                label= char(fn{i});
                value = tab_struct.(label);
                if isa(value, 'categorical')
                    value = tab_struct.(label);
                end
                if isa(value, 'double')
                    value = char(jsonencode(tab_struct.(label)));
                end
                labels{i, 1} = label; 
                values{i, 1} = value;
            end
            dtable = table(labels, values);
            tab_obj.Data = dtable;
            tab_obj.ColumnEditable = [false, true];
        end

        %% Handler functions

        % Define a handler function at receiving data from TCP client
        function event_received(obj, data)
            % INPUT:
            %   data - 2d or 3d double array

            % update the output table
            try
                sz = size(data);
                if (size(sz, 2) == 2)
                    obj.OutputUITable.Data{1, 2} = {strcat('1/', num2str(obj.var_tab_param.statistic))};
                else
                    obj.OutputUITable.Data{1, 2} = {strcat(num2str(sz(3)), "/", num2str(obj.var_tab_param.statistic))};
                end
                obj.OutputUITable.Data{3, 2} = {jsonencode(sz)};
            catch
                send(obj.queue_pool.log, 'PIV: updating of output table is failed')
            end
            % update the display panel
            try
                switch obj.var_tab_param.display
                    case 'surf'
                        obj.DisplayTablePanel.Visible = 'off';
                        obj.DisplayUITable.Visible = 'off';
                        obj.DisplayTableGridLayout.Visible = 'off';
                        obj.DisplayFigurePanel.Visible = 'on';
                        
                        delete(obj.DisplayFigurePanel.Children)
                        fig = figure('Visible', 'off');
                        ax = subplot(1, 1, 1, 'Parent', fig); cla(ax);
                        imshow(data(:, :, end), obj.var_tab_param.clim, 'Parent', ax);
                        colormap(ax, 'jet'); colorbar(ax); axis(ax, 'on');
                        copyobj(ax, obj.DisplayFigurePanel);
                    case 'table'
                        obj.DisplayTablePanel.Visible = 'on';
                        obj.DisplayTableGridLayout.Visible = 'on';
                        obj.DisplayUITable.Visible = 'on';
                        obj.DisplayFigurePanel.Visible = 'off';
                        obj.DisplayUITable.Data = data(:, :, end);
                end
            catch
                send(obj.queue_pool.log, 'PIV: updating of display panel is failed')
            end
        end

        % Define a handler function at accumulation data by TCP server
        function event_accumulated(obj, data)
            % display accumulating statistic duration
            obj.OutputUITable.Data{2, 2} = {num2str(obj.tcp_server.UserData.toc)};

            % process & plot data by worker
            parfeval(@obj.process, 0, data, obj.var_tab_param, obj.queue_pool);
        end

        % Define a PIV data processing function
        function process(~, data, tab_param, queue_pool)
            % create a skew 2D window function
            function win = build_win_bin(ln_lim, ws, sz)
                win = false(sz);
                ln = round(linspace(ln_lim(1), ln_lim(2), sz(2)));
                for k = 1:size(win, 2)
                    win(ln(k):ln(k) + ws - 1, k) = ones(1, ws);
                end    
            end
            % define a calculating algorithm
            function piv_var = calculate(data, tab_param)
                piv_var.key = data.key;
                piv_var.vt = data.data; % original accumulated 3d array from davis;
                piv_var.vtc = piv_var.vt(tab_param.crop(1):end-tab_param.crop(2), ...
                    tab_param.crop(3):end-tab_param.crop(4), :); % boundary crop field;
                piv_var.vtcf = piv_var.vtc; % fill nan(zeros) in 3d array;

                switch tab_param.fill
                    case '2d'
                        piv_var.vtcf(piv_var.vtcf == 0) = nan; % davis marks empty vectors as strictly integer zero -> convert thier to nan;
                        temporary = zeros(size(piv_var.vtcf));
                        for i = 1:size(piv_var.vtcf, 3)
                            temporary(:, :, i) = fillmissing(piv_var.vtcf(:, :, i), 'linear'); % fill nans according to linear interpolation;
                        end
                        piv_var.vtcf = temporary;
                    case '3d'
                        piv_var.vtcf(piv_var.vtcf == 0) = nan; % davis marks empty vectors as strictly integer zero -> convert thier to nan;
                        piv_var.vtcf = fillmissing(piv_var.vtcf, 'linear'); % fill nans according to linear interpolation;
                end

                % avarage data along 3-axis accordiong to statistic;
                piv_var.vtcfm3d.d = piv_var.vtcf; % initial data;
                piv_var.vtcfm3d.dc = piv_var.vtcfm3d.d - mean(piv_var.vtcfm3d.d, 3); % centered data;
                piv_var.vtcfm3d.dcrms = rms(piv_var.vtcfm3d.d - mean(piv_var.vtcfm3d.d, 3), 3); % rms centered data;
                index = abs(piv_var.vtcfm3d.dc) - tab_param.kernelavg * piv_var.vtcfm3d.dcrms < 0;
                piv_var.vtcfm3d.dm = piv_var.vtcfm3d.d; % avagering statistic;
                piv_var.vtcfm3d.dm(~index) = nan;
                piv_var.vtcfm3d.dm = mean(piv_var.vtcfm3d.dm, 3, 'omitnan');

                % filtering 2d time averaged field;
                piv_var.vtcfm2d = piv_var.vtcfm3d.dm;
                switch tab_param.filter2d
                    case 'gaussian'
                        piv_var.vtcfm2d = imfilter(piv_var.vtcfm2d, fspecial('gaussian', tab_param.kernel2d(1), tab_param.kernel2d(2)));
                end

                % shift 2d field;
                winb = build_win_bin(tab_param.shift(1:2), tab_param.shift(3), size(piv_var.vtcfm2d)); % build shift index mask;
                piv_var.vtcfm2ds = reshape(piv_var.vtcfm2d(winb), [], size(piv_var.vtcfm2d, 2)); % apply mask;

                % meaning 2d field along 2-axis;
                piv_var.vtcfm1d = mean(piv_var.vtcfm2ds, 2, 'omitnan');

                % substract trend from 1d array;
                piv_var.vtcfm1ds = piv_var.vtcfm1d;
                switch tab_param.filter1d
                    case 'moving'
                        piv_var.vtcfm1ds = piv_var.vtcfm1ds - smooth(piv_var.vtcfm1ds, tab_param.kernel1d);
                    case 'off'
                        piv_var.vtcfm1ds = piv_var.vtcfm1ds - mean(piv_var.vtcfm1ds, 'omitnan');
                end

                % multiply 1d array by window function;
                piv_var.vtcfm1dsw = piv_var.vtcfm1ds .* tukeywin(size(piv_var.vtcfm1ds, 1), tab_param.tukeywin);

                % calculate spectum;
                piv_var.vtcfm1dswfft = abs(fft(piv_var.vtcfm1dsw)).^2;
            end
            % define results visualization 
            function axs = visualize(piv_var, tab_param)
                sz = [2, 4]; axs = [];
                for j = 1:prod(sz)
                    axs.(strcat('ax', num2str(j))) = subplot(sz(1), sz(2), j);
                end

                i = 1;
                % plot instantaneous field;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                label = jsonencode(size(piv_var.vt));    
                imshow(piv_var.vt(:, :, end), tab_param.clim, 'Parent', ax);
                colormap(ax, 'jet'); axis(ax, 'on');
                title(ax, strcat("instantaneous ", label), 'FontWeight', 'Normal');

                i = 2;
                % plot crop field;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                label = jsonencode(size(piv_var.vtc));     
                imshow(piv_var.vtc(:, :, end), tab_param.clim, 'Parent', ax);
                colormap(ax, 'jet'); axis(ax, 'on');
                title(ax, strcat("crop ", label), 'FontWeight', 'Normal');

                i = 3;
                % plot fill field;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                label = jsonencode(size(piv_var.vtcf));     
                imshow(piv_var.vtcf(:, :, end), tab_param.clim, 'Parent', ax);
                colormap(ax, 'jet'); axis(ax, 'on');
                title(ax, strcat("fill ", label), 'FontWeight', 'Normal');

                i = 4;
                % plot time mean field;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                label = jsonencode(size(piv_var.vtcfm3d.dm));     
                imshow(piv_var.vtcfm3d.dm, tab_param.clim, 'Parent', ax);
                colormap(ax, 'jet'); axis(ax, 'on');
                title(ax, strcat("time mean ", label), 'FontWeight', 'Normal');

                i = 5;
                % plot 2d filter field;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                label = jsonencode(size(piv_var.vtcfm2d));     
                imshow(piv_var.vtcfm2d, tab_param.clim, 'Parent', ax);
                colormap(ax, 'jet'); axis(ax, 'on');
                title(ax, strcat("2d filter ", label), 'FontWeight', 'Normal');

                i = 6;
                % plot shift field;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                label = jsonencode(size(piv_var.vtcfm2ds));     
                imshow(piv_var.vtcfm2ds, tab_param.clim, 'Parent', ax);
                colormap(ax, 'jet'); axis(ax, 'on');
                title(ax, strcat("shift ", label), 'FontWeight', 'Normal');

                i = 7;
                % plot mean along 2-axis;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
                label = jsonencode(size(piv_var.vtcfm1d));    
                plot(ax, piv_var.vtcfm1d); title(ax, strcat("mean 2d ", label), 'FontWeight', 'Normal');

                i = 8;
                % plot subtract trend;
                ax = axs.(strcat('ax', num2str(i))); cla(ax);
                hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
                label = jsonencode(size(piv_var.vtcfm1ds));    
                plot(ax, piv_var.vtcfm1ds); plot(ax, piv_var.vtcfm1dsw); 
                title(ax, strcat("subtract trend & window", label), 'FontWeight', 'Normal');
            end
            % process
            piv_var = calculate(data, tab_param);
            % send results to client
            send(queue_pool.processed, piv_var);
            % visualize
            axs = visualize(piv_var, tab_param);   
            % send plot objects to client         
            send(queue_pool.display_processed, axs);
        end

        % Define handler function at completion processing that displays calculated results
        function event_display_processed(obj, ax)
            switch obj.var_tab_param.display
                 case 'process'
                     try
                        c = struct2cell(ax);
                        obj.DisplayTablePanel.Visible = 'off';
                        obj.DisplayTableGridLayout.Visible = 'off';
                        obj.DisplayUITable.Visible = 'off';
                        obj.DisplayFigurePanel.Visible = 'on';
                        delete(obj.DisplayFigurePanel.Children)
                        for i = 1:size(c,1)
                            copyobj(c{i}, obj.DisplayFigurePanel);
                        end
                     catch
                        send(obj.queue_pool.log, 'PIV: showing of processed piv results is failed');
                     end
            end
        end

        %% Implementation of usage TCP server

        % Create TCP server
        function server = create_server(~, port, queue_pool)
            % INPUT:
            %       port - listening port
            %       queue_pool - 
            % OUTPUT:
            %       server - TPC server instance

            % define a handler function at client connection
            function callback(src, ~)
                if src.Connected
                    try
                        % decode received JSON packet
                        data = jsondecode(read(src, src.NumBytesAvailable, 'string'));
                    catch
                        % send error message via queue pool
                        send(src.UserData.queue_pool.log, 'PIV: davis transmitting packet is failed')
                    end
                    try
                        % accumulate data
                        src.UserData.data_counter = cat(3, src.UserData.data_counter, data);
                    catch
                        send(src.UserData.queue_pool.log, 'PIV: accumulation data is failed')
                    end
                    try
                        % send data via queue pool
                        send(src.UserData.queue_pool.received, src.UserData.data_counter); 
                    catch
                        send(src.UserData.queue_pool.log, 'PIV: send data via queue pool is failed')
                    end
                    try
                        % check termination criteria of statistic accumulation
                        if (size(src.UserData.data_counter, 3) >= src.UserData.count)
                            % update timer
                            src.UserData.toc = toc(src.UserData.tic); src.UserData.tic = tic;
                            src.UserData.data_send = src.UserData.data_counter;
                            % send accumulated data via queue pool
                            send(src.UserData.queue_pool.accumulated, struct('data', src.UserData.data_send, 'key', src.UserData.key));
                            % zeroing counter
                            src.UserData.data_counter = [];
                        end
                    catch
                        % send message via queue pool
                        send(src.UserData.queue_pool.log, 'PIV: termination criteria of statistic accumulation is failed')
                    end
                end
            end
            % prepare address
            [~, hostname] = system('hostname'); hostname = string(strtrim(hostname));
            address = resolvehost(hostname, 'address');
            % create TCP server instance
            server = tcpserver(address, port, 'ConnectionChangedFcn', @callback);
            % initialize default parameters
            server.UserData = struct('data_counter', [], 'count', 5, 'tic', [], 'toc', [], 'key', 0, 'queue_pool', queue_pool);
            % start timer
            server.UserData.tic = tic;
        end

        % Initialize TCP server
        function init_server(obj)
            % define callback of progress accumulation statistic     
            afterEach(obj.queue_pool.received, @obj.event_received);
            % define callback of finishing accumulation statistic
            afterEach(obj.queue_pool.accumulated, @obj.event_accumulated);
            % define callback of processed accumulated statistic
            afterEach(obj.queue_pool.processed, @obj.event_processed);
            % define callback of displaying processed accumulated statistic
            afterEach(obj.queue_pool.display_processed, @obj.event_display_processed);

            % create server
            obj.tcp_server = obj.create_server(obj.tcp_server_port, obj.queue_pool);
            % send s server configuration message
            send(obj.queue_pool.log, strcat("PIV: start tpc server ", obj.tcp_server.ServerAddress, ":", num2str(obj.tcp_server.ServerPort)));
        end

        %% UI appearance and its behaviour

        % Create components
        function create_components(obj)
            
            % Create MainGridLayout
            obj.MainGridLayout = uigridlayout(obj.parent_ui);
            obj.MainGridLayout.ColumnWidth = {'0.5x', '1x'};
            obj.MainGridLayout.RowHeight = {'1x', '0.5x', '0.5x'};

            % Create DisplayFigurePanel
            obj.DisplayFigurePanel = uipanel(obj.MainGridLayout);
            obj.DisplayFigurePanel.Title = 'Display';
            obj.DisplayFigurePanel.Layout.Row = [1 3];
            obj.DisplayFigurePanel.Layout.Column = 2;

            % Create DisplayTablePanel
            obj.DisplayTablePanel = uipanel(obj.MainGridLayout);
            obj.DisplayTablePanel.Title = 'Display';
            obj.DisplayTablePanel.Layout.Row = [1 3];
            obj.DisplayTablePanel.Layout.Column = 2;
            obj.DisplayTablePanel.Visible = 'off';

            % Create DisplayTableGridLayout
            obj.DisplayTableGridLayout = uigridlayout(obj.DisplayTablePanel);
            obj.DisplayTableGridLayout.ColumnWidth = {'1x'};
            obj.DisplayTableGridLayout.RowHeight = {'1x'};
            obj.DisplayTableGridLayout.Visible = 'off';

            % Create DisplayUITable
            obj.DisplayUITable = uitable(obj.DisplayTableGridLayout);
            obj.DisplayUITable.ColumnName = '';
            obj.DisplayUITable.RowName = {''};
            obj.DisplayUITable.Layout.Row = 1;
            obj.DisplayUITable.Layout.Column = 1;
            obj.DisplayUITable.Visible = 'off';

            % Create ParameterPanel
            obj.ParameterPanel = uipanel(obj.MainGridLayout);
            obj.ParameterPanel.Title = 'Parameters';
            obj.ParameterPanel.Layout.Row = 1;
            obj.ParameterPanel.Layout.Column = 1;

            % Create ParameterGridLayout
            obj.ParameterGridLayout = uigridlayout(obj.ParameterPanel);
            obj.ParameterGridLayout.ColumnWidth = {'1x'};
            obj.ParameterGridLayout.RowHeight = {'1x'};

            % Create ParameterUITable
            obj.ParameterUITable = uitable(obj.ParameterGridLayout);
            obj.ParameterUITable.ColumnName = '';
            obj.ParameterUITable.RowName = {};
            obj.ParameterUITable.Layout.Row = 1;
            obj.ParameterUITable.Layout.Column = 1;
            obj.ParameterUITable.CellEditCallback = createCallbackFcn(obj, @ParamaterCellEditCallback, true);

            % Create OutputPanel
            obj.OutputPanel = uipanel(obj.MainGridLayout);
            obj.OutputPanel.Title = 'Outputs';
            obj.OutputPanel.Layout.Row = 2;
            obj.OutputPanel.Layout.Column = 1;

            % Create OutputGridLayout
            obj.OutputGridLayout = uigridlayout(obj.OutputPanel);
            obj.OutputGridLayout.ColumnWidth = {'1x'};
            obj.OutputGridLayout.RowHeight = {'1x'};

            % Create OutputUITable
            obj.OutputUITable = uitable(obj.OutputGridLayout);
            obj.OutputUITable.ColumnName = '';
            obj.OutputUITable.RowName = {};
            obj.OutputUITable.Layout.Row = 1;
            obj.OutputUITable.Layout.Column = 1;

            % Create ActionPanel
            obj.ActionPanel = uipanel(obj.MainGridLayout);
            obj.ActionPanel.Title = 'Actions';
            obj.ActionPanel.Layout.Row = 3;
            obj.ActionPanel.Layout.Column = 1;

            % Create ActionGridLayout
            obj.ActionGridLayout = uigridlayout(obj.ActionPanel);
            obj.ActionGridLayout.ColumnWidth = {'1x'};
            obj.ActionGridLayout.RowHeight = {'1x'};

            % Create RestartButton
            obj.RestartButton = uibutton(obj.ActionGridLayout, 'state');
            obj.RestartButton.Text = 'Restart';
            obj.RestartButton.Layout.Row = 1;
            obj.RestartButton.Layout.Column = 1;
            obj.RestartButton.ValueChangedFcn = createCallbackFcn(obj, @RestartButtonValueChanged, true);

        end

        % Initialize components
        function init_components(obj)
            obj.DisplayFigurePanel.AutoResizeChildren = 'off';
            % set values from struct to table
            obj.init_tab_param(obj.var_tab_param, obj.ParameterUITable)

            obj.OutputUITable.Data = table({'progress'; 'time'; 'size'}, {''; '-'; ''});

            obj.DisplayUITable.ColumnName = split(num2str(1:100))';

        end

        % Define a functnio handler at cell editing of parameter table 
        function ParamaterCellEditCallback(obj, event)
            index = event.Indices(1);
            label = string(obj.ParameterUITable.Data.labels(index));
            value = obj.ParameterUITable.Data.values(index); value = value{1};
            if isa(value, 'categorical')
                obj.var_tab_param.(label) = char(value);
            end
            if isa(value, 'char')
                obj.var_tab_param.(label) = jsondecode(value);
                switch label
                    case 'statistic'
                        obj.server.UserData.count = obj.var_tab_param.statistic;
                end
            end
        end

        % Value changed function: RestartButton
        function RestartButtonValueChanged(obj, event)
            try
                delete(obj.tcp_server);
                obj.init_server();
            catch
                send(obj.queue_pool.log, 'PIV: restarting of TCP server is failed')
            end
            obj.RestartButton.Value = false;
        end

    end
end