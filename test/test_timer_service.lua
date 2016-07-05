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
local timer_service = require "dromozoa.socks.timer_service"

local service = timer_service()

local done
local thread = coroutine.create(function ()
  local handle = service:add_timer(service:get_current_time(), coroutine.running())
  coroutine.yield()
  service:delete_timer(handle)

  local handle = service:add_timer(service:get_current_time():add(0.2), coroutine.running())
  coroutine.yield()
  service:delete_timer(handle)

  done = true
end)

assert(coroutine.resume(thread))
assert(service:dispatch())
assert(unix.nanosleep(0.5))
assert(not done)
assert(service:dispatch())
assert(done)
assert(service:dispatch())
