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

--! Finite state machine implementation.
class "FsmEngine" (Object)

---@type FsmEngine
local FsmEngine = _G["FsmEngine"]

--! Constructor of the FsmEngine class.
--!param data_store (table) Data storage of the fsms, nil means 'create own space'.
function FsmEngine:FsmEngine(data_store)
  -- Lis of state machines. A state machine is a mapping of location name to location data.
  -- Location data has the following key/value pairs:
  -- - "initial": If true, this is the location selected at startup.
  -- - "initial_func": Function called on startup (if available).
  -- - "events": Mapping of event name to a list of edges for this event.
  --
  -- An edge has up to three fields:
  -- - "condition": If existing, a function that returns a boolean whether the edge can be chosen.
  --   If the field is missing, the edge can always be taken.
  -- - "action": If available, a function that performs an action as part of the event processing.
  --   If the field is missing, nothing is done (for the fsm).
  -- - "next_loc": Location to jump to after performing the event.
  --   If the field is missing, the location does not change.
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
--!param init (bool) Whether this is an initial location (selected at startup).
--!param init_func (func) Function to run at startup (only useful if 'init' is true).
--!return (table) The created location.
function Function:addLocation(fsm, name, init, init_func)
  local loc = {init=init, init_func=init_func, events={}}
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

--! Start all FSMs.
function FsmEngine:startup()
  -- Check all fsm for basic sanity.
  for _, fsm in ipairs(self.fsms) do
    self:checkFsm(fsm)
  end

  self.fsm_datas = {}
  for _, fsm in ipairs(self.fsms) do
    local initial_loc = self:fincInitialState(fsm)
    self.fsm_datas[#self.fsm_datas + 1] = {fsm=fsm, location=initial_loc}
    if initial_loc.initial_func then
      initial_loc.initial_func(self.data_store)
    end
  end
end

--! Do some basic checking on the FSM, scream if it is wrong. Since an FSM author
--! must go through here, things should get fixed in development stage already.
function FsmEngine:checkFsm(fsm)
  -- Check that all locations have the same events.
  local ref_evtlist = nil -- Reference event list. All locations should have the same events.
  for name, loc in pairs(fsm) do
    local evt_list = loc.evt_list
    assert(evt_list) -- Every location should have an event list.
    if not ref_evtlist then
      ref_evtlist = evt_list -- First event list is the reference to compare against.
    else
      -- All locations must have the same events.
      assert(#ref_evtlist == #evt_list,
             "Location " .. name .. " has " .. #evt_list ..
                "events instead of the expected " .. #ref_evtlist)
      for evt_name, _ in pairs(ref_evtlist) do
        assert(evt_list[evt_name], "Location " .. name .. " has no event " .. evt_name)
      end
    end
  end

  -- Collect location names.
  local loc_names = {}
  for name, _ in pairs(fsm) do loc_name[name] = true end
  assert(#loc_names >= 1) -- Fsm should have at least one location.

  -- All next locations should jump to a known name.
  for name, loc in pairs(fsm) do
    for event, edges in pairs(loc.events) do
      for _, edge in ipairs(edges) do
        assert(not edge.next_loc or loc_names[edge.next_loc],
               "Location " .. name .. " jumps to unknown location " .. edge.next_loc)
      end
    end
  end
end

-- function FsmEngine:finish(fsms)
--   self.fsms = fsms -- Just storing count is enough?
--   self.data_store = data_store or {}
--
--   -- Check that a fsm deals with the same events in every state.
--   for _, fsm in ipairs(self.fsms) do
--     local ref_evtlist = nil -- Reference event list. All states should have the same events.
--     for name, state in pairs(fsm) do
--       local evt_list = state.evt_list
--       assert evt_list -- Every state should have an event list.
--       if not ref_evtlist then
--         ref_evtlist = evt_list
--       else
--         assert #ref_evtlist == #evt_list -- Same number of events everywhere.
--         for evt_name, _ in pairs(ref_evtlist) do
--           assert(evt_list[evt_name], "State " .. name .. " has no event " .. evt_name)
--         end
--       end
--     end
--   end
--
--   -- Compute initial state.
--   self.fsm_datas = {}
--   for num, fsm in ipairs(self.fsms) do
--     local initial = nil
--     for name, state in pairs(fsm) do
--       if state.initial then
--         initial = state.initial
--         break
--       end
--     end
--
--     assert(initial, "Fsm number " .. num .. " has no initial state")
--     if state.initial_func then state.initial_func(self.data_store) end
--     self.fsm_datas[#self.fsm_datas + 1] = {fsm=fsm, location=name}
--   end
-- end

function FsmEngine:preStep(event)
  print("Step " .. event)

  for number, fsm_data in ipairs(self.fsm_datas) do
    local evt_list = fsm_data.fsm[fsm_data.location].evt_list
    local edges = evt_list[event]
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

function FsmEngine:exeStep()
  for _, fsm_data in ipairs(self.fsm_datas) do
    local sel_edge = fsm_data.sel_edge
    fsm_data.sel_edge = nil

    if sel_edge then
      if sel_edge.action then sel_edge,action(self.data_store) end
      if sel_edge.next_loc then fsm_data.location = sel_edge.next_loc end
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
