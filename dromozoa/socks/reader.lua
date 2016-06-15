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

local stream_buffer = require "dromozoa.socks.stream_buffer"

local class = {}

function class.new(service, fd)
  return {
    service = service;
    fd = fd;
    stream_buffer = stream_buffer();
  }
end

function class:read(count)
  return self:deferred(function (promise)
    while true do
      local result = self.stream_buffer:read(count)
      if result ~= nil then
        return promise:set_value(result)
      end
      self.service:io_handler(fd, "read", function (promise)
      end)
    end
  end)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, state)
    return setmetatable(class.new(state), metatable)
  end;
})
