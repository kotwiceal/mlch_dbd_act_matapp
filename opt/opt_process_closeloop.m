function opt_process_closeloop(problem, queueEventPool, queuePollableWorkerPool)
    arguments
        problem struct
        queueEventPool struct
        queuePollableWorkerPool struct
    end
    send(queueEventPool.logger, 'OPT: start optimization');

    % define objective function
    problem.objective = @(value) opt_obj_fcn(problem.func_norm, value, problem.index, queueEventPool, queuePollableWorkerPool);

    problem.objective(zeros(1, 16)); % evaluate the reference case
    [vector, value] = fmincon(problem);
    problem.objective(vector); % evaluate the optimal case

    send(queueEventPool.logger, strcat('OPT: optimization is completed: vec=', jsonencode(vector), '; val=', jsonencode(value)));
    send(queueEventPool.mcuHttpPost, jsonencode(struct('dac', struct('value', zeros(1, 16), 'index', 0:15))));
    send(queueEventPool.optComplete, struct(value = value, vector = vector));
end