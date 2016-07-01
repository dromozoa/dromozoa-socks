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
local future_service = require "dromozoa.socks.future_service"

unix.selfpipe.open()

local service = future_service()
local done
assert(service:dispatch(function (service)
  local PATH = os.getenv("PATH")
  local process1 = assert(unix.process():forkexec(PATH, { "sleep", "2" }))
  local process2 = assert(unix.process():forkexec(PATH, { "sleep", "1" }))

  print(process1[1])
  print(process2[1])

  local f1 = service:deferred(function (promise)
    print("f1", unix.clock_gettime(unix.CLOCK_REALTIME))
    print("f1", service:wait(process1[1]):get())
    print("f1", unix.clock_gettime(unix.CLOCK_REALTIME))
    return promise:set("f1")
  end)

  local f2 = service:deferred(function (promise)
    print("f2", unix.clock_gettime(unix.CLOCK_REALTIME))
    print("f2", service:wait(process2[1]):get())
    print("f2", unix.clock_gettime(unix.CLOCK_REALTIME))
    return promise:set("f2")
  end)

  service:when_all(f1, f2):get()

  local f1 = service:deferred(function (promise)
    local process = assert(unix.process():forkexec(PATH, { arg[-1], "-e", "local unix = require \"dromozoa.unix\" for i = 1, 5 do unix.nanosleep(0.2) print(2, i) end" }))
    return promise:set(service:wait(process[1]):get())
  end)

  local f2 = service:deferred(function (promise)
    local process = assert(unix.process():forkexec(PATH, { arg[-1], "-e", "local unix = require \"dromozoa.unix\" for i = 1, 10 do unix.nanosleep(0.2) print(1, i) end" }))
    return promise:set(service:wait(process[1]):get())
  end)

  print("f1.state", f1.state)
  print("f2.state", f2.state)

  service:when_any(f1, f2):get()
  service:when_any(f2):get()

  service:stop()
  done = true
end))
assert(done)

unix.selfpipe.close()
