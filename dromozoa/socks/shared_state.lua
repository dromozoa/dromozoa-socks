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

local sequence = require "dromozoa.commons.sequence"
local unpack = require "dromozoa.commons.unpack"

local function propagate(self)
  local that = self.future.state
  assert(that:is_ready())
  for sharer_state in self.sharer_states:each() do
    assert(sharer_state:is_running() or sharer_state:is_suspended())
    if sharer_state:is_running() then
      if that.message ~= nil then
        sharer_state:set_error(that.message)
      else
        sharer_state:set_value(unpack(that.value))
      end
    end
  end
end

local class = {}

function class.new(future)
  local self = {
    future = future;
    sharer_states = sequence();
  }
  self.propagator = coroutine.create(function ()
    propagate(self)
  end)
  return self
end

function class:launch(sharer_state)
  local that = self.future.state
  self.sharer_states:push(sharer_state)
  if that:is_ready() then
    propagate(self)
  elseif that:is_initial() or that:is_suspended() then
    local current_state = sharer_state.service:get_current_state()
    sharer_state.service:set_current_state(nil)
    if that:dispatch() then
      propagate(self)
    else
      that.caller = self.propagator
    end
    sharer_state.service:set_current_state(current_state)
  end
end

function class:suspend()
  local that = self.future.state
  assert(that:is_running())
  local is_running = false
  for sharer_state in self.sharer_states:each() do
    assert(sharer_state:is_running() or sharer_state:is_suspended())
    if sharer_state:is_running() then
      is_running = true
      break
    end
  end
  if not is_running then
    that:suspend()
  end
end

function class:resume()
  local that = self.future.state
  if that:is_ready() then
    propagate(self)
  elseif that:is_suspended() then
    that:resume()
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, future)
    return setmetatable(class.new(future), metatable)
  end;
})
