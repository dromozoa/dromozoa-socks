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

local service = future_service()

local T = {
  { 0.1, 0.3, 0.5 };
  { 0.5, 0.3, 0.1 };
  { 0.3, 0.5, 0.1 };
}

for i = 1, #T do
  local t1 = T[i][1]
  local t2 = T[i][2]
  local t3 = T[i][3]

  print("--")
  assert(service:dispatch(function (service)
    service:start()

    local f0 = service:deferred(function (promise)
    end)

    local f1 = service:deferred(function (promise)
      local timer = unix.timer():start()
      f0:wait_for(t1)
      local elapsed = timer:stop():elapsed()
      print("1:", elapsed, t1)
      promise:set()
    end)

    local f2 = service:deferred(function (promise)
      local timer = unix.timer():start()
      f1:wait_for(t2)
      local elapsed = timer:stop():elapsed()
      print("2:", elapsed, t2)
      promise:set()
    end)

    local timer = unix.timer():start()
    f2:wait_for(t3)
    local elapsed = timer:stop():elapsed()
    print("3:", elapsed, t3)

    local timer = unix.timer():start()
    f2:wait()
    local elapsed = timer:stop():elapsed()
    print("3:", elapsed)

    service:stop()
  end))
end
