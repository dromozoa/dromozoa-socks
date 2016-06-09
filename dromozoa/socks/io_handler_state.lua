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

local create_thread = require "dromozoa.socks.create_thread"
local io_handler = require "dromozoa.socks.io_handler"
local promise = require "dromozoa.socks.promise"
local state = require "dromozoa.socks.state"

local class = {}

function class.new(service, fd, event, thread)
  local self = state.new(service)
  self.thread = create_thread(thread)
  self.handler = io_handler(fd, event, coroutine.create(function ()
    local promise = promise(self)
    while true do
      self.service:before_resume_thread(self)
      local result, message = coroutine.resume(self.thread, promise)
      if not result then
        self:set_error(message)
      end
      if self:is_ready() then
        return
      end
      coroutine.yield()
    end
  end))
  return self
end

function class:launch()
  assert(self.service:add_handler(self.handler))
end

function class:finish(status)
  assert(self.service:delete_handler(self.handler))
  return state.finish(self, status)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __index = state;
  __call = function (_, service, fd, event, thread)
    return setmetatable(class.new(service, fd, event, thread), metatable)
  end;
})
