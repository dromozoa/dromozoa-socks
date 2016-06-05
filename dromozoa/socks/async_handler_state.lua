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

local async_handler = require "dromozoa.socks.async_handler"
local async_promise = require "dromozoa.socks.async_promise"
local async_state = require "dromozoa.socks.async_state"

local class = {}

function class.new(service, fd, event, thread)
  local self = async_state.new(service)
  self.handler = async_handler(fd, event, coroutine.create(function ()
    local promise = async_promise(self)
    while true do
      local result, message = coroutine.resume(thread, promise)
      if not result then
        self:set_error(message)
      end
      if self:is_ready() then
        return
      end
      coroutine.yield()
    end
  end))
  return self
end

function class:set_ready()
  self.status = "ready"
  if self.handler then
    assert(self.service:del(self.handler))
  end
  if self.timer_handle then
    self.timer_handle:delete()
    self.timer_handle = nil
  end
  local thread = self.thread
  if thread then
    self.thread = nil
    assert(coroutine.resume(thread, "ready"))
  end
end

function class:wait(timeout)
  if self:is_ready() then
    return "ready"
  else
    assert(self.service:add(self.handler))
    if timeout then
      self.timer_handle = self.service.timer:insert(timeout, coroutine.create(function ()
        if self.handler then
          assert(self.service:del(self.handler))
        end
        self.timer_handle = nil
        assert(coroutine.resume(self.thread, "timeout"))
      end))
    end
    self.thread = coroutine.running()
    return coroutine.yield()
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = async_state;
  __call = function (_, service, fd, event, thread)
    return setmetatable(class.new(service, fd, event, thread), metatable)
  end;
})
