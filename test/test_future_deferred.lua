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

local service = future_service()

local done
assert(not done)
assert(service:dispatch(function (service)
  local f1 = service:deferred(function (promise)
    print("1a")
    promise:set_value(1)
    print("1b")
  end)
  local f2 = service:deferred(function (promise)
    print("2a")
    promise:set_value(f1:get() + 2)
    print("2b")
  end)
  local f3 = service:deferred(function (promise)
    print("3a")
    promise:set_value(f2:get() + 3)
    print("3b")
  end)
  print("4a")
  assert(f3:get() == 6)
  print("4b")
  service:stop()
  done = true
end))
assert(done)

local fd1, fd2 = unix.socketpair(unix.AF_UNIX, uint32.bor(unix.SOCK_STREAM, unix.SOCK_CLOEXEC))
assert(fd1:ndelay_on())
assert(fd2:ndelay_off())

local done
assert(not done)
assert(service:dispatch(function (service)
  service:start()

  local f1 = service:io_handler(fd1, "read", function (promise)
    while true do
      local char = fd1:read(1)
      if char then
        return promise:set_value(char)
      else
        if unix.get_last_error() == unix.EAGAIN then
          promise = coroutine.yield()
        else
          assert(unix.get_last_error())
        end
      end
    end
  end)

  local f2 = service:deferred(function (promise)
    print("2a")
    assert(f1:wait_for(0.5) == "timeout")
    print("2b")
    return promise:set_value(42)
  end)

  assert(f2:wait_for(0.2) == "timeout")
  assert(f2:wait_for(0.5) == "ready")
  assert(f2:get() == 42)
  service:stop()

  done = true
end))
assert(done)

assert(fd1:close())
assert(fd2:close())
