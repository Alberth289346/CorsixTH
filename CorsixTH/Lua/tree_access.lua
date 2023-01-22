
-- Static class for extracting translated text strings by name.
class "TreeAccess"

-- @type TreeAccess
local TreeAccess = _G["TreeAccess"]

--! Parse the name of the string, breaking it into a sequence of nested table
--  key names.Such a key name is ".identifier" (leading dot is skipped the first
--  time), followed by zero or more "[number]" table indices.
--!param name (str) Name to parse.
--!return (array of str, or nil) Parts of the name as an array, or nil if
--  parsing fails.
function TreeAccess._getNameParts(name)
  local start = 1
  local result = {}

  while start <= #name do
    local first, last
    -- Match the identifier.
    if start == 1 then
      first, last = name:find("^%a[%a%d_]*", start)
    else
      -- Non-first names are prefixed with a "."
      first, last = name:find("^%.%a[%a%d_]*", start)
      if first then first = first + 1 end -- Drop the leading ".".
    end
    if not first then return nil end -- Parsing failed.

    result[#result + 1] = name:sub(first, last)
    start = last + 1

    -- Match "[number]" parts if they exist.
    first, last = name:find("^(%[%d+%])", start)
    while first do
      result[#result + 1] = name:sub(first, last)
      start = last + 1

      first, last = name:find("^(%[%d+%])", start)
    end
  end
  return result
end

--! Walk through the tree, following the path in name_parts, and return the
--  node at the end of the path.
--!param tree (nested hash tables) Tree to explore.
--!param name_parts Names or indices of the path to follow.
--!return node in the tree at the end of the path, or nil if the path does not exist.
function TreeAccess._stepThroughTree(tree, name_parts, star_index)
  if not name_parts then return nil end -- Invalid selection keys.

  local value = tree
  for _, name_part in ipairs(name_parts) do
    -- Bail out if selection ran out of tree to select from.
    if not value or type(value) ~= "table" then return nil end

    -- Use rawget to avoid triggering errors on missing entries.
    if name_part:sub(1, 1) == "[" then
      value = rawget(value, tonumber(name_part.sub(2, -2)))
    else
      value = rawget(value, name_part)
    end
  end
  return value
end

--! Read a value from the tree.
--!param tree (nested has tables) Tree to read.
--!param name (string) Name of the element to retrieve, may point at a non-leaf value.
--!return Data at tree[decoded-name], or nil if such a value does not exist.
function TreeAccess.readTree(tree, name)
  assert(type(name) == "string", "name is not a string.")
  local name_parts = TreeAccess._getNameParts(name)
  return TreeAccess._stepThroughTree(tree, name_parts)
end
