local spaceship = {}
spaceship.__index = spaceship

function spaceship.create()
    local object = {}
    setmetatable(object,spaceship)
    return object
end

function spaceship:init()
    MsgSystem:RegisterHandler( self.entity, "OnChargeEnter" )
    MsgSystem:RegisterHandler( self.entity, "OnChargeExit" )
    MsgSystem:RegisterHandler( self.entity, "OnGhostEnter" )
    MsgSystem:RegisterHandler( self.entity, "OnGhostExit" )
    MsgSystem:RegisterHandler( self.entity, "OnSpawnEnter" )
    MsgSystem:RegisterHandler( self.entity, "OnSpawnExit" )    
    MsgSystem:RegisterHandler( self.entity, "OnDestroy" )
    MsgSystem:RegisterHandler( self.entity, "OnDamage" )
    MsgSystem:RegisterHandler( self.entity, "OnRespawn" )
    MsgSystem:RegisterHandler( self.entity, "OnShieldDamage" )	
    MsgSystem:RegisterHandler( self.entity, "OnCoreDeath" )
    MsgSystem:RegisterHandler( self.entity, "OnCoreDeathSurvival" )	
    MsgSystem:RegisterHandler( self.entity, "OnAddDamage" )	
	MsgSystem:RegisterHandler( self.entity, "OnPermissionUpdate" )		

    self.fadeFSM = EntityService:CreateStateMachine( self.entity )
    self.fadeFSM:AddState( "fade_in", { from="*", enter="OnFadeInEnter", execute="OnFadeInExecute", exit="OnFadeInExit" } )
    self.fadeFSM:AddState( "ghost_fade_in", { from="*", enter="OnFadeInEnter", execute="OnFadeInExecute", exit="OnGhostFadeInExit" } ) 
    self.fadeTime = 0.3
    
    self.isGhost = false
    self.currentMesh = "meshes/units/alien/spaceship_plasma.mesh"
    self.currentEffect = INVALID_ID
	self.player_color = PlayerService:GetPlayerColor( self.entity )
    self.lastOverridenMaterial = "";
	
    self.chargeUpgrade1Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_1);
    self.chargeUpgrade2Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_2);
    self.chargeUpgrade3Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_3);
    self.chargeUpgrade4Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_4);	

	self.empCooldownTimer = 5
	self.empCooldownHandler = EntityService:CreateSequence( self.entity )
	self.empCooldownHandler:RegisterInterrupt( self.empCooldownTimer, "RestorePlayerEMPPermissions" )
	
	self:NightModeOn()
end

function spaceship:OnPermissionUpdate( state )
    self.chargeUpgrade1Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_1);
    self.chargeUpgrade2Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_2);
    self.chargeUpgrade3Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_3);
    self.chargeUpgrade4Bought = PlayerService:GetPermission(self.entity, PP_CHARGE_WEAPON_UPGRADE_4);
end

function spaceship:GetPlayerColor() 
    return self.player_color
end

function spaceship:FadeIn()
    EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", 1 )
    self.fadeFSM:ChangeState("fade_in")
    return self.fadeTime
end

function spaceship:FadeOut( mesh, material )
    self.currentEffect = EffectService:AttachEffect( self.entity, mesh )
    EntityService:ChangeMaterial( self.currentEffect, material )
    return 0
end

function spaceship:OnFadeInEnter( state )
    state:SetDurationLimit( self.fadeTime )
end

function spaceship:OnFadeInExecute( state )
    local progress = state:GetDuration() / state:GetDurationLimit()
    EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", 1 - progress )
end


function spaceship:OnFadeInExit( state )

end

function spaceship:GhostFadeIn()
    EntityService:ChangeMaterial( self.entity, "units_alien/spaceship_" .. self:GetPlayerColor() .. "_ghost_holo_dissolve" )
    EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", 1 )
    self.fadeFSM:ChangeState("ghost_fade_in")
    return self.fadeTime
end

function spaceship:OnGhostFadeInExit( state )
    EntityService:ChangeMaterial( self.entity, "units_alien/spaceship_" .. self:GetPlayerColor() .. "_ghost" )
end

function spaceship:OnChargeEnter( event ) 
    self.isGhost = false
    local material = EntityService:GetOverridenMaterial( self.entity )

    EntityService:ChangeMesh( self.entity, "meshes/units/alien/spaceship_charge.mesh" )

    if ( material ~= "" ) then 
        EntityService:ChangeMaterial( self.entity, material )
    end

	if ( self.chargeLoopSound == nil ) then
		self.chargeLoopSound = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/alien_charging_weapon")
		soundDuration = SoundService:GetSoundDuration("weapon_fire/charging_player_weapon")
		EntityService:RemoveEntity( self.chargeLoopSound, soundDuration )
	end
	EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_charge_start")
   
    self:FadeIn()
    AnimationService:StartAnim( self.entity, "to_charge", false )
	self.isCharge = true
	
    return AnimationService:GetAnimDuration( self.entity, "to_charge" )
end

function spaceship:OnChargeExit( event )
    EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/spaceship_morph_particle" )
    self.currentEffect = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_charge" )
    AnimationService:StartAnim( self.currentEffect, "from_charge", false )
	EntityService:RemoveEntity( self.chargeLoopSound )
    self.chargeLoopSound = nil
	
    return 0
end

function spaceship:OnGhost1Enter( event )
    self:OnGhostEnter( "meshes/units/alien/spaceship_plasma.mesh" )
    self.currentLightningEffect = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_plasma_lightning" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_ghost_enter")
    EffectService:AttachEffects( self.entity, "ghost_state" )
    return self.fadeTime
