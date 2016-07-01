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

local unpack = require "dromozoa.commons.unpack"
local pack = require "dromozoa.socks.pack"
local state = require "dromozoa.socks.state"

local class = {}

function class.new(service, task)
  local self = state.new(service)
  self.task = task
  self.thread = coroutine.create(function (task)
    local result = pack(task:result())
    if self:is_running() then
      self:set(unpack(result))
    else
      self.result = result
    end
  end)
  return self
end

function class:launch()
  state.launch(self)
  local task = self.task
  self.task = nil
  assert(self.service:add_task(task, self.thread))
end

function class:resume()
  state.resume(self)
  local result = self.result
  self.result = nil
  if result then
    self:set(unpack(result))
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = state;
  __call = function (_, service, task)
    return setmetatable(class.new(service, task), metatable)
  end;
})
