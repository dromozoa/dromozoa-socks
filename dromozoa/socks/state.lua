-- Copyright (C) 2016,2017 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local pack = require "dromozoa.commons.pack"
local unpack = require "dromozoa.commons.unpack"
local create_thread = require "dromozoa.socks.create_thread"
local never_return = require "dromozoa.socks.never_return"
local resume_thread = require "dromozoa.socks.resume_thread"

local class = {}

function class.new(service)
  return {
    service = service;
    status = "initial";
  }
end

function class:is_initial()
  return self.status == "initial"
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

function class:launch()
  assert(not self.waiting_state)
  assert(self:is_initial())
  self.status = "running"
end

function class:suspend()
  local waiting_state = self.waiting_state
  if waiting_state then
    waiting_state:suspend()
  end
  assert(self:is_running())
  self.status = "suspended"
  if self.timer_handle then
    self.service:delete_timer(self.timer_handle)
    self.timer_handle = nil
  end
end

function class:resume()
  local waiting_state = self.waiting_state
  if waiting_state then
    waiting_state:resume()
  end
  assert(self:is_suspended())
  self.status = "running"
  if self.timeout then
    self.timer_handle = self.service:add_timer(self.timeout, self.timer)
  end
end

function class:finish()
  assert(not self.waiting_state)
  assert(self:is_running())
  self.status = "ready"
  if self.timer_handle then
    self.service:delete_timer(self.timer_handle)
    self.timer_handle = nil
  end
end

function class:set_ready()
  self:finish()
  self.service:set_current_state(self.parent_state)
  if self.parent_state then
    self.parent_state.waiting_state = nil
    self.parent_state = nil
  end
  local caller = self.caller
  if caller then
    self.caller = nil
    resume_thread(caller, "ready")
  end
end

function class:set(...)
  self.value = pack(...)
  self:set_ready()
end

function class:error(message)
  self.value = pack(nil, debug.traceback(message))
  self:set_ready()
  error(never_return, 0)
end

function class:assert(...)
  if ... then
    return ...
  else
    local result, message = ...
    if message == nil then
      message = "assertion failed!"
    end
    self.value = pack(nil, debug.traceback(message))
    self:set_ready()
    error(never_return, 0)
  end
end

function class:dispatch(timeout)
  if self:is_ready() then
    return true
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
      return true
    else
      if timeout then
        self.timeout = timeout
        self.timer = coroutine.create(function ()
          self:suspend()
          self.timeout = nil
          self.timer = nil
          self.service:set_current_state(self.parent_state)
          if self.parent_state then
            self.parent_state.waiting_state = nil
            self.parent_state = nil
          end
          local caller = self.caller
          self.caller = nil
          resume_thread(caller, "timeout")
        end)
        self.timer_handle = self.service:add_timer(self.timeout, self.timer)
      end
      if parent_state then
        parent_state.waiting_state = self
      end
      self.parent_state = parent_state
      return false
    end
  end
end

function class:wait(timeout)
  if self:dispatch(timeout) then
    return "ready"
  else
    self.caller = coroutine.running()
    return coroutine.yield()
  end
end

function class:wait_until(timeout)
  return self:wait(timeout)
end

function class:wait_for(timeout)
  return self:wait(self.service:get_current_time():add(timeout))
end

function class:get()
  self:wait()
  return unpack(self.value, 1, self.value.n)
end

function class:then_(thread)
  local thread = create_thread(thread)
  return self.service:deferred(function (promise)
    self:wait()
    resume_thread(thread, self, promise)
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
