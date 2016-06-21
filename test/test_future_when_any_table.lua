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

local done
assert(service:dispatch(function (service)
  local f0 = service:deferred(function (promise)
  end)

  local futures = {
    foo = service:deferred(function (promise)
      assert(f0:wait_for(0.5) == "timeout")
      promise:set_value("bar")
    end);
    [1] = service:deferred(function (promise)
      promise:set_value(42)
    end);
    [2] = service:deferred(function (promise)
      promise:set_value({})
    end);
  }

  local k = service:when_any_table(futures):get()
  assert(k == 1 or k == 2)
  print(k)
  print(futures[k]:get())
  futures[k] = nil

  local k = service:when_any_table(futures):get()
  assert(k == 1 or k == 2)
  print(k)
  print(futures[k]:get())
  futures[k] = nil

  local k = service:when_any_table(futures):get()
  assert(k == "foo")
  print(k)
  print(futures[k]:get())
  futures[k] = nil

  assert(next(futures) == nil)

  service:stop()
  done = true
end))
assert(done)
