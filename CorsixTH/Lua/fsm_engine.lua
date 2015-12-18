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

function FsmEngine:FsmEngine(fsms, data_store)
  self.fsms = fsms -- Just storing count is enough?
  self.data_store = data_store or {}

  -- Check that a fsm deals with the same events in every state.
  for _, fsm in ipairs(self.fsms) do
    local ref_evtlist = nil -- Reference event list. All states should have the same events.
    for name, state in pairs(fsm) do
      local evt_list = state.evt_list
      assert evt_list -- Every state should have an event list.
      if not ref_evtlist then
        ref_evtlist = evt_list
      else
        assert #ref_evtlist == #evt_list -- Same number of events everywhere.
        for evt_name, _ in pairs(ref_evtlist) do
          assert(evt_list[evt_name], "State " .. name .. " has no event " .. evt_name)
        end
      end
    end
  end

  -- Compute initial state.
  self.fsm_datas = {}
  for num, fsm in ipairs(self.fsms) do
    local initial = nil
    for name, state in pairs(fsm) do
      if state.initial then
        initial = state.initial
        break
      end
    end

    assert(initial, "Fsm number " .. num .. " has no initial state")
    if state.initial_func then state.initial_func(self.data_store) end
    self.fsm_datas[#self.fsm_datas + 1] = {fsm=fsm, location=name}
  end
end

function FsmEngine:step(event)
  print("Step " .. event)

  -- First find a transition that will be taken in each fsm. Actions are not
  -- yet performed, as they may change the stored data, and disturb checks
  -- of other fsms.
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
        print("Error: FSM #" .. number .. " in state " .. fsm_data.location .. " cannot do event " .. event)
      end
      fsm_data.sel_edge = sel_edge

    -- else: This fsm does not participate in this event, and stays where it is.
    end
  end

  -- Perform the action if available, and jump to the next location if available.
  for _, fsm_data in ipairs(self.fsm_datas) do
    local sel_edge = fsm_data.sel_edge
    fsm_data.sel_edge = nil

    if sel_edge then
      if sel_edge.action then sel_edge,action(self.data_store) end
      if sel_edge.next_loc then fsm_data.location = sel_edge.next_loc end
    end
  end
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
