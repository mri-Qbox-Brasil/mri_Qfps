local timecycleModifier = "default"

-- Crosshair state
local crosshairEnabled = false
local crosshairSettings = nil

-- The extra modifier belongs to the filter, so it never needs saving on its own.
local TIMECYCLES <const> = {
    default = false,
    cinema = false,
    yell_tunnel_nodirect = false,
    tunnel = false,
    MP_Powerplay_blend = "reflection_correct_ambient",
}

local function applyTimecycle()
    ClearExtraTimecycleModifier()
    if timecycleModifier == "default" then
        ClearTimecycleModifier()
        return
    end
    SetTimecycleModifier(timecycleModifier)
    local extra = TIMECYCLES[timecycleModifier]
    if extra then
        SetExtraTimecycleModifier(extra)
    end
end

local function setPlayerTimecycleModifier(cycle)
    if TIMECYCLES[cycle] == nil then return end
    timecycleModifier = cycle
    SetResourceKvp("mri_Qfps:TimecycleModifier", cycle)
    applyTimecycle()
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

local CROSSHAIR_KVP <const> = "mri_Qfps:Crosshair"
local LEGACY_KEYS <const> = { "Enabled", "Size", "Thickness", "Gap", "Dot", "ColorR", "ColorG", "ColorB", "Alpha", "Outline", "OutlineThickness", "Style" }

local function clearLegacyCrosshair()
    for _, key in ipairs(LEGACY_KEYS) do
        DeleteResourceKvp("mri_Qfps:Crosshair" .. key)
    end
end

-- The NUI owns the crosshair shape, so the Lua keeps it as one opaque JSON.
local function saveCrosshairKvp(settings)
    if type(settings) ~= "table" then return end
    SetResourceKvp(CROSSHAIR_KVP, json.encode(settings))
    clearLegacyCrosshair()
end

-- Saves from before 1.1 come back in the old fields; the NUI converts them to pixels.
local function loadCrosshairKvp()
    local saved = GetResourceKvpString(CROSSHAIR_KVP)
    if saved then
        local ok, data = pcall(json.decode, saved)
        if ok and type(data) == "table" then return data end
    end

    local enabled = GetResourceKvpString("mri_Qfps:CrosshairEnabled")
    if enabled == nil then return nil end
    local function num(key, default) return tonumber(GetResourceKvpString("mri_Qfps:Crosshair" .. key)) or default end
    return {
        enabled = enabled == "true",
        size = num("Size", 5),
        thickness = num("Thickness", 1),
        gap = num("Gap", 0),
        dot = GetResourceKvpString("mri_Qfps:CrosshairDot") == "1",
        color_r = num("ColorR", 50),
        color_g = num("ColorG", 250),
        color_b = num("ColorB", 50),
        alpha = num("Alpha", 200),
        outline = GetResourceKvpString("mri_Qfps:CrosshairOutline") == "1",
        outlineThickness = num("OutlineThickness", 1),
    }
end

local function clearCrosshairKvp()
    DeleteResourceKvp(CROSSHAIR_KVP)
    clearLegacyCrosshair()
end

-- ═══ Hit marker ═══

local HIT_KVP <const> = "mri_Qfps:Hitmarker"
local HEAD_BONE <const> = 31086

local HIT_KINDS <const> = { hit = true, head = true, kill = true }

-- The NUI owns the marker look; the Lua only needs these fields to route a hit.
local hitPrefs = { marker = true, style = "cross", sound = "classic", volume = "medium" }
local lastHitSound = 0

local function loadHitPrefs()
    local saved = GetResourceKvpString(HIT_KVP)
    if not saved then return end
    local ok, data = pcall(json.decode, saved)
    if ok and type(data) == "table" then
        for key, value in pairs(data) do hitPrefs[key] = value end
    end
    -- the synthesized and GTA sounds gave way to one recorded hitmarker
    if hitPrefs.sound ~= "off" then hitPrefs.sound = "classic" end
end

local function hitAllowed()
    return { marker = Config.AllowHitmarker == true, sound = Config.AllowHitSound == true }
end

local function playHit(kind)
    local marker = Config.AllowHitmarker and hitPrefs.marker == true
    local sound = Config.AllowHitSound and hitPrefs.sound or "off"

    -- shotgun pellets land in the same frame: one sound per burst
    local now = GetGameTimer()
    if sound ~= "off" then
        if now - lastHitSound < 60 and kind == "hit" then sound = "off" else lastHitSound = now end
    end

    if marker or sound ~= "off" then
        SendNUIMessage({ action = "hit", data = { kind = kind, marker = marker, style = hitPrefs.style, sound = sound ~= "off", volume = hitPrefs.volume } })
    end
end

