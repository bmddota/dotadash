
vPlayerIlluminate = {}
vPlayerProjectiles = {}
vPlayerDummies = {}
vPlayerToggles = {}

function warpToPoint(keys)
  local target = keys.Target
  local caster = keys.caster
  
  if caster == nil then
		return
	end

  local point = nil
	if target == "POINT" and keys.target_points[1] then
		point = keys.target_points[1]
	else
    return
  end
  
  --print(tostring(point))
  -- prevent top left
  --if point.x < -2700 and point.y > 2200 then
    --point = Vector(-2180, 1368, 0)
  --end
  
  -- prevent top right
  --if point.x > 2700 and point.y > 2200 then
    --point = Vector(2180, 1368, 0)
  --end

  FindClearSpaceForUnit(caster, point, true)
end

function unstick(keys)
  local caster = keys.caster
  local forward = caster:GetForwardVector()
  FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

function greenTurtleShell(keys)
  local caster = keys.caster
  local forward = caster:GetForwardVector()
  
  local shell = CreateUnitByName("npc_green_turtle_shell", caster:GetAbsOrigin() + 75 * forward, false, caster, caster, caster:GetTeamNumber())
  shell:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  shell:AddNewModifier(unit, nil, "modifier_phased", {})
  local ability = shell:FindAbilityByName("reflex_dummy_unit")
  ability:SetLevel(1)
  
  Physics:Unit(shell)
  --shell:SetBaseMoveSpeed(BASE_MOVESPEED)
  shell:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
  shell:SetPhysicsAcceleration(Vector(0,0,GRAVITY_AMOUNT))
  shell:Slide(false)
  shell:SetPhysicsFriction(0)
  
  shell:AddPhysicsVelocity(tonumber(keys.Speed) * forward)
  
  local timer = DoUniqueString('shell')
  
  shell:OnPhysicsFrame(function(unit)
    local forward = unit:GetForwardVector()
    
    unit:SetForwardVector(RotatePosition( Vector(0,0,0), QAngle(0, 720 / 30, 0), forward ))
    
    local pos = unit:GetAbsOrigin()
    local ents = Entities:FindAllByClassnameWithin("npc_dota_hero*", pos, 125)
    local ent = nil
    local dist = 1000
    for k,v in pairs(ents) do
      if v ~= caster then
        local diff = v:GetAbsOrigin() - pos
        local l = diff:Length()
        if l < dist then
          dist = l
          ent = v
        end
      end
    end
    
    if ent ~= nil and ent.GetPhysicsVelocity ~= nil then
      local distance = ent:GetAbsOrigin() - shell:GetAbsOrigin()
      if distance.z < 40 then
        local direction = distance:Normalized()
        
        ent:EmitSound("Hero_Alchemist.UnstableConcoction.Stun")
        --ent:AddNewModifier(ent, nil, "modifier_stunned", {duration = 2.5})
        --local vel = ent:GetPhysicsVelocity()
        --ent:AddPhysicsVelocity(vel * (-2/3) + Vector(0,0,600)  + direction * 150)
        
        local particle = ParticleManager:CreateParticle("nian_roar_prj_gasexplode_shockwave", PATTACH_POINT, ent)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0))
        ParticleManager:SetParticleControl(particle, 1, Vector(50,5,1)) -- radius, thickness, speed
        ParticleManager:SetParticleControl(particle, 3, ent:GetAbsOrigin()) -- position
        
        local ents = Entities:FindAllByClassnameWithin("npc_dota_hero*", shell:GetAbsOrigin(), 450)
        for k,v in pairs(ents) do
          if v.AddPhysicsVelocity ~= nil and IsValidEntity(v) then
            local vel = v:GetPhysicsVelocity()
            v:AddPhysicsVelocity(vel * (-2/3) + Vector(0,0,600) + direction * 150)
            v:AddNewModifier(v, nil, "modifier_silence", {duration = 2.5})
          end
        end
        
        DotaDashGameMode:RemoveTimer(timer)
        shell:StopPhysicsSimulation()
        shell:Destroy()
      end
    end
  end)
  
  DotaDashGameMode:CreateTimer(timer, {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 10,
    callback = function(reflex, args)
      shell:StopPhysicsSimulation()
      shell:Destroy()
    end
  })
