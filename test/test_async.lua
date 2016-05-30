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

local uint32 = require "dromozoa.commons.uint32"
local unix = require "dromozoa.unix"
local async_event = require "dromozoa.socks.async_event"
local async_service = require "dromozoa.socks.async_service"

local fd1, fd2 = unix.socketpair(unix.AF_UNIX, uint32.bor(unix.SOCK_STREAM, unix.SOCK_CLOEXEC))

local service = async_service()

service:add(async_event(fd1, "read", function (service, event, ev)
  print(service, event, ev)
  service:del(event)
  service:add(async_event(fd2, "write", function (service, event, ev)
    print(service, event, ev)
    service:del(event)
    fd2:write("x")
    service:add(async_event(fd1, "read", function (service, event, ev)
      print(service, event, ev)
      service:del(event)
      local x = fd1:read(1)
      assert(x == "x")
      service:stop()
    end))
  end))
end), service.current_time:add(1))

service:dispatch()

assert(fd1:close())
assert(fd2:close())
