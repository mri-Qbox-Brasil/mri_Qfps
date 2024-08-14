ColorScheme = GlobalState.UIColors or {}
local timecycleModifier = "default"
local lodDistance = nil
local lightsCutOff = 1.0
local shadowsCutOff = 1.0
local presetFps = "default"

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

local function setDistance(args)
    local input = lib.inputDialog(locale("menu.distanceTitle"), {
        {
            type = "slider",
            min = 0.01,
            max = 50.0,
            step = 0.1,
            default = lodDistance or 1.0
        }, {
            type = "checkbox",
            label = locale("menu.reset"),
        }
    })
    if input then
        if input[2] then
            lodDistance = nil
            DeleteResourceKvp("mri_Qfps:LodDistance")
        else
            lodDistance = tonumber(input[1])
            SetResourceKvp("mri_Qfps:LodDistance", lodDistance)
        end
    end
    if args and args.callback then
        args.callback()
    end
end

local function setLights(args)
    local input = lib.inputDialog(locale("menu.lightsTitle"), {
        {
            type = "slider",
            min = 0.01,
            max = 50.0,
            step = 0.1,
            default = lightsCutOff or 1.0
        }, {
            type = "checkbox",
            label = locale("menu.reset"),
        }
    })
    if input then
        if input[2] then
            lightsCutOff = 1.0
            DeleteResourceKvp("mri_Qfps:LightsCutOff")
        else
            lightsCutOff = tonumber(input[1])
            SetResourceKvp("mri_Qfps:LightsCutOff", lightsCutOff)
        end
    end
    if args and args.callback then
        args.callback()
    end
end

local function setShadows(args)
    local input = lib.inputDialog(locale("menu.shadowsTitle"), {
        {
            type = "slider",
            min = 0.01,
            max = 1.0,
            step = 0.1,
            default = shadowsCutOff or 1.0
        }, {
            type = "checkbox",
            label = locale("menu.reset"),
        }
    })
    if input then
        if input[2] then
            shadowsCutOff = 1.0
            DeleteResourceKvp("mri_Qfps:ShadowsCutOff")
        else
            shadowsCutOff = tonumber(input[1])
            SetResourceKvp("mri_Qfps:ShadowsCutOff", shadowsCutOff)
        end
    end
    if args and args.callback then
        args.callback()
    end
end

local function setPresetFps(args)
    if args and args.preset then
        presetFps = args.preset
        SetResourceKvp("mri_Qfps:PresetFps", presetFps)
    end

    if args and args.callback then
        args.callback()
    end
end

local function menuObj(title, modifier, extra, callback)
    return {
        title = locale(title),
        description = locale("menu.timecycleModifierDescription",
            ifThen(timecycleModifier == modifier, "Ativo", "Inativo")),
        icon = ifThen(timecycleModifier == modifier, "toggle-on", "toggle-off"),
        iconAnimation = Config.IconAnimation,
        iconColor = ifThen(timecycleModifier == modifier, ColorScheme.success, ColorScheme.danger),
        onSelect = setPlayerTimecycleModifier,
        args = {
            cycle = modifier,
            extra = extra,
            callback = callback
        }
    }
end

local function gfxMenu()
    local ctx = {
        id = "menu_gfx",
        menu = "menu_mrifps",
        title = locale("menu.gfxTitle"),
        description = locale("menu.gfxDescription"),
        options = {
            menuObj("menu.timecycleDefault", "default", nil, gfxMenu),
            menuObj("menu.timecycleCinema", "cinema", nil, gfxMenu),
            menuObj("menu.timecycleYell", "yell_tunnel_nodirect", nil, gfxMenu),
            menuObj("menu.timecycleTunnel", "tunnel", nil, gfxMenu),
            menuObj("menu.timecyclePower", "MP_Powerplay_blend", "reflection_correct_ambient", gfxMenu),
        }
    }

    lib.registerContext(ctx)
    lib.showContext(ctx.id)
end

local function presetMenu()
    local ctx = {
        id = "menu_preset",
        menu = "menu_fps",
        title = locale("menu.presetTitle"),
        description = locale("menu.presetDescription"),
        options = {{
            title = locale("menu.reset"),
            description = locale("menu.resetDescription"),
            icon = ifThen(presetFps == "default", "toggle-on", "toggle-off"),
            iconColor = ifThen(presetFps == "default", ColorScheme.success, ColorScheme.danger),
            iconAnimation = Config.IconAnimation,
            onSelect = setPresetFps,
            args = {
                preset = "default",
                callback = presetMenu
            }
        }, {
            title = locale("menu.presetULow"),
            description = locale("menu.presetULowDescription"),
            icon = ifThen(presetFps == "ulow", "toggle-on", "toggle-off"),
            iconColor = ifThen(presetFps == "ulow", ColorScheme.success, ColorScheme.danger),
            iconAnimation = Config.IconAnimation,
            onSelect = setPresetFps,
            args = {
                preset = "ulow",
                callback = presetMenu
            }
        }, {
            title = locale("menu.presetLow"),
            description = locale("menu.presetLowDescription"),
            icon = ifThen(presetFps == "low", "toggle-on", "toggle-off"),
            iconColor = ifThen(presetFps == "low", ColorScheme.success, ColorScheme.danger),
            iconAnimation = Config.IconAnimation,
            onSelect = setPresetFps,
            args = {
                preset = "low",
                callback = presetMenu
            }
        }, {
            title = locale("menu.presetMedium"),
            description = locale("menu.presetMediumDescription"),
            icon = ifThen(presetFps == "medium", "toggle-on", "toggle-off"),
            iconColor = ifThen(presetFps == "medium", ColorScheme.success, ColorScheme.danger),
            iconAnimation = Config.IconAnimation,
            onSelect = setPresetFps,
            args = {
                preset = "medium",
                callback = presetMenu
            }
        }}
    }

    lib.registerContext(ctx)
    lib.showContext(ctx.id)
