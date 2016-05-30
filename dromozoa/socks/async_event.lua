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

local class = {}

function class.new(fd, type, thread)
  return {
    fd = fd;
    type = type;
    thread = thread;
  }
end

function class:dispatch(service, type)
  return coroutine.resume(self.thread, service, self, type)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, fd, type, thread)
    return setmetatable(class.new(fd, type, thread), metatable)
  end;
})
