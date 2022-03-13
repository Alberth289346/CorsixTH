class "WalkActivity" (Activity)

--@type WalkActivity
local WalkActivity = _G["WalkActivity"]

--! Walk from the source location to the destination location.
--! Doors are ignored.
--! Reports
--!  - "no-path" if path finding fails,
--!  - "blocked" if tile on the path is found blocked, or
--!  - "arrived" if the NPC arrives at the destination.
function WalkActivity:WalkActivity(humanoid, stack)
  Activity.Activity(self, humanoid, stack)

  -- Tables {x, y, optional dir and offset}
  -- (x, y) Position in the levels, optional orientation for starting/ending the walk.
  -- Offset to the given position and direction in number of tiles.
  -- Position may be outside the level.
  self.source_loc = nil
  self.dest_loc = nil

  self.path = nil -- {path_x, path_y arrays}.
  self.path_index = nil -- Index in path.

  self._state = nil -- Don't set directoy, use self:setState()
  self:setState("initial")
end

local function isCompassDirection(dir)
  return dir == "east" or dir == "west" or dir == "north" or dir == "south"
end

local function checkOrientation(dir)
  if dir == nil then return true end
  return isCompassDirection(dir)
end

local function checkOffset(dir, offset)
  if offset == nil then return true end
  assert(type(offset) == "number")
  return isCompassDirection(dir)
end

--! Specify the source location (x, y, optional direction and offset)
function WalkActivity:setSource(source_loc)
  print("setSource " .. serialize(source_loc, {max_depth=2}))
  assert(source_loc)
  assert(type(source_loc.x) == "number")
  assert(type(source_loc.y) == "number")
  assert(checkOrientation(source_loc.dir), "direction '" .. tostring(source_loc.dir) .. "' is incorrect.")
  for k, v in pairs(source_loc) do print(k, v) end
  assert(checkOffset(source_loc.dir, source_loc.offset),
      "offset '" .. tostring(source_loc.offset) .. "' with direction '"
      .. tostring(source_loc.dir) .. "' is incorrect.")
  self.source_loc = source_loc
end

--! Specify the destination location (x, y, optional direction and offset)
function WalkActivity:setDestination(dest_loc)
  print("setDestination " .. serialize(dest_loc, {max_depth=2}))
  assert(type(dest_loc.x) == "number")
  assert(type(dest_loc.y) == "number")
  assert(checkOrientation(dest_loc.dir), "direction '" .. tostring(dest_loc.dir) .. "' is incorrect.")
  assert(checkOffset(dest_loc.dir, dest_loc.offset))
  self.dest_loc = dest_loc
end

function WalkActivity:report()
  assert(self.reason ~= nil)
  return self.reason
end

local handle_functions

function WalkActivity:setState(new_state)
  assert(handle_functions[new_state], "Missing event function for state " .. tostring(new_state))
  self._state = new_state
end

function WalkActivity:handleEvent(event)
  print("WalkActivity:handleEvent " .. serialize(event, {max_depth=1}))

  local handler = handle_functions[self._state]
  return handler(self, event)
end

function WalkActivity:handleInitialEvent(event)
  assert(event.name == "start")

  -- Compute a path.
  local start_x, start_y = self.source_loc.x, self.source_loc.y
  local dest_x, dest_y = self.dest_loc.x, self.dest_loc.y
  local px, py = self.humanoid.world:getPath(start_x, start_y, dest_x, dest_y)
  self.path = {path_x = px, path_y = py}
  self.path_index = 1

  if not self.path.path_x then
    self.reason = "no-path"
    self:setState("done")
    print("WalkActivity: no path found.")
    return Activity.finished_response
  end

  if #self.path.path_x == 1 then
    self.reason = "arrived"
    self:setState("done")
    print("WalkActivity: arrived.")
    return Activity.finished_response
  end

  -- XXX Perform offset walking at source location.
  -- XXX Perform offset walking at destination location.

  -- First tile works, switch to regular walk state.
  self.reason = self:_walkTile()
  if self.reason then
    self:_stopHumanoidSafely()
    self:setState("done")
    return Activity.finished_response
  end

  self:setState("walking")
  return Activity.ok_response
end

function WalkActivity:handleWalkingEvent(event)
  if event.name == "anim_done" then
    self.reason = self:_walkTile()
    if self.reason then
      self:_stopHumanoidSafely()
      self:setState("done")
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

function WalkActivity:handleDoneEvent(event)
  error("Unexpected event " .. serialize(event, {max_depth=2}))
end

handle_functions = {
  initial = WalkActivity.handleInitialEvent,
  walking = WalkActivity.handleWalkingEvent,
  done = WalkActivity.handleDoneEvent,
}

-- Callback function for finished animation
-- TODO Eliminate.
local timer_fn = permanent"walk_activity_timer_fn"( function(humanoid)
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
