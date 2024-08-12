classdef applab_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayoutApp                 matlab.ui.container.GridLayout
        TabGroup                      matlab.ui.container.TabGroup
        PIVTab                        matlab.ui.container.Tab
        GridLayoutPIV                 matlab.ui.container.GridLayout
        PIVActionsPanel               matlab.ui.container.Panel
        GridLayoutPIVActionPanel      matlab.ui.container.GridLayout
        PIVSaveButton                 matlab.ui.control.StateButton
        PIVLoadButton                 matlab.ui.control.StateButton
        PIVRestartButton              matlab.ui.control.StateButton
        PIVOutputsPanel               matlab.ui.container.Panel
        GridLayoutPIVOutputsPanel     matlab.ui.container.GridLayout
        PIVOutputsUITable             matlab.ui.control.Table
        PIVParametersPanel            matlab.ui.container.Panel
        GridLayoutPIVParametersPanel  matlab.ui.container.GridLayout
        PIVParametersUITable          matlab.ui.control.Table
        PIVPreviewPanel               matlab.ui.container.Panel
        GridLayoutPIVPreviewPanel     matlab.ui.container.GridLayout
        PIVPreviewUITable             matlab.ui.control.Table
        DBDTab                        matlab.ui.container.Tab
        GridLayoutDBD                 matlab.ui.container.GridLayout
        DBDFrequencySliderPanel       matlab.ui.container.Panel
        GridLayoutDBDFrequencySliderPanel  matlab.ui.container.GridLayout
        FrequencySlider               matlab.ui.control.Slider
        DBDVoltageSliderPanel         matlab.ui.container.Panel
        GridLayoutDBDVoltageSliderPanel  matlab.ui.container.GridLayout
        VoltageSlider                 matlab.ui.control.Slider
        DBDTree                       matlab.ui.container.CheckBoxTree
        MonitorPanel                  matlab.ui.container.Panel
        ManualPanel                   matlab.ui.container.Panel
        GridLayoutDBDManualPanel      matlab.ui.container.GridLayout
        DBDParametersTable            matlab.ui.control.Table
        DBDActionsPanel               matlab.ui.container.Panel
        GridLayoutDBDActionsPanel     matlab.ui.container.GridLayout
        HalfButton                    matlab.ui.control.Button
        StopButton                    matlab.ui.control.StateButton
        RequestButton                 matlab.ui.control.StateButton
        SendButton                    matlab.ui.control.StateButton
        OPTTab                        matlab.ui.container.Tab
        GridLayoutOPT                 matlab.ui.container.GridLayout
        OPTTree                       matlab.ui.container.CheckBoxTree
        OPTActionsPanel               matlab.ui.container.Panel
        GridLayoutOPTActionsPanel     matlab.ui.container.GridLayout
        OPTCancelButton               matlab.ui.control.StateButton
        OPTLoadButton                 matlab.ui.control.StateButton
        OPTStartButton                matlab.ui.control.StateButton
        OPTSaveButton                 matlab.ui.control.StateButton
        OPTSettingsPanel              matlab.ui.container.Panel
        GridLayoutOPTSettingsPanel    matlab.ui.container.GridLayout
        OPTSettingsUITable            matlab.ui.control.Table
        OPTResultsPanel               matlab.ui.container.Panel
        GridLayoutOPTResultsPanel     matlab.ui.container.GridLayout
        OPTResultsUITable             matlab.ui.control.Table
        OPTPreviewPanel               matlab.ui.container.Panel
        MESTab                        matlab.ui.container.Tab
        GridLayoutMES                 matlab.ui.container.GridLayout
        MESScanPanel                  matlab.ui.container.Panel
        GridLayoutMESScanPanel        matlab.ui.container.GridLayout
        MESScanUITable                matlab.ui.control.Table
        MESActionsPanel               matlab.ui.container.Panel
        GridLayoutMESActionsPanel     matlab.ui.container.GridLayout
        MESLoadButton                 matlab.ui.control.StateButton
        MESSaveButton                 matlab.ui.control.StateButton
        MESStopButton                 matlab.ui.control.StateButton
        MESStartButton                matlab.ui.control.StateButton
        MESSettingsPanel              matlab.ui.container.Panel
        GridLayoutMESSettingsPanel    matlab.ui.container.GridLayout
        MESSettingsUITable            matlab.ui.control.Table
        SMTab                         matlab.ui.container.Tab
        GridLayoutSM                  matlab.ui.container.GridLayout
        StepMotorsPanel               matlab.ui.container.Panel
        GridLayoutSMD                 matlab.ui.container.GridLayout
        SMInitializeButton            matlab.ui.control.StateButton
        SMStatusButton                matlab.ui.control.StateButton
        SMHomeButton                  matlab.ui.control.StateButton
        SMZeroButton                  matlab.ui.control.StateButton
        SMShiftButton                 matlab.ui.control.StateButton
        SMStopButton                  matlab.ui.control.StateButton
        SMMoveButton                  matlab.ui.control.StateButton
        SMLOCUITable                  matlab.ui.control.Table
        SeedingPanel                  matlab.ui.container.Panel
        GridLayoutSMSeedingPanel      matlab.ui.container.GridLayout
        SeedingParametersUITable      matlab.ui.control.Table
        InitializeButton              matlab.ui.control.Button
        SwitchGateButton              matlab.ui.control.StateButton
        LogTextArea                   matlab.ui.control.TextArea
        MESScanContextMenu            matlab.ui.container.ContextMenu
        AddMenu                       matlab.ui.container.Menu
        ClearMenu                     matlab.ui.container.Menu
        DeleteMenu                    matlab.ui.container.Menu
        CopyMenu                      matlab.ui.container.Menu
        PasteMenu                     matlab.ui.container.Menu
        OPTResultsContextMenu         matlab.ui.container.ContextMenu
        OPTResultsCopyMenu            matlab.ui.container.Menu
        ContextMenu                   matlab.ui.container.ContextMenu
        DefaultMenu                   matlab.ui.container.Menu
        ChangeviewMenu                matlab.ui.container.Menu
        OPTParametersContextMenu      matlab.ui.container.ContextMenu
        PasteMenuOPT                  matlab.ui.container.Menu
        DBDParamContextMenu           matlab.ui.container.ContextMenu
        DBDParamPasteMenu             matlab.ui.container.Menu
    end

    
    properties (Access = private)
        %% APP
        % server instances
        server_piv; server_mes;

        % queue data pool instances
        queueEventPoolLabel = {'disp', 'logger', 'pivAccumulate', 'pivPreview', 'pivProcessed', 'pivDisplay', 'pivResetCounter', ...
            'optPreview', 'optComplete', 'optTerminate', 'mcuHttpPost', 'mcuDisable', 'mesComplete', 'mesPreview', 'mesStore', 'mesTerminate', ...
            'mesTerminate', 'mesMcuUdpPost', 'seedingWatcher', 'seedingHandle', 'seedingTimerHandle', 'sdMove', 'mcuTrigger', 'mcuCOMWrite'}
        queueEventPool = struct();

        queuePollablePoolLabel = {'pivProcessed', 'mcuHttpPost', 'seedingWatcher'}
        queuePollableClientPool = struct();
        queuePollableWorkerPool = struct();

        % background worker instances
        poolobj = []; poolfun_opt = []; poolfun_mes = [];

        % to store a row copy 
        buffer_row = []
        %% PIV
        piv_tab_param = struct(port = 6060, ... % port of TCP server transmitter
            statistic = 5, ... % volume of statistics accumulation
            fill = categorical({'nearest'}, {'none'; 'linear'; 'nearest'}), ... % apply the fill misssing method to data
            timefilt = false, ... % time filter based on data statistics
            timefiltker = 7, ... % count of time RMS to pass data at time filtering
            spatfilt = categorical({'median'}, {'none'; 'gaussian'; 'average'; 'median'; 'wiener'}), ... % spatial filter method, applied to time averaged data
            spatfiltker = [3, 3], ... % kernel of spatial filter
            motionfilt = false, ... % spatial motion filter
            motionfiltker = 40, ... % kernel of motion filter
            motionfiltdeg = 35, ... % angle of motion filter kernel
            shift = true, ... % shift transveral data index
            shiftker = [1, 1, 50], ... %  parameter at transveral data index shifting: [left top index, right top index, width]
            subtrend = categorical({'moving'}, {'none'; 'moving'; 'mean'; 'poly1'}), ... % trend substraction method: high-pass fitler
            subtrendker = 30, .... % kernel of 1D moving filter
            tukeywin = 0.4, ... % tukey window function parameter
            norm = 2, ... % norm order of transersal profile
            display = categorical({'process'}, {'surf'; 'table'; 'process'}), ... % to show workflow
            clim = [1, 5]); % colorbar limit

        piv_tab_param_def;
        piv_var = struct();
        %% DBD       
        dbd_tab_param = struct(address = '192.168.1.1', ... % MCU address
            port_http = 8090, ... % MCU HTTP port
            port_udp = 8080, ... % MCU UDP port
            voltage_value = 2*ones(1, 16), ... % voltage vector
            voltage_index = 0:15, ... % voltage channel index
            frequency_value = [76,70,69,73,67,68,60,64,64,63,65,63,67,66,69,68], ... % frequency vector
            frequency_index = 0:15, ... % frequency channel index
            mode = categorical({'frequency'}, {'all'; 'voltage'; 'frequency'})); % data transmitting mode
        dbd_tab_param_cell_select = [];
        dbd_tab_param_def;

        dbd_power_param = struct(voltage = [], frequency = [])
        dbdSliderIndex = struct(voltage = [], frequency = [])
        mcu_http_get = []
        mcu_http_post = []
        mcu_udp_post = []
        %% OPT
        opt_tab_param = struct(index = 0:15, ... % voltage channel using at optimization
            x0 = 2*ones(1,16), ... % initial approximation
            xmin = 1.3*ones(1,16), ... % upper boundary
            xmax = 3.4*ones(1,16), ... % lower boundary
            FiniteDifferenceType = categorical({'forward'}, {'forward'; 'central'}), ... % see https://www.mathworks.com/help/optim/ug/optimization-options-reference.html
            FunctionTolerance = 1, ...
            HonorBounds = true, ... 
            DiffMinChange = 0.2, ...
            StepTolerance = 0.1, ...
            method = categorical({'interior-point'}, {'interior-point'; 'active-set'; 'sqp'}), ...
            norm = 2, ... % norm order of objective function
            loop = categorical({'close'}, {'close'}), ... % type of optimization
            seed = true); % auto flow seeding

        opt_tab_param_def;
        opt_tab_param_cell_select = [];
        opt_tab_res = [];

        opt_tab_res_row_index = [];

        opt_data_openloop_def = struct('input', [], 'output', [], 'index', 0:3, 'x0', 2*ones(1, 4), 'xmin', 0*ones(1, 4), 'xmax', 4*ones(1, 4));
        opt_data_closeloop_def = struct('input', [], 'output', [], 'index', 0:15, 'x0', 2*ones(1, 16), 'xmin', 1.5*ones(1, 16), 'xmax', 3.5*ones(1, 16));
        opt_data_openloop;
        opt_data_closeloop;

        opt_tree_open_label = {'u', 'vmr', 'dvmr', 'dvmr_rms', 'dvmr_n', 'dvmr_nm', 'opt-vec', 'opt-val'};
        opt_tree_closed_label = {'input', 'output', 'value'};
        %% MES
        mes_tab_scan_row_index = [];
        mes_buffer_row = [];

        mes_tab_param = struct(port = 5050, ... % port of TCP server transmitter
            index = [0, 1, 2, 3], ... % voltage channel index
            voltage = [], ... % voltage vector
            pulldown = false, ... % reset power
            position = [0, 10, 20, 50], ... % step motors position vector
            amplitude = [0, 1.8, 2.2, 2.6], ...
            seeding = true, ...
            triggerpin = 5, ...
            grid = categorical({'generator'}, {'generator'; 'manual'}), ... % method to create scanning table
            mode = categorical({'extsync'}, {'matlab'; 'extsync'})); % measurement method: `davis` - PIV data stored in DaVis, `matlab` - in application memory, `extsync` - master - matlab, slave - davis; 
        mes_tab_param_def;
        mes_tab_scan = [];
        mes_tab_matlab_input = [];
        mes_tab_matlab_output = [];
        %% SM
        sm_device = {};
        sm_tab_loc = struct(rowname = ["current", "move", "shift"], colname = ["camera", "laser"], data = zeros(3, 2));
        %% SD
        mcu = [];
        sd_counter = 1;
        sd_tab_param = struct(port = categorical({'COM8'}, serialportlist()), ...
            channel = 4, ... % channel of TTL
            period = 20, ... % period in iteration to open seeding gate
            duration = 60, ... % seeding duration in seconds
            delay = 30); % delay after closing gate in seconds
        sd_tab_param_def = [];
        mcu_switch_seed_gate = [];
        mcu_trigger_handle = [];
        mcu_com_write = []
    end
    
    methods (Access = private)
        %% declaration of net functions;
        function dbd_set_val(app, type, value, index)
            try
                switch type
                    case 'dac'
                        app.dbd_tab_param.voltage_value(index + 1) = value;
                        app.mcu_udp_post('dac', app.dbd_tab_param.voltage_value, index + 1);
                    case 'fm'
                        app.dbd_tab_param.frequency_value(index + 1) = value;
                        app.mcu_udp_post('fm', app.dbd_tab_param.frequency_value, index + 1);
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
                app.poolobj = parpool(3);
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
                        app.GridLayoutPIVPreviewPanel.Visible = 'off';
                        tile = tiledlayout(app.PIVPreviewPanel, 'flow');
                        ax = nexttile(tile); imagesc(ax, packet.data(:,:,end)); axis(ax, 'image');
                        colorbar(ax); colormap(ax, 'turbo'); clim(ax, app.piv_tab_param.clim);
                    case 'table'
                        app.PIVPreviewUITable.Visible = 'on';
                        app.GridLayoutPIVPreviewPanel.Visible = 'on';
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
                        app.GridLayoutPIVPreviewPanel.Visible = 'off';
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
            afterEach(app.queueEventPool.mcuDisable, @app.dbd_power_reset);
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
            send(app.queuePollableClientPool.mcuHttpPost, state);
            if (state)
                app.dbd_tab_param.voltage_value(data.dac.index + 1) = data.dac.value;
                app.dbd_display();
            end
        end

        function dbd_power_reset(app, state)
            if state
                app.mcu_udp_post('dac', 0.5*ones(1,16), 0:15);
                pause(0.1);
                app.mcu_udp_post('dac', 0*ones(1,16), 0:15);
                app.dbd_tab_param.voltage_value = zeros(1, 16);
            end
        end
        %% declaration OPT module function

        function opt_init(app)
            %% to initialize appearance
            app.OPTPreviewPanel.AutoResizeChildren = 'off';
            app.opt_init_tab_param();
            app.opt_init_tab_res();

            app.opt_tab_param_def = app.opt_tab_param;
            app.opt_data_openloop = app.opt_data_openloop_def;
            app.opt_data_closeloop = app.opt_data_closeloop_def;

            app.opt_init_tree();
            %% assign callback functions
            afterEach(app.queueEventPool.optPreview, @app.opt_preview);
            afterEach(app.queueEventPool.optComplete, @app.opt_complete);
            afterEach(app.queueEventPool.optTerminate, @app.opt_terminate);
        end

        function opt_init_tab_param(app)
            %% to initialize setting table
            app.init_tab_param(app.opt_tab_param, 'OPTSettingsUITable');
        end

        function opt_init_tab_res(app)
            %% to initialize result table
            if isempty(app.opt_tab_res)
                app.OPTResultsUITable.Data = {};
            else
                addStyle(app.OPTResultsUITable, uistyle('BackgroundColor', 'White'));
                app.OPTResultsUITable.ColumnName = app.opt_tab_res.Properties.VariableNames;
                app.OPTResultsUITable.Data = app.opt_tab_res;
            end
        end

        function opt_init_tree(app)
            %% to initialize checkbox-tree instance for voltage and frequency vectors
            delete(app.OPTTree.Children);
            switch app.opt_tab_param.loop
                case 'open'
                    if isempty(app.opt_data_openloop.input)
                        sz = 0;
                    else
                        sz = numel(app.opt_data_openloop.index);
                    end
                    data_index = app.opt_data_openloop.index;
                    plot_label = app.opt_tree_open_label;
                case 'close'
                    sz = size(app.opt_data_closeloop.input, 2);
                    data_index = 1:sz;
                    plot_label = app.opt_tree_closed_label;
            end
            if (sz ~= 0)
                data_sibling = uitreenode(app.OPTTree, 'Text', 'data');
                plot_sibling = uitreenode(app.OPTTree, 'Text', 'plot');
                for i = 1:sz
                    uitreenode(data_sibling, 'Text', num2str(data_index(i)));
                end
                for i = 1:size(plot_label, 2)
                    uitreenode(plot_sibling, 'Text', string(plot_label(i)));
                end
                expand(app.OPTTree);
            end
        end

        function opt_preview_prepare(app)
            % initialize preview plots
            tile = tiledlayout(app.OPTPreviewPanel, 3, 1);
            xl = {'channel', 'z_n', 'iteration'}; 
            yl = {'voltage, V', '<u>, pixel', strcat('|<u>|_', num2str(app.opt_tab_param.norm))};
            for i = 1:3
                ax = nexttile(tile); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); xlabel(ax, xl{i}); ylabel(ax, yl{i});
            end
        end

        function opt_table_prepare(app)
            app.opt_tab_res = [];
            addStyle(app.OPTResultsUITable, uistyle('BackgroundColor', 'White'));
            app.OPTResultsUITable.Data = app.opt_tab_res;
            app.OPTResultsUITable.ColumnName = split(strcat("Time Value ", num2str(0:15)))';           
        end

        function opt_preview(app, data)
            % accumulate data at close loop mode
            app.opt_data_closeloop.input = cat(2, app.opt_data_closeloop.input, app.dbd_tab_param.voltage_value(:));
            app.opt_data_closeloop.output = cat(2, app.opt_data_closeloop.output, data.output(:));
            app.opt_data_closeloop.value = cat(1, app.opt_data_closeloop.value, data.obj_val);

            % plot data
            mesnum = numel(app.opt_data_closeloop.value);
            if mesnum > 5; index = [1, mesnum-3:mesnum]; else; index = 1:mesnum; end
            tile = tiledlayout(app.OPTPreviewPanel, 3, 1);
            ax = nexttile(tile); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); xlabel(ax, 'channel'); ylabel(ax, 'voltage, V');
            plot(ax, app.dbd_tab_param.voltage_index, app.opt_data_closeloop.input(:,index), '.-'); legend(ax, split(num2str(index)));
            ax = nexttile(tile); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); xlabel(ax, 'z_n'); ylabel(ax, '<u>, pixel');
            plot(ax, app.opt_data_closeloop.output(:,index), '.-'); legend(ax, split(num2str(index)));
            ax = nexttile(tile); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); xlabel(ax, 'iteration'); ylabel(ax, strcat('|<u>|_', num2str(app.opt_tab_param.norm)));
            plot(ax, app.opt_data_closeloop.value, '.-');

            % store and display table
            app.opt_tab_res = [app.opt_tab_res; round(data.time, 2), round(data.obj_val, 3), round(app.dbd_tab_param.voltage_value(:), 3)'];
            app.OPTResultsUITable.Data = app.opt_tab_res;

            app.opt_data_closeloop.tab_res = array2table(app.opt_tab_res);
            app.opt_data_closeloop.tab_res.Properties.VariableNames = split(strcat("Time Value ", num2str(0:15)))';

            scroll(app.OPTResultsUITable, 'bottom');
        end

        function opt_preview_select(app, data_index, plot_index)
            switch app.opt_tab_param.loop
                case 'open'
                    if ~isempty(plot_index)
                        sz = numel(plot_index);
                        data = app.opt_data_openloop;
                        sz_data_index = numel(data_index);
                        axs = [];
                        ax = app.OPTPreviewPanel;
                        for i = 1:sz
                            axs = [axs, subplot(sz, 1, i, 'Parent', ax)];
                            cla(axs(i)); hold(axs(i), 'on'); grid(axs(i), 'on'); box(axs(i), 'on'); legend(axs(i));
                            switch char(plot_index{i})
                                case 'u'
                                    if isfield(data, 'u')
                                        for j = 1:sz_data_index
                                            plot(axs(i), 0:15, data.u(:, :, j));
                                        end
                                    end
                                case 'vmr'
                                    if isfield(data, 'vmr')
                                        for j = 1:sz_data_index
                                            plot(axs(i), data.vmr(:, :, j));
                                        end
                                    end
                                case 'dvmr'
                                    if isfield(data, 'dvmr')
                                        for j = 1:sz_data_index
                                            plot(axs(i), data.dvmr(:, :, j));
                                        end
                                    end
                                case 'dvmr_rms'
                                    if isfield(data, 'dvmr_rms')
                                        for j = 1:sz_data_index
                                            plot(axs(i), data.voltage(2:end), data.dvmr_rms(:, j));
                                        end
                                    end
                                case 'dvmr_n'
                                    if isfield(data, 'dvmr_n')
                                        for j = 1:sz_data_index
                                            plot(axs(i), data.dvmr_n(:, :, j));
                                        end
                                    end
                                case 'dvmr_nm'
                                    if isfield(data, 'dvmr_nm')
                                        for j = 1:sz_data_index
                                            plot(axs(i), data.dvmr_nm(:, j));
                                        end
                                    end
                                case 'opt-vec'
                                    if isfield(data, 'vector') && isfield(data, 'vector_calib')
                                        plot(axs(i), data.index, data.vector);
                                        yyaxis(axs(i), 'right');
                                        plot(axs(i), data.index, data.vector_calib);
                                        title(axs(i), strcat('rms=', num2str(round(data.e, 3))), 'FontWeight', 'Normal');
                                    end
                                case 'opt-val'
                                    if isfield(data, 'fe')
                                        plot(axs(i), data.y);
                                        plot(axs(i), data.fe);
                                        title(axs(i), strcat('rms=', num2str(round(data.e, 3))), 'FontWeight', 'Normal');
                                    end
                            end
                        end
                    else
                        delete(app.OPTPreviewPanel.Children);
                    end
                case 'close'
                    if ~isempty(plot_index)
                        data = app.opt_data_closeloop;
                        tile = tiledlayout(app.OPTPreviewPanel, 3, 1);
                        for i = 1:numel(plot_index)
                            ax = nexttile(tile);
                            cla(ax); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
                            switch char(plot_index{i})
                                case 'input'
                                    if isfield(data, 'input') && ~isempty(data_index)
                                        plot(ax, 0:15, data.input(:, data_index), '.-');
                                        xlabel(ax, 'channel'); ylabel(ax, 'voltage, V');
                                    end
                                case 'output'
                                    if isfield(data, 'output') && ~isempty(data_index)
                                        plot(ax, data.output(:, data_index), '.-');
                                        xlabel(ax, 'z_n'); ylabel(ax, '<u>, pxl.');
                                    end
                                case 'value'
                                    if isfield(data, 'value')
                                        plot(ax, data.value, '.-');
                                        xlabel(ax, 'iteration'); ylabel(ax, strcat('|<u>|_', num2str(app.opt_tab_param.norm)));
                                    end
                            end
                        end
                    else
                        delete(app.OPTPreviewPanel.Children);
                    end
            end

        end

        function opt_terminate(app, isTerminate)
            try
                if isTerminate
                    app.OPTCancelButton.Enable = 'off';
                    if ~isempty(app.poolfun_opt)
                        cancel(app.poolfun_opt);
                    end
                    app.log('OPT: terminate optimization');
                    app.dbd_power_reset(true);
                    app.StopButton.Value = false;
                    app.dbd_display();
                    app.OPTCancelButton.Value = false;
                    app.OPTCancelButton.Enable = 'on';
                    app.OPTStartButton.Value = false;
                    app.OPTStartButton.Enable = 'on';
                    app.OPTTree.Enable = 'on';
                    app.OPTSettingsUITable.Enable = 'on';
                    app.opt_init_tree();
                    app.mcu_switch_seed_gate(0);
                end
            catch
            end
        end

        function opt_complete(app, data)
            try
                app.mcu_switch_seed_gate(0);
                app.OPTSettingsUITable.Enable = 'on';
                app.OPTStartButton.Value = false;
                app.OPTStartButton.Enable = 'on';
                app.OPTTree.Enable = 'on';
                app.opt_init_tree();

                app.opt_tab_res = [app.opt_tab_res; 0, data.value, data.vector(:)'];
                app.OPTResultsUITable.Data = app.opt_tab_res;
                scroll(app.OPTResultsUITable, 'bottom');
                addStyle(app.OPTResultsUITable, uistyle('BackgroundColor', '#77AC30'), 'row', size(app.OPTResultsUITable.Data, 1));
            catch 
                app.log('OPT: optimization comple event failed');
            end
        end

        %% declaration MES function
        function mes_init(app)
            %% initialize appearance
            app.mes_tab_param_def = app.mes_tab_param;

            % initiale parameters table of measuarement section;
            app.init_tab_param(app.mes_tab_param, 'MESSettingsUITable');

            app.mes_init_tab_scan();

            %% assign callback function
            afterEach(app.queueEventPool.mesPreview, @app.mes_scan_preview);
            afterEach(app.queueEventPool.mesStore, @app.mes_scan_store);
            afterEach(app.queueEventPool.mesComplete, @app.mes_scan_complete);
            afterEach(app.queueEventPool.mesTerminate, @app.mes_scan_terminate);
            afterEach(app.queueEventPool.mesMcuUdpPost, @(x)app.dbd_set_val('dac', x, 0:15));
        end
    
        function mes_scan_preview(app, i)
            addStyle(app.MESScanUITable, uistyle('BackgroundColor', '#77AC30'), 'row', i);
        end

        function mes_scan_complete(app, ~)
            app.MESStopButton.Value = false;
            app.MESStartButton.Value = false;
            app.MESStartButton.Enable = 'on';
            app.opt_data_openloop.output = app.mes_tab_matlab_output;
        end

        function mes_scan_store(app, data_struct)
            app.mes_tab_matlab_output = cat(2, app.mes_tab_matlab_output, data_struct.data);
            app.opt_data_openloop.data = cat(2, app.opt_data_openloop.data, data_struct.data);
        end

        function mes_scan_terminate(app, ~)
            try
               switch app.mes_tab_param.mode
                   case 'extsync'
                        delete(app.server_mes);
                        app.log('MES: TCP server is terminated, stop scanning');
                    case 'davis'
                        delete(app.server_mes);
                        app.log('MES: TCP server is terminated, stop scanning');
                    case 'matlab'
                        cancel(app.poolfun_mes)
                        app.log('MES: parallel function is terminated, stop scanning');
               end
                app.dbd_power_reset();
            catch
                app.log('MES: button click stop is failed');
            end
            app.MESStopButton.Value = false;
            app.MESStartButton.Value = false;
            app.MESStartButton.Enable = 'on';
            app.mcu_switch_seed_gate(0);
            app.mcu_trigger_handle(0);
        end

        function mes_init_tab_param(app)
            app.init_tab_param(app.mes_tab_param, 'MESSettingsUITable');
        end

        function mes_init_tab_scan(app)
            app.MESScanUITable.ColumnName = cat(1, {'axis1'; 'axis2'; 'seeding'}, "ch"+split(num2str(0:15)));
            app.MESScanUITable.Data = app.mes_tab_scan;
            app.MESScanUITable.ColumnEditable = true(1, numel(app.MESScanUITable.ColumnName));
            addStyle(app.MESScanUITable, uistyle('BackgroundColor', 'White'));
        end

        %% declaration SM function

        function sm_init(app)

            [folder, ~, ~] = fileparts(mfilename('fullpath'));

            addpath(genpath(fullfile(folder, 'libs', 'ximc')));

            if ~libisloaded('libximc.dll')
               [notfound, warnings] = loadlibrary(fullfile(folder, 'libs', 'ximc', 'libximc.dll'), @ximcm);
            end

            app.sm_init_device();
            app.sm_init_tab_loc();

            afterEach(app.queueEventPool.sdMove, @app.sm_move_pos);
        end

        function sm_move_pos(app, position)
            flag = true;
            for i = 1:size(app.sm_device, 2)
                ximc_move(app.sm_device{i}.name, position(i));
            end
            result = []; response = [];
            while flag
                for i = 1:size(app.sm_device, 2)
                    [result(i), app.sm_device{i}.state] = ximc_get_state(app.sm_device{i}.name);
                    response(i) = app.sm_device{i}.state.CurPosition;
                    if prod(~logical(result)) == 1
                        if prod(position == response)
                            flag = false;
                        end
                    end
                end
            end
        end

        function sm_init_device(app)
            probe_flags = 5; enum_hints = 'addr=192.168.1.1,172.16.2.3';
            sm_device_name = ximc_enumerate_devices_wrap(probe_flags, enum_hints);  
            if (size(sm_device_name, 2) == 0)
                app.log('SM: devices are not found');
                return;
            end
            app.log('SM: devices are initialized');
            for i = 1:size(sm_device_name, 2)
                app.sm_device{i}.name = sm_device_name{i};
            end
        end

        function sm_init_tab_loc(app)
            app.SMLOCUITable.RowName = app.sm_tab_loc.rowname;
            app.SMLOCUITable.ColumnName = app.sm_tab_loc.colname;
            app.SMLOCUITable.Data = app.sm_tab_loc.data;
            app.SMLOCUITable.ColumnEditable = true(1, size(app.sm_tab_loc.data, 2));

            for i = 1:numel(app.sm_device)
                [result, app.sm_device{i}.state] = ximc_get_state(app.sm_device{i}.name);
                if (result == 0)
                    app.SMLOCUITable.Data(1, i) = app.sm_device{i}.state.CurPosition;
                end
            end
        end

        function sm_disp_curpos(app)
            for i = 1:size(app.sm_device, 2)
                [result, app.sm_device{i}.state] = ximc_get_state(app.sm_device{i}.name);
                app.sm_device{i}.state
                if (result == 0)
                    app.SMLOCUITable.Data(1, i) = app.sm_device{i}.state.CurPosition;
                else
                    app.log(['SM: error at getting status of device ', app.sm_device{i}.name, ' with code', num2str(result)]);
                end
            end
        
        end

        function sm_move_button(app)
            for i = 1:size(app.sm_device, 2)
                ximc_move(app.sm_device{i}.name, app.sm_tab_loc.data(2, i));
            end
            app.sm_disp_curpos();
        end

        function sm_home_button(app)
            for i = 1:size(app.sm_device, 2)
                ximc_move(app.sm_device{i}.name, 0);
            end
            app.sm_disp_curpos();
        end

        function sm_status_button(app)
            app.sm_disp_curpos();
        end

        %% declaration of SD functions
        function sd_init(app)
            app.sd_tab_param_def = app.sd_tab_param;
            app.init_tab_param(app.sd_tab_param, 'SeedingParametersUITable');

            app.sm_mcu_init();

            afterEach(app.queueEventPool.seedingWatcher, @app.sd_seeding_counter);
            afterEach(app.queueEventPool.seedingHandle, @app.mcu_switch_seed_gate);
            afterEach(app.queueEventPool.seedingTimerHandle, @app.mcu_switch_seed_gate_timer);
            afterEach(app.queueEventPool.mcuTrigger, @app.mcu_trigger_handle);
            afterEach(app.queueEventPool.mcuCOMWrite, @(arg) app.mcu_com_write(arg{:}));
        end

        function sm_mcu_init(app)
            delete(app.mcu);
            try
                app.mcu = serialport(char(app.sd_tab_param.port), 9600, "Timeout", 5);
                configureTerminator(app.mcu, "CR")
                app.mcu_com_write = @(value, channel, command) mcu_com_write(value = value, channel = channel, command = command, ...
                    serial = app.mcu, log = app.queueEventPool.logger);
                app.mcu_switch_seed_gate = @(value) mcu_com_write(value = value, channel = app.sd_tab_param.channel, ...
                    serial = app.mcu, command = 'chdigout', log = app.queueEventPool.logger);
                app.mcu_trigger_handle = @(value) mcu_com_write(value = value, channel = app.mes_tab_param.triggerpin, ...
                    serial = app.mcu, command = 'chdigout', log = app.queueEventPool.logger);
                app.log(strcat("SD: serialport connected to ",char(app.sd_tab_param.port)));
            catch
                app.log("SD: serialport connection error");
            end
        end

        function sd_seeding_counter(app, state)
            if state
                app.sd_counter = app.sd_counter + 1;
                if app.sd_counter > app.sd_tab_param.period
                    app.sd_counter = 1;
                    send(app.queuePollableClientPool.seedingWatcher, ...
                        struct(duration = app.sd_tab_param.duration, delay = app.sd_tab_param.delay, state = true));
                end
            end
        end

        function mcu_switch_seed_gate_timer(app, state)
            if state
                app.dbd_power_reset(true);
                app.mcu_switch_seed_gate(1);
                pause(app.sd_tab_param.duration);
                app.mcu_switch_seed_gate(0);
                pause(app.sd_tab_param.delay);
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
            app.opt_init();
            app.mes_init();
            app.sm_init();
            app.sd_init();
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

        % Value changed function: OPTStartButton
        function OPTStartButtonValueChanged(app, event)
            if (app.OPTStartButton.Value)
                app.OPTStartButton.Enable ='off';
                
                app.sd_counter = 1;

                % it is necessary to local store variables to perform their copying in function_handles
                normval = app.opt_tab_param.norm;
    
                app.log('OPT: start the optimization');
                app.OPTTree.Enable = 'off';
                delete(app.OPTPreviewPanel.Children);
       
                %% build optimization problem
                problem.options = optimoptions('fmincon', 'Algorithm', char(app.opt_tab_param.method), ...
                    'FiniteDifferenceType', char(app.opt_tab_param.FiniteDifferenceType), 'FunctionTolerance', app.opt_tab_param.FunctionTolerance, ...
                    'HonorBounds', app.opt_tab_param.HonorBounds, ...
                    'DiffMinChange', app.opt_tab_param.DiffMinChange, 'StepTolerance', app.opt_tab_param.StepTolerance);
                problem.solver = 'fmincon';
                problem.x0 = app.opt_tab_param.x0;
                problem.lb = app.opt_tab_param.xmin;
                problem.ub = app.opt_tab_param.xmax;
                problem.index = app.opt_tab_param.index;
                % problem.func_norm = @(x) rms(x.*exp(abs(expval*x)), 'omitnan');
                problem.func_norm = @(x) norm(x, normval);
                problem.seeding = struct(auto = app.opt_tab_param.seed);

                switch app.opt_tab_param.loop
                    case 'open'
                        if ~isempty(app.opt_data_openloop.input)
                            app.opt_data_openloop.norm = app.opt_tab_param.norm;
                            opt_process_openloop(app, problem);
                        else
                            app.OPTStartButton.Value = false;
                            app.OPTStartButton.Enable = 'on';
                            app.log('OPT: open-loop data is empty');
                        end
    
                    case 'close'             
                        app.opt_preview_prepare();
                        app.opt_table_prepare();
                        app.opt_data_closeloop.input = [];
                        app.opt_data_closeloop.output = [];
                        app.opt_data_closeloop.value = [];
                        app.opt_data_closeloop.tab_res = [];
                        app.opt_data_closeloop.norm = app.opt_tab_param.norm;
                        app.OPTSettingsUITable.Enable = 'off';
                        % start closeloop optimization
                        app.poolfun_opt = parfeval(app.poolobj, @opt_process_closeloop, 0, problem, app.queueEventPool, app.queuePollableWorkerPool); 
                end
                addStyle(app.OPTResultsUITable, uistyle('BackgroundColor', 'White'));
            end
        end

        % Value changed function: OPTCancelButton
        function OPTCancelButtonValueChanged(app, event)
            try
                if (app.OPTCancelButton.Value)
                    app.OPTCancelButton.Enable = 'off';
                    if ~isempty(app.poolfun_opt)
                        cancel(app.poolfun_opt);
                    end
                    app.log('OPT: terminate optimization');
                    app.dbd_tab_param.voltage_value = zeros(1, 16);
                    app.mcu_udp_post('dac', zeros(1, 16), 0:15);
                    app.StopButton.Value = false;
                    app.dbd_display();
                    app.OPTCancelButton.Value = false;
                    app.OPTCancelButton.Enable = 'on';
                    app.OPTStartButton.Value = false;
                    app.OPTStartButton.Enable = 'on';
                    app.OPTTree.Enable = 'on';
                    app.OPTSettingsUITable.Enable = 'on';
                    app.opt_init_tree();
                end
            catch
            end
        end

        % Value changed function: OPTSaveButton
        function OPTSaveButtonValueChanged(app, event)
            try

                [file, path, ~] = uiputfile('applab.mat');
                [~, name, ~] = fileparts(fullfile(path, file));

                if exist(fullfile(path, file), 'file')
                    applab = load(fullfile(path, file));
                else
                    applab = struct();
                end

                applab.opt_tab_param = app.assemble_tab_param(app.opt_tab_param, app.opt_tab_param_def);
                if ~isempty(app.OPTResultsUITable.Data)
                    applab.opt_tab_res = array2table(app.OPTResultsUITable.Data, 'VariableNames', app.OPTResultsUITable.ColumnName);
                end

                if ~isempty(app.opt_data_openloop)
                    applab.opt_data_openloop = app.opt_data_openloop;
                end

                if ~isempty(app.opt_data_closeloop)
                    applab.opt_data_closeloop = app.opt_data_closeloop;
                end

                fig = figure('Visible','on');
                ax = copyobj(findobj(app.OPTPreviewPanel, 'Type', 'axes'), fig);
                savefig(fig, fullfile(path, strcat(name, '_fig_opt.fig')));
                delete(fig);

                save(fullfile(path, file), '-struct', 'applab');
                app.log('OPT: saving the parameters, results, table and fiugres is succeed');
            catch
                app.log('OPT: saving the parameters, results, table and fiugres is failed');
            end
            app.OPTSaveButton.Value = false;
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
            try
                cancel(app.poolfun_opt);
            catch
            end
            delete(app.mcu);
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

        % Double-clicked callback: OPTResultsUITable
        function OPTResultsUITableDoubleClicked(app, event)
            displayRow = event.InteractionInformation.DisplayRow;
            try
                app.OPTSettingsUITable.Data(2, 2) = {jsonencode(round(app.OPTResultsUITable.Data(displayRow, 3:end),3))};
                app.log('OPT: copy voltage vector and paste as iniaital approximation');
            catch
                app.log('OPT: copy voltage vector by double click failed');
            end
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

        % Value changed function: MESStartButton
        function MESStartButtonValueChanged(app, event)
            app.MESStartButton.Enable = 'off';
            % reset actuator power
            app.dbd_set_val('dac', zeros(1, 16), 0:15);
            app.dbd_set_val('fm', app.dbd_tab_param.frequency_value, app.dbd_tab_param.frequency_index);
            % build scan grid
            tab_scan = [];
            switch char(app.mes_tab_param.grid)
                case 'generator'
                    addStyle(app.MESScanUITable, uistyle('BackgroundColor', 'White'));
                    app.mes_init_tab_scan();
                    [tab_scan, mask] = mes_scan_tab_gen(voltage = app.mes_tab_param.voltage, channel = app.mes_tab_param.index, ...
                        position = app.mes_tab_param.position, amplitude = app.mes_tab_param.amplitude, ...
                        period = app.sd_tab_param.period, ...
                        pulldown = app.mes_tab_param.pulldown, ...
                        queueEventLogger = app.queueEventPool.logger);
                    app.MESScanUITable.Data = tab_scan;
                case 'manual'
                    addStyle(app.MESScanUITable, uistyle('BackgroundColor', 'White'));
                    if isa(app.MESScanUITable.Data, 'table')
                        tab_scan = table2array(app.MESScanUITable.Data)';
                    end
                    if isa(app.MESScanUITable.Data, 'double')
                        tab_scan = app.MESScanUITable.Data';
                    end
            end
            app.mes_tab_scan = tab_scan;
            switch app.mes_tab_param.mode
                case 'matlab'
                    if ~isempty(tab_scan)
                        app.opt_data_openloop.index = app.mes_tab_param.index;
                        app.opt_data_openloop.x0 = app.opt_data_openloop_def.x0(1) * ones(1, numel(app.opt_data_openloop.index));
                        app.opt_data_openloop.xmin = app.opt_data_openloop_def.xmin(1) * ones(1, numel(app.opt_data_openloop.index));
                        app.opt_data_openloop.xmax = app.opt_data_openloop_def.xmax(1) * ones(1, numel(app.opt_data_openloop.index));
                        app.opt_data_openloop.voltage = app.mes_tab_param.voltage;
                        app.opt_data_openloop.input = tab_scan;
                        app.opt_data_openloop.tab_res = [];
                        app.opt_data_openloop.output = [];
                        app.mes_tab_matlab_output = [];
                        app.opt_data_openloop.vtcfm1d = [];
                        app.opt_data_openloop
                        app.poolfun_mes = parfeval(app.poolobj, @mes_scan, 0, tab_scan, 0:15, app.queueEventPool, app.queuePollableWorkerPool);
                    else
                        app.mes_scan_complete();
                    end
                case 'extsync'
                   app.server_mes = mes_tcp_eventer(port = app.mes_tab_param.port, ...
                        queueEventPost = app.queueEventPool.mesMcuUdpPost, scan = tab_scan, mask = mask, ...
                        queueEventSeeding = app.queueEventPool.seedingTimerHandle, ...
                        queueEventPreview = app.queueEventPool.mesPreview, ...
                        queueEventMove = app.queueEventPool.sdMove, ...
                        queueEventTrigger = app.queueEventPool.mcuTrigger, ...
                        queueEventTerminate = app.queueEventPool.mesTerminate, queueEventLogger = app.queueEventPool.logger);
            end
        end

        % Value changed function: MESStopButton
        function MESStopButtonValueChanged(app, event)
            app.mes_scan_terminate();
        end

        % Value changed function: MESSaveButton
        function MESSaveButtonValueChanged(app, event)
            try
                [file, path, ~] = uiputfile('applab.mat');

                if exist(fullfile(path, file), 'file')
                    applab = load(fullfile(path, file));
                else
                    applab = struct();
                end
                
                applab.mes_tab_param = app.assemble_tab_param(app.mes_tab_param, app.mes_tab_param_def);
                if ~isempty(app.MESScanUITable.Data)
                    applab.mes_tab_scan = array2table(app.MESScanUITable.Data, 'VariableNames', app.MESScanUITable.ColumnName);
                end

                if ~isempty(app.mes_tab_matlab_output)
                    applab.mes_tab_matlab = app.mes_tab_matlab_output;
                end

                save(fullfile(path, file), '-struct', 'applab');
                app.log('MES: saveing the scanning table is succeed');
            catch
                app.log('MES: saveing the scanning table is failed');
            end
            app.MESSaveButton.Value = false;
        end

        % Menu selected function: AddMenu
        function AddMenuSelected(app, event)
            try
                app.mes_tab_scan = [app.mes_tab_scan; zeros(1, 16)];
                app.mes_init_tab_scan();
                app.log('MES: appending scan table row is succeed');
            catch
                app.log('MES: appending scan table row is failed');
            end
        end

        % Menu selected function: ClearMenu
        function ClearMenuSelected(app, event)
            try
                app.mes_tab_scan = [];
                app.mes_init_tab_scan();
                app.log('MES: clearing scan table is succeed');
            catch
                app.log('MES: clearing scan table is failed');
            end
        end

        % Cell selection callback: MESScanUITable
        function MESScanUITableCellSelection(app, event)
            try
                app.mes_tab_scan_row_index = event.Indices(1);
            catch
            end
        end

        % Menu selected function: DeleteMenu
        function DeleteMenuSelected(app, event)
            try
                app.mes_tab_scan(app.mes_tab_scan_row_index, :) = [];
                app.mes_init_tab_scan();
                app.log('MES: deleting scan table row is succeed');
            catch
                app.log('MES: deleting scan table row is failed');
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
                [file, path, ~] = uiputfile('applab.mat');
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

        % Cell edit callback: OPTSettingsUITable
        function OPTSettingsUITableCellEdit(app, event)
            index = event.Indices(1);
            label = string(app.OPTSettingsUITable.Data.labels(index));
            value = app.OPTSettingsUITable.Data.values(index); value = value{1};
            try
                if isa(value, 'categorical')                
                     app.opt_tab_param.(label) = value;
                     switch label
                         case 'loop'
                            app.opt_init_tree();                          
                            switch char(value)
                                 case 'open'
                                    app.opt_tab_param.index = app.opt_data_openloop.index;
                                    app.opt_tab_param.x0 = app.opt_data_openloop.x0;
                                    app.opt_tab_param.xmin = app.opt_data_openloop.xmin;
                                    app.opt_tab_param.xmax = app.opt_data_openloop.xmax;
                                    app.init_tab_param(app.opt_tab_param, 'OPTSettingsUITable');

                                    if isfield(app.opt_data_openloop, 'tab_res')
                                        if ~isempty(app.opt_data_openloop.tab_res)
                                            app.opt_tab_res = app.opt_data_openloop.tab_res;
                                            app.opt_init_tab_res();
                                        end
                                    end
                                 case 'close'
                                    app.opt_tab_param.index = app.opt_data_closeloop.index;
                                    app.opt_tab_param.x0 = app.opt_data_closeloop.x0;
                                    app.opt_tab_param.xmin = app.opt_data_closeloop.xmin;
                                    app.opt_tab_param.xmax = app.opt_data_closeloop.xmax;
                                    app.init_tab_param(app.opt_tab_param, 'OPTSettingsUITable');

                                    if isfield(app.opt_data_closeloop, 'tab_res')
                                        if ~isempty(app.opt_data_closeloop.tab_res)
                                            app.opt_tab_res = app.opt_data_closeloop.tab_res;
                                            app.opt_init_tab_res();
                                        end
                                    end
                             end
                     end
                end
                if isa(value, 'char')
                    app.opt_tab_param.(label) = jsondecode(value);
                    if iscategory(categorical({'x0', 'xmin', 'xmax', 'index'}), label)
                        switch app.opt_tab_param.loop
                            case 'open'
                                app.opt_data_openloop.(label) = app.opt_tab_param.(label);
                            case 'close'
                                app.opt_data_closeloop.(label) = app.opt_tab_param.(label);
                        end
                    end
                end
                if isa(value, 'logical')
                    app.opt_tab_param.(label) = value;
                end
            catch
            end
        end

        % Menu selected function: CopyMenu
        function CopyMenuSelected(app, event)
            try
                app.buffer_row = app.MESScanUITable.Data(app.mes_tab_scan_row_index, :);
            catch
            end
        end

        % Menu selected function: PasteMenu
        function PasteMenuSelected(app, event)
            try
                app.MESScanUITable.Data(app.mes_tab_scan_row_index, :) = app.buffer_row;
            catch
            end
        end

        % Menu selected function: OPTResultsCopyMenu
        function OPTResultsCopyMenuSelected(app, event)
            try
                row = app.OPTResultsUITable.Data(app.opt_tab_res_row_index, 3:end);
                if isa(row, 'table')
                    app.buffer_row = table2array(app.OPTResultsUITable.Data(app.opt_tab_res_row_index, 2:end));
                end
                if isa(row, 'double')
                    app.buffer_row = app.OPTResultsUITable.Data(app.opt_tab_res_row_index, 3:end);
                end
            catch
            end
        end

        % Value changed function: OPTLoadButton
        function OPTLoadButtonValueChanged(app, event)
            try
                [file, path] = uigetfile('*.mat');
                applab = load(fullfile(path, file));
                if isfield(applab, 'opt_tab_param')
                    app.opt_tab_param = applab.opt_tab_param;
                    app.opt_init_tab_param();
                end
                if isfield(applab, 'opt_tab_res')
                    app.opt_tab_res = applab.opt_tab_res;
                    app.opt_init_tab_res();
                end
                if isfield(applab, 'opt_data_openloop')
                    app.opt_data_openloop = applab.opt_data_openloop;
                    app.opt_init_tree();
                end
                if isfield(applab, 'opt_data_closeloop')
                    app.opt_data_closeloop = applab.opt_data_closeloop;
                    app.opt_init_tree();
                end
                app.log('OPT: loading the parameters table is succeed');
            catch
                app.log('OPT: loading the parameters table is failed');
            end
            app.OPTLoadButton.Value = false;
        end

        % Context menu opening function: OPTResultsContextMenu
        function OPTResultsContextMenuOpening(app, event)
            app.OPTResultsUITable.Data
            app.opt_tab_res_row_index
            app.OPTResultsUITable.Data(app.opt_tab_res_row_index, :)
        end

        % Cell selection callback: OPTResultsUITable
        function OPTResultsUITableCellSelection(app, event)
            try
                app.opt_tab_res_row_index = event.Indices(1);
            catch
            end
        end

        % Value changed function: MESLoadButton
        function MESLoadButtonValueChanged(app, event)
            try
                [file, path] = uigetfile('*.mat');
                applab = load(fullfile(path, file));
                if isfield(applab, 'mes_tab_param')
                    app.mes_tab_param = applab.mes_tab_param;
                    app.mes_init_tab_param();
                    app.log('MES: loading the parameters table is succeed');
                end
                if isfield(applab, 'mes_tab_scan')
                    app.mes_tab_scan = applab.mes_tab_scan;
                    app.mes_init_tab_scan();
                    app.log('MES: loading the scan table is succeed');
                end
            catch
                app.log('MES: loading the parameters and scan tables is failed');
            end
            app.MESLoadButton.Value = false;
        end

        % Value changed function: SMMoveButton
        function SMMoveButtonValueChanged(app, event)
            app.sm_move_button();
            app.SMMoveButton.Value = false;
        end

        % Cell edit callback: SMLOCUITable
        function SMLOCUITableCellEdit(app, event)
            try
                ir = event.Indices(1);
                ic = event.Indices(2);
                app.sm_tab_loc.data(ir, ic) = double(app.SMLOCUITable.Data(ir, ic));
            catch
            end
        end

        % Value changed function: SMHomeButton
        function SMHomeButtonValueChanged(app, event)
            app.sm_home_button();
            app.SMHomeButton.Value = false;
        end

        % Value changed function: SMStatusButton
        function SMStatusButtonValueChanged(app, event)
            app.sm_status_button();
            app.SMStatusButton.Value = false;
        end

        % Cell edit callback: MESSettingsUITable
        function MESSettingsUITableCellEdit(app, event)
            app.update_tab_param('mes_tab_param', 'MESSettingsUITable', event.Indices(1));
            
            index = event.Indices(1);
            label = string(app.MESSettingsUITable.Data.labels(index));

            % redefine MCU method
            if iscategory(categorical({'triggerpin'}), label)
                app.mcu_trigger_handle = @(value) mcu_com_write(value = value, channel = app.mes_tab_param.triggerpin, ...
                    serial = app.mcu, command = 'chdigout', log = app.queueEventPool.logger);
            end
        end

        % Cell edit callback: MESScanUITable
        function MESScanUITableCellEdit(app, event)
            try
                indices = event.Indices;
                newData = event.NewData;
                app.mes_tab_scan(indices(1), indices(2)) = newData;
                app.log('MES: cell value changing of scan table is succeed');
            catch
                app.log('MES: cell value changing of scan table is failed');
            end
        end

        % Callback function: OPTTree
        function OPTTreeCheckedNodesChanged(app, event)
            checkedNodes = event.CheckedNodes;
            data_index = []; plot_index = {};
            for i = 1:size(checkedNodes, 1)        
                if ~isprop(checkedNodes(i).Parent, 'CheckedNodes')
                    switch checkedNodes(i).Parent.Text
                        case 'data'
                            data_index = cat(1, data_index, str2num(checkedNodes(i).Text));
                        case 'plot'
                            plot_index = cat(1, plot_index, checkedNodes(i).Text);
                    end
                end 
            end
            app.opt_preview_select(data_index, plot_index);
        end

        % Menu selected function: DefaultMenu
        function DefaultMenuMenuSelected(app, event)
            app.dbd_tab_param = app.dbd_tab_param_def;
            app.init_tab_param(app.dbd_tab_param, 'DBDParametersTable');
        end

        % Cell edit callback: DBDParametersTable
        function DBDParametersTableCellEdit(app, event)
            app.update_tab_param('dbd_tab_param', 'DBDParametersTable', event.Indices(1));

            index = event.Indices(1);
            label = string(app.DBDParametersTable.Data.labels(index));

            % redefine MCU method
            if iscategory(categorical({'address', 'port_udp', 'port_http'}), label)
                app.dbd_init_mcu();
            end
        end

        % Menu selected function: PasteMenuOPT
        function PasteMenuOPTSelected(app, event)
            % there is error
            label = app.OPTSettingsUITable.Data.labels(app.opt_tab_param_cell_select); label = label{1};
            switch label
                case 'x0'
                    app.opt_tab_param.(label) = jsonencode(app.buffer_row);
                    app.init_tab_param(app.opt_tab_param, 'OPTSettingsUITable');
            end
        end

        % Cell selection callback: OPTSettingsUITable
        function OPTSettingsUITableCellSelection(app, event)
            % app.opt_tab_param_cell_select = event.Indices(1);
        end

        % Cell selection callback: DBDParametersTable
        function DBDParametersTableCellSelection(app, event)
            try
                app.dbd_tab_param_cell_select = event.Indices(1);
            catch
            end
        end

        % Menu selected function: DBDParamPasteMenu
        function DBDParamPasteMenuSelected(app, event)
            label = app.DBDParametersTable.Data.labels(app.dbd_tab_param_cell_select); label = label{1};
            switch label
                case 'voltage_value'
                    app.dbd_tab_param.(label) = jsonencode(app.buffer_row);
                    app.init_tab_param(app.dbd_tab_param, 'DBDParametersTable');
            end
        end

        % Button pushed function: InitializeButton
        function InitializeButtonPushed(app, event)
            app.sm_mcu_init();
        end

        % Value changed function: SwitchGateButton
        function SwitchGateButtonValueChanged(app, event)
            app.mcu_switch_seed_gate(event.Value);
        end

        % Button pushed function: HalfButton
        function HalfButtonPushed(app, event)
            app.mcu_udp_post('dac', 0.5*ones(1, 16), 0:15);
            app.dbd_tab_param.voltage_value = zeros(1, 16);
            app.StopButton.Value = false;
            app.dbd_display();
            app.log('DBD: call the half button');
        end

        % Cell edit callback: SeedingParametersUITable
        function SeedingParametersUITableCellEdit(app, event)
            app.update_tab_param('sd_tab_param', 'SeedingParametersUITable', event.Indices(1));

            index = event.Indices(1);
            label = string(app.SeedingParametersUITable.Data.labels(index));

            % redefine MCU method
            if iscategory(categorical({'port', 'channel'}), label)
                app.mcu_switch_seed_gate = @(value) mcu_com_write(value = value, channel = app.sd_tab_param.channel, ...
                    serial = app.mcu, command = 'chdigout', log = app.queueEventPool.logger);
            end
        end

        % Value changed function: SMInitializeButton
        function SMInitializeButtonValueChanged(app, event)
            app.sm_init_device();
            app.sm_init_tab_loc();
            app.SMInitializeButton.Value = false;
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

            % Create GridLayoutApp
            app.GridLayoutApp = uigridlayout(app.UIFigure);
            app.GridLayoutApp.ColumnWidth = {'1x'};
            app.GridLayoutApp.RowHeight = {'8x', '1x'};
            app.GridLayoutApp.RowSpacing = 0;
            app.GridLayoutApp.Padding = [0 0 0 0];

            % Create LogTextArea
            app.LogTextArea = uitextarea(app.GridLayoutApp);
            app.LogTextArea.Editable = 'off';
            app.LogTextArea.Layout.Row = 2;
            app.LogTextArea.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayoutApp);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create PIVTab
            app.PIVTab = uitab(app.TabGroup);
            app.PIVTab.Title = 'PIV';

            % Create GridLayoutPIV
            app.GridLayoutPIV = uigridlayout(app.PIVTab);
            app.GridLayoutPIV.ColumnWidth = {'0.5x', '1x'};
            app.GridLayoutPIV.RowHeight = {'1x', '0.5x', '0.3x'};

            % Create PIVPreviewPanel
            app.PIVPreviewPanel = uipanel(app.GridLayoutPIV);
            app.PIVPreviewPanel.Title = 'Preview';
            app.PIVPreviewPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.PIVPreviewPanel.Layout.Row = [1 3];
            app.PIVPreviewPanel.Layout.Column = 2;

            % Create GridLayoutPIVPreviewPanel
            app.GridLayoutPIVPreviewPanel = uigridlayout(app.PIVPreviewPanel);
            app.GridLayoutPIVPreviewPanel.ColumnWidth = {'1x'};
            app.GridLayoutPIVPreviewPanel.RowHeight = {'1x'};

            % Create PIVPreviewUITable
            app.PIVPreviewUITable = uitable(app.GridLayoutPIVPreviewPanel);
            app.PIVPreviewUITable.ColumnName = '';
            app.PIVPreviewUITable.RowStriping = 'off';
            app.PIVPreviewUITable.Multiselect = 'off';
            app.PIVPreviewUITable.Visible = 'off';
            app.PIVPreviewUITable.Layout.Row = 1;
            app.PIVPreviewUITable.Layout.Column = 1;

            % Create PIVParametersPanel
            app.PIVParametersPanel = uipanel(app.GridLayoutPIV);
            app.PIVParametersPanel.Title = 'Parameters';
            app.PIVParametersPanel.Layout.Row = 1;
            app.PIVParametersPanel.Layout.Column = 1;

            % Create GridLayoutPIVParametersPanel
            app.GridLayoutPIVParametersPanel = uigridlayout(app.PIVParametersPanel);
            app.GridLayoutPIVParametersPanel.ColumnWidth = {'1x'};
            app.GridLayoutPIVParametersPanel.RowHeight = {'1x'};

            % Create PIVParametersUITable
            app.PIVParametersUITable = uitable(app.GridLayoutPIVParametersPanel);
            app.PIVParametersUITable.ColumnName = '';
            app.PIVParametersUITable.RowName = {};
            app.PIVParametersUITable.CellEditCallback = createCallbackFcn(app, @PIVParametersUITableCellEdit, true);
            app.PIVParametersUITable.Layout.Row = 1;
            app.PIVParametersUITable.Layout.Column = 1;

            % Create PIVOutputsPanel
            app.PIVOutputsPanel = uipanel(app.GridLayoutPIV);
            app.PIVOutputsPanel.Title = 'Outputs';
            app.PIVOutputsPanel.Layout.Row = 2;
            app.PIVOutputsPanel.Layout.Column = 1;

            % Create GridLayoutPIVOutputsPanel
            app.GridLayoutPIVOutputsPanel = uigridlayout(app.PIVOutputsPanel);
            app.GridLayoutPIVOutputsPanel.ColumnWidth = {'1x'};
            app.GridLayoutPIVOutputsPanel.RowHeight = {'1x'};

            % Create PIVOutputsUITable
            app.PIVOutputsUITable = uitable(app.GridLayoutPIVOutputsPanel);
            app.PIVOutputsUITable.ColumnName = '';
            app.PIVOutputsUITable.RowName = {};
            app.PIVOutputsUITable.Layout.Row = 1;
            app.PIVOutputsUITable.Layout.Column = 1;

            % Create PIVActionsPanel
            app.PIVActionsPanel = uipanel(app.GridLayoutPIV);
            app.PIVActionsPanel.Title = 'Actions';
            app.PIVActionsPanel.Layout.Row = 3;
            app.PIVActionsPanel.Layout.Column = 1;

            % Create GridLayoutPIVActionPanel
            app.GridLayoutPIVActionPanel = uigridlayout(app.PIVActionsPanel);
            app.GridLayoutPIVActionPanel.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayoutPIVActionPanel.RowHeight = {'1x'};

            % Create PIVRestartButton
            app.PIVRestartButton = uibutton(app.GridLayoutPIVActionPanel, 'state');
            app.PIVRestartButton.ValueChangedFcn = createCallbackFcn(app, @PIVRestartButtonValueChanged, true);
            app.PIVRestartButton.Text = 'Restart';
            app.PIVRestartButton.Layout.Row = 1;
            app.PIVRestartButton.Layout.Column = 3;

            % Create PIVLoadButton
            app.PIVLoadButton = uibutton(app.GridLayoutPIVActionPanel, 'state');
            app.PIVLoadButton.ValueChangedFcn = createCallbackFcn(app, @PIVLoadButtonValueChanged, true);
            app.PIVLoadButton.Text = 'Load';
            app.PIVLoadButton.Layout.Row = 1;
            app.PIVLoadButton.Layout.Column = 1;

            % Create PIVSaveButton
            app.PIVSaveButton = uibutton(app.GridLayoutPIVActionPanel, 'state');
            app.PIVSaveButton.ValueChangedFcn = createCallbackFcn(app, @PIVSaveButtonValueChanged, true);
            app.PIVSaveButton.Text = 'Save';
            app.PIVSaveButton.Layout.Row = 1;
            app.PIVSaveButton.Layout.Column = 2;

            % Create DBDTab
            app.DBDTab = uitab(app.TabGroup);
            app.DBDTab.Title = 'DBD';

            % Create GridLayoutDBD
            app.GridLayoutDBD = uigridlayout(app.DBDTab);
            app.GridLayoutDBD.ColumnWidth = {'1x', '0.5x', '0.5x', '1x'};

            % Create ManualPanel
            app.ManualPanel = uipanel(app.GridLayoutDBD);
            app.ManualPanel.Title = 'Manual';
            app.ManualPanel.Layout.Row = [1 2];
            app.ManualPanel.Layout.Column = 1;

            % Create GridLayoutDBDManualPanel
            app.GridLayoutDBDManualPanel = uigridlayout(app.ManualPanel);
            app.GridLayoutDBDManualPanel.ColumnWidth = {'1x'};
            app.GridLayoutDBDManualPanel.RowHeight = {'1x', '1x', '0.35x', '0.35x'};

            % Create DBDActionsPanel
            app.DBDActionsPanel = uipanel(app.GridLayoutDBDManualPanel);
            app.DBDActionsPanel.Title = 'Actions';
            app.DBDActionsPanel.Layout.Row = 4;
            app.DBDActionsPanel.Layout.Column = 1;

            % Create GridLayoutDBDActionsPanel
            app.GridLayoutDBDActionsPanel = uigridlayout(app.DBDActionsPanel);
            app.GridLayoutDBDActionsPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayoutDBDActionsPanel.RowHeight = {'1x'};

            % Create SendButton
            app.SendButton = uibutton(app.GridLayoutDBDActionsPanel, 'state');
            app.SendButton.ValueChangedFcn = createCallbackFcn(app, @SendButtonValueChanged, true);
            app.SendButton.Text = 'Send';
            app.SendButton.Layout.Row = 1;
            app.SendButton.Layout.Column = 1;

            % Create RequestButton
            app.RequestButton = uibutton(app.GridLayoutDBDActionsPanel, 'state');
            app.RequestButton.ValueChangedFcn = createCallbackFcn(app, @RequestButtonValueChanged, true);
            app.RequestButton.Text = 'Request';
            app.RequestButton.Layout.Row = 1;
            app.RequestButton.Layout.Column = 2;

            % Create StopButton
            app.StopButton = uibutton(app.GridLayoutDBDActionsPanel, 'state');
            app.StopButton.ValueChangedFcn = createCallbackFcn(app, @StopButtonValueChanged, true);
            app.StopButton.Text = 'Stop';
            app.StopButton.Layout.Row = 1;
            app.StopButton.Layout.Column = 3;

            % Create HalfButton
            app.HalfButton = uibutton(app.GridLayoutDBDActionsPanel, 'push');
            app.HalfButton.ButtonPushedFcn = createCallbackFcn(app, @HalfButtonPushed, true);
            app.HalfButton.Layout.Row = 1;
            app.HalfButton.Layout.Column = 4;
            app.HalfButton.Text = 'Half';

            % Create DBDParametersTable
            app.DBDParametersTable = uitable(app.GridLayoutDBDManualPanel);
            app.DBDParametersTable.ColumnName = '';
            app.DBDParametersTable.RowName = {};
            app.DBDParametersTable.CellEditCallback = createCallbackFcn(app, @DBDParametersTableCellEdit, true);
            app.DBDParametersTable.CellSelectionCallback = createCallbackFcn(app, @DBDParametersTableCellSelection, true);
            app.DBDParametersTable.Layout.Row = [1 3];
            app.DBDParametersTable.Layout.Column = 1;

            % Create MonitorPanel
            app.MonitorPanel = uipanel(app.GridLayoutDBD);
            app.MonitorPanel.Title = 'Monitor';
            app.MonitorPanel.Layout.Row = [1 2];
            app.MonitorPanel.Layout.Column = 4;

            % Create DBDTree
            app.DBDTree = uitree(app.GridLayoutDBD, 'checkbox');
            app.DBDTree.Layout.Row = [1 2];
            app.DBDTree.Layout.Column = 2;

            % Assign Checked Nodes
            app.DBDTree.CheckedNodesChangedFcn = createCallbackFcn(app, @DBDTreeCheckedNodesChanged, true);

            % Create DBDVoltageSliderPanel
            app.DBDVoltageSliderPanel = uipanel(app.GridLayoutDBD);
            app.DBDVoltageSliderPanel.Title = 'Voltage';
            app.DBDVoltageSliderPanel.Layout.Row = 1;
            app.DBDVoltageSliderPanel.Layout.Column = 3;

            % Create GridLayoutDBDVoltageSliderPanel
            app.GridLayoutDBDVoltageSliderPanel = uigridlayout(app.DBDVoltageSliderPanel);
            app.GridLayoutDBDVoltageSliderPanel.ColumnWidth = {'1x'};
            app.GridLayoutDBDVoltageSliderPanel.RowHeight = {'1x'};

            % Create VoltageSlider
            app.VoltageSlider = uislider(app.GridLayoutDBDVoltageSliderPanel);
            app.VoltageSlider.Limits = [0 4];
            app.VoltageSlider.Orientation = 'vertical';
            app.VoltageSlider.ValueChangedFcn = createCallbackFcn(app, @VoltageSliderValueChanged, true);
            app.VoltageSlider.Layout.Row = 1;
            app.VoltageSlider.Layout.Column = 1;

            % Create DBDFrequencySliderPanel
            app.DBDFrequencySliderPanel = uipanel(app.GridLayoutDBD);
            app.DBDFrequencySliderPanel.Title = 'Frequency';
            app.DBDFrequencySliderPanel.Layout.Row = 2;
            app.DBDFrequencySliderPanel.Layout.Column = 3;

            % Create GridLayoutDBDFrequencySliderPanel
            app.GridLayoutDBDFrequencySliderPanel = uigridlayout(app.DBDFrequencySliderPanel);
            app.GridLayoutDBDFrequencySliderPanel.ColumnWidth = {'1x'};
            app.GridLayoutDBDFrequencySliderPanel.RowHeight = {'1x'};

            % Create FrequencySlider
            app.FrequencySlider = uislider(app.GridLayoutDBDFrequencySliderPanel);
            app.FrequencySlider.Limits = [50 90];
            app.FrequencySlider.Orientation = 'vertical';
            app.FrequencySlider.ValueChangedFcn = createCallbackFcn(app, @FrequencySliderValueChanged, true);
            app.FrequencySlider.Layout.Row = 1;
            app.FrequencySlider.Layout.Column = 1;
            app.FrequencySlider.Value = 60;

            % Create OPTTab
            app.OPTTab = uitab(app.TabGroup);
            app.OPTTab.Title = 'OPT';

            % Create GridLayoutOPT
            app.GridLayoutOPT = uigridlayout(app.OPTTab);
            app.GridLayoutOPT.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayoutOPT.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create OPTPreviewPanel
            app.OPTPreviewPanel = uipanel(app.GridLayoutOPT);
            app.OPTPreviewPanel.Title = 'Preview';
            app.OPTPreviewPanel.Layout.Row = [1 10];
            app.OPTPreviewPanel.Layout.Column = [5 8];

            % Create OPTResultsPanel
            app.OPTResultsPanel = uipanel(app.GridLayoutOPT);
            app.OPTResultsPanel.Title = 'Results';
            app.OPTResultsPanel.Layout.Row = [7 10];
            app.OPTResultsPanel.Layout.Column = [1 4];

            % Create GridLayoutOPTResultsPanel
            app.GridLayoutOPTResultsPanel = uigridlayout(app.OPTResultsPanel);
            app.GridLayoutOPTResultsPanel.ColumnWidth = {'1x'};
            app.GridLayoutOPTResultsPanel.RowHeight = {'1x'};

            % Create OPTResultsUITable
            app.OPTResultsUITable = uitable(app.GridLayoutOPTResultsPanel);
            app.OPTResultsUITable.ColumnName = '';
            app.OPTResultsUITable.SelectionType = 'row';
            app.OPTResultsUITable.CellSelectionCallback = createCallbackFcn(app, @OPTResultsUITableCellSelection, true);
            app.OPTResultsUITable.DoubleClickedFcn = createCallbackFcn(app, @OPTResultsUITableDoubleClicked, true);
            app.OPTResultsUITable.Layout.Row = 1;
            app.OPTResultsUITable.Layout.Column = 1;

            % Create OPTSettingsPanel
            app.OPTSettingsPanel = uipanel(app.GridLayoutOPT);
            app.OPTSettingsPanel.Title = 'Settings';
            app.OPTSettingsPanel.Layout.Row = [1 5];
            app.OPTSettingsPanel.Layout.Column = [1 3];

            % Create GridLayoutOPTSettingsPanel
            app.GridLayoutOPTSettingsPanel = uigridlayout(app.OPTSettingsPanel);
            app.GridLayoutOPTSettingsPanel.ColumnWidth = {'1x'};
            app.GridLayoutOPTSettingsPanel.RowHeight = {'1x'};

            % Create OPTSettingsUITable
            app.OPTSettingsUITable = uitable(app.GridLayoutOPTSettingsPanel);
            app.OPTSettingsUITable.ColumnName = '';
            app.OPTSettingsUITable.RowName = {};
            app.OPTSettingsUITable.CellEditCallback = createCallbackFcn(app, @OPTSettingsUITableCellEdit, true);
            app.OPTSettingsUITable.CellSelectionCallback = createCallbackFcn(app, @OPTSettingsUITableCellSelection, true);
            app.OPTSettingsUITable.Layout.Row = 1;
            app.OPTSettingsUITable.Layout.Column = 1;

            % Create OPTActionsPanel
            app.OPTActionsPanel = uipanel(app.GridLayoutOPT);
            app.OPTActionsPanel.Title = 'Actions';
            app.OPTActionsPanel.Layout.Row = 6;
            app.OPTActionsPanel.Layout.Column = [1 3];

            % Create GridLayoutOPTActionsPanel
            app.GridLayoutOPTActionsPanel = uigridlayout(app.OPTActionsPanel);
            app.GridLayoutOPTActionsPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayoutOPTActionsPanel.RowHeight = {'1x'};

            % Create OPTSaveButton
            app.OPTSaveButton = uibutton(app.GridLayoutOPTActionsPanel, 'state');
            app.OPTSaveButton.ValueChangedFcn = createCallbackFcn(app, @OPTSaveButtonValueChanged, true);
            app.OPTSaveButton.Text = 'Save';
            app.OPTSaveButton.Layout.Row = 1;
            app.OPTSaveButton.Layout.Column = 3;

            % Create OPTStartButton
            app.OPTStartButton = uibutton(app.GridLayoutOPTActionsPanel, 'state');
            app.OPTStartButton.ValueChangedFcn = createCallbackFcn(app, @OPTStartButtonValueChanged, true);
            app.OPTStartButton.Text = 'Start';
            app.OPTStartButton.Layout.Row = 1;
            app.OPTStartButton.Layout.Column = 1;

            % Create OPTLoadButton
            app.OPTLoadButton = uibutton(app.GridLayoutOPTActionsPanel, 'state');
            app.OPTLoadButton.ValueChangedFcn = createCallbackFcn(app, @OPTLoadButtonValueChanged, true);
            app.OPTLoadButton.Text = 'Load';
            app.OPTLoadButton.Layout.Row = 1;
            app.OPTLoadButton.Layout.Column = 4;

            % Create OPTCancelButton
            app.OPTCancelButton = uibutton(app.GridLayoutOPTActionsPanel, 'state');
            app.OPTCancelButton.ValueChangedFcn = createCallbackFcn(app, @OPTCancelButtonValueChanged, true);
            app.OPTCancelButton.Text = 'Cancel';
            app.OPTCancelButton.Layout.Row = 1;
            app.OPTCancelButton.Layout.Column = 2;

            % Create OPTTree
            app.OPTTree = uitree(app.GridLayoutOPT, 'checkbox');
            app.OPTTree.Layout.Row = [1 6];
            app.OPTTree.Layout.Column = 4;

            % Assign Checked Nodes
            app.OPTTree.CheckedNodesChangedFcn = createCallbackFcn(app, @OPTTreeCheckedNodesChanged, true);

            % Create MESTab
            app.MESTab = uitab(app.TabGroup);
            app.MESTab.Title = 'MES';

            % Create GridLayoutMES
            app.GridLayoutMES = uigridlayout(app.MESTab);
            app.GridLayoutMES.ColumnWidth = {'0.5x', '1x'};

            % Create MESSettingsPanel
            app.MESSettingsPanel = uipanel(app.GridLayoutMES);
            app.MESSettingsPanel.Title = 'Settings';
            app.MESSettingsPanel.Layout.Row = 1;
            app.MESSettingsPanel.Layout.Column = 1;

            % Create GridLayoutMESSettingsPanel
            app.GridLayoutMESSettingsPanel = uigridlayout(app.MESSettingsPanel);
            app.GridLayoutMESSettingsPanel.ColumnWidth = {'1x'};
            app.GridLayoutMESSettingsPanel.RowHeight = {'1x'};

            % Create MESSettingsUITable
            app.MESSettingsUITable = uitable(app.GridLayoutMESSettingsPanel);
            app.MESSettingsUITable.ColumnName = '';
            app.MESSettingsUITable.RowName = {};
            app.MESSettingsUITable.CellEditCallback = createCallbackFcn(app, @MESSettingsUITableCellEdit, true);
            app.MESSettingsUITable.Layout.Row = 1;
            app.MESSettingsUITable.Layout.Column = 1;

            % Create MESActionsPanel
            app.MESActionsPanel = uipanel(app.GridLayoutMES);
            app.MESActionsPanel.Title = 'Actions';
            app.MESActionsPanel.Layout.Row = 2;
            app.MESActionsPanel.Layout.Column = 1;

            % Create GridLayoutMESActionsPanel
            app.GridLayoutMESActionsPanel = uigridlayout(app.MESActionsPanel);
            app.GridLayoutMESActionsPanel.ColumnWidth = {'1x'};
            app.GridLayoutMESActionsPanel.RowHeight = {'1x', '1x', '1x', '1x'};

            % Create MESStartButton
            app.MESStartButton = uibutton(app.GridLayoutMESActionsPanel, 'state');
            app.MESStartButton.ValueChangedFcn = createCallbackFcn(app, @MESStartButtonValueChanged, true);
            app.MESStartButton.Text = 'Start';
            app.MESStartButton.Layout.Row = 1;
            app.MESStartButton.Layout.Column = 1;

            % Create MESStopButton
            app.MESStopButton = uibutton(app.GridLayoutMESActionsPanel, 'state');
            app.MESStopButton.ValueChangedFcn = createCallbackFcn(app, @MESStopButtonValueChanged, true);
            app.MESStopButton.Text = 'Stop';
            app.MESStopButton.Layout.Row = 2;
            app.MESStopButton.Layout.Column = 1;

            % Create MESSaveButton
            app.MESSaveButton = uibutton(app.GridLayoutMESActionsPanel, 'state');
            app.MESSaveButton.ValueChangedFcn = createCallbackFcn(app, @MESSaveButtonValueChanged, true);
            app.MESSaveButton.Text = 'Save';
            app.MESSaveButton.Layout.Row = 4;
            app.MESSaveButton.Layout.Column = 1;

            % Create MESLoadButton
            app.MESLoadButton = uibutton(app.GridLayoutMESActionsPanel, 'state');
            app.MESLoadButton.ValueChangedFcn = createCallbackFcn(app, @MESLoadButtonValueChanged, true);
            app.MESLoadButton.Text = 'Load';
            app.MESLoadButton.Layout.Row = 3;
            app.MESLoadButton.Layout.Column = 1;

            % Create MESScanPanel
            app.MESScanPanel = uipanel(app.GridLayoutMES);
            app.MESScanPanel.Title = 'Panel';
            app.MESScanPanel.Layout.Row = [1 2];
            app.MESScanPanel.Layout.Column = 2;

            % Create GridLayoutMESScanPanel
            app.GridLayoutMESScanPanel = uigridlayout(app.MESScanPanel);
            app.GridLayoutMESScanPanel.ColumnWidth = {'1x'};
            app.GridLayoutMESScanPanel.RowHeight = {'1x'};

            % Create MESScanUITable
            app.MESScanUITable = uitable(app.GridLayoutMESScanPanel);
            app.MESScanUITable.ColumnName = '';
            app.MESScanUITable.SelectionType = 'row';
            app.MESScanUITable.CellEditCallback = createCallbackFcn(app, @MESScanUITableCellEdit, true);
            app.MESScanUITable.CellSelectionCallback = createCallbackFcn(app, @MESScanUITableCellSelection, true);
            app.MESScanUITable.Layout.Row = 1;
            app.MESScanUITable.Layout.Column = 1;

            % Create SMTab
            app.SMTab = uitab(app.TabGroup);
            app.SMTab.Title = 'SM';

            % Create GridLayoutSM
            app.GridLayoutSM = uigridlayout(app.SMTab);

            % Create SeedingPanel
            app.SeedingPanel = uipanel(app.GridLayoutSM);
            app.SeedingPanel.Title = 'Seeding';
            app.SeedingPanel.Layout.Row = 1;
            app.SeedingPanel.Layout.Column = 2;

            % Create GridLayoutSMSeedingPanel
            app.GridLayoutSMSeedingPanel = uigridlayout(app.SeedingPanel);
            app.GridLayoutSMSeedingPanel.ColumnWidth = {'1x'};
            app.GridLayoutSMSeedingPanel.RowHeight = {'1x', '0.2x', '0.2x'};

            % Create SwitchGateButton
            app.SwitchGateButton = uibutton(app.GridLayoutSMSeedingPanel, 'state');
            app.SwitchGateButton.ValueChangedFcn = createCallbackFcn(app, @SwitchGateButtonValueChanged, true);
            app.SwitchGateButton.Text = 'Switch Gate';
            app.SwitchGateButton.Layout.Row = 3;
            app.SwitchGateButton.Layout.Column = 1;

            % Create InitializeButton
            app.InitializeButton = uibutton(app.GridLayoutSMSeedingPanel, 'push');
            app.InitializeButton.ButtonPushedFcn = createCallbackFcn(app, @InitializeButtonPushed, true);
            app.InitializeButton.Layout.Row = 2;
            app.InitializeButton.Layout.Column = 1;
            app.InitializeButton.Text = 'Initialize';

            % Create SeedingParametersUITable
            app.SeedingParametersUITable = uitable(app.GridLayoutSMSeedingPanel);
            app.SeedingParametersUITable.ColumnName = '';
            app.SeedingParametersUITable.RowName = {};
            app.SeedingParametersUITable.CellEditCallback = createCallbackFcn(app, @SeedingParametersUITableCellEdit, true);
            app.SeedingParametersUITable.Layout.Row = 1;
            app.SeedingParametersUITable.Layout.Column = 1;

            % Create StepMotorsPanel
            app.StepMotorsPanel = uipanel(app.GridLayoutSM);
            app.StepMotorsPanel.Title = 'Step Motors';
            app.StepMotorsPanel.Layout.Row = 1;
            app.StepMotorsPanel.Layout.Column = 1;

            % Create GridLayoutSMD
            app.GridLayoutSMD = uigridlayout(app.StepMotorsPanel);
            app.GridLayoutSMD.ColumnWidth = {'1x', '0.5x'};
            app.GridLayoutSMD.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create SMLOCUITable
            app.SMLOCUITable = uitable(app.GridLayoutSMD);
            app.SMLOCUITable.ColumnName = '';
            app.SMLOCUITable.RowName = {};
            app.SMLOCUITable.CellEditCallback = createCallbackFcn(app, @SMLOCUITableCellEdit, true);
            app.SMLOCUITable.Layout.Row = [1 7];
            app.SMLOCUITable.Layout.Column = 1;

            % Create SMMoveButton
            app.SMMoveButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMMoveButton.ValueChangedFcn = createCallbackFcn(app, @SMMoveButtonValueChanged, true);
            app.SMMoveButton.Text = 'Move';
            app.SMMoveButton.Layout.Row = 4;
            app.SMMoveButton.Layout.Column = 2;

            % Create SMStopButton
            app.SMStopButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMStopButton.Enable = 'off';
            app.SMStopButton.Text = 'Stop';
            app.SMStopButton.Layout.Row = 6;
            app.SMStopButton.Layout.Column = 2;

            % Create SMShiftButton
            app.SMShiftButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMShiftButton.Enable = 'off';
            app.SMShiftButton.Text = 'Shift';
            app.SMShiftButton.Layout.Row = 5;
            app.SMShiftButton.Layout.Column = 2;

            % Create SMZeroButton
            app.SMZeroButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMZeroButton.Enable = 'off';
            app.SMZeroButton.Text = 'Zero';
            app.SMZeroButton.Layout.Row = 2;
            app.SMZeroButton.Layout.Column = 2;

            % Create SMHomeButton
            app.SMHomeButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMHomeButton.ValueChangedFcn = createCallbackFcn(app, @SMHomeButtonValueChanged, true);
            app.SMHomeButton.Text = 'Home';
            app.SMHomeButton.Layout.Row = 3;
            app.SMHomeButton.Layout.Column = 2;

            % Create SMStatusButton
            app.SMStatusButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMStatusButton.ValueChangedFcn = createCallbackFcn(app, @SMStatusButtonValueChanged, true);
            app.SMStatusButton.Text = 'Status';
            app.SMStatusButton.Layout.Row = 1;
            app.SMStatusButton.Layout.Column = 2;

            % Create SMInitializeButton
            app.SMInitializeButton = uibutton(app.GridLayoutSMD, 'state');
            app.SMInitializeButton.ValueChangedFcn = createCallbackFcn(app, @SMInitializeButtonValueChanged, true);
            app.SMInitializeButton.Text = 'Initialize';
            app.SMInitializeButton.Layout.Row = 7;
            app.SMInitializeButton.Layout.Column = 2;

            % Create MESScanContextMenu
            app.MESScanContextMenu = uicontextmenu(app.UIFigure);

            % Create AddMenu
            app.AddMenu = uimenu(app.MESScanContextMenu);
            app.AddMenu.MenuSelectedFcn = createCallbackFcn(app, @AddMenuSelected, true);
            app.AddMenu.Text = 'Add';

            % Create ClearMenu
            app.ClearMenu = uimenu(app.MESScanContextMenu);
            app.ClearMenu.MenuSelectedFcn = createCallbackFcn(app, @ClearMenuSelected, true);
            app.ClearMenu.Text = 'Clear';

            % Create DeleteMenu
            app.DeleteMenu = uimenu(app.MESScanContextMenu);
            app.DeleteMenu.MenuSelectedFcn = createCallbackFcn(app, @DeleteMenuSelected, true);
            app.DeleteMenu.Text = 'Delete';

            % Create CopyMenu
            app.CopyMenu = uimenu(app.MESScanContextMenu);
            app.CopyMenu.MenuSelectedFcn = createCallbackFcn(app, @CopyMenuSelected, true);
            app.CopyMenu.Text = 'Copy';

            % Create PasteMenu
            app.PasteMenu = uimenu(app.MESScanContextMenu);
            app.PasteMenu.MenuSelectedFcn = createCallbackFcn(app, @PasteMenuSelected, true);
            app.PasteMenu.Text = 'Paste';
            
            % Assign app.MESScanContextMenu
            app.MESScanUITable.ContextMenu = app.MESScanContextMenu;

            % Create OPTResultsContextMenu
            app.OPTResultsContextMenu = uicontextmenu(app.UIFigure);
            app.OPTResultsContextMenu.ContextMenuOpeningFcn = createCallbackFcn(app, @OPTResultsContextMenuOpening, true);

            % Create OPTResultsCopyMenu
            app.OPTResultsCopyMenu = uimenu(app.OPTResultsContextMenu);
            app.OPTResultsCopyMenu.MenuSelectedFcn = createCallbackFcn(app, @OPTResultsCopyMenuSelected, true);
            app.OPTResultsCopyMenu.Text = 'Copy';
            
            % Assign app.OPTResultsContextMenu
            app.OPTResultsUITable.ContextMenu = app.OPTResultsContextMenu;

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create DefaultMenu
            app.DefaultMenu = uimenu(app.ContextMenu);
            app.DefaultMenu.MenuSelectedFcn = createCallbackFcn(app, @DefaultMenuMenuSelected, true);
            app.DefaultMenu.Text = 'Default';

            % Create ChangeviewMenu
            app.ChangeviewMenu = uimenu(app.ContextMenu);
            app.ChangeviewMenu.Text = 'Change view';

            % Create OPTParametersContextMenu
            app.OPTParametersContextMenu = uicontextmenu(app.UIFigure);

            % Create PasteMenuOPT
            app.PasteMenuOPT = uimenu(app.OPTParametersContextMenu);
            app.PasteMenuOPT.MenuSelectedFcn = createCallbackFcn(app, @PasteMenuOPTSelected, true);
            app.PasteMenuOPT.Text = 'Paste';
            
            % Assign app.OPTParametersContextMenu
            app.OPTSettingsUITable.ContextMenu = app.OPTParametersContextMenu;

            % Create DBDParamContextMenu
            app.DBDParamContextMenu = uicontextmenu(app.UIFigure);

            % Create DBDParamPasteMenu
            app.DBDParamPasteMenu = uimenu(app.DBDParamContextMenu);
            app.DBDParamPasteMenu.MenuSelectedFcn = createCallbackFcn(app, @DBDParamPasteMenuSelected, true);
            app.DBDParamPasteMenu.Text = 'Paste';
            
            % Assign app.DBDParamContextMenu
            app.DBDParametersTable.ContextMenu = app.DBDParamContextMenu;

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