end

function hop(keys)
  local caster = keys.caster
  local forward = caster:GetForwardVector()
  forward.z = 0
  forward = forward:Normalized() * 100
  if caster.AddPhysicsVelocity ~=nil then
    caster:AddPhysicsVelocity(Vector(forward.x,forward.y,775) + caster.vSlideVelocity)
    caster:AddPhysicsAcceleration(Vector(0,0,-20))
    DotaDashGameMode.vPlayers[caster:GetPlayerID()].bFlying = true
    DotaDashGameMode.vPlayers[caster:GetPlayerID()].fLastFriction = caster:GetPhysicsFriction()
    caster:PreventDI(true)
    caster:SetPhysicsFriction(0)
    caster:AddNewModifier(caster, nil, "modifier_pudge_meat_hook", {})
    
    DotaDashGameMode:CreateTimer(DoUniqueString('hop'), {
      useGameTime = true,
      endTime = GameRules:GetGameTime() + 2,
      callback = function(reflex, args)
        caster:AddPhysicsAcceleration(Vector(0,0,20))
      end
    })
  end
end

function bananaPeel(keys)
  local caster = keys.caster
  local backward = caster:GetForwardVector() * -1
  
  local banana = CreateUnitByName("npc_banana_peel", caster:GetAbsOrigin() + 75 * backward, false, caster, caster, caster:GetTeamNumber())
  banana:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  banana:AddNewModifier(unit, nil, "modifier_phased", {})
  local ability = banana:FindAbilityByName("reflex_dummy_unit")
  ability:SetLevel(1)
  
  Physics:Unit(banana)
  
  banana:SetForwardVector(backward)
  
  banana:AddPhysicsVelocity(backward * 300)
  banana:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
  banana:SetPhysicsAcceleration(Vector(0,0,GRAVITY_AMOUNT))
  banana:SetPhysicsVelocityMax(1000)
  banana:Slide(false)
  banana:SetPhysicsFriction(FRICTION_MULTIPLIER)
  banana:Hibernate(false)
  
  local timer = DoUniqueString('banana')
  local timer2 = DoUniqueString('banana2')
  local startTime = GameRules:GetGameTime() + 0.5
  
  banana:OnPhysicsFrame(function(unit)
    --print('FIND')
    -- Find
    local pos = unit:GetAbsOrigin()
    local ents = Entities:FindAllByClassnameWithin("npc_dota_hero*", pos, 125)
    local ent = nil
    local dist = 1000
    local gt = GameRules:GetGameTime()
    local distance = nil
    for k,v in pairs(ents) do
      if gt > startTime or v ~= caster then
        local diff = v:GetAbsOrigin() - pos
        local l = diff:Length()
        if l < dist then
          dist = l
          ent = v
          distance = diff
        end
      end
    end
    
    if ent ~= nil and ent.GetPhysicsVelocity ~= nil then
      
      -- Stop if reached the unit
      if distance:Length() < 125 and distance.z < 40 then
        ent:EmitSound("dotadash.slip")
        
        --[[local particle = ParticleManager:CreateParticle("nian_roar_prj_gasexplode_shockwave", PATTACH_POINT, ent)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0))
        ParticleManager:SetParticleControl(particle, 1, Vector(50,5,1)) -- radius, thickness, speed
        ParticleManager:SetParticleControl(particle, 3, ent:GetAbsOrigin()) -- position]]
        
        
        ent:PreventDI(true)
        ent:AddNewModifier(ent, nil, "modifier_silence", {duration = 2.0})
        ent:AddNewModifier(ent, nil, "modifier_pudge_meat_hook", {duration = 2.0})
        ent:AddPhysicsVelocity(ent:GetPhysicsVelocity() * (-1/3))
        local fric = ent:GetPhysicsFriction()
        DotaDashGameMode.fLastFriction = fric
        ent:SetPhysicsFriction(.01)
        
        local done = GameRules:GetGameTime() + 2.0
        DotaDashGameMode:CreateTimer(timer2, {
          useGameTime = true,
          endTime = GameRules:GetGameTime() + .1,
          callback = function(reflex, args)
            if GameRules:GetGameTime() > done then
              ent:PreventDI(false)
              ent:SetPhysicsFriction(DotaDashGameMode.fLastFriction)
              return
            end
            if IsValidEntity(banana) then
              ent:PreventDI(true)
            end
            return GameRules:GetGameTime() + .1
          end
        })
        
        DotaDashGameMode:RemoveTimer(timer)
        banana:StopPhysicsSimulation()
        banana:Destroy()
      end
    end
  end)
  
  DotaDashGameMode:CreateTimer(timer, {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 100,
    callback = function(reflex, args)
      if IsValidEntity(banana) then
        banana:StopPhysicsSimulation()
        banana:Destroy()
      end
    end
  })