-- The game raises this on the shooter's own client, for NPCs and other players alike.
AddEventHandler("gameEventTriggered", function(name, args)
    if name ~= "CEventNetworkEntityDamage" then return end
    if not (Config.AllowHitmarker or Config.AllowHitSound) then return end
    local victim, attacker = args[1], args[2]
    if attacker ~= cache.ped or victim == cache.ped or not IsEntityAPed(victim) then return end

    local kind = "hit"
    if args[6] == 1 then
        kind = "kill"
    elseif IsPedDeadOrDying(victim, true) then
        -- shots into a body already down are not hits
        return
    else
        local found, bone = GetPedLastDamageBone(victim)
        if found and bone == HEAD_BONE then kind = "head" end
    end
    playHit(kind)
end)

AddEventHandler("mri_Qfps:client:settingsApplied", function()
    SendNUIMessage({ action = "hitAllowed", data = hitAllowed() })
end)

-- ═══ Menu ═══

local function openMenu()
    -- the preview reopens the menu itself when it ends
    if FpsMetrics.previewing then return end
    -- false lets the NUI start from its own default crosshair
    local chSettings = loadCrosshairKvp() or false

    local accent = GetConvar("mri:color", "#00E699")
    FpsMetrics.menuOpen = true
    FpsMetrics.detail("menu", true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            graphics = FpsGraphics.get(),
            layer = FpsAuto.layer(),
            locks = { presets = Config.AllowedPresets or {}, cityLights = Config.LockCityLights == true, floor = FpsGraphics.floor() },
            auto = FpsAuto.prefs,
            hud = FpsMetrics.hud,
            metrics = FpsMetrics.stats(),
            timecycle = timecycleModifier,
            crosshair = chSettings,
            hitmarker = hitPrefs,
            hitAllowed = hitAllowed(),
            loadingDistance = Config.LoadingDistanceEnabled,
            locale = GetConvar("ox:locale", "pt-br"):lower(),
            accentColor = accent:match("^#%x%x%x%x%x%x") and accent:sub(1, 7) or "#00E699",
            backgroundColor = GetConvar("mri:backgroundColor", ""),
        }
    })
end

local PREFS_KVP <const> = "mri_Qfps:Prefs"

local function savePrefs()
    SetResourceKvp(PREFS_KVP, json.encode({ auto = FpsAuto.prefs, hud = FpsMetrics.hud }))
end

-- Other scripts clear the timecycle when their own effect ends (panel blur, death screen).
local function watchTimecycle()
    CreateThread(function()
        while true do
            Wait(500)
            if timecycleModifier ~= "default" then
                local cleared = GetTimecycleModifierIndex() == -1
                if not cleared and TIMECYCLES[timecycleModifier] then
                    cleared = GetExtraTimecycleModifierIndex() == -1
                end
                if cleared then applyTimecycle() end
            end
        end
    end)
end

local hasInit = false

local function init()
    if hasInit then return end
    hasInit = true

    timecycleModifier = GetResourceKvpString("mri_Qfps:TimecycleModifier") or "default"
    if TIMECYCLES[timecycleModifier] == nil then timecycleModifier = "default" end
    if timecycleModifier ~= "default" then applyTimecycle() end

    FpsGraphics.load()

    local ok, prefs = pcall(json.decode, GetResourceKvpString(PREFS_KVP) or "")
    if ok and type(prefs) == "table" then
        FpsAuto.setPrefs(prefs.auto)
        FpsMetrics.setHud(prefs.hud)
    end

    loadHitPrefs()

    local savedCrosshair = loadCrosshairKvp()
    if savedCrosshair then
        applyCrosshairUI(savedCrosshair)
    end

    FpsGraphics.startLoop()
    FpsMetrics.start()
    FpsAuto.start()
    watchTimecycle()
end

-- Locks from the panel apply at once: a locked preset falls back to the default.
AddEventHandler("mri_Qfps:client:settingsApplied", function()
    if hasInit then FpsGraphics.reapplyLocks() end
end)

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    init()
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        init()
    end
end)

-- ═══ F9 Menu Injector (mri_Qbox) ═══

local function registerPlayerMenu()
    if GetResourceState("mri_Qbox") ~= "started" then return end
    exports["mri_Qbox"]:AddPlayerMenu({
        title = locale("menu.title"),
        description = locale("menu.description"),
        icon = "tools",
        iconAnimation = Config.IconAnimation and "fade" or nil,
        arrow = true,
        onSelectFunction = openMenu
    })
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if GetResourceState("mri_Qbox") == "started" then
            exports["mri_Qbox"]:RemovePlayerMenu(locale("menu.title"))
        end
    end
end)

-- mri_Qbox keeps the runtime F9 items in memory, so a restart of it drops ours.
AddEventHandler("onClientResourceStart", function(resource)
    if resource == "mri_Qbox" then registerPlayerMenu() end
end)

AddEventHandler("mri_Qfps:client:settingsApplied", registerPlayerMenu)

registerPlayerMenu()

