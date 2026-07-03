ColorScheme = GlobalState.UIColors or {}
local timecycleModifier = "default"
local lodDistance = nil
local lightsCutOff = 1.0
local shadowsCutOff = 1.0
local presetFps = "default"

-- Crosshair state
local crosshairEnabled = false
local crosshairSettings = nil

local function ifThen(condition, ifTrue, ifFalse)
    if condition then
        return ifTrue
    end
    return ifFalse
end

local function setPlayerTimecycleModifier(args)
    if args.cycle == "default" then
        ClearTimecycleModifier()
        ClearExtraTimecycleModifier()
    else
        SetTimecycleModifier(args.cycle)
        if args.extra then
            SetExtraTimecycleModifier(args.extra)
        end
    end
    SetResourceKvp("mri_Qfps:TimecycleModifier", args.cycle)
    timecycleModifier = args.cycle
    if args and args.callback then
        args.callback()
    end
end

local function Optimize(status)
	local ped = PlayerPedId()
	if (status) then
		ClearBrief()
		ClearFocus()
		ClearPrints()
		ClearHdArea()
		ClearGpsFlags()
		SetRainLevel(0.0)
		SetWindSpeed(0.0)
		ClearSmallPrints()
		ClearReplayStats()
		ClearPedWetness(ped)
		ClearPedEnvDirt(ped)
		ClearAllBrokenGlass()
		ClearOverrideWeather()
		ClearAllHelpMessages()
		DisableScreenblurFade()
		ClearPedBloodDamage(ped)
		ResetPedVisibleDamage(ped)
		LeaderboardsReadClearAll()
		LeaderboardsClearCacheData()
		DisplayRadar(false)
		RopeDrawShadowEnabled(false)
		CascadeShadowsClearShadowSampleType()
		CascadeShadowsSetAircraftMode(false)
		CascadeShadowsEnableEntityTracker(true)
		CascadeShadowsSetDynamicDepthMode(false)
		CascadeShadowsInitSession()
		CascadeShadowsSetEntityTrackerScale(0.0)
		CascadeShadowsSetDynamicDepthValue(0.0)
		CascadeShadowsSetCascadeBoundsScale(0.0)
		SetFlashLightFadeDistance(50.0)
		SetLightsCutoffDistanceTweak(50.0)
		DisableVehicleDistantlights(true)
		DistantCopCarSirens(false)
		SetPedAoBlobRendering(ped, false)
	else
		RopeDrawShadowEnabled(true)
		CascadeShadowsClearShadowSampleType()
		CascadeShadowsSetAircraftMode(true)
		CascadeShadowsEnableEntityTracker(false)
		CascadeShadowsSetDynamicDepthMode(true)
		CascadeShadowsInitSession()
		CascadeShadowsSetEntityTrackerScale(0.0)
		CascadeShadowsSetDynamicDepthValue(0.0)
		CascadeShadowsSetCascadeBoundsScale(0.0)
		SetFlashLightFadeDistance(0.0)
		SetLightsCutoffDistanceTweak(0.0)
		DisableVehicleDistantlights(false)
		DistantCopCarSirens(false)
		SetPedAoBlobRendering(ped, true)
        DisplayRadar(true)
	end
end

local function setPresetFps(preset)
    if preset then
        presetFps = preset
        SetResourceKvp("mri_Qfps:PresetFps", presetFps)

        if preset == "ulow" then
            Optimize(true)
            TriggerEvent("Notify", "sucesso", "Sistema de Limpeza e Otimização ativado.", 5000)
        else
            Optimize(false)
        end
    end
end

-- ═══ Crosshair System ═══

local function applyCrosshairUI(settings)
    if not settings or not settings.enabled then
        crosshairEnabled = false
        return
    end

    crosshairEnabled = true
    crosshairSettings = settings

    SendNUIMessage({
        action = 'updateCrosshairStyle',
        data = settings
    })
end

