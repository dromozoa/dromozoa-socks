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

local function wait_until(self, timeout)
  if self.state.status == "ready" then
    return "ready"
  else
    self.state.thread = coroutine.running()
    if timeout then
      self.state.timer_handle = self.state.service.timer:insert(timeout, coroutine.create(function ()
        self.state.timer_handle = nil
        self.state:del_handler()
        assert(coroutine.resume(self.state.thread, "timeout"))
      end))
    end
    self.state:add_handler()
    return coroutine.yield()
  end
end

local class = {}

function class.new(state)
  return {
    state = state;
  }
end

function class:get()
  self:wait()
  return self.state:get()
end

function class:wait()
  return wait_until(self)
end

function class:wait_for(timeout)
  return wait_until(self, self.state.service.timer.current_time:add(timeout))
end

function class:wait_until(timeout)
  return wait_until(self, timeout)
end

function class:is_ready()
  return self.state.status == "ready"
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, state)
    return setmetatable(class.new(state), metatable)
  end;
})
