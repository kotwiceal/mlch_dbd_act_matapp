classdef applab_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure     matlab.ui.Figure
        GridLayout   matlab.ui.container.GridLayout
        LogTextArea  matlab.ui.control.TextArea
        TabGroup     matlab.ui.container.TabGroup
        PIVTab       matlab.ui.container.Tab
        DBDTab       matlab.ui.container.Tab
    end

    
    properties (Access = private)
        module = struct() % to store imported modules;
        queue_pool = struct('log', parallel.pool.DataQueue, 'disp', parallel.pool.DataQueue) % to store queue pool
        pool % to store allocated pool
    end
    
    methods (Access = private)
        % define logger function
        function log(app, message)
            % INPUT:
            %       message - displayed string
            app.LogTextArea.Value = [app.LogTextArea.Value; strcat(string(datetime), " ", message)];
            scroll(app.LogTextArea, 'bottom');
        end

        function init_workers(app)
            % allocate pool
            app.poolobj = gcp('nocreate');
            if isempty(app.poolobj)
                app.pool = parpool(3);
            end

            % initialize functions to workers
            afterEach(app.queue_pool.log, @app.log)
            afterEach(app.queue_pool.disp, @disp)
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clc
            % initialize workers
            app.init_workers();
            
            % create piv interface section
            app.module.piv = piv(app.PIVTab, app.queue_pool);
            % create dbd interface section
            app.module.dbd = dbd(app.DBDTab, app.queue_pool);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % forced deleting TCP server instance
            try
                delete(app.module.piv.tcp_server)
            catch
            end
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1191 699];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x', '0.2x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create PIVTab
            app.PIVTab = uitab(app.TabGroup);
            app.PIVTab.Title = 'PIV';

            % Create DBDTab
            app.DBDTab = uitab(app.TabGroup);
            app.DBDTab.Title = 'DBD';

            % Create LogTextArea
            app.LogTextArea = uitextarea(app.GridLayout);
            app.LogTextArea.Layout.Row = 2;
            app.LogTextArea.Layout.Column = 1;

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