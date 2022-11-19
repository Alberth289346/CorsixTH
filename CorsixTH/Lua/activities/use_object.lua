class "UseObjectActivity" (Activity)
local UseObjectActivity = _G["UseObjectActivity"]

--! Construct a use-object activity.
--!param humanoid (Humanoid) Humanoid performing the walk.
--!param exit_names (map of exit-names to parent state names) Continuation states in
--  the parent when this activity ends. Expected names are "done".
--!param setup (table) 'object' gives the object to use, 'position' is the
--  position of the object.
function UseObjectActivity:UseObjectActivity(parent, humanoid, exit_names, setup)
  self:Activity(parent, humanoid, exit_names)

  self.object = setup.object
  self.object_pos = setup.position
  --print("Object: " .. serialize(self.object, {max_depth=1}))
  local usage_anims
  usage_anims, self.usage_draw_flags = self.object:getUsageAnimationsInfo()

  -- Collect the animations.
  local hum_class = self.humanoid.humanoid_class
  self.object_anims = {}
  if usage_anims.begin_use then
    self.object_anims[#self.object_anims + 1] = {phase=-5, anim=usage_anims.begin_use[hum_class], begin_use=true}
  end
  if usage_anims.begin_use_2 then
    self.object_anims[#self.object_anims + 1] = {phase=-4, anim=usage_anims.begin_use2[hum_class], begin_use=true}
  end
  if usage_anims.begin_use_3 then
    self.object_anims[#self.object_anims + 1] = {phase=-3, anim=usage_anims.begin_use3[hum_class], begin_use=true}
  end
  if usage_anims.begin_use_4 then
    self.object_anims[#self.object_anims + 1] = {phase=-2, anim=usage_anims.begin_use4[hum_class], begin_use=true}
  end
  if usage_anims.begin_use_5 then
    self.object_anims[#self.object_anims + 1] = {phase=-1, anim=usage_anims.begin_use5[hum_class], begin_use=true}
  end
  if usage_anims.in_use then
    self.object_anims[#self.object_anims + 1] = {phase=0, anim=usage_anims.in_use[hum_class], in_use=true}
  end
  if usage_anims.finish_use then
    self.object_anims[#self.object_anims + 1] = {phase=1, anim=usage_anims.finish_use[hum_class], finish_use=true}
  end
  if usage_anims.finish_use_2 then
    self.object_anims[#self.object_anims + 1] = {phase=2, anim=usage_anims.finish_use_2[hum_class], finish_use=true}
  end
  if usage_anims.finish_use_3 then
    self.object_anims[#self.object_anims + 1] = {phase=3, anim=usage_anims.finish_use_3[hum_class], finish_use=true}
  end
  if usage_anims.finish_use_4 then
    self.object_anims[#self.object_anims + 1] = {phase=4, anim=usage_anims.finish_use_4[hum_class], finish_use=true}
  end
  if usage_anims.finish_use_5 then
    self.object_anims[#self.object_anims + 1] = {phase=5, anim=usage_anims.finish_use_5[hum_class], finish_use=true}
  end
  assert(#self.object_anims > 0)
  self.index = 1
  self._cur_state = "animate"
end

function UseObjectActivity:_animate(msg)
  assert(not msg)
  if self.index > #self.object_anims then
    return Activity.returnExit("done")
  end

  local obj_anim = self.object_anims[self.index]
  local cb_func = function() self.humanoid:onTick(nil) end
  print("anim.anim: " .. serialize(obj_anim.anim))
  print("pos " .. self.humanoid.tile_x .. ", " .. self.humanoid.tile_y .. ")")
  self.humanoid:setAnimation(obj_anim.anim, self.usage_draw_flags)
  print("phase=" .. obj_anim.phase)
  local length = self.world:getAnimLength(obj_anim.anim)
  self.humanoid:setTimer(length, cb_func)
  self.index = self.index + 1
  return Activity.returnDone()
end

local _states = {
  ["animate"] = UseObjectActivity._animate
}

function UseObjectActivity:step(msg)
  print("UseObjectActivity:step")
  if msg then
    -- Ask the parent activity what to do with the message.
    local answer = self.parent:childMessage(msg)
    if answer then
      assert(false, "Is this correct??") -- This looks old!!
      return answer
    end
  end

  self:computeAnimation("use-object", _states)
end

-- Activity:childMessage is never used as the UseObjectActivity never spawns a child activity.
