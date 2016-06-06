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
local async_promise = require "dromozoa.socks.async_promise"
local async_state = require "dromozoa.socks.async_deferred_state"
local pack = require "dromozoa.socks.pack"

local class = {}

function class.new(service, ...)
  local self = async_state.new(service)
  local futures = pack(...)
  local states = sequence()
  for future in sequence.each(futures) do
    states:push(future.state)
  end
  self.futures = futures
  self.states = states
  self.worker = coroutine.create(function ()
    self:set_value(self.futures)
  end)
  return self
end

function class:launch()
  for state in self.states:each() do
    if state:is_ready() then
      self:set_value(self.futures)
      return
    end
  end
  for state in self.states:each() do
    state:launch()
    if state:is_ready() then
      self:set_value(self.futures)
      return
    end
  end
  for state in self.states:each() do
    state.thread = self.worker
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = async_state;
  __call = function (_, service, ...)
    return setmetatable(class.new(service, ...), metatable)
  end;
})
