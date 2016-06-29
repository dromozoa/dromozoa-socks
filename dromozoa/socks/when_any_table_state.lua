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

local pairs = require "dromozoa.commons.pairs"
local state = require "dromozoa.socks.state"

local function each_state(self)
  return coroutine.wrap(function ()
    for key, future in pairs(self.futures) do
      coroutine.yield(key, future.state)
    end
  end)
end

local class = {}

function class.new(service, futures)
  local self = state.new(service)
  self.futures = futures
  return self
end

function class:launch()
  state.launch(self)
  local current_state = self.service:get_current_state()
  for key, that in each_state(self) do
    self.service:set_current_state(nil)
    if that:dispatch() then
      self:set_value(key)
      break
    else
      that.caller = coroutine.create(function ()
        self:set_value(key)
      end)
    end
  end
  self.service:set_current_state(current_state)
end

function class:suspend()
  state.suspend(self)
  for _, that in each_state(self) do
    assert(that:is_running() or that:is_ready())
    if that:is_running() then
      that:suspend()
    end
  end
end

function class:resume()
  state.resume(self)
  for _, that in each_state(self) do
    assert(that:is_suspended() or that:is_ready())
    if that:is_suspended() then
      that:resume()
    end
  end
end

function class:finish()
  state.finish(self)
  for _, that in each_state(self) do
    assert(that:is_initial() or that:is_running() or that:is_ready())
    if that:is_running() then
      that:suspend()
    end
    that.caller = nil
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = state;
  __call = function (_, service, futures)
    return setmetatable(class.new(service, futures), metatable)
  end;
})
