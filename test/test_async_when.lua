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

local deferred_state = require "dromozoa.socks.deferred_state"
local future = require "dromozoa.socks.future"
local future_service = require "dromozoa.socks.future_service"
local latch_state = require "dromozoa.socks.latch_state"

local service = future_service()

assert(service:dispatch(coroutine.create(function ()
  local f0 = future(deferred_state(service, coroutine.create(function (promise)
  end)))

  local f1 = future(deferred_state(service, coroutine.create(function (promise)
    f0:wait_for(0.5)
    promise:set_value(1)
  end)))

  local f2 = future(deferred_state(service, coroutine.create(function (promise)
    promise:set_value(2)
  end)))

  local f3 = future(deferred_state(service, coroutine.create(function (promise)
    promise:set_value(3)
  end)))

  assert(not f1:is_ready())
  assert(not f2:is_ready())
  assert(not f3:is_ready())

  future(latch_state(1, f1, f2, f3)):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(not f3:is_ready())

  future(latch_state(1, f1, f3)):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  assert(future(latch_state(1, f1)):wait_for(0.2) == "timeout")
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  assert(future(latch_state(1, f1)):wait_for(0.5) == "ready")
  assert(f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  local f1 = future(deferred_state(service, coroutine.create(function (promise)
    f0:wait_for(0.5)
    promise:set_value(1)
  end)))

  local f2 = future(deferred_state(service, coroutine.create(function (promise)
    promise:set_value(2)
  end)))

  local f3 = future(deferred_state(service, coroutine.create(function (promise)
    promise:set_value(3)
  end)))

  assert(not f1:is_ready())
  assert(not f2:is_ready())
  assert(not f3:is_ready())

  assert(future(latch_state("n", f1, f2, f3)):wait_for(0.2) == "timeout")
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  assert(future(latch_state("n", f1, f2, f3)):wait_for(0.5) == "ready")
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  service:stop()
end)))
