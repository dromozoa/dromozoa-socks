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

local unix = require "dromozoa.unix"
local create_thread = require "dromozoa.socks.create_thread"
local futures = require "dromozoa.socks.futures"
local io_handler = require "dromozoa.socks.io_handler"
local io_service = require "dromozoa.socks.io_service"
local timer_service = require "dromozoa.socks.timer_service"

local class = {}

function class.new()
  local async_service = unix.async_service()
  local async_threads = {}
  local self = {
    timer_service = timer_service();
    io_service = io_service();
    async_service = async_service;
    async_threads = async_threads;
  }
  class.add_handler(self, io_handler(unix.fd_ref(async_service:get()), "read", function ()
    while true do
      local result = self.async_service:read()
      if result > 0 then
        while true do
          local task = self.async_service:pop()
          if task then
            local thread = self.async_threads[task]
            if thread then
              self.async_threads[task] = nil
              assert(coroutine.resume(thread))
            end
          else
            break
          end
        end
      end
      coroutine.yield()
    end
  end))
  return self
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

function class:add_task(task, thread)
  self.async_service:push(task)
  self.async_threads[task] = thread
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

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = futures;
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
