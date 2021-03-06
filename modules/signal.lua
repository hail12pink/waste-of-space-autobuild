local SignalConnection = {}
SignalConnection.ClassName = "SignalConnection"
SignalConnection.__index = SignalConnection

function SignalConnection.new(container, index, handler)
	return setmetatable({
		_container = container;
		_index = index;
		_handler = handler;
	}, SignalConnection)
end

function SignalConnection:Disconnect()
	if self._container then
		self._container[self._index] = nil
	end
end

local Signal = {}
Signal.ClassName = "Signal"
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_waits = {};
		_handlers = {};
	}, Signal)
end

function Signal:Fire(...)
	for i, v in ipairs(self._waits) do
		coroutine.resume(v, ...)
		table.remove(self._waits, i)
	end

	for i, v in pairs(self._handlers) do
		local thread = coroutine.create(v._handler)
		coroutine.resume(thread, ...)
	end
end

function Signal:Connect(handler)
	assert(type(handler) == "function", "Passed value is not a function")

	local index = #self._handlers + 1
	local connection = SignalConnection.new(self._handlers, index, handler)

	table.insert(self._handlers, index, connection)
	
	return connection
end

function Signal:Wait()
	table.insert(self._waits, coroutine.running())
	return coroutine.yield()
end

function Signal:Destroy()
	for i, v in ipairs(self._waits) do
		coroutine.resume(v)
		table.remove(self._waits, i)
	end

	for i, connection in pairs(self._handlers) do
		connection:Disconnect()
	end
end
