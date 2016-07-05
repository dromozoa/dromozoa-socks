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

local equal = require "dromozoa.commons.equal"
local sequence = require "dromozoa.commons.sequence"
local uint32 = require "dromozoa.commons.uint32"
local unix = require "dromozoa.unix"
local future_service = require "dromozoa.socks.future_service"

local fd1, fd2 = unix.socketpair(unix.AF_UNIX, uint32.bor(unix.SOCK_STREAM, unix.SOCK_CLOEXEC))
assert(fd1:ndelay_on())
assert(fd2:ndelay_off())

local service = future_service()

local done
assert(service:dispatch(function (service)
  local sr = service:make_shared_reader(fd1)

  local result = sequence()

  local f = service:deferred(function (promise)
  end)

  local f1 = service:deferred(function (promise)
    local r = sr:share()
    result:push("f1", r:read_until("X"):get())
    result:push("f1", r:read_until("X"):get())
    result:push("f1", r:read_until("X"):get())
    return promise:set("f1")
  end)

  local f2 = service:deferred(function (promise)
    local r = sr:share()
    result:push("f2", r:read(3):get())
    result:push("f2", r:read(3):get())
    result:push("f2", r:read(3):get())
    result:push("f2", r:read(2):get())
    return promise:set("f2")
  end)

  local f3 = service:deferred(function (promise)
    f:wait_for(0.1)
    fd2:write("f")
    f:wait_for(0.1)
    fd2:write("o")
    f:wait_for(0.1)
    fd2:write("o")
    f:wait_for(0.1)
    fd2:write("X")
    f:wait_for(0.1)
    fd2:write("b")
    f:wait_for(0.1)
    fd2:write("a")
    f:wait_for(0.1)
    fd2:write("r")
    f:wait_for(0.1)
    fd2:write("X")
    f:wait_for(0.1)
    fd2:write("b")
    f:wait_for(0.1)
    fd2:write("a")
    f:wait_for(0.1)
    fd2:write("z")
    f:wait_for(0.1)
    fd2:write("X")
    return promise:set("f3")
  end)

  service:when_all(f1, f2, f3):get()
  f1:get()
  f2:get()
  f3:get()

  assert(equal(result, {
    "f2", "foo",
    "f1", "foo",
    "f2", "Xba",
    "f1", "bar",
    "f2", "rXb",
    "f2", "az",
    "f1", "baz",
  }))

  service:stop()
  done = true
end))
assert(done)

assert(fd1:close())
assert(fd2:close())