-- Efficient aiming detection loop (0.00ms idle, optimized fade-out)
Citizen.CreateThread(function()
    local isAiming = false
    local unarmedHash = GetHashKey("WEAPON_UNARMED")
    local playerId = PlayerId()
    local keepHidingTimer = 0

    while true do
        local sleep = 500
        
        if crosshairEnabled then
            local ped = cache.ped or PlayerPedId()

            if GetSelectedPedWeapon(ped) ~= unarmedHash then
                -- Armed, check if aiming or hip-firing
                local isCombatActive = IsPlayerFreeAiming(playerId) or IsControlPressed(0, 25) or IsPedShooting(ped)

                if isCombatActive then 
                    sleep = 0 
                    keepHidingTimer = GetGameTimer() + 500 -- Extend 0ms loop for 500ms after leaving combat
                    HideHudComponentThisFrame(14) -- Hide native crosshair

                    if not isAiming then
                        isAiming = true
                        SendNUIMessage({ action = "showCrosshair" })
                    end
                elseif GetGameTimer() < keepHidingTimer then
                    -- Player just stopped aiming (quick-scope transition)
                    -- Keep loop at 0 and hide native so it doesn't flash during the weapon lowering animation
                    sleep = 0
                    HideHudComponentThisFrame(14)
                    
                    if isAiming then
                        isAiming = false
                        SendNUIMessage({ action = "hideCrosshair" })
                    end
                else
                    -- Relaxed state while carrying weapon
                    sleep = 50 
                    
                    if isAiming then
                        isAiming = false
                        SendNUIMessage({ action = "hideCrosshair" })
                    end
                end
            else
                if isAiming then
                    isAiming = false
                    SendNUIMessage({ action = "hideCrosshair" })
                end
            end
        else
            if isAiming then
                isAiming = false
                SendNUIMessage({ action = "hideCrosshair" })
            end
        end

        Citizen.Wait(sleep)
    end
end)

local function saveCrosshairKvp(settings)
    if not settings then return end
    SetResourceKvp("mri_Qfps:CrosshairEnabled", tostring(settings.enabled))
    SetResourceKvp("mri_Qfps:CrosshairSize", tostring(settings.size or 5))
    SetResourceKvp("mri_Qfps:CrosshairThickness", tostring(settings.thickness or 1))
    SetResourceKvp("mri_Qfps:CrosshairGap", tostring(settings.gap or 0))
    SetResourceKvp("mri_Qfps:CrosshairDot", tostring(settings.dot and 1 or 0))
    SetResourceKvp("mri_Qfps:CrosshairColorR", tostring(settings.color_r or 50))
    SetResourceKvp("mri_Qfps:CrosshairColorG", tostring(settings.color_g or 250))
    SetResourceKvp("mri_Qfps:CrosshairColorB", tostring(settings.color_b or 50))
    SetResourceKvp("mri_Qfps:CrosshairAlpha", tostring(settings.alpha or 200))
    SetResourceKvp("mri_Qfps:CrosshairOutline", tostring(settings.outline and 1 or 0))
    SetResourceKvp("mri_Qfps:CrosshairOutlineThickness", tostring(settings.outlineThickness or 1))
    SetResourceKvp("mri_Qfps:CrosshairStyle", tostring(settings.style or 4))
end

local function loadCrosshairKvp()
    local enabled = GetResourceKvpString("mri_Qfps:CrosshairEnabled")
    if enabled == nil then
        return nil
    end

    return {
        enabled = enabled == "true",
        size = tonumber(GetResourceKvpString("mri_Qfps:CrosshairSize")) or 5,
        thickness = tonumber(GetResourceKvpString("mri_Qfps:CrosshairThickness")) or 1,
        gap = tonumber(GetResourceKvpString("mri_Qfps:CrosshairGap")) or 0,
        dot = GetResourceKvpString("mri_Qfps:CrosshairDot") == "1",
        color_r = tonumber(GetResourceKvpString("mri_Qfps:CrosshairColorR")) or 50,
        color_g = tonumber(GetResourceKvpString("mri_Qfps:CrosshairColorG")) or 250,
        color_b = tonumber(GetResourceKvpString("mri_Qfps:CrosshairColorB")) or 50,
        alpha = tonumber(GetResourceKvpString("mri_Qfps:CrosshairAlpha")) or 200,
        outline = GetResourceKvpString("mri_Qfps:CrosshairOutline") == "1",
        outlineThickness = tonumber(GetResourceKvpString("mri_Qfps:CrosshairOutlineThickness")) or 1,
        style = tonumber(GetResourceKvpString("mri_Qfps:CrosshairStyle")) or 4,
    }
end

local function clearCrosshairKvp()
    DeleteResourceKvp("mri_Qfps:CrosshairEnabled")
    DeleteResourceKvp("mri_Qfps:CrosshairSize")
    DeleteResourceKvp("mri_Qfps:CrosshairThickness")
    DeleteResourceKvp("mri_Qfps:CrosshairGap")
    DeleteResourceKvp("mri_Qfps:CrosshairDot")
    DeleteResourceKvp("mri_Qfps:CrosshairColorR")
    DeleteResourceKvp("mri_Qfps:CrosshairColorG")
    DeleteResourceKvp("mri_Qfps:CrosshairColorB")
    DeleteResourceKvp("mri_Qfps:CrosshairAlpha")
    DeleteResourceKvp("mri_Qfps:CrosshairOutline")
    DeleteResourceKvp("mri_Qfps:CrosshairOutlineThickness")
    DeleteResourceKvp("mri_Qfps:CrosshairStyle")
