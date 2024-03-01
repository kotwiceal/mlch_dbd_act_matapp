function mes_scan(value, index, queueEventPool, queuePollableWorkerPool)
    arguments
        value (1,:) double
        index (1,:) doule
        queueEventPool struct
        queuePollableWorkerPool struct
    end

    send(queueEventPool.logger, 'MES: start of scanning');
    for i = 1:size(value, 2)
        mes_scan_fcn(value(:, i), index, i, queueEventPool, queuePollableWorkerPool);
    end
    send(queueEventPool.logger, 'MES: completion of scanning');
    send(queueEventPool.mcuHttpPost, jsonencode(struct(dac = struct(value = zeros(1, 16), index = 0:15))));
    send(queue_pool.mesComplete, true);
end