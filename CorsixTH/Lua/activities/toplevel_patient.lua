class "PatientActivity" (Activity)
local PatientActivity = _G["PatientActivity"]

function PatientActivity:PatientActivity(humanoid)
  Activity.Activity(self, nil, humanoid, {})

  self._cur_state = "start-walk-to-drink-machine"
end

function PatientActivity:_startWalkToDrinkMachine()
  print("***** PatientActivity:_startWalkToDrinkMachine")
  local machine, lx, ly = self.world:findObjectNear(self.humanoid, "drinks_machine")
  if not machine or not lx or not ly then
    self._cur_state = "delete-self"
    return Activity.returnNotDone()
  end

  local walk_exit_names = {
    ["no-path-found"] = "delete-self",
    ["arrived"] = "pickup-soda",
    ["blocked"] = "delete-self",
  }
  local setup = {
    dest_pos = Position(lx, ly)
  }
  local walk = WalkActivity(self, self.humanoid, walk_exit_names, setup)
  self._cur_state = "wait-for-walk"
  return Activity.returnStart(walk)
end

function PatientActivity:_waitForWalk()
  print("***** Not expecting to get in WaitForWalk.")
  return Activity.returnDone()
end

function PatientActivity:deleteSelf()
  print("***** Goodbye cruel world")
  self.humanoid:destroyEntity()
end

function PatientActivity:pickupSoda()
  print("***** OOps!")
  assert(false)
end

local _states = {
  ["start-walk-to-drink-machine"] = PatientActivity._startWalkToDrinkMachine,
  ["delete-self"] = PatientActivity._deleteSelf,
  ["pickup-soda"] = PatientActivity._pickupSoda,
  ["wait-for-walk"] = PatientActivity._waitForWalk,
}

function PatientActivity:step(msg)
  print()
  print("PatientActivity:step")
  if msg then
    if msg.event == "spawn" then -- Should do actual spawning (humanoid_actions/spawn)
      self.humanoid:setTile(msg.position.x, msg.position.y)
      return
    end
    if msg.event == "new-hospital" then
      -- Do the simple case (first hospital that is visited).
      assert(#self.humanoid._activity_stack == 1 and self._cur_state == "start-walk-to-drink-machine")
      self.humanoid:setHospital(msg.hospital)
      return
    end
    assert(false, "Unexpected event " .. msg.event)
  end

  local n = 0
  while true do
    assert(n < 20)
    n = n +1

    local to_execute_state = self._cur_state
    local func = _states[self._cur_state]
    assert(func, "Unknown current state " .. tostring(self._cur_state))
    local value = func(self, msg)
    assert(type(value) == "table", "Unexpected activity value found:" .. serialize(value, {detect_cycles=true, max_depth=1}))

    if value.start_activity then
      self.humanoid:_pushActivity(value.start_activity, true)
      return -- This activity is blocked now.

    elseif value.exit_activity then
      local next_parent_state = self:getParentState(value.exit_activity)
      self.humanoid:_popActivity(next_parent_state)
      return

    elseif value.done ~= nil then
      if value.done then break end
      -- Else not done yet, loop back.

    else
      error("Unexpected activity value found:" .. serialize(value, {detect_cycles=true, max_depth=1}))
    end
  end
end

function PatientActivity:childMessage()
  assert(false) -- No idea what to expect here currently.
end

