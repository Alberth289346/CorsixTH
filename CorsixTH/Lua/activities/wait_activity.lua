class "WaitActivity" (Activity)

-- @type WaitActivity
local WaitActivity = _G["WaitActivity"]

--! Wait for something to happen.
--! Reports
--!  - "time-out" NPC waited as long as specified.
function WaitActivity:WaitActivity(humanoid, stack)
  Activity.Activity(self, humanoid, stack)
  self.state = nil -- Don't set directly, use self:setState()
  self:setState("initial")
  self.reason = nil -- How did the activity end?
  --XXX timeouts, allowed behavior, end-condition
  self.standing = {value = 60} -- XXX Make it configurable.
end

function WaitActivity:report()
  assert(self.reason ~= nil)
  return self.reason
end

local handle_functions

function WaitActivity:setState(new_state)
  assert(handle_functions[new_state], "State " .. new_state .. " is not available.")
  self.state = new_state
end

function WaitActivity:handleEvent(event)
  print("WaitActivity::state=" .. self.state .. ", handleEvent "
      .. serialize(event, {max_depth=2}))

  local handler = handle_functions[self.state]
  return handler(self, event)
end

function WaitActivity:handleInitialEvent(event)
  if event.name == "start" then
    -- Select the only currently available activity.
    self:_animateStanding(nil, self.standing.value)
    print("Standing for " .. self.standing.value .. " ticks.")
    self:setState("standing")
    return Activity.ok_response
  end

  error("Unexpected event " .. serialize(event, {max_depth=1}))
end

function WaitActivity:handleStandingEvent(event)
  -- End the activity if so requested.
  if event.name == "hurry" or event.name == "abort" then return Activity.finished_response end

  -- Currently it has just one animation.
  if event.name == "anim_done" then
    -- XXX needs change.
    self.reason = "time-out"
    return Activity.finished_response
  end

  -- XXX Needs handling UI actions?! (but likely not here)
  return Activity.unknown_response
end


handle_functions = {
  initial = WaitActivity.handleInitialEvent,
  standing = WaitActivity.handleStandingEvent,
}

-- Callback function for finished animation
-- TODO Eliminate.
local timer_fn = permanent"wait_activity_timer_fn"( function(humanoid)
  humanoid.activity_stack:processEvent(ActivityStack.event_anim_done)
end)

local directions = {"east", "west", "north", "south"}

--! Humanoid will idle in the given direction or its last direction, for num_ticks ticks.
--!param direction Facing direction.
--!param num_ticks Number of ticks to wait.
function WaitActivity:_animateStanding(direction, num_ticks)
  direction = direction or directions[math.random(1, #directions)]

  local anims = self.humanoid.walk_anims
  if direction == "north" then
    self.humanoid:setAnimation(anims.idle_north, 0)
  elseif direction == "east" then
    self.humanoid:setAnimation(anims.idle_east, 0)
  elseif direction == "south" then
    self.humanoid:setAnimation(anims.idle_east, 1)
  elseif direction == "west" then
    self.humanoid:setAnimation(anims.idle_north, 1)
  end
  self.humanoid.th:setTile(self.humanoid.th:getTile())
  self.humanoid:setSpeed(0, 0)
  self.humanoid:setTimer(num_ticks, timer_fn)
end

print(" - WaitActivity loaded.")
