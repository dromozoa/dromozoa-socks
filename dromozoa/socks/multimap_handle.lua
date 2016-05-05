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

function class.new(tree, a, b)
  return class.reset({ tree = tree }, a, b)
end

function class:reset(a, b)
  if b == nil then
    b = a
  end
  self.a = a
  self.b = b
  return self
end

function class:delete()
  local a = self.a
  if a == nil then
    return
  end
  local tree = self.tree
  local b = self.b
  while true do
    local s = tree:successor(a)
    tree:delete(a)
    if a == b then
      break
    end
    a = s
  end
end

function class:each()
  local a = self.a
  if a == nil then
    return function () end
  end
  local tree = self.tree
  local b = self.b
  local that = class(tree)
  return coroutine.wrap(function ()
    while true do
      local s = tree:successor(a)
      coroutine.yield(tree:key(a), tree:get(a), that:reset(a))
      if a == b then
        break
      end
      a = s
    end
  end)
end

function class:empty()
  return self.a == nil
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, tree, a, b)
    return setmetatable(class.new(tree, a, b), metatable)
  end;
})
