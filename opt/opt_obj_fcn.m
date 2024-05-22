function result = opt_obj_fcn(func_norm, value, index, seeding, queueEventPool, queuePollableWorkerPool)
    arguments
        func_norm function_handle
        value (1,:) double
        index (1,:) double
        seeding struct
        queueEventPool struct
        queuePollableWorkerPool struct
    end

    if seeding.auto
        send(queueEventPool.seedingWatcher, true);
        send(queueEventPool.logger, 'OPT: check seeding counter');
        [packet, state] = poll(queuePollableWorkerPool.seedingWatcher.Value, 0.5);
        if state
            if packet.state
                send(queueEventPool.mcuDisable, true);
                send(queueEventPool.logger, 'OPT: start flow seeding, optimization is paused');
                send(queueEventPool.seedingHandle, 1);
                pause(packet.duration);
                send(queueEventPool.seedingHandle, 0);
                pause(packet.delay);
                send(queueEventPool.logger, 'OPT: finish flow seeding, optimization is continued');
            end
        else
            send(queueEventPool.logger, 'OPT: seeding parameter receiving timeout is expired, flow seeding is omitted');
        end
    end

    tStart = tic;
    result = nan;
    
    send(queueEventPool.logger, 'OPT: send voltage packet');
    send(queueEventPool.mcuHttpPost, jsonencode(struct(dac = struct(value = value, index = index))));
    state = poll(queuePollableWorkerPool.mcuHttpPost.Value, 10);
    if ~state
        send(queueEventPool.logger, 'OPT: voltage packet is not received, function is terminated');                   
        send(queueEventPool.optTerminate, true);
        return
    end
    send(queueEventPool.logger, 'OPT: voltage packet is received');

    send(queueEventPool.logger, 'OPT: worker synchronization');
    state = false;
    while ~state
        send(queueEventPool.logger, 'OPT: reset data counter');
        id = rand(1, 1);
        send(queueEventPool.pivResetCounter, id);

        send(queueEventPool.logger, 'OPT: wait measurement data');
        [packet, plstate] = poll(queuePollableWorkerPool.pivProcessed.Value, 30);

        if plstate
            state = packet.id == id;
        else
            send(queueEventPool.logger, 'OPT: timeout is expired, function is terminated');
            break
        end
    end

    if plstate
        send(queueEventPool.logger, 'OPT: measurement data is received');
        result = func_norm(packet.data);
    
        send(queueEventPool.logger, strcat({'OPT: object value is '}, num2str(result)));
        
        tEnd = toc(tStart);
        send(queueEventPool.optPreview, struct('output', packet.data, 'obj_val', result, 'time', tEnd, 'input', value));
    else
        send(queueEventPool.optTerminate, true);
        return
    end
end