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
  local futures = {}

  for i = 1, 4 do
    futures[i] = service:accept(fd, uint32.bor(unix.SOCK_NONBLOCK, unix.SOCK_CLOEXEC)):then_(function (future, promise)
      local fd, address = future:get()
      local reader = service:make_reader(fd)
      local writer = service:make_writer(fd)

      while true do
        local result = reader:read_until("\n"):get()
        print("read", result)
        if result == "" then
          break
        end
        writer:write(result:upper()):get()
        print("written")
      end
      assert(fd:close())
      return promise:set()
    end)

    local f = service:when_any_table(futures)
    local k = f:get()
    futures[k] = nil
  end

  service:stop()
end))
