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

local reader_buffer = require "dromozoa.socks.reader_buffer"

local BUFFER_SIZE = 256

local class = {}

function class.new(service, fd)
  return {
    service = service;
    fd = fd;
    buffer = reader_buffer();
  }
end

function class:read(count)
  return self.service:deferred(function (promise)
    while true do
      local result = self.buffer:read(count)
      if result then
        return promise:set_value(result)
      end
      local result = self.service:read(self.fd, BUFFER_SIZE):get()
      if result == "" then
        self.buffer:close()
      else
        self.buffer:write(result)
      end
    end
  end)
end

function class:read_some(count)
  return self.service:deferred(function (promise)
    return promise:set_value(self.buffer:read_some(count))
  end)
end

function class:read_any(count)
  return self.service:deferred(function (promise)
    while true do
      local result = self.buffer:read_some(count)
      if result ~= "" or self.buffer.closed then
        return promise:set_value(result)
      end
      local result = self.service:read(self.fd, BUFFER_SIZE):get()
      if result == "" then
        self.buffer:close()
      else
        self.buffer:write(result)
      end
    end
  end)
end

function class:read_until(pattern)
  return self.service:deferred(function (promise)
    while true do
      local result, capture = self.buffer:read_until(pattern)
      if result then
        return promise:set_value(result, capture)
      end
      local result = self.service:read(self.fd, BUFFER_SIZE):get()
      if result == "" then
        self.buffer:close()
      else
        self.buffer:write(result)
      end
    end
  end)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, service, fd)
    return setmetatable(class.new(service, fd), metatable)
  end;
})
