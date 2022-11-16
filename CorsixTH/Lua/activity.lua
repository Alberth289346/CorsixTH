class "Activity"
local Activity = _G["Activity"]

--! Constructor of an activity.
--!param parent (Activity) Parent activity, or nil if at the highest level
--  (life of the humanoid).
--!param humanoid (Humanoid) Humanoid performing the activities.
--!param exit_names (table of exit-names to parent state names) Successor states in
--  the parent activity when this activity is done.
function Activity:Activity(parent, humanoid, exit_names)
  self.parent = parent
  self.humanoid = humanoid
  self.world = humanoid.world

  self._exit_names = exit_names
end

local done_value = {done = true}
function Activity.returnDone()
  return done_value
end

local notdone_value = {done = false}
function Activity.returnNotDone()
  return notdone_value
end

function Activity.returnExit(exit_reason)
  return {exit_activity = exit_reason}
end

function Activity.returnStart(activity)
  return {start_activity = activity}
end


--! Get the successor state for the parent for the given exit reason.
--  Note it is a fatal error if a reason occurs but there is no mapping for it in the exit-list.
--!param exit_reason (string) Exit reason for the child to finish processing.
--!return (string) Successor state for the parent activity.
function Activity:getParentState(exit_reason)
  assert(self._exit_names[exit_reason])
  return self._exit_names[exit_reason]
end

-- Known events:
-- {event="tick"} A 'tick' occurred and the activity requested to be notified of them.

--! Decide on the next step
--!param msg (nil or table) Reason for the request. nil means the current animation
--  delay has timed out, else a table with an 'event' field describing the event
--  that occurred.
--!return (nil or string) Exit name if the activity is done, else nil.
function Activity:step(msg)
  error("Implement me in a derived class.")
end

--! Query from a child activity what to do with the given message.
--!param msg (table) Message to process / decide about.
--!return (nil or string) Nil if the message should be ignored (parent should
--  eventually handle it), exit name in 'exits' of the child if control must
--  be returned to the parent,
function Activity:childMessage(msg)
  error("Implement me in a derived class.")
end
