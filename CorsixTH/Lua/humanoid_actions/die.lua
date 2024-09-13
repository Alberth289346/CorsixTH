--[[ Copyright (c) 2009 Edvin "Lego3" Linge

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

class "DieAction" (HumanoidAction)

---@type DieAction
local DieAction = _G["DieAction"]

function DieAction:DieAction()
  self:HumanoidAction("die")
end

local action_die_tick; action_die_tick = permanent"action_die_tick"( function(humanoid)
  local action = humanoid:getCurrentAction()
  local phase = action.phase
  local mirror = humanoid.last_move_direction == "east" and 0 or 1
  if phase == 0 then
    action.phase = 1
    if humanoid.die_anims.extra_east ~= nil then
      humanoid:setTimer(humanoid.world:getAnimLength(humanoid.die_anims.extra_east), action_die_tick)
      humanoid:setAnimation(humanoid.die_anims.extra_east, mirror)
    else
      action_die_tick(humanoid)
    end
  elseif phase == 1 then
    action.phase = 2
    humanoid:setTimer(11, action_die_tick)
    humanoid:setAnimation(humanoid.die_anims.rise_east, mirror)
  elseif phase == 2 then
    -- Female slack tongue head layer is missing from wings animation onwards
    -- So we change the head to its standard equivalent
    if humanoid.humanoid_class == "Slack Female Patient" then
      humanoid:setLayer(0, humanoid.layers[0] - 8)
    end

    action.phase = 3
    humanoid:setTimer(11, action_die_tick)
    humanoid:setAnimation(humanoid.die_anims.wings_east, mirror)
  elseif phase == 3 then
    action.phase = 4
    humanoid:setTimer(15, action_die_tick)
    humanoid:setAnimation(humanoid.die_anims.hands_east, mirror)
  elseif phase == 4 then
    action.phase = 5
    humanoid:setTimer(30, action_die_tick)
    humanoid:setAnimation(humanoid.die_anims.fly_east, mirror)
    humanoid:setTilePositionSpeed(humanoid.tile_x, humanoid.tile_y, nil, nil, 0, -4)
  else
    humanoid:despawn()
    humanoid.world:destroyEntity(humanoid)
  end
end)

local action_die_tick_reaper; action_die_tick_reaper = permanent"action_die_tick_reaper"( function(humanoid)
  local action = humanoid:getCurrentAction()
  local mirror = humanoid.last_move_direction == "east" and 0 or 1
  local phase = action.phase

  if phase == 0 then
    action.phase = 1

    if humanoid.die_anims.extra_east ~= nil then
      humanoid:setTimer(humanoid.world:getAnimLength(humanoid.die_anims.extra_east), action_die_tick_reaper)
      humanoid:setAnimation(humanoid.die_anims.extra_east, mirror)
    else
      action_die_tick_reaper(humanoid)
    end

  --1: The patient stays on the ground until phase 5:
  elseif phase == 1 then
    action.phase = 2
    if humanoid.humanoid_class ~= "Standard Male Patient" then
      humanoid:setType("Standard Male Patient")
    end
    humanoid:setAnimation(humanoid.on_ground_anim, mirror)
    action_die_tick_reaper(humanoid)

  --2: Spawn the grim reaper and the lava hole, if no suitable spawn points are found a heaven death will be started:
  elseif phase == 2 then
    local spawn_scenarios = {
      {
        holes_orientation = "south",
        hole_search_x = humanoid.tile_x,
        hole_search_y = humanoid.tile_y + 4,
        grim_hole_offset_x = 1,
        grim_hole_offset_y = 0,
        grim_spawn_dir = "west",
        hum_hole_offset_x = -1,
        hum_hole_offset_y = 0,
        grim_spawn_positions = {
          {after_spawn_idle_direction = "east", hole_x_offset = -5, hole_y_offset = 2},
          {hole_x_offset = 0, hole_y_offset = 3}
        }
      },
      {
        holes_orientation = "east",
        hole_search_x = humanoid.tile_x + 4,
        hole_search_y = humanoid.tile_y,
        grim_hole_offset_x = 0,
        grim_hole_offset_y = 1,
        grim_spawn_dir = "north",
        hum_hole_offset_x = 0,
        hum_hole_offset_y = -1,
        grim_spawn_positions = {
          {hole_x_offset = 3, hole_y_offset = 0}
        }
      }
    }

    --! Check whether a grim reaper scenario can be used.
    --!param humanoid Humanoid that is about to die.
    --!param spawn_scenario Scenario to check.
    --!return Computed positions and directions for the scenario, else nil.
    local function tryToUseHellDeathSpawnScenario(humanoid, spawn_scenario)
      local world = humanoid.world

      local holes_orientation = spawn_scenario.holes_orientation
      local hole_x, hole_y = world.pathfinder:findIdleTile(spawn_scenario.hole_search_x, spawn_scenario.hole_search_y, 0)

      if hole_x and world:canNonSideObjectBeSpawnedAt(hole_x, hole_y, "gates_to_hell", holes_orientation, 0, 0) then
        local mirror_grim = (holes_orientation == "south") and 1 or 0

        local grim_use_tile_x, grim_use_tile_y
        grim_use_tile_x = hole_x + spawn_scenario.grim_hole_offset_x
        grim_use_tile_y = hole_y + spawn_scenario.grim_hole_offset_y
        humanoid.hole_use_tile_x = hole_x + spawn_scenario.hum_hole_offset_x
        humanoid.hole_use_tile_y = hole_y + spawn_scenario.hum_hole_offset_y
        -- tile can't be in a room and must be accessible by the patient
        if not world:getPathDistance(humanoid.tile_x, humanoid.tile_y, humanoid.hole_use_tile_x, humanoid.hole_use_tile_y)
            or world:getRoom(humanoid.hole_use_tile_x, humanoid.hole_use_tile_y) then
          return nil
        end
        -- ensure grim won't be in a room
        if world:getRoom(grim_use_tile_x, grim_use_tile_y) then
          return nil
        end
        --Ensure that the lava hole is passable on at least one of its sides to prevent it from blocking 1 tile wide corridors:
        world.map:setCellFlags(hole_x, hole_y, {passable = false})
        local hole_has_passable_side = world:getPathDistance(grim_use_tile_x, grim_use_tile_y, humanoid.hole_use_tile_x, humanoid.hole_use_tile_y) == 4
        world.map:setCellFlags(hole_x, hole_y, {passable = true})
        if not hole_has_passable_side then
          return nil
        end

        --Try to find grim a spawn point which will allow him to walk to his lava hole use tile:
        local grim_x, grim_y
        local grim_spawn_idle_direction
        local grim_cant_walk_to_use_tile = true
        for _, find_grim_spawn_attempt in ipairs(spawn_scenario.grim_spawn_positions) do
          grim_spawn_idle_direction = find_grim_spawn_attempt.after_spawn_idle_direction or spawn_scenario.grim_spawn_dir
          grim_x, grim_y = world.pathfinder:findIdleTile(hole_x + find_grim_spawn_attempt.hole_x_offset, hole_y + find_grim_spawn_attempt.hole_y_offset, 0)
          if grim_x and not world:getRoom(grim_x, grim_y)
              and world:getPathDistance(grim_x, grim_y, grim_use_tile_x, grim_use_tile_y) then
            grim_cant_walk_to_use_tile = false
            break
          end
        end
        -- Else spawn him on it:
        if grim_cant_walk_to_use_tile then
          grim_spawn_idle_direction = spawn_scenario.grim_spawn_dir
          grim_x = grim_use_tile_x
          grim_y = grim_use_tile_y
        end

        -- Construct scenario data table.
        return {
          holes_orientation = holes_orientation,
          hole_x = hole_x,
          hole_y = hole_y,
          grim_x = grim_x,
          grim_y = grim_y,
          grim_use_tile_x = grim_use_tile_x
          grim_use_tile_y = grim_use_tile_y,
          grim_spawn_idle_direction = grim_spawn_idle_direction,
          mirror_grim = mirror_grim
        }
      end

      return nil
    end

    local scenario_data = nil
    for _, spawn_scenario in ipairs(spawn_scenarios) do
      scenario_data = tryToUseHellDeathSpawnScenario(humanoid, spawn_scenario)
      if scenario_data then break end
    end

    -- None of the scenarios can be used, fallback to a normal death.
    if not scenario_data then
      action_die_tick(humanoid)
      return
    end

    --Spawn the grim reaper and the lava hole:
    local lava_hole = humanoid.world:newObject("gates_to_hell", scenario_data.hole_x, scenario_data.hole_y, scenario_data.holes_orientation)
    local grim_reaper = humanoid.world:newEntity("GrimReaper", 1660)

    local point_dir = {x = scenario_data.grim_x, y = scenario_data.grim_y, direction = scenario_data.grim_spawn_idle_direction}
    grim_reaper:setNextAction(IdleSpawnAction(1660, point_dir):setCount(40))

    --Initialise the grim reaper:
    grim_reaper:setHospital(humanoid.world:getLocalPlayerHospital())
    grim_reaper.lava_hole = lava_hole
    grim_reaper.lava_hole.orientation = scenario_data.holes_orientation
    grim_reaper.use_tile_x = scenario_data.grim_use_tile_x
    grim_reaper.use_tile_y = scenario_data.grim_use_tile_y
    grim_reaper.mirror = mirror_grim
    grim_reaper.patient = humanoid
    humanoid.grim_reaper = grim_reaper

    action.phase = 3
    action_die_tick_reaper(humanoid)

  --3: The grim reaper walks to his lava hole use tile and then stands idle waiting for phase 6:
  elseif phase == 3 then
    action.phase = 4
    local grim = humanoid.grim_reaper
    if grim.tile_x ~= grim.use_tile_x or grim.tile_y ~= grim.use_tile_y then
      grim:queueAction(WalkAction(grim.use_tile_x, grim.use_tile_y):disableTruncate())
    end

    local loop_callback_wait = --[[persistable:reaper_wait]]function()
      grim:setAnimation(1002, grim.mirror)
      action_die_tick_reaper(humanoid)
    end
    grim:queueAction(IdleAction():setLoopCallback(loop_callback_wait))

  --4: There will be a brief pause before the patient stands up:
  elseif phase == 4 then
    action.phase = 5
    humanoid:setTimer(20, action_die_tick_reaper)

  -- 5: The dead patient will now stand up:
  elseif phase == 5 then
    action.phase = 6
    humanoid:setTimer(humanoid.world:getAnimLength(humanoid.die_anims.rise_hell_east), action_die_tick_reaper)
    humanoid:setAnimation(humanoid.die_anims.rise_hell_east, mirror)

  --6: The dead patient will now walk in to the lava hole, falling in as the grim reaper does his "sending patient to hell" animation:
  elseif phase == 6 then
    local grim = humanoid.grim_reaper
    local lava_hole = grim.lava_hole
    --The grim reaper's final actions:
    local loop_callback_swipe =--[[persistable:reaper_swipe]]function()
      grim:setAnimation(1670, grim.mirror)
    end
    grim:queueAction(IdleAction():setCount(grim.world:getAnimLength(1670)):setLoopCallback(loop_callback_swipe))

    local loop_callback_leave =--[[persistable:reaper_leave]]function()
      grim:setAnimation(1678, grim.mirror)
    end
    grim:queueAction(IdleAction():setCount(grim.world:getAnimLength(1678)):setLoopCallback(loop_callback_leave))

    local lava_destroy = --[[persistable:lava_destroy]]function()
      humanoid.world:destroyEntity(lava_hole)
    end
    local loop_callback_destroy =--[[persistable:reaper_destroy]]function()
      lava_hole.playing_sounds_in_random_sequence = false
      lava_hole:setTimer(lava_hole.world:getAnimLength(2552), lava_destroy)
      lava_hole:setAnimation(2552)
      grim.world:destroyEntity(grim)
    end
    grim:queueAction(IdleAction():setLoopCallback(loop_callback_destroy))

    --The patient's final actions:
    humanoid:walkTo(humanoid.hole_use_tile_x, humanoid.hole_use_tile_y, true)

    local post_walk_into = --[[persistable:walk_into_lava]]function()
      grim:finishAction()
    end

    local use_action = UseObjectAction(lava_hole)
    use_action.destroy_user_after_use = true
    use_action.after_walk_in = post_walk_into
    humanoid:queueAction(use_action)
    humanoid:finishAction()
  end
end)

local function action_die_start(action, humanoid)
  humanoid:setMoodInfo() -- clear all mood icons
  local preferred_fall_direction
  if math.random(0, 1) == 1 then
    preferred_fall_direction = "east"
  else
    preferred_fall_direction = "south"
  end
  local anims = humanoid.die_anims
  assert(anims, "Error: no death animation for humanoid ".. humanoid.humanoid_class)
  action.must_happen = true
  local fall = anims.fall_east

  --If this isn't done their bald head will become bloated instead of suddenly having hair:
  if humanoid.disease.id == "baldness" then humanoid:setLayer(0,2) end

  local mirror_fall = preferred_fall_direction == "east" and 0 or 1
  humanoid.last_move_direction = preferred_fall_direction

  humanoid:setAnimation(anims.fall_east, mirror_fall)

  action.phase = 0

  local fall_anim_duration = humanoid.world:getAnimLength(fall)
  if humanoid.humanoid_class == "Chewbacca Patient" then
    --After 21 ticks the first frame of the buggy falling part of this animation is reached
    --so this animation is ended early, action_die_tick will then use the standard male fall animation:
    fall_anim_duration = 21
  end
  -- Bloaty head patients can't go to hell because they don't have a
  -- "transform to standard male"/"fall into lava hole" animation.
  if humanoid:isMalePatient() and humanoid.disease.id ~= "bloaty_head" then
    if math.random(1, 100) <= 65 then
      humanoid:setTimer(fall_anim_duration, action_die_tick_reaper)
    else
      humanoid:setTimer(fall_anim_duration, action_die_tick)
    end
  else
    humanoid:setTimer(fall_anim_duration, action_die_tick)
  end
  humanoid.dead = true
end

return action_die_start
