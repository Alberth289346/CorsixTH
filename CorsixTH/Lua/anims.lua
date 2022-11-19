
class "Animations"
local Animations = _G["Animations"]

local DIR_EAST = "east"
local DIR_WEST = "west"
local DIR_NORTH = "north"
local DIR_SOUTH = "south"

--! Stop movement of the humanoid.
--!param (Humanoid) humanoid Humanoid to stop.
--!param (optional Position) If given the position to set for the humanoid,
--  else its current position is used.
--!param (optional string) If set, compass direction of facing.
function Animations.stopHumanoid(humanoid, position, direction)
  -- Set idle animation in the right direction
  direction = direction or humanoid.last_move_direction
  local anims = humanoid.walk_anims
  if direction == "north" then
    humanoid:setAnimation(anims.idle_north, 0)
  elseif direction == "east" then
    humanoid:setAnimation(anims.idle_east, 0)
  elseif direction == "south" then
    humanoid:setAnimation(anims.idle_east, 1)
  elseif direction == "west" then
    humanoid:setAnimation(anims.idle_north, 1)
  end

  -- at the indicated position, fully stopped.
  humanoid:setSpeed(0, 0)
  humanoid:setTimer(nil)
  if position then
    humanoid:setTilePositionSpeed(position.x, position.y)
  else
    humanoid:setTilePositionSpeed(humanoid.tile_x, humanoid.tile_y)
  end
end

function Animations.walkTile(dir, humanoid, cb_func, start_pos)
  if dir == DIR_NORTH then
    Animations.walkTileNorth(humanoid, cb_func, start_pos)
  elseif dir == DIR_SOUTH then
    Animations.walkTileSouth(humanoid, cb_func, start_pos)
  elseif dir == DIR_WEST then
    Animations.walkTileWest(humanoid, cb_func, start_pos)
  else
    assert(dir == DIR_EAST, "Unexpected direction " .. dir)
    Animations.walkTileEast(humanoid, cb_func, start_pos)
  end
end

