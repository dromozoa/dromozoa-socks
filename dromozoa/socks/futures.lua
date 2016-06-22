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

local translate_range = require "dromozoa.commons.translate_range"
local unix = require "dromozoa.unix"
local future = require "dromozoa.socks.future"
local deferred_state = require "dromozoa.socks.deferred_state"
local io_handler_state = require "dromozoa.socks.io_handler_state"
local latch_state = require "dromozoa.socks.latch_state"
local make_ready_future = require "dromozoa.socks.make_ready_future"
local reader = require "dromozoa.socks.reader"
local shared_future = require "dromozoa.socks.shared_future"
local shared_state = require "dromozoa.socks.shared_state"
local when_any_table_state = require "dromozoa.socks.when_any_table_state"

local function is_resource_unavailable_try_again()
  local code = unix.get_last_errno()
  return code == unix.EAGAIN or code == unix.EWOULDBLOCK
end

local class = {}

function class.deferred(service, thread)
  return future(deferred_state(service, thread))
end

function class.io_handler(service, fd, event, thread)
  return future(io_handler_state(service, fd, event, thread))
end

function class.when_all(service, ...)
  return future(latch_state(service, "n", ...))
end

function class.when_any(service, ...)
  return future(latch_state(service, 1, ...))
end

function class.when_any_table(service, futures)
  return future(when_any_table_state(service, futures))
end

function class.make_ready_future(_, ...)
  return make_ready_future(...)
end

function class.make_shared_future(service, future)
  local state = future.state
  future.state = nil
  return shared_future(service, shared_state(service, state))
end

function class.accept(service, fd, flags)
  return service:deferred(function (promise)
    assert(fd:is_ndelay_on())
    local result, address = fd:accept(flags)
    if result then
      return promise:set_value(result, address)
    elseif is_resource_unavailable_try_again() then
      local future = service:io_handler(fd, "read", function (promise)
        while true do
          assert(fd:is_ndelay_on())
          local result, address = fd:accept(flags)
          if result then
            return promise:set_value(result, address)
          elseif is_resource_unavailable_try_again() then
            promise = coroutine.yield()
          else
            return promise:set_error(unix.strerror(unix.get_last_errno()))
          end
        end
      end)
      return promise:set_value(future:get())
    else
      return promise:set_error(unix.strerror(unix.get_last_errno()))
    end
  end)
end

function class.connect(service, fd, address)
  return service:deferred(function (promise)
    assert(fd:is_ndelay_on())
    local result = fd:connect(address)
    if result then
      return promise:set_value(result)
    elseif unix.get_last_errno() == unix.EINPROGRESS then
      local future = service:io_handler(fd, "write", function (promise)
        local code = fd:getsockopt(unix.SOL_SOCKET, unix.SO_ERROR)
        if code then
          if code == 0 then
            return promise:set_value(fd)
          else
            return promise:set_error(unix.strerror(code))
          end
        else
          return promise:set_error(unix.strerror(unix.get_last_errno()))
        end
      end)
      return promise:set_value(future:get())
    else
      return promise:set_error(unix.strerror(unix.get_last_errno()))
    end
  end)
end

function class.read(service, fd, size)
  return service:deferred(function (promise)
    assert(fd:is_ndelay_on())
    local result = fd:read(size)
    if result then
      return promise:set_value(result)
    elseif is_resource_unavailable_try_again() then
      local future = service:io_handler(fd, "read", function (promise)
        while true do
          assert(fd:is_ndelay_on())
          local result = fd:read(size)
          if result then
            return promise:set_value(result)
          elseif is_resource_unavailable_try_again() then
            promise = coroutine.yield()
          else
            return promise:set_error(unix.strerror(unix.get_last_errno()))
          end
        end
      end)
      return promise:set_value(future:get())
    else
      return promise:set_error(unix.strerror(unix.get_last_errno()))
    end
  end)
end

function class.write(service, fd, buffer, i, j)
  return service:deferred(function (promise)
    assert(fd:is_ndelay_on())
    local result = fd:write(buffer, i, j)
    if result then
      return promise:set_value(result)
    elseif is_resource_unavailable_try_again() then
      local future = service:io_handler(fd, "write", function (promise)
        while true do
          assert(fd:is_ndelay_on())
          local result = fd:write(buffer, i, j)
          if result then
            return promise:set_value(result)
          elseif is_resource_unavailable_try_again() then
            promise = coroutine.yield()
          else
            return promise:set_error(unix.strerror(unix.get_last_errno()))
          end
        end
      end)
      return promise:set_value(future:get())
    else
      return promise:set_error(unix.strerror(unix.get_last_errno()))
    end
  end)
end

function class.make_reader(service, fd)
  return reader(service, fd)
end

function class.selfpipe(service)
  return service:deferred(function (promise)
    local result = unix.selfpipe.read()
    if result > 0 then
      return promise:set_value(result)
    else
      local future = service:io_handler(unix.selfpipe.get(), "read", function (promise)
        while true do
          local result = unix.selfpipe.read()
          if result > 0 then
            return promise:set_value(result)
          else
            promise = coroutine.yield()
          end
        end
      end)
      return promise:set_value(future:get())
    end
  end)
end

function class.wait(service, pid)
  return service:deferred(function (promise)
    while true do
      local result, code, status = unix.wait(pid, unix.WNOHANG)
      if result then
        if result == 0 then
          if service.shared_futures.selfpipe == nil or service.shared_futures.selfpipe:is_ready() then
            service.shared_futures.selfpipe = service:make_shared_future(service:selfpipe())
          end
          service.shared_futures.selfpipe:share():get()
        else
          return promise:set_value(result, code, status)
        end
      else
        return promise:set_error(unix.strerror(unix.get_last_errno()))
      end
    end
  end)
end

return class
