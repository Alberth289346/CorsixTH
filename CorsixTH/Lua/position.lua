class "Position"
local Position = _G["Position"]

--! Construct a position.
function Position:Position(x, y)
  assert(type(x) == "number" and math.floor(x) == x)
  assert(type(y) == "number" and math.floor(y) == y)
  self.x = x
  self.y = y
end

-- Meta-METHODS

local Position_mt = Position._metatable

function Position_mt:__tostring()
  return string.format("(%d, %d)", self.x, self.y)
end

function Position_mt.__eq(one, other)
  return one.x == other.x and one.y == other.y
end

local DIR_EAST = "east"
local DIR_WEST = "west"
local DIR_NORTH = "north"
local DIR_SOUTH = "south"
local DELTA_EAST = Position(1, 0)
local DELTA_WEST = Position(-1, 0)
local DELTA_NORTH = Position(0, -1)
local DELTA_SOUTH = Position(0, 1)

local DIRS_TO_DELTAS = {
  [DIR_EAST] = DELTA_EAST,
  [DIR_WEST] = DELTA_WEST,
  [DIR_NORTH] = DELTA_NORTH,
  [DIR_SOUTH] = DELTA_SOUTH,
}

-- Check if the given position is a position.
--!param pos (Position) Position to check.
--!param on_map (bool) Whether the position is on-map.
function Position.checkIsPosition(pos, on_map)
  assert(type(pos.x) == "number", "X coordinate is not a number.")
  assert(type(pos.y) == "number", "Y coordinate is not a number.")
  assert(pos.x == math.floor(pos.x), "X coordinate is not an integer.")
  assert(pos.y == math.floor(pos.y), "Y coordinate is not an integer.")
  if on_map then
    assert(TheApp.world:isOnMap(pos.x, pos.y), "Position is off-map.")
  end
end

--! Move a position in X or Y direction from 'src_pos' towards 'dest_pos'.
--!param src_pos (Position) Current position.
--!param dest_pos (Position) Destination position.
--!return A single tile nearer to the destination position.
function Position.moveTowards(src_pos, dest_pos)
  local function sgn(v)
    return v == 0 and 0 or (v > 0 and 1 or -1)
  end

  local dx = dest_pos.x - src_pos.x
  local dy = dest_pos.y - src_pos.y
  if math.abs(dx) > math.abs(dy) then
    return Position(src_pos.x + sgn(dx), src_pos.y)
  else
    return Position(src_pos.x, src_pos.y + sgn(dy))
  end
end

--! Construct an on-map position close to the provided position.
--!param pos (Position) Position nearby, possibly off-map.
--!return (Position) Position near 'pos', always on-map.
function Position.clampToWorld(pos)
  if TheApp.world:isOnMap(pos.x, pos.y) then return pos end

  local w, h = TheApp.map.width, TheApp.map.height
  return Position(math.min(math.max(pos.x, 1), w), math.min(math.max(pos.y, 1), h))
end

--! Construct a position 'count' tiles in given direction from this position.
--!param dir (string) Direction of movement.
--!param count (optional integer) Number of tiles to move, by default 1
--!return (Position) A new position at the destination.
function Position:moveDir(dir, count)
  if not count then count =1 end

  local delta = DIRS_TO_DELTAS[dir]
  return Position(self.x + delta.x * count, self.y + delta.y * count)
end

--! Compute direction from self to the provided destination.
-- Both positions must be in the same row or column at the map.
--!param dest_pos (Position) Position to aim for from self.
--!return (string, integer) direction and the absolute distance.
function Position:getDir(dest_pos)
  if self.x == dest_pos.x then
    return ((self.y < dest_pos.y) and DIR_SOUTH or DIR_NORTH), math.abs(self.y - dest_pos.y)
  else
    assert(self.y == dest_pos.y)
    return ((self.x < dest_pos.x) and DIR_EAST or DIR_WEST), math.abs(self.x - dest_pos.x)
  end
end
