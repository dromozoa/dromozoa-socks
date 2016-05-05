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

local multimap_handle = require "dromozoa.socks.multimap_handle"
local rb_tree = require "dromozoa.socks.rb_tree"

local class = {}

function class.new(compare)
  return {
    tree = rb_tree(compare);
  }
end

function class:insert(k, v)
  local tree = self.tree
  local h = tree:insert(k, v)
  return multimap_handle(tree, h)
end

function class:each()
  local tree = self.tree
  return multimap_handle(tree, tree:minimum(), tree:maximum()):each()
end

function class:lower_bound(k)
  local tree = self.tree
  local h = tree:lower_bound(k)
  if h == nil then
    return multimap_handle(tree)
  end
  return multimap_handle(tree, h, tree:maximum())
end

function class:upper_bound(k)
  local tree = self.tree
  local h = tree:upper_bound(k)
  if h == nil then
    return multimap_handle(tree)
  end
  return multimap_handle(tree, tree:minimum(), h)
end

function class:equal_range(k)
  local tree = self.tree
  local h = tree:search(k)
  if h == nil then
    return multimap_handle(tree)
  else
    return multimap_handle(tree, h, tree:upper_bound(k))
  end
end

function class:empty()
  local tree = self.tree
  return tree:empty()
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, compare)
    return setmetatable(class.new(compare), metatable)
  end;
})
