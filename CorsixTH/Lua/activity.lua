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
local notdone_value = {done = false}

--! Construct a return value to denote "done".
function Activity.returnDone()
  return done_value
end

--! Construct a return value to denote "not done yet".
function Activity.returnNotDone()
  return notdone_value
end

--! Construct a return value to denote "activity exited".
--!param exit_reason Reason of exiting.
function Activity.returnExit(exit_reason)
  return {exit_activity = exit_reason}
end

--! Construct a return value to denote "child activity started".
--!param activity Activity to start as child activity.
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

function Activity:computeAnimation(activity_name, state_funcs)
  local n = 0
  while true do
    assert(n < 20)
    n = n + 1

    local to_execute_state = self._cur_state
    local func = state_funcs[self._cur_state]
    assert(func, "Unknown current state " .. tostring(self._cur_state))
    local value = func(self, nil) -- msg assumed to be nil.
    assert(type(value) == "table", "Unexpected activity value found:"
        .. serialize(value, {detect_cycles=true, max_depth=1}))

    if value.start_activity then
      self.humanoid:_pushActivity(value.start_activity, true)
      return -- Child runs after push.

    elseif value.exit_activity then
      local next_parent_state = self:getParentState(value.exit_activity)
      self.humanoid:_popActivity(next_parent_state)
      return -- Parent runs after pop.

    elseif value.done ~= nil then
      if value.done then break end
      -- Else not done yet, loop back.

    else
      error("Unexpected activity value found:" .. serialize(value, {detect_cycles=true, max_depth=1}))
    end
  end
end

--! Query from a child activity what to do with the given message.
--!param msg (table) Message to process / decide about.
--!return (nil or string) Nil if the message should be ignored (parent should
--  eventually handle it), exit name in 'exits' of the child if control must
--  be returned to the parent,
function Activity:childMessage(msg)
  error("Implement me in a derived class.")
end
