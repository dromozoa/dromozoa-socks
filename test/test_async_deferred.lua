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

local async_future = require "dromozoa.socks.async_future"
local async_deferred = require "dromozoa.socks.async_deferred"
local async_service = require "dromozoa.socks.async_service"

local service = async_service()

local f1 = async_future(async_deferred(service, coroutine.create(function (p)
  print("1a")
  p:set_value(1)
  print("1b")
end)))

local f2 = async_future(async_deferred(service, coroutine.create(function (p)
  print("2a")
  p:set_value(f1:get() + 2)
  print("2b")
end)))

local f3 = async_future(async_deferred(service, coroutine.create(function (p)
  print("3a")
  p:set_value(f2:get() + 3)
  print("3b")
end)))

assert(service:dispatch(coroutine.create(function ()
  print("4a")
  assert(f3:get() == 6)
  print("4b")
  service:stop()
end)))
