class "PatientActivity" (Activity)

-- @type PatientActivity
local PatientActivity = _G["PatientActivity"]

function PatientActivity:PatientActivity(humanoid, stack)
  Activity.Activity(self, humanoid, stack)
  self.state = nil -- Don't set directly, use self:setState()
  self:setState("initial")
end

local handle_functions

function PatientActivity:setState(new_state)
  assert(handle_functions[new_state], "State " .. new_state .. " is not avaiable.")
  self.state = new_state
end

function PatientActivity:handleEvent(event)
  print("PatientActivity::state=" .. self.state .. ", handleEvent "
      .. serialize(event, {max_depth=2}))

  local handler = handle_functions[self.state]
  return handler(self, event)
end

--! Just created.
function PatientActivity:_handleInitialEvent(event)
  if event.name == "start" then
    self:setState("to_first_reception")
    return Activity.ok_response
  end
  error("Unknown event " .. serialize(event, {max_depth=1}))
end

--! Walk to first reception. If not available, despawn.
function PatientActivity:handleToFirstReceptionEvent(event)
  if event.name == "abort" then
    self:despawn()
    return Activity.finished_response
  elseif event.name == "hurry" then
    return Activity.ok_response
  end
  -- Other standard events are not expected.

  -- XXX The hospital gets set outside the PatientActivity!
  if event.name ~= "to-hospital" then
    error("Unknown event " .. serialize(event, {max_depth=1}))
  end

  -- Handle the 'to-hospital' event.
  local source_x = 64 -- event.source.x
  local source_y = 104 -- event.source.y
  print("Temp source=(" .. source_x .. ", " .. source_y .. ")")
  self.humanoid:setTile(source_x, source_y) -- Set initial tile for sanity.

  local best_desk = self.humanoid.hospital:findBestPatientReceptionDesk(source_x, source_y)
  if not best_desk then
    -- Hospital is not ready, despawn.
    self:despawn()
    print("Despawned before walk (no reception desk available")
    return Activity.finished_response
  end

  event.source.x = source_x -- XXX Remove after temp position above is removed.
  event.source.y = source_y

  print("Destination=(" .. best_desk.x .. ", " .. best_desk.y .. ")")
  local walk_activity = WalkActivity(self.humanoid, self.stack)
  walk_activity:setSource(event.source)
  walk_activity:setDestination(best_desk)

  self.humanoid:updateDynamicInfo(_S.dynamic_info.patient.actions.on_my_way_to
    :format(best_desk.desk.object_type.name))

  self:setState("await_walk_to_reception")
  return {response="child_created", new_activity=walk_activity}
end

function PatientActivity:handleArrivedAtReception(event)
  error("Reached the reception!")
end

--[[
function WalkActivity:handleEvent(event)
  if event.name == "start" then
  elseif event.name == "anim_done" then
  elseif event.name == "child_finished" then
  elseif event.name == "hurry" then
  elseif event.name == "abort" then
  else -- Other event
    return Activity.unknown_response
  end
end
]]--

handle_functions = {
  initial = PatientActivity._handleInitialEvent,
  to_first_reception = PatientActivity.handleToFirstReceptionEvent,
  await_walk_to_reception = PatientActivity.handleArrivedAtReception,
}


--! Removal of the patient from the game.
--XXX Probable belongs in Activity
function PatientActivity:despawn()
  local humanoid = self.humanoid
  if humanoid.hospital then humanoid.hospital:despawn() end
  humanoid.world:destroyEntity(humanoid)
end


print(" - PatientActivity loaded.")
