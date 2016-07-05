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
local future_service = require "dromozoa.socks.future_service"

local fd1, fd2 = unix.socketpair(unix.AF_UNIX, uint32.bor(unix.SOCK_STREAM, unix.SOCK_CLOEXEC))
assert(fd1:ndelay_on())
assert(fd2:ndelay_off())

local service = future_service()

local done
assert(service:dispatch(function (service)
  local f = service:io_handler(fd1, "read", function (promise)
    local buffer = ""
    while true do
      local char = fd1:read(1)
      if char then
        print(("char=%q"):format(char))
        if char == "\n" then
          promise:set(buffer)
          break
        else
          buffer = buffer .. char
        end
      else
        if unix.get_last_errno() == unix.EAGAIN then
          promise = coroutine.yield()
        else
          assert(unix.get_last_error())
        end
      end
    end
  end)

  assert(not f:is_ready())

  assert(f:wait_for(0.2) == "timeout")
  print(unix.clock_gettime(unix.CLOCK_REALTIME))
  assert(fd2:write("f"))

  assert(f:wait_for(0.2) == "timeout")
  print(unix.clock_gettime(unix.CLOCK_REALTIME))
  assert(fd2:write("o"))

  assert(f:wait_for(0.2) == "timeout")
  print(unix.clock_gettime(unix.CLOCK_REALTIME))
  assert(fd2:write("o"))

  assert(f:wait_for(0.2) == "timeout")
  print(unix.clock_gettime(unix.CLOCK_REALTIME))
  assert(fd2:write("\n"))

  assert(f:wait() == "ready")
  print(unix.clock_gettime(unix.CLOCK_REALTIME))

  assert(f:is_ready())
  assert(f:get() == "foo")
  fd2:write("bar\n")

  service:stop()
  done = true
end))
assert(done)

assert(fd1:close())
assert(fd2:close())
