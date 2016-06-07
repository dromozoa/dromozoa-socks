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
local pack = require "dromozoa.socks.pack"
local state = require "dromozoa.socks.state"

local function count_down(self)
  self.count = self.count - 1
  if self.count == 0 then
    self:set_value(unpack(self.futures))
    return true
  else
    return false
  end
end

local function each_state(self)
  return coroutine.wrap(function ()
    for _, future in ipairs(self.futures) do
      coroutine.yield(future.state)
    end
  end)
end

local class = {}

function class.new(count, future, ...)
  local self = state.new(future.state.service)
  self.futures = pack(future, ...)
  if count == "n" then
    self.count = self.futures.n
  else
    self.count = count
  end
  self.counter = coroutine.create(function ()
    count_down(self)
  end)
  return self
end

function class:launch()
  for state in each_state(self) do
    if state:is_ready() then
      if count_down(self) then
        return
      end
    end
  end
  for state in each_state(self) do
    state:launch()
    if state:is_ready() then
      if count_down(self) then
        return
      end
    end
  end
  for state in each_state(self) do
    state.thread = self.counter
  end
end

function class:finish(delete_timer_handle)
  for state in each_state(self) do
    state:finish(delete_timer_handle)
  end
  return state.finish(self, delete_timer_handle)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = state;
  __call = function (_, when, ...)
    return setmetatable(class.new(when, ...), metatable)
  end;
})
