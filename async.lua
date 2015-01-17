local async = {}

async.waterfall = function(tasks, finalCb)
    local expected = 1
    local iterate

    iterate = function(i, err, ...)
        if expected ~= i then
            return
        end
        expected = expected + 1
        if err or i > #tasks then
            if finalCb then
                return finalCb(err, ...)
            end
            return
        end
        local task = tasks[i]

        return task(function(...)
            iterate(i + 1, ...)
        end, ...)
    end

    iterate(1)
end

async.parallel = function(tasks, finalCb)
    local results = {}
    local abort = false
    local status = {
        n = 0
    }
    local iterate = function(i, err, r)
        if abort then
            return
        end
        if status[i] then
            return
        end
        if err then
            abort = true
            if finalCb then
                finalCb(err)
            end
            return
        end
        results[i] = r
        status[i] = true
        status.n = status.n + 1

        if status.n == #tasks then
            if finalCb then
                finalCb(nil, results)
            end
        end
    end

    for i = 1, #tasks do
        tasks[i](function(...)
            iterate(i, ...)
        end)
    end
end

return async