end

function redTurtleShell(keys)
  local caster = keys.caster
  local forward = caster:GetForwardVector()
  
  local shell = CreateUnitByName("npc_red_turtle_shell", caster:GetAbsOrigin() + 75 * forward, false, caster, caster, caster:GetTeamNumber())
  shell:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  shell:AddNewModifier(unit, nil, "modifier_phased", {})
  local ability = shell:FindAbilityByName("reflex_dummy_unit")
  ability:SetLevel(1)
  
  Physics:Unit(shell)
  --shell:SetBaseMoveSpeed(BASE_MOVESPEED)
  shell:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
  shell:SetPhysicsAcceleration(Vector(0,0,GRAVITY_AMOUNT))
  shell:SetPhysicsVelocityMax(keys.Speed)
  shell:Slide(false)
  shell:SetPhysicsFriction(0)
  
  local timer = DoUniqueString('redshell')
  local timer2 = DoUniqueString('redactive')
  
  shell:AddPhysicsVelocity(tonumber(keys.Speed) * forward)
  shell.bAcquire = false
  
  DotaDashGameMode:CreateTimer(timer2, {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 0.5,
    callback = function(reflex, args)
      shell.bAcquire = true
    end
  })
  
  shell:OnPhysicsFrame(function(unit)
    local forward = unit:GetForwardVector()
    
    unit:SetForwardVector(RotatePosition( Vector(0,0,0), QAngle(0, 720 / 30, 0), forward ))
    
    -- Find and track
    local pos = unit:GetAbsOrigin()
    local ents = Entities:FindAllByClassnameWithin("npc_dota_hero*", pos, 800)
    local ent = nil
    local dist = 1000
    for k,v in pairs(ents) do
      if v ~= caster then
        local diff = v:GetAbsOrigin() - pos
        local l = diff:Length()
        if l < dist then
          dist = l
          ent = v
        end
      end
    end
    
    if ent ~= nil and ent.GetPhysicsVelocity ~= nil then
      local distance = ent:GetAbsOrigin() - shell:GetAbsOrigin()
      local direction = distance:Normalized()
      direction.z = 0
      if unit.bAcquire then 
        shell:SetPhysicsAcceleration(direction * 115 + Vector(0,0,GRAVITY_AMOUNT))
      end
      
      -- Stop if reached the unit
      if distance:Length() < 125 and distance.z < 40 then
        ent:EmitSound("Hero_Alchemist.UnstableConcoction.Stun")
        
        local particle = ParticleManager:CreateParticle("nian_roar_prj_gasexplode_shockwave", PATTACH_POINT, ent)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0))
        ParticleManager:SetParticleControl(particle, 1, Vector(50,5,1)) -- radius, thickness, speed
        ParticleManager:SetParticleControl(particle, 3, ent:GetAbsOrigin()) -- position
        
        
        ents = Entities:FindAllByClassnameWithin("npc_dota_hero*", shell:GetAbsOrigin(), 450)
        for k,v in pairs(ents) do
          if v.AddPhysicsVelocity ~= nil and IsValidEntity(v) then
            local vel = v:GetPhysicsVelocity()
            v:AddPhysicsVelocity(vel * (-2/3) + Vector(0,0,600) + direction * 150)
            v:AddNewModifier(v, nil, "modifier_silence", {duration = 2.5})
          end
        end
        
        DotaDashGameMode:RemoveTimer(timer2)
        DotaDashGameMode:RemoveTimer(timer)
        shell:StopPhysicsSimulation()
        shell:Destroy()
      end
    end
  end)
  
  DotaDashGameMode:CreateTimer(timer, {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 10,
    callback = function(reflex, args)
      shell:StopPhysicsSimulation()
      shell:Destroy()
    end
  })
