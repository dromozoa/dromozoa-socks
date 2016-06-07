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

local uint32 = require "dromozoa.commons.uint32"
local unix = require "dromozoa.unix"

local class = {}

function class.new()
  return {
    selector = unix.selector();
    selector_timeout = unix.timespec(0.02, unix.TIMESPEC_TYPE_DURATION);
    read_handlers = {};
    write_handlers = {};
  }
end

function class:add_handler(handler)
  local fd = unix.fd.get(handler.fd)
  local event = handler.event
  if event == "read" then
    if self.write_handlers[fd] == nil then
      if not self.selector:add(fd, unix.SELECTOR_READ) then
        return unix.get_last_error()
      end
    else
      if not self.selector:mod(fd, unix.SELECTOR_READ_WRITE) then
        return unix.get_last_error()
      end
    end
    self.read_handlers[fd] = handler
    handler.status = true
    return self
  elseif event == "write" then
    if self.read_handlers[fd] == nil then
      if not self.selector:add(fd, unix.SELECTOR_WRITE) then
        return unix.get_last_error()
      end
    else
      if not self.selector:mod(fd, unix.SELECTOR_READ_WRITE) then
        return unix.get_last_error()
      end
    end
    self.write_handlers[fd] = handler
    handler.status = true
    return self
  end
end

function class:delete_handler(handler)
  local fd = unix.fd.get(handler.fd)
  local event = handler.event
  if event == "read" then
    if self.write_handlers[fd] == nil then
      if not self.selector:del(fd) then
        return unix.get_last_error()
      end
    else
      if not self.selector:mod(fd, unix.SELECTOR_WRITE) then
        return unix.get_last_error()
      end
    end
    self.read_handlers[fd] = nil
    handler.status = nil
    return self
  elseif event == "write" then
    if self.read_handlers[fd] == nil then
      if not self.selector:del(fd) then
        return unix.get_last_error()
      end
    else
      if not self.selector:mod(fd, unix.SELECTOR_READ) then
        return unix.get_last_error()
      end
    end
    self.write_handlers[fd] = nil
    handler.status = nil
    return self
  end
end

function class:empty()
  return next(self.read_handlers) == nil and next(self.write_handlers) == nil
end

function class:dispatch()
  local result = self.selector:select(self.selector_timeout)
  if not result then
    if unix.get_last_errno() ~= unix.EINTR then
      return unix.get_last_error()
    end
  else
    for i = 1, result do
      local fd, event = self.selector:event(i)
      if uint32.band(event, unix.SELECTOR_READ) ~= 0 then
        local result, message = self.read_handlers[fd]:dispatch(self, "read")
        if not result then
          return nil, message
        end
      end
      if uint32.band(event, unix.SELECTOR_WRITE) ~= 0 then
        local result, message = self.write_handlers[fd]:dispatch(self, "write")
        if not result then
          return nil, message
        end
      end
    end
  end
  return self
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