-- Fallback: direct event trigger
RegisterNetEvent("mri_Qfps:openFpsMenu", function()
    openMenu()
end)

-- ═══ Admin ═══

-- Only the server sends this, after checking the admin permission.
RegisterNetEvent("mri_Qfps:client:forcePreset", function(preset)
    if FpsGraphics.setPreset(preset) then
        lib.notify({ description = locale("notify.forced", locale("ui.fps.preset." .. preset)), type = "inform", duration = 6000 })
    end
end)

-- ═══ NUI Callbacks ═══

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    FpsMetrics.menuOpen = false
    FpsMetrics.detail("menu", false)
    cb(true)
end)

RegisterNUICallback("setPresetFps", function(data, cb)
    if not FpsGraphics.setPreset(data.preset) then return cb(false) end
    cb(FpsGraphics.get())
end)

-- Values that land exactly on a preset light its card again; anything else is custom.
RegisterNUICallback("setGraphics", function(data, cb)
    FpsGraphics.setValues(data)
    cb(FpsGraphics.get())
end)

RegisterNUICallback("setAuto", function(data, cb)
    FpsAuto.setPrefs(data)
    savePrefs()
    cb(FpsAuto.prefs)
end)

RegisterNUICallback("setHud", function(data, cb)
    FpsMetrics.setHud(data)
    savePrefs()
    cb(FpsMetrics.hud)
end)

-- The menu closes so its own drawing does not skew the numbers, then opens again with the result.
RegisterNUICallback("preview", function(data, cb)
    cb(true)
    if FpsMetrics.previewing or not FpsGraphics.PRESETS[data.preset] or not FpsGraphics.presetAllowed(data.preset) then return end
    SetNuiFocus(false, false)
    FpsMetrics.menuOpen = false
    SendNUIMessage({ action = "previewStart" })
    CreateThread(function()
        local result = FpsMetrics.preview(data.preset, function(step, progress)
            SendNUIMessage({ action = "previewStep", data = { step = step, progress = progress } })
        end)
        openMenu()
        SendNUIMessage({ action = "previewResult", data = result })
    end)
end)

RegisterNUICallback("setTimecycle", function(data, cb)
    setPlayerTimecycleModifier(data.cycle)
    cb(true)
end)

-- The overlay asks on load: a message sent before the page is up would be lost.
RegisterNUICallback("getCrosshair", function(_, cb)
    cb(crosshairEnabled and crosshairSettings or false)
end)

RegisterNUICallback("setCrosshair", function(data, cb)
    applyCrosshairUI(data)
    saveCrosshairKvp(data)
    cb(true)
end)

RegisterNUICallback("setHitmarker", function(data, cb)
    if type(data) == "table" then
        for key, value in pairs(data) do hitPrefs[key] = value end
        SetResourceKvp(HIT_KVP, json.encode(hitPrefs))
    end
    cb(true)
end)

-- The test goes through the real path, so it shows exactly what a shot would.
RegisterNUICallback("testHit", function(data, cb)
    if HIT_KINDS[data.kind] then playHit(data.kind) end
    cb(true)
end)

RegisterNUICallback("resetCrosshair", function(data, cb)
    crosshairEnabled = false
    crosshairSettings = nil
    clearCrosshairKvp()
    SendNUIMessage({ action = "hideCrosshair" })
    cb(true)
end)

RegisterNUICallback("getUiConfig", function(_, cb)
    if GetResourceState("ox_lib") ~= "started" then return cb(false) end
    local ok, cfg = pcall(function() return exports.ox_lib:getUiConfig() end)
    cb(ok and type(cfg) == "table" and cfg or false)
end)

-- The mri_Qadmin plugin page posts here from its iframe.
RegisterNUICallback("getSettings", function(_, cb)
    cb(lib.callback.await("mri_Qfps:getSettings", false) or false)
end)

RegisterNUICallback("getPlayers", function(_, cb)
    cb(lib.callback.await("mri_Qfps:players", false) or false)
end)

RegisterNUICallback("forcePreset", function(data, cb)
    cb(lib.callback.await("mri_Qfps:forcePreset", false, data.target, data.preset) or false)
end)

RegisterNUICallback("saveSettings", function(data, cb)
    cb(lib.callback.await("mri_Qfps:saveSettings", false, data.section, data.values) or false)
end)

RegisterNetEvent("ox_lib:uiConfigChanged", function(cfg)
    if type(cfg) == "table" then SendNUIMessage({ action = "applyUiConfig", data = cfg }) end
end)

RegisterNetEvent("mri_Qfps:client:accentColor", function(color)
    SendNUIMessage({ action = "updateAccentColor", data = { accentColor = color } })
end)

RegisterNetEvent("mri_Qfps:client:backgroundColor", function(color)
    SendNUIMessage({ action = "updateBackgroundColor", data = { backgroundColor = color or "" } })
end)