end

function blueTurtleShell(keys)
  local caster = keys.caster
  local forward = caster:GetForwardVector()
  
  local shell = CreateUnitByName("npc_blue_turtle_shell", caster:GetAbsOrigin() + 75 * forward, false, caster, caster, caster:GetTeamNumber())
  shell:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  shell:AddNewModifier(unit, nil, "modifier_phased", {})
  local ability = shell:FindAbilityByName("reflex_dummy_unit")
  ability:SetLevel(1)
  
  Physics:Unit(shell)
  --shell:SetBaseMoveSpeed(BASE_MOVESPEED)
  shell:FollowNavMesh(false)
  shell:SetAutoUnstuck(false)
  shell:SetNavCollisionType(PHYSICS_NAV_NOTHING)
  shell:SetPhysicsAcceleration(Vector(0,0,0))
  shell:SetPhysicsVelocityMax(2000)
  shell:Slide(false)
  shell:SetPhysicsFriction(0)
  
  local timer = DoUniqueString('bluehsell')
  
  local first = nil
  local maxPos = -1
  local points = #MAP_DATA[GetMapName()].waypoints
  
  DotaDashGameMode:LoopOverPlayers(function(ply, plyID)
    local pos = (ply.nLap - 1) * points + (ply.nCurWaypoint - 1)
    if pos > maxPos then
      first = ply.hero
      maxPos = pos
    end
  end)
  
  shell:AddPhysicsVelocity(1000 * forward)
  
  shell:OnPhysicsFrame(function(unit)
    local forward = unit:GetForwardVector()
    
    unit:SetForwardVector(RotatePosition( Vector(0,0,0), QAngle(0, 720 / 30, 0), forward ))
    
    local ent = first
    
    if ent ~= nil and ent.GetPhysicsVelocity ~= nil then
      local distance = ent:GetAbsOrigin() - shell:GetAbsOrigin()
      local direction = distance:Normalized()
      direction.z = 0
      shell:SetPhysicsAcceleration(direction * 300 + Vector(0,0,0))
      
      local dist = distance:Length()
      if dist < 2000 or shell:GetAbsOrigin().z >= 700 then
        shell:AddPhysicsVelocity(Vector(0,0,-1 * math.abs(distance.z)))
      else
        shell:AddPhysicsVelocity(Vector(0,0,10))
      end
      
      -- Stop if reached the unit
      if distance:Length() < 150 then
        ent:EmitSound("Hero_Alchemist.UnstableConcoction.Stun")

        local particle = ParticleManager:CreateParticle("nian_roar_prj_gasexplode_shockwave", PATTACH_POINT, ent)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0))
        ParticleManager:SetParticleControl(particle, 1, Vector(50,5,1)) -- radius, thickness, speed
        ParticleManager:SetParticleControl(particle, 3, ent:GetAbsOrigin()) -- position
        
        
        ents = Entities:FindAllByClassnameWithin("npc_dota_hero*", shell:GetAbsOrigin(), 450)
        for k,v in pairs(ents) do
          if v.AddPhysicsVelocity ~= nil and IsValidEntity(v) then
            local vel = v:GetPhysicsVelocity()
            v:AddPhysicsVelocity(vel * (-2/3) + Vector(0,0,600) + direction * 150)
            v:AddNewModifier(v, nil, "modifier_silence", {duration = 2.5})
          end
        end
        
        shell:StopPhysicsSimulation()
        shell:Destroy()
      end
    end
  end)
end
  


function rocketBoots(keys)
  local caster = keys.caster
  local forward = caster:GetForwardVector()
  
  local accel = tonumber(keys.SpeedBoost) / 10 * forward
  caster:AddPhysicsAcceleration(accel)
  
  DotaDashGameMode:CreateTimer(DoUniqueString('accel'), {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 3,
    callback = function(reflex, args)
      caster:SetPhysicsAcceleration(Vector(0,0,caster:GetPhysicsAcceleration().z))
    end
  })
  --caster:AddPhysicsVelocity(tonumber(keys.SpeedBoost) * forward)