end
function spaceship:OnGhost1Exit( event )
    self:OnGhostExit( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_plasma" )
    EntityService:RemoveEntity( self.currentLightningEffect ) 
    EffectService:DestroyEffectsByType( self.entity, "ghost_state" )
    return 0
end
function spaceship:OnGhost2Enter( event )
    self:OnGhostEnter( "meshes/units/alien/spaceship_rockets.mesh" )
    self.currentLightningEffect = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_rockets_lightning" )
    EffectService:AttachEffects( self.entity, "ghost_state" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_ghost_enter")
    return self.fadeTime
end
function spaceship:OnGhost2Exit( event )
    self:OnGhostExit( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_rockets" )
    EntityService:RemoveEntity( self.currentLightningEffect ) 
    EffectService:DestroyEffectsByType( self.entity, "ghost_state" )
    return 0
end
function spaceship:OnGhost3Enter( event )
    self:OnGhostEnter( "meshes/units/alien/spaceship_laser.mesh" )
    self.currentLightningEffect = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_laser_lightning" )
    EffectService:AttachEffects( self.entity, "ghost_state" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_ghost_enter")
    return self.fadeTime
end
function spaceship:OnGhost3Exit( event )
    self:OnGhostExit( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_laser" )
    EntityService:RemoveEntity( self.currentLightningEffect ) 
    EffectService:DestroyEffectsByType( self.entity, "ghost_state" )
    return 0
end
function spaceship:OnGhost4Enter( event )
    self:OnGhostEnter( "meshes/units/alien/spaceship_bombs.mesh" )
    self.currentLightningEffect = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_bombs_lightning" )
    EffectService:AttachEffects( self.entity, "ghost_state" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_ghost_enter")
    return self.fadeTime
end
function spaceship:OnGhost4Exit( event )
    self:OnGhostExit( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_bombs" )
    EntityService:RemoveEntity( self.currentLightningEffect ) 
    EffectService:DestroyEffectsByType( self.entity, "ghost_state" )
    return 0
end

function spaceship:OnGhostEnter( mesh )
	if( self.isCharge ) then
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/spaceship_morph_particle" )
	else
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/spaceship_morph" )
	end

    self:OnWeaponChargeExit( nil )
    EntityService:SetImmortality( self.entity, true )
    EntityService:DisableRegeneration( self.entity )
    EntityService:ChangeType( self.entity, "spaceship|ghost" )
    --EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_engine_ghost" )    
    EntityService:ChangeMesh( self.entity, mesh )
    if ( self.isGhost ) then
        self:GhostFadeIn()
    else
        self.lastOverridenMaterial = EntityService:GetOverridenMaterial( self.entity )
        EntityService:ChangeMaterial( self.entity, "units_alien/spaceship_" .. self:GetPlayerColor() .. "_ghost" )
    end
    if ( EntityService:IsAlive( self.currentEffect ) ) then
        EntityService:ChangeMaterial( self.currentEffect, "units_alien/spaceship_" .. self:GetPlayerColor() .. "_ghost_dissolve" )
    end
    MsgSystem:SendGlobalMsg( "OnPlayerEnteredGhostMode" ); 

    EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_ghost" )

    self.isGhost = true
	self.isCharge = false
end

function spaceship:OnGhostExit( blueprint )
    --EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_engine_ghost" )    
    MsgSystem:SendGlobalMsg( "OnPlayerExitedGhostMode" );
    self.currentEffect = EffectService:AttachEffect( self.entity, blueprint )
    EntityService:ChangeMaterial( self.currentEffect, "units_alien/spaceship_" .. self:GetPlayerColor() .. "_ghost_holo_dissolve" )
    EntityService:SetImmortality( self.entity, false )
    EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_ghost" )
end

function spaceship:OnFight1Enter( event )
    self:OnFighterEnter( "meshes/units/alien/spaceship_plasma.mesh" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_morph_1")
    return self:FadeIn()
end

function spaceship:OnFight1Exit( event )
    local material = EntityService:GetOverridenMaterial( self.entity )

    if ( material ~= "" ) then 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_plasma", material )
    else 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_plasma", "units_alien/spaceship_" .. self:GetPlayerColor() )
    end
end

function spaceship:OnFight2Enter( event ) 
    self:OnFighterEnter( "meshes/units/alien/spaceship_rockets.mesh" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_morph_2")    
    return self:FadeIn()
end

function spaceship:OnFight2Exit( event )
    local material = EntityService:GetOverridenMaterial( self.entity )

    if ( material ~= "" ) then 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_rockets", material )
    else 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_rockets", "units_alien/spaceship_" .. self:GetPlayerColor() )
    end
end

function spaceship:OnFight3Enter( event )
    self:OnFighterEnter( "meshes/units/alien/spaceship_laser.mesh" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_morph_3")
    return self:FadeIn()
end

function spaceship:OnFight3Exit( event )
    local material = EntityService:GetOverridenMaterial( self.entity )

    if ( material ~= "" ) then 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_laser", material )
    else 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_laser", "units_alien/spaceship_" .. self:GetPlayerColor() )
    end
end

function spaceship:OnFight4Enter( event )
    self:OnFighterEnter( "meshes/units/alien/spaceship_bombs.mesh" )
    EffectService:AttachEffect( self.entity, "player/base/effects/misc/spaceship_morph_4")
    return self:FadeIn()
end

function spaceship:OnFight4Exit( event )
    local material = EntityService:GetOverridenMaterial( self.entity )

    if ( material ~= "" ) then 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_bombs", material )
    else 
        return self:FadeOut( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_bombs", "units_alien/spaceship_" .. self:GetPlayerColor() )
    end
end

function spaceship:OnFighterEnter( mesh )
	if( self.isCharge ) then
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/spaceship_morph_particle" )
	else
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/spaceship_morph" )
	end

    EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_engine_ghost" )    
    EntityService:ChangeMesh( self.entity, mesh )
	EntityService:ChangeMaterial( self.entity, "units_alien/spaceship_" .. self:GetPlayerColor() )
    EntityService:ChangeType( self.entity, "air_unit|spaceship|fighter" ) 
    EntityService:EnableRegeneration( self.entity )
	EntityService:SetImmortality( self.entity, false )
    
	self.currentMesh = mesh;

    if ( self.isGhost or self.isCharge ) then 
        if ( self.lastOverridenMaterial ~= "" ) then 
            EntityService:ChangeMaterial( self.entity, self.lastOverridenMaterial )
            self.lastOverridenMaterial = ""
        else
            EntityService:ChangeMaterial( self.entity, "units_alien/spaceship_" .. self:GetPlayerColor() )
        end
    end

    self.isGhost = false  
	self.isCharge = false
end

function spaceship:OnSpawnEnter( event )
    self.isGhost = false
	self.isCharge = false
	PlayerService:TeleportToSpawn( self.entity );
    EffectService:SpawnDelayedEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_creation", 0.1 )	
    return 0.9
end

function spaceship:OnSpawnExit( event )
    EffectService:AttachDelayedEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/spaceship_shield", 0.1 )	
    EffectService:AttachDelayedEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/vehicles/spaceship_spawn", 0.3 )
    return 0.0
end

function spaceship:OnCoreDeath( event )
	PlayerService:SwitchToFight( self.entity )
	MsgSystem:SendEntityDelayedMsg( "OnAddDamage", self.entity, 0.1 )		    
end

function spaceship:OnCoreDeathSurvival( event )
	PlayerService:SwitchToBuild( self.entity )
end

function spaceship:OnAddDamage( event )	
    DamageService:AddDamage( self.entity, 9001 )
end

function spaceship:OnDamage( event )
--LogService:Log("OnDamage")	
-- EMP DAMAGE FUNCTIONALITY
     if ( event:GetDamageType() == "emp" ) then
		--LogService:Log("OnDamage EMP")			
		local restorePermissions = false		
		
		if EntityService:IsAlive( self.entity ) then 			
		
			PlayerService:DisablePlayerInput( self.entity, INPUT_SHOOT )
			PlayerService:DisablePlayerInput( self.entity, INPUT_CHARGE )
			PlayerService:DisablePlayerInput( self.entity, INPUT_SWITCH )
		
			EffectService:AttachEffect( self.entity, "effects/weapon_hit/spaceship_emp_hit" )			
			PlayerService:ShowCustomCooldown( self.entity, "hud/bars/emp_bars_1x2", self.empCooldownTimer )			
		
			restorePermissions = true
		end			
	
		if restorePermissions == true then			
			self.empCooldownHandler:Reset()
			self.empCooldownHandler:Start()
		end
	end
	
end

function spaceship:RestorePlayerEMPPermissions()    
    PlayerService:EnablePlayerInput( self.entity, INPUT_SHOOT )
    PlayerService:EnablePlayerInput( self.entity, INPUT_CHARGE )
    PlayerService:EnablePlayerInput( self.entity, INPUT_SWITCH )    
end

function spaceship:OnDestroy( event )
    self:SpawnWreck()
	self.isGhost = false
	self.isCharge = false
	self:RestorePlayerEMPPermissions()
    --EntityService:DestroyEntity( self.entity, "default", false )
    MsgSystem:SendEntityDelayedMsg( "OnRespawn", self.entity, 3 )		
	LogService:Log("spaceship OnRespawn sent")
    MsgSystem:SendGlobalMsg( "OnPlayerDeath" )		
end

function spaceship:OnRespawn( event )
    LogService:Log("spaceship:OnRespawn called")
	if EntityService:IsAlive( MissionService:GetCoreId() ) == true then
		self.isGhost = false
		self.isCharge = false
		LogService:Log("calling PlayerService:RespawnSpaceship")
		PlayerService:RespawnSpaceship( self.entity );
	end
end

function spaceship:SpawnWreck( )
    if self.isCharge == true then
		local wreckId = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_wreck_charge", self.entity, "neutral" )
	elseif ( self.currentMesh == "meshes/units/alien/spaceship_plasma.mesh") then
        local wreckId = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_wreck_plasma", self.entity, "neutral" )        
    elseif ( self.currentMesh == "meshes/units/alien/spaceship_rockets.mesh" ) then
        local wreckId = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_wreck_rockets", self.entity, "neutral" )        
    elseif ( self.currentMesh == "meshes/units/alien/spaceship_bombs.mesh" ) then
        local wreckId = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_wreck_bombs", self.entity, "neutral" )        
    elseif ( self.currentMesh == "meshes/units/alien/spaceship_laser.mesh" ) then
        local wreckId = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/units/alien/spaceship_wreck_laser", self.entity, "neutral" )        
    end
end

function spaceship:OnWeaponChargeStart( weapon )
    self.chargeWeapon = weapon
    self.chargeTimer = 0
    self.chargeStage0 = false
    self.chargeStage1 = false
    self.chargeStage2 = false
    self.chargeStage3 = false
    
    if ( self.chargeWeapon == "plasma" ) then
        self:StartPlasmaCharge()
    elseif ( self.chargeWeapon == "missiles" ) then
        self:StartMissileCharge()
    elseif ( self.chargeWeapon == "laser" ) then
        self:StartLaserCharge()
    elseif ( self.chargeWeapon == "bombs" ) then
        self:StartBombCharge()
    end
end

function spaceship:OnWeaponChargeExecute( dt )
    if ( self.chargeWeapon ~= nil ) then 
        self.chargeTimer = self.chargeTimer + dt
        if ( self.chargeWeapon == "plasma" ) then
            self:ExecutePlasmaCharge()
        elseif ( self.chargeWeapon == "missiles" ) then
            self:ExecuteMissileCharge()
        elseif ( self.chargeWeapon == "laser" ) then
            self:ExecuteLaserCharge()
        elseif ( self.chargeWeapon == "bombs" ) then
            self:ExecuteBombCharge()
        end
    end
end

function spaceship:OnWeaponChargeExit()
    
    local status = false;
    local cooldown = 0.0

    if ( self.chargeWeapon ~= nil ) then 
        if ( self.chargeWeapon == "plasma" ) then
            status = self:ReleasePlasmaCharge()
        elseif ( self.chargeWeapon == "missiles" ) then
            status = self:ReleaseMissileCharge()
        elseif ( self.chargeWeapon == "laser" ) then
            status = self:ReleaseLaserCharge()
        elseif ( self.chargeWeapon == "bombs" ) then
            status = self:ReleaseBombCharge()
        end
    end

    if ( status == true ) then 
        cooldown = 0.6
    end

    self.chargeWeapon = nil
    self.chargeTimer = 0
    self.chargeStage0 = false
    self.chargeStage1 = false
    self.chargeStage2 = false
    self.chargeStage3 = false

    return cooldown;
end

function spaceship:OnShieldDamage()
	if self.chargeTimer < 1.3 then
		self.chargeTimer = self.chargeTimer + 0.5 -- 0 -> 1,3
	elseif self.chargeTimer < 3.0 then
		self.chargeTimer = self.chargeTimer + 0.2 -- 1 -> 3
	elseif self.chargeTimer < 5.6 then
		self.chargeTimer = self.chargeTimer + 0.2 -- 3 -> 5
	end
end

function spaceship:GetChargedScale( time )
    local time1 = time - 1
    local time2 = time1 * time1
    local time3 = time2 * time1
    local time4 = time2 * time2

    if ( time < 1.6 ) then 
        return (-25.5555555555597) * time3 + (20.7777777777816) * time2 + (-1.60000000000087) * time1
    elseif ( time < 2.4 ) then 
        return 1.0
    elseif ( time < 3.6 ) then 
        return (-3.41666666658322) * time3 + (20.3821428566456) * time2 + (-38.87833333237) * time1 + (24.8474285708216)
    elseif ( time < 4.4 ) then 
        return 1.5
    elseif ( time < 5.6 ) then 
        return (-3.95833332438253) * time3 + (47.3035713219464) * time2 + (-186.580951960216) * time1 + (244.609999449945)
    else 
        return 2.0  + 0.20 * math.sin( ( time - 5.6 ) * 3.14 )
    end
end

function spaceship:StartPlasmaCharge()
    self.chargePlasmaStartEnt = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_start",  "att_muzzle_forward" )
    self.chargeLaserEnt = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/laser_tracer", "att_muzzle_forward")
	if (self.chargeUpgrade1Bought == true ) then
		self.chargeShieldEnt = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/shield/spaceship_shield" )
		AnimationService:StartAnim( self.chargeShieldEnt, "shield_appear", false )
		self.chargeShieldDistortionEnt = EffectService:AttachEffect( self.chargeShieldEnt, "shield/spaceship_shield_distortion" )
		TeamService:SetTeam( self.chargeShieldDistortionEnt, PLAYER_TEAM )
	end
	self.chargePlasmaEnt = nil
end

function spaceship:ExecutePlasmaCharge()
    local offset = self.chargeTimer / 2.5 
	if (self.chargeUpgrade1Bought == true ) then
	    if ( offset > 2 ) then offset = 2 end
		EntityService:SetPosition( self.chargeShieldEnt, offset, 0, 0 )
		EntityService:SetGraphicsUniform( self.chargeShieldEnt, "cTimer", self.chargeTimer )

		local shieldObject = EntityService:GetLuaObject( self.chargeShieldEnt )
		if ( self.chargeStage0 == false and shieldObject ~= nil ) then
			shieldObject:SetParent( self.entity )
			self.chargeStage0 = true
		end
    end

    if ( self.chargeStage1 == false and self.chargeTimer >= 1.3 ) then
        self.chargePlasmaEnt = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_plasma_ball", "att_muzzle_forward" )
        TeamService:SetTeam( self.chargePlasmaEnt, PLAYER_TEAM )
        EntityService:RemoveComponent( self.chargePlasmaEnt, "AmmoComp" ) 
        --    EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_change" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_change", "att_muzzle_forward" )		
        EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" )
        EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_sphere" )
        EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_shield_energy" )
        if ( self.chargeUpgrade1Bought == true ) then
            EntityService:ChangeMaterial( self.chargeShieldDistortionEnt, "shield/spaceship_shield_distortion_1" )
        end
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_low_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_low_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_far_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_far_right" )
		SoundService:Play( "weapon_fire/alien_charging_lvl1_marker", self.entity )
        self.chargeStage1 = true
    end

    if ( self.chargeStage2 == false and self.chargeTimer >= 3.0 ) then
       -- EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_lvl2_change" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_lvl2_change", "att_muzzle_forward" )		
        EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_ring" )
        if ( self.chargeUpgrade1Bought == true ) then
            EntityService:ChangeMaterial( self.chargeShieldDistortionEnt, "shield/spaceship_shield_distortion_2" )
        end
    	SoundService:Play( "weapon_fire/alien_charging_lvl2_marker", self.entity )
        self.chargeStage2 = true
    end

    if ( self.chargeStage3 == false and self.chargeTimer >= 5.0 ) then
    --    EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_final_change" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_final_change", "att_muzzle_forward" )		
        EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_outer_energy" )
        if ( self.chargeUpgrade1Bought == true ) then
            EntityService:ChangeMaterial( self.chargeShieldDistortionEnt, "shield/spaceship_shield_distortion_3" )
        end
        EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2" )  
		SoundService:Play( "weapon_fire/alien_charging_lvl3_marker", self.entity )		
        self.chargeStage3 = true
    end

    if ( self.chargePlasmaEnt ~= nil ) then
        local scale = self:GetChargedScale( self.chargeTimer )
        EntityService:SetScale( self.chargePlasmaEnt, scale, scale, scale )
    end
end

function spaceship:ReleasePlasmaCharge()
    local status = false

	if ( self.chargeUpgrade1Bought == true ) then
		if ( self.chargeTimer > 0.4 and self.chargeTimer < 1.3 ) then
			AnimationService:StartAnim( self.chargeShieldEnt, "shield_disappear", false )
			EntityService:RemoveEntity( self.chargeShieldEnt, 0.4)
			self.chargeShieldEnt = nil
		elseif ( self.chargeTimer > 1.3 ) then 
			AnimationService:StartAnim( self.chargeShieldEnt, "shield_fire", false )
			EntityService:RemoveEntity( self.chargeShieldEnt, 6.0 )
			EntityService:DetachEntity( self.chargeShieldEnt )
			EntityService:DisableCollisions( self.chargeShieldEnt )
			self.chargeShieldEnt = nil
			status = true
		else
			EntityService:RemoveEntity( self.chargeShieldEnt )
			self.chargeShieldEnt = nil
		end
	end
    if ( self.chargePlasmaEnt ~= nil ) then
        if ( self.chargeTimer > 1.3 ) then 
            EntityService:CreateLifeTime( self.chargePlasmaEnt, 0.3, "camera")
            EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_plasma_ball" )
            MoveService:SetMoveType( self.chargePlasmaEnt, "forward", true )

            EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charged_plasma_ball" )
            EffectService:DestroyEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_shield_energy" )
                        
            if ( self.chargeStage3 == true ) then 
                EntityService:SetAmmoDef( self.chargePlasmaEnt, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_plasma_ball_lvl3" )
                EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_trail_big" )
				EffectService:AttachEffect( self.chargePlasmaEnt, "player/base/projectiles/player_plasma_ball_wind" )
                EffectService:DestroyEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_outer_energy" )
                EffectService:SpawnEffect( self.chargePlasmaEnt, "effects/misc/camera_shake_big" )
				SoundService:Stop( "weapon_fire/alien_charging_lvl3_marker", self.entity )
            elseif ( self.chargeStage2 == true ) then 
                EntityService:SetAmmoDef( self.chargePlasmaEnt, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_plasma_ball_lvl2" )
                EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_trail_medium" )
				EffectService:AttachEffect( self.chargePlasmaEnt, "player/base/projectiles/player_plasma_ball_wind" )
                EffectService:SpawnEffect( self.chargePlasmaEnt, "effects/misc/camera_shake_medium" )
				SoundService:Stop( "weapon_fire/alien_charging_lvl2_marker", self.entity )
            elseif ( self.chargeStage1 == true ) then
                EntityService:SetAmmoDef( self.chargePlasmaEnt, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_plasma_ball_lvl1" )
                EffectService:AttachEffect( self.chargePlasmaEnt, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_trail_small" )
				EffectService:AttachEffect( self.chargePlasmaEnt, "player/base/projectiles/player_plasma_ball_wind" )
                EffectService:SpawnEffect( self.chargePlasmaEnt, "effects/misc/camera_shake_small" )
				SoundService:Stop( "weapon_fire/alien_charging_lvl1_marker", self.entity )
            end
        else
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_plasma_ball" )
        end
        
        self.chargePlasmaEnt = nil
    end

    EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2" )    
    
   	if ( self.chargeShieldDistortionEnt ~= nil) then
        EntityService:RemoveEntity( self.chargeShieldDistortionEnt ) 
        self.chargeShieldDistortionEnt = nil
    end
    EntityService:RemoveEntity( self.chargeLaserEnt )
    self.chargeLaserEnt = nil
    EntityService:RemoveEntity( self.chargePlasmaStartEnt ) 
    self.chargePlasmaStartEnt = nil

    return status
end

function spaceship:StartMissileCharge()
    self.chargeEmpStartEnt = EffectService:AttachEffect(self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_start",  "att_center")

    if ( self.chargeUpgrade2Bought == true ) then
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_field", "att_center" )
        self.chargeEmpShieldEnt = EffectService:AttachEffect(self.entity, "player/" .. self:GetPlayerColor() .. "/shield/emp_shield",  "att_center" )
	    TeamService:SetTeam( self.chargeEmpShieldEnt, PLAYER_TEAM )
        EntityService:SetParent(self.entity, self.chargeEmpShieldEnt);
	    EntityService:SetGraphicsUniform( self.chargeEmpShieldEnt, "cAlpha",  0.0 )
        AnimationService:StartAnim( self.chargeEmpShieldEnt, "emp_shield_appear", false )
    end
    self.chargeEmpEnt = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/misc/emp_core", "att_center"  )
    AnimationService:StartAnim( self.chargeEmpEnt, "emp_core_rotation", false )
end

function spaceship:ExecuteMissileCharge()
    if ( self.chargeStage1 == false and self.chargeTimer > 0.2 ) then
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl1", "att_center" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full", "att_center" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_change", "att_center" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy", "att_arm_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy", "att_arm_right" ) 
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy", "att_arm_low_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy", "att_arm_low_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy", "att_arm_far_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy", "att_arm_far_right" )
		SoundService:Play( "weapon_fire/alien_charging_lvl1_marker", self.entity )
        self.chargeStage1 = true
    end
    if ( self.chargeStage2 == false and self.chargeTimer > 1.5 ) then
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl2", "att_center" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_lvl2_change", "att_center" )
		SoundService:Play( "weapon_fire/alien_charging_lvl2_marker", self.entity )
        self.chargeStage2 = true
    end
    if ( self.chargeStage3 == false and self.chargeTimer > 3.0 ) then
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl3", "att_center" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_final_change", "att_center" )
        AnimationService:StartAnim( self.chargeEmpEnt, "emp_core_idle", true )
        EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy" ) 
		SoundService:Play( "weapon_fire/alien_charging_lvl3_marker", self.entity )
        self.chargeStage3 = true         
    end
end

function spaceship:ReleaseMissileCharge()
    local status = false
    if ( self.chargeUpgrade2Bought == true ) then
        if ( self.chargeTimer > 0.1 ) then
            EntityService:GetLuaObject( self.chargeEmpShieldEnt ):Destroy()
            self.chargeEmpShieldEnt = nil
        else
            EntityService:RemoveEntity( self.chargeEmpShieldEnt )
            self.chargeEmpShieldEnt = nil
        end
    end

    if ( self.chargeTimer > 0.2 ) then 
        status = true
        if ( self.chargeStage3 == true ) then 
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl3" )
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl2" )
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl1" )
			EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" ) 
            EffectService:SpawnEffect( self.entity, "effects/misc/camera_shake_big", "att_center" )
            local blast = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_emp_lvl3", self.entity, "att_center", "player" )
            EntityService:SetAmmoDef( blast, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_emp_lvl3" )
			SoundService:Stop( "weapon_fire/alien_charging_lvl3_marker", self.entity )
        elseif ( self.chargeStage2 == true ) then 
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl2" )
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl1" )
			EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" ) 
            EffectService:SpawnEffect( self.entity, "effects/misc/camera_shake_medium", "att_center" )
            local blast = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_emp_lvl2", self.entity, "att_center", "player" )
            EntityService:SetAmmoDef( blast, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_emp_lvl2" )
			SoundService:Stop( "weapon_fire/alien_charging_lvl2_marker", self.entity )
        elseif ( self.chargeStage1 == true ) then
            EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_core_lvl1" )
			EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" ) 
            EffectService:SpawnEffect( self.entity, "effects/misc/camera_shake_small", "att_center" )
            local blast = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_emp_lvl1", self.entity, "att_center", "player" )
            EntityService:SetAmmoDef( blast, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_emp_lvl1" )
			SoundService:Stop( "weapon_fire/alien_charging_lvl1_marker", self.entity )
        end
    end

    EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_arm_energy" ) 
    if ( self.chargeUpgrade2Bought == true ) then
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_field" )
    end

    EntityService:RemoveEntity( self.chargeEmpEnt ) 
    self.chargeEmpEnt = nil 
    EntityService:RemoveEntity( self.chargeEmpStartEnt ) 
    self.chargeEmpStartEnt = nil

    return status
end

function spaceship:StartLaserCharge()
	if self.chargeLaserArmorEnt ~= nil then
		EntityService:RemoveEntity( self.chargeLaserArmorEnt ) 
		self.chargeLaserArmorEnt = nil
	end
	
    if ( self.chargeUpgrade3Bought == true ) then
        self.chargeLaserArmorEnt = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_gravity_field", "body" )
        BehaviorService:FireEvent( self.entity, "ActiveSpacehipLaserArmorEvent" );
    end
end

function spaceship:ExecuteLaserCharge()  
    if ( self.chargeStage1 == false and self.chargeTimer >= 0.2 ) then
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_low_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_low_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_far_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2", "att_arm_far_right" )
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_change" )
		SoundService:Play( "weapon_fire/alien_charging_lvl1_marker", self.entity )
        self.chargeStage1 = true
    end

    if ( self.chargeStage2 == false and self.chargeTimer >= 1.8 ) then
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_lvl2_change" )
		SoundService:Play( "weapon_fire/alien_charging_lvl2_marker", self.entity )	
        self.chargeStage2 = true
    end
	
    if ( self.chargeStage3 == false and self.chargeTimer >= 3.6 ) then
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_emp_final_change" )
		SoundService:Play( "weapon_fire/alien_charging_lvl3_marker", self.entity )	
        self.chargeStage3 = true
    end
end

function spaceship:ReleaseLaserCharge()
    local status = true
    EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_arm_energy2" )
    if ( self.chargeUpgrade3Bought == true ) then
        BehaviorService:FireEvent( self.entity, "DeactiveSpacehipLaserArmorEvent" )
        EntityService:RemoveEntity( self.chargeLaserArmorEnt ) 
        self.chargeLaserArmorEnt = nil
    end
    return status
end

function spaceship:GetLaserParams()
    if ( self.chargeStage1 == true  or self.chargeStage2 == true or self.chargeStage3 == true ) then
        local bombParams =	
        { 
            cooldown        = 25.0,
        } 
		--local ent=EffectService:AttachEffect( self.entity, "units/alien/spaceship_charge_cooldown", "att_center"  )
		--EntityService:SetLifeTime(ent, 20)
        return bombParams
    else 
        local bombParams =
        { 
            cooldown        = 25.0,
        } 
        return bombParams
    end
end

function spaceship:StartBombCharge()
    self.chargeHoloBombLvl1 = nil
    self.chargeHoloBombLvl2 = nil
    self.chargeHoloBombLvl3 = nil
    self.chargeTeleBombLvl1 = nil
    self.chargeTeleBombLvl2 = nil
    self.chargeTeleBombLvl3 = nil
    self.chargeBombLvl1 = nil
    self.chargeBombLvl2 = nil
    self.chargeBombLvl3 = nil
    self.chargeStartEnt = EffectService:AttachEffect(self.entity,  "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/plasma_ball_start", "att_muzzle_forward" )
end

function spaceship:ExecuteBombCharge() 

   if ( self.chargeStage0 == false and self.chargeTimer > 0.0 ) then

        ------------------------------------ HOLO BOMB LVL 1 -----------------------------------
        self.chargeHoloBombLvl1 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl1", "att_muzzle_forward" )
        EntityService:SetInitialLuaState( self.chargeHoloBombLvl1, "hologram" )
        EntityService:SetVisible( self.chargeHoloBombLvl1, false )

        ------------------------------------ TELE BOMB LVL 1 -----------------------------------
        self.chargeTeleBombLvl1 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl1", "att_muzzle_forward" )
        EntityService:SetInitialLuaState( self.chargeTeleBombLvl1, "teleport" )
        EntityService:SetVisible( self.chargeTeleBombLvl1, false )

        --------------------------------------- BOMB LVL 1 ------------------------------------- 
        self.chargeBombLvl1 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl1", "att_center" )
        EntityService:SetInitialLuaState( self.chargeBombLvl1, "default" )
        EntityService:SetVisible( self.chargeBombLvl1, false )

        self.chargeStage0 = true
    end
    if ( self.chargeStage1 == false and self.chargeTimer > 0.3 ) then

        ------------------------------------- EFFECTS LVL 1 ----------------------------------- 
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl1", "att_center" ) 
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full", "att_center" ) 
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_hologram_core", "att_muzzle_forward" )
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_change", "att_muzzle_forward" )
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_change", "att_center" )

		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy", "att_arm_left" )
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy", "att_arm_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy", "att_arm_low_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy", "att_arm_low_right" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy", "att_arm_far_left" )
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy", "att_arm_far_right" )

		self.chargeStage1 = true
    end
    if ( self.chargeStage2 == false and self.chargeTimer > 200.2 ) then

        ------------------------------------ HOLO BOMB LVL 2 ----------------------------------- 
	    self.chargeHoloBombLvl2 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl2", "att_muzzle_forward" )
        EntityService:SetInitialLuaState( self.chargeHoloBombLvl2, "hologram" )
        EntityService:SetVisible( self.chargeHoloBombLvl2, false )

        ------------------------------------ TELE BOMB LVL 2 -----------------------------------
        self.chargeTeleBombLvl2 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl2", "att_muzzle_forward" )
        EntityService:SetInitialLuaState( self.chargeTeleBombLvl2, "teleport" )
        EntityService:SetVisible( self.chargeTeleBombLvl2, false )

        --------------------------------------- BOMB LVL 2 ------------------------------------- 
        self.chargeBombLvl2 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl2", "att_center" )
        EntityService:SetInitialLuaState( self.chargeBombLvl2, "default" )
        EntityService:SetVisible( self.chargeBombLvl2, false )

        ------------------------------------- EFFECTS LVL 2 ------------------------------------ 
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl2", "att_center" )        
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_change", "att_muzzle_forward" )        
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_change", "att_center" )        

        self.chargeStage2 = true
    end
    if ( self.chargeStage3 == false and self.chargeTimer > 300.2 ) then

        ------------------------------------ HOLO BOMB LVL 3 -----------------------------------
        self.chargeHoloBombLvl3 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl3", "att_muzzle_forward" )
        EntityService:SetInitialLuaState( self.chargeHoloBombLvl3, "hologram" )
        EntityService:SetVisible( self.chargeHoloBombLvl3, false )

        ------------------------------------ TELE BOMB LVL 3 -----------------------------------
        self.chargeTeleBombLvl3 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl3", "att_muzzle_forward" )
        EntityService:SetInitialLuaState( self.chargeTeleBombLvl3, "teleport" )
        EntityService:SetVisible( self.chargeTeleBombLvl3, false )

        --------------------------------------- BOMB LVL 3 ------------------------------------- 
        self.chargeBombLvl3 = EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl3", "att_center" )
        EntityService:SetInitialLuaState( self.chargeBombLvl3, "default" )
        EntityService:SetVisible( self.chargeBombLvl3, false )

        ------------------------------------- EFFECTS LVL 3 ----------------------------------- 
        EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl3", "att_center" )        
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_change", "att_muzzle_forward" )        
		EffectService:AttachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_change", "att_center" )   

        EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy" )     

        self.chargeStage3 = true         
    end
end

function spaceship:ReleaseBombCharge()
    local status = true

    if ( self.chargeStage1 == true ) then
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl1", "att_muzzle_forward" )
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl1", "att_muzzle_forward" )
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl1", "att_center" )
        EntityService:RemoveEntity( self.chargeHoloBombLvl1, 1.1 )
        EntityService:GetLuaObject( self.chargeHoloBombLvl1 ):FadeOut()
        EntityService:RemoveEntity( self.chargeTeleBombLvl1, 1.1 )
        EntityService:GetLuaObject( self.chargeTeleBombLvl1 ):FadeIn()
        EntityService:GetLuaObject( self.chargeBombLvl1 ):FadeOut()
        self.chargeHoloBombLvl1 = nil 
        self.chargeTeleBombLvl1 = nil
        self.chargeBombLvl1 = nil
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl1" )
		EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" ) 
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_hologram_core" )
    elseif ( self.chargeStage0 == true ) then 
        EntityService:RemoveEntity( self.chargeHoloBombLvl1 )
        EntityService:RemoveEntity( self.chargeTeleBombLvl1 )
        EntityService:RemoveEntity( self.chargeBombLvl1 )
    end    

    if ( self.chargeStage2 == true ) then
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl2", "att_muzzle_forward" )
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl2", "att_muzzle_forward" )
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl2", "att_center" )
        EntityService:RemoveEntity( self.chargeHoloBombLvl2, 1.1 )
        EntityService:GetLuaObject( self.chargeHoloBombLvl2 ):FadeOut()
        EntityService:RemoveEntity( self.chargeTeleBombLvl2, 1.1 )
        EntityService:GetLuaObject( self.chargeTeleBombLvl2 ):FadeIn()
        EntityService:GetLuaObject( self.chargeBombLvl2 ):FadeOut()
        self.chargeHoloBombLvl2 = nil
        self.chargeTeleBombLvl2 = nil
        self.chargeBombLvl2 = nil
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl2" )
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl1" )
		EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" ) 
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_hologram_core" )
    end    
    if ( self.chargeStage3 == true ) then 
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl3", "att_muzzle_forward" )
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl3", "att_muzzle_forward" )
        EffectService:DetachEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_lvl3", "att_center" )
        EntityService:RemoveEntity( self.chargeHoloBombLvl3, 1.1 )
        EntityService:GetLuaObject( self.chargeHoloBombLvl3 ):FadeOut()
        EntityService:RemoveEntity( self.chargeTeleBombLvl3, 1.1 )
        EntityService:GetLuaObject( self.chargeTeleBombLvl3 ):FadeIn()
        EntityService:GetLuaObject( self.chargeBombLvl3 ):FadeOut()
        self.chargeHoloBombLvl3 = nil 
        self.chargeTeleBombLvl3 = nil
        self.chargeBombLvl3 = nil

        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl3" )
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl2" )
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_core_lvl1" )
		EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/weapon_fire/alien_charging_full" ) 
        EffectService:DestroyEffect( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_hologram_core" )
    end

    EffectService:DestroyEffectsByBlueprint( self.entity, "player/" .. self:GetPlayerColor() .. "/effects/projectiles_and_trails/alien_bomb_arm_energy" )

    if ( self.chargeStage3 == true ) then 
        local chargeBomb = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_explosion_lvl3", self.entity, "att_muzzle_forward", "player" )
        EntityService:SetAmmoDef( chargeBomb, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_explosion_lvl3" )
        --local chargeAreaBomb = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_area_lvl3", self.entity, "att_muzzle_forward", "player" )
        --EntityService:SetAmmoDef( chargeAreaBomb, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_area_lvl3" )
    elseif ( self.chargeStage2 == true ) then 
        local chargeBomb = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_explosion_lvl2", self.entity, "att_muzzle_forward", "player" )
        EntityService:SetAmmoDef( chargeBomb, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_explosion_lvl2" )
        --local chargeAreaBomb = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_area_lvl2", self.entity, "att_muzzle_forward", "player" )
        --EntityService:SetAmmoDef( chargeAreaBomb, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_area_lvl2" )
    elseif( self.chargeStage1 == true ) then 
        local chargeBomb = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_explosion_lvl1", self.entity, "att_muzzle_forward", "player" )
        EntityService:SetAmmoDef( chargeBomb, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_explosion_lvl1" )
        --local chargeAreaBomb = EntityService:SpawnEntity( "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_area_lvl1", self.entity, "att_muzzle_forward", "player" )
        --EntityService:SetAmmoDef( chargeAreaBomb, self.entity, "player/" .. self:GetPlayerColor() .. "/projectiles/player_charged_bomb_area_lvl1" )
    else 
        status = false
    end

    EntityService:RemoveEntity( self.chargeStartEnt ) 
    self.chargeStartEnt = nil

    return status
end

function spaceship:GetEmpParams()
    if ( self.chargeStage1 == true  or self.chargeStage2 == true or self.chargeStage3 == true ) then
        local empParams =
        { 
            cooldown        = 7.0,
        } 
        return empParams
    else 
        local empParams =
        { 
            cooldown        = 0.0,
        } 
        return empParams
    end
end

function spaceship:GetTimeWarpParams()
    local timeWarpParams =
    { 
        desaturation    = 0.7,
        brightness      = 1.0,
        contrast        = 1.0,
        bloom_scale     = 1.0, 
        time_factor     = 0.33,
        fade_in_time    = 0.25, 
        fade_out_time   = 0.25,
        delay           = 0.0,
    } 
    return timeWarpParams
end

function spaceship:GetBombParams()
    if ( self.chargeStage1 == true  or self.chargeStage2 == true or self.chargeStage3 == true ) then
        local bombParams =
        { 
            cooldown        = 10.0,
        } 
        return bombParams
    else 
        local bombParams =
        { 
            cooldown        = 0.0,
        } 
        return bombParams
    end
end

function spaceship:NightModeOn()
	if NIGHT_MODE == true then
		EffectService:AttachEffects( self.entity, "night" )
	end
end

function spaceship:NightModeOff()
	if NIGHT_MODE == true then
		EffectService:DestroyEffectsByType( self.entity, "night" )
	end
end

return spaceship
