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

local class = {}

function class.new(service)
  return {
    service = service;
  }
end

function class:release(delete_timer_handle)
  if self.timer_handle then
    if delete_timer_handle then
      self.timer_handle:delete()
    end
    self.timer_handle = nil
  end
  local thread = self.thread
  self.thread = nil
  return thread
end

function class:set_ready()
  self.status = "ready"
  local thread = self:release(true)
  if thread then
    assert(coroutine.resume(thread, "ready"))
  end
end

function class:set_value(...)
  self.value = pack(...)
  self:set_ready()
end

function class:set_error(message)
  self.message = message
  self:set_ready()
end

function class:is_ready()
  return self.status == "ready"
end

function class:wait(timeout)
  if self:is_ready() then
    return "ready"
  else
    self:launch()
    if self:is_ready() then
      return "ready"
    end
    if timeout then
      self.timer_handle = self.service:add_timer(timeout, coroutine.create(function ()
        local thread = self:release(false)
        if thread then
          assert(coroutine.resume(thread, "timeout"))
        end
      end))
    end
    self.thread = coroutine.running()
    return coroutine.yield()
  end
end

function class:wait_for(timeout)
  return self:wait(self.service:get_current_time():add(timeout))
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
  __call = function (_, service)
    return setmetatable(class.new(service), metatable)
  end;
})
