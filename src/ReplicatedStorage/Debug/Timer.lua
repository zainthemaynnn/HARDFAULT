local Timer = {}
Timer.__index = Timer

function Timer.new()
	local self = setmetatable({}, Timer)
	self._LastCall = os.time()
	self._Duration = 0
	self._Paused = true
	return self
end

function Timer:_UpdateDuration()
	if not self.Paused then
		self._Duration += os.difftime(os.time(), self._LastCall)
		self._LastCall = os.time()
	end
end

function Timer:Resume()
	self._LastCall = os.time()
	self._Paused = false
end

function Timer:Pause()
	self:_UpdateDuration()
	self._Paused = true
end

function Timer:IsPaused()
	return self._Paused
end

function Timer:Duration()
	self:_UpdateDuration()
	return self._Duration
end

function Timer:Reset()
	self._Duration = 0
	self:Resume()
end

function Timer.benchmark(fn, iterations, ...)
	local begin = os.time()
	for _ = 0, iterations do
		fn(...)
	end
	return os.difftime(begin, os.time())
end

return Timer