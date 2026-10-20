-- Cuts where nobody is looking: a temporary layer over the player's preset that is never saved.
FpsAuto = {}

FpsAuto.prefs = {
    pauseSaver = true,
    afk = false,
    afkMinutes = 5,
    interior = false,
    autoBoost = false,
    boostBelow = 45,
    boostAbove = 90,
    alert = false,
    alertBelow = 30,
    cleanup = false,
    cleanupEvery = 60,
    cleanupRadius = 100,
}

-- Applied while the player is not playing, so a locked preset is fine here.
local IDLE_PRESET <const> = "ulow"
local BOOST_COOLDOWN <const> = 30000
local ALERT_COOLDOWN <const> = 120000

local paused, away = false, false
local lastActive, lastCoords = GetGameTimer(), nil
local boostLevel = nil
local nextBoostCheck, nextAlert, nextCleanup, lowSince = 0, 0, 0, nil

local function setPrefs(prefs)
    if type(prefs) ~= "table" then return end
    for key, default in pairs(FpsAuto.prefs) do
        local v = prefs[key]
        if type(v) == type(default) then FpsAuto.prefs[key] = v end
    end
end
FpsAuto.setPrefs = setPrefs

-- Mouse look, a step, a key or a focused NUI counts as activity; the game's idle camera moves on its own, so the rendered camera does not.
local function active()
    local coords = GetEntityCoords(cache.ped)
    local moved = not lastCoords or #(coords - lastCoords) > 0.3
        or GetDisabledControlNormal(0, 1) ~= 0.0 or GetDisabledControlNormal(0, 2) ~= 0.0
        or IsControlPressed(0, 32) or IsControlPressed(0, 24) or IsNuiFocused()
    lastCoords = coords
    return moved
end

local function presetIndex(id)
    for i, value in ipairs(FpsGraphics.ORDER) do
        if value == id then return i end
    end
    return 1
end

-- One preset step at a time, with a pause between steps so it never jumps back and forth.
local function autoBoost(now)
    local p = FpsAuto.prefs
    if not p.autoBoost then
        if boostLevel then boostLevel = nil; FpsGraphics.setLayer("auto", nil) end
        return
    end
    local base = presetIndex(FpsGraphics.preset())
    -- the player picked a preset as light as the boost (or lighter): their choice shows at once
    if boostLevel and boostLevel <= base then
        boostLevel = nil
        FpsGraphics.setLayer("auto", nil)
    end
    if now < nextBoostCheck then return end
    local avg = FpsMetrics.average(10)
    if avg <= 0 then return end

    local level = boostLevel or base
    local target = level
    if avg < p.boostBelow and level < #FpsGraphics.ORDER then
        target = level + 1
        while target <= #FpsGraphics.ORDER and not FpsGraphics.presetAllowed(FpsGraphics.ORDER[target]) do target = target + 1 end
        if target > #FpsGraphics.ORDER then target = level end
    elseif avg > p.boostAbove and boostLevel then
        target = level - 1
        while target > base and not FpsGraphics.presetAllowed(FpsGraphics.ORDER[target]) do target = target - 1 end
    end

    if target ~= level then
        nextBoostCheck = now + BOOST_COOLDOWN
        if target <= base then
            boostLevel = nil
            FpsGraphics.setLayer("auto", nil)
        else
            boostLevel = target
            FpsGraphics.setLayer("auto", FpsGraphics.ORDER[target])
        end
    else
        nextBoostCheck = now + 10000
    end
end

-- Only after 15 seconds in a row under the line, at most every two minutes.
local function alert(now)
    local p = FpsAuto.prefs
    if not p.alert then lowSince = nil return end
    local avg = FpsMetrics.average(3)
    if avg > 0 and avg < p.alertBelow then
        lowSince = lowSince or now
        if now - lowSince >= 15000 and now >= nextAlert then
            nextAlert = now + ALERT_COOLDOWN
            lib.notify({ description = locale("notify.low_fps", math.floor(FpsMetrics.average(15) + 0.5)), type = "warning", duration = 7000 })
        end
    else
        lowSince = nil
    end
end

-- Decals, particles and broken glass are cosmetic; nothing runs while the player is fighting.
local function cleanup(now)
    local p = FpsAuto.prefs
    if not p.cleanup or now < nextCleanup then return end
    nextCleanup = now + p.cleanupEvery * 1000
    if IsPedShooting(cache.ped) or IsPedInMeleeCombat(cache.ped) then return end
    local c = GetEntityCoords(cache.ped)
    RemoveDecalsInRange(c.x, c.y, c.z, p.cleanupRadius + 0.0)
    RemoveParticleFxInRange(c.x, c.y, c.z, p.cleanupRadius + 0.0)
    ClearAllBrokenGlass()
end

function FpsAuto.start()
    CreateThread(function()
        while true do
            Wait(500)
            local now = GetGameTimer()
            local p = FpsAuto.prefs

            local isPaused = p.pauseSaver and IsPauseMenuActive()
            if isPaused ~= paused then
                paused = isPaused
                FpsGraphics.setLayer("pause", paused and IDLE_PRESET or nil)
            end

            if active() then lastActive = now end
            local isAway = p.afk and not isPaused and now - lastActive > p.afkMinutes * 60000
            if isAway ~= away then
                away = isAway
                FpsGraphics.setLayer("afk", away and IDLE_PRESET or nil)
            end

            FpsGraphics.interiorRelief = p.interior and GetInteriorFromEntity(cache.ped) ~= 0

            autoBoost(now)
            alert(now)
            cleanup(now)
        end
    end)
end

-- The menu shows the player's choice; this says when a layer is on top of it.
function FpsAuto.layer()
    if away then return "afk" end
    if paused then return "pause" end
    if boostLevel then return FpsGraphics.ORDER[boostLevel] end
    return nil
end
