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

local future = require "dromozoa.socks.future"
local sharer_state = require "dromozoa.socks.sharer_state"

local class = {}

function class.new(service, shared_state)
  return {
    service = service;
    shared_state = shared_state;
  }
end

function class:share()
  return future(sharer_state(self.service, self.shared_state))
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, service, shared_state)
    return setmetatable(class.new(service, shared_state), metatable)
  end;
})
