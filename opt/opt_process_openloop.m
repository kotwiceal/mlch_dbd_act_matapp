function opt_process_openloop(app, problem)

    sz_ind = numel(app.opt_data_openloop.index);
    sz_vol = numel(app.opt_data_openloop.voltage);

    y = app.opt_data_openloop.output(:, 1);
    u = reshape(app.opt_data_openloop.input(:, 2:end), [], sz_vol - 1,  sz_ind);
    vmr = reshape(app.opt_data_openloop.output(:, 2:end), [], sz_vol - 1,  sz_ind);
    dvm = app.opt_data_openloop.output(:, 2:end) - app.opt_data_openloop.output(:, 1);
    dvmr = reshape(dvm, [], sz_vol - 1,  sz_ind);
    dvmr_rms = squeeze(rms(dvmr, 1, 'omitnan'));
    dvmr_n = permute(dvmr, [2, 3, 1]) ./ dvmr_rms; dvmr_n = permute(dvmr_n, [3, 1, 2]);
    dvmr_nm = squeeze(mean(dvmr_n, 2));
    P = dvmr_nm; 

    app.opt_data_openloop.y = y;
    app.opt_data_openloop.u = u;
    app.opt_data_openloop.vmr = vmr;
    app.opt_data_openloop.dvm = dvm;
    app.opt_data_openloop.dvmr = dvmr;
    app.opt_data_openloop.dvmr_rms = dvmr_rms;
    app.opt_data_openloop.dvmr_n = dvmr_n;
    app.opt_data_openloop.dvmr_nm = dvmr_nm;
    app.opt_data_openloop.P = P;

    problem.objective = @(u) problem.func_norm(y + P*u');
    problem.options = optimoptions('fmincon', 'Algorithm', char(app.opt_tab_param.method));
    [vector, value] = fmincon(problem);

    if size(app.opt_data_openloop.voltage, 2) > 1
        app.opt_data_openloop.voltage = app.opt_data_openloop.voltage';
    end

    if size(app.opt_data_openloop.index, 1) > 1
        app.opt_data_openloop.index = app.opt_data_openloop.index';
    end

    for i = 1:sz_ind
        rms_ft{i} = fit(dvmr_rms(:, i), app.opt_data_openloop.voltage(2:end), 'poly1');
        vector_calib(i) = round(rms_ft{i}(vector(i)));
    end

    fe = y+P*vector';
    e = rms(y+P*vector')/rms(y);

    app.opt_data_openloop.fe = fe;
    app.opt_data_openloop.e = e;
    app.opt_data_openloop.vector_calib = rms_ft{i};
    app.opt_data_openloop.vector_calib = vector_calib;
    app.opt_data_openloop.vector = vector;

    app.OPTResultsUITable.Data = [];
    app.OPTResultsUITable.ColumnName = split(strcat("Result ", num2str(app.opt_data_openloop.index)))';  
    app.OPTResultsUITable.Data = [table({'optimization'; 'calibration'}, 'VariableNames', {'Result'}), array2table([vector; vector_calib])];

    app.opt_data_openloop.tab_res = [table({'optimization'; 'calibration'}, 'VariableNames', {'Result'}), array2table([vector; vector_calib])];
    app.opt_data_openloop.tab_res.Properties.VariableNames = split(strcat("Result ", num2str(app.opt_data_openloop.index)))';

    app.log(strcat('OPT: optimization is completed: vec=', jsonencode(vector), '; val=', jsonencode(value)));
    app.log(strcat('OPT: account calibration: vec=', jsonencode(vector_calib)));

    app.OPTStartButton.Enable = 'on';
    app.OPTStartButton.Value = false;
    app.OPTTree.Enable = 'on';
    app.opt_init_tree();
end