function Animations.walkTileEast(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local factor = (humanoid.speed == "fast") and 2 or 1
  local quantity = 8 / factor

  local dest_pos = start_pos:moveDir(DIR_EAST)
  humanoid.last_move_direction = DIR_EAST
  humanoid:setAnimation(humanoid.walk_anims.walk_east)
  humanoid:setTilePositionSpeed(dest_pos.x, dest_pos.y, -32, -16, 4 * factor, 2 * factor)
  humanoid:setTimer(quantity, cb_func)
end

function Animations.walkTileSouth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local factor = (humanoid.speed == "fast") and 2 or 1
  local quantity = 8 / factor

  local dest_pos = start_pos:moveDir(DIR_SOUTH)
  humanoid.last_move_direction = DIR_SOUTH
  humanoid:setAnimation(humanoid.walk_anims.walk_east, DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(dest_pos.x, dest_pos.y, 32, -16, -4 * factor, 2 * factor)
  humanoid:setTimer(quantity, cb_func)
end

function Animations.walkTileWest(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local factor = (humanoid.speed == "fast") and 2 or 1
  local quantity = 8 / factor

  humanoid.last_move_direction = DIR_WEST
  humanoid:setAnimation(humanoid.walk_anims.walk_north, DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y, 0, 0, -4 * factor, -2 * factor)
  humanoid:setTimer(quantity, cb_func)
end

function Animations.walkTileNorth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local factor = (humanoid.speed == "fast") and 2 or 1
  local quantity = 8 / factor

  humanoid.last_move_direction = DIR_NORTH
  humanoid:setAnimation(humanoid.walk_anims.walk_north)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y, 0, 0, 4 * factor, -2 * factor)
  humanoid:setTimer(quantity, cb_func)
end

-- =======================================================================

function Animations.throughPlainDoorEast(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local dest_pos = start_pos:moveDir(DIR_EAST)
  assert(humanoid.door_anims.entering)

  local duration = 10
  humanoid.last_move_direction = DIR_EAST
  humanoid:setAnimation(humanoid.door_anims.entering, DrawFlags.ListBottom)
  humanoid:setTilePositionSpeed(dest_pos.x, dest_pos.y)
  humanoid:setTimer(duration, cb_func)
end

function Animations.throughPlainDoorSouth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local dest_pos = start_pos:moveDir(DIR_SOUTH)
  assert(humanoid.door_anims.entering)

  local duration = 10
  humanoid.last_move_direction = DIR_SOUTH
  humanoid:setAnimation(humanoid.door_anims.entering, DrawFlags.ListBottom + DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(dest_pos.x, dest_pos.y)
  humanoid:setTimer(duration, cb_func)
end

function Animations.throughPlainDoorWest(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  assert(humanoid.door_anims.leaving)

  local duration = humanoid.world:getAnimLength(humanoid.door_anims.leaving)
  humanoid.last_move_direction = DIR_WEST
  humanoid:setAnimation(humanoid.door_anims.leaving, DrawFlags.ListBottom + DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(duration, cb_func)
end

function Animations.throughPlainDoorNorth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  assert(humanoid.door_anims.leaving)

  local duration = humanoid.world:getAnimLength(humanoid.door_anims.leaving)
  humanoid.last_move_direction = DIR_NORTH
  humanoid:setAnimation(humanoid.door_anims.leaving, DrawFlags.ListBottom)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(duration, cb_func)
end

-- =======================================================================

function Animations.throughSwingDoorWest(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  assert(humanoid.door_anims.leaving_swing)

  local duration = humanoid.world:getAnimLength(humanoid.door_anims.leaving_swing)
  humanoid.last_move_direction = DIR_WEST
  humanoid:setAnimation(humanoid.door_anims.leaving_swing, DrawFlags.ListBottom + DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(duration, cb_func)

  local door = humanoid.world:getObject(start_pos.x, start_pos.y, "swing_door_right")
  door:swingDoors("in", duration)
end

function Animations.throughSwingDoorNorth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  assert(humanoid.door_anims.leaving_swing)

  local duration = humanoid.world:getAnimLength(humanoid.door_anims.leaving_swing)
  humanoid.last_move_direction = DIR_NORTH
  humanoid:setAnimation(humanoid.door_anims.leaving_swing, DrawFlags.ListBottom)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(duration, cb_func)

  local door = humanoid.world:getObject(start_pos.x, start_pos.y, "swing_door_right")
  door:swingDoors("in", duration)
end

function Animations.throughSwingDoorEast(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local dest_pos = start_pos:moveDir(DIR_EAST)
  assert(humanoid.door_anims.entering_swing)

  local duration = humanoid.world:getAnimLength(humanoid.door_anims.entering_swing)
  humanoid.last_move_direction = DIR_EAST
  humanoid:setAnimation(humanoid.door_anims.entering_swing, DrawFlags.ListBottom)
  humanoid:setTilePositionSpeed(dest_pos.x, dest_pos.y)
  humanoid:setTimer(duration, cb_func)

  local door = humanoid.world:getObject(dest_pos.x, dest_pos.y, "swing_door_right")
  door:swingDoors("out", duration)
end

function Animations.throughSwingDoorSouth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local dest_pos = start_pos:moveDir(DIR_SOUTH)
  assert(humanoid.door_anims.entering_swing)

  local duration = humanoid.world:getAnimLength(humanoid.door_anims.entering_swing)
  humanoid.last_move_direction = DIR_SOUTH
  humanoid:setAnimation(humanoid.door_anims.entering_swing, DrawFlags.ListBottom + DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(dest_pos.x, dest_pos.y)
  humanoid:setTimer(duration, cb_func)

  local door = humanoid.world:getObject(dest_pos.x, dest_pos.y, "swing_door_right")
  door:swingDoors("out", duration)
end

-- =======================================================================

function Animations.knockPlainDoorEast(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local anim = humanoid.door_anims.knock_east
  humanoid:setAnimation(anim)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(humanoid.world:getAnimLength(anim), cb_func)

  local dest_pos = start_pos:moveDir(DIR_EAST)
  local door = humanoid.world:getObject(dest_pos.x, dest_pos.y, "door")
  door.th:makeVisible()
end

function Animations.knockPlainDoorSouth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local anim = humanoid.door_anims.knock_east
  humanoid:setAnimation(anim, DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(humanoid.world:getAnimLength(anim), cb_func)

  local dest_pos = start_pos:moveDir(DIR_SOUTH)
  local door = humanoid.world:getObject(dest_pos.x, dest_pos.y, "door")
  door.th:makeVisible()
end

function Animations.knockPlainDoorWest(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local anim = humanoid.door_anims.knock_north
  humanoid:setAnimation(anim, DrawFlags.FlipHorizontal)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(humanoid.world:getAnimLength(anim), cb_func)

  local door = humanoid.world:getObject(start_pos.x, start_pos.y, "door")
  door.th:makeVisible()
end

function Animations.knockPlainDoorNorth(humanoid, cb_func, start_pos)
  if not start_pos then start_pos = Position(humanoid.tile_x, humanoid.tile_y) end

  local anim = humanoid.door_anims.knock_north
  humanoid:setAnimation(anim)
  humanoid:setTilePositionSpeed(start_pos.x, start_pos.y)
  humanoid:setTimer(humanoid.world:getAnimLength(anim), cb_func)

  local door = humanoid.world:getObject(start_pos.x, start_pos.y, "door")
  door.th:makeVisible()
end