end

local line = 0
local vec = Vector(0,0,0)

function printLine(keys)
  if line == 0 then
    line = 1
    vec = keys.target_points[1]
  else 
    line = 0
    vec2 = keys.target_points[1]
    print('{from = Vector(' .. tostring(math.floor(vec.x))
      .. "," .. tostring(math.floor(vec.y)) 
      .. "," .. tostring(math.floor(vec.z))
      .. "), to = Vector(" .. tostring(math.floor(vec2.x))
      .. "," .. tostring(math.floor(vec2.y)) 
      .. "," .. tostring(math.floor(vec2.z))
      .. ")},")
  end
end

function printPoint(keys)
  local point = keys.target_points[1]
  local navX = #MAP_DATA[GetMapName()].anggrid - (GridNav:WorldToGridPosX(point.x) + #MAP_DATA[GetMapName()].anggrid / 2)
  local navY = #MAP_DATA[GetMapName()].anggrid - (GridNav:WorldToGridPosY(point.y) + #MAP_DATA[GetMapName()].anggrid / 2)
  
  print(navX)
  print(navY)
  print('X=' .. tostring(navX) .. ", Y=" .. tostring(navY) .. ", ang=" .. tostring(MAP_DATA[GetMapName()].anggrid[navX][navY]))
  print('{origin = Vector(' .. tostring(math.floor(keys.target_points[1].x))
    .. "," .. tostring(math.floor(keys.target_points[1].y)) .. "," .. tostring(math.floor(keys.target_points[1].z)) .. ")},")
end

function goBackToWaypoint(keys)
  local caster = keys.caster
  caster:Slide(false)
  FindClearSpaceForUnit(caster, caster.lastWaypoint, true)
  
  DotaDashGameMode:CreateTimer(DoUniqueString('reslide'), {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 0.1,
    callback = function(reflex, args)
      caster:Slide(true)
    end
  })
end

function teamBasedCircle(keys)
  local target = keys.Target
  local caster = keys.caster
  local duration = tonumber(keys.Duration) or 6
  local safeEffect = keys.SafeEffect
  local dangerEffect = keys.DangerEffect
  local sound = keys.Sound or nil
  
  if caster == nil or keys.Radius == nil then
		return
	end
  
  local radius = tonumber(keys.Radius)
  
  local targetEntity = nil
    
  local attach = PATTACH_ABSORIGIN_FOLLOW
  
  local point = keys.target_points[1]
  local team = caster:GetTeam()
  
  targetEntity = CreateUnitByName("npc_dota_danger_indicator", point, false, caster, caster, team)
  targetEntity:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  targetEntity:AddNewModifier(unit, nil, "modifier_phased", {})
  local ability = targetEntity:FindAbilityByName("reflex_dummy_unit")
  ability:SetLevel(1)
  
  if sound ~= nil then
    targetEntity:EmitSound(sound)
  end
  
  DotaDashGameMode:LoopOverPlayers(function(ply, plyID)
    local particle = nil
    if ply.nTeam == team then
      particle = ParticleManager:CreateParticleForPlayer(safeEffect, attach, targetEntity, PlayerResource:GetPlayer(plyID))--cmdPlayer:GetAssignedHero())
    else
      particle = ParticleManager:CreateParticleForPlayer(dangerEffect, attach, targetEntity, PlayerResource:GetPlayer(plyID))--cmdPlayer:GetAssignedHero())
    end
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,1,1)) -- endpoint
    ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
  end)
  -- Test Lua-particle generation

  -- Bots
  for k,v in pairs(DotaDashGameMode.vBots) do
    local particle = nil
    if team == DOTA_TEAM_GOODGUYS then
      particle = ParticleManager:CreateParticleForPlayer(safeEffect, attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    else
      particle = ParticleManager:CreateParticleForPlayer(dangerEffect, attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    end
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,1,1)) -- endpoint
    ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
  end
  
  -- Broadcasters
  for k,v in pairs(DotaDashGameMode.vBroadcasters) do
    local particle = nil
    if team == DOTA_TEAM_GOODGUYS then
      particle = ParticleManager:CreateParticleForPlayer(safeEffect, attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    else
      particle = ParticleManager:CreateParticleForPlayer(dangerEffect, attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    end
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,1,1)) -- endpoint
    ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
  end
 
  DotaDashGameMode:CreateTimer(DoUniqueString("circle"), {
    endTime = GameRules:GetGameTime() + duration,
    useGameTime = true,
    callback = function(reflex, args)
      if sound ~= nil then
        targetEntity:StopSound(sound)
      end
      targetEntity:Destroy()
    end
  })
