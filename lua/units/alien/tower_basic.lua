local tower_basic = {}
tower_basic.__index = tower_basic

function tower_basic.create()
	local object = {}
	setmetatable(object,tower_basic)
	return object
end

function tower_basic:init()
	MsgSystem:RegisterHandler( self.entity, "OnTargetAcquired" )
	MsgSystem:RegisterHandler( self.entity, "OnTargetLost" )
	MsgSystem:RegisterHandler( self.entity, "OnDamage" )
	MsgSystem:RegisterHandler( self.entity, "OnDestroy" )

    self.targetingCounter = 0

	--self.checkFlamer = EntityService:CreateSequence( self.entity )
    --self.checkFlamer:RegisterInterrupt( 0.25, "CheckFlamerSequence" )
	--self.checkFlamer:Start()

	self.isAttack = false
	self.isUpgrade = false
	self.isInDanger = false
end

function tower_basic:GetTowerBaseName()
    local blueprintName = EntityService:GetBlueprintName( self.entity );
		
	if blueprintName == "units/alien/tower_ground_basic" then 
		return "meshes/units/alien/tower_ground_basic"
	elseif blueprintName == "units/alien/tower_ground_flamer" then 
		return "meshes/units/alien/tower_ground_flamer"
	elseif blueprintName == "units/alien/tower_ground_shockwave" then 
		return "meshes/units/alien/tower_ground_shockwave"
	elseif blueprintName == "units/alien/tower_ground_laser" then 
		return "meshes/units/alien/tower_ground_laser"
	elseif blueprintName == "units/alien/tower_ground_artillery" then 
		return "meshes/units/alien/tower_ground_artillery"
	elseif blueprintName == "units/alien/tower_ground_flamer_artillery" then 
		return "meshes/units/alien/tower_ground_flamer_artillery"
	elseif blueprintName == "units/alien/tower_air_basic" then 
		return "meshes/units/alien/tower_air_basic"
	elseif blueprintName == "units/alien/tower_air_laser" then 
		return "meshes/units/alien/tower_air_laser"	
	elseif blueprintName == "units/alien/tower_ground_railgun" then 
		return "meshes/units/alien/tower_ground_railgun"	
	elseif blueprintName == "units/alien/tower_air_missile" then 
		return "meshes/units/alien/tower_air_missile"		
	else
		return "meshes/units/alien/tower_ground_basic" -- failsafe
	end
end

function tower_basic:StartAttack()
	if ( self.isUpgrade == false ) then
	    local blueprintName = EntityService:GetBlueprintName( self.entity );
		
		if blueprintName == "units/alien/tower_ground_flamer" then 
			AimService:StartAiming( self.entity, "tower_turret" )
			WeaponService:StartShootInRange( self.entity, "main_gun" )
		else
			AimService:StartAiming( self.entity, "tower_turret" )
			WeaponService:StartShootOnAim( self.entity, "main_gun" )
		end

		self.isAttack = true
	end
end

function tower_basic:StartIdle()
	local blueprintName = EntityService:GetBlueprintName( self.entity );
		
	if blueprintName == "units/alien/tower_air_basic" then 
		AnimationService:StartAnim( self.entity, "idle" )
	elseif blueprintName == "units/alien/tower_air_laser" then 
		AnimationService:StartAnim( self.entity, "idle" )
	elseif blueprintName == "units/alien/tower_air_missile" then 
		AnimationService:StartAnim( self.entity, "idle" )
	elseif blueprintName == "units/alien/tower_ground_shockwave" then 
		AnimationService:StartAnim( self.entity, "idle" )
	end
end

function tower_basic:StopAttack()
	if ( self.isUpgrade == false ) then
		AimService:StopAiming( self.entity, "tower_turret" )
	    WeaponService:StopShoot( self.entity, "main_gun" )
		self.isAttack = false
	end
end

function tower_basic:EnableFlamerAttack()
	if ( self.isUpgrade == false ) then
		AimService:StartAiming( self.entity, "tower_turret" )
		WeaponService:StartShootInRange( self.entity, "main_gun" )
	end
end

