local core = {}
core.__index = core

function core.create()
	local object = {}
	setmetatable(object,core)
	return object
end

function Iter(table)
    local index = 0
    local count = #table

    return function()
        index = index + 1

        if index <= count then
            return table[index]
        end

    end
end

function core:init()	
	MsgSystem:RegisterHandler( self.entity, "OnDamage" )	
	MsgSystem:RegisterHandler( self.entity, "OnDestroy" )	
	MsgSystem:RegisterHandler( self.entity, "OnDestructionLevelChanged" )
	MsgSystem:RegisterHandler( self.entity, "OnMissionSuccess" )
	MsgSystem:RegisterHandler( self.entity, "OnCoreShockWaveActivate" )
	MsgSystem:RegisterHandler( self.entity, "OnCoreWeaponActivate" )

	self.fsm = EntityService:CreateStateMachine( self.entity )
	self.fsm:AddState( "default", { from="*", enter="OnEnterDefault" } )
	self.fsm:AddState( "startup", { from="*", enter="OnEnterStartup" } )
	self.fsm:AddState( "alert", { from="*", enter="OnEnterAlert", exit="OnExitAlert" } )
	self.fsm:AddState( "open", { from="*", enter="OnEnterOpen", exit="OnExitOpen" } )
	self.fsm:ChangeState( "startup" )	
	
	self.coreWeaponActive    = MissionService:IsCoreWeaponActive()
	self.coreShockWaveActive = MissionService:IsCoreShockWaveDamageActive()
	
	if EntityService:GetData( self.entity ):HasString( "coreShockWaveActive" ) then
		self.coreShockWaveActive = EntityService:GetData( self.entity ):GetString( "coreShockWaveActive" )		
	end
	
	if ( self.coreWeaponActive ) then
		AimService:StartAiming( self.entity, "main_turret" )
		WeaponService:StartShootOnAim( self.entity, "main_gun" )
	end
	
	MissionService:CreateInfluence( self.entity )
	EntityService:CreateAnimationListener( self.entity, "OnAnimationEnded" )
end

function core:OnAnimationEnded( anim ) 
	if anim == "fly_to_base" and self.fsm:GetCurrentState() == "open" then
		self.fsm:ChangeState( "startup" )
	end
end

function core:OnEnterStartup( state )	
	if EntityService:GetData( self.entity ):HasString( "coreInitialized" ) == false then		
		--EffectService:AttachEffect( self.entity, "effects/vehicles/core_shield", "att_energy" )	
		EffectService:AttachEffect( self.entity, "effects/vehicles/light_pillar", "att_light_pillar" )
		--EffectService:AttachEffect( self.entity, "lights/point/blue_core", "att_ball" )	
		--EffectService:AttachEffect( self.entity, "lights/point/orange_core", "48" )	
		EffectService:AttachEffect( self.entity, "lights/point/blue_core", "att_rotating_pillar" )		
		--EffectService:AttachEffect( self.entity, "effects/vehicles/light_orange", "48" )	
		--EffectService:AttachEffect( self.entity, "effects/vehicles/light_red", "att_rotating_pillar_2" )		
		EffectService:AttachEffect( self.entity, "lights/point/blue_core", "att_rotating_pillar_2" )	
		self:NightModeOn()			
	
	end	
	AnimationService:StartAnim( self.entity, "idle", true )

	self.fsm:ChangeState( "default" )
end

function core:OnEnterDefault( state )	
	EntityService:GetData( self.entity ):SetString( "coreInitialized", "true" )
end

function core:OnEnterOpen( state )	
	--LogService:Log("OnEnterOpen")
	AnimationService:StartAnim( self.entity, "fly_to_base", false )
end

function core:OnExitOpen( state )	
	--LogService:Log("OnExitOpen")	
	MsgSystem:SendGlobalMsg( "OnOpenCoreFinished" )	
end

