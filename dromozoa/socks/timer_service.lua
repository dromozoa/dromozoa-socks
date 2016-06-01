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
local multimap = require "dromozoa.socks.multimap"

local class = {}

function class.new(clock)
  if clock == nil then
    clock = unix.CLOCK_MONOTONIC_RAW
  end
  return class.update({
    clock = clock;
    threads = multimap();
  })
end

function class:update()
  self.current_time = unix.clock_gettime(self.clock)
  return self
end

function class:insert(timeout, thread)
  return self.threads:insert(timeout, thread)
end

function class:dispatch()
  local count = 0
  while true do
    self:update()
    local range = self.threads:upper_bound(self.current_time)
    if range:empty() then
      break
    end
    for _, thread, handle in range:each() do
      handle:delete()
      local result, message = coroutine.resume(thread, "timeout")
      if result then
        count = count + 1
      else
        return nil, message
      end
    end
  end
  return count
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, clock)
    return setmetatable(class.new(clock), metatable)
  end;
})
