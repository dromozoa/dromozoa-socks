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

local create_thread = require "dromozoa.socks.create_thread"
local unpack = require "dromozoa.commons.unpack"
local pack = require "dromozoa.socks.pack"

local class = {}

function class.new(service)
  return {
    service = service;
  }
end

function class:launch()
  self.status = "running"
end

function class:suspend()
  self.status = "suspended"
  self.timer_handle = nil
end

function class:resume()
  self.status = "running"
end

function class:finish()
  self.status = "ready"
  if self.timer_handle then
    self.timer_handle:delete()
    self.timer_handle = nil
  end
end

function class:is_running()
  return self.status == "running"
end

function class:is_suspended()
  return self.status == "suspended"
end

function class:is_ready()
  return self.status == "ready"
end

function class:set_ready()
  self:finish()
  self.service:set_current_state(self.parent_state)
  local caller = self.caller
  if caller then
    self.caller = nil
    assert(coroutine.resume(caller, "ready"))
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

function class:wait(timeout)
  if self:is_ready() then
    return "ready"
  else
    local parent_state = self.service:get_current_state()
    self.service:set_current_state(self)
    if self:is_suspended() then
      self:resume()
    else
      self:launch()
    end
    if self:is_ready() then
      self.service:set_current_state(parent_state)
      return "ready"
    else
      if timeout then
        self.timer_handle = self.service:add_timer(timeout, coroutine.create(function ()
          self:suspend()
          self.service:set_current_state(self.parent_state)
          local caller = self.caller
          self.caller = nil
          assert(coroutine.resume(caller, "timeout"))
        end))
      end
      if parent_state then
        parent_state.waiting_state = self
      end
      self.parent_state = parent_state
      self.caller = coroutine.running()
      return coroutine.yield()
    end
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

function class:then_(thread)
  local thread = create_thread(thread)
  return self.service:deferred(function (promise)
    self:wait()
    promise:set_value(select(2, assert(coroutine.resume(thread, self))))
  end)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, service)
    return setmetatable(class.new(service), metatable)
  end;
})
