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
    ["arrived"] = "pickup-drinks",
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
  -- TODO: Monitor drinks-machine so it doesn't disappear!
  print("***** Not expecting to get in _waitForWalk.")
  return Activity.returnDone()
end

function PatientActivity:_deleteSelf()
  print("***** Goodbye cruel world")
  if self.humanoid.hospital then
    self.humanoid.hospital:removePatient(self.humanoid)
  end
  self.world:destroyEntity(self.humanoid)
  return Activity.returnDone() -- Forever!
end

function PatientActivity:_pickupDrinks()
  print("***** pickup drinks")
  --print("Object: " .. serialize(self.humanoid, {max_depth=1}))
  local machine, lx, ly = self.world:findObjectNear(self.humanoid, "drinks_machine")
  if not machine or not lx or not ly then
    self._cur_state = "delete-self"
    return Activity.returnNotDone()
  end

  local use_exit_names = {
    ["done"] = "delete-self"
  }
  local setup = {
    object = machine,
    position = Position(lx, ly)
  }
  local use_object = UseObjectActivity(self, self.humanoid, use_exit_names, setup)
  self._cur_state = "wait-for-use-drinks-machine"
  return Activity.returnStart(use_object)
end

function PatientActivity:_waitForDrinksMachineUse()
  -- TODO: Monitor drinks-machine so it doesn't disappear!
  print("***** Not expecting to get in _waitForDrinksMachineUse.")
  return Activity.returnDone()
end

local _states = {
  ["start-walk-to-drink-machine"] = PatientActivity._startWalkToDrinkMachine,
  ["delete-self"] = PatientActivity._deleteSelf,
  ["pickup-drinks"] = PatientActivity._pickupDrinks,
  ["wait-for-walk"] = PatientActivity._waitForWalk,
  ["wait-for-use-drinks-machine"] = PatientActivity._waitForDrinksMachineUse,
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

  self:computeAnimation("toplevel-pat", _states)
end

function PatientActivity:childMessage()
  assert(false) -- No idea what to expect here currently.
end

