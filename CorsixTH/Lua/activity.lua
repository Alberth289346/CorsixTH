
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

  elseif action_name == "findObject" then
    return Activity.findObject(humanoid, ...)
  elseif action_name == "computeObjectPath" then
    return Activity.computeObjectPath(humanoid, ...)

  elseif action_name == "claimFoundReceptionDesk" then
    local obj = humanoid.activity_bb.object_data.object
    assert(obj) -- Perform type check!
    assert(not obj.reserved_for or obj.reserved_for == humanoid)
    obj.reserved_for = humanoid
    return false -- No animation started.

  elseif action_name == "walkTile" then
    return Activity.walkTile(humanoid, ...)

  else
    error("Unknown action '" .. action_name .. "' found.")
  end
end

function Activity.checkGuard(humanoid, guard_name)
  local bb = humanoid.activity_bb

  if guard_name == "foundObject" then
    --print("foundObject: " .. serialize(bb.object_data))
    return bb.object_data.object
  elseif guard_name == "not_pathFound" then
    return not bb.path_data.path_x
  elseif guard_name == "pathDone" then
    return bb.path_data.path_x and #bb.path_data.path_x <= bb.path_data.path_index

  -- XXX deal with blocking [walk.lua, line 191 and further]
  elseif guard_name == "pathNorth" then
    return Activity.isNextPathTileAt(humanoid, 0, -1)
  elseif guard_name == "pathSouth" then
    return Activity.isNextPathTileAt(humanoid, 0, 1)
  elseif guard_name == "pathEast" then
    return Activity.isNextPathTileAt(humanoid, 1, 0)
  elseif guard_name == "pathWest" then
    return Activity.isNextPathTileAt(humanoid, -1, 0)
  else
    error("Unknown guard '" .. guard_name .. "' found.")
  end
end

function Activity.isNextPathTileAt(humanoid, dx, dy)
  local path_data = humanoid.activity_bb.path_data
  local path_x = path_data.path_x
  local path_y = path_data.path_y
  local path_index = path_data.path_index

  if not path_x then return false end
  if #path_x <= path_index then return false end
  local x1, y1 = path_x[path_index], path_y[path_index]
  local x2, y2 = path_x[path_index + 1], path_y[path_index + 1]
  if x1 + dx ~= x2 then return false end
  if y1 + dy ~= y2 then return false end
  -- XXX path blocking, and perhaps a door?
  return true
end

local flag_flip_h = 1

function Activity.walkTile(humanoid, dx, dy, direction)
  local anims = humanoid.walk_anims
  local world = humanoid.world

  local path_data = humanoid.activity_bb.path_data
  local path_x = path_data.path_x
  local path_y = path_data.path_y
  local path_index = path_data.path_index
  local x1, y1 = path_x[path_index], path_y[path_index]
  local x2, y2 = path_x[path_index + 1], path_y[path_index + 1]
  path_data.path_index = path_index + 1

  -- walk.lua 114 and further
  local factor = 1
  local quantity = 8
  if humanoid.speed and humanoid.speed == "fast" then
    factor = 2
    quantity = 4
  end

  local notify_object = world:getObjectToNotifyOfOccupants(x2, y2)
  if notify_object then
    notify_object:onOccupantChange(1)
  end
  notify_object = world:getObjectToNotifyOfOccupants(x1, y1)
  if notify_object then
    notify_object:onOccupantChange(-1)
  end
  if x1 ~= x2 then
    if x1 < x2 then
      humanoid.last_move_direction = "east"
      humanoid:setAnimation(anims.walk_east)
      humanoid:setTilePositionSpeed(x2, y2, -32, -16, 4 * factor, 2 * factor)
    else
      humanoid.last_move_direction = "west"
      humanoid:setAnimation(anims.walk_north, flag_flip_h)
      humanoid:setTilePositionSpeed(x1, y1, 0, 0, -4 * factor, -2 * factor)
    end
  else
    if y1 < y2 then
      humanoid.last_move_direction = "south"
      humanoid:setAnimation(anims.walk_east, flag_flip_h)
      humanoid:setTilePositionSpeed(x2, y2, 32, -16, -4 * factor, 2 * factor)
    else
      humanoid.last_move_direction = "north"
      humanoid:setAnimation(anims.walk_north)
      humanoid:setTilePositionSpeed(x1, y1, 0, 0, 4 * factor, -2 * factor)
    end
  end
  humanoid:setTimer(quantity, finish_action)
  return true
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

