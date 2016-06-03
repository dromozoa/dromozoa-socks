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
local async_future = require "dromozoa.socks.async_future"
local async_service = require "dromozoa.socks.async_service"
local async_state = require "dromozoa.socks.async_state"

local fd1, fd2 = unix.socketpair(unix.AF_UNIX, uint32.bor(unix.SOCK_STREAM, unix.SOCK_CLOEXEC))
assert(fd1:ndelay_on())
assert(fd2:ndelay_off())

local service = async_service()

local state = async_state(fd1, "read", coroutine.create(function (promise)
  local buffer = ""
  while true do
    local char = fd1:read(1)
    if char then
      if char == "\n" then
        promise:set_value(buffer)
        break
      else
        buffer = buffer .. char
      end
    else
      if unix.get_last_errno() == unix.EAGAIN then
        promise = coroutine.yield()
      else
        assert(unix.get_last_error())
      end
    end
  end
end))

local future = async_future(service, state)

assert(service:dispatch(coroutine.create(function ()
  assert(not future:is_ready())
  assert(future:wait(service.timer.current_time:add(0.2)) == "timeout")
  fd2:write("f")
  assert(future:wait(service.timer.current_time:add(0.2)) == "timeout")
  fd2:write("o")
  assert(future:wait(service.timer.current_time:add(0.2)) == "timeout")
  fd2:write("o")
  assert(future:wait(service.timer.current_time:add(0.2)) == "timeout")
  fd2:write("\n")
  assert(future:wait(service.timer.current_time:add(0.2)) == "ready")
  assert(future:is_ready())
  assert(future:get() == "foo")
  fd2:write("bar\n")
  service:stop()
end)))

assert(fd1:close())
assert(fd2:close())
