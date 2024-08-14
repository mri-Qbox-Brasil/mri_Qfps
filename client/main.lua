ColorScheme = GlobalState.UIColors or {}
local timecycleModifier = "default"
local lodDistance = nil
local lightsCutOff = 1.0
local shadowsCutOff = 1.0

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
            min = 0.1,
            max = 200.0,
            step = 0.5,
            default = lodDistance
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
            min = 0.5,
            max = 200.0,
            step = 0.5,
            default = lightsCutOff
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
            min = 0.1,
            max = 1.0,
            step = 0.1,
            default = shadowsCutOff
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

            if lightsCutOff ~= nil then
                SetLightsCutoffDistanceTweak(lightsCutOff)
                SetFlashLightFadeDistance(lightsCutOff)
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
                else
                    RopeDrawShadowEnabled(false)
                    CascadeShadowsSetAircraftMode(false)
                    CascadeShadowsEnableEntityTracker(false)
                    CascadeShadowsSetDynamicDepthMode(false)
                    SetPedAoBlobRendering(cache.ped, false)
                end
                CascadeShadowsSetEntityTrackerScale(shadowsCutOff)
                CascadeShadowsSetDynamicDepthValue(shadowsCutOff)
                CascadeShadowsSetCascadeBoundsScale(shadowsCutOff)
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
