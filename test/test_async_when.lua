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

local async_when_state = require "dromozoa.socks.async_when_state"
local async_future = require "dromozoa.socks.async_future"
local async_deferred_state = require "dromozoa.socks.async_deferred_state"
local async_service = require "dromozoa.socks.async_service"

local service = async_service()

local f1 = async_future(async_deferred_state(service, coroutine.create(function (promise)
end)))

local f2 = async_future(async_deferred_state(service, coroutine.create(function (promise)
  promise:set_value(2)
end)))

local f3 = async_future(async_deferred_state(service, coroutine.create(function (promise)
  promise:set_value(3)
end)))

assert(service:dispatch(coroutine.create(function ()
  assert(not f1:is_ready())
  assert(not f2:is_ready())
  assert(not f3:is_ready())

  async_future(async_when_state(service, f1, f2, f3)):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(not f3:is_ready())

  async_future(async_when_state(service, f1, f3)):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  async_future(async_when_state(service, f1)):wait_for(0.2)
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  service:stop()
end)))
