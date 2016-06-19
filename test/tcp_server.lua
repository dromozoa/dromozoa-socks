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

local addrinfo = assert(unix.getaddrinfo(nil, "4242", {
  ai_family = unix.AF_INET;
  ai_socktype = unix.SOCK_STREAM;
  ai_hints = AF_PASSIVE;
}))
local ai = addrinfo[1]
local fd = assert(unix.socket(ai.ai_family, uint32.bor(ai.ai_socktype, unix.SOCK_NONBLOCK, unix.SOCK_CLOEXEC), ai.ai_protocol))

assert(fd:setsockopt(unix.SOL_SOCKET, unix.SO_REUSEADDR, 1))
assert(fd:bind(ai.ai_addr))
assert(fd:listen())

local service = future_service()
assert(service:dispatch(function (service)
  local f1 = service:accept(fd, uint32.bor(unix.SOCK_NONBLOCK, unix.SOCK_CLOEXEC))

  local f2 = f1:then_(function (f, p)
    local fd, address = f:get()
    while true do
      local f = service:read(fd, 1500)
      print("rf", f.state, f.state.status)
      if f:wait_for(1000) == "timeout" then
        print("timeout")
        break
      end
      print("rf", f.state, f.state.status)
      local result = f:get()
      print("read", #result)
      if result == "" then
        break
      end
      local i = 1
      local j = #result
      while i <= j do
        local n = service:write(fd, result, i, j):get()
        i = i + n
        print("written", i, j)
      end
    end
    assert(fd:close())
    return p:set_value()
  end)

  print("f1", f1.state)
  print("f2", f2.state)

  f2:get()
  service:stop()
end))
