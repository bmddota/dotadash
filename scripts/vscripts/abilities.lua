
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
    
    -- Find if we hit anyone
    local ent = Entities:FindByClassnameWithin(nil, "npc_dota_hero*", unit:GetAbsOrigin(), 150)
    if ent == caster then
      ent = Entities:FindByClassnameWithin(ent, "npc_dota_hero*", unit:GetAbsOrigin(), 150)
    end
    
    if ent ~= nil and ent.GetPhysicsVelocity ~= nil then
      local distance = ent:GetAbsOrigin() - shell:GetAbsOrigin()
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
          v:AddNewModifier(v, nil, "modifier_ember_spirit_searing_chains", {duration = 2.5})
        end
      end
      
      DotaDashGameMode:RemoveTimer(timer)
      shell:StopPhysicsSimulation()
      shell:Destroy()
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
  shell:SetPhysicsVelocityMax(1200)
  shell:Slide(false)
  shell:SetPhysicsFriction(0)
  
  local timer = DoUniqueString('redshell')
  
  shell:AddPhysicsVelocity(tonumber(keys.Speed) * forward)
  
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
      shell:SetPhysicsAcceleration(direction * 115 + Vector(0,0,GRAVITY_AMOUNT))
      
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
            v:AddNewModifier(v, nil, "modifier_ember_spirit_searing_chains", {duration = 2.5})
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
