print ('[DOTADASH] dotadash.lua' )

USE_LOBBY=true
DEBUG=false
THINK_TIME = 0.1

DOTADASH_VERSION = "0.04.07"

GRAVITY_AMOUNT = -15
SLIDE_MULTIPLIER = 0.30
FRICTION_MULTIPLIER = 0.04
BASE_MOVESPEED = 250
VELOCITY_MAX = 2600
VELOCITY_CLAMP = 10
TAKEOFF_VELOCITY = 500 / 30
NAV_LOOKAHEAD = 2
BOUNCE_MULTIPLIER = 0.8

LAPS_TO_WIN = 2
ROUNDS_TO_WIN = 3
ROUND_TIME = 60 --240
PRE_GAME_TIME = 30 -- 30
PRE_ROUND_TIME = 15 --30
POST_ROUND_TIME = 2
POST_GAME_TIME = 30

STARTING_GOLD = 500--650
GOLD_PER_ROUND_LOSER = 1150--750
GOLD_PER_ROUND_WINNER = 1150--1100
GOLD_PER_KILL = 300
GOLD_PER_MVP = 500
GOLD_PER_SURVIVE = 250
GOLD_TIME_BONUS_1 = 250
GOLD_TIME_BONUS_2 = 150
GOLD_TIME_BONUS_3 = 100

LEVELS_PER_ROUND_LOSER = 2.5 -- 2
LEVELS_PER_ROUND_WINNER = 1.25 -- 1
MAX_LEVEL = 50

XP_PER_LEVEL_TABLE = {}

for i=1,MAX_LEVEL do
  XP_PER_LEVEL_TABLE[i] = i * 100
end

POINTS_PER_POSITION = {
  13,
  10,
  8,
  7,
  6,
  5,
  4,
  3,
  2,
  1
}

-- FILL MAP_DATA
require("map_" .. GetMapName())
if MAP_DATA.anggrid then
  Physics:AngleGrid(MAP_DATA.anggrid, MAP_DATA.angoffset)
end

-- Adjust globals
SPAWNS = MAP_DATA.spawns
GRAVITY_AMOUNT = MAP_DATA.gravity or GRAVITY_AMOUNT
SLIDE_MULTIPLIER = MAP_DATA.slideMultiplier or SLIDE_MULTIPLIER
FRICTION_MULTIPLIER = MAP_DATA.friction or FRICTION_MULTIPLIER
BASE_MOVESPEED = MAP_DATA.baseMovespeed or BASE_MOVESPEED
VELOCITY_MAX = MAP_DATA.velocityMax or VELOCITY_MAX
VELOCITY_CLAMP = MAP_DATA.velocityClamp or VELOCITY_CLAMP
TAKEOFF_VELOCITY = MAP_DATA.takeoffVelocity or TAKEOFF_VELOCITY
NAV_LOOKAHEAD = MAP_DATA.lookahead or NAV_LOOKAHEAD
BOUNCE_MULTIPLIER = MAP_DATA.bounceMultiplier or BOUNCE_MULTIPLIER

LAPS_TO_WIN = MAP_DATA.lapsToWin or LAPS_TO_WIN
ROUNDS_TO_WIN = MAP_DATA.roudsToWin or ROUNDS_TO_WIN


ITEMS_BEHIND = {
  {item_blue_turtle_shell = .5},
  {item_lightning_bolt = .35},
  {item_star_power = .70},
  {item_rocket_boots = 2},
  {item_green_turtle_shell = 1},
  {item_red_turtle_shell = 1},
  {item_banana_peel = 1},
  {item_banana_peel3 = 1}
}

ITEMS_TABLE = {
  {item_blue_turtle_shell = 0.25},
  {item_lightning_bolt = 0.20},
  {item_star_power = 0.3},
  {item_rocket_boots = 1},
  {item_green_turtle_shell = 1},
  {item_red_turtle_shell = 1},
  {item_banana_peel = 1},
  {item_banana_peel3 = .5}
}

ITEMS_FIRST = {
  {item_rocket_boots = .5},
  {item_green_turtle_shell = 1},
  {item_red_turtle_shell = 1},
  {item_banana_peel = 1}
}

bInPreRound = true
roundOne = true

if DotaDashGameMode == nil then
  print ( '[DOTADASH] creating DotaDash game mode' )
  DotaDashGameMode = {}
  DotaDashGameMode.szEntityClassName = "dotadash"
  DotaDashGameMode.szNativeClassName = "dota_base_game_mode"
  DotaDashGameMode.__index = DotaDashGameMode
end

function DotaDashGameMode:new( o )
  print ( '[DOTADASH] DotaDashGameMode:new' )
  o = o or {}
  setmetatable( o, DotaDashGameMode )
  return o
end

function DotaDashGameMode:InitGameMode()
  print('[DOTADASH] Starting to load DotaDash gamemode...')

  ITEMS_BEHIND = scaleTable(ITEMS_BEHIND)
  ITEMS_TABLE = scaleTable(ITEMS_TABLE)
  ITEMS_FIRST = scaleTable(ITEMS_FIRST)
  
  -- Setup rules
  GameRules:SetHeroRespawnEnabled( false )
  GameRules:SetUseUniversalShopMode( true )
  GameRules:SetSameHeroSelectionEnabled( false )
  GameRules:SetHeroSelectionTime( 30.0 )
  GameRules:SetPreGameTime( PRE_ROUND_TIME + PRE_GAME_TIME)
  GameRules:SetPostGameTime( 60.0 )
  GameRules:SetUseCustomHeroXPValues ( true )
  GameRules:SetGoldPerTick(0)

  GameRules:SetRuneSpawnTime(10000)
  GameRules:SetTreeRegrowTime(10000)
  print('[DOTADASH] Rules set')

  InitLogFile( "log/dotadash.txt","")

  -- Hooks
  ListenToGameEvent('entity_killed', Dynamic_Wrap(DotaDashGameMode, 'OnEntityKilled'), self)
  --ListenToGameEvent('dota_player_kill', Dynamic_Wrap(DotaDashGameMode, 'OnPlayerKilled'), self)
  print('[DOTADASH] entity_killed event set')
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(DotaDashGameMode, 'AutoAssignPlayer'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(DotaDashGameMode, 'CleanupPlayer'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(DotaDashGameMode, 'ShopReplacement'), self)
  ListenToGameEvent('player_say', Dynamic_Wrap(DotaDashGameMode, 'PlayerSay'), self)
  ListenToGameEvent('player_connect', Dynamic_Wrap(DotaDashGameMode, 'PlayerConnect'), self)
  --ListenToGameEvent('dota_inventory_changed', Dynamic_Wrap(DotaDashGameMode, 'InventoryChanged'), self)
  --ListenToGameEvent('dota_inventory_item_changed', Dynamic_Wrap(DotaDashGameMode, 'InventoryItemChanged'), self)
  --ListenToGameEvent('dota_action_item', Dynamic_Wrap(DotaDashGameMode, 'ActionItem'), self)
  ListenToGameEvent('dota_rune_spotted', Dynamic_Wrap(DotaDashGameMode, 'RuneSpotted'), self)
  ListenToGameEvent('dota_rune_pickup', Dynamic_Wrap(DotaDashGameMode, 'RunePickup'), self)
  ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(DotaDashGameMode, 'RuneActivated'), self)
  
  ------
  --ListenToGameEvent('player_info', Dynamic_Wrap(DotaDashGameMode, 'PlayerInfo'), self)
  --ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(DotaDashGameMode, 'AbilityUsed'), self)

  local function _boundWatConsoleCommand(...)
    return self:_WatConsoleCommand(...)
  end
  Convars:RegisterCommand( "dash_wat", _boundWatConsoleCommand, "Report the status of DotaDash", 0 )
  print('[DOTADASH] dash_wat set')

  Convars:RegisterCommand('dash_reset_all', function()
    if not Convars:GetCommandClient() or DEBUG then      
      self:LoopOverPlayers(function(player, plyID)
        print ( '[DOTADASH] Resetting player ' .. plyID)
        --PlayerResource:SetGold(plyID, 30000, true)
        player.hero:SetGold(30000, true)
        player.hero:AddExperience(1000, true)

        if player.hero:HasModifier("modifier_stunned") then
          player.hero:RemoveModifierByName("modifier_stunned")
        end

        if player.hero:HasModifier("modifier_invulnerable") then
          player.hero:RemoveModifierByName("modifier_invulnerable")
        end
        
        player.hero:Slide(true)
        player.hero:SkipSlide(5)
      end)
    end
  end, 'Resets all players.', 0)
  
  -- Fill server with fake clients
  Convars:RegisterCommand('fake', function()
    -- Check if the server ran it
    if not Convars:GetCommandClient() or DEBUG then
      -- Create fake Players
      SendToServerConsole('dota_create_fake_clients')
      
      local fakes = {
        "npc_dota_hero_ancient_apparition",
        "npc_dota_hero_antimage",
        "npc_dota_hero_bane",
        "npc_dota_hero_beastmaster",
        "npc_dota_hero_bloodseeker",
        "npc_dota_hero_chen",
        "npc_dota_hero_crystal_maiden",
        "npc_dota_hero_dark_seer",
        "npc_dota_hero_dazzle",
        "npc_dota_hero_dragon_knight",
        "npc_dota_hero_doom_bringer"
      }
        
      self:CreateTimer('assign_fakes', {
        endTime = Time(),
        callback = function(reflex, args)
          local userID = 20
          for i=0, 9 do
            -- Check if this player is a fake one
            if PlayerResource:IsFakeClient(i) then
              -- Grab player instance
              local ply = PlayerResource:GetPlayer(i)
              -- Make sure we actually found a player instance
              if ply then
                userID = userID + 1
                CreateHeroForPlayer(fakes[i], ply)
                self:AutoAssignPlayer({
                  userid = userID,
                  index = ply:entindex()-1
                })
              end
            end
          end
          
          local ply = Convars:GetCommandClient()
          local plyID = ply:GetPlayerID()
          local hero = ply:GetAssignedHero()
          for k,v in pairs(HeroList:GetAllHeroes()) do
            if v ~= hero then
              v:SetControllableByPlayer(plyID, true)
            end
          end
        end})
    end
  end, 'Connects and assigns fake Players.', 0)
  
  Convars:RegisterCommand('dash_test_round_complete', function()
    local cmdPlayer = Convars:GetCommandClient()
    if DEBUG then
      self:RoundComplete(true)
    end
  end, 'Tests the death function', 0)

  -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
  math.randomseed(tonumber(timeTxt))

  self.nConnected = 0

  -- Round stuff
  self.nCurrentRound = 0
  self.nCurrentLap = 1
  self.nFinishLineCrossed = 0
  self.vPositions = {}

  -- Timers
  self.timers = {}

  -- userID map
  self.vUserNames = {}
  self.vUserIds = {}
  self.vSteamIds = {}
  self.vBots = {}
  self.vBroadcasters = {}

  self.vPlayers = {}
  self.vRadiant = {}
  self.vDire = {}

  self.WALLS = {}

  -- Active Hero Map
  self.vPlayerHeroData = {}
  self.bPlayersInit = false
  print('[DOTADASH] values set')

  print('[DOTADASH] Precaching stuff...')
  PrecacheUnitByName('npc_precache_everything')
  print('[DOTADASH] Done precaching!') 

  self.thinkState = Dynamic_Wrap( DotaDashGameMode, '_thinkState_Prep' )
  
  SendToServerConsole("sv_alltalk 1")

  print('[DOTADASH] Done loading DotaDash gamemode!\n\n')
end

GameMode = nil

