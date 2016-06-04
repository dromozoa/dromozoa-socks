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
  assert(self.service:del(self.handler))
  if self.timer_handle then
    self.timer_handle:delete()
    self.timer_handle = nil
  end
  assert(coroutine.resume(self.thread, "ready"))
end

local class = {}

function class.new(service, fd, event, thread)
  local self = {
    service = service;
  }
  self.promise = async_promise(self)
  self.handler = async_handler(fd, event, coroutine.create(function (service, handler, event)
    self.service = service
    while true do
      local result, message = coroutine.resume(thread, self.promise)
      if not result then
        self:set_error(message)
        break
      end
      if self.status == "ready" then
        break
      end
      self.service, handler, event = coroutine.yield()
    end
  end))
  return self
end

function class:each_handler()
  return coroutine.wrap(function ()
    coroutine.yield(self.handler)
  end)
end

function class:set_value(...)
  self.value = pack(...)
  return set_ready(self)
end

function class:set_error(message)
  self.message = message
  return set_ready(self)
end

function class:get()
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
