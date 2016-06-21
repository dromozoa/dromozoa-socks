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

  print(unix.clock_gettime(unix.CLOCK_REALTIME))
  print(service:selfpipe():get())
  print(unix.clock_gettime(unix.CLOCK_REALTIME))
  print(service:selfpipe():get())
  print(unix.clock_gettime(unix.CLOCK_REALTIME))

  print(unix.wait(-1))
  print(unix.wait(-1))

  service:stop()
  done = true
end))
assert(done)

unix.selfpipe.close()
