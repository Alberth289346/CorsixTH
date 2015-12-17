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

  -- Compute initial state.
  self.states = {}
  for _, fsm in ipairs(self.fsms) do
    for name, state in pairs(fsm) do
      if state.initial then
        if state.initial_func then state.initial_func(self.data_store) end
        self.states[#self.states + 1] = {fsm=fsm, location=name}
        break
      end
    end
  end
  assert(#self.states == #self.fsms) -- Each fsm should be initialized.
end

function FsmEngine:step(event, must_happen)
  print("step " .. event)
  local selected_trans = {}
  for number, state in ipairs(self.states) do
    local transitions = state.fsm[state.location] or {}
    transitions = transitions.transitions or {}
    transitions = transitions[event] or {}
    local found = false
    for _, tr in ipairs(transitions) do
      if not tr.condition or tr.condition(self.data_store) then
        selected_trans[#selected_trans + 1] = {fsm=state.fsm, location=state.location, trans=tr}
        found = true
        break
      end
    end
    if must_happen and not found then
      print("Error: FSM #" .. number .. " in state " .. state.location .. " cannot do event " .. event)
    end
  end
  if #selected_trans == #self.fsms then
    -- All fsms are willing to do the step.
    self.states = {}
    for _, sel_tr in ipairs(selected_trans) do
      if sel_tr.trans.action then sel_tr.trans.action(self.data_store) end
      local next_loc = sel_tr.trans.next_loc or sel_tr.location
      self.states[#self.states + 1] = {fsm=sel_tr.fsm, location = next_loc}
    end
  else
    -- At least one state machine didn't want to go along
    assert(not must_happen)
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