function Activity.findObject(humanoid, destinationObject, ...)
  if destinationObject == "unusedReceptionDesk" then
    local freaking_sneaky_answer -- findObjectNear can't be bothered to return the found desk.
    local function goodDesk(x, y)
      local desk = humanoid.world:getObject(x, y, "reception_desk")
      if not desk then return false end
      if desk.receptionist then return desk.receptionist == humanoid end -- Humanoid already at this desk.
      if desk.reserved_for then return desk.reserved_for == humanoid end -- Humanoid already got this desk,
      freaking_sneaky_answer = desk
      return true
    end

    humanoid.world:findObjectNear(humanoid, "reception_desk", nil, goodDesk)
    local unused_desk = freaking_sneaky_answer
    print("desk: " .. tostring(unused_desk))
    local object_data = humanoid.activity_bb.object_data
    object_data.object = unused_desk
    if unused_desk then
      local use_x, use_y = unused_desk:getSecondaryUsageTile()
      object_data.x = use_x
      object_data.y = use_y
    else
      object_data.x = nil
      object_data.y = nil
    end
  else
    error("Don't know about finding path to '" .. tostring(destinationObject) .. "'")
  end
end

function Activity.computeObjectPath(humanoid, ...)
  local object_data = humanoid.activity_bb.object_data
  local path_x, path_y = humanoid.world:getPath(humanoid.tile_x, humanoid.tile_y, object_data.x, object_data.y)
  local path_data = humanoid.activity_bb.path_data
  path_data.path_x = path_x
  path_data.path_y = path_y
  path_data.path_index = 1
end

function Activity.rootReceptionistActivity()
  return Activity.makeActivity("root-receptionist",
    {
      -- New receptionist, wait until it is dropped in the hospital
      -- XXX drop outside the hospital?
      -- XXX abort drop?
      {src_state="initial", dest_state="created", action={"idleAnim"}},
      {src_state="created", dest_state="crash", action={"crash"}}, -- Test or check to see 'created' is not scanned for a next animation.
      {src_state="created", dest_state="placed", event="onPlaceInCorridor"},

      -- Receptionist in corridor, find a new desk to work.
      {src_state="placed", dest_state="searchedDesk", action={"findObject", "unusedReceptionDesk"}},
      {src_state="searchedDesk", dest_state="computedPath", guard="foundObject", action={"computeObjectPath"}},
      {src_state="searchedDesk", dest_state="noDesk"}, -- No desk found.
      {src_state="computedPath", dest_state="noDesk", guard="not_pathFound"}, -- not reachable (should find another desk instead!)
      {src_state="computedPath", dest_state="walkToDesk", action={"claimFoundReceptionDesk"}},
      {src_state="walkToDesk", dest_state="arrived", guard="pathDone"},
      -- XXX if blocked walking, meander and try again [ walk.lua line 191-ish]
      {src_state="walkToDesk", dest_state="walkToDesk", guard="pathNorth", action={"walkTile", 0, -1, "North"}},
      {src_state="walkToDesk", dest_state="walkToDesk", guard="pathSouth", action={"walkTile", 0, 1, "South"}},
      {src_state="walkToDesk", dest_state="walkToDesk", guard="pathEast", action={"walkTile", 1, 0, "East"}},
      {src_state="walkToDesk", dest_state="walkToDesk", guard="pathWest", action={"walkTile", -1, 0, "West"}},

      -- XXX if found claim it, and go to it.
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
