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
local multimap = require "dromozoa.socks.multimap"

local function get_selector_event(self, fd)
  local selector_event = 0
  if self.read_events[fd] ~= nil then
    selector_event = uint32.bor(selector_event, unix.SELECTOR_READ)
  end
  if self.write_events[fd] ~= nil then
    selector_event = uint32.bor(selector_event, unix.SELECTOR_WRITE)
  end
  return selector_event
end

local class = {}

function class.new()
  return {
    current_time = unix.clock_gettime(unix.CLOCK_MONOTONIC_RAW);
    selector = unix.selector();
    selector_timeout = unix.timespec(0.02, unix.TIMESPEC_TYPE_DURATION);
    read_events = {};
    write_events = {};
    timeout_events = multimap();
  }
end

function class:add(event, timeout)
  if event.fd ~= nil then
    local fd = event.fd:get()
    local old_selector_event = get_selector_event(self, fd)
    if event.event == "read" then
      self.read_events[fd] = event
    elseif event.event == "write" then
      self.write_events[fd] = event
    end
    local new_selector_event = get_selector_event(self, fd)
    if old_selector_event == 0 then
      self.selector:add(fd, new_selector_event)
    else
      self.selector:mod(fd, new_selector_event)
    end
  end
  if timeout ~= nil then
    event.timeout_handle = self.timeout_events:insert(timeout, event)
  end
  return self
end

function class:del(event)
  if event.fd ~= nil then
    local fd = event.fd:get()
    if event.event == "read" then
      self.read_events[fd] = nil
    elseif event.event == "write" then
      self.write_events[fd] = nil
    end
    local new_selector_event = get_selector_event(self, fd)
    if new_selector_event == 0 then
      self.selector:del(fd)
    else
      self.selector:mod(fd, new_selector_event)
    end
  end
  if event.timeout_handle ~= nil then
    event.timeout_handle:delete()
    event.timeout_handle = nil
  end
  return self
end

function class:stop()
  self.stopped = true
  return self
end

function class:dispatch()
  self.stopped = false
  while not self.stopped do
    self.current_time = unix.clock_gettime(unix.CLOCK_MONOTONIC_RAW)
    for _, event in self.timeout_events:upper_bound(self.current_time):each() do
      event.callback(self, event, "timeout")
    end
    local result = self.selector:select(self.selector_timeout)
    if result == nil then
      if unix.get_last_errno() ~= unix.EINTR then
        return unix.get_last_error()
      end
    else
      self.current_time = unix.clock_gettime(unix.CLOCK_MONOTONIC_RAW)
      for i = 1, result do
        local fd, selector_event = self.selector:event(i)
        if uint32.band(selector_event, unix.SELECTOR_READ) ~= 0 then
          local event = self.read_events[fd]
          event.callback(self, event, "read")
        end
        if uint32.band(selector_event, unix.SELECTOR_WRITE) ~= 0 then
          local event = self.write_events[fd]
          event.callback(self, event, "write")
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
  __call = function (_, selector)
    return setmetatable(class.new(selector), metatable)
  end;
})
