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
local future_service = require "dromozoa.socks.future_service"

local function check(n, ...)
  assert(select("#", ...) == n)
end

future_service():dispatch(function (service)
  local f = service:deferred(function (promise)
    assert(equal({ promise:assert(1, 2, 3) }, { 1, 2, 3 }))
    local f = function ()
      promise:assert(false, "foo")
    end
    f()
    error("unreachable")
  end)

  print(f:get())

  local f = service:deferred(function (promise)
    local f = service:deferred(function (promise)
      return promise:set(42)
    end)
    check(1, promise:assert(f:get()))
    return promise:set(42)
  end)

  f:get()

  service:stop()
end)

local thread = coroutine.create(function ()
  local f = function ()
    assert(false, "foo")
  end
  f()
end)
print(coroutine.resume(thread))
