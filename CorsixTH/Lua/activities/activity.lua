class "Activity"

-- @type Activity
local Activity = _G["Activity"]

-- Available modes for the activity in increasing hurry to end it.
local _activity_modes = {
  normal = 1, -- normal operation
  hurrt = 2, -- An emergency of some kind has happened, do the minimal work to end
  aborting = 3, -- end NOW.
}

function Activity:Activity(humanoid, stack)
  self.humanoid = humanoid
  self.stack = stack

  -- How soon to end the activity, one of _activity_modes.
  -- Note that this is only for stack administration, an activity should react
  -- on "finish" and "abort" events instead.
  self._mode = "normal"
end

--! Set the mode of the activity.
--  Stack query & update function to establish which activities to send an event.
--!param new_mode Desired new mode for this activity.
--!return Whether the mode was in fact changed.
function Activity:_setActivityMode(new_mode)
  local current_mode = _activity_modes[self._mode]
  local new_mode = _activity_modes[new_mode]
  if current_mode < new_mode then
    self._mode = new_mode
    return true
  end
  return false
end

--! An event has arrived for the activity.
--!param event Event to handle.
--!return (table) response.
function Activity:handleEvent(event)
  error("Implement me")
end

Activity.ok_response = {response="ok"}
Activity.finished_response = {response="finished"}
Activity.hurry_child_response = {response="hurry_child"}
Activity.abort_child_response = {response="abort_child"}
Activity.unknown_response = {response="unknown"}

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


print(" - Activity loaded.")
