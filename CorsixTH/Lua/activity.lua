
-- class "Edge"
-- 
-- ---@type Edge
-- local Edge = _G["Edge"]

class "Activity"

---@type Activity
local Activity = _G["Activity"]

function Activity:Activity(activity_name, initial_state, edges_by_state, exit_states)
  self.activity_name = activity_name
  self.initial_state = initial_state
  self.edges_by_state = edges_by_state
  self.exit_states = exit_states
end


--! Edge in an activity state machine.
--!param src_state (string) Name of the source state.
--!param dest_state (string) Name of the destination state.
--!param guard (optional table) Guard that must hold before the edge can be
--  used. If present, the guard has a 'name' field identifying it.
--!param action (optional table) Action that should be performed when the edge
--  is chosen. If present, the action has a 'name' field identifying it.
-- function Edge:Edge(src_state, dest_state, guard, action)
--     self.src_state = src_state
--     self.dest_state = dest_state
--     self.guard = guard
--     self.action = action
-- end

--! Construct a activity from its edges.
--!param activity Name of the activity.
--!param edges (list of edges) Edges of the activity, order is preserved.
--!return (Activity) the loaded activity.
function Activity.makeActivity(activity_name, edges)
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
  assert(initial_state, "Activity should have at least one edge.")
  return Activity(activity_name, initial_state, edges_by_state, exit_states)
end

local finish_action = permanent"activity_finish_action"( function(humanoid)
  humanoid:finishAction()
end)


function Activity.performAction(humanoid, action_name, ...)
  if action_name == "idleAnim" then
    return Activity.idleAnim(humanoid, ...)
  elseif action_name == "crash" then
    return Activity.crash(humanoid, ...)
  elseif action_name == "computePath" then
    return Activity.computePath(humanoid, ...)
  else
    error("Unknown action '" .. action_name .. "' found.")
  end
end

function Activity.crash(humanoid)
  error("Crashing activity!")
end

function Activity.idleAnim(humanoid)
  local direction = humanoid.activity_bb.direction or humanoid.last_move_direction
  local anims = humanoid.walk_anims
  if direction == "north" then
    humanoid:setAnimation(anims.idle_north, 0)
  elseif direction == "east" then
    humanoid:setAnimation(anims.idle_east, 0)
  elseif direction == "south" then
    humanoid:setAnimation(anims.idle_east, 1)
  elseif direction == "west" then
    humanoid:setAnimation(anims.idle_north, 1)
  end
  humanoid.th:setTile(humanoid.th:getTile())
  humanoid:setSpeed(0, 0)
  humanoid:setTimer(1)
  return true
end

function Activity.computePath(humanoid, destination, ...)
  error("Trying to find " .. destination)
end

function Activity.rootReceptionistActivity()
  return Activity.makeActivity("root-receptionist",
    {
      {src_state="initial", dest_state="created", action={"idleAnim"}},
      {src_state="created", dest_state="crash", action={"crash"}}, -- Test or check to see 'created' is not scanned for a next animation.
      {src_state="created", dest_state="placed", event="onPlaceInCorridor"},
      {src_state="placed", dest_state="got_path", action={"computePath", "unusedReceptionDesk"}},
      -- XXX if not found, meander, and try again
      -- XXX if found claim it, and go to it.
      -- XXX if blocked, meander and try again
    }
    -- XXX drop down receptionist  Receptionist:onPlaceInCorridor()
    -- XXX pickup receptionist
    -- XXX pickup or sell desk
    -- XXX place desk
    -- XXX fire receptionist
  )
end

function Activity.dumpStates(activity, filename)
  local handle = io.open(filename, "w")
  if handle then
    handle:write("digraph {\n")
    handle:write("dummy_start_node [shape=point color=green];\n")
    handle:write("dummy_start_node -> " .. activity.initial_state .. ";\n")
    for s, _ in pairs(activity.exit_states) do
      handle:write(s .. " [color=red];\n")
    end
    for _, edges in pairs(activity.edges_by_state) do
      for _, edge in ipairs(edges) do
        if edge.event then
          handle:write(edge.src_state .. " -> " .. edge.dest_state .. " [label=\"" .. edge.event .. "\"];\n")
        elseif edge.action then
          handle:write(edge.src_state .. " -> " .. edge.dest_state .. " [label=\"" .. edge.action[1] .. "\"];\n")
        else
          handle:write(edge.src_state .. " -> " .. edge.dest_state .. ";\n")
        end
      end
    end
    handle:write("}\n")
    handle:close()
  end
end

Activity.dumpStates(Activity.rootReceptionistActivity(), "receptionist_graph.dot")
print("receptionist_graph.dot dummped")
