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

local nodename, servname = ...

local service = future_service()
service:dispatch(function (service)
  local fd = assert(service:connect_tcp(nodename, servname):get())

  local f1 = service:deferred(function (promise)
    local writer = service:make_writer(fd)
    writer:write((("x"):rep(80) .. "z\n"):rep(10)):get()
    print("written")
    assert(fd:shutdown(unix.SHUT_WR))
    print("shut_wr")
    return promise:set()
  end)

  local f2 = service:deferred(function(promise)
    local reader = service:make_reader(fd)
    while true do
      local result, capture = reader:read_until("Z"):get()
      print("read", result, capture)
      if result == "" then
        break
      end
    end
    return promise:set()
  end)

  service:when_all(f1, f2):get()
  f1:get()
  f2:get()
  assert(fd:close())

  service:stop()
end)
