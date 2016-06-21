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

local fd1, fd2 = unix.pipe()
assert(fd1:ndelay_on())
assert(fd2:ndelay_on())

local service = future_service()

local done
assert(service:dispatch(function (service)
  local f = service:read(fd1, 16)
  assert(f:wait_for(0.2) == "timeout")
  assert(fd1:close())
  assert(fd2:close())
  local result, message = pcall(function ()
    return f:get()
  end)
  assert(not result)
  print(message)

  service:stop()
  done = true
end))
assert(done)
