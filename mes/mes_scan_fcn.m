function mes_scan_fcn(value, index, i, queueEventPool, queuePollableWorkerPool)
    arguments
        value (1,:) double
        index (1,:) doule
        i (1,1) double
        queueEventPool struct
        queuePollableWorkerPool struct
    end
    
    tStart = tic;            
    send(queueEventPool.logger, 'MES: send voltage packet');
    send(queueEventPool.mcuHttpPost, jsonencode(struct(dac = struct(value = value, index = index))));
    state = poll(queuePollableWorkerPool.mcuHttpPost.Value, 10);
    if (~state)
        send(queueEventPool.logger, 'MES: voltage packet is not received, function is terminated');                   
        send(queueEventPool.mesTerminate, true);
        return;
    end
    send(queueEventPool.logger, 'MES: voltage packet is received');
    
    send(queueEventPool.logger, 'MES: worker synchronization');
    state = false;
    while ~state
        send(queueEventPool.logger, 'MES: reset data counter');
        id = rand(1, 1);
        send(queueEventPool.pivResetCounter, id);
        
        send(queueEventPool.logger, 'MES: wait measurement data');
        [data, plstate] = poll(queuePollableWorkerPool.pivProcessed.Value, 30);
    
        if plstate
            state = data.id == id;
        else
            send(queueEventPool.logger, 'MES: timeout is expired, function is terminated');
            send(queueEventPool.logger, 'MES: function is terminated');
            break;
        end
    end

    if plstate
        send(queueEventPool.logger, 'MES: measurement data is received');
        tEnd = toc(tStart);
        send(queueEventPool.mesPreview, i);
        send(queueEventPool.mesStore, struct(data = data.data, time = tEnd, input = value));
    else
        send(queueEventPool.mesTerminate, true);
        return;
    end
end