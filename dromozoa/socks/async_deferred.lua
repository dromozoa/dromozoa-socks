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
local async_promise = require "dromozoa.socks.async_promise"

local function set_ready(self)
  self.status = "ready"
  if self.thread then
    assert(coroutine.resume(self.thread, "ready"))
  end
end

local class = {
  policy = "deferred";
}

function class.new(service, thread)
  local self = {
    service = service;
  }
  self.promise = async_promise(self)
  self.deferred = coroutine.create(function ()
    coroutine.resume(thread, self.promise)
  end)
  return self
end

function class:set_value(...)
  self.value = pack(...)
  return set_ready(self)
end

function class:set_error(message)
  self.message = message
  return set_ready(self)
end

function class:is_ready()
  return self.status == "ready"
end

function class:get()
  self:wait()
  if self.message ~= nil then
    error(self.message)
  else
    return unpack(self.value)
  end
end

function class:wait()
  if self.status == "ready" then
    return "ready"
  else
    local result, message = coroutine.resume(self.deferred)
    if not result then
      self:set_error(message)
    end
    if self.status == "ready" then
      return ready
    else
      self.thread = coroutine.running()
      return coroutine.yield()
    end
  end
end

function class:wait_for()
  return self:wait()
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, service, thread)
    return setmetatable(class.new(service, thread), metatable)
  end;
})
