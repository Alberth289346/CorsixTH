class "PatientActivity" (Activity)

-- @type PatientActivity
local PatientActivity = _G["PatientActivity"]

function PatientActivity:PatientActivity(humanoid, stack)
  Activity.Activity(self, humanoid, stack)
  self.state = "started"
end

function PatientActivity:handleEvent(event)
  print("PatientActivity:handleEvent " .. serialize(event, {max_depth=1}))

  -- XXX get hospital, get position
  if event.name == "start" then
    self.state = "started"
    return Activity.ok_response
  end

  if event.name == "to-hospital" then
    local source_dir = event.source.direction
    local source_x = 64 -- event.source.x
    local source_y = 104 -- event.source.y
    print("Temp source=(" .. source_x .. ", " .. source_y .. ")")

    local best_desk = self.humanoid.hospital:findBestPatientReceptionDesk(source_x, source_y)
    assert(best_desk) -- If it fails, data of the event may become lost?!

    print("Destination=(" .. best_desk.use_x .. ", " .. best_desk.use_y .. ")")
    local walk_activity = WalkActivity(self.humanoid, self.stack)
    walk_activity:setDestination(best_desk.use_x, best_desk.use_y, best_desk.dir)

    self.humanoid:updateDynamicInfo(_S.dynamic_info.patient.actions.on_my_way_to
      :format(best_desk.desk.object_type.name))
    self.humanoid:setTile(source_x, source_y) -- Set initial tile.

    -- Spawning starts a number of tiles before the indicated position.
    -- Note this may be off-map!
    if event.offset then
      source_x = source_x + (source_dir == "west" and -event.offset or 0)
          - (source_dir == "east" and event.offset or 0)
      source_y = source_y + (source_dir == "north" and -event.offset or 0)
          - (source_dir == "south" and event.offset or 0)
    end
    walk_activity:setSource(source_x, source_y, source_dir)

    return {response="child_created", new_activity=walk_activity}
  end

--  elseif event.name == "anim_done" then
--  elseif event.name == "child_finished" then
--  elseif event.name == "hurry" then
--  elseif event.name == "abort" then
--  else -- Other event
--    return Activity.unknown_response
--  end

  error("Unknown event " .. serialize(event, {max_depth=1}))
end

print(" - PatientActivity loaded.")
