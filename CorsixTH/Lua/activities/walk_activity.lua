class "WalkActivity" (Activity)

--@type WalkActivity
local WalkActivity = _G["WalkActivity"]

function WalkActivity:WalkActivity(humanoid, stack)
  Activity.Activity(self, humanoid, stack)

  -- Table {x, y, dir} with the destination position and optional compass direction.
  -- Position may be outside the level.
  self.dest_loc = nil
  self.path = nil -- {path_x, path_y arrays}.
  self.path_index = nil -- Index in path.
end

--! Specify the destination position, and direction.
--!param x Destination x coordinate, may be outside the level.
--!param y Destination y coordinate, may be outside the level.
--!param dir Optional compass direction to face at the end of the walk.
function WalkActivity:setDestination(x, y, dir)
  self.dest_loc = {x=x, y=y, dir=dir}
end

function WalkActivity:handleEvent(event)
  if event == "start" then
    local start_x, start_y = self.humanoid.tile_x, self.humanoid.tile_y
    local dest_x, dest_y = self.dest_loc.x, self.dest_loc.y
    self.path = humanoid.world:getPath(start_x, start_y, dest_x, dest_y)
    self.path_index = 1

    -- XXX Document 'reason' in the description
    -- XXX Implement passing that data to the parent

    -- XXX Return the activity to the parent for inspection???
    if not self.path.path_x then
      return {response="finished", reason="no-path"}
    elseif #self.path.path_x == 1 then
      return {response="finished", reason="arrived"}
    end

    local reason = self:_walkTile()
    if reason then
      self._stopHumanoidSafely()
      return {response="finished", reason=reason}
    end
    return Activity.ok_response

  elseif event == "anim_done" then
    local reason = self:_walkTile()
    if reason then
      self._stopHumanoidSafely()
      return {response="finished", reason=reason}
    end
    return Activity.ok_response

  elseif event == "hurry" then
    return Activity.ok_response

  elseif event == "abort" then
    self._stopHumanoidSafely()
    return Activity.finished_response

  else -- Other event
    return Activity.unknown_response
  end
end

function WalkActivity:_walkTile()
  local x1 = self.path.path_x[self.path_index]
  local y1 = self.path.path_y[self.path_index]
  local x2 = self.path.path_x[self.path_index + 1]
  local y2 = self.path.path_y[self.path_index + 1]

  if not x2 then
    -- Arrived at the destination.
    self._stopHumanoidSafely(x1, y1)
    return "arrived"
  end

  -- Check tiles for being passable (someone may have built something here).
  local map = humanoid.world.map.th
  map:getCellFlags(x1, y1, flags_here) -- May lie outside the level
  map:getCellFlags(x2, y2, flags_there) -- May lie outside the level
  local recalc_route = not flags_there.passable and flags_here.passable

  if recalc_route then -- Blocked!
    self._stopHumanoidSafely(x1, y1)
    return "blocked"
  end

  -- Walking a tile.
  local flag_flip_h = 1
  local factor = 1
  local quantity = 8
  if humanoid.speed and humanoid.speed == "fast" then
    factor = 2
    quantity = 4
  end

  local anims = humanoid.walk_anims
  local world = humanoid.world
  if world:isOnMap(x2, y2) then
    local notify_object = world:getObjectToNotifyOfOccupants(x2, y2)
    if notify_object then
      notify_object:onOccupantChange(1)
    end
  end
  if world:isOnMap(x1, y1) then
    local notify_object = world:getObjectToNotifyOfOccupants(x1, y1)
    if notify_object then
      notify_object:onOccupantChange(-1)
    end
  end

  if x1 ~= x2 then
    if x1 < x2 then
      humanoid.last_move_direction = "east"
      humanoid:setAnimation(anims.walk_east)
      humanoid:setTilePositionSpeed(x2, y2, -32, -16, 4 * factor, 2 * factor)
    else
      humanoid.last_move_direction = "west"
      humanoid:setAnimation(anims.walk_north, flag_flip_h)
      humanoid:setTilePositionSpeed(x1, y1, 0, 0, -4 * factor, -2 * factor)
    end
  else
    if y1 < y2 then
      humanoid.last_move_direction = "south"
      humanoid:setAnimation(anims.walk_east, flag_flip_h)
      humanoid:setTilePositionSpeed(x2, y2, 32, -16, -4 * factor, 2 * factor)
    else
      humanoid.last_move_direction = "north"
      humanoid:setAnimation(anims.walk_north)
      humanoid:setTilePositionSpeed(x1, y1, 0, 0, 4*factor, -2*factor)
    end
  end
  humanoid:setTimer(quantity, timer_fn)

  self.path_index = self.path_index + 1
end

function WalkActivity:_stopHumanoidSafely(x1, y1)
  if not x1 or not y1 then
    x1 = self.humanoid.tile_x
    y1 = self.humanoid.tile_y
  end

  local map = humanoid.world.map
  x1 = math.max(1, math.min(map.width, x1))
  y1 = math.max(1, math.min(map.height, y1))
  self.humanoid:setTilePositionSpeed(x1, y1)

