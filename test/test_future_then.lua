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

assert(future_service():dispatch(function (service)
  assert(service:deferred(function (promise)
    promise:set_value(1)
  end):then_(function (future, promise)
    return promise:set_value(future:get() + 2)
  end):then_(function (future, promise)
    return promise:set_value(future:get() + 3)
  end):get() == 6)
  service:stop()
end))
