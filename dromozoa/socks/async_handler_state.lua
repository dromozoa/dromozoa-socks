-- Copyright (C) 2016 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-socks.
--
-- dromozoa-socks is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-socks is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-socks.  If not, see <http://www.gnu.org/licenses/>.

local unpack = require "dromozoa.commons.unpack"
local pack = require "dromozoa.socks.pack"
local async_handler = require "dromozoa.socks.async_handler"
local async_promise = require "dromozoa.socks.async_promise"

local function set_ready(self)
  self.status = "ready"
  if self.handler then
    assert(self.service:del(self.handler))
  end
  local timer_handle = self.timer_handle
  if timer_handle then
    self.timer_handle = nil
    timer_handle:delete()
  end
  local thread = self.thread
  if thread then
    self.thread = nil
    assert(coroutine.resume(thread, "ready"))
  end
end

local class = {}

function class.new(service, fd, event, thread)
  local self = {
    service = service;
  }
  self.handler = async_handler(fd, event, coroutine.create(function ()
    local promise = async_promise(self)
    while true do
      local result, message = coroutine.resume(thread, promise)
      if not result then
        self:set_error(message)
        return
      end
      if self.status == "ready" then
        return
      end
      coroutine.yield()
    end
  end))
  return self
end

function class:set_value(...)
  self.value = pack(...)
  set_ready(self)
end

function class:set_error(message)
  self.message = message
  set_ready(self)
end

function class:is_ready()
  return self.status == "ready"
end

function class:wait(timeout)
  if self.status == "ready" then
    return "ready"
  else
    assert(self.service:add(self.handler))
    if timeout then
      self.timer_handle = self.service.timer:insert(timeout, coroutine.create(function ()
        self.timer_handle = nil
        assert(self.service:del(self.handler))
        assert(coroutine.resume(self.thread, "timeout"))
      end))
    end
    self.thread = coroutine.running()
    return coroutine.yield()
  end
end

function class:wait_for(timeout)
  return self:wait(self.service.timer.current_time:add(timeout))
end

function class:get()
  self:wait()
  if self.message ~= nil then
    error(self.message)
  else
    return unpack(self.value)
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, service, fd, event, thread)
    return setmetatable(class.new(service, fd, event, thread), metatable)
  end;
})
