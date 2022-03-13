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
  assert(handle_functions[new_state], "State " .. new_state .. " is not available.")
  self.state = new_state
end

function PatientActivity:handleEvent(event)
  print("PatientActivity::state=" .. self.state .. ", handleEvent "
      .. serialize(event, {max_depth=2}))

  local handler = handle_functions[self.state]
  return handler(self, event)
end

--! New patient.
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
  return {response = "child_created", new_activity = walk_activity}
end

function PatientActivity:handleArrivedAtReception(event)
  if event.name == "abort" then return Activity.abort_child_response end
  if event.name == "hurry" then return Activity.ok_response end

  -- Only expected event is the child walk activity reporting in.
  if event.name ~= "child_finished" then
    return Activity.unknown_response
  end

  -- XXX Walk approach needs fine-tuning, it should adapt when the desk is being moved!!
  -- XXX This likely holds for any child activity. --> Child should ask parent activity?!

  local reason = event.activity:report()
  if reason == "no-path" or reason == "blocked" then
    self:despawn()
    -- XXX Handle waiting if inside the hospital???
    print("Despawned on lack of path (no path to desk available or path got blocked).")
    return Activity.finished_response
  end

  -- Arrived at reception.
  assert(reason == "arrived", "Unexpected reason '" .. tostring(reason) .. "' found.")
  -- XXX Implement registration at reception.

  local wait_activity = WaitActivity(self.humanoid, self.stack)
  -- XXX Specify timeouts of waiting.
  -- XXX Specify end-condition of waiting?
  -- XXX Specify allowed behavior while waiting (sitting, standing, wandering,
  --     being annoyed, drink machine).
  self:setState("waiting_for_room")
  return {response = "child_created", new_activity = wait_activity}
end

function PatientActivity:handleWaitingForRoom(event)
  if event.name == "abort" then return Activity.abort_child_response end
  if event.name == "hurry" then return Activity.hurry_child_response end

  -- Wait for meandering done.
  local reason = event.activity:report()
  print("Done with waiting (reason = " .. reason .. ")")

  error("Go home!")
end

--[[
function Activity:handleEvent(event)
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
  waiting_for_room = PatientActivity.handleWaitingForRoom,
}


--! Removal of the patient from the game.
--XXX Probable belongs in Activity
function PatientActivity:despawn()
  local humanoid = self.humanoid
  if humanoid.hospital then humanoid.hospital:despawn() end
  humanoid.world:destroyEntity(humanoid)
end


print(" - PatientActivity loaded.")
