class "AcitivityStack"

-- @rtpe AcitivityStack
local AcitivityStack = _G["AcitivityStack"]

--! Hierarchical state machine describing the life of an NPC.
-- The stat machines are reactive, they receive event and as a result may perform
-- actions and/or trigger other events.
function AcitivityStack:AcitivityStack(humanoid)
  self._humanoid = humanoid
  self._stack = {} -- Array of Activity
end

function AcitivityStack:startMainActivity(activity)
  assert(#self._stack == 0)
  self._stack[1] = activity
  self:processEvent("start")
end

local well_known_events = {
  ok = true, finished = true, child_created = true, hurry_child = true,
  abort_child = true, anim_done = true,
}

AcitivityStack.event_anim_done = {name="anim_done"}
AcitivityStack.event_start = {name="start"}
AcitivityStack.event_hurry = {name="hurry"}
AcitivityStack.event_abort = {name="abort"}

function AcitivityStack:processEvent(event)
  assert(event.name == "anim_done" or not well_known_events[event.name])

  local activity_index = #self._stack
  assert(activity_index > 0)
  while true do
    local response = self._stack[activity_index]:handleEvent(event)
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
      event = AcitivityStack.event_start

    elseif response.response == "hurry_child" then
      assert(activity_index < #self._stack)
      activity_index = activity_index + 1
      if not self._stack[activity_index]:setActivityMode("hurry") then return end
      event = AcitivityStack.event_hurry

    elseif response.response == "abort_child" then
      assert(activity_index < #self._stack)
      activity_index = activity_index + 1
      if not self._stack[activity_index]:setActivityMode("abort") then return end
      event = AcitivityStack.event_abort

    elseif response.response == "unknown" then
      assert(not well_known_events[event]) -- Should not be an known event.
      assert(activity_index > 1)
      activity_index = activity_index - 1
      -- And try the same event again.
    else
      error("Unknown response " .. tostring(response))
    end
  end
end