end

function teamBasedWall(keys)
  local target = keys.Target
  local caster = keys.caster
  local duration = tonumber(keys.Duration) or 6
  
  if caster == nil or keys.EffectLineLength == nil then
		return
	end
  
  local length = tonumber(keys.EffectLineLength)
  
  local targetEntity = nil
    
  local attach = PATTACH_ABSORIGIN_FOLLOW
  
  local point = keys.target_points[1]
  local diff = point - caster:GetAbsOrigin()
  diff.z = 0
  diff = diff:Normalized()
  
  local vec = RotatePosition( Vector(0,0,0), QAngle(0, 90, 0), diff )
  local team = caster:GetTeam()
  
  targetEntity = CreateUnitByName("npc_dota_danger_indicator", point + (vec * length / 2), false, caster, caster, team)
  targetEntity:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  targetEntity:AddNewModifier(unit, nil, "modifier_phased", {})
  local ability = targetEntity:FindAbilityByName("reflex_dummy_unit")
  ability:SetLevel(1)
  
  DotaDashGameMode:LoopOverPlayers(function(ply, plyID)
    local particle = nil
    if ply.nTeam == team then
      particle = ParticleManager:CreateParticleForPlayer("ref_dark_seer_wall_of_replica", attach, targetEntity, PlayerResource:GetPlayer(plyID))--cmdPlayer:GetAssignedHero())
    else
      particle = ParticleManager:CreateParticleForPlayer("dark_seer_wall_of_replica", attach, targetEntity, PlayerResource:GetPlayer(plyID))--cmdPlayer:GetAssignedHero())
    end
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, point + (vec * length / -2)) -- endpoint
    ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
  end)
  -- Test Lua-particle generation

  -- Bots
  for k,v in pairs(DotaDashGameMode.vBots) do
    local particle = nil
    if team == DOTA_TEAM_GOODGUYS then
      particle = ParticleManager:CreateParticleForPlayer("ref_dark_seer_wall_of_replica", attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    else
      particle = ParticleManager:CreateParticleForPlayer("dark_seer_wall_of_replica", attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    end
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, point + (vec * length / -2)) -- endpoint
    ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
  end
  
  -- Broadcasters
  for k,v in pairs(DotaDashGameMode.vBroadcasters) do
    local particle = nil
    if team == DOTA_TEAM_GOODGUYS then
      particle = ParticleManager:CreateParticleForPlayer("ref_dark_seer_wall_of_replica", attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    else
      particle = ParticleManager:CreateParticleForPlayer("dark_seer_wall_of_replica", attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    end
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, point + (vec * length / -2)) -- endpoint
    ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
  end
  
  local endPoint = point + (vec * length / 2)
  
  for i=0,length,200 do
    dangerIndicator({
        caster = caster,
        Target = "POINT",
        target_points = { endPoint - vec * i },
        target_entities = {},
        Radius = 110,
        Duration = duration * 3.25
      })
  end
 
  DotaDashGameMode:CreateTimer(DoUniqueString("wall"), {
    endTime = GameRules:GetGameTime() + duration,
    useGameTime = true,
    callback = function(reflex, args)
      targetEntity:Destroy()
    end
  })
end

function dangerIndicator(keys)
  local target = keys.Target
  local caster = keys.caster
  local duration = tonumber(keys.Duration) or 6
  local noEnemy = keys.NoEnemy or nil
  
  if caster == nil or keys.Radius == nil then
		return
	end
  
  local radius = tonumber(keys.Radius)
  
  local targetEntity = nil
    
  local attach = PATTACH_ABSORIGIN_FOLLOW
  
  local point = nil
	if target == "POINT" and keys.target_points[1] then
		point = keys.target_points[1]
    targetEntity = CreateUnitByName("npc_dota_danger_indicator", point, false, nil, nil, DOTA_TEAM_NOTEAM)
    targetEntity:AddNewModifier(unit, nil, "modifier_invulnerable", {})
    targetEntity:AddNewModifier(unit, nil, "modifier_phased", {})
    local ability = targetEntity:FindAbilityByName("reflex_dummy_unit")
    ability:SetLevel(1)
	end
	if keys.target_entities[1] then
		targetEntity = keys.target_entities[1]
    attach = PATTACH_ABSORIGIN_FOLLOW
	end
	if target == "CASTER" then
		targetEntity = caster
    attach = PATTACH_ABSORIGIN_FOLLOW
	end
  
  local team = caster:GetTeam()
  --print ('team: ' .. team)
  
  DotaDashGameMode:LoopOverPlayers(function(ply, plyID)
    if noEnemy ~= nil and ply.nTeam ~= team then
      return
    end
    local particle = ParticleManager:CreateParticleForPlayer("generic_aoe_shockwave_1", attach, targetEntity, PlayerResource:GetPlayer(plyID))--cmdPlayer:GetAssignedHero())
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0)) -- radius
    ParticleManager:SetParticleControl(particle, 2, Vector(duration,0,1)) -- something
    if ply.nTeam == team and not ply.bColorblind then
      ParticleManager:SetParticleControl(particle, 3, Vector(0,200,0)) -- color
    elseif ply.nTeam == team and ply.bColorblind then
      ParticleManager:SetParticleControl(particle, 3, Vector(0,0,200)) -- color
    else
      ParticleManager:SetParticleControl(particle, 3, Vector(200,0,0)) -- color
    end
    ParticleManager:SetParticleControl(particle, 4, Vector(0,0,0)) -- something
  end)
  -- Test Lua-particle generation

  -- Bots
  for k,v in pairs(DotaDashGameMode.vBots) do
    local particle = ParticleManager:CreateParticleForPlayer("generic_aoe_shockwave_1", attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0)) -- radius
    ParticleManager:SetParticleControl(particle, 2, Vector(duration,0,1)) -- something
    if team == DOTA_TEAM_GOODGUYS then
      ParticleManager:SetParticleControl(particle, 3, Vector(0,200,0)) -- color
    else
      ParticleManager:SetParticleControl(particle, 3, Vector(200,0,0)) -- color
    end
    ParticleManager:SetParticleControl(particle, 4, Vector(0,0,0)) -- something
  end
  
  -- Broadcasters
  for k,v in pairs(DotaDashGameMode.vBroadcasters) do
    local particle = ParticleManager:CreateParticleForPlayer("generic_aoe_shockwave_1", attach, targetEntity, DotaDashGameMode.vUserIds[k])--cmdPlayer:GetAssignedHero())
    ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0)) -- radius
    ParticleManager:SetParticleControl(particle, 2, Vector(duration,0,1)) -- something
    if team == DOTA_TEAM_GOODGUYS then
      ParticleManager:SetParticleControl(particle, 3, Vector(0,200,0)) -- color
    else
      ParticleManager:SetParticleControl(particle, 3, Vector(200,0,0)) -- color
    end
    ParticleManager:SetParticleControl(particle, 4, Vector(0,0,0)) -- something
  end
  
  if target == "POINT" then
    DotaDashGameMode:CreateTimer(DoUniqueString("danger"), {
      endTime = GameRules:GetGameTime() + 0.5,
      useGameTime = true,
      callback = function(reflex, args)
        targetEntity:Destroy()
      end
    })
  end
end

function getItemByName( hero, name )
	if not hero:HasItemInInventory ( name ) then
		return nil
	end
	
	--print ( '[DOTADASH] find item in inventory' )
	-- Find item by slot
	for i=0,11 do
		--print ( '\t[DOTADASH] finding item ' .. i)
		local item = hero:GetItemInSlot( i )
		--print ( '\t[DOTADASH] item: ' .. tostring(item) )
		if item ~= nil then
			--print ( '\t[DOTADASH] getting ability name' .. i)
			local lname = item:GetAbilityName()
			--print ( string.format ('[DOTADASH] item slot %d: %s', i, lname) )
			if lname == name then
				return item
			end
		end
	end
	
	return nil
end
