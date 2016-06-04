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

function class:wait(timeout)
  if self.state.status == "ready" then
    return "ready"
  else
    self.state.thread = coroutine.running()
    if timeout then
      self.state.timer_handle = self.state.service.timer:insert(timeout, coroutine.create(function ()
        for handler in self.state:each_handler() do
          if handler.status then
            assert(self.state.service:del(handler))
          end
        end
        assert(coroutine.resume(self.state.thread, "timeout"))
      end))
    end
    for handler in self.state:each_handler() do
      assert(self.state.service:add(handler))
    end
    return coroutine.yield()
  end
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
