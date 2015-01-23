local async = require("async")

local tests = {

    onlyOnce_should_throw_if_called_twice = function()
        local f = async.onlyOnce(function()
        end)
        assert(pcall(f))
        assert(not pcall(f))
    end,

    each_should_iterate_in_parallel = function()
        local arr       = {1, 2, 3}
        local callbacks = {}

        async.each(arr, function(item, callback)
            callbacks[item] = callback
        end)

        assert(callbacks[1])
        assert(callbacks[2])
        assert(callbacks[3])
    end,

    each_can_finish_without_error = function()
        local arr       = {1, 2, 3}
        local callbacks = {}
        local finished = false

        async.each(arr, function(item, callback)
            callbacks[item] = callback
        end,
        function(err, results)
            assert(not err)
            assert(results[1] == 'a')
            assert(results[2] == 'b')
            assert(results[3] == 'c')

            assert(not finished)
            finished = true
        end)

        assert(not finished)
        callbacks[1](nil, 'a')
        assert(not finished)
        callbacks[2](nil, 'b')
        assert(not finished)
        callbacks[3](nil, 'c')

        assert(finished)
    end,

    each_can_handle_error = function()
        local arr       = {1, 2, 3}
        local callbacks = {}
        local finished = false

        async.each(arr, function(item, callback)
            callbacks[item] = callback
        end,
        function(err)
            assert(not finished)
            assert(err == "error")
            finished = true
        end)

        assert(not finished)
        callbacks[1]("error")
        assert(finished)

        callbacks[2]()
        callbacks[3]()
    end,

    eachSeries_should_iterate_one_by_one = function()
        local arr       = {1, 2, 3}
        local callbacks = {}
        local expected  = 1

        async.eachSeries(arr, function(i, cb)
            assert(expected == i)
            callbacks[i] = cb
        end)

        expected = 2
        callbacks[1]()
        expected = 3
        callbacks[2]()
    end,

    eachSeries_can_finish_without_error = function()
        local arr       = {1, 2, 3}
        local callbacks = {}
        local finished  = false

        async.eachSeries(arr, function(i, cb)
            callbacks[i] = cb
        end,
        function(err, results)
            assert(not err)
            assert(results[1] == 'a')
            assert(results[2] == 'b')
            assert(results[3] == 'c')

            assert(not finished)
            finished = true
        end)

        callbacks[1](nil, 'a')
        callbacks[2](nil, 'b')
        callbacks[3](nil, 'c')

        assert(finished)
    end,

    eachSeries_can_handle_error = function()
        local arr       = {1, 2, 3}
        local callbacks = {}
        local finished  = false

        async.eachSeries(arr, function(i, cb)
            callbacks[i] = cb
        end,
        function(err, results)
            assert(err == 'error')
            assert(not finished)
            finished = true
        end)

        assert(not finished)
        callbacks[1]('error')
        assert(finished)
    end,
}

local function runTest(name, func)
    return xpcall(func, function(msg)
        print(string.format("[%s]: %s", name, msg))
    end)
end

local function runAllTests(tests)
    local succeeded, failed = 0, 0

    for name, test in pairs(tests) do
        if runTest(name, test) then
            succeeded = succeeded + 1
        else
            failed = failed + 1
        end
    end

    print(string.format("%d succeeded, %d failed", succeeded, failed))
end

runAllTests(tests)
