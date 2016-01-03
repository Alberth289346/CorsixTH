--[[ Copyright (c) 2009 Peter "Corsix" Cawley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

dofile "fsm_engine"

local object = {}
object.id = "plant"
object.thob = 45
object.name = _S.object.plant
object.class = "Plant"
object.tooltip = _S.tooltip.objects.plant
object.ticks = false
object.corridor_object = 6
object.build_preview_animation = 934

object.idle_animations = {
  north = 1950,
  south = 1950,
  east = 1950,
  west = 1950,
}
object.usage_animations = {
  north = {
    begin_use = { ["Handyman"] = {1972, object_visible = true} },
    in_use = { ["Handyman"] = {1980, object_visible = true} },
  },
  east = {
    begin_use = { ["Handyman"] = {1974, object_visible = true} },
    in_use = { ["Handyman"] = {1982, object_visible = true} },
  },
}
object.orientations = {
  north = {
    footprint = { {0, 0, complete_cell = true} },
    use_position = {0, -1},
    use_animate_from_use_position = true
  },
  east = {
    footprint = { {0, 0, complete_cell = true} },
    use_position = {-1, 0},
    use_animate_from_use_position = true
  },
  south = {
    footprint = { {0, 0, complete_cell = true} },
    use_position = {0, -1},
    use_animate_from_use_position = true
  },
  west = {
    footprint = { {0, 0, complete_cell = true} },
    use_position = {-1, 0},
    use_animate_from_use_position = true
  },
}

-- For litter: put broom back 356
-- take broom out: 1874
-- swoop: 1878
-- For plant: droop down: 1950
-- back up again: 1952

-- The states specify which frame to show
local states = {"healthy", "drooping1", "drooping2", "dying", "dead"}

local days_between_states = 75

-- days before we reannouncing our watering status if we were unreachable
local days_unreachable = 10


--! An `Object` which needs watering now and then.
class "Plant" (Object)

---@type Plant
local Plant = _G["Plant"]


local setup_full_health = --[[persistable:acrtwbryewhrewhy]]function(self)
  self.days_left = days_between_states
  self.current_state = 0
end

--! Decay health of the plant a bit.
local decay_action = --[[persistable:aegrtwcbhctycnt]] function(self)
  -- The plant will need water a little more often if it is hot where it is.
  local temp = self.world.map.th:getCellTemperature(self.tile_x, self.tile_y)
  self.days_left = self.days_left - (1 + temp)
  if self.days_left < 1 then
    self.days_left = days_between_states
    if self.current_state < 5 then
      self.current_state = self.current_state + 1
    end
  end
end

local --[[persistable:p5igcjucowh9uo]] function reset_call_handyman(self)
  -- Discard open tasks for watering
  -- local taskIndex = self.hospital:getIndexOfTask(self.tile_x, self.tile_y, "watering")
  -- if taskIndex ~= -1 then
  --  self.hospital:removeHandymanTask(taskIndex, "watering")
  --end
  print("simu-remove water call")
end

-- Setup timer for increasing health again. Recovery takes longer if plant
-- closer to death.
local setup_timer = --[[persistable:wvg5e7h64fj56]]function(self)
  reset_call_handyman(self)

  self.ticks = (self.direction == "south" or self.direction == "east") and 35 or 20
  -- set timer for 'ticks'.
  self.cycles = (self.current_state > 1) and math.floor(14 / self.current_state) or 1
end

-- Increase health one 'level'.
local restart_timer = --[[persistable:afqegrwxhhjey]]function(self)
  self.days_left = days_between_states
  self.current_state = self.current_state - 1
  self.ticks = self.cycles
  -- set timer for 'ticks'.
end

-- Check whether full health can be reached by going up one level.
local can_reach_full_health = --[[persistable:qgc4wgc64whx5]] function(self)
  return self.current_state <= 1
end

local plant_needs_water_check = --[[persistable:hrpgi94w6mhu69hu]] function(self)
  if self.current_state == 0 and self.days_left >= 10 then return false end
  return not self.reserved_for
end

--! Call the handyman for help (or update the priority of the task).
--!return (bool) Whether the plant can be reached by the handyman.
local call_handyman_action = --[[persistable:ag4qyc26yh37ju]] function(self)
  -- Test reachability
  if false then
    self.unreachable_counter = days_unreachable
    return false -- Jump to unreachable location.
  end

  print("Simu-call watering handyman")
  -- XXX  Check the handyman state machine versus its code.

--    local index = self.hospital:getIndexOfTask(self.tile_x, self.tile_y, "watering")
--    if index == -1 then
--      local call = self.world.dispatcher:callForWatering(self)
--      self.hospital:addHandymanTask(self, "watering", self.current_state + 1, self.tile_x, self.tile_y, call)
--    else
--      self.hospital:modifyHandymanTaskPriority(index, self.current_state + 1, "watering")
--    end
  return true -- Jump to called_handyman.
end

--! Callback function to decrement the unreachable counter.
--!return (int) Number of days left before plant should try reachability again.
local decrement_unreachable = --[[persistable:atg0ipwhuio5whjo5wvn]] function(self)
  self.unreachable_counter = math.max(self.unreachable_counter - 1, 0)
  return self.unreachable_counter
end

--! Check whether the health of the plant is so bad, it can die.
--!return (bool) Plant is in a really bad state.
local plant_is_dying_check = --[[persistable:q4xty6hu53e7uj574]] function(self)
  return self.current_state > 1
end

--! Warn the player that the plant is dying.
local warn_player_action = --[[persistable:q3tc4wy3cu3x6yvh37]] function(self)
  --self.world.ui.adviser:say(_A.warnings.plants_thirsty)
  print("Simu-warned player")
end

-- XXX Picked up tickDay / onClick !


function Plant:sneakDump()
  local data = self.store
  for k, v in pairs(self.store) do
    if self[k] then
      print("\t", k, v, self[k])
    else
      print("\t", k, v, nil)
    end
  end
  print("")
end


function Plant:Plant(world, object_type, x, y, direction, etc)
  -- It doesn't matter which direction the plant is facing. It will be rotated so that an approaching
  -- handyman uses the correct usage animation when appropriate.
  self:Object(world, object_type, x, y, direction, etc)
  self.current_state = 0
  self.base_frame = self.th:getFrame()
  self.days_left = days_between_states
  self.unreachable = false
  self.unreachable_counter = days_unreachable

  self.store = {}  -- FSM data storage container, should eventually be 'self'
  self.store.tile_x = self.tile_x
  self.store.tile_y = self.tile_y
  self.store.world = self.world
  --self.store.hospital = self.hospital

  self.store.direction = direction
  self.store.cycles = nil -- Time interval of recovery to next level of health in number of ticks.
  self.store.current_state = nil -- State of the plant; 0=healthy, 4=dead
  self.store.days_left = nil -- Number of days water left for the current state.
  self.store.unreachable_counter = 0 -- Number of days to wait before testing reachability again.


  self.fsm = FsmEngine(self.store)
  local fsm, loc

  -- FSM:
  -- Decay health daily.
  fsm = self.fsm:addFsm()
  loc = self.fsm:addLocation(fsm, "decaying", true, setup_full_health)
  self.fsm:addEdge(loc, "tick_day", nil, decay_action)


  -- FSM:
  -- Try to get attention of a handyman for some water when getting dry.
  fsm = self.fsm:addFsm()
  -- Wait until a handyman is required.
  loc = self.fsm:addLocation(fsm, "plant_ok", true)
  self.fsm:addBranchingEdge(loc, "tick_day", plant_needs_water_check, call_handyman_action,
                            {true = "called_handyman", false = "unreachable"})
  self:fsm:addEdge(loc, "tick_day") -- Plant ok, do nothing

  -- Called handyman, wait until he arrives.
  loc = self.fsm:addLocation(fsm, "called_handyman")
  self.fsm:addBranchingEdge(loc, "tick_day", plant_needs_water_check, call_handyman_action,
                            {true = "called_handyman", false = "unreachable"})
  self.fsm:addEdge(loc, "tick_day", nil, reset_call_handyman, "plant_ok")

  -- Plant is not reachable, wait a while before trying again.
  loc = self.fsm:addLocation(fsm, "unreachable")
  self.fsm:addBranchingEdge(loc, "tick_day", nil, decrement_unreachable, {0: "plant_ok"})


  -- FSM:
  -- Restore health after watering.
  fsm = self.fsm:addFsm()
  -- Waiting for watering.
  loc = self.fsm:addLocation(fsm, "blocked", true)
  self.fsm:addEdge(loc, "watering", nil, setup_timer, "restoring") -- Got water, jump to restoring health.

  -- Got water, restore to health (quickly).
  loc = self.fsm:addLocation(fsm, "restoring")
  self.fsm:addEdge(loc, "watering", nil, nil, nil) -- Ignore further water attempts, already restoring.
  self.fsm:addEdge(loc, "timeout", can_reach_full_health, setup_full_health, "blocked") -- Restore is done.
  self.fsm:addEdge(loc, "timeout", nil, restart_timer) -- Increase current state, and restore again


  -- FSM:
  -- Try to get attention of the player if things seem to go terribly wrong.
  fsm = self.fsm:addFsm()
  loc = self.fsm:addLocation(fsm, "not_warned", true)
  self.fsm:addEdge(loc, "tick_day", plant_is_dying_check, warn_player_action, "warned_player")
  self.fsm:addEdge(loc, "tick_day") -- Plant still ok, do nothing,

  loc = self.fsm:addLocation(fsm, "warned_player")
  self.fsm:addEdge(loc, "tick_day") -- Warned the player once for this plant, stay here.

  self.fsm:startup() -- Initialize the FSMs.
  self:sneakDump()
end

--! Goes one step forward (or backward) in the states of the plant.
--!param restoring (boolean) If true the plant improves its health instead of drooping.
function Plant:setNextState(restoring)
  if restoring then
    if self.current_state > 0 then
      self.current_state = self.current_state - 1
    end
  elseif self.current_state < 5 then
    self.current_state = self.current_state + 1
  end

  self.th:setFrame(self.base_frame + self.current_state)
end

local plant_restoring; plant_restoring = permanent"plant_restoring"( function(plant)
  local phase = plant.phase
  if plant.fsm then
    plant.fsm:step("timeout", false)
    plant:sneakDump()
  end
  plant:setNextState(true)
  if phase > 0 then
    plant.phase = phase - 1
    plant:setTimer(math.floor(14 / plant.cycles), plant_restoring)
  else
    plant.ticks = false
  end
end)

--! Restores the plant to its initial state. (i.e. healthy)
function Plant:restoreToFullHealth()
  if self.fsm then
    self.fsm:step("watering")
    self:sneakDump()
  end
  self.ticks = true
  self.phase = self.current_state
  self.cycles = self.current_state
  self:setTimer((self.direction == "south" or self.direction == "east") and 35 or 20, plant_restoring)
  self.days_left = days_between_states

  print("real remove watering call")
  local taskIndex = self.hospital:getIndexOfTask(self.tile_x, self.tile_y, "watering")
  if taskIndex ~= -1 then
    self.hospital:removeHandymanTask(taskIndex, "watering")
  end
end

--! Overridden since the plant animates slowly over time
function Plant:tick()
  local timer = self.timer_time
  if timer then
    timer = timer - 1
    if timer == 0 then
      self.timer_time = nil
      local timer_function = self.timer_function
      self.timer_function = nil
      timer_function(self)
    else
      self.timer_time = timer
    end
  end
end

--! Returns whether the plant is in need of watering right now.
function Plant:needsWatering()
  if self.current_state == 0 then
    if self.days_left < 10 then
      return true
    end
  else
    return true
  end
end

--! When the plant needs water it periodically calls for a nearby handyman.
function Plant:callForWatering()
  -- If self.ticks is true it means that a handyman is currently watering the plant.
  -- If there are no tiles to water from, just die.
  if not self.ticks then
    if not self.unreachable then
      print("Real call for watering (or update of priority)")
      local index = self.hospital:getIndexOfTask(self.tile_x, self.tile_y, "watering")
      if index == -1 then
        local call = self.world.dispatcher:callForWatering(self)
        self.hospital:addHandymanTask(self, "watering", self.current_state + 1, self.tile_x, self.tile_y, call)
      else
        self.hospital:modifyHandymanTaskPriority(index, self.current_state + 1, "watering")
      end
    end

    -- If very thirsty, make user aware of it.
    if self.current_state > 1 and not self.plant_announced then
      self.world.ui.adviser:say(_A.warnings.plants_thirsty)
      self.plant_announced = true
    end
  end
end

--! When a handyman is about to be summoned this function queues the complete set of actions necessary,
--  including entering and leaving any room involved. It also queues a meander action at the end.
--  Note that if there are more plants that need watering inside the room he will continue to water
--  those too before leaving.
--!param handyman (Staff) The handyman that is about to get the actions.
function Plant:createHandymanActions(handyman)
  local this_room = self:getRoom()
  local handyman_room = handyman:getRoom()
  local ux, uy = self:getBestUsageTileXY(handyman.tile_x, handyman.tile_y)
  if not ux or not uy then
    -- The plant cannot be reached.
    self.unreachable = true
    self.unreachable_counter = days_unreachable
    local index = self.hospital:getIndexOfTask(self.tile_x, self.tile_y, "watering")
    if index ~= -1 then
      self.hospital:removeHandymanTask(index, "watering")
    end
    -- Release Handyman
    handyman:setCallCompleted()
    if handyman_room then
      handyman:setNextAction(handyman_room:createLeaveAction())
      handyman:queueAction{name = "meander"}
    else
      handyman:setNextAction{name = "meander"}
    end
    return
  end
  self.reserved_for = handyman
  local action = {name = "walk", x = ux, y = uy, is_entering = this_room and true or false}
  local water_action = {
    name = "use_object",
    object = self,
    watering_plant = true,
  }
  if handyman_room and handyman_room ~= this_room then
    handyman:setNextAction(handyman_room:createLeaveAction())
    handyman:queueAction(action)
  else
    handyman:setNextAction(action)
  end
  handyman:queueAction(water_action)
  CallsDispatcher.queueCallCheckpointAction(handyman)
  handyman:queueAction{name = "answer_call"}
end

--! When a handyman should go to the plant he should approach it from the closest reachable tile.
--!param from_x (integer) The x coordinate of tile to calculate from.
--!param from_y (integer) The y coordinate of tile to calculate from.
function Plant:getBestUsageTileXY(from_x, from_y)
  local access_points = {{dx =  0, dy =  1, direction = "north"},
                         {dx =  0, dy = -1, direction = "south"},
                         {dx = -1, dy =  0, direction = "east"},
                         {dx =  1, dy =  0, direction = "west"}}
  local shortest
  local best_point = nil
  local room_here = self:getRoom()
  for _, point in ipairs(access_points) do
    local dest_x, dest_y = self.tile_x + point.dx, self.tile_y + point.dy
    local room_there = self.world:getRoom(dest_x, dest_y)
    if room_here == room_there then
      local distance = self.world:getPathDistance(from_x, from_y, self.tile_x + point.dx, self.tile_y + point.dy)
      if distance and (not best_point or shortest > distance) then
        best_point = point
        shortest = distance
      end
    end
  end

  if best_point then
    self.direction = best_point.direction
    return self.tile_x + best_point.dx, self.tile_y + best_point.dy
  else
    self.direction = "north"
    return
  end
end

--! Counts down to eventually let the plant droop.
function Plant:tickDay()
  if not self.picked_up then
    -- The plant will need water a little more often if it is hot where it is.
    local temp = self.world.map.th:getCellTemperature(self.tile_x, self.tile_y)
    self.days_left = self.days_left - (1 + temp)
    if self.days_left < 1 then
      self.days_left = days_between_states
      self:setNextState()
    elseif not self.reserved_for and self:needsWatering() and not self.unreachable then
      self:callForWatering()
    end
    if self.unreachable then
      self.unreachable_counter = self.unreachable_counter - 1
      if self.unreachable_counter == 0 then
        self.unreachable = false
      end
    end
  end
  if self.fsm then
    self.fsm:step("tick_day")
    self:sneakDump()
  end
end

--! The plant needs to retain its animation and reset its unreachable flag when being moved
function Plant:onClick(ui, button)
  if button == "right" then
    self.unreachable = false
    self.picked_up = true
    self.current_frame = self.base_frame + self.current_state
  end
  Object.onClick(self, ui, button)
end

function Plant:isPleasing()
  if not self.ticks then
    return true
  else
   return false
  end
end

function Plant:onDestroy()
  local index = self.hospital:getIndexOfTask(self.tile_x, self.tile_y, "watering")
  if index ~= -1 then
    self.hospital:removeHandymanTask(index, "watering")
  end
  Object.onDestroy(self)
end

function Plant:afterLoad(old, new)
  if old < 52 then
    self.hospital = self.world:getLocalPlayerHospital()
  end
  Object.afterLoad(self, old, new)
end


return object
