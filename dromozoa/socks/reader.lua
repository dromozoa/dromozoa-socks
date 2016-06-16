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

local unix = require "dromozoa.unix"
local make_ready_future = require "dromozoa.socks.make_ready_future"
local stream_buffer = require "dromozoa.socks.stream_buffer"

local BUFFER_SIZE = 256

local function read(self, f)
  local result = f(self.stream_buffer)
  if result then
    return make_ready_future(result)
  else
    return self.service:io_handler(self.fd, "read", function (promise)
      while true do
        local result = self.fd:read(BUFFER_SIZE)
        if result then
          if result == "" then
            self.stream_buffer:close()
          else
            self.stream_buffer:write(result)
          end
          local result = f(self.stream_buffer)
          if result then
            -- should return capture
            return promise:set_value(result)
          end
        else
          if unix.get_last_errno() == unix.EAGAIN then
            promise = coroutine.yield()
          else
            return promise:set_error(unix.strerror(unix.get_last_errno()))
          end
        end
      end
    end)
  end
end

local class = {}

function class.new(service, fd)
  assert(fd:is_ndelay_on())
  return {
    service = service;
    fd = fd;
    stream_buffer = stream_buffer();
  }
end

function class:read(count)
  return read(self, function (stream_buffer)
    return stream_buffer:read(count)
  end)
end

function class:read_some(count)
  return read(self, function (stream_buffer)
    return stream_buffer:read_some(count)
  end)
end

function class:read_until(pattern)
  return read(self, function (stream_buffer)
    return stream_buffer:read_until(pattern)
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
