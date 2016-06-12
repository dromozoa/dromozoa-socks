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
local multimap = require "dromozoa.socks.multimap"

local class = {}

function class.new(clock)
  if clock == nil then
    clock = unix.CLOCK_MONOTONIC_RAW
  end
  return class.update_current_time({
    clock = clock;
    threads = multimap();
  })
end

function class:update_current_time()
  self.current_time = unix.clock_gettime(self.clock)
  return self
end

function class:get_current_time()
  return self.current_time
end

function class:add_timer(timeout, thread)
  return self.threads:insert(timeout, create_thread(thread))
end

function class:empty()
  return self.threads:empty()
end

function class:dispatch()
  self:update_current_time()
  for _, thread, handle in self.threads:upper_bound(self:get_current_time()):each() do
    local result, message = coroutine.resume(thread, handle)
    if not result then
      return nil, message
    end
  end
  return self
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, clock)
    return setmetatable(class.new(clock), metatable)
  end;
})
