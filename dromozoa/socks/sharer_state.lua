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

local state = require "dromozoa.socks.state"

local class = {}

function class.new(service, shared_state)
  local self = state.new(service)
  self.shared_state = shared_state
  return self
end

function class:launch()
  state.launch(self)
  self.shared_state:launch(self)
end

function class:suspend()
  state.suspend(self)
  self.shared_state:suspend()
end

function class:resume()
  state.resume(self)
  self.shared_state:resume()
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = state;
  __call = function (_, service, shared_state)
    return setmetatable(class.new(service, shared_state), metatable)
  end;
})
