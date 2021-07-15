-- Copyright me. XXX

-- Skill is a collection of behavior by an NPC for some part of the game.
class "Skill"

---@type Skill
local Skill = _G["Skill"]

--!param skill_name Name of the skill.
--!param initial_state First state of the skill.
--!param edges_by_state Array of Edge for every state in the skill.
--!note Use the Skill.makeSkill function to make a skill.
function Skill:Skill(skill_name, initial_state, edges_by_state, exit_states)
  self.skill_name = skill_name
  self.initial_state = initial_state -- string
  self.current_state = initial_state
  self.edges_by_state = edges_by_state -- set of arrays of edges
  self.exit_states = exit_states -- set
end

--! Construct a skill from its edges.
--!param skill_name Name of the skill.
--!param edges (list of edges) Edges of the skill, order is preserved.
function Skill.makeSkill(skill_name, edges)
  -- Split edges on their source state. This implies all states have at least
  -- one outgoing edge.
  local edges_by_state = {}
  for _, edge in ipairs(edges) do
    local state_edges = edges_by_state[edge.src_state]
    if not state_edges then
      state_edges = {}
      edges_by_state[edge.src_state] = state_edges
    end
    state_edges[#state_edges + 1] = edge
  end

  --Find the initial state and the exit states.
  local initial_state = nil
  local exit_states = {} -- set
  for _, edge in ipairs(edges) do
    if not initial_state or edge.src_state == "initial" then
      initial_state = edge.src_state
    end
    if not edges_by_state[edge.dest_state] then
      -- Found an exit state.
      exit_states[edge.dest_state] = true
    end
  end
  assert(initial_state, "Skill should have at least one edge.")
  return Skill(skill_name, initial_state, edges_by_state, exit_states)
end

--! A skill is a state machine with edges from one state to the next.
--  The global idea is that while moving along an edge, its animation is
--  started. While the animation is displayed, the NPC stays in the destination
--  state indicated by the edge that started the animation (this state is
--  referred to as 'current state'). When the animation ends, a new edge is
--  selected the leaves from the current state.
--
--  To enable changes in taken edges, each edge may have a condition (a guard)
--  that must hold for the edge to be available for selection.
--
--  In addition, an edge may not start a new animation. In that case, the state
--  of the NPC moves to the destination of the edge, and another edge is
--  selected to start the animation.
--
--  A state is just a name, it has no content. A guard and an action are both
--  code, but for simplicity they are both tables with a 'name' field, and
--  possibly parameters. The Entity:evalGuard() and Entity:evalAction()
--  functions are used to resolve them to a result value.

class "Edge"

---@type Edge
local Edge = _G["Edge"]

function Edge:Edge(src_state, dest_state, guard, action)
    self.src_state = src_state
    self.dest_state = dest_state
    self.guard = guard
    self.action = action
end
