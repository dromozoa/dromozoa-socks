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
local deferred_state = require "dromozoa.socks.deferred_state"
local future = require "dromozoa.socks.future"
local io_handler_state = require "dromozoa.socks.io_handler_state"
local io_service = require "dromozoa.socks.io_service"
local latch_state = require "dromozoa.socks.latch_state"
local make_ready_future = require "dromozoa.socks.make_ready_future"
local shared_future = require "dromozoa.socks.shared_future"
local shared_state = require "dromozoa.socks.shared_state"
local timer_service = require "dromozoa.socks.timer_service"

local class = {}

function class.new()
  return {
    timer_service = timer_service();
    io_service = io_service();
  }
end

function class:get_current_time()
  return self.timer_service:get_current_time()
end

function class:add_timer(timeout, thread)
  return self.timer_service:add_timer(timeout, thread)
end

function class:delete_timer(handle)
  self.timer_service:delete_timer(handle)
  return self
end

function class:add_handler(handler)
  local result, message = self.io_service:add_handler(handler)
  if not result then
    return nil, message
  end
  return self
end

function class:delete_handler(handler)
  local result, message = self.io_service:delete_handler(handler)
  if not result then
    return nil, message
  end
  return self
end

function class:start()
  self.stopped = nil
  return self
end

function class:stop()
  self.stopped = true
  return self
end

function class:dispatch(thread)
  if thread then
    local result, message = coroutine.resume(create_thread(thread), self)
    if not result then
      return nil, message
    end
    if self.stopped then
      return self
    end
  end
  while true do
    local result, message = self.timer_service:dispatch()
    if not result then
      return nil, message
    end
    if self.stopped then
      return self
    end
    local result, message = self.io_service:dispatch()
    if not result then
      return nil, message
    end
    if self.stopped then
      return self
    end
  end
end

function class:set_current_state(current_state)
  self.current_state = current_state
end

function class:get_current_state()
  return self.current_state
end

function class:deferred(thread)
  return future(deferred_state(self, thread))
end

function class:io_handler(fd, event, thread)
  return future(io_handler_state(self, fd, event, thread))
end

function class:when_any(...)
  return future(latch_state(self, 1, ...))
end

function class:when_all(...)
  return future(latch_state(self, "n", ...))
end

function class:make_ready_future(...)
  return make_ready_future(...)
end

function class:make_shared_future(future)
  return shared_future(self, shared_state(self, future))
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
