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

local class = {}

function class.new(service, fd)
  return {
    service = service;
    fd = fd;
  }
end

function class:write(buffer, i, j)
  return self.service:deferred(function (promise)
    local min, max = translate_range(#buffer, i, j)
    while min <= max do
      local result, message, code = self.service:write(self.fd, buffer, min, max):get()
      if not result then
        return promise:set(nil, message, code)
      else
        min = min + result
      end
    end
    return promise:set(self)
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
