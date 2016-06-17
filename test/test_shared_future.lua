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
  local f1 = service:io_handler(fd1, "read", function (promise)
    while true do
      print("io1")
      local char = fd1:read(1)
      print("io2", char)
      if char then
        return promise:set_value(char)
      else
        if unix.get_last_errno() == unix.EAGAIN then
          promise = coroutine.yield()
        else
          return promise:set_error(unix.strerror(unix.get_last_errno()))
        end
      end
    end
  end)

  local f2 = service:deferred(function (promise)
    print("f2a", unix.clock_gettime(unix.CLOCK_REALTIME))
    local char = f1:get()
    print("f2b")
    return promise:set_value(char)
  end)

  local shared = service:make_shared_future(f2)
  local sharer1 = shared:share()
  local sharer2 = shared:share()

  local f3 = service:deferred(function (promise)
    print("u1a", unix.clock_gettime(unix.CLOCK_REALTIME))
    sharer1:wait_for(0.5)
    print("u1b", unix.clock_gettime(unix.CLOCK_REALTIME))
    promise:set_value(true)
  end)

  local f4 = service:deferred(function (promise)
    print("u2a", unix.clock_gettime(unix.CLOCK_REALTIME))
    sharer2:wait_for(0.3)
    print("u2b", unix.clock_gettime(unix.CLOCK_REALTIME))
    promise:set_value(true)
  end)

  print("f3", f3.state)
  print("f4", f4.state)

  local f5 = service:when_all(f3, f4)
  assert(f5:wait_for(0.2) == "timeout")

  print("sharer1", sharer1.state.status)
  print("sharer2", sharer2.state.status)
  print("f3", f3.state.status)
  print("f4", f4.state.status)

  assert(f5:wait_for(0.2) == "timeout")

  print("sharer1", sharer1.state.status)
  print("sharer2", sharer2.state.status)
  print("f3", f3.state.status)
  print("f4", f4.state.status)

  assert(f5:wait_for(0.2) == "ready")

  print("sharer1", sharer1.state.status)
  print("sharer2", sharer2.state.status)
  print("f3", f3.state.status)
  print("f4", f4.state.status)

  local f3 = service:deferred(function (promise)
    print("u1a", unix.clock_gettime(unix.CLOCK_REALTIME))
    sharer1:wait_for(0.5)
    print("u1b", unix.clock_gettime(unix.CLOCK_REALTIME))
    promise:set_value(true)
  end)

  local f4 = service:deferred(function (promise)
    print("u2a", unix.clock_gettime(unix.CLOCK_REALTIME))
    sharer2:wait_for(0.3)
    print("u2b", unix.clock_gettime(unix.CLOCK_REALTIME))
    promise:set_value(true)
  end)

  print("f3", f3.state)
  print("f4", f4.state)

  local f5 = service:when_all(f3, f4)
  assert(f5:wait_for(0.2) == "timeout")

  fd2:write("x")

  f5:get()

  service:stop()
  done = true
end))
assert(done)

assert(fd1:close())
assert(fd2:close())
