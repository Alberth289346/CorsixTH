class "WalkActivity" (Activity)
local WalkActivity = _G["WalkActivity"]

--! Compute a path from the start to the destination.
--!param start_pos (Position) Starting tile of the humanoid.
--!param dest_pos (Position) Destination tile of the humanoid.
--!return (array Position) Path from the start to the destination.
--  Empty path if no route was found, a single position is the start position
--  is also the end position, else a sequence of positions where the last
--  position is the destination tile.
function WalkActivity:_getPath(start_pos, dest_pos)
  local px, py = self.world:getPath(start_pos.x, start_pos.y, dest_pos.x, dest_pos.y)
  local path = {}
  if px then
    for i = 1, #px do path[#path + 1] = Position(px[i], py[i]) end
  end
  return path
end

--! Test if the path is free of obstacles between the current and the next position.
--!param cur_pos (Position) Current position.
--!param next_pos (Position) Next position to visit.
--!return (bool) Whether a free passage exists between cur_pos and next_pos.
function WalkActivity:_isPassable(cur_pos, next_pos)
  local cur_flags, next_flags = {}, {}

  -- Make sure that the next tile hasn't somehow become impassable since our
  -- route was determined
  local map = self.world.map.th
  map:getCellFlags(cur_pos.x, cur_pos.y, cur_flags)
  map:getCellFlags(next_pos.x, next_pos.y, next_flags)
  local is_passable = next_flags.passable and cur_flags.passable

  -- Also make sure that a room hasn't unexpectedly been built on top of the
  -- path since the route was calculated.
  return is_passable and cur_flags.roomId == next_flags.roomId
end

--! Construct a walk activity.
--!param humanoid (Humanoid) Humanoid performing the walk.
--!param exit_names (map of exit-names to parent state names) Continuation states in
--  the parent when this activity ends. Expected names are "no-path-found", "arrived",
--  "blocked".
--!param setup (table) If 'path' exists (array of Position) the path to follow,
--  else a 'dest_pos' (Position) the destination tile. In the latter case,
--  'start_pos' (Position) may also be specified as the initial tile of the
--  humanoid.
function WalkActivity:WalkActivity(parent, humanoid, exit_names, setup)
  self:Activity(parent, humanoid, exit_names)

  -- Compute a path between the tiles if necessary.
  if setup.path then
    self.path = setup.path
  else
    assert(setup.dest_pos)
    local start_pos
    if setup.start_pos then
      start_pos = setup.start_pos
    else
      start_pos = Position(self.humanoid.tile_x, self.humanoid.tile_y)
    end
    self.path = self:_getPath(start_pos, setup.dest_pos)
  end
  self.index = 1 -- Current tile is the starting point.

  -- Setup initial state.
  if not self.path then
    self._cur_state = "no-path-found"
  else
    self._cur_state = "decide-move"
  end

  print("WalkActivity:WalkActivity(): _cur_state = " .. self._cur_state)
end


function WalkActivity:_noPathFound()
  return Activity.returnExit("no-path-found")
end

function WalkActivity:_decideMove()
  print("WalkActivity:_decideMove: step " .. self.index .. " of " .. #self.path)
  if #self.path == self.index then
    return Activity.returnExit("arrived")
  end

  local cb_func = function() self.humanoid:onTick(nil) end
  local cur_pos, next_pos = self.path[self.index], self.path[self.index + 1]

  if not self:_isPassable(cur_pos, next_pos) then
    return Activity.returnExit("blocked")
  end

  print("walk-tile (" .. next_pos.x .. ", " .. next_pos.y .. ")")
  local dir = cur_pos:getDir(next_pos)
  Animations.walkTile(dir, self.humanoid, cb_func, cur_pos)
  self.index = self.index + 1
  -- self._cur_state is already ok, no need to change it.
  return Activity.returnDone()
end


local states = {
  ["no-path-found"] = WalkActivity._noPathFound,
  ["decide-move"] = WalkActivity._decideMove,
}

function WalkActivity:step(msg)
  print()
  print("***** WalkActivity:step()")
  -- WalkActivity doesn't handle any message itself, always ask the parent activity.
  if msg then
    local answer = self.parent:childMessage(msg)
    if answer then return answer end
  end

  -- Perform states until done, possibly with an exit code if the activity has ended.
  local n = 0
  while true do
    assert(n < 20) -- Avoid looping too much.
    n = n + 1

    local to_execute_state = self._cur_state
    local func = states[self._cur_state]
    assert(func, "Unknown current state " .. tostring(self._cur_state))
    local value = func(self, msg)
    assert(type(value) == "table", "Unexpected activity value found:" .. serialize(value, {detect_cycles=true, depth=2}))
    assert(not value.start_activity) -- Walk doesn't start anything.
    if value.exit_activity then
      local next_parent_state = self:getParentState(value.exit_activity)
      self.humanoid:_popActivity(next_parent_state)
      return

    elseif value.done ~= nil then
      if value.done then break end
      -- Else not done yet, loop back.

    else
      error("Unexpected activity value found:" .. serialize(value, {detect_cycles=true, depth=2}))
    end
  end
end

-- Activity:childMessage is never used as a walk does not spawn a child activity.