function DotaDashGameMode:CaptureGameMode()
  if GameMode == nil then
    print('[DOTADASH] Capturing game mode...')
    GameMode = GameRules:GetGameModeEntity()    
    GameMode:SetRecommendedItemsDisabled( true )
    GameMode:SetCameraDistanceOverride( 1600.0 )
    GameMode:SetCustomBuybackCostEnabled( true )
    GameMode:SetCustomBuybackCooldownEnabled( true )
    GameMode:SetBuybackEnabled( false )
    GameMode:SetUseCustomHeroLevels ( true )
    GameMode:SetCustomHeroMaxLevel ( MAX_LEVEL )
    GameMode:SetTopBarTeamValuesOverride ( true )
    GameMode:SetRemoveIllusionsOnDeath( false )

    GameMode:SetFogOfWarDisabled(true)
    --GameRules:SetHeroMinimapIconSize( 300 )

    GameMode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

    print( '[DOTADASH] Beginning Think' ) 
    GameMode:SetContextThink("DotaDashThink", Dynamic_Wrap( DotaDashGameMode, 'Think' ), 0.1 )
    
    -- Collision thinker
    Physics:CreateTimer('collision',{
      endTime = GameRules:GetGameTime(),
      useGameTime = true,
      callback = function(reflex, args)
        -- Collision for heroes
        local heroes = {}
        for k,unit in pairs(HeroList:GetAllHeroes()) do 
          local index = unit:entindex()
          local ents = Entities:FindAllInSphere(unit:GetAbsOrigin(), 100)
          
          if heroes[index] == nil and unit.vVelocity ~= nil then
            heroes[index] = unit
            for k,v in pairs(ents) do
              if v ~= unit and v.vVelocity ~= nil and string.find(v:GetClassname(), "npc_dota_hero") then
                -- Found a hero to collide with
                local pos = unit:GetAbsOrigin()
                local vPos = v:GetAbsOrigin()
                local dir = vPos - pos
                dir.z = 0
                dir = dir:Normalized()
                
                local neg = -1 * dir
                
                local dot = dir:Dot(unit.vVelocity)
                local dot2 = neg:Dot(v.vVelocity)
                
                if dot < 5 and dot2 < 5 then
                  break
                end
                --[[print(unit:GetClassname() .. " -- " .. v:GetClassname())
                print(tostring(pos) .. " -- " .. tostring(vPos))
                print(tostring(dir) .. " -- " .. tostring(neg))
                print(tostring(dot) .. " -- " .. tostring(dot2))
                print(tostring(unit.vVelocity) .. " -- " .. tostring(v.vVelocity))
                print("-------------------------")]]
                local now = GameRules:GetGameTime()
                local collide = true
                if ((unit.bStarPower or unit.bLightningBolt) and (v.nHitTime ~= nil and v.nHitTime + .5 > now)) then
                  collide = false
                end
                if ((v.bStarPower or v.bLightningBolt) and (unit.nHitTime ~= nil and unit.nHitTime + .5 > now)) then
                  collide = false
                end

                if collide then
                  if unit.bStarPower then
                    local vel = ((dot * dir) - (dot2 * neg)) * 2
                    v:AddPhysicsVelocity(Vector(vel.x,vel.y,650))
                    v.nHitTime = now
                    v:EmitSound("Hero_Spirit_Breaker.GreaterBash")
                  elseif v.bStarPower then
                    local vel = ((dot * neg) - (dot2 * dir)) * 2
                    unit:AddPhysicsVelocity(Vector(vel.x,vel.y,650))
                    unit.nHitTime = now
                    unit:EmitSound("Hero_Spirit_Breaker.GreaterBash")
                  elseif unit.bLightningBolt then
                    v.vVelocity = Vector(v.vVelocity.x / 5, v.vVelocity.y / 5, v.vVelocity.z)
                    v:AddNewModifier(v, nil, "modifier_ember_spirit_searing_chains", {duration = 1.5})
                    v.nHitTime = now
                    v:EmitSound("DotaDash.LightningHit")
                  elseif v.bLightningBolt then
                    unit.vVelocity = Vector(unit.vVelocity.x / 5, unit.vVelocity.y / 5, unit.vVelocity.z)
                    unit:AddNewModifier(unit, nil, "modifier_ember_spirit_searing_chains", {duration = 1.5})
                    unit.nHitTime = now
                    unit:EmitSound("DotaDash.LightningHit")
                  else
                    unit.vVelocity = unit.vVelocity + (dot * neg) - (dot2 * dir)
                    v.vVelocity = v.vVelocity + (dot * dir) - (dot2 * neg)
                  end
                end
                
                heroes[v:entindex()] = v
                break
              end
            end
          end
          
          -- Powerup collision
          for k,v in pairs(ents) do
            if v.bBlockActive and not hasPowerup(unit) then
              v.bBlockActive = false
              v:AddNewModifier(v, nil, "modifier_puck_phase_shift", {duration = 5})
              
              EmitSoundOnClient("Item.DropGemShop", PlayerResource:GetPlayer(unit:GetPlayerID()))
              local item = CreateItem("item_powerup", unit, unit)
              unit:AddItem(item)
              
              DotaDashGameMode:CreateTimer(DoUniqueString("blockhit"), {
                useGameTime = true,
                endTime = GameRules:GetGameTime() + 5,
                callback = function(reflex, args)
                  v.bBlockActive = true
                end
              })
              
              DotaDashGameMode:CreateTimer(DoUniqueString("unwrap"), {
                useGameTime = true,
                endTime = GameRules:GetGameTime() + 3,
                callback = function(reflex, args)
                  if IsValidEntity(item) then
                    item:Destroy()
                    
                    local playerID = unit:GetPlayerID()
                    
                    local position = 1
                    for i=1,#self.vPositions do
                      if self.vPositions[i].playerID == playerID then
                        position = i
                        break
                      end
                    end
                    
                    EmitSoundOnClient("Item.PickUpGemShop", PlayerResource:GetPlayer(unit:GetPlayerID()))
                    --local blueShellPerc = ((position - 1) * 2.5) * (10 / (#self.vPlayers + 1))
                    local isBehind = (position / (#self.vPlayers + 1)) > .5
                    local roll = RandomFloat(0.0,100.0)
                    local index = nil
                    local rollTable = ITEMS_TABLE
                    if position == 1 then
                      rollTable = ITEMS_FIRST
                    elseif isBehind then
                      rollTable = ITEMS_BEHIND
                    end
                    
                    for i=1,#rollTable do
                      local v2 = nil
                      for k,v in pairs(rollTable[i]) do
                        index = k
                        v2 = v
                      end
                      if v2 >= roll then
                        break
                      end
                    end
                    
                    item = CreateItem(index, unit, unit)
                    unit:AddItem(item)
                  end
                end
              })
            end
          end
        end
        
        return GameRules:GetGameTime()
      end})
  end
end

--[[function DotaDashGameMode:AbilityUsed(keys)
  print('[DOTADASH] AbilityUsed')
  PrintTable(keys)
  PrintTable(getmetatable(keys))
  
  local ent = Entities:First()
  repeat
    print('\t[DOTADASH] ENTName: ' .. tostring(ent:GetName()) .. " -- ClassName: " .. tostring(ent:GetClassname()) .. " -- entindex: " .. tostring(ent:entindex()))
    PrintTable(ent)
    PrintTable(getmetatable(ent))
    ent = Entities:Next(ent)
  until ent == nil
end]]

-- Cleanup a player when they leave
function DotaDashGameMode:CleanupPlayer(keys)
  print('[DOTADASH] Player Disconnected ' .. tostring(keys.userid))
  self.nConnected = self.nConnected - 1
end

function DotaDashGameMode:ActionItem(keys)
  print('ActionItem')
  PrintTable(keys)
  PrintTable(getmetatable(keys))
end

function DotaDashGameMode:InventoryItemChanged(keys)
  print('InventoryItemChanged')
  PrintTable(keys)
  PrintTable(getmetatable(keys))
end

function DotaDashGameMode:InventoryChanged(keys)
  print('InventoryChanged')
  PrintTable(keys)
  PrintTable(getmetatable(keys))
end

--dota_rune_spotted
function DotaDashGameMode:RuneSpotted(keys)
  print('RuneSpotted')
  PrintTable(keys)
end

--dota_rune_pickup
function DotaDashGameMode:RunePickup(keys)
  print('RunePickup')
  PrintTable(keys)
end

--dota_rune_activated_server
function DotaDashGameMode:RuneActivated(keys)
  print('RuneActivated')
  PrintTable(keys)
end

function DotaDashGameMode:CloseServer()
  -- Just exit
  --SendToServerConsole('exit')
end

function DotaDashGameMode:PlayerConnect(keys)
  --print('[DOTADASH] PlayerConnect')
  --PrintTable(keys)
  self.vUserNames[keys.userid] = keys.name
  if keys.bot == 1 then
    self.vBots[keys.userid] = 1
  end
end

local attach = 0
local controlPoints = {}
local particleEffect = ""
local abilPoints = false
local particle = nil
local paused = nil
local unitNum = 0
local units = {}

function DotaDashGameMode:PlayerSay(keys)
  --print ('[DOTADASH] PlayerSay')
  --PrintTable(keys)
  
  local ply = self.vUserIds[keys.userid]
  if ply == nil then
    return
  end
  
  local plyID = ply:GetPlayerID()
  if not PlayerResource:IsValidPlayer(plyID) then
    return
  end
  
  local player = self.vPlayers[plyID]
  if player == nil then
    return
  end
  
  -- Should have a valid, in-game player saying something at this points/gold
  local text = keys.text
  
  if string.find(text, "^-dmg") then
    if string.find(text, "all") then
      local team = player.nTeam
      self:LoopOverPlayers(function(player, plyID)
        if player.nTeam == team then
          local name = player.name
          local total = PlayerResource:GetRawPlayerDamage(plyID)
          local roundDamage = player.nRoundDamage
          Say(ply, " _ " .. name .. ":  Last Round: " .. roundDamage .. "  --  Total: " .. total, true)
        end
      end)
    else
      local name = player.name
      local total = PlayerResource:GetRawPlayerDamage(plyID)
      local roundDamage = player.nRoundDamage
      Say(ply, " _ " .. name .. ":  Last Round: " .. roundDamage .. "  --  Total: " .. total, true)
    end
  end
  
  local lvl1 = string.match(text, "^-lvl%s+(%d+)")
  if DEBUG and lvl1 ~= nil then
    local num = tonumber(lvl1)
    for k,v in pairs(HeroList:GetAllHeroes()) do
      for i=1,num do
        v:HeroLevelUp(false)
      end
    end
  end

  if DEBUG and string.find(text, "^-regrow") then
    GridNav:RegrowAllTrees()
  end

  if DEBUG and string.find(text, "^-spider") then
    local mapGnv = {}
    local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
    local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)

    print(worldMin)
    print(worldMax)

    local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
    local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
    local boundY1 = GridNav:WorldToGridPosX(worldMin.y)
    local boundY2 = GridNav:WorldToGridPosX(worldMax.y)

    print(boundX1 .. " -- " .. boundX2)
    print(boundY1 .. " -- " .. boundY2)

    print('----------------------')

    InitLogFile("addons/dotadash/spider.txt", "")
    AppendToLogFile("addons/dotadash/spider.txt", "P1")
    AppendToLogFile("addons/dotadash/spider.txt", "#spider created pbm")
    AppendToLogFile("addons/dotadash/spider.txt", tostring(boundX2 - boundX1 + 1) .. " " .. tostring(boundY2 - boundY1 + 1))

    local pseudoGNV = {}
    local WALLS = self.WALLS
    for i=1,#WALLS do
      local from = WALLS[i].from
      local to = WALLS[i].to
      local cur = from
      local dist = to - from
      dist.z = 0
      local dir = dist:Normalized()
      dist = dist:Length()
      local norm = RotatePosition(Vector(0,0,0), QAngle(0,90,0), dir)

      for j=1,math.floor(dist/30) do
        local pos = cur + norm * 64
        local pos2 = cur - norm * 64
        local x = GridNav:WorldToGridPosX(pos.x)
        local y = GridNav:WorldToGridPosY(pos.y)
        if pseudoGNV[x] == nil then
          pseudoGNV[x] = {}
        end
        pseudoGNV[x][y] = true

        x = GridNav:WorldToGridPosX(pos2.x)
        y = GridNav:WorldToGridPosY(pos2.y)
        if pseudoGNV[x] == nil then
          pseudoGNV[x] = {}
        end
        pseudoGNV[x][y] = true

        x = GridNav:WorldToGridPosX(cur.x)
        y = GridNav:WorldToGridPosY(cur.y)
        if pseudoGNV[x] == nil then
          pseudoGNV[x] = {}
        end
        pseudoGNV[x][y] = true

        cur = from + dir*j*30
      end

      cur = to
      local pos = cur + norm * 64
      local pos2 = cur - norm * 64
      local blocked = not GridNav:IsTraversable(pos) or GridNav:IsBlocked(pos)
      if blocked then
        local x = GridNav:WorldToGridPosX(pos.x)
        local y = GridNav:WorldToGridPosY(pos.y)
        if pseudoGNV[x] == nil then
          pseudoGNV[x] = {}
        end
        pseudoGNV[x][y] = true
      end

      blocked = not GridNav:IsTraversable(pos2) or GridNav:IsBlocked(pos2)
      if blocked then
        local x = GridNav:WorldToGridPosX(pos2.x)
        local y = GridNav:WorldToGridPosY(pos2.y)
        if pseudoGNV[x] == nil then
          pseudoGNV[x] = {}
        end
        pseudoGNV[x][y] = true
      end

      blocked = not GridNav:IsTraversable(cur) or GridNav:IsBlocked(cur)
      if blocked then
        local x = GridNav:WorldToGridPosX(cur.x)
        local y = GridNav:WorldToGridPosY(cur.y)
        if pseudoGNV[x] == nil then
          pseudoGNV[x] = {}
        end
        pseudoGNV[x][y] = true
      end
    end

    --PrintTable(pseudoGNV)
    --print('---------------')

    local s = ""

    for i=boundY2,boundY1,-1 do
      for j=boundX1,boundX2 do
        local position = Vector(GridNav:GridPosToWorldCenterX(j), GridNav:GridPosToWorldCenterY(i), 0)
        local blocked = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position) or (pseudoGNV[j] ~= nil and pseudoGNV[j][i])

        if blocked then
          s = s .. "1"
        else
          s = s .. "0"
        end

        if j == boundX2 then
          AppendToLogFile("addons/dotadash/spider.txt", s)
          s = ""
        else
          s = s .. " "
        end
      end
    end
  end

  if DEBUG and string.find(text, "^-anggrid") then
    local timestamp = GetSystemDate() .. " " .. GetSystemTime()
    timestamp = timestamp:gsub(":","_"):gsub(" ","_")
    local fileName = "log/" .. GetMapName() .. timestamp .. ".txt"
    print(fileName)

    local anggrid = {}
    local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
    local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)

    print(worldMin)
    print(worldMax)

    local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
    local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
    local boundY1 = GridNav:WorldToGridPosX(worldMin.y)
    local boundY2 = GridNav:WorldToGridPosX(worldMax.y)
    local offsetX = boundX1 * -1 + 1
    local offsetY = boundY1 * -1 + 1

    print(boundX1 .. " -- " .. boundX2)
    print(boundY1 .. " -- " .. boundY2)
    print(offsetX)
    print(offsetY)

    local vecs = {
      {vec = Vector(0,1,0):Normalized(), x=0,y=1},-- N
      {vec = Vector(1,1,0):Normalized(), x=1,y=1}, -- NE
      {vec = Vector(1,0,0):Normalized(), x=1,y=0}, -- E
      {vec = Vector(1,-1,0):Normalized(), x=1,y=-1}, -- SE
      {vec = Vector(0,-1,0):Normalized(), x=0,y=-1}, -- S
      {vec = Vector(-1,-1,0):Normalized(), x=-1,y=-1}, -- SW
      {vec = Vector(-1,0,0):Normalized(), x=-1,y=0}, -- W
      {vec = Vector(-1,1,0):Normalized(), x=-1,y=1} -- NW
    }

    print('----------------------')

    anggrid[1] = {}
    for j=boundY1,boundY2 do
      anggrid[1][j + offsetY] = -1
    end
    anggrid[1][boundY2 + offsetY] = -1

    for i=boundX1+1,boundX2-1 do
      anggrid[i+offsetX] = {}
      anggrid[i+offsetX][1] = -1
      for j=(boundY1+1),boundY2-1 do
        local position = Vector(GridNav:GridPosToWorldCenterX(i), GridNav:GridPosToWorldCenterY(j), 0)
        local blocked = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position) --or (pseudoGNV[i] ~= nil and pseudoGNV[i][j])
        local seg = 0
        local sum = Vector(0,0,0)
        local count = 0
        local inseg = false

        if blocked then
          for k=1,#vecs do
            local vec = vecs[k].vec
            local xoff = vecs[k].x
            local yoff = vecs[k].y
            local pos = Vector(GridNav:GridPosToWorldCenterX(i+xoff), GridNav:GridPosToWorldCenterY(j+yoff), 0)
            local blo = not GridNav:IsTraversable(pos) or GridNav:IsBlocked(pos) --or (pseudoGNV[i+xoff] ~= nil and pseudoGNV[i+xoff][j+yoff])

            if not blo then
              count = count + 1
              inseg = true
              sum = sum + vec
            else
              if inseg then
                inseg = false
                seg = seg + 1
              end
            end
          end

          if seg > 1 then
            print ('OVERSEG x=' .. i .. ' y=' .. j)
            anggrid[i+offsetX][j+offsetY] = -1
          elseif count > 5 then
            print ('PROTRUDE x=' .. i .. ' y=' .. j)
            anggrid[i+offsetX][j+offsetY] = -1
          elseif count == 0 then
            anggrid[i+offsetX][j+offsetY] = -1
          else
            local sum = sum:Normalized()
            local angle = math.floor((math.acos(Vector(1,0,0):Dot(sum:Normalized()))/ math.pi * 180))
            if sum.y < 0 then
              angle = -1 * angle
            end
            anggrid[i+offsetX][j+offsetY] = angle
          end
        else
          anggrid[i+offsetX][j+offsetY] = -1
        end
      end
      anggrid[i+offsetX][boundY2+offsetY] = -1
    end

    anggrid[boundX2+offsetX] = {}
    for j=boundY1,boundY2 do
      anggrid[boundX2+offsetX][j+offsetY] = -1
    end
    anggrid[boundX2+offsetX][boundY2+offsetY] = -1

    print('--------------')
    print(#anggrid)
    print(#anggrid[1])
    print(#anggrid[2])
    print(#anggrid[3])

    MAP_DATA.anggrid = anggrid
    Physics:AngleGrid(anggrid)
  end
  
  local ap = abilPoints

  local fname = string.match(text, "^-angsave%s+(.+)")
  if DEBUG and fname ~= nil then
    -- Process map
    local addString = function (stack, s)
        table.insert(stack, s)    -- push 's' into the the stack
        for i=table.getn(stack)-1, 1, -1 do
          if string.len(stack[i]) > string.len(stack[i+1]) then
            break
          end
          stack[i] = stack[i] .. table.remove(stack)
        end
      end

    local s = {""}
    addString(s, "{")
    local anggrid = Physics.anggrid
    for x=1,#anggrid do
      addString(s, "{")
      for y=1,#anggrid[x] do
        addString(s, tostring(anggrid[x][y]))
        if y < #anggrid[x] then
          addString(s, ",")
        end
      end
      addString(s, "}")
      if x < #anggrid then
        addString(s, ",")
      end
    end
    addString(s, "}")

    s = table.concat(s)
    print('------------')
    print(fname)
    print(s)

    InitLogFile("addons/dotadash/" .. fname .. ".txt", s)
  end

  if DEBUG and string.find(text, "^-points") then
    for k,v in pairs(HeroList:GetAllHeroes()) do
      if ap then
        abilPoints = false
        v:SetAbilityPoints(0)
      else
        abilPoints = true
        v:SetAbilityPoints(25)
      end
    end
  end
  
  if DEBUG and string.find(text, "^-res") then
    local m = string.match(text, "(%d)")
    if m ~= nil then
      local p = PlayerResource:GetPlayer(tonumber(m))
      local v = p:GetAssignedHero()
      v:SetRespawnPosition(v:GetAbsOrigin())
      v:RespawnHero(false, false, false)
    else 
      for k,v in pairs(HeroList:GetAllHeroes()) do
        if not v:IsAlive() then
          v:SetRespawnPosition(v:GetAbsOrigin())
          v:RespawnHero(false, false, false)
        end
      end
    end
  end
  
  if DEBUG and string.find(text, "^-units") then
    local m = string.match(text, "(%d+)")
    if m ~= nil then
      unitNum = unitNum + m
      print (unitNum)
      for i=1,m do 
        local unit = CreateUnitByName('npc_dummy_blank', player.hero:GetAbsOrigin(), true, player.hero, player.hero, player.hero:GetTeamNumber())
        unit:AddNewModifier(unit, nil, "modifier_phased", {})
        unit:SetModel('models/heroes/lycan/lycan_wolf.mdl')
        unit:SetOriginalModel('models/heroes/lycan/lycan_wolf.mdl')
        
        Physics:Unit(unit)
        unit:SetPhysicsFriction(0)
        unit:SetPhysicsVelocity(RandomVector(2000))
        unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      end
    end
  end
  
  if DEBUG and string.find(text, "^-findent") then
    local ent = Entities:FindAllInSphere(player.hero:GetAbsOrigin(), 100)
    for k,v in pairs(ent) do
      print(tostring(k) .. " -- " .. v:GetClassname() .. " -- " .. v:GetName())
    end
    print('=====================')
  end
  
  if DEBUG and string.find(text, "^-entprint") then
    local m = string.match(text, "(%d+)")
    if m == nil then
      local ent = Entities:First()
      while ent ~= nil do
        print(tostring(ent:entindex()) .. " -- " .. ent:GetClassname() .. " -- " .. ent:GetName())
        ent = Entities:Next(ent)
      end
    else
      local ent = Entities:FindInSphere(nil, player.hero:GetAbsOrigin(), tonumber(m))
      while ent ~= nil do
        print(tostring(ent:entindex()) .. " -- " .. ent:GetClassname() .. " -- " .. ent:GetName())
        ent = Entities:FindInSphere(ent, player.hero:GetAbsOrigin(), tonumber(m))
      end
    end
  end
  
  if DEBUG and string.find(text, "^-hibtest") then
    local m = string.match(text, "(%d+)")
    if m ~= nil and m == "0" then
      self:CreateTimer('units2',{
        useGameTime = true,
        endTime = GameRules:GetGameTime(),
        callback = function(reflex, args)
          local pushNum = math.floor(#units / 10) + 1
          for i=1,pushNum do
            local unit = units[RandomInt(1, #units)]
            unit:AddPhysicsVelocity(RandomVector(RandomInt(1000,2000)))
          end
          
          return GameRules:GetGameTime() + 1
        end
      })
    elseif m ~= nil then
      unitNum = unitNum + m
      print (unitNum)
      for i=1,m do 
        local unit = CreateUnitByName('npc_dummy_blank', player.hero:GetAbsOrigin(), true, player.hero, player.hero, player.hero:GetTeamNumber())
        unit:AddNewModifier(unit, nil, "modifier_phased", {})
        unit:SetModel('models/heroes/lycan/lycan_wolf.mdl')
        unit:SetOriginalModel('models/heroes/lycan/lycan_wolf.mdl')
        
        Physics:Unit(unit)
        unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
        
        units[#units + 1] = unit
      end
    end
  end
  
  if DEBUG and string.find(text, "^-tractor") then
    local m = string.match(text, "(%d)")
    if m ~= nil then
      local p = PlayerResource:GetPlayer(tonumber(m))
      local target = p:GetAssignedHero()
      local source = player.hero
      
      target:SetPhysicsVelocityMax(500)
      target:PreventDI()
      
      local direction = source:GetAbsOrigin() - target:GetAbsOrigin()
      direction = direction:Normalized()
      target:SetPhysicsAcceleration(direction * 50)
      
      target:OnPhysicsFrame(function(unit)
        -- Retarget acceleration vector
        local distance = source:GetAbsOrigin() - target:GetAbsOrigin()
        local direction = distance:Normalized()
        target:SetPhysicsAcceleration(direction * 50)
        
        -- Stop if reached the unit
        if distance:Length() < 100 then
          target:SetPhysicsAcceleration(Vector(0,0,0))
          target:SetPhysicsVelocity(Vector(0,0,0))
          target:OnPhysicsFrame(nil)
        end
      end)
    end
  end
  
  if DEBUG and string.find(text, "^-gold") then
    for k,v in pairs(HeroList:GetAllHeroes()) do
      v:SetGold(50000, true)
      GameRules:SetUseUniversalShopMode( true )
    end
  end
  
  if DEBUG and string.find(text, "^-waypoints") then
    local mapdata = MAP_DATA
    if mapdata == nil then
      print('[DOTADASH] ERROR: NO MAP DATA FOR THIS RACE')
    else
      local waypoints = mapdata.waypoints
      for i=1,#waypoints do
        local waypoint = waypoints[i]
        PrintTable(waypoint)
        print('------------------')
        local unit = CreateUnitByName('npc_dota_danger_indicator', waypoint.from, false, nil, nil, DOTA_TEAM_NOTEAM)
        --unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
        --unit:AddNewModifier(unit, nil, "modifier_phased", {})
        local ability = unit:FindAbilityByName("reflex_dummy_unit")
        --ability:SetLevel(1)
        
        local particleName = waypoint.particle or "dark_seer_wall_of_replica"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, unit)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
        ParticleManager:SetParticleControl(particle, 1, waypoint.to) -- endpoint
        ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
      end
    end
  end
  
  if DEBUG and string.find(text, "^-phys") then
    --PlayerResource:SetCameraTarget(plyID, player.hero)
    --player.hero:AddNewModifier(player.hero, nil, "modifier_camera_follow", {})
  end
  
  local vel1,vel2,vel3 = string.match(text, "^-vel%s+(-?%d+)%s+(-?%d+)%s+(-?%d+)")
  if DEBUG and vel1 ~= nil and vel2 ~= nil and vel3 ~= nil then
    player.hero:AddPhysicsVelocity(Vector(tonumber(vel1), tonumber(vel2), tonumber(vel3)))
  end
  
  local velmax1 = string.match(text, "^-velmax%s+(%d+)")
  if DEBUG and velmax1 ~= nil then
    player.hero:SetPhysicsVelocityMax(tonumber(velmax1))
    print('-velmax' .. tonumber(velmax1))
  end
  
  local acc1,acc2,acc3 = string.match(text, "^-acc%s+(-?%d+)%s+(-?%d+)%s+(-?%d+)")
  if DEBUG and acc1 ~= nil and acc2 ~= nil and acc3 ~= nil then
    player.hero:SetPhysicsAcceleration(Vector(tonumber(acc1), tonumber(acc2), tonumber(acc3)))
  end
  
  local fric1 = string.match(text, "^-fric%s+(-?%d+)")
  if DEBUG and fric1 ~= nil then
    player.hero:SetPhysicsFriction(tonumber(fric1) / 100 )
  end
  
  local slide1 = string.match(text, "^-slidemult%s+(-?%d+)")
  if DEBUG and slide1 ~= nil then
    player.hero:SetSlideMultiplier(tonumber(slide1) / 100 )
  end
  
  if DEBUG and string.find(text, "^-prevent") then
    player.hero:PreventDI(not player.hero:IsPreventDI())
  end
  
  if DEBUG and string.find(text, "^-onframe") then
    player.hero:OnPhysicsFrame(function(unit)
      --PrintTable(unit)
      --print('----------------')
    end)
  end
  
  if DEBUG and string.find(text, "^-slide$") then
    player.hero:Slide(not player.hero:IsSlide())
    print(player.hero:IsSlide())
  end
  
  if DEBUG and string.find(text, "^-nav$") then
    player.hero:FollowNavMesh(not player.hero:IsFollowNavMesh())
  end
  
  local clamp1 = string.match(text, "^-clamp%s+(%d+)")
  if DEBUG and clamp1 ~= nil then
    player.hero:SetVelocityClamp( tonumber(clamp1))
  end
  
  if DEBUG and string.find(text, "^-hibernate") then
    player.hero:Hibernate(not player.hero:IsHibernate())
    print(player.hero:IsHibernate())
  end
  
  if DEBUG and string.find(text, "^-navtype") then
      local navType = player.hero:GetNavCollisionType()
      navType = (navType + 1) % 4
      print('navtype: ' .. tostring(navType))
      player.hero:SetNavCollisionType(navType)
  end
  
  if DEBUG and string.find(text, "^-ground") then
    local ground = player.hero:GetGroundBehavior()
    ground = (ground + 1) % 3
    print('ground: ' .. tostring(ground))
    player.hero:SetGroundBehavior(ground)
  end
  
  if DEBUG and string.find(text, "^-pause") then
    paused = self.timers['round_time_out']
    self:RemoveTimer('round_time_out')
  end
  
  if DEBUG and string.find(text, "^-unpause") and paused ~= nil then
    self.timers['round_time_out'] = paused
    paused = nil
  end
  
  local abil1 = string.match(text, "^-abil%s+(.+)")
  if DEBUG and abil1 ~= nil then
    for k,v in pairs(HeroList:GetAllHeroes()) do
      if player.hero ~= v then
        local found = false
        for k2,i in pairs({1,2,3,6,4,5}) do
          if not found then
            local ability = v:FindAbilityByName( 'reflex_empty' .. i)
            if ability ~= nil then
              --print ( '[DOTADASH] found empty' .. i .. " replacing")
              v:RemoveAbility('reflex_empty' .. i)
              v:AddAbility(abil1)
              found = true
            end
          end
        end
      end
    end
  end
  
  local item1 = string.match(text, "^-item%s+(.+)")
  if DEBUG and item1 ~= nil then
    for k,v in pairs(HeroList:GetAllHeroes()) do
      if player.hero ~= v then
        local item = CreateItem(item1, v, v)
        v:AddItem(item)
      end
    end
  end
  
  if DEBUG and string.find(text, "^-heal") then
    local m = string.match(text, "(%d)")
    if m ~= nil then
      local p = PlayerResource:GetPlayer(tonumber(m))
      local v = p:GetAssignedHero()
      v:SetHealth(v:GetMaxHealth()) 
    else 
      for k,v in pairs(HeroList:GetAllHeroes()) do
        if v ~= player.hero then
          v:SetHealth(v:GetMaxHealth())
        end
      end
    end
  end
  
  local sAttach = string.match(text, "^-attach%s+(%d+)")
  if DEBUG and sAttach ~= nil then
    attach = tonumber(sAttach)
    Say(nil, 'Attach set ' .. sAttach, false)
  end
  
  local cp,nill = string.match(text, "^-cp%s+(%d+)%s+nil")
  if DEBUG and cp ~= nil and nill ~= nil then
    controlPoints[tonumber(cp)] = nil
    Say(nil, 'CP ' .. cp .. ' set to nil', false)
  else
    local cp,c1,c2,c3 = string.match(text, "^-cp%s+(%d+)%s+(-?%d+)%s+(-?%d+)%s+(-?%d+)")
    if DEBUG and cp ~= nil and c1 ~= nil and c2 ~= nil and c3 ~= nil then
      controlPoints[tonumber(cp)] = Vector(tonumber(c1), tonumber(c2), tonumber(c3))
      if particle ~= nil then
        ParticleManager:SetParticleControl(particle, tonumber(cp), controlPoints[tonumber(cp)])
      end
      Say(nil, 'CP ' .. cp .. ' set to Vector(' .. c1 .. ', ' .. c2 .. ', ' .. c3 .. ')', false)
    end
  end
  
  if DEBUG and string.find(text, "^-newp") then
    particle = nil
  end
  
  if DEBUG and string.find(text, "^-rpi") and particle ~= nil then
    ParticleManager:ReleaseParticleIndex(particle)
  end
  
  local effect = string.match(text, "^-particle%s*(.*)")
  if DEBUG and effect ~= nil and effect ~= "" then
    particleEffect = effect
    particle = ParticleManager:CreateParticle(effect, attach, player.hero)--cmdPlayer:GetAssignedHero())
    for cp,vec in pairs(controlPoints) do
      ParticleManager:SetParticleControl(particle, cp, vec)--Vector(0,0,0)) -- something
    end
  elseif DEBUG and effect ~= nil and effect == "" then
    particle = ParticleManager:CreateParticle(particleEffect, attach, player.hero)--cmdPlayer:GetAssignedHero())
    for cp,vec in pairs(controlPoints) do
      ParticleManager:SetParticleControl(particle, cp, vec)--Vector(0,0,0)) -- something
    end
  end
end

function DotaDashGameMode:AutoAssignPlayer(keys)
  print ('[DOTADASH] AutoAssignPlayer')
  self:CaptureGameMode()
  
  print ('[DOTADASH] getting index')
  local entIndex = keys.index+1
  local ply = EntIndexToHScript(entIndex)
  
  local playerID = ply:GetPlayerID()

  self.nConnected = self.nConnected + 1
  self:RemoveTimer('all_disconnect')
  
  self.vUserIds[keys.userid] = ply
  
  if PlayerResource:IsBroadcaster(playerID) then
    self.vBroadcasters[keys.userid] = 1
    return
  end
  
  if self.vBots[keys.userid] ~= nil then
    return
  end

  playerID = ply:GetPlayerID()
  if self.vPlayers[playerID] ~= nil then
    --self.vUserIds[playerID] = nil
    self.vUserIds[keys.userid] = ply

    --Player is reconnecting, redraw stuff
    self:DrawBarriersForPlayer(ply)
    self:DrawWaypointsForPlayer(ply)

    --Fire off full-update message to reconnecting player
    local player = self.vPlayers[playerID]
    local curLaps = ""

    for i=0,#self.vPlayers do
      local p = self.vPlayers[i]
      if i == #self.vPlayers then
        curLaps = curLaps .. tostring(p.nLap)
      else
        curLaps = curLaps .. tostring(p.nLap) .. ","
      end
    end

    local positions = self:UpdatePositions(true)
    print('dd_full_update')
    local eventTable = {playerID = playerID, positions = positions, currentLaps = curLaps, maxLaps = LAPS_TO_WIN}
    PrintTable(eventTable)
    FireGameEvent("dd_full_update", eventTable)
    return
  end

  if not roundOne then
    -- This player is conencting after the intial drawings, redraw
    self:DrawBarriersForPlayer(ply)
    self:DrawWaypointsForPlayer(ply)
  end
  
  if not USE_LOBBY and playerID == -1 then
    print ('[DOTADASH] team sizes ' ..  #self.vRadiant .. "  --  " .. #self.vDire)
    if #self.vRadiant > #self.vDire then
      print ('[DOTADASH] setting to bad guys')
      ply:SetTeam(DOTA_TEAM_BADGUYS)
      ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)
      table.insert (self.vDire, ply)
    else
      print ('[DOTADASH] setting to good guys')
      ply:SetTeam(DOTA_TEAM_GOODGUYS)
      ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_GOODGUYS)
      table.insert (self.vRadiant, ply)
    end
    playerID = ply:GetPlayerID()
  end

  print ('[DOTADASH] playerID: ' .. playerID)
  self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply
  
  print('[DOTADASH] SteamID: ' .. PlayerResource:GetSteamAccountID(playerID))

  --Autoassign player
  self:CreateTimer('assign_player_'..entIndex, {
  endTime = Time(),
  callback = function(reflex, args)
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME then
      print ('[DOTADASH] in pregame')
      -- Assign a hero to a fake client
      local heroEntity = ply:GetAssignedHero()
      print ('[DOTADASH] got assigned hero')
      -- Check if we have a reference for this player's hero
      if heroEntity ~= nil and IsValidEntity(heroEntity) then
        print ('[DOTADASH] setting hero assignment')
        local heroTable = {
          hero = heroEntity,
          nKillsThisRound = 0,
          bDead = false,
          nUnspentGold = STARTING_GOLD,
          fLevel = 1.0,
          nCurXP = 100,
          nTeam = ply:GetTeam(),
          bRoundInit = false,
          nUnspentAbilityPoints = 1,
          bConnected = true,
          nLastRoundDamage = 0,
          nRoundDamage = 0,
          name = self.vUserNames[keys.userid] or "FAKE",
          bColorblind = false,
          bFlying = false,
          nTotalScore = 0,
          nRoundPosition = 0,
          nLap = 1,
          nCurWaypoint = 1,
          bCompletedRace = false,
          oNextWayPointEntity = nil,
          playerID = playerID,
          fLastFriction = FRICTION_MULTIPLIER,
          spawn = nil,
          vAbilities = {
            "reflex_empty1",
            "reflex_empty2",
            "reflex_empty3",
            "reflex_empty4",
            "reflex_empty5",
            "reflex_empty6"
          }
        }
        print ('[DOTADASH] playerID: ' .. playerID)
        self.vPlayers[playerID] = heroTable
        
        print ( "[DOTADASH] setting stuff for player"  .. playerID)
        --heroEntity:__KeyValueFromInt('StatusManaRegen', 100)
        --local dash = CreateItem("item_reflex_dash", heroEntity, heroEntity)
        --heroEntity:AddItem(dash)
        --local shooter = CreateItem("item_simple_shooter", heroEntity, heroEntity)
        --heroEntity:AddItem(shooter)
        heroEntity:SetCustomDeathXP(0)

        heroEntity:SetGold(0, false)
        heroEntity:SetGold(STARTING_GOLD, true)
        --PlayerResource:SetGold( playerID, 0, false )
        --PlayerResource:SetGold( playerID, STARTING_GOLD, true )
        print ( "[DOTADASH] GOLD SET FOR PLAYER "  .. playerID)
        PlayerResource:SetBuybackCooldownTime( playerID, 0 )
        PlayerResource:SetBuybackGoldLimitTime( playerID, 0 )
        PlayerResource:ResetBuybackCostTime( playerID )
        
        -- Physics stuff
        local unit = heroEntity
        Physics:Unit(unit)
        unit:SetBaseMoveSpeed(BASE_MOVESPEED)
        unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
        unit:SetPhysicsAcceleration(Vector(0,0,GRAVITY_AMOUNT))
        unit:Slide(true)
        unit:SkipSlide(30)
        unit:SetSlideMultiplier(SLIDE_MULTIPLIER)
        unit:Hibernate(false)
        unit:SetPhysicsFriction(FRICTION_MULTIPLIER)
        unit:SetVelocityClamp(VELOCITY_CLAMP)
        unit:SetPhysicsVelocityMax(VELOCITY_MAX)
        unit:SetBounceMultiplier(BOUNCE_MULTIPLIER)
        unit:SetNavGridLookahead(NAV_LOOKAHEAD)

        local mapdata = MAP_DATA
        local waypoints = mapdata.waypoints
        local frameCount = 0
        unit.lastWaypoint = unit:GetAbsOrigin()
        heroTable.oNextWayPointEntity = CreateUnitByName("npc_firefly_dummy", waypoints[1].middle + Vector(0,0,160), false, unit, unit, unit:GetTeamNumber())
        heroTable.oNextWayPointEntity:AddNewModifier(unit, nil, "modifier_invulnerable", {})
        heroTable.oNextWayPointEntity:AddNewModifier(unit, nil, "modifier_phased", {})
        local ability = heroTable.oNextWayPointEntity:FindAbilityByName("reflex_dummy_unit")
        ability:SetLevel(1)
        --bloodseeker_rupture
        local particle = ParticleManager:CreateParticleForPlayer("keeper_of_the_light_recall", PATTACH_OVERHEAD_FOLLOW, heroTable.oNextWayPointEntity, ply)--cmdPlayer:GetAssignedHero())
        --ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
        --ParticleManager:SetParticleControl(particle, 1, Vector(radius,1,1)) -- endpoint
        --ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
        
        ability = unit:FindAbilityByName("dota_dash_back_to_waypoint")
        if ability ~= nil then
          ability:SetLevel(1)
        end
        ability = unit:FindAbilityByName("dota_unstick")
        if ability ~= nil then
          ability:SetLevel(1)
        end
        ability = unit:FindAbilityByName("dota_dash_hop")
        if ability ~= nil then
          ability:SetLevel(1)
        end
        
        unit:OnPhysicsFrame(function(unit)
          
          frameCount = (frameCount + 1) % 30
          --Fix acceleration
          local accel = unit:GetPhysicsAcceleration()
          local grav = accel.z
          accel.z =0
          local forward = unit:GetForwardVector()
          forward.z = 0
          local accel2 = forward * accel:Length()
          accel2 = Vector(accel2.x, accel2.y, grav)
          unit:SetPhysicsAcceleration(accel2)
          
          --PlayerResource:SetCameraTarget(playerID, unit)
          -- No DI during flight
          if unit.bRocketRob ~= nil and unit.bRocketRob == true then
            local pos = unit:GetAbsOrigin()
            local groundPos = GetGroundPosition(pos, unit)
            -- print(tostring(pos) .. " -- " .. tostring(groundPos))
            if not heroTable.bFlying and pos.z > groundPos.z and unit.vVelocity:Length() > TAKEOFF_VELOCITY then
              unit:PreventDI(true)
              unit:AddPhysicsVelocity(unit.vSlideVelocity)
              heroTable.fLastFriction = unit:GetPhysicsFriction()
              unit:SetPhysicsFriction(0)
              unit:AddNewModifier(unit, nil, "modifier_pudge_meat_hook", {})
              heroTable.bFlying = true
            elseif heroTable.bFlying and pos.z <= groundPos.z then
              unit:PreventDI(false)
              if heroTable.fLastFriction == 0 then
                unit:SetPhysicsFriction(FRICTION_MULTIPLIER)
                heroTable.fLastFriction = FRICTION_MULTIPLIER
              else
                unit:SetPhysicsFriction(FRICTION_MULTIPLIER)
                --unit:SetPhysicsFriction(heroTable.fLastFriction)
              end
              heroTable.bFlying = false
              unit:RemoveModifierByName("modifier_pudge_meat_hook")
            end
            
            local curWaypoint = heroTable.nCurWaypoint
            -- Collision for waypoints
            local waypoint = waypoints[curWaypoint]
            pos.z = 0
            
            local am = pos - waypoint.a
            local amDotAb = am:Dot(waypoint.ab)
            local inside = false
            if amDotAb > 0 and amDotAb < waypoint.ab2 then
              local amDotAd = am:Dot(waypoint.ad)
              if amDotAd > 0 and amDotAd < waypoint.ad2 then
                inside = true
              end
            end
          end
          
          if inside then
            print('hit waypoint: ' .. curWaypoint)
            unit.lastWaypoint = waypoint.middle
            curWaypoint = curWaypoint + 1
            heroTable.nCurWaypoint = curWaypoint
            
            if curWaypoint > #waypoints then
              heroTable.nLap = heroTable.nLap + 1
              
              local name = heroTable.name
              if string.len(heroTable.name) > 10 then
                name = string.sub(name, 1, 10)
              end
              
              if heroTable.nLap > self.nCurrentLap and heroTable.nLap <= LAPS_TO_WIN then
                self.nCurrentLap = heroTable.nLap
                local msg = {
                  message = name .. " has begun lap " .. tostring(heroTable.nLap),
                  duration = 0.9
                }
                FireGameEvent("show_center_message",msg)
                
                local times = 1
                DotaDashGameMode:CreateTimer('lapbegin', {
                  useGameTime = true,
                  endTime = GameRules:GetGameTime() + 1,
                  callback = function(reflex, args)
                    local msg = {
                      message = name .. " has begun lap " .. tostring(heroTable.nLap),
                      duration = 0.9
                    }
                    FireGameEvent("show_center_message",msg)
                    
                    if times == 1 then
                      times = 0
                      return GameRules:GetGameTime() + 1
                    end
                    return
                  end
                })
              end
              
              print('dd_lap_update: playerID: ' .. tostring(heroTable.playerID) .. ' -- nLap: ' .. tostring(heroTable.nLap))
              FireGameEvent("dd_lap_update", {playerID = heroTable.playerID, lap = heroTable.nLap})
              curWaypoint = 1
              heroTable.nCurWaypoint = 1
              --print('hit last waypoint, New Lap: ' .. tostring(heroTable.nLap))
              if heroTable.nLap > LAPS_TO_WIN then
                GameRules:SendCustomMessage("<font color='#44FF44'>" .. name .. "</font> has finished the race!", 0, 0)
                unit:AddNewModifier(unit, nil, "modifier_stunned", {})
                unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
                
                EmitSoundOnClient("Tutorial.TaskCompleted", ply)
                DotaDashGameMode:CompletedRace(unit)
                heroTable.nLap = 1
                heroTable.bCompletedRace = true
                table.remove(self.vPositions, 1)
              else
                GameRules:SendCustomMessage("<font color='#44FF44'>" .. name .. "</font> has completed Lap " .. tostring(heroTable.nLap-1) .. "!", 0, 0)
                EmitSoundOnClient("ui.npe_badge", ply)
                
                -- Update Positions
                self:UpdatePositions()
              end
            else
              EmitSoundOnClient("Bottle.Cork", ply)
              
              -- Update Positions 
              self:UpdatePositions()
            end
            
            heroTable.oNextWayPointEntity:SetAbsOrigin(waypoints[curWaypoint].middle + Vector(0,0,160))
          end
          
          
        end)
          

        if not bInPreRound then
          if heroTable.bRoundInit == false then
            print ( '[DOTADASH] Initializing player ' .. playerID)
            heroTable.bRoundInit = true
            heroTable.hero:SkipSlide(30)
            print ('[DOTADASH] post-pre-game init')
            local spawn = nil
            if self.spawns ~= nil then
              local index = RandomInt(1,#self.spawns)
              spawn = self.spawns[index]
              heroTable.spawn = spawn
              table.remove(self.spawns, index)

              --print(heroTable.spawn.origin)
              heroTable.hero:SetRespawnPosition(spawn.origin)
              heroTable.hero:SetAbsOrigin(spawn.origin)
              if spawn.forward ~= nil then
                heroTable.hero:SetForwardVector(spawn.forward)
              end
            end
            heroTable.hero:RespawnHero(false, false, false)
            --heroTable.hero:RespawnUnit()
            heroTable.nKillsThisRound = 0
            heroTable.bDead = false

            --PlayerResource:SetGold(playerID, 0, true)
            heroTable.hero:SetGold(0, true)
            heroTable.nUnspentAbilityPoints = heroTable.hero:GetAbilityPoints()
            heroTable.hero:SetAbilityPoints(0)

            self.vPositions[#self.vPositions + 1] = heroTable
            heroTable.nLap = 1
            print('dd_lap_update: playerID: ' .. tostring(heroTable.playerID) .. ' -- nLap: 1')
            FireGameEvent("dd_lap_update", {playerID = heroTable.playerID, lap = 1})
            heroTable.nRoundPosition = 0
            heroTable.bCompletedRace = false

            --if has modifier remove it
            if heroTable.hero:HasModifier("modifier_stunned") then
              heroTable.hero:RemoveModifierByName("modifier_stunned")
            end
          end
        end

        return
      end
    end

    return Time() + 1.0
  end
  --persist = true
})
end

function DotaDashGameMode:UpdatePositions(retString)
  local waypoints = MAP_DATA.waypoints
  local points = #waypoints
  local lastPositions = {}

  for i=1,#self.vPositions do
    lastPositions[i] = self.vPositions[i]
  end
  
  table.sort(self.vPositions, function(a,b)
    local scoreA = (a.nLap - 1) * points + (a.nCurWaypoint - 1)
    local scoreB = (b.nLap - 1) * points + (b.nCurWaypoint - 1)
    local ret = scoreA > scoreB
    
    if scoreA == scoreB then
      local mid = waypoints[a.nCurWaypoint].middle
      local distA = mid - a.hero:GetAbsOrigin()
      local distB = mid - b.hero:GetAbsOrigin()
      
      distA = distA:Length()
      distB = distB:Length()
      
      ret = distA < distB
    end
    
    return ret
  end)
  
  --[[ Print update
  local s = "{"
  for i=1,#self.vPositions do
    local v = self.vPositions[i]
    local score = (v.nLap - 1) * points + (v.nCurWaypoint - 1)
    s = s .. tostring(v.playerID) .. "=" .. tostring(score) .. ","
  end
  print(s .. "}")]]
  
  -- Send update to clients if the positions have changed
  local equal = true
  local vPositions = self.vPositions
  local s = tostring(vPositions[1].playerID)
  if lastPositions[1].playerID ~= vPositions[1].playerID then
    equal = false
  end
  for i=2,#lastPositions do
    if lastPositions[i].playerID ~= vPositions[i].playerID then
      equal = false
    end
    s = s .. "," .. tostring(vPositions[i].playerID)
  end

  if not equal then
    print('dd_position_update: positions: ' .. s)
    FireGameEvent("dd_position_update", {positions = s})
  end

  if retString then
    return s
  end
end

function DotaDashGameMode:CompletedRace(unit)
  local plyID = unit:GetPlayerID()
  local player = self.vPlayers[plyID]
  
  self.nFinishLineCrossed = self.nFinishLineCrossed + 1
  
  local score = POINTS_PER_POSITION[self.nFinishLineCrossed]--5 - self.nFinishLineCrossed
  if score < 0 then
    score = 0
  end
  
  local suffix = "th"
  if self.nFinishLineCrossed == 1 then
    suffix = "st"
  elseif self.nFinishLineCrossed == 2 then
    suffix = "nd"
  elseif self.nFinishLineCrossed == 3 then
    suffix = "rd"
  end
  
  Say(nil, player.name .. " came in " .. tostring(self.nFinishLineCrossed) .. suffix .. "! -- Points: " .. score, false)
  
  player.nTotalScore = player.nTotalScore + score
  for i=1,score do
    PlayerResource:IncrementKills(plyID, 1)
  end
  player.nRoundPosition = nFinishLineCrossed
  
  if self.nFinishLineCrossed == #self.vPlayers + 1 then
    self:RemoveTimer('round_time_out')
    
    EmitGlobalSound("crowd.lv_01")
    self:CreateTimer('victory', {
      endTime = Time() + POST_ROUND_TIME,
      callback = function(reflex, args)
        DotaDashGameMode:RoundComplete(false)
      end})
  end
  
  if self.timers['round_time_out'] == nil then
    local timeoutCount = 13
    self:CreateTimer('round_time_out',{
    endTime = GameRules:GetGameTime() + ROUND_TIME - 45,
    useGameTime = true,
    callback = function(reflex, args)
      timeoutCount = timeoutCount - 1
      if timeoutCount == 0 then 
        -- TIME OUT
        self:LoopOverPlayers(function(player, plyID)
          player.hero:AddNewModifier( player.hero, nil , "modifier_stunned", {})
          player.hero:AddNewModifier( player.hero, nil , "modifier_invulnerable", {})
        end)
        
        EmitGlobalSound("crowd.lv_01")
        self:CreateTimer('victory', {
          endTime = Time() + POST_ROUND_TIME,
          callback = function(reflex, args)
            DotaDashGameMode:RoundComplete(true)
          end})

        return
      elseif timeoutCount == 12 then
        Say(nil, "45 seconds remaining!", false)
        return GameRules:GetGameTime() + 15
      elseif timeoutCount == 11 then
        Say(nil, "30 seconds remaining!", false)
        return GameRules:GetGameTime() + 20
      else
        local msg = {
          message = tostring(timeoutCount),
          duration = 0.9
        }
        FireGameEvent("show_center_message",msg)
        return GameRules:GetGameTime() + 1
      end
    end})
  end
end

function DotaDashGameMode:LoopOverPlayers(callback)
  for k, v in pairs(self.vPlayers) do
    -- Validate the player
    if IsValidEntity(v.hero) then
      -- Run the callback
      if callback(v, v.hero:GetPlayerID()) then
        break
      end
    end
  end
end

function DotaDashGameMode:ShopReplacement( keys )
  --print ( '[DOTADASH] ShopReplacement' )
  PrintTable(keys)

  local plyID = keys.PlayerID
  if not plyID then return end

  local player = self.vPlayers[plyID]
  if not player then return end

  local item = self:getItemByName(player.hero, keys.itemname)
  if not item then return end

  print ( item:GetAbilityName())
  --print ( ABILITY_ITEM_TABLE[item:GetAbilityName()] )
  
  if (string.find(item:GetAbilityName(), "item_recipe_") ~= nil) then
    local cost = item:GetCost()
    player.hero:SetGold(player.hero:GetGold() + cost, true)
    item:Remove()
    return
  end

  -- Prevent rebuying existing items
  local baseName = item:GetAbilityName()
  local count = 0
  if string.find(baseName:sub(-1), "2") ~= nil or string.find(baseName:sub(-1), "3") ~= nil or string.find(baseName:sub(-1), "4") ~= nil then
    --print('[DOTADASH] BaseName: ' .. baseName)
    baseName = baseName:sub(1, -3)
    --print('[DOTADASH] BaseName: ' .. baseName)
  end
  
  for i=0,11 do
    --print ( '\t[DOTADASH] finding item ' .. i)
    local item2 = player.hero:GetItemInSlot( i )
    --print ( '\t[DOTADASH] item: ' .. tostring(item) )
    if item2 ~= nil then
      --print ( '\t[DOTADASH] getting item name' .. i)
      local lname = item2:GetAbilityName()
      --print ( string.format ('[DOTADASH] item slot %d: %s', i, lname) )
      if string.find(lname, baseName) then
        count = count + 1
        --print (tostring(count))
        if count > 1 then
          local cost = item:GetCost()
          player.hero:SetGold(player.hero:GetGold() + cost, true)
          item:Remove()
          return
        end
      end
    end
  end
end

function DotaDashGameMode:getItemByName( hero, name )
  --if not hero:HasItemInInventory ( name ) then
  --  return nil
  --end

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

function DotaDashGameMode:_thinkState_Prep( dt )
  --print ( '[DOTADASH] _thinkState_Prep' )
  if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_PRE_GAME then
    -- Waiting on the game to start...
    return
  end

  self.thinkState = Dynamic_Wrap( DotaDashGameMode, '_thinkState_None' )
  self:InitializeRound()

end

function DotaDashGameMode:_thinkState_None( dt )
  return
end

function DotaDashGameMode:InitializeRound()
  print ( '[DOTADASH] InitializeRound called' )
  bInPreRound = true
  GameRules:SetUseUniversalShopMode( true )

  self.nCurrentRound = self.nCurrentRound + 1
  self.nCurrentLap = 1
  self.nFinishLineCrossed = 0

  print('dd_start_race: maxLaps: ' .. tostring(LAPS_TO_WIN))
  FireGameEvent("dd_start_race", {maxLaps = LAPS_TO_WIN})

  local mapdata = MAP_DATA
  local spawnsOrig = mapdata.spawns
  self.spawns = nil
  if spawnsOrig ~= nil and #spawnsOrig >= 10 then
    self.spawns = {}
    for i=1,#spawnsOrig do
      self.spawns[i] = spawnsOrig[i]
    end
  end
  
  self.vPositions = {}
  
  --cancelTimer = false
  --Init Round (give level ups/points/gold back)
  self:RemoveTimer('playerInit')
  self:CreateTimer('playerInit', {
  endTime = Time(),
  callback = function(reflex, args)
    if not bInPreRound then
      return Time() + 0.5
    end
    self:LoopOverPlayers(function(player, plyID)
      if player.bRoundInit == false then
        print ( '[DOTADASH] Initializing player ' .. plyID)
        player.bRoundInit = true
        player.hero:SkipSlide(30)
        local spawn = nil
        if self.spawns ~= nil then
          local index = RandomInt(1,#self.spawns)
          spawn = self.spawns[index]
          player.spawn = spawn
          table.remove(self.spawns, index)

          --print(player.spawn.origin)
          player.hero:SetRespawnPosition(spawn.origin)
          player.hero:SetAbsOrigin(spawn.origin)
          if spawn.forward ~= nil then
            player.hero:SetForwardVector(spawn.forward)
          end
        end

        player.hero:RespawnHero(false, false, false)
        --SendToConsole("dota_camera_lock 1")
        player.hero:SetPhysicsVelocity(Vector(0,0,0))
        --player.hero:RespawnUnit()
        player.nKillsThisRound = 0
        player.bDead = false
        player.nRoundDamage = PlayerResource:GetRawPlayerDamage(plyID) - player.nLastRoundDamage
        player.nLastRoundDamage = PlayerResource:GetRawPlayerDamage(plyID)
        --PlayerResource:SetGold(plyID, player.nUnspentGold, true)
        player.hero:SetGold(player.nUnspentGold, true)
        player.hero:SetAbilityPoints(player.nUnspentAbilityPoints)
        
        self.vPositions[#self.vPositions + 1] = player
        player.nLap = 1
        print('dd_lap_update: playerID: ' .. tostring(player.playerID) .. ' -- nLap: 1')
        FireGameEvent("dd_lap_update", {playerID = player.playerID, lap = 1})
        player.nRoundPosition = 0
        player.bCompletedRace = false
        
        --[[local points = #MAP_DATA.waypoints
        local s = "{"
        for i=1,#self.vPositions do
          local v = self.vPositions[i]
          local score = (v.nLap - 1) * points + (v.nCurWaypoint - 1)
          s = s .. tostring(v.playerID) .. "=" .. tostring(score) .. ","
        end
        print(s .. "}")]]
        
        
        if mapdata == nil then
          print('[DOTADASH] ERROR: NO MAP DATA FOR THIS RACE')
        else
          local waypoints = mapdata.waypoints
          player.nCurWaypoint = 1
          player.oNextWayPointEntity:SetAbsOrigin(waypoints[1].middle + Vector(0,0,160))
        end

        for i=0,11 do
          local item = player.hero:GetItemInSlot( i )
          if item ~= nil then
            item:Destroy()
          end
        end
        
        if not player.hero:HasModifier("modifier_stunned") then
          player.hero:AddNewModifier( player.hero, nil , "modifier_stunned", {})
        end

        if not player.hero:HasModifier("modifier_invulnerable") then
          player.hero:AddNewModifier(player.hero, nil , "modifier_invulnerable", {})
        end
      end
    end)
    
    return Time() + 0.5
  end})

  local roundTime = PRE_ROUND_TIME
  
  Say(nil, string.format("Race %d starts in %d seconds!", self.nCurrentRound, roundTime), false)
  
  if roundOne then
    --Create Waypoints
    if mapdata == nil then
      print('[DOTADASH] ERROR: NO MAP DATA FOR THIS RACE')
    else
      local waypoints = mapdata.waypoints
      for i=1,#waypoints do
        local waypoint = waypoints[i]
        local unit = CreateUnitByName('npc_dota_danger_indicator', waypoint.from, false, nil, nil, DOTA_TEAM_NOTEAM)
        unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
        unit:AddNewModifier(unit, nil, "modifier_phased", {})
        local ability = unit:FindAbilityByName("reflex_dummy_unit")
        ability:SetLevel(1)

        waypoint.unit = unit
        
        local particleName = waypoint.particle or "dark_seer_wall_of_replica"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, unit)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
        ParticleManager:SetParticleControl(particle, 1, waypoint.to) -- endpoint
        ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
        
        --Build rectangle
        local thickness = waypoint.thickness or 180
        thickness = thickness / 2
        
        waypoint.middle = waypoint.to
        
        waypoint.to.z = 0
        waypoint.from.z = 0
        
        local dir = waypoint.to - waypoint.from
        waypoint.middle = waypoint.middle - (dir / 2)
        dir = dir:Normalized()
        
        dir = RotatePosition(Vector(0,0,0), QAngle(0,90,0), dir)
        
        --PrintTable(dir)
        --PrintTable(getmetatable(dir))
        
        local a = waypoint.from + (dir * thickness)
        local b = waypoint.from - (dir * thickness)
        local d = waypoint.to + (dir * thickness)
        waypoint.a = a
        waypoint.ab = b - a
        waypoint.ad = d - a
        waypoint.ab2 = waypoint.ab:Dot(waypoint.ab)
        waypoint.ad2 = waypoint.ad:Dot(waypoint.ad)
        
        --PrintTable(waypoint)
        --print('------------------')
      end
      
      --Create Powerups
      local powerups = mapdata.powerups
      for i=1,#powerups do
        local powerup = powerups[i]
        --PrintTable(powerup)
        --print('-----------')
        
        local unit = CreateUnitByName('npc_item_block', powerup.origin, false, nil, nil, DOTA_TEAM_NOTEAM)
        unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
        unit:AddNewModifier(unit, nil, "modifier_phased", {})
        local ability = unit:FindAbilityByName("reflex_dummy_unit")
        ability:SetLevel(1)
        
        unit.bBlockActive = true
      end

      --Create Barriers
      local barriers = mapdata.barriers
      if barriers ~= nil then
        for i=1,#barriers do
          local barrier = barriers[i]

          local particle = ParticleManager:CreateParticle("dd_earthshaker_fissure", PATTACH_WORLDORIGIN, nil)
          ParticleManager:SetParticleControl(particle, 0, barrier.from)
          ParticleManager:SetParticleControl(particle, 1, barrier.to) -- radius, thickness, speed
          ParticleManager:SetParticleControl(particle, 2, Vector(10000,0,0)) -- duration

          ParticleManager:ReleaseParticleIndex(particle)
        end
      end

      -- spawn vision dummies
      local vision = mapdata.vision
      if vision ~= nil then
        local i=1
        self:CreateTimer('vision', {
          useGameTime = true,
          endTime = GameRules:GetGameTime() + .1,
          callback = function(reflex, args)
            if i > #vision then
              return
            end
            local vis = vision[i]
            --print("vis: " .. tostring(i) .. " -- " .. tostring(vis.origin))

            local dummy = CreateUnitByName("npc_vision_dummy", vis.origin, false, nil, nil, DOTA_TEAM_GOODGUYS)
            dummy:AddNewModifier(unit, nil, "modifier_invulnerable", {})
            dummy:AddNewModifier(unit, nil, "modifier_phased", {})
            local ab = dummy:FindAbilityByName("reflex_dummy_unit")
            ab:SetLevel(1)

            dummy = CreateUnitByName("npc_vision_dummy", vis.origin, false, nil, nil, DOTA_TEAM_BADGUYS)
            dummy:AddNewModifier(unit, nil, "modifier_invulnerable", {})
            dummy:AddNewModifier(unit, nil, "modifier_phased", {})
            ab = dummy:FindAbilityByName("reflex_dummy_unit")
            ab:SetLevel(1)

            i = i+1
            return GameRules:GetGameTime() + .2
          end
          })
      end

      GameRules:SetRuneSpawnTime(10000)
      GameRules:SetTreeRegrowTime(10000)

      --Vacuum trees
      local vacuums = mapdata.vacuums
      if vacuums ~= nil then
        for i=1,#vacuums do
          --print('vac' .. i)
          local vacuum = vacuums[i]
          local unit = CreateUnitByName('npc_vacuum_dummy', vacuum.origin, false, nil, nil, DOTA_TEAM_NOTEAM)
          local ability = unit:FindAbilityByName("dotadash_vacuum")
          vacuum.unit = unit
          vacuum.ability = ability
          if vacuum.size == nil then
            ability:SetLevel(5)
          else
            ability:SetLevel(vacuum.size)
          end
        end

        local rerun = 2
        DotaDashGameMode:CreateTimer('vacuums', {
          useGameTime = true,
          endTime = GameRules:GetGameTime() + 1.0,
          callback = function(reflex, args)
            if rerun == 0 then
              for i=1,#vacuums do
                local vacuum = vacuums[i]
                local unit = vacuum.unit
                unit:Destroy()
              end
              return
            else
              for i=1,#vacuums do
                local vacuum = vacuums[i]
                local ability = vacuum.ability
                local unit = vacuum.unit
                unit:CastAbilityOnPosition(unit:GetAbsOrigin(), ability, 0)
              end
              rerun = rerun - 1
              return GameRules:GetGameTime() + 2.0
            end
          end
          })

        if GetMapName() == "dash" then
          DotaDashGameMode:CreateTimer('entityDelete', {
            useGameTime = true,
            endTime = GameRules:GetGameTime(),
            callback = function(reflex, args)
              local delete = {
                "npc_dota_creep_lane",
                "npc_dota_creep_siege",
                "npc_dota_creep_neutral"
              }
              for j=1,#delete do
                local ents = Entities:FindAllByClassname(delete[j])
                local curTime = GameRules:GetGameTime()
                for i=1,#ents do
                  local ent = ents[i]
                  if ent:GetCreationTime() + 60 < curTime then
                    ent:Destroy()
                  end
                end
              end

              return GameRules:GetGameTime() + 20
            end
            })

          DotaDashGameMode:CreateTimer('runeDelete', {
            useGameTime = true,
            endTime = GameRules:GetGameTime(),
            callback = function(reflex, args)
              local ents = Entities:FindAllByClassname("dota_item_rune")
              for i=1,#ents do
                print('deleting rune')
                local ent = ents[i]
                ent:Destroy()
                return
              end

              return GameRules:GetGameTime() + .1
            end
            })
          local ents = Entities:FindAllByClassname("npc_dota_spawner_good_mid")
          for i=1,#ents do
            print('deleting mid')
            local ent = ents[i]
            ent:Destroy()
          end
          
          ents = Entities:FindAllByClassname("npc_dota_spawner_bad_mid")
          for i=1,#ents do
            print('deleting mid')
            local ent = ents[i]
            ent:Destroy()
          end

          ents = Entities:FindAllByClassname("npc_dota_neutral_spawner")
          for i=1,#ents do
            local ent = ents[i]
            ent:Destroy()
          end

          ents = Entities:FindAllByClassname("npc_dota_tower")
          for i=1,#ents do
            local ent = ents[i]
            ent:__KeyValueFromInt("ProjectileSpeed", 2000)
          end
        end
      end

    end
    
    --[[GameRules:SendCustomMessage("USE <font color='#FF3333'>dota_camera_lock 1</font> FOR THIS GAME", 0, 0)
    Say(nil, "USE dota_camera_lock 1 FOR THIS GAME", false)
    
    local times = 10
    local msg = {
      message = "USE dota_camera_lock 1",
      duration = 0.9
    }
    self:CreateTimer('cameraLock', {
      endTime = GameRules:GetGameTime(),
      useGameTime = true,
      callback = function(reflex, args)
        times = times - 1
        if times == 0 then
          return
        end
        
        FireGameEvent("show_center_message",msg)
        return GameRules:GetGameTime() + 1
      end
    })]]
    
    self:CreateTimer('reflexDetail', {
      endTime = GameRules:GetGameTime() + 5,
      useGameTime = true,
      callback = function(reflex, args)
        GameRules:SendCustomMessage("Welcome to <font color='#70EA72'>Dota Dash!</font>", 0, 0)
        GameRules:SendCustomMessage("Version: " .. DOTADASH_VERSION, 0, 0)
        GameRules:SendCustomMessage("Created by <font color='#70EA72'>BMD</font>", 0, 0)
        GameRules:SendCustomMessage("Map by <font color='#70EA72'>" .. (MAP_DATA.author or "Unknown") .. "</font>", 0, 0)
        GameRules:SendCustomMessage("UI by <font color='#70EA72'>Nullscope</font>", 0, 0)
        GameRules:SendCustomMessage("Send feedback to <font color='#70EA72'>bmddota@gmail.com</font>", 0, 0)

        local ents = Entities:FindAllByClassname("npc_dota_roshan")
        for i=1,#ents do
          print ('roshan')
          local ent = ents[i]
          ent:__KeyValueFromFloat("AttackAnimationPoint", 0.0)
        end
      end
    })
  end
 
  roundOne = false
  
  local startCount = 5
  --Set Timers for round start announcements
  self:CreateTimer('round_start_timer', {
  endTime = GameRules:GetGameTime() + roundTime - 10,
  useGameTime = true,
  callback = function(reflex, args)
    startCount = startCount - 1
    if startCount == 0 then
      self.fRoundStartTime = GameRules:GetGameTime()
      self:LoopOverPlayers(function(player, plyID)
        -- Refund any recipes left
        for i=0,11 do
          local item = player.hero:GetItemInSlot( i )
          if item ~= nil then
            local name = item:GetAbilityName()
            if string.find(name, "item_recipe_") ~= nil then
              local cost = item:GetCost()
              player.hero:SetGold(player.hero:GetGold() + cost, true)
              item:Remove()
            end
          end
        end

        player.nUnspentGold = PlayerResource:GetGold(plyID)
        --PlayerResource:SetGold(plyID, 0, true)
        player.hero:SetGold(0, true)
        player.hero:SetGold(0, false)
        player.nUnspentAbilityPoints = player.hero:GetAbilityPoints()
        player.hero:SetAbilityPoints(0)
        GameRules:SetUseUniversalShopMode( false )

        --if has modifier remove it
        if player.hero:HasModifier("modifier_stunned") then
          player.hero:RemoveModifierByName("modifier_stunned")
        end
        
        if player.hero:HasModifier("modifier_invulnerable") then
          player.hero:RemoveModifierByName("modifier_invulnerable")
        end
        
        player.hero:Slide(true)
      end)

      bInPreRound = false;
      local msg = {
        message = "RACE!",
        duration = 0.9
      }
      FireGameEvent("show_center_message",msg)
      return
    elseif startCount == 4 then
      Say(nil, "10 seconds remaining!", false)
      return GameRules:GetGameTime() + 7
    elseif startCount == 3 then
      local msg = {
        message = tostring(startCount),
        duration = 0.9
      }
      print('SOUND')
      FireGameEvent("show_center_message",msg)
      --HeroList:GetAllHeroes()[1]:EmitSound("DotaDash.RaceStart")
      EmitGlobalSound("DotaDash.RaceStart")
      return GameRules:GetGameTime() + 1
    else
      local msg = {
        message = tostring(startCount),
        duration = 0.9
      }
      FireGameEvent("show_center_message",msg)
      return GameRules:GetGameTime() + 1
    end
  end})

end

function DotaDashGameMode:RoundComplete(timedOut)
  print ('[DOTADASH] Round Complete')
  
  self:RemoveTimer('round_start_timer')
  self:RemoveTimer('round_time_out')
  self:RemoveTimer('victory')
  
  
  local scores = {}
  self:LoopOverPlayers(function(player, plyID)
    scores[#scores+1] = player
  end)
  
  table.sort(scores, function(a,b)
    return a.nTotalScore > b.nTotalScore
  end)

  local s = ""
  for i=1,#scores do
    s = s.. tostring(scores[i].nTotalScore) .. ","
  end
  print("{" .. s .. "}")
  
  
  if #scores > 1 then
    GameMode:SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, scores[2].nTotalScore )
  end
  GameMode:SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, scores[1].nTotalScore )

  --FireGameEvent("dd_scoreboard", {scores = s})

  for i=1,5 do
    local b = scores[i+5]
    local a = scores[i]
    if a ~= nil then 
      if b == nil then
        Say(nil, tostring(i) .. "> " .. scores[i].name .. ": " .. tostring(scores[i].nTotalScore), false)
      else
        local name =scores[i].name
        local sco = tostring(scores[i].nTotalScore)
        if (string.len(sco) == 1) then
          sco = " " .. sco
        end
        local l = string.len(name)
        if l > 10 then
          l = 10
          name = string.sub(name, 1,10)
        else
          name = name .. string.rep(" ", 10 - l)
        end
        
        local name2 =scores[i+5].name
        local name2 =scores[i+5].name
        local sco2 = tostring(scores[i+5].nTotalScore)
        if (string.len(sco2) == 1) then
          sco2 = " " .. sco2
        end
        local l2 = string.len(name2)
        if l2 > 10 then
          l2 = 10
          name2 = string.sub(name2, 1,10)
        else
          name2 = name2 .. string.rep(" ", 10 - l)
        end
        
        local extra = "   "
        if i == 5 then
          extra = "  "
        end
        
        local s = tostring(i) .. "> " .. name .. ": " .. sco
          .. extra .. tostring(i+5) .. "> " .. name2 .. ": " .. sco2
        Say(nil, s, false)
      end
    end
  end
  --Say(nil, "Overall Score:  " .. self.nRadiantScore .. " - " .. self.nDireScore, false)

  -- Check if at max round
  -- Complete game entirely and declare an overall victor
  if  self.nCurrentRound>= ROUNDS_TO_WIN then
    EmitGlobalSound("crowd.lv_04")
    Say(nil, scores[1].name .. " WINS!!  Well Played!", false) 
    GameRules:SetSafeToLeave( true )
    GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
    self:CreateTimer('endGame', {
    endTime = Time() + POST_GAME_TIME,
    callback = function(reflex, args)
      DotaDashGameMode:CloseServer()
    end})
    return
 end
  
  self:LoopOverPlayers(function(player, plyID)
    player.bRoundInit = false
  end)

  self:InitializeRound()
end

function DotaDashGameMode:Think()
  --print ( '[DOTADASH] Thinking' )
  -- If the game's over, it's over.
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    -- self._scriptBind:EndThink( "GameThink" )
    --DotaDashGameMode:EndThink( "GameThink" )
    return
  end

  -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local now = GameRules:GetGameTime()
  --print("now: " .. now)
  if DotaDashGameMode.t0 == nil then
    DotaDashGameMode.t0 = now
  end
  local dt = now - DotaDashGameMode.t0
  DotaDashGameMode.t0 = now

  DotaDashGameMode:thinkState( dt )

  -- Process timers
  for k,v in pairs(DotaDashGameMode.timers) do
    local bUseGameTime = false
    if v.useGameTime and v.useGameTime == true then
      bUseGameTime = true;
    end
    -- Check if the timer has finished
    if (bUseGameTime and GameRules:GetGameTime() > v.endTime) or (not bUseGameTime and Time() > v.endTime) then
      -- Remove from timers list
      DotaDashGameMode.timers[k] = nil

      --print ( '[DOTADASH] Running timer: ' .. k)

      -- Run the callback
      local status, nextCall = pcall(v.callback, DotaDashGameMode, v)

      -- Make sure it worked
      if status then
        -- Check if it needs to loop
        if nextCall then
          -- Change it's end time
          v.endTime = nextCall
          DotaDashGameMode.timers[k] = v
        end

        -- Update timer data
        --self:UpdateTimerData()
      else
        -- Nope, handle the error
        DotaDashGameMode:HandleEventError('Timer', k, nextCall)
      end
    end
  end

  return THINK_TIME
end

function DotaDashGameMode:HandleEventError(name, event, err)
  -- This gets fired when an event throws an error

  -- Log to console
  print(err)

  -- Ensure we have data
  name = tostring(name or 'unknown')
  event = tostring(event or 'unknown')
  err = tostring(err or 'unknown')

  -- Tell everyone there was an error
  print("[DOTADASH] " .. name .. ' threw an error on event ' .. event)
  print("[DOTADASH] " .. err)
  --Say(nil, name .. ' threw an error on event '..event, false)
  --Say(nil, err, false)

  -- Prevent loop arounds
  if not self.errorHandled then
    -- Store that we handled an error
    self.errorHandled = true

    -- End the gamemode
    --self:EndGamemode()
  end
end

function DotaDashGameMode:CreateTimer(name, args)
  --[[
  args: {
  endTime = Time you want this timer to end: Time() + 30 (for 30 seconds from now),
  useGameTime = use Game Time instead of Time()
  callback = function(frota, args) to run when this timer expires,
  text = text to display to clients,
  send = set this to true if you want clients to get this,
  persist = bool: Should we keep this timer even if the match ends?
  }

  If you want your timer to loop, simply return the time of the next callback inside of your callback, for example:

  callback = function()
  return Time() + 30 -- Will fire again in 30 seconds
  end
  ]]

  if not args.endTime or not args.callback then
    print("Invalid timer created: "..name)
    return
  end

  -- Store the timer
  self.timers[name] = args

  -- Update the timer
  --self:UpdateTimerData()
end

function DotaDashGameMode:RemoveTimer(name)
  -- Remove this timer
  self.timers[name] = nil

  -- Update the timers
  --self:UpdateTimerData()
end

function DotaDashGameMode:RemoveTimers(killAll)
  local timers = {}

  -- If we shouldn't kill all timers
  if not killAll then
    -- Loop over all timers
    for k,v in pairs(self.timers) do
      -- Check if it is persistant
      if v.persist then
        -- Add it to our new timer list
        timers[k] = v
      end
    end
  end

  -- Store the new batch of timers
  self.timers = timers
end

function DotaDashGameMode:_WatConsoleCommand()
  print( '******* DotaDash Game Status ***************' )
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      print ( string.format ( 'PlayerdID: %d called wat', playerID ) )
    end
  end

  PrintTable(self.vPlayers)
  print( '*********************************************' )
end

function DotaDashGameMode:OnPlayerKilled(keys)
  --[[print('[DOTADASH] OnPlayerKilled')
  PrintTable(keys)
  PrintTable(getmetatable(keys))
  print('-----------------------')]]
end

function DotaDashGameMode:OnEntityKilled( keys )
  --[[print('[DOTADASH] OnEntityKilled')
  PrintTable(keys)
  PrintTable(getmetatable(keys))
  print('-----------------------')]]
end

function DotaDashGameMode:FindAndRemove(hero, abilityName)
  if hero == nil or abilityName == nil then
    return
  end

  local ability = hero:FindAbilityByName(abilityName)
  if ability == nil then
    return
  end

  hero:RemoveAbility(abilityName)
end

function DotaDashGameMode:FindAndRemoveMod(hero, modName)
  if hero:HasModifier(modName) then
    hero:RemoveModifierByName(modName)
  end
end

function DotaDashGameMode:DrawBarriersForPlayer(player)
  --Create Barriers
  if roundOne then
    return
  end
  self:CreateTimer(DoUniqueString('waypoints'), {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 3,
    callback = function(reflex, args)
      local barriers = MAP_DATA.barriers
      if barriers ~= nil then
        for i=1,#barriers do
          local barrier = barriers[i]

          local particle = ParticleManager:CreateParticleForPlayer("dd_earthshaker_fissure", PATTACH_WORLDORIGIN, nil, player)
          ParticleManager:SetParticleControl(particle, 0, barrier.from)
          ParticleManager:SetParticleControl(particle, 1, barrier.to) -- radius, thickness, speed
          ParticleManager:SetParticleControl(particle, 2, Vector(10000,0,0)) -- duration

          ParticleManager:ReleaseParticleIndex(particle)
        end
      end
    end
    })
end

function DotaDashGameMode:DrawWaypointsForPlayer(player)
  if roundOne then
    return
  end
  self:CreateTimer(DoUniqueString('waypoints'), {
    useGameTime = true,
    endTime = GameRules:GetGameTime() + 3,
    callback = function(reflex, args)
      local waypoints = MAP_DATA.waypoints
      for i=1,#waypoints do
        local waypoint = waypoints[i]
        local unit = waypoint.unit
        
        local particleName = waypoint.particle or "dark_seer_wall_of_replica"
        local particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_ABSORIGIN_FOLLOW, unit, player)
        ParticleManager:SetParticleControl(particle, 0, Vector(0,0,0)) -- something
        ParticleManager:SetParticleControl(particle, 1, waypoint.to) -- endpoint
        ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- something
      end
    end
    })
end

function scaleTable(tab)
  local total = 0
  for i=1,#tab do
    for k,v in pairs(tab[i]) do
      total = total + v
    end
  end
  
  local val = 0
  for i=1,#tab do
    for k,v in pairs(tab[i]) do
      tab[i][k] = 100 * (val + v) / total
      val = val + v 
    end
  end
  
  return tab
end

function callModRemover( caster, modName, abilityLevel)
  if abilityLevel == nil then
    abilityLevel = ""
  else
    abilityLevel = "_" .. abilityLevel
  end
  local applier = modName .. abilityLevel .. "_applier"
  local ab = caster:FindAbilityByName(applier)
  if ab == nil then
    caster:AddAbility(applier)
    ab = caster:FindAbilityByName( applier )
  end
  ab:OnChannelFinish(true)
  --caster:CastAbilityNoTarget(ab, -1)
  caster:RemoveAbility(applier)
end

function callModApplier( caster, modName, abilityLevel)
  if abilityLevel == nil then
    abilityLevel = ""
  else
    abilityLevel = "_" .. abilityLevel
  end
  local applier = modName .. abilityLevel .. "_applier"
  local ab = caster:FindAbilityByName(applier)
  if ab == nil then
    caster:AddAbility(applier)
    ab = caster:FindAbilityByName( applier )
  end
  caster:CastAbilityNoTarget(ab, -1)
  caster:RemoveAbility(applier)
end

function hasPowerup(unit)
  if unit:HasItemInInventory("item_powerup") then
    return true
  end
  for i=1,#ITEMS_TABLE do
    for k,v in pairs(ITEMS_TABLE[i]) do
      if unit:HasItemInInventory(k) then
        return true
      end
    end
  end
  --[[for k,v in pairs(ITEM_FIRST) do
    if unit:HasItemInInventory(k) then
      return true
    end
  end]]
  
  return false
end

-- A helper function for dealing damage from a source unit to a target unit.  Damage dealt is pure damage
function dealDamage(source, target, damage)
  local unit = nil
  if damage == 0 then
    return
  end
  
  if source ~= nil then
    unit = CreateUnitByName("npc_dota_danger_indicator", target:GetAbsOrigin(), false, source, source, source:GetTeamNumber())
  else
    unit = CreateUnitByName("npc_dota_danger_indicator", target:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NOTEAM)
  end
  unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  unit:AddNewModifier(unit, nil, "modifier_phased", {})
  --local dummy = unit:FindAbilityByName("reflex_dummy_unit")
  --dummy:SetLevel(1)
  
  local maxTimes = math.floor(damage / 2000)
  local remainder = math.floor(damage % 2000)
  local abilIndex = math.floor((remainder-1) / 20) + 1
  local abilLevel = math.floor(((remainder-1) % 20)) + 1
  
  local hp = target:GetHealth()
  
  if remainder ~= 0 then
    local abilityName = "modifier_damage_applier" .. abilIndex
    unit:AddAbility(abilityName)
    local ability = unit:FindAbilityByName( abilityName )
    ability:SetLevel(abilLevel)
    
    local diff = nil
    
    diff = target:GetAbsOrigin() - unit:GetAbsOrigin()
    diff.z = 0
    unit:SetForwardVector(diff:Normalized())
    unit:CastAbilityOnTarget(target, ability, 0 )
  end
  
  for i=1,maxTimes do
    unit:AddAbility("modifier_damage_applier100")
    local ability = unit:FindAbilityByName( "modifier_damage_applier100" )
    ability:SetLevel(20)
    diff = target:GetAbsOrigin() - unit:GetAbsOrigin()
    diff.z = 0
    unit:SetForwardVector(diff:Normalized())
    unit:CastAbilityOnTarget(target, ability, 0 )
  end
  
  DotaDashGameMode:CreateTimer(DoUniqueString("damage"), {
    endTime = GameRules:GetGameTime() + 0.2,
    useGameTime = true,
    callback = function(reflex, args)
      unit:Destroy()
      if IsValidEntity(target) and target:GetHealth() == hp and hp ~= 0 and damage ~= 0 then
        print ("[DOTADASH] WARNING: dealDamage did no damage -- retrying : " .. hp)
        dealDamage(source, target, damage)
      end
    end
  })
end