end

-- ═══ Menu ═══

local function mriFpsMenu()
    -- Load current crosshair settings for UI
    local chSettings = loadCrosshairKvp() or {
        enabled = false,
        size = 5, thickness = 1, gap = 0, dot = false,
        color_r = 50, color_g = 250, color_b = 50,
        alpha = 200, outline = false, outlineThickness = 1, style = 4
    }

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVisible',
        data = true
    })
    SendNUIMessage({
        action = 'initState',
        data = {
            preset = presetFps,
            lodDistance = lodDistance,
            lightsCutoff = lightsCutOff,
            shadowsCutoff = shadowsCutOff,
            timecycle = timecycleModifier,
            crosshair = chSettings,
        }
    })
end

local function startFpsBoost()
    CreateThread(function()
        local lastLightVal = nil
        local lastPresetFps = nil
        local lastShadowsCutOff = nil

        while true do
            if lodDistance ~= nil then
                OverrideLodscaleThisFrame(lodDistance)
            end

            if presetFps ~= lastPresetFps or lightsCutOff ~= lastLightVal or shadowsCutOff ~= lastShadowsCutOff then
                lastPresetFps = presetFps
                lastLightVal = lightsCutOff
                lastShadowsCutOff = shadowsCutOff

                if presetFps == "default" then

                    -- Slider < 1.0 culls distant light sources for fps. Never below 50m:
                    -- headlights sit ~10m from the 3rd person camera and blink when the
                    -- cutoff boundary crosses them. 1.0+ or no saved value = game default
                    -- (0.0 disables the tweak).
                    if lightsCutOff ~= nil and lightsCutOff < 1.0 then
                        local cutoff = 50.0 + (lightsCutOff * 200.0)
                        SetLightsCutoffDistanceTweak(cutoff)
                        SetFlashLightFadeDistance(cutoff)
                        DisableVehicleDistantlights(true)
                    else
                        SetLightsCutoffDistanceTweak(0.0)
                        SetFlashLightFadeDistance(0.0)
                        DisableVehicleDistantlights(false)
                    end

                    if shadowsCutOff ~= nil then
                        if shadowsCutOff > 0 then
                            RopeDrawShadowEnabled(true)
                            CascadeShadowsClearShadowSampleType()
                            CascadeShadowsSetAircraftMode(true)
                            CascadeShadowsEnableEntityTracker(true)
                            CascadeShadowsSetDynamicDepthMode(true)
                            CascadeShadowsInitSession()
                            SetPedAoBlobRendering(cache.ped, true)
                            CascadeShadowsSetEntityTrackerScale(shadowsCutOff)
                            CascadeShadowsSetDynamicDepthValue(shadowsCutOff)
                            CascadeShadowsSetCascadeBoundsScale(shadowsCutOff)
                        else
                            RopeDrawShadowEnabled(false)
                            CascadeShadowsSetAircraftMode(false)
                            CascadeShadowsEnableEntityTracker(false)
                            CascadeShadowsSetDynamicDepthMode(false)
                            SetPedAoBlobRendering(cache.ped, false)
                            CascadeShadowsSetEntityTrackerScale(shadowsCutOff)
                            CascadeShadowsSetDynamicDepthValue(shadowsCutOff)
                            CascadeShadowsSetCascadeBoundsScale(shadowsCutOff)
                        end
                    else
                        RopeDrawShadowEnabled(true)

                        CascadeShadowsSetAircraftMode(true)
                        CascadeShadowsEnableEntityTracker(false)
                        CascadeShadowsSetDynamicDepthMode(true)
                        CascadeShadowsSetEntityTrackerScale(5.0)
                        CascadeShadowsSetDynamicDepthValue(5.0)
                        CascadeShadowsSetCascadeBoundsScale(5.0)
                    end
                elseif presetFps == "ulow" then
                    RopeDrawShadowEnabled(false)

                    CascadeShadowsClearShadowSampleType()
                    CascadeShadowsSetAircraftMode(false)
                    CascadeShadowsEnableEntityTracker(true)
                    CascadeShadowsSetDynamicDepthMode(false)
                    CascadeShadowsSetEntityTrackerScale(0.0)
                    CascadeShadowsSetDynamicDepthValue(0.0)
                    CascadeShadowsSetCascadeBoundsScale(0.0)

                    SetFlashLightFadeDistance(50.0)
                    SetLightsCutoffDistanceTweak(50.0)
                    DisableVehicleDistantlights(true)
                elseif presetFps == "low" then
                    RopeDrawShadowEnabled(false)

                    CascadeShadowsClearShadowSampleType()
                    CascadeShadowsSetAircraftMode(false)
                    CascadeShadowsEnableEntityTracker(true)
                    CascadeShadowsSetDynamicDepthMode(false)
                    CascadeShadowsSetEntityTrackerScale(0.0)
                    CascadeShadowsSetDynamicDepthValue(0.0)
                    CascadeShadowsSetCascadeBoundsScale(0.0)

                    SetFlashLightFadeDistance(100.0)
                    SetLightsCutoffDistanceTweak(100.0)
                    DisableVehicleDistantlights(true)
                elseif presetFps == "medium" then
                    RopeDrawShadowEnabled(true)

                    CascadeShadowsClearShadowSampleType()
                    CascadeShadowsSetAircraftMode(false)
                    CascadeShadowsEnableEntityTracker(true)
                    CascadeShadowsSetDynamicDepthMode(false)
                    CascadeShadowsSetEntityTrackerScale(5.0)
                    CascadeShadowsSetDynamicDepthValue(3.0)
                    CascadeShadowsSetCascadeBoundsScale(3.0)

                    SetFlashLightFadeDistance(150.0)
                    SetLightsCutoffDistanceTweak(150.0)
                    DisableVehicleDistantlights(false)
                end
            end

            if lodDistance ~= nil then
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end

local hasInit = false

local function init()
    if hasInit then return end
    hasInit = true

    timecycleModifier = GetResourceKvpString("mri_Qfps:TimecycleModifier") or "default"
    if Config.LoadingDistanceEnabled then
        lodDistance = tonumber(GetResourceKvpString("mri_Qfps:LodDistance")) or nil
    end
    lightsCutOff = tonumber(GetResourceKvpString("mri_Qfps:LightsCutoff")) or nil
    shadowsCutOff = tonumber(GetResourceKvpString("mri_Qfps:ShadowsCutoff")) or 1.0
    presetFps = GetResourceKvpString("mri_Qfps:PresetFps") or "default"
    setPlayerTimecycleModifier({cycle = timecycleModifier})
    
    if presetFps == "ulow" then
        Optimize(true)
    end

    -- Load and apply saved crosshair
    local savedCrosshair = loadCrosshairKvp()
    if savedCrosshair then
        applyCrosshairUI(savedCrosshair)
    end

    startFpsBoost()
end

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    init()
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        init()
    end
end)