function tower_basic:DisableFlamerAttack()
	if ( self.isUpgrade == false ) then
		AimService:StopAiming( self.entity, "tower_turret" )
	    WeaponService:StopShoot( self.entity, "main_gun" )
	end
end

function tower_basic:OnTowerBoneReset()
	self:StopAttack()
	return 0.0
end

function tower_basic:NightModeOn()
	if NIGHT_MODE == true then
		EffectService:DestroyEffectsByType( self.entity, "night" )
		EffectService:AttachEffects( self.entity, "night" )
	end
end

function tower_basic:NightModeOff()
	if NIGHT_MODE == true then
		EffectService:DestroyEffectsByType( self.entity, "night" )
	end
end

function tower_basic:OnTowerCreateEnter()
	self:NightModeOn()
	EntityService:ChangeMesh( self.entity, self:GetTowerBaseName().."_morph.mesh" )
	EffectService:SpawnEffect( self.entity, "effects/vehicles/tower_build" )	
	AnimationService:StartAnim( self.entity, "from_zero", false )
	return AnimationService:GetAnimDuration( self.entity, "from_zero" )
end

function tower_basic:OnTowerCreateExit()
    EntityService:ChangeMesh( self.entity, self:GetTowerBaseName()..".mesh" )	
    self:StartAttack()
    self:StartIdle()	
    return 0.0
end

function tower_basic:OnTowerSellEnter()
	self:StopAttack()
	EntityService:ChangeMesh( self.entity, self:GetTowerBaseName().."_morph.mesh" )
	EffectService:SpawnEffect( self.entity, "effects/vehicles/tower_sell" )	
	AnimationService:StartAnim( self.entity, "to_zero", false )	
	return AnimationService:GetAnimDuration( self.entity, "to_zero" )
end

function tower_basic:OnTowerSellExit()
	EntityService:RemoveEntity( self.entity )
	return 0.0
end

function tower_basic:OnTowerMoveStartEnter( x, y, z )
	self:StopAttack()
	self:NightModeOff()
    EntityService:ChangeMesh( self.entity, self:GetTowerBaseName().."_morph.mesh" )
    AnimationService:StartAnim( self.entity, "to_zero", false )
    EffectService:SpawnEffect( self.entity, "effects/vehicles/tower_lift_off" )
    EntityService:SpawnEntity( "effects/vehicles/tower_landing", x, y, z, "neutral" )
    self.cubeEntity1 = EntityService:SpawnEntity( "units/alien/tower_cube_form", self.entity, "neutral" )
    AnimationService:StartAnim( self.cubeEntity1, "from_zero", false )
    self.cubeEntity2 = EntityService:SpawnEntity( "units/alien/tower_cube_form", x, y, z, "neutral" )
    AnimationService:StartAnim( self.cubeEntity2, "from_zero", false )
    return AnimationService:GetAnimDuration( self.entity, "to_zero" )
end

function tower_basic:OnTowerMoveStartExit(  x, y, z )
    return 0
end

function tower_basic:OnTowerMoveEndEnter( x, y, z )
    AnimationService:StartAnim( self.cubeEntity1, "to_zero", false )
    AnimationService:StartAnim( self.cubeEntity2, "to_zero", false )   
    AnimationService:StartAnim( self.entity, "from_zero", false )
    return AnimationService:GetAnimDuration( self.cubeEntity2, "from_zero" )
end

function tower_basic:OnTowerMoveEndMiddle( x, y, z )
    return 0
end

function tower_basic:OnTowerMoveEndExit( x, y, z )
    EntityService:ChangeMesh( self.entity, self:GetTowerBaseName()..".mesh" )
    self:StartAttack()
    self:StartIdle()
	self:NightModeOn()
    EntityService:RemoveEntity( self.cubeEntity1 ) 
    self.cubeEntity1 = nil
    EntityService:RemoveEntity( self.cubeEntity2 )
    self.cubeEntity2 = nil
    return 0
end

