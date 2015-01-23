local async = {}

async._error = error

local function dummyFunc()
end

-- Call only once
--
local function onlyOnce(fn)
    local called = false
    return function(...)
        if called then
            error("Callback was already called.")
        end
        called = true
        fn(...)
    end
end
async.onlyOnce = onlyOnce

-- Iterate arr in parallel
--   and passes all results to the final callback.
--
async.each = function(arr, iterator, callback)
    callback = callback or dummyFunc

    local results = {}
    local completed = 0

    local function reduce(i, err, r)
        if err then
            local func = callback
            callback = dummyFunc
            return func(err)
        end
        results[i] = r
        completed = completed + 1
        if completed == #arr then
            return callback(nil, results)
        end
    end

    for i = 1, #arr do
        iterator(arr[i], onlyOnce(function(...)
            reduce(i, ...)
        end))
    end
end

-- Iterate arr in one by one
--   and passes all results to the final callback.
--
async.eachSeries = function(arr, iterator, callback)
    callback = callback or dummyFunc

    local results = {}

    local function iterate(i, err)
        if err or i > #arr then
            return callback(err, results)
        end
        return iterator(arr[i], onlyOnce(function(err, r)
            results[i] = r
            iterate(i + 1, err)
        end))
    end

    iterate(1)
end

-- Do tasks one by one,
--   and passes all results to the final callback.
--
async.series = function(tasks, callback)
    return async.eachSeries(tasks, function(task, cb)
        return task(cb)
    end, callback)
end

-- Do tasks one by one,
--   and allow each function to pass its results to the next function,
--
async.waterfall = function(tasks, callback)
    callback = callback or dummyFunc

    local function iterate(i, err, ...)
        if err or i > #tasks then
            return callback(err, ...)
        end
        return tasks[i](..., onlyOnce(function(...)
            iterate(i + 1, ...)
        end))
    end

    iterate(1)
end

-- Do tasks in parallel
--
async.parallel = function(tasks, callback)
    return async.each(tasks, function(task, cb)
        return task(cb)
    end, callback)
end

return async
