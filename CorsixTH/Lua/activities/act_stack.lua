class "ActivityStack"

-- @rtpe ActivityStack
local ActivityStack = _G["ActivityStack"]

--! Hierarchical state machine describing the life of an NPC.
-- The stat machines are reactive, they receive event and as a result may perform
-- actions and/or trigger other events.
function ActivityStack:ActivityStack(humanoid)
  self._humanoid = humanoid
  self._stack = {} -- Array of Activity
end

function ActivityStack:startMainActivity(activity)
  assert(#self._stack == 0)
  self._stack[1] = activity
  self:processEvent(ActivityStack.event_start)
end

local well_known_events = {
  start = true, anim_done=true, hurry=true, abort=true, child_finished=true,
}

ActivityStack.event_anim_done = {name="anim_done"}
ActivityStack.event_start = {name="start"}
ActivityStack.event_hurry = {name="hurry"}
ActivityStack.event_abort = {name="abort"}

function ActivityStack:processEvent(event)
  local activity_index = #self._stack
  assert(activity_index > 0)
  while true do
    print("STACK " .. activity_index .. " : " .. serialize(event, {max_depth=1}))
    local response = self._stack[activity_index]:handleEvent(event)
    print("       -> " .. serialize(response, {max_depth=1}))

    if response.response == "ok" then
      return

    elseif response.response == "finished" then
      assert(activity_index == #self._stack)
      assert(activity_index > 1)
      local activity = self._stack[activity_index]
      self._stack[activity_index] = nil
      activity_index = activity_index - 1
      event = {name = "child_finished", activity = activity}

    elseif response.response == "child_created" then
      assert(activity_index == #self._stack)
      assert(response.new_activity)
      self._stack[#self._stack + 1] = response.new_activity
      activity_index = activity_index + 1
      event = ActivityStack.event_start

    elseif response.response == "hurry_child" then
      assert(activity_index < #self._stack)
      activity_index = activity_index + 1
      if not self._stack[activity_index]:setActivityMode("hurry") then return end
      event = ActivityStack.event_hurry

    elseif response.response == "abort_child" then
      assert(activity_index < #self._stack)
      activity_index = activity_index + 1
      if not self._stack[activity_index]:setActivityMode("abort") then return end
      event = ActivityStack.event_abort

    elseif response.response == "unknown" then
      assert(not well_known_events[event.name]) -- Should not be an known event.
      assert(activity_index > 1)
      activity_index = activity_index - 1
      -- And try the same event again.
    else
      error("Unknown response " .. serialize(response))
    end
  end
end

print(" - ActivityStack loaded.")
