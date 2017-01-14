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

local uint32 = require "dromozoa.commons.uint32"
local unix = require "dromozoa.unix"
local io_handler = require "dromozoa.socks.io_handler"
local io_service = require "dromozoa.socks.io_service"

local fd1, fd2 = unix.socketpair(unix.AF_UNIX, uint32.bor(unix.SOCK_STREAM, unix.SOCK_CLOEXEC))
assert(fd1:ndelay_on())
assert(fd2:ndelay_on())

local service = io_service()

assert(service:dispatch())

local done
service:add_handler(io_handler(fd2, "write", function (service, handler, event)
  assert(event == "write")
  service:remove_handler(handler)
  fd2:write("x")
  service:add_handler(io_handler(fd1, "read", function (service, handler, event)
    assert(event == "read")
    service:remove_handler(handler)
    assert(fd1:read(1) == "x")
    done = true
  end))
end))

assert(service:dispatch())

assert(not done)
assert(service:dispatch())
assert(done)

assert(service:dispatch())

assert(fd1:close())
assert(fd2:close())
