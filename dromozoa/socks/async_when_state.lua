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

local ipairs = require "dromozoa.commons.ipairs"
local unpack = require "dromozoa.commons.unpack"
local async_state = require "dromozoa.socks.async_deferred_state"
local pack = require "dromozoa.socks.pack"

local class = {}

function class.new(service, when, ...)
  local self = async_state.new(service)
  self.futures = pack(...)
  self.worker = coroutine.create(function ()
    self:set_value(unpack(self.futures))
  end)
  return self
end

function class:each_state()
  return coroutine.wrap(function ()
    for _, future in ipairs(self.futures) do
      coroutine.yield(future.state)
    end
  end)
end

function class:launch()
  for state in self:each_state() do
    if state:is_ready() then
      self:set_value(unpack(self.futures))
      return
    end
  end
  for state in self:each_state() do
    state:launch()
    if state:is_ready() then
      self:set_value(unpack(self.futures))
      return
    end
  end
  for state in self:each_state() do
    state.thread = self.worker
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = async_state;
  __call = function (_, service, when, ...)
    return setmetatable(class.new(service, when, ...), metatable)
  end;
})
