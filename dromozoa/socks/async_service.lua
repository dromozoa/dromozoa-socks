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
local timer_service = require "dromozoa.socks.timer_service"

local function add_reader(self, reader)
  local fd = unix.fd.get(reader.fd)
  if self.writers[fd] == nil then
    if not self.selector:add(fd, unix.SELECTOR_READ) then
      return unix.get_last_error()
    end
  else
    if not self.selector:mod(fd, unix.SELECTOR_READ_WRITE) then
      return unix.get_last_error()
    end
  end
  self.readers[fd] = reader
  reader.status = true
  return self
end

local function add_writer(self, writer)
  local fd = unix.fd.get(writer.fd)
  if self.readers[fd] == nil then
    if not self.selector:add(fd, unix.SELECTOR_WRITE) then
      return unix.get_last_error()
    end
  else
    if not self.selector:mod(fd, unix.SELECTOR_READ_WRITE) then
      return unix.get_last_error()
    end
  end
  self.writers[fd] = writer
  writer.status = true
  return self
end

local function del_reader(self, reader)
  local fd = unix.fd.get(reader.fd)
  if self.writers[fd] == nil then
    if not self.selector:del(fd) then
      return unix.get_last_error()
    end
  else
    if not self.selector:mod(fd, unix.SELECTOR_WRITE) then
      return unix.get_last_error()
    end
  end
  self.readers[fd] = nil
  reader.status = nil
  return self
end

local function del_writer(self, writer)
  local fd = unix.fd.get(writer.fd)
  if self.readers[fd] == nil then
    if not self.selector:del(fd) then
      return unix.get_last_error()
    end
  else
    if not self.selector:mod(fd, unix.SELECTOR_READ) then
      return unix.get_last_error()
    end
  end
  self.writers[fd] = nil
  writer.status = nil
  return self
end

local class = {}

function class.new()
  return {
    selector = unix.selector();
    selector_timeout = unix.timespec(0.02, unix.TIMESPEC_TYPE_DURATION);
    timer = timer_service();
    readers = {};
    writers = {};
  }
end

function class:add(handler)
  local event = handler.event
  if event == "read" then
    return add_reader(self, handler)
  elseif event == "write" then
    return add_writer(self, handler)
  end
end

function class:del(handler)
  local event = handler.event
  if event == "read" then
    return del_reader(self, handler)
  elseif event == "write" then
    return del_writer(self, handler)
  end
end

function class:start()
  self.stopped = nil
  return self
end

function class:stop()
  self.stopped = true
  return self
end

function class:dispatch(thread)
  if thread then
    local result, message = coroutine.resume(thread)
    if not result then
      return nil, message
    end
    if self.stopped then
      return self
    end
  end
  while true do
    local result, message = self.timer:dispatch()
    if not result then
      return nil, message
    end
    if self.stopped then
      return self
    end
    local result = self.selector:select(self.selector_timeout)
    if not result then
      if unix.get_last_errno() ~= unix.EINTR then
        return unix.get_last_error()
      end
    else
      self.timer:update()
      for i = 1, result do
        local fd, event = self.selector:event(i)
        if uint32.band(event, unix.SELECTOR_READ) ~= 0 then
          local result, message = self.readers[fd]:dispatch(self, "read")
          if not result then
            return nil, message
          end
        end
        if uint32.band(event, unix.SELECTOR_WRITE) ~= 0 then
          local result, message = self.writers[fd]:dispatch(self, "write")
          if not result then
            return nil, message
          end
        end
      end
      if self.stopped then
        return self
      end
    end
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
