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

local future_service = require "dromozoa.socks.future_service"

local service = future_service()

assert(service:dispatch(coroutine.create(function (service)
  local f0 = service:deferred(function (promise)
  end)

  local f1 = service:deferred(function (promise)
    assert(f0:wait_for(0.5) == "timeout")
    promise:set_value(1)
  end)

  local f2 = service:deferred(function (promise)
    promise:set_value(2)
  end)

  local f3 = service:deferred(function (promise)
    promise:set_value(3)
  end)

  assert(not f1:is_ready())
  assert(not f2:is_ready())
  assert(not f3:is_ready())

  service:when_any(f1, f2, f3):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(not f3:is_ready())

  service:when_any(f1, f2, f3):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(not f3:is_ready())

  service:when_any(f1, f3):wait()
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  assert(service:when_any(f1):wait_for(0.2) == "timeout")
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  assert(service:when_any(f1):wait_for(0.5) == "ready")
  assert(f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  local f1 = service:deferred(function (promise)
    assert(f0:wait_for(0.5) == "timeout")
    promise:set_value(1)
  end)

  local f2 = service:deferred(function (promise)
    promise:set_value(2)
  end)

  local f3 = service:deferred(function (promise)
    promise:set_value(3)
  end)

  assert(not f1:is_ready())
  assert(not f2:is_ready())
  assert(not f3:is_ready())

  assert(service:when_all(f1, f2, f3):wait_for(0.2) == "timeout")
  assert(not f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  assert(service:when_all(f1, f2, f3):wait_for(0.5) == "ready")
  assert(f1:is_ready())
  assert(f2:is_ready())
  assert(f3:is_ready())

  service:stop()
end)))
