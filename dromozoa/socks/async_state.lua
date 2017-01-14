-- Copyright (C) 2016,2017 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local pack = require "dromozoa.commons.pack"
local unpack = require "dromozoa.commons.unpack"
local state = require "dromozoa.socks.state"

local class = {}

function class.new(service, task)
  local self = state.new(service)
  self.task = task
  self.task_thread = coroutine.create(function (task)
    local task_result = pack(task:result())
    if self:is_running() then
      self:set(unpack(task_result, 1, task_result.n))
    else
      self.task_result = task_result
    end
  end)
  return self
end

function class:launch()
  state.launch(self)
  local task = self.task
  local task_thread = self.task_thread
  self.task = nil
  self.task_thread = nil
  assert(self.service:add_task(task, task_thread))
end

function class:resume()
  state.resume(self)
  local task_result = self.task_result
  self.task_result = nil
  if task_result then
    self:set(unpack(task_result, 1, task_result.n))
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
