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

local nodename, servname = ...
if nodename == "" then
  nodename = nil
end

local service = future_service()

service:dispatch(function (service)
  local futures = {}

  local acceptors = {}
  for fd in assert(service:bind_tcp(nodename, servname):get()):each() do
    acceptors[fd:get()] = fd
    futures[fd:get()] = service:accept(fd)
  end

  while true do
    local f = service:when_any_table(futures)
    local k = f:get()

    local future = futures[k]
    futures[k] = nil

    if acceptors[k] then
      local fd, address = assert(future:get())
      futures[fd:get()] = service:deferred(function (promise)
        print("sock", fd:getsockname():getnameinfo(uint32.bor(unix.NI_NUMERICHOST, unix.NI_NUMERICSERV)))
        print("peer", fd:getpeername():getnameinfo(uint32.bor(unix.NI_NUMERICHOST, unix.NI_NUMERICSERV)))

        local reader = service:make_reader(fd)
        local writer = service:make_writer(fd)
        while true do
          local result = reader:read_until("\n"):get()
          -- print("read", result)
          if result == "" then
            break
          end
          writer:write(result:upper()):get()
          -- print("written")
        end
        assert(fd:close())
        return promise:set(true)
      end)
      futures[k] = service:accept(acceptors[k])
    else
      print(future:get())
    end
  end

  service:stop()
end)