-- ═══ F9 Menu Injector (mri_Qbox) ═══

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if GetResourceState("mri_Qbox") == "started" then
            exports["mri_Qbox"]:RemovePlayerMenu(locale("menu.mriFpsTitle"))
        end
    end
end)

if GetResourceState("mri_Qbox") == "started" then
    exports["mri_Qbox"]:AddPlayerMenu({
        title = locale("menu.mriFpsTitle"),
        description = locale("menu.mriFpsDescription"),
        icon = "tools",
        iconAnimation = "fade",
        arrow = true,
        onSelectFunction = mriFpsMenu
    })
end

-- Fallback: direct event trigger
RegisterNetEvent("mri_Qfps:openFpsMenu", function()
    mriFpsMenu()
end)

-- ═══ NUI Callbacks ═══

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("setPresetFps", function(data, cb)
    setPresetFps(data.preset)
    cb("ok")
end)

RegisterNUICallback("setSliders", function(data, cb)
    if data.lodDistance ~= nil then
        lodDistance = tonumber(data.lodDistance)
        SetResourceKvp("mri_Qfps:LodDistance", tostring(lodDistance))
    end
    if data.lightsCutoff ~= nil then
        lightsCutOff = tonumber(data.lightsCutoff)
        SetResourceKvp("mri_Qfps:LightsCutoff", tostring(lightsCutOff))
    end
    if data.shadowsCutoff ~= nil then
        shadowsCutOff = tonumber(data.shadowsCutoff)
        SetResourceKvp("mri_Qfps:ShadowsCutoff", tostring(shadowsCutOff))
    end
    cb("ok")
end)

RegisterNUICallback("setTimecycle", function(data, cb)
    setPlayerTimecycleModifier({cycle = data.cycle, extra = data.extra})
    cb("ok")
end)

RegisterNUICallback("setCrosshair", function(data, cb)
    applyCrosshairUI(data)
    saveCrosshairKvp(data)
    cb("ok")
end)

RegisterNUICallback("resetCrosshair", function(data, cb)
    crosshairEnabled = false
    crosshairSettings = nil
    clearCrosshairKvp()
    SendNUIMessage({ action = "hideCrosshair" })
    cb("ok")
end)