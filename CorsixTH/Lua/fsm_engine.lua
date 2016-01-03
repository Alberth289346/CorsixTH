--[[ Copyright (c) 2009 Peter "Corsix" Cawley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

--! Count the number of entries in a table. While it looks like it should be a
--! standard function in Lua, it doesn't seem to exist.
--!param tbl (table) Table to count the size.
--!return (int) Number of key/value pairs in the given table.
local function count_entries(tbl)
  local count = 0
  for _, _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

--! Finite state machine implementation.
class "FsmEngine" (Object)

---@type FsmEngine
local FsmEngine = _G["FsmEngine"]

--! Constructor of the FsmEngine class.
--!param data_store (table) Data storage of the fsms, nil means 'create own space'.
function FsmEngine:FsmEngine(data_store)
  -- List of state machines. A state machine is a mapping of location name to location data.
  -- Location data has the following key/value pairs:
  -- - "initial": If true, this is the location selected at startup.
  -- - "initial_func": Function called on startup (if available).
  -- - "events": Mapping of event name to a list of edges for this event.
  --
  -- An edge has up to three fields:
  -- - "condition": If existing, a function that returns a boolean whether the
  --   edge can be chosen. If the field is missing, the edge can always be taken.
  -- - "action_func": If available, a function that performs an action as part of
  --   the event processing. If the field is missing, nothing is done (for the
  --   fsm).
  -- - The next location to jump to can be expressed as "next_loc", as
  --   "next_loc_table", or as 'nothing'.
  --   - "next_loc": Location to jump to after performing the event.
  --   - "next_loc_table": Table with jump destinations, keys are the possible
  --     return values of the action, values are the next location string.
  --   - If both fields are missing, the location does not change.
  --
  -- When an event occurs, its edges are checked from first to last in the
  -- list. The first one that can be performed is chosen. If all fsms with the
  -- event have a chosen edge, the edges are executed.
  self.fsms = {}
  self.data_store = data_store or {}

  self.fsm_datas = nil
end

--! Add a new (empty) FSM.
--!return (table) The creted FSM.
function FsmEngine:addFsm()
  local fsm = {}
  self.fsms[#self.fsms + 1] = fsm
  return fsm
end

--! Add a new location to an fsm.
--!param fsm (table) Fsm to add the location to.
--!param name (str) Name of the new location.
--!param initial (bool) Whether this is an initial location (selected at startup).
--!param initial_func (func) Function to run at startup (only useful if 'initial' is true).
--!return (table) The created location.
function FsmEngine:addLocation(fsm, name, initial, initial_func)
  local loc = {initial=initial, initial_func=initial_func, events={}}
  fsm[name] = loc
  return loc
end

--! Add an edge for an event at a location.
--!param loc (table) Location to add the edge to.
--!param event (string) Event name.
--!param cond_func (func) If not nil, function return a boolean for testing whether the edge may be taken.
--!param action_func (func) If not nil, function performing an update when the edge is taken.
--!param next_loc (string) If not nil, name of the location to jump to after taking the edge.
function FsmEngine:addEdge(loc, event, cond_func, action_func, next_loc)
  if not loc.events[event] then
    loc.events[event] = {}
  end
  local count = #loc.events[event]
  loc.events[event][count + 1] = {cond_func = cond_func, action_func = action_func, next_loc = next_loc}
end

--! Add an edge for an event at a location that may jump to one of several next
--! locations.
--!param loc (table) Location to add the edge to.
--!param event (string) Event name.
--!param cond_func (func) If not nil, function return a boolean for testing whether
--!      the edge may be taken.
--!param action_func (func) Function performing an update when the edge is taken.
--!      Also provides a return value to use as key in 'next_loc_table'.
--!param next_loc_table (table) Name of the next location to jump to, using the
--!      return value of the action function as key.
function FsmEngine:addBranchingEdge(loc, event, cond_func, action_func, next_loc_table)
  assert(action_func)

  if not loc.events[event] then
    loc.events[event] = {}
  end
  local count = #loc.events[event]
  loc.events[event][count + 1] = {cond_func = cond_func, action_func = action_func,
                                  next_loc_table = next_loc_table}
end

--! Start all FSMs.
function FsmEngine:startup()
  -- Check all fsm for basic sanity.
  for _, fsm in ipairs(self.fsms) do
    self:checkFsm(fsm)
  end

  -- Set up initial state of every FSM.
  self.fsm_datas = {}
  for _, fsm in ipairs(self.fsms) do
    local initial_loc = self:findInitialLocation(fsm)
    self.fsm_datas[#self.fsm_datas + 1] = {fsm=fsm, location=initial_loc}
    if initial_loc.initial_func then
      initial_loc.initial_func(self.data_store)
    end
  end
end

--! Do some basic checking on the FSM, scream if it is wrong. Since an FSM author
--! must go through here, things should get fixed in development stage already.
function FsmEngine:checkFsm(fsm)
  -- 1. Build a list of events used in the fsm.
  local ref_events = {} -- Reference event list. Eventually all locations should have the same events.
  for name, loc in pairs(fsm) do
    local events = loc.events
    assert(events, "Location " .. name .. " has no event list?") -- Every location should have an event list.
    for evt_name, _ in pairs(events) do
      ref_events[evt_name] = true
    end
  end

  -- 2. Automagically insert missing special event 'timeout'.
  -- 3. Check that all locations have the same events.
  for name, loc in pairs(fsm) do
    local events = loc.events

    -- If 'timeout' is used, ignore it in the locations that don't have it.
    if ref_events.timeout and not events.timeout then
      self:addEdge(loc, "timeout", nil, nil, nil) -- Loop back to the current location without doing anything.
    end

    -- All locations must have the same events.
    if count_entries(ref_events) ~= count_entries(events) then
      assert(false, "Location " .. name .. " has " .. count_entries(events) ..
             "events instead of the expected " .. count_entries(ref_events))
    end

    for evt_name, _ in pairs(ref_events) do
      assert(events[evt_name], "Location " .. name .. " has no event " .. evt_name)
    end
  end

  -- Collect location names.
  local loc_names = {}
  for name, _ in pairs(fsm) do loc_names[name] = true end
  assert(count_entries(loc_names) >= 1) -- Fsm should have at least one location.

  -- All next locations should jump to a known name.
  for name, loc in pairs(fsm) do
    for event, edges in pairs(loc.events) do
      for _, edge in ipairs(edges) do
        if edge.next_loc then
          assert(loc_names[edge.next_loc],
                 "Location " .. name .. " jumps to unknown location " .. edge.next_loc)
        elseif edge.next_loc_table then
          for _, next_loc in pairs(edge.next_loc_table) do
            assert(loc_names[next_loc],
                   "Location " .. name .. " jumps to unknown location " .. next_loc)
          end
        -- else no location jump, do nothing.
        end
      end
    end
  end
end

--! Get the initial location of the fsm, produces an error if no initial location available.
--!param fsm FSM to search.
--!return (location table) Location used as initial location.
function FsmEngine:findInitialLocation(fsm)
  for name, loc in pairs(fsm) do
    if loc.initial then return loc end
  end

  -- Error detected, try to give the programmer a bit of a clue where to look.
  for name, _ in pairs(fsm) do
    assert(false, "No initial location found for FSM with location " .. name)
  end
  assert(false) -- Should never be reached.
end

--! Find the edge in each FSM that will participate in performing the given event.
--!param event (str) Name of the event to perform.
function FsmEngine:preStep(event)
  print("Step " .. event)

  for number, fsm_data in ipairs(self.fsm_datas) do
    local events = fsm_data.location.events
    local edges = events[event]
    local sel_edge = nil
    if edges then
      for _, edge in ipairs(edges) do
        if not edge.condition or edge.condition(self.data_store) then
          sel_edge = edge
          break
        end
      end
      if not sel_edge then
        print("FSM #" .. number .. " in state " .. fsm_data.location .. " cannot do event " .. event)
      end
      fsm_data.sel_edge = sel_edge

    -- else: This fsm does not participate in this event, and stays where it is.
    end
  end
end

--! Actually perform the selected edge that was selected in 'self:preStep'.
function FsmEngine:exeStep()
  for num, fsm_data in ipairs(self.fsm_datas) do
    local sel_edge = fsm_data.sel_edge
    fsm_data.sel_edge = nil

    if sel_edge then
      -- FSM has a selected edge; take it. Perform action, and update the location.
      local value = nil
      if sel_edge.action_func then
        value = sel_edge.action_func(self.data_store)
      end

      if sel_edge.next_loc then
        fsm_data.location = fsm_data.fsm[sel_edge.next_loc]

      elseif sel_edge.next_loc_table then
        value = value and sel_edge.next_loc_table[value]
        if value then fsm_data.location = fsm_data.fsm[value] end

      -- else no location jump, do nothing.
      end
    end
  end
end

function FsmEngine:step(event)
  self:preStep(event)
  self:exeStep()
end

function FsmEngine:pp(d)
  if type(d) == "table" then
    local s
    for k, v in pairs(d) do
      if s then
        s = s .. ", " .. self:pp(k) .. ":" .. self:pp(v)
      else
        s = self:pp(k) .. ":" .. self:pp(v)
      end
    end
    if s then
      return "{" .. s .. "}"
    else
      return "{ }"
    end
  else
    return tostring(d)
  end
end

return FsmEngine
