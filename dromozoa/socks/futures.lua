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

local future = require "dromozoa.socks.future"
local deferred_state = require "dromozoa.socks.deferred_state"
local io_handler_state = require "dromozoa.socks.io_handler_state"
local latch_state = require "dromozoa.socks.latch_state"
local make_ready_future = require "dromozoa.socks.make_ready_future"
local shared_future = require "dromozoa.socks.shared_future"
local shared_state = require "dromozoa.socks.shared_state"

local class = {}

function class.deferred(service, thread)
  return future(deferred_state(service, thread))
end

function class.io_handler(service, fd, event, thread)
  return future(io_handler_state(service, fd, event, thread))
end

function class.when_any(service, ...)
  return future(latch_state(service, 1, ...))
end

function class.when_all(service, ...)
  return future(latch_state(service, "n", ...))
end

function class.make_ready_future(_, ...)
  return make_ready_future(...)
end

function class.make_shared_future(service, future)
  local state = future.state
  future.state = nil
  return shared_future(service, shared_state(service, state))
end

return class
