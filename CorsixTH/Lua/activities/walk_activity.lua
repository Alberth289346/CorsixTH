class "WalkActivity" (Activity)

--@type WalkActivity
local WalkActivity = _G["WalkActivity"]

function WalkActivity:WalkActivity(humanoid, stack)
  Activity.Activity(self, humanoid, stack)

  -- Tables {x, y, dir} with the destination position and optional compass direction.
  -- Position may be outside the level.
  self.source_loc = nil
  self.dest_loc = nil

  self.path = nil -- {path_x, path_y arrays}.
  self.path_index = nil -- Index in path.
end

--! Specify the source position and direction.
--!param x Source x coordinate, may be outside the level.
--!param y Source y coordinate, may be outside the level.
--!param dir Optional compass direction to face at the start of the walk.
function WalkActivity:setSource(x, y, dir)
  self.source_loc = {x=x, y=y, dir=dir}
end

--! Specify the destination position and direction.
--!param x Destination x coordinate, may be outside the level.
--!param y Destination y coordinate, may be outside the level.
--!param dir Optional compass direction to face at the end of the walk.
function WalkActivity:setDestination(x, y, dir)
  self.dest_loc = {x=x, y=y, dir=dir}
end

function WalkActivity:report()
  return self.reason
end

function WalkActivity:handleEvent(event)
  print("WalkActivity:handleEvent " .. serialize(event, {max_depth=1}))

  if event.name == "start" then
    local start_x, start_y = self.source_loc.x, self.source_loc.y
    local dest_x, dest_y = self.dest_loc.x, self.dest_loc.y
    local px, py = self.humanoid.world:getPath(start_x, start_y, dest_x, dest_y)
    self.path = {path_x = px, path_y = py}
    self.path_index = 1

    if not self.path.path_x then
      self.reason = "no-path"
      print("WalkActivity: no path found.")
      return Activity.finished_response
    elseif #self.path.path_x == 1 then
      self.reason = "arrived"
      print("WalkActivity: arrived.")
      return Activity.finished_response
    end

    self.reason = self:_walkTile()
    if self.reason then
      self:_stopHumanoidSafely()
      return Activity.finished_response
    end
    return Activity.ok_response

  elseif event.name == "anim_done" then
    local reason = self:_walkTile()
    if reason then
      self:_stopHumanoidSafely()
      return Activity.finished_response
    end
    return Activity.ok_response

  elseif event.name == "hurry" then
    return Activity.ok_response

  elseif event.name == "abort" then
    self:_stopHumanoidSafely()
    return Activity.finished_response

  else -- Other event
    return Activity.unknown_response
  end
end

-- Callback function for finished animation
-- TODO Eliminate.
local timer_fn = permanent"walk_activity_timer_fn"( function(humanoid)
  print("CB walk_tile fired.")
  humanoid.activity_stack:processEvent(ActivityStack.event_anim_done)
end)

--! Make the humanoid walk a tile.
--!return nil if a tile walk was started, else a reason why it could not be done.
function WalkActivity:_walkTile()
  local x1 = self.path.path_x[self.path_index]
  local y1 = self.path.path_y[self.path_index]
  local x2 = self.path.path_x[self.path_index + 1]
  local y2 = self.path.path_y[self.path_index + 1]

  if not x2 then
    -- Arrived at the destination.
    self:_stopHumanoidSafely(x1, y1)
    return "arrived"
  end

  -- Check tiles for being passable (someone may have built something here).
  local map = self.humanoid.world.map.th
  local flags_here = map:getCellFlags(x1, y1) -- May lie outside the level
  local flags_there = map:getCellFlags(x2, y2) -- May lie outside the level
  local recalc_route = not flags_there.passable and flags_here.passable

  if recalc_route then -- Blocked!
    self:_stopHumanoidSafely(x1, y1)
    return "blocked"
  end

  -- Walking a tile.
  local flag_flip_h = 1
  local factor = 1
  local quantity = 8
  if self.humanoid.speed and self.humanoid.speed == "fast" then
    factor = 2
    quantity = 4
  end

  local anims = self.humanoid.walk_anims
  local world = self.humanoid.world
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
      self.humanoid.last_move_direction = "east"
      self.humanoid:setAnimation(anims.walk_east)
      self.humanoid:setTilePositionSpeed(x2, y2, -32, -16, 4 * factor, 2 * factor)
    else
      self.humanoid.last_move_direction = "west"
      self.humanoid:setAnimation(anims.walk_north, flag_flip_h)
      self.humanoid:setTilePositionSpeed(x1, y1, 0, 0, -4 * factor, -2 * factor)
    end
  else
    if y1 < y2 then
      self.humanoid.last_move_direction = "south"
      self.humanoid:setAnimation(anims.walk_east, flag_flip_h)
      self.humanoid:setTilePositionSpeed(x2, y2, 32, -16, -4 * factor, 2 * factor)
    else
      self.humanoid.last_move_direction = "north"
      self.humanoid:setAnimation(anims.walk_north)
      self.humanoid:setTilePositionSpeed(x1, y1, 0, 0, 4*factor, -2*factor)
    end
  end

  print("WalkActivity: walk a tile (" .. x1 .. ", " .. y1 .. ")->(" .. x2 .. ", " .. y2 .. ").")
  self.humanoid:setTimer(quantity, timer_fn)

  self.path_index = self.path_index + 1
end

function WalkActivity:_stopHumanoidSafely(x1, y1)
  if not x1 or not y1 then
    x1 = self.humanoid.tile_x
    y1 = self.humanoid.tile_y
  end

  local map = self.humanoid.world.map
  x1 = math.max(1, math.min(map.width, x1))
  y1 = math.max(1, math.min(map.height, y1))
  self.humanoid:setTilePositionSpeed(x1, y1)
end

print(" - WalkActivity loaded.")
