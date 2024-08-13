local timecycleModifier = "default"

local function ifThen(condition, ifTrue, ifFalse)
    if condition then
        return ifTrue
    end
    return ifFalse
end

local function SetPlayerTimecycleModifier(args)
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
    if args then
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
        arrow = true,
        onSelect = SetPlayerTimecycleModifier,
        args = {
            cycle = modifier,
            extra = extra,
            callback = callback
        }
    }
end

local function fpsMenu()
    local ctx = {
        id = "menu_fps",
        menu = "menu_jogador",
        title = locale("menu.title"),
        description = locale("menu.description"),
        options = {
            menuObj("menu.timecycleDefault", "default", nil, fpsMenu),
            menuObj("menu.timecycleCinema", "cinema", nil, fpsMenu),
            menuObj("menu.timecycleYell", "yell_tunnel_nodirect", nil, fpsMenu),
            menuObj("menu.timecycleTunnel", "tunnel", nil, fpsMenu),
            menuObj("menu.timecyclePower", "MP_Powerplay_blend", "reflection_correct_ambient", fpsMenu)
        }
    }

    lib.registerContext(ctx)
    lib.showContext(ctx.id)
end

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    timecycleModifier = GetResourceKvpString("mri_Qfps:TimecycleModifier") or "default"
    if timecycleModifier ~= "default" then
        SetTimecycleModifier(timecycleModifier)
    end
end)

if GetResourceState("mri_Qbox") == "started" then
    exports["mri_Qbox"]:AddPlayerMenu({
        title = locale("menu.title"),
        description = locale("menu.description"),
        icon = "tools",
        iconAnimation = "fade",
        arrow = true,
        onSelectFunction = fpsMenu
    })
else
    lib.callback.register("mri_Qfps:fpsMenu", function()
        fpsMenu()
        return true
    end)
end