end

local function fpsMenu()
    local ctx = {
        id = "menu_fps",
        menu = "menu_mrifps",
        title = locale("menu.fpsTitle"),
        description = locale("menu.fpsDescription"),
        options = {{
            title = locale("menu.distanceTitle"),
            description = locale("menu.distanceDescription"),
            icon = "people-arrows",
            iconAnimation = Config.IconAnimation,
            onSelect = setDistance,
            args = {
                callback = fpsMenu
            }
        }, {
            title = locale("menu.lightsTitle"),
            description = locale("menu.lightsDescription"),
            icon = "lightbulb",
            iconAnimation = Config.IconAnimation,
            onSelect = setLights,
            args = {
                callback = fpsMenu
            }
        }, {
            title = locale("menu.shadowsTitle"),
            description = locale("menu.shadowsDescription"),
            icon = "sun",
            iconAnimation = Config.IconAnimation,
            onSelect = setShadows,
            args = {
                callback = fpsMenu
            }
        }, {
            title = locale("menu.presetTitle"),
            description = locale("menu.presetDescription"),
            icon = "list-check",
            iconAnimation = Config.IconAnimation,
            onSelect = presetMenu,
        }}
    }

    lib.registerContext(ctx)
    lib.showContext(ctx.id)
end

local function mriFpsMenu()
    local ctx = {
        id = "menu_mrifps",
        menu = "menu_jogador",
        title = locale("menu.mriFpsTitle"),
        description = locale("menu.mriFpsDescription"),
        options = {{
            title = locale("menu.gfxTitle"),
            description = locale("menu.gfxDescription"),
            icon = "clapperboard",
            iconAnimation = Config.IconAnimation,
            arrow = true,
            onSelect = gfxMenu,
        },{
            title = locale("menu.fpsTitle"),
            description = locale("menu.fpsDescription"),
            icon = "gauge-simple-high",
            iconAnimation = Config.IconAnimation,
            arrow = true,
            onSelect = fpsMenu,
        }}
    }

    lib.registerContext(ctx)
    lib.showContext(ctx.id)
end

local function startFpsBoost()
    CreateThread(function()
        local lastLightVal = lightsCutOff
        if lightsCutOff ~= nil then
            DisableVehicleDistantlights(lightsCutOff <= 1.0)
        end
        while true do
            if lodDistance ~= nil then
                OverrideLodscaleThisFrame(lodDistance)
            end

            if presetFps == "default" then
                SetArtificialLightsState(false)

                if lightsCutOff ~= nil then
                    SetLightsCutoffDistanceTweak(lightsCutOff)
                    SetFlashLightFadeDistance(lightsCutOff)
                else
                    SetFlashLightFadeDistance(10.0)
                    SetLightsCutoffDistanceTweak(10.0)
                end

                if lastLightVal ~= lightsCutOff then
                    lastLightVal = lightsCutOff
                    DisableVehicleDistantlights(lightsCutOff <= 1.0)
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

                SetFlashLightFadeDistance(0.0)
                SetLightsCutoffDistanceTweak(0.0)
            elseif presetFps == "low" then
                RopeDrawShadowEnabled(false)

                CascadeShadowsClearShadowSampleType()
                CascadeShadowsSetAircraftMode(false)
                CascadeShadowsEnableEntityTracker(true)
                CascadeShadowsSetDynamicDepthMode(false)
                CascadeShadowsSetEntityTrackerScale(0.0)
                CascadeShadowsSetDynamicDepthValue(0.0)
                CascadeShadowsSetCascadeBoundsScale(0.0)

                SetFlashLightFadeDistance(5.0)
                SetLightsCutoffDistanceTweak(5.0)
            elseif presetFps == "medium" then
                RopeDrawShadowEnabled(true)

                CascadeShadowsClearShadowSampleType()
                CascadeShadowsSetAircraftMode(false)
                CascadeShadowsEnableEntityTracker(true)
                CascadeShadowsSetDynamicDepthMode(false)
                CascadeShadowsSetEntityTrackerScale(5.0)
                CascadeShadowsSetDynamicDepthValue(3.0)
                CascadeShadowsSetCascadeBoundsScale(3.0)

                SetFlashLightFadeDistance(3.0)
                SetLightsCutoffDistanceTweak(3.0)
                SetArtificialLightsState(false)
            end
            Wait(0)
        end
    end)
end

local function init()
    timecycleModifier = GetResourceKvpString("mri_Qfps:TimecycleModifier") or "default"
    lodDistance = tonumber(GetResourceKvpString("mri_Qfps:LodDistance")) or nil
    lightsCutOff = tonumber(GetResourceKvpString("mri_Qfps:LightsCutoff")) or nil
    shadowsCutOff = tonumber(GetResourceKvpString("mri_Qfps:ShadowsCutoff")) or 1.0
    presetFps = GetResourceKvpString("mri_Qfps:PresetFps") or "default"
    setPlayerTimecycleModifier({cycle = timecycleModifier})
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

if GetResourceState("mri_Qbox") == "started" then
    exports["mri_Qbox"]:AddPlayerMenu({
        title = locale("menu.mriFpsTitle"),
        description = locale("menu.mriFpsDescription"),
        icon = "tools",
        iconAnimation = "fade",
        arrow = true,
        onSelectFunction = mriFpsMenu
    })
else
    lib.callback.register("mri_Qfps:fpsMenu", function()
        mriFpsMenu()
        return true
    end)
end
