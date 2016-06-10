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
  print("launch", self, self.waiting_state)
  -- if self.waiting_state then
  --   self.waiting_state:launch()
  -- end
end

function class:finish(status)
  print("finish", self, self.waiting_state, status)
  -- if self.waiting_state then
  --   self.waiting_state:finish(status)
  -- end
  if self.timer_handle then
    if status == "ready" then
      self.timer_handle:delete()
    end
    self.timer_handle = nil
  end
  local caller = self.caller
  self.caller = nil
  return caller
end

function class:set_ready()
  self.status = "ready"
  local caller = self:finish("ready")
  local parent_state = self.parent_state
  if parent_state then
    parent_state.waiting_state = nil
  end
  self.service:set_current_state(parent_state)
  if caller then
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

function class:is_ready()
  return self.status == "ready"
end

function class:wait(timeout)
  if self:is_ready() then
    return "ready"
  else
    local parent_state = self.service:get_current_state()
    self.service:set_current_state(self)
    self:launch()
    if self:is_ready() then
      self.service:set_current_state(parent_state)
      return "ready"
    else
      self.parent_state = parent_state
      if parent_state then
        parent_state.waiting_state = self
      end
      print("wait", "parent", self.parent_state, "waiting", self)
      if timeout then
        self.timer_handle = self.service:add_timer(timeout, coroutine.create(function ()
          local caller = self:finish("timeout")
          local parent_state = self.parent_state
          if parent_state then
            parent_state.waiting_state = nil
          end
          self.service:set_current_state(parent_state)
          if caller then
            assert(coroutine.resume(caller, "timeout"))
          end
        end))
      end
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
