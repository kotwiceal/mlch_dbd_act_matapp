classdef applab_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout6              matlab.ui.container.GridLayout
        TabGroup                 matlab.ui.container.TabGroup
        PIVTab                   matlab.ui.container.Tab
        GridLayout12             matlab.ui.container.GridLayout
        PIVActionsPanel          matlab.ui.container.Panel
        GridLayout15             matlab.ui.container.GridLayout
        PIVSaveButton            matlab.ui.control.StateButton
        PIVLoadButton            matlab.ui.control.StateButton
        PIVRestartButton         matlab.ui.control.StateButton
        PIVOutputsPanel          matlab.ui.container.Panel
        GridLayout14             matlab.ui.container.GridLayout
        PIVOutputsUITable        matlab.ui.control.Table
        PIVParametersPanel       matlab.ui.container.Panel
        GridLayout13             matlab.ui.container.GridLayout
        PIVParametersUITable     matlab.ui.control.Table
        PIVPreviewPanel          matlab.ui.container.Panel
        GridLayout3              matlab.ui.container.GridLayout
        PIVPreviewUITable        matlab.ui.control.Table
        DBDTab                   matlab.ui.container.Tab
        GridLayout7              matlab.ui.container.GridLayout
        DBDFrequencySliderPanel  matlab.ui.container.Panel
        GridLayout17             matlab.ui.container.GridLayout
        FrequencySlider          matlab.ui.control.Slider
        DBDVoltageSliderPanel    matlab.ui.container.Panel
        GridLayout16             matlab.ui.container.GridLayout
        VoltageSlider            matlab.ui.control.Slider
        DBDTree                  matlab.ui.container.CheckBoxTree
        MonitorPanel             matlab.ui.container.Panel
        ManualPanel              matlab.ui.container.Panel
        GridLayout8              matlab.ui.container.GridLayout
        DBDParametersTable       matlab.ui.control.Table
        DBDActionsPanel          matlab.ui.container.Panel
        GridLayout11             matlab.ui.container.GridLayout
        StopButton               matlab.ui.control.StateButton
        RequestButton            matlab.ui.control.StateButton
        SendButton               matlab.ui.control.StateButton
        LogTextArea              matlab.ui.control.TextArea
    end

    
    properties (Access = private)
        %% APP
        server_piv;

        queueEventPoolLabel = {'disp', 'logger', 'pivAccumulate', 'pivPreview', 'pivProcessed', 'pivDisplay', 'pivResetCounter', ...
            'optPreview', 'optComplete', 'optTerminate', 'mcuHttpPost', 'mesComplete', 'mesPreview', 'mesStore', 'mesTerminate', ...
            'mesTerminate', 'mesMcuUdpPost'}
        queueEventPool = struct();

        queuePollablePoolLabel = {'pivProcessed', 'mcuHttpPost'}
        queuePollableClientPool = struct();
        queuePollableWorkerPool = struct();

        poolobj = [];

        buffer_row = []
        %% PIV
        piv_tab_param = struct(port = 6060, statistic = 5, fill = categorical({'nearest'}, {'none'; 'linear'; 'nearest'}), ...
            timefilt = false, timefiltker = 7, ...
            spatfilt = categorical({'median'}, {'none'; 'gaussian'; 'average'; 'median'; 'wiener'}), ...
            spatfiltker = [3, 3], motionfilt = false, motionfiltker = 40, motionfiltdeg = 35, ...
            shift = true, shiftker = [1, 1, 50], ...
            subtrend = categorical({'moving'}, {'none'; 'moving'; 'mean'; 'poly1'}), ...
            subtrendker = 30, scale = 3.037, tukeywin = 0.4, norm = 2, ...
            display = categorical({'process'}, {'surf'; 'table'; 'process'}), clim = [1, 5]);

        piv_tab_param_def;
        piv_var = struct();
        %% DBD       
        dbd_tab_param = struct(address = '192.168.1.1', port_http = 8090, port_udp = 8080, voltage_value = 2*ones(1, 16), voltage_index = 0:15, ...
            frequency_value = [76,70,69,73,67,68,60,64,64,63,65,63,67,66,69,68], frequency_index = 0:15, ...
            mode = categorical({'frequency'}, {'all'; 'voltage'; 'frequency'}));
        dbd_tab_param_cell_select = [];
        dbd_tab_param_def;

        dbd_power_param = struct(voltage = [], frequency = [])
        dbdSliderIndex = struct(voltage = [], frequency = [])
        mcu_http_get = []
        mcu_http_post = []
        mcu_udp_post = []
    end
    
    methods (Access = private)
        %% declaration of net functions;
        function dbd_set_val(app, type, value, index)
            try
                switch type
                    case 'dac'
                        app.dbd_tab_param.voltage_value(index + 1) = value;
                        app.mcu_udp_post('dac', app.dbd_tab_param.voltage_value, app.dbd_tab_param.voltage_index);
                    case 'fm'
                        app.dbd_tab_param.frequency_value(index + 1) = value;
                        app.mcu_udp_post('fm', app.dbd_tab_param.frequency_value, app.dbd_tab_param.frequency_index);
                end
                app.dbd_display();
            catch
            end
        end

        %% declaration support functions;

        function log(app, message)
            app.LogTextArea.Value = [app.LogTextArea.Value; strcat(string(datetime), " ", message)];
            scroll(app.LogTextArea, 'bottom');
        end

        function init_worker(app)
            %% initialize pool
            app.poolobj = gcp('nocreate');
            if isempty(app.poolobj)
                app.poolobj = parpool;
            end

            %% define parallel.pool.DataQueue instances
            for i = 1:length(app.queueEventPoolLabel)
                app.queueEventPool.(app.queueEventPoolLabel{i}) = parallel.pool.DataQueue;
            end
            afterEach(app.queueEventPool.disp, @disp);
            afterEach(app.queueEventPool.logger, @app.log);

            %% define parallel.pool.Constant instances
            for i = 1:length(app.queuePollablePoolLabel)
                app.queuePollableWorkerPool.(app.queuePollablePoolLabel{i}) = parallel.pool.Constant(@parallel.pool.PollableDataQueue);
                app.queuePollableClientPool.(app.queuePollablePoolLabel{i}) = fetchOutputs(parfeval(@(x) x.Value, 1, app.queuePollableWorkerPool.(app.queuePollablePoolLabel{i})));
            end
        end

        function init_tab_param(app, tab_struct, tab_obj)
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
            app.(tab_obj).Data = dtable;
            app.(tab_obj).ColumnEditable = [false, true];
        end

        function update_tab_param(app, tab_struct, tab_obj, index)
            label = string(app.(tab_obj).Data.labels(index));
            value = app.(tab_obj).Data.values(index); value = value{1};
            try
                if isa(value, 'categorical')                
                    app.(tab_struct).(label) = value;
                end
                if isa(value, 'char') && isa(app.(tab_struct).(label), 'double')
                    app.(tab_struct).(label) = jsondecode(value);
                else
                    app.(tab_struct).(label) = value;
                end
            catch
            end
        end

        function read_tab_param(app, tab_struct, tab_obj)
            try
                for index = 1:size(app.(tab_obj).Data.labels, 1)
                    label = string(app.(tab_obj).Data.labels(index));
                    value = app.(tab_obj).Data.values(index); value = value{1};
                    if isa(value, 'categorical')                
                        app.(tab_struct).(label) = value;
                    end
                    if isa(value, 'char') && isa(app.(tab_struct).(label), 'double')
                        app.(tab_struct).(label) = jsondecode(value);
                    else
                        app.(tab_struct).(label) = value;
                    end
                end
            catch
            end
        end

        function tab_param = assemble_tab_param(~, tab_stuct, tab_struct_def)
            tab_param = tab_stuct;
            fn = fieldnames(tab_struct_def);
            for i = 1:size(fn, 1)
                label = char(fn{i});
                value = tab_struct_def.(label);
                if isa(value, 'categorical')
                    tab_param.(label) = categorical({char(tab_stuct.(label))}, categories(tab_struct_def.(label)));
                end
            end
        end
        %% declaration of PIV module functions

        function piv_init(app)
            %% initialize appearance
            app.PIVPreviewPanel.AutoResizeChildren = 'off';
            app.piv_tab_param_def = app.piv_tab_param;
            app.init_tab_param(app.piv_tab_param, 'PIVParametersUITable');
            app.PIVOutputsUITable.Data = table({'Progress'; 'Time'; 'Size'; 'Norm'}, {''; ''; ''; ''});
            app.PIVPreviewUITable.ColumnName = split(num2str(1:100))';
            %% assign callback functions
            afterEach(app.queueEventPool.pivPreview, @app.piv_callback_preview);
            afterEach(app.queueEventPool.pivAccumulate, @app.piv_callback_accumulate);
            afterEach(app.queueEventPool.pivDisplay, @app.piv_callback_display);
            afterEach(app.queueEventPool.pivProcessed, @app.piv_callback_processed);
            afterEach(app.queueEventPool.pivResetCounter, @app.piv_reset_counter);
            %% launch TCP server
            app.piv_init_tcp();
        end

        function piv_init_tcp(app)
            %% initialize TCP server receiving JSON packet
            app.server_piv  = piv_tcp_receiver(port = app.piv_tab_param.port, ...
                queueEventAccumulate = app.queueEventPool.pivAccumulate, ...
                queueEventPreview = app.queueEventPool.pivPreview, ...
                queueEventLogger = app.queueEventPool.logger);
        end

        function piv_callback_preview(app, packet)
            %% to display receiving packet info
            try
                app.PIVOutputsUITable.Data{1, 2} = {strcat(num2str(size(packet.data, 3)), '/', num2str(app.piv_tab_param.statistic))};
                app.PIVOutputsUITable.Data{3, 2} = {jsonencode(packet.size)};
            catch
                app.log('PIV: accumulation progress displaying is failed');
            end
            try
                switch char(app.piv_tab_param.display)
                    case 'surf'
                        app.PIVPreviewUITable.Visible = 'off';
                        app.GridLayout3.Visible = 'off';
                        tile = tiledlayout(app.PIVPreviewPanel, 'flow');
                        ax = nexttile(tile); imagesc(ax, packet.data(:,:,end)); axis(ax, 'image');
                        colorbar(ax); colormap(ax, 'turbo'); clim(ax, app.piv_tab_param.clim);
                    case 'table'
                        app.PIVPreviewUITable.Visible = 'on';
                        app.GridLayout3.Visible = 'on';
                        app.PIVPreviewUITable.Data = packet.data(:,:,end);
                end
            catch
                app.log('PIV: preview is failed');
            end
        end

        function piv_callback_display(app, tile)
            %% to display processing stages of accumulated data
            switch app.piv_tab_param.display
                case 'process'
                    try
                        tileglobal = tiledlayout(app.PIVPreviewPanel, 'flow'); 
                        copyobj(tile, tileglobal)
                        app.PIVPreviewUITable.Visible = 'off';
                        app.GridLayout3.Visible = 'off';
                    catch
                        app.log('PIV: showing of process PIV reuslt is failed');
                    end
           end
        end

        function piv_callback_accumulate(app, packet)
            %% to process accumulated data
            % display accumulating statistic duration
            app.PIVOutputsUITable.Data{2, 2} = {num2str(app.server_piv.UserData.toc)};
            % process and display data in background worker
            parfeval(@piv_data_process, 0, packet, app.piv_tab_param, app.queueEventPool.pivProcessed, app.queueEventPool.pivDisplay);
        end        

        function piv_callback_processed(app, packet)
            %% to send processed data to another background workers
            app.piv_var = packet;
            app.PIVOutputsUITable.Data{4, 2} = {norm(packet.data, app.piv_tab_param.norm)};
            try
                send(app.queuePollableClientPool.pivProcessed, packet);
            catch
                app.log('PIV: sending process piv reuslt to worker is failed');
            end
        end

        function piv_reset_counter(app, id)
            %% to reset counter of TCP server
            app.server_piv.UserData.stack = [];
            app.server_piv.UserData.id = id;
        end
        %% declaration DBD module functions;
        function dbd_init(app)
            %% to initialize appearance
            app.MonitorPanel.AutoResizeChildren = 'off';
            app.dbd_init_tree();
            app.dbd_init_mcu();
            app.dbd_display();

            app.dbd_tab_param_def = app.dbd_tab_param;
            app.init_tab_param(app.dbd_tab_param, 'DBDParametersTable');
            %% assign callback function
            afterEach(app.queueEventPool.mcuHttpPost, @app.mcu_http_post_par);
        end

        function dbd_init_tree(app)
            %% to initialize checkbox-tree instance for voltage and frequency vectors 
            voltage_sibling = uitreenode(app.DBDTree, 'Text', 'Voltage');
            frequency_sibling = uitreenode(app.DBDTree, 'Text', 'Frequency');
            for i = 0:15
                uitreenode(voltage_sibling, 'Text', num2str(i));
                uitreenode(frequency_sibling, 'Text', num2str(i));
            end
            expand(app.DBDTree);
        end

        function dbd_init_mcu(app)
            %% to initialize MCU methods
            app.mcu_http_get = @() mcu_http_get(address = app.dbd_tab_param.address, port = app.dbd_tab_param.port_http, log = app.queueEventPool.logger);
            app.mcu_http_post = @(type, value, index) mcu_http_post(type, value, index, address = app.dbd_tab_param.address, ...
                port = app.dbd_tab_param.port_http, log = app.queueEventPool.logger);
            app.mcu_udp_post = @(type, value, index) mcu_udp_post(type, value, index, address = app.dbd_tab_param.address, ...
                port = app.dbd_tab_param.port_udp, log = app.queueEventPool.logger);
        end

        function dbd_display(app)
            %% to visualize voltage and frequency vectors
            tile = tiledlayout(app.MonitorPanel, 'flow');
            ax = nexttile(tile); hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on'); 
            bar(ax, app.dbd_tab_param.voltage_index, app.dbd_tab_param.voltage_value); xticks(ax, app.dbd_tab_param.voltage_index);
            xlabel(ax, 'channel'); ylabel(ax, 'V, mV');
            ax = nexttile(tile); hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on'); 
            bar(ax, app.dbd_tab_param.frequency_index, app.dbd_tab_param.frequency_value); xticks(ax, app.dbd_tab_param.frequency_index); 
            xlabel(ax, 'channel'); ylabel(ax, 'f, kHz'); ylim(ax, [50, 90]);
        end

        function mcu_http_post_par(app, data)
            data = jsondecode(data);
            state = app.mcu_http_post('dac', data.dac.value, data.dac.index);
            % send(app.worker_client_http, state);
            send(app.queuePollableClientPool.mcuHttpPost, state);
            if (state)
                app.dbd_tab_param.voltage_value(data.dac.index + 1) = data.dac.value;
                app.dbd_display();
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clc; 

            warning on all
            warning on backtrace
            warning on verbose

            d = dir(fullfile(fileparts(mfilename('fullpath')), '..'));
            folder = d(1).folder;

            addpath(genpath(folder));

            app.log('APP: initialize application');

            app.init_worker();
            app.piv_init();
            app.dbd_init();
        end

        % Value changed function: SendButton
        function SendButtonValueChanged(app, event)
            try
                app.log('DBD: call the send button');
                app.read_tab_param('dbd_tab_param', 'DBDParametersTable');
                switch app.dbd_tab_param.mode
                    case 'voltage'
                        app.mcu_udp_post('dac', app.dbd_tab_param.voltage_value, app.dbd_tab_param.voltage_index);
                    case 'frequency'
                        app.mcu_udp_post('fm', app.dbd_tab_param.frequency_value, app.dbd_tab_param.frequency_index);
                    case 'all'
                        app.mcu_udp_post('dac', app.dbd_tab_param.voltage_value, app.dbd_tab_param.voltage_index);
                        app.mcu_udp_post('fm', app.dbd_tab_param.frequency_value, app.dbd_tab_param.frequency_index);
                end
                app.dbd_display();
            catch           
                app.log('DBD: call the send button failed');
            end
            app.SendButton.Value = false;
        end

        % Value changed function: StopButton
        function StopButtonValueChanged(app, event)
            app.mcu_udp_post('dac', zeros(1, 16), 0:15);
            app.dbd_tab_param.voltage_value = zeros(1, 16);
            app.StopButton.Value = false;
            app.dbd_display();
            app.log('DBD: call the stop button');
        end

        % Value changed function: RequestButton
        function RequestButtonValueChanged(app, event)
            data = app.mcu_http_get();
            if ~isempty(data)
                app.dbd_tab_param.voltage_value = data.dac.value;
                app.dbd_tab_param.frequency_value = data.fm.value;
                app.dbd_display();
            end
            app.RequestButton.Value = false;
        end

        % Cell edit callback: PIVParametersUITable
        function PIVParametersUITableCellEdit(app, event)
            index = event.Indices(1);
            label = string(app.PIVParametersUITable.Data.labels(index));
            value = app.PIVParametersUITable.Data.values(index); value = value{1};
            if isa(value, 'categorical')
                 app.piv_tab_param.(label) = char(value);
            end
            if isa(value, 'char')
                app.piv_tab_param.(label) = jsondecode(value);
                switch label
                    case 'statistic'
                        app.server_piv.UserData.number = app.piv_tab_param.statistic;
                end
            end
            if isa(value, 'logical')
                app.piv_tab_param.(label) = value;
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app);            
        end

        % Value changed function: PIVRestartButton
        function PIVRestartButtonValueChanged(app, event)
            try
                app.log('PIV: restart TCP server')
                delete(app.server_piv);
                app.piv_init_tcp();
            catch
                app.log('PIV: restart TCP server failed')
            end
            app.PIVRestartButton.Value = false;
        end

        % Callback function: DBDTree
        function DBDTreeCheckedNodesChanged(app, event)
            checkedNodes = event.CheckedNodes;
            app.dbdSliderIndex.voltage = [];
            app.dbdSliderIndex.frequency = [];
            for i = 1:size(checkedNodes, 1)        
                if ~isprop(checkedNodes(i).Parent, 'CheckedNodes')
                    switch checkedNodes(i).Parent.Text
                        case 'Voltage'
                            app.dbdSliderIndex.voltage = [app.dbdSliderIndex.voltage, str2num(checkedNodes(i).Text)];
                        case 'Frequency'
                            app.dbdSliderIndex.frequency = [app.dbdSliderIndex.frequency, str2num(checkedNodes(i).Text)];
                    end
                end 
            end
        end

        % Value changed function: VoltageSlider
        function VoltageSliderValueChanged(app, event)
            if ~isempty(app.dbdSliderIndex.voltage)
                app.dbd_tab_param.voltage_value(app.dbdSliderIndex.voltage + 1) = app.VoltageSlider.Value .* ones(1, size(app.dbdSliderIndex.voltage, 2));
                app.mcu_udp_post('dac', app.dbd_tab_param.voltage_value, app.dbd_tab_param.voltage_index);
                app.dbd_display();
            end
        end

        % Value changed function: FrequencySlider
        function FrequencySliderValueChanged(app, event)
            if ~isempty(app.dbdSliderIndex.frequency)
                app.dbd_tab_param.frequency_value(app.dbdSliderIndex.frequency + 1) = app.FrequencySlider.Value .* ones(1, size(app.dbdSliderIndex.frequency, 2));
                app.mcu_udp_post('fm', app.dbd_tab_param.frequency_value, app.dbd_tab_param.frequency_index);
                app.dbd_display();
            end
        end

        % Value changed function: PIVLoadButton
        function PIVLoadButtonValueChanged(app, event)
            try
                [file, path] = uigetfile('*.mat');
                data = load(fullfile(path, file));
                if isfield(data, 'piv_tab_param')
                    app.piv_tab_param = data.piv_tab_param;
                    app.init_tab_param(app.piv_tab_param, 'PIVParametersUITable');
                    app.server_piv.UserData.number = app.piv_tab_param.statistic;
                    app.log('PIV: loading the parameters table is succeed');
                end
            catch
                app.log('PIV: loading the parameters table is failed');
            end
            app.PIVLoadButton.Value = false;
        end

        % Value changed function: PIVSaveButton
        function PIVSaveButtonValueChanged(app, event)
            try
                [file, path, ~] = uiputfile('applab_piv.mat');
                if exist(fullfile(path, file), 'file')
                    applab = load(fullfile(path, file));

                else
                    applab = struct();
                end
                applab.piv_tab_param = app.assemble_tab_param(app.piv_tab_param, app.piv_tab_param_def);
                save(fullfile(path, file), '-struct', 'applab');
            catch
                app.log('PIV: saving the parameters table is failed');
            end

            app.PIVSaveButton.Value = false;
        end

        % Cell edit callback: DBDParametersTable
        function DBDParametersTableCellEdit(app, event)
            app.update_tab_param('dbd_tab_param', 'DBDParametersTable', event.Indices(1));

            index = event.Indices(1);
            label = string(app.DBDParametersTable.Data.labels(index));

            % redefine MCU methods
            if iscategory(categorical({'address', 'port_udp', 'port_http'}), label)
                app.dbd_init_mcu();
            end
        end

        % Cell selection callback: DBDParametersTable
        function DBDParametersTableCellSelection(app, event)
            try
                app.dbd_tab_param_cell_select = event.Indices(1);
            catch
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1452 905];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.UIFigure);
            app.GridLayout6.ColumnWidth = {'1x'};
            app.GridLayout6.RowHeight = {'8x', '1x'};
            app.GridLayout6.RowSpacing = 0;
            app.GridLayout6.Padding = [0 0 0 0];

            % Create LogTextArea
            app.LogTextArea = uitextarea(app.GridLayout6);
            app.LogTextArea.Editable = 'off';
            app.LogTextArea.Layout.Row = 2;
            app.LogTextArea.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout6);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create PIVTab
            app.PIVTab = uitab(app.TabGroup);
            app.PIVTab.Title = 'PIV';

            % Create GridLayout12
            app.GridLayout12 = uigridlayout(app.PIVTab);
            app.GridLayout12.ColumnWidth = {'0.5x', '1x'};
            app.GridLayout12.RowHeight = {'1x', '0.5x', '0.3x'};

            % Create PIVPreviewPanel
            app.PIVPreviewPanel = uipanel(app.GridLayout12);
            app.PIVPreviewPanel.Title = 'Preview';
            app.PIVPreviewPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.PIVPreviewPanel.Layout.Row = [1 3];
            app.PIVPreviewPanel.Layout.Column = 2;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.PIVPreviewPanel);
            app.GridLayout3.ColumnWidth = {'1x'};
            app.GridLayout3.RowHeight = {'1x'};

            % Create PIVPreviewUITable
            app.PIVPreviewUITable = uitable(app.GridLayout3);
            app.PIVPreviewUITable.ColumnName = '';
            app.PIVPreviewUITable.RowStriping = 'off';
            app.PIVPreviewUITable.Multiselect = 'off';
            app.PIVPreviewUITable.Visible = 'off';
            app.PIVPreviewUITable.Layout.Row = 1;
            app.PIVPreviewUITable.Layout.Column = 1;

            % Create PIVParametersPanel
            app.PIVParametersPanel = uipanel(app.GridLayout12);
            app.PIVParametersPanel.Title = 'Parameters';
            app.PIVParametersPanel.Layout.Row = 1;
            app.PIVParametersPanel.Layout.Column = 1;

            % Create GridLayout13
            app.GridLayout13 = uigridlayout(app.PIVParametersPanel);
            app.GridLayout13.ColumnWidth = {'1x'};
            app.GridLayout13.RowHeight = {'1x'};

            % Create PIVParametersUITable
            app.PIVParametersUITable = uitable(app.GridLayout13);
            app.PIVParametersUITable.ColumnName = '';
            app.PIVParametersUITable.RowName = {};
            app.PIVParametersUITable.CellEditCallback = createCallbackFcn(app, @PIVParametersUITableCellEdit, true);
            app.PIVParametersUITable.Layout.Row = 1;
            app.PIVParametersUITable.Layout.Column = 1;

            % Create PIVOutputsPanel
            app.PIVOutputsPanel = uipanel(app.GridLayout12);
            app.PIVOutputsPanel.Title = 'Outputs';
            app.PIVOutputsPanel.Layout.Row = 2;
            app.PIVOutputsPanel.Layout.Column = 1;

            % Create GridLayout14
            app.GridLayout14 = uigridlayout(app.PIVOutputsPanel);
            app.GridLayout14.ColumnWidth = {'1x'};
            app.GridLayout14.RowHeight = {'1x'};

            % Create PIVOutputsUITable
            app.PIVOutputsUITable = uitable(app.GridLayout14);
            app.PIVOutputsUITable.ColumnName = '';
            app.PIVOutputsUITable.RowName = {};
            app.PIVOutputsUITable.Layout.Row = 1;
            app.PIVOutputsUITable.Layout.Column = 1;

            % Create PIVActionsPanel
            app.PIVActionsPanel = uipanel(app.GridLayout12);
            app.PIVActionsPanel.Title = 'Actions';
            app.PIVActionsPanel.Layout.Row = 3;
            app.PIVActionsPanel.Layout.Column = 1;

            % Create GridLayout15
            app.GridLayout15 = uigridlayout(app.PIVActionsPanel);
            app.GridLayout15.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout15.RowHeight = {'1x'};

            % Create PIVRestartButton
            app.PIVRestartButton = uibutton(app.GridLayout15, 'state');
            app.PIVRestartButton.ValueChangedFcn = createCallbackFcn(app, @PIVRestartButtonValueChanged, true);
            app.PIVRestartButton.Text = 'Restart';
            app.PIVRestartButton.Layout.Row = 1;
            app.PIVRestartButton.Layout.Column = 3;

            % Create PIVLoadButton
            app.PIVLoadButton = uibutton(app.GridLayout15, 'state');
            app.PIVLoadButton.ValueChangedFcn = createCallbackFcn(app, @PIVLoadButtonValueChanged, true);
            app.PIVLoadButton.Text = 'Load';
            app.PIVLoadButton.Layout.Row = 1;
            app.PIVLoadButton.Layout.Column = 1;

            % Create PIVSaveButton
            app.PIVSaveButton = uibutton(app.GridLayout15, 'state');
            app.PIVSaveButton.ValueChangedFcn = createCallbackFcn(app, @PIVSaveButtonValueChanged, true);
            app.PIVSaveButton.Text = 'Save';
            app.PIVSaveButton.Layout.Row = 1;
            app.PIVSaveButton.Layout.Column = 2;

            % Create DBDTab
            app.DBDTab = uitab(app.TabGroup);
            app.DBDTab.Title = 'DBD';

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.DBDTab);
            app.GridLayout7.ColumnWidth = {'1x', '0.5x', '0.5x', '1x'};

            % Create ManualPanel
            app.ManualPanel = uipanel(app.GridLayout7);
            app.ManualPanel.Title = 'Manual';
            app.ManualPanel.Layout.Row = [1 2];
            app.ManualPanel.Layout.Column = 1;

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.ManualPanel);
            app.GridLayout8.ColumnWidth = {'1x'};
            app.GridLayout8.RowHeight = {'1x', '1x', '0.35x', '0.35x'};

            % Create DBDActionsPanel
            app.DBDActionsPanel = uipanel(app.GridLayout8);
            app.DBDActionsPanel.Title = 'Actions';
            app.DBDActionsPanel.Layout.Row = 4;
            app.DBDActionsPanel.Layout.Column = 1;

            % Create GridLayout11
            app.GridLayout11 = uigridlayout(app.DBDActionsPanel);
            app.GridLayout11.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout11.RowHeight = {'1x'};

            % Create SendButton
            app.SendButton = uibutton(app.GridLayout11, 'state');
            app.SendButton.ValueChangedFcn = createCallbackFcn(app, @SendButtonValueChanged, true);
            app.SendButton.Text = 'Send';
            app.SendButton.Layout.Row = 1;
            app.SendButton.Layout.Column = 1;

            % Create RequestButton
            app.RequestButton = uibutton(app.GridLayout11, 'state');
            app.RequestButton.ValueChangedFcn = createCallbackFcn(app, @RequestButtonValueChanged, true);
            app.RequestButton.Text = 'Request';
            app.RequestButton.Layout.Row = 1;
            app.RequestButton.Layout.Column = 2;

            % Create StopButton
            app.StopButton = uibutton(app.GridLayout11, 'state');
            app.StopButton.ValueChangedFcn = createCallbackFcn(app, @StopButtonValueChanged, true);
            app.StopButton.Text = 'Stop';
            app.StopButton.Layout.Row = 1;
            app.StopButton.Layout.Column = 3;

            % Create DBDParametersTable
            app.DBDParametersTable = uitable(app.GridLayout8);
            app.DBDParametersTable.ColumnName = '';
            app.DBDParametersTable.RowName = {};
            app.DBDParametersTable.CellEditCallback = createCallbackFcn(app, @DBDParametersTableCellEdit, true);
            app.DBDParametersTable.CellSelectionCallback = createCallbackFcn(app, @DBDParametersTableCellSelection, true);
            app.DBDParametersTable.Layout.Row = [1 3];
            app.DBDParametersTable.Layout.Column = 1;

            % Create MonitorPanel
            app.MonitorPanel = uipanel(app.GridLayout7);
            app.MonitorPanel.Title = 'Monitor';
            app.MonitorPanel.Layout.Row = [1 2];
            app.MonitorPanel.Layout.Column = 4;

            % Create DBDTree
            app.DBDTree = uitree(app.GridLayout7, 'checkbox');
            app.DBDTree.Layout.Row = [1 2];
            app.DBDTree.Layout.Column = 2;

            % Assign Checked Nodes
            app.DBDTree.CheckedNodesChangedFcn = createCallbackFcn(app, @DBDTreeCheckedNodesChanged, true);

            % Create DBDVoltageSliderPanel
            app.DBDVoltageSliderPanel = uipanel(app.GridLayout7);
            app.DBDVoltageSliderPanel.Title = 'Voltage';
            app.DBDVoltageSliderPanel.Layout.Row = 1;
            app.DBDVoltageSliderPanel.Layout.Column = 3;

            % Create GridLayout16
            app.GridLayout16 = uigridlayout(app.DBDVoltageSliderPanel);
            app.GridLayout16.ColumnWidth = {'1x'};
            app.GridLayout16.RowHeight = {'1x'};

            % Create VoltageSlider
            app.VoltageSlider = uislider(app.GridLayout16);
            app.VoltageSlider.Limits = [0 4];
            app.VoltageSlider.Orientation = 'vertical';
            app.VoltageSlider.ValueChangedFcn = createCallbackFcn(app, @VoltageSliderValueChanged, true);
            app.VoltageSlider.Layout.Row = 1;
            app.VoltageSlider.Layout.Column = 1;

            % Create DBDFrequencySliderPanel
            app.DBDFrequencySliderPanel = uipanel(app.GridLayout7);
            app.DBDFrequencySliderPanel.Title = 'Frequency';
            app.DBDFrequencySliderPanel.Layout.Row = 2;
            app.DBDFrequencySliderPanel.Layout.Column = 3;

            % Create GridLayout17
            app.GridLayout17 = uigridlayout(app.DBDFrequencySliderPanel);
            app.GridLayout17.ColumnWidth = {'1x'};
            app.GridLayout17.RowHeight = {'1x'};

            % Create FrequencySlider
            app.FrequencySlider = uislider(app.GridLayout17);
            app.FrequencySlider.Limits = [50 90];
            app.FrequencySlider.Orientation = 'vertical';
            app.FrequencySlider.ValueChangedFcn = createCallbackFcn(app, @FrequencySliderValueChanged, true);
            app.FrequencySlider.Layout.Row = 1;
            app.FrequencySlider.Layout.Column = 1;
            app.FrequencySlider.Value = 60;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = applab_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end