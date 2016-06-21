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

-- local host = "10.211.55.30"
-- local host = "49.212.170.128"
local host = localhost
local addrinfo = assert(unix.getaddrinfo(host, "4242", {
  ai_family = unix.AF_INET;
  ai_socktype = unix.SOCK_STREAM;
}))
local ai = addrinfo[1]
local fd = assert(unix.socket(ai.ai_family, uint32.bor(ai.ai_socktype, unix.SOCK_NONBLOCK, unix.SOCK_CLOEXEC), ai.ai_protocol))

local service = future_service()
assert(service:dispatch(function (service)
  print(service:connect(fd, ai.ai_addr):get())

  print(fd:getsockname():getnameinfo(uint32.bor(unix.NI_NUMERICHOST, unix.NI_NUMERICSERV)))
  print(fd:getpeername():getnameinfo(uint32.bor(unix.NI_NUMERICHOST, unix.NI_NUMERICSERV)))

  local f0 = service:deferred(function (promise)
  end)

  local f1 = service:deferred(function (promise)
    -- local data = (("x"):rep(1022) .. "\r\n"):rep(1024)
    for i = 1, 8 do
      local data = "foo\n"
      local i = 1
      local j = #data
      while i <= j do
        local n = service:write(fd, data, i, j):get()
        i = i + n
        print("written", i, j)
      end
      f0:wait_for(0.5)
    end
    assert(fd:shutdown(unix.SHUT_WR))
    promise:set_value(true)
  end)

  local f2 = service:deferred(function (promise)
    while true do
      local f = service:read(fd, 1500)
      if f:wait_for(10) == "timeout" then
        print("timeout")
        break
      end
      local result = f:get()
      print("read", #result)
      if result == "" then
        break
      end
    end
    promise:set_value(true)
  end)

  service:when_all(f1, f2):get()
  service:stop()
end))

assert(fd:close())
