classdef dbd < matlab.apps.AppBase
%   DBD class aims to communicate MCU (ESP32) by means UDP socket and HTTP requesting and 
%   contains GUI implementation to adjust sending and requesting voltage and frequency vectors.

    properties (Access = public)
        % define UI properties
        MainGridLayout          matlab.ui.container.GridLayout

        ManualPanel             matlab.ui.container.Panel
        ManualGridLayout        matlab.ui.container.GridLayout
        ManualUITable           matlab.ui.control.Table

        ActionPanel             matlab.ui.container.Panel
        ActionGridLayout        matlab.ui.container.GridLayout
        SendActionButton        matlab.ui.control.StateButton
        RequestActionButton     matlab.ui.control.StateButton
        StopActionButton        matlab.ui.control.StateButton

        SelectorTree            matlab.ui.container.CheckBoxTree

        VoltagePanel            matlab.ui.container.Panel
        VoltageGridLayout       matlab.ui.container.GridLayout
        VoltageSlider           matlab.ui.control.Slider

        FrequencyPanel          matlab.ui.container.Panel
        FrequencyGridLayout     matlab.ui.container.GridLayout
        FrequencySlider         matlab.ui.control.Slider

        MonitorPanel            matlab.ui.container.Panel
        
        % define specific properties
        parent_ui % to put there all UI objects of present class

        % define default fields of parameter table
        tab_param = struct('voltage_value', 2*ones(1, 16), 'voltage_index', 0:15, ...
            'frequency_value', [74,70,70,70,65,68,59,65,65,63,64,62,66,65,68,65], 'frequency_index', 0:15, ...
            'mode', categorical({'all'}, {'all'; 'voltage'; 'frequency'}));
        tab_param_def;

        % slider supports
        voltage_input_state = true;
        frequency_input_state = true;
        voltage_slider_index;
        frequency_slider_index;

        % send and listen for data between client and workers
        queue_pool = struct();

        % declaration of net configuration MCU (ESP32)
        url_set_param = 'http://192.168.1.1:8090/set-param'
        url_get_param = 'http://192.168.1.1:8090/get-param'
        udp_ip = '192.168.1.1'
        udp_port = 8080
        
    end

    methods
        function obj = dbd(parent_ui, queue_pool)
            % assign arguments
            obj.parent_ui = parent_ui;
            obj.queue_pool.log = queue_pool.log;
            obj.queue_pool.disp = queue_pool.disp;

            % build content
            obj.create_components();
            obj.init_components();
        end

        %% Supporting functnios

        % Define functnion to request via HTTP GET a JSON packet
        function data = receive_http(obj)
            % OPTPUT
            %   data - received data struct
            data = [];
            try
                request = matlab.net.http.RequestMessage;
                response = request.send(obj.url_get_param);
                data = response.Body.Data;
                send(obj.queue_pool.log, strcat("DBD: http receive request: ", jsonencode(data)))
            catch
                send(obj.queue_pool.log, 'DBD: http receive request is failed')
            end
        end

        % Define functnion to send via HTTP POST a JSON packet
        function state = send_http(obj, type, value ,index)
            % INPUT:
            %   type - string asign selector: 'dac' send packet to DACs, 'fm' send packet to FGs 
            %   value - sending double value array; for 'dac' range is 0-4[V], for 'fm' range is 0-160[kHz]
            %   index - sending integer value array in range 0-15
            % OPTPUT
            %   state - bool success requesting
            state = false;
            try
                parameters = struct();
                if (size(value, 1) == 1) && (size(value, 2) == 1)
                    parameters.(type).value = {value};
                    parameters.(type).index = {index};     
                else
                    parameters.(type).value = value;
                    parameters.(type).index = index;   
                end
                message = jsonencode(parameters);
                request = matlab.net.http.RequestMessage('POST', [matlab.net.http.field.ContentTypeField('application/json'), ...
                    matlab.net.http.field.AcceptField('application/json')], message);
                response = request.send(obj.url_set_param);
                state = true;
                send(obj.queue_pool.log, strcat("DBD: http send request: ", message))
            catch
                send(obj.queue_pool.log, 'DBD: http send request is failed')
            end
        end

        % Define functnion to send via UDP socket a JSON packet
        function send_udp(obj, type, value, index)
            % INPUT:
            %   type - string asign selector: 'dac' send packet to DACs, 'fm' send packet to FGs 
            %   value - sending double value array; for 'dac' range is 0-4[V], for 'fm' range is 0-160[kHz]
            %   index - sending integer value array in range 0-15
            try
                parameters = struct();
                if (size(value, 1) == 1) && (size(value, 2) == 1)
                    parameters.(type).value = {value};
                    parameters.(type).index = {index};  
                else
                    parameters.(type).value = value;
                    parameters.(type).index = index;   
                end         
                message = jsonencode(parameters);
                udp_socket = udpport;
                write(udp_socket, message, 'string', obj.udp_ip, obj.udp_port);
                send(obj.queue_pool.log, strcat("DBD: send socket-UDP packet: ", message))
            catch
                send(obj.queue_pool.log, 'DBD: send socket-UDP packet is failed')
            end
        end

        % Define initialization of tree checkbox UI to fast adjusting voltage and frequency vectors
        function monitor_plot(obj)
            ax = obj.MonitorPanel; axs = [subplot(2, 1, 1, 'Parent', ax), subplot(2, 1, 2, 'Parent', ax)];              
            cla(axs(1)); hold(axs(1), 'on'); box(axs(1), 'on'); grid(axs(1), 'on'); 
            bar(axs(1), obj.tab_param.voltage_index, obj.tab_param.voltage_value, 'FaceColor', '#0072BD'); xticks(axs(1), obj.tab_param.voltage_index);
            cla(axs(2)); hold(axs(2), 'on'); box(axs(2), 'on'); grid(axs(2), 'on'); 
            bar(axs(2), obj.tab_param.frequency_index, obj.tab_param.frequency_value, 'FaceColor', '#77AC30'); xticks(axs(2), obj.tab_param.frequency_index); 
            ylim(axs(2), [50, 90])
        end

        % Define initialization of UI three checkbox to fast adjusting voltage and frequency vectors
        function init_tree(obj)
            voltage_sibling = uitreenode(obj.SelectorTree, 'Text', 'Voltage');
            frequency_sibling = uitreenode(obj.SelectorTree, 'Text', 'Frequency');
            for i = 0:15
                uitreenode(voltage_sibling, 'Text', num2str(i));
                uitreenode(frequency_sibling, 'Text', num2str(i));
            end
            expand(obj.SelectorTree);
        end

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
        
        % Define a function of table reading
        function read_tab_param(obj, tab_struct, tab_obj)
            % INPUT:
            %   tab_struct - string name of structure that fields are assigned as first column of table, value - second column;
            %   tab_obj - string name of table UI object;
            try
                for index = 1:size(obj.(tab_obj).Data.labels, 1)
                    label = string(obj.(tab_obj).Data.labels(index));
                    value = obj.(tab_obj).Data.values(index); value = value{1};
                    if isa(value, 'categorical')                
                        obj.(tab_struct).(label) = value;
                    end
                    if isa(value, 'char')
                        obj.(tab_struct).(label) = jsondecode(value);
                    end
                end
            catch
            end
        end

         % Define a function of table cell reading
        function update_tab_param(obj, tab_struct, tab_obj, index)
            % INPUT:
            %   tab_struct - string name of structure that fields are assigned as first column of table, value - second column;
            %   tab_obj - string name of table UI object;
            %   index - number changed table row
            label = string(obj.(tab_obj).Data.labels(index));
            value = obj.(tab_obj).Data.values(index); value = value{1};
            try
                if isa(value, 'categorical')                
                    obj.(tab_struct).(label) = value;
                end
                if isa(value, 'char')
                    obj.(tab_struct).(label) = jsondecode(value);
                end
            catch
            end
        end

        %% UI appearance and its behaviour

        % Create components
        function create_components(obj)

            % Create MainGridLayout
            obj.MainGridLayout = uigridlayout(obj.parent_ui);
            obj.MainGridLayout.ColumnWidth = {'1x', '0.5x', '0.5x', '1x'};
            obj.MainGridLayout.RowHeight = {'1x', '1x'};

            % Create ManualPanelPanel
            obj.ManualPanel = uipanel(obj.MainGridLayout);
            obj.ManualPanel.Title = 'Manual';
            obj.ManualPanel.Layout.Row = [1 2];
            obj.ManualPanel.Layout.Column = 1;

            % Create ManualGridLayout
            obj.ManualGridLayout = uigridlayout(obj.ManualPanel);
            obj.ManualGridLayout.ColumnWidth = {'1x'};
            obj.ManualGridLayout.RowHeight = {'1x', '0.35x'};

            % Create ManualUITable
            obj.ManualUITable = uitable(obj.ManualGridLayout);
            obj.ManualUITable.ColumnName = '';
            obj.ManualUITable.RowName = {};
            obj.ManualUITable.Layout.Row = 1;
            obj.ManualUITable.Layout.Column = 1;
            obj.ManualUITable.CellEditCallback = createCallbackFcn(obj, ...
                @(src, event) obj.update_tab_param('tab_param', 'ManualUITable', event.Indices(1)), true);

            % Create ActionPanel
            obj.ActionPanel = uipanel(obj.ManualGridLayout);
            obj.ActionPanel.Title = 'Manual';
            obj.ActionPanel.Layout.Row = 2;
            obj.ActionPanel.Layout.Column = 1;

            % Create ActionGridLayout
            obj.ActionGridLayout = uigridlayout(obj.ActionPanel);
            obj.ActionGridLayout.ColumnWidth = {'1x', '1x', '1x'};
            obj.ActionGridLayout.RowHeight = {'1x'};

            % Create SendActionButton
            obj.SendActionButton = uibutton(obj.ActionGridLayout, 'state');
            obj.SendActionButton.Text = 'Send';
            obj.SendActionButton.Layout.Row = 1;
            obj.SendActionButton.Layout.Column = 1;
            obj.SendActionButton.ValueChangedFcn = createCallbackFcn(obj, @SendActionButtonValueChanged, true);

            % Create RequestActionButton
            obj.RequestActionButton = uibutton(obj.ActionGridLayout, 'state');
            obj.RequestActionButton.Text = 'Request';
            obj.RequestActionButton.Layout.Row = 1;
            obj.RequestActionButton.Layout.Column = 2;
            obj.RequestActionButton.ValueChangedFcn = createCallbackFcn(obj, @RequestActionButtonValueChanged, true);

            % Create StopActionButton
            obj.StopActionButton = uibutton(obj.ActionGridLayout, 'state');
            obj.StopActionButton.Text = 'Stop';
            obj.StopActionButton.Layout.Row = 1;
            obj.StopActionButton.Layout.Column = 3;
            obj.StopActionButton.ValueChangedFcn = createCallbackFcn(obj, @StopActionButtonValueChanged, true);

            % Create SelectorTree
            obj.SelectorTree = uitree(obj.MainGridLayout, 'checkbox');
            obj.SelectorTree.Layout.Row = [1 2];
            obj.SelectorTree.Layout.Column = 2;
            obj.SelectorTree.CheckedNodesChangedFcn = createCallbackFcn(obj, @SelectorTreeCheckedNodesChanged, true);

            % Create VoltagePanel
            obj.VoltagePanel = uipanel(obj.MainGridLayout);
            obj.VoltagePanel.Title = 'Voltage';
            obj.VoltagePanel.Layout.Row = 1;
            obj.VoltagePanel.Layout.Column = 3;

            % Create VoltageGridLayout
            obj.VoltageGridLayout = uigridlayout(obj.VoltagePanel);
            obj.VoltageGridLayout.ColumnWidth = {'1x'};
            obj.VoltageGridLayout.RowHeight = {'1x'};

            % Create VoltageSlider
            obj.VoltageSlider = uislider(obj.VoltageGridLayout);
            obj.VoltageSlider.Limits = [0 4000];
            obj.VoltageSlider.Orientation = 'vertical';
            obj.VoltageSlider.Layout.Row = 1;
            obj.VoltageSlider.Layout.Column = 1;
            obj.VoltageSlider.ValueChangedFcn = createCallbackFcn(obj, @VoltageSliderValueChanged, true);

            % Create VoltagePanel
            obj.FrequencyPanel = uipanel(obj.MainGridLayout);
            obj.FrequencyPanel.Title = 'Voltage';
            obj.FrequencyPanel.Layout.Row = 2;
            obj.FrequencyPanel.Layout.Column = 3;

            % Create VoltageGridLayout
            obj.FrequencyGridLayout = uigridlayout(obj.FrequencyPanel);
            obj.FrequencyGridLayout.ColumnWidth = {'1x'};
            obj.FrequencyGridLayout.RowHeight = {'1x'};

            % Create VoltageSlider
            obj.FrequencySlider = uislider(obj.FrequencyGridLayout);
            obj.FrequencySlider.Limits = [0, 160];
            obj.FrequencySlider.Orientation = 'vertical';
            obj.FrequencySlider.Layout.Row = 1;
            obj.FrequencySlider.Layout.Column = 1;
            obj.FrequencySlider.ValueChangedFcn = createCallbackFcn(obj, @FrequencySliderValueChanged, true);

            % Create MonitorPanel
            obj.MonitorPanel = uipanel(obj.MainGridLayout);
            obj.MonitorPanel.Title = 'Manual';
            obj.MonitorPanel.Layout.Row = [1 2];
            obj.MonitorPanel.Layout.Column = 4;

        end

        % Initialize components
        function init_components(obj)

            obj.MonitorPanel.AutoResizeChildren = 'off';
            obj.init_tree();
            obj.monitor_plot();

            obj.tab_param_def = obj.tab_param;
            obj.init_tab_param(obj.tab_param, obj.ManualUITable)
            
        end

        %% Define callbacks

        % Value changed function: SendActionButton
        function SendActionButtonValueChanged(obj, event)
            try
                send(obj.queue_pool.log, 'DBD: call send button')
                obj.read_tab_param('tab_param', 'ManualUITable');
                switch obj.tab_param.mode
                    case 'voltage'
                        obj.send_udp('dac', obj.tab_param.voltage_value, obj.tab_param.voltage_index);
                    case 'frequency'
                        obj.send_udp('fm', obj.tab_param.frequency_value, obj.tab_param.frequency_index);
                    case 'all'
                        obj.send_udp('dac', obj.tab_param.voltage_value, obj.tab_param.voltage_index);
                        obj.send_udp('fm', obj.tab_param.frequency_value, obj.tab_param.frequency_index);
                end
                obj.monitor_plot();
                obj.SendActionButton.Value = false;
            catch                
            end
        end

        % Value changed function: RequestActionButton
        function RequestActionButtonValueChanged(obj, event)
            data = obj.receive_http();
            if ~(isempty(data))
                obj.tab_param.voltage_value = data.dac.value;
                obj.tab_param.frequency_value = data.fm.value;
                obj.monitor_plot();
            end
            obj.RequestActionButton.Value = false;
        end

        % Value changed function: StopActionButton
        function StopActionButtonValueChanged(obj, event)
            obj.tab_param.voltage_value = zeros(1, 16);
            obj.tab_param.voltage_index = 0:15;
            obj.send_udp('dac', obj.tab_param.voltage_value, obj.tab_param.voltage_index);
            obj.StopActionButton.Value = false;
            obj.monitor_plot();
            send(obj.queue_pool.log, 'DBD: call stop button')
        end

        % Callback function: SelectorTree
        function SelectorTreeCheckedNodesChanged(obj, event)
            checkedNodes = event.CheckedNodes;
            obj.voltage_slider_index = [];
            obj.frequency_slider_index = [];
            for i = 1:size(checkedNodes, 1)        
                if ~isprop(checkedNodes(i).Parent, 'CheckedNodes')
                    switch checkedNodes(i).Parent.Text
                        case 'Voltage'
                            obj.voltage_slider_index = [obj.voltage_slider_index, str2num(checkedNodes(i).Text)];
                        case 'Frequency'
                            obj.frequency_slider_index = [obj.frequency_slider_index, str2num(checkedNodes(i).Text)];
                    end
                end 
            end
        end

        % Value changed function: VoltageSlider
        function VoltageSliderValueChanged(obj, event)
            if ~isempty(obj.voltage_slider_index)
                obj.tab_param.voltage_value(obj.voltage_slider_index + 1) = round(obj.VoltageSlider.Value) .* ones(1, size(obj.voltage_slider_index, 2));
                obj.send_udp('dac', obj.tab_param.voltage_value, obj.tab_param.voltage_index);
                obj.monitor_plot();
            end
        end

        % Value changed function: FrequencySlider
        function FrequencySliderValueChanged(obj, event)
            if ~isempty(obj.frequency_slider_index)
                obj.tab_param.frequency_value(obj.frequency_slider_index + 1) = round(obj.FrequencySlider.Value) .* ones(1, size(obj.frequency_slider_index, 2));
                obj.send_udp('fm', obj.tab_param.frequency_value, obj.tab_param.frequency_index);
                obj.monitor_plot();
            end
        end

    end
end