function tower_basic:OnTowerUpgradeStartEnter()
	self.isUpgrade = true
	self:StopAttack()
	self:NightModeOn()

	if ( EffectService:HasEffect( self.entity, "effects/misc/tower_in_danger" ) ) then
		self.isInDanger = true
	end

	EntityService:ChangeMesh( self.entity, self:GetTowerBaseName().."_morph.mesh" )
	EffectService:SpawnEffect( self.entity, "effects/vehicles/tower_upgrade" )
	AnimationService:StartAnim( self.entity, "to_zero", false, 2.0 )
	self.cubeEntity = EntityService:SpawnEntity( "units/alien/tower_cube_form", self.entity, "neutral" )
	AnimationService:StartAnim( self.cubeEntity, "from_zero", false, 2.0 )
	return AnimationService:GetAnimDuration( self.entity, "to_zero" ) / 2
end

function tower_basic:OnTowerUpgradeStartExit()
	AnimationService:StartAnim( self.cubeEntity, "to_zero", false )
	return 0.0
end

function tower_basic:OnTowerUpgradeEndEnter()
	EntityService:ChangeMesh( self.entity, self:GetTowerBaseName().."_morph.mesh" )
	AnimationService:StartAnim( self.entity, "from_zero", false )
	self:NightModeOn()
	return AnimationService:GetAnimDuration( self.entity, "from_zero" )
end

function tower_basic:OnTowerUpgradeEndExit()
    self.isUpgrade = false
    EntityService:ChangeMesh( self.entity, self:GetTowerBaseName()..".mesh" )
	EntityService:RemoveEntity( self.cubeEntity )
	self.cubeEntity = nil
    self:StartAttack()
    self:StartIdle()		
	
	if ( self.targetingCounter ~= 0 ) then	
		EffectService:AttachEffect( self.entity, "effects/misc/artillery_marker", "body" )	
		SoundService:Play("voice_over/generic/dialog_alien_alert_tower_is_under_attack")		
	end
	
	if ( self.isInDanger ) then
		self.isInDanger = false
		EffectService:AttachEffect( self.entity, "effects/misc/tower_in_danger", "body" )	
	end

	return 0.0
end

function tower_basic:CheckFlamerSequence( checkHealth )
	if ( self.isAttack ) then
		local blueprintName = EntityService:GetBlueprintName( self.entity );
		
		if blueprintName == "units/alien/tower_ground_flamer" then 
			self:EnableFlamerAttack()
		end
	end
end

function tower_basic:OnDamage( event )
	if ( ( self.targetingCounter > 0 ) and ( EffectService:HasEffect( self.entity, "effects/misc/artillery_marker" ) == false ) ) then
		EffectService:AttachEffect( self.entity, "effects/misc/artillery_marker", "body" )	
	end
end

function tower_basic:OnTargetAcquired( event )		
	--LogService:Log( "Turret Target Acquired marker enabled" )	
	
	if ( self.targetingCounter == 0 ) then	
		EffectService:AttachEffect( self.entity, "effects/misc/artillery_marker", "body" )	
		SoundService:Play("voice_over/generic/dialog_alien_alert_tower_is_under_attack")
	end
	
	self.targetingCounter = self.targetingCounter + 1
	
end

function tower_basic:OnTargetLost( event )		
	--LogService:Log( "Turret Target Acquired marker disabled" )
	self.targetingCounter = self.targetingCounter - 1
	
	if ( self.targetingCounter == 0 ) then	
		EffectService:DestroyEffect( self.entity, "effects/misc/artillery_marker", "body" )		
	end
	
	if ( self.targetingCounter < 0 ) then	
		LogService:Log( "ERROR - TARGETING COUNTER BELOW ZERO - THIS SHOULDN'T HAPPEN" )
	end
	
end

function tower_basic:OnDestroy( event )
	if string.find( EntityService:GetBlueprintName( self.entity ),"air") then
		LogService:Log("Tower air destroyed!")
		EntityService:SpawnEntity( "effects/misc/tower_air_destroyed", self.entity, "no_team")
	else	
		LogService:Log("Tower ground destroyed!")
		EntityService:SpawnEntity( "effects/misc/tower_ground_destroyed", self.entity, "no_team")
	end
	MissionService:RefundTower( self.entity )
	EntityService:DestroyEntity( self.entity )
	SoundService:Play("voice_over/generic/dialog_alien_alert_tower_destroyed")
end

return tower_basic