function core:OnEnterAlert( state )
	--self.alert = 1
	state:SetDurationLimit( 4 )
	EffectService:AttachEffect( self.entity, "effects/misc/core_marker" )
	--if FindService:FindEntityByTypeInDistance( self.entity, "spaceship", 75 ) == INVALID_ID then
	SoundService:Play("voice_over/generic/dialog_alien_alert_core_is_under_attack")
--	end	
end

function core:OnExitAlert( state )
	EffectService:DestroyEffect( self.entity, "effects/misc/core_marker" )	
	self.fsm:ChangeState( "default" )
end

function core:OnDamage( event )	
	if event:GetDamageValue() > 0 then
		if self.fsm:GetCurrentState() == "default" then
			if ( CameraService:HasEntityInFrustum( self.entity ) == false )then
				self.fsm:ChangeState( "alert" )
				return
			end
		end
	end
end

function core:OnDestructionLevelChanged( event )	
	--LogService:Log("OnDestructionLevelChanged")
	if event:GetDestructionLevelName() == "75" then		
		local soundDuration = SoundService:GetSoundDuration( "voice_over/generic/dialog_alien_alert_core_health_75" )	
		GuiService:ShowDialog( "dialog_alien_core", "DIALOG/generic/dialog_alien_alert_core_health_75","voice_over/generic/dialog_alien_alert_core_health_75", 0, soundDuration, false, false, false, 0 )		
		if ( self.coreShockWaveActive) then
			EffectService:AttachEffects(self.entity, "core_emergency_shockwave")
		end
	elseif event:GetDestructionLevelName() == "50" then		
		local soundDuration = SoundService:GetSoundDuration( "voice_over/generic/dialog_alien_alert_core_health_50" )	
		GuiService:ShowDialog( "dialog_alien_core", "DIALOG/generic/dialog_alien_alert_core_health_50","voice_over/generic/dialog_alien_alert_core_health_50", 0, soundDuration, false, false, false, 0 )		
		if ( self.coreShockWaveActive) then
			EffectService:AttachEffects(self.entity, "core_emergency_shockwave")
		end
	elseif event:GetDestructionLevelName() == "25" then		
		local soundDuration = SoundService:GetSoundDuration( "voice_over/generic/dialog_alien_alert_core_health_25" )	
		GuiService:ShowDialog( "dialog_alien_core", "DIALOG/generic/dialog_alien_alert_core_health_25","voice_over/generic/dialog_alien_alert_core_health_25", 0, soundDuration, false, false, false, 0 )		
		if ( self.coreShockWaveActive) then
			EffectService:AttachEffects(self.entity, "core_emergency_shockwave")
		end
	end		
end

function core:OnDestroy( event )		 		
	EntityService:ChangeType( self.entity, "" )	
	if ( self.coreWeaponActive ) then
		AimService:StopAiming( self.entity, "main_turret" )
		WeaponService:StopShoot( self.entity, "main_gun" )
	end
	local children = EntityService:GetChildren(self.entity, true)
	for child in Iter(children) do
		EntityService:RemoveEntity(child)
	end
	AnimationService:StopAnim( self.entity, "idle" )
end

function core:OnCoreShockWaveActivate( event )	
	LogService:Log("CoreShochWaveActivated")
	EntityService:GetData( self.entity ):SetString( "coreShockWaveActive", "true" )
	self.coreShockWaveActive = true
end

function core:OnCoreWeaponActivate( event )	
	LogService:Log("CoreWeaponActivate")

	self.coreWeaponActive = true

	if ( self.coreWeaponActive ) then
		AimService:StartAiming( self.entity, "main_turret" )
		WeaponService:StartShootOnAim( self.entity, "main_gun" )
	end
end

function core:OnMissionSuccess()
	--MissionService:UpgradeInfluence( self.entity, 30, 20, 5, 0.1 )
end

function core:NightModeOn()
	if NIGHT_MODE == true then
		EffectService:AttachEffects( self.entity, "night" )
	end
end

function core:NightModeOff()
	if NIGHT_MODE == true then
		EffectService:DestroyEffectsByType( self.entity, "night" )
	end
end

return core
