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
  self.thread = coroutine.create(function ()
    local result = pack(self.task:result())
    self.task = nil
    if self:is_running() then
      if result[1] == nil then
        self:set_error(result[2])
      else
        self:set_value(unpack(result))
      end
    else
      self.task_result = result
    end
  end)
  return self
end

function class:launch()
  state.launch(self)
  assert(self.service:add_task(self.task, self.thread))
end

function class:resume()
  state.resume(self)
  local result = self.task_result
  self.task_result = nil
  if result then
    if result[1] == nil then
      self:set_error(result[2])
    else
      self:set_value(unpack(result))
    end
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
