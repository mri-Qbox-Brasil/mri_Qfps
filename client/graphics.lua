-- Everything the presets and the fine tuning touch. 1.0 (or the default flag) is the game default:
-- a player who never touched the menu gets no native call at all.
FpsGraphics = {}

local KVP <const> = "mri_Qfps:Graphics"

local PRESETS <const> = {
    default = { lod = 1.0, lights = 1.0, shadows = 1.0, entityLod = 1.0, decals = true, flatWater = false, cityLights = 1.0, coronas = 1.0, distantLights = 1.0, puddles = 1.0, postFx = 1.0, vehicleLights = 1.0 },
    medium = { lod = 0.8, lights = 0.5, shadows = 3.0, entityLod = 0.75, decals = true, flatWater = false, cityLights = 0.75, coronas = 0.75, distantLights = 0.75, puddles = 0.5, postFx = 0.75, vehicleLights = 1.0 },
    low = { lod = 0.5, lights = 0.25, shadows = 0.0, entityLod = 0.5, decals = false, flatWater = false, cityLights = 0.5, coronas = 0.5, distantLights = 0.5, puddles = 0.25, postFx = 0.5, vehicleLights = 0.5 },
    ulow = { lod = 0.1, lights = 0.0, shadows = 0.0, entityLod = 0.25, decals = false, flatWater = true, cityLights = 0.25, coronas = 0.25, distantLights = 0.25, puddles = 0.0, postFx = 0.0, vehicleLights = 0.25 },
}
FpsGraphics.PRESETS = PRESETS
FpsGraphics.ORDER = { "default", "medium", "low", "ulow" }

-- visualsettings.dat keys scaled by each render slider
local VISUAL_KEYS <const> = {
    cityLights = {
        "lodlight.small.range", "lodlight.medium.range", "lodlight.large.range",
        "lodlight.small.fade", "lodlight.medium.fade", "lodlight.large.fade",
        "misc.brightlight.distculled.FadeStart", "misc.brightlight.distculled.FadeEnd",
        "trafficLight.farFadeStart", "trafficLight.farFadeEnd",
    },
    coronas = {
        "misc.coronas.sizeScaleGlobal", "misc.coronas.intensityScaleGlobal",
        "misc.coronas.sizeScaleWater", "misc.coronas.intensityScaleWater",
        "lodlight.small.corona.range", "lodlight.medium.corona.range", "lodlight.large.corona.range",
    },
    distantLights = {
        "distantlights.size", "distantlights.sizeMin", "distantlights.carlight.HDRIntensity",
        "distantlights.streetlight.HDRIntensity",
    },
    puddles = { "puddles.range", "puddles.scale", "puddles.strength" },
    postFx = {
        "bokeh.globalAlpha", "bokeh.sizeMultiplier",
        "bloom.blurblendmult.small", "bloom.blurblendmult.med", "bloom.blurblendmult.large",
    },
    vehicleLights = {
        "car.headlights.volume.intensityscale", "car.headlights.volume.sizescale",
        "vehicle.lights.fadeDistance.main", "vehicle.lights.fadeDistance.secondary",
        "vehicle.lights.fadeDistance.neon",
    },
}
-- own headlights go dark below this
local MIN_VEHICLE_LIGHTS <const> = 0.15

local function copy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

local user = copy(PRESETS.default)
local preset = "default"
local layers = {}
local effective = user
local applied = copy(PRESETS.default)
local visualDefaults = {}

-- ═══ Values ═══

function FpsGraphics.presetAllowed(id)
    return type(Config.AllowedPresets) ~= "table" or Config.AllowedPresets[id] ~= false
end

-- How much of the picture a value keeps; shadows 3.0 (wide, soft cascades) sits between off and default.
local function quality(key, v)
    if key == "decals" then return v and 1 or 0 end
    if key == "flatWater" then return v and 0 or 1 end
    if key == "shadows" then return v <= 0 and 0 or (v == 1.0 and 2 or 1) end
    return v
end

-- The lightest value each option may reach: the lightest among the presets the server allows.
function FpsGraphics.floor()
    local out = {}
    for _, id in ipairs(FpsGraphics.ORDER) do
        if id == "default" or FpsGraphics.presetAllowed(id) then
            for key, v in pairs(PRESETS[id]) do
                if out[key] == nil or quality(key, v) < quality(key, out[key]) then out[key] = v end
            end
        end
    end
    return out
end

---@param free boolean? temporary layers skip the preset locks
local function clean(values, free)
    local out = copy(PRESETS.default)
    if type(values) ~= "table" then return out end
    for key, default in pairs(PRESETS.default) do
        local v = values[key]
        if type(default) == "boolean" then
            if type(v) == "boolean" then out[key] = v end
        elseif tonumber(v) then
            out[key] = math.max(tonumber(v) + 0.0, 0.0)
        end
    end
    if out.lights > 1.0 then out.lights = 1.0 end
    if out.vehicleLights < MIN_VEHICLE_LIGHTS then out.vehicleLights = MIN_VEHICLE_LIGHTS end
    if not free then
        -- a locked preset must not come back one option at a time
        for key, v in pairs(FpsGraphics.floor()) do
            if quality(key, out[key]) < quality(key, v) then out[key] = v end
        end
    end
    if Config.LockCityLights then out.cityLights = 1.0 end
    return out
end

local function same(a, b)
    for key in pairs(PRESETS.default) do
        if a[key] ~= b[key] then return false end
    end
    return true
end

local function matchPreset(values)
    for _, id in ipairs(FpsGraphics.ORDER) do
        if same(clean(PRESETS[id], true), values) then return id end
    end
    return "custom"
end

-- ═══ Apply ═══

local function applyLights(v)
    if v < 1.0 then
        local cutoff = 50.0 + (v * 200.0)
        SetLightsCutoffDistanceTweak(cutoff)
        SetFlashLightFadeDistance(cutoff)
        DisableVehicleDistantlights(v < 0.5)
    else
        SetLightsCutoffDistanceTweak(0.0)
        SetFlashLightFadeDistance(0.0)
        DisableVehicleDistantlights(false)
    end
end

local function applyShadows(v)
    if v == 1.0 then
        RopeDrawShadowEnabled(true)
        CascadeShadowsClearShadowSampleType()
        CascadeShadowsInitSession()
        SetPedAoBlobRendering(cache.ped, true)
    elseif v <= 0 then
        RopeDrawShadowEnabled(false)
        CascadeShadowsClearShadowSampleType()
        CascadeShadowsSetAircraftMode(false)
        CascadeShadowsEnableEntityTracker(true)
        CascadeShadowsSetDynamicDepthMode(false)
        CascadeShadowsSetEntityTrackerScale(0.0)
        CascadeShadowsSetDynamicDepthValue(0.0)
        CascadeShadowsSetCascadeBoundsScale(0.0)
        SetPedAoBlobRendering(cache.ped, false)
    else
        RopeDrawShadowEnabled(true)
        CascadeShadowsClearShadowSampleType()
        CascadeShadowsSetAircraftMode(false)
        CascadeShadowsEnableEntityTracker(true)
        CascadeShadowsSetDynamicDepthMode(false)
        CascadeShadowsSetEntityTrackerScale(v)
        CascadeShadowsSetDynamicDepthValue(v)
        CascadeShadowsSetCascadeBoundsScale(v)
        SetPedAoBlobRendering(cache.ped, true)
    end
end

-- The factory values are read once, the first time a group leaves 1.0, so 1.0 restores them exactly.
local function applyVisual(group, scale)
    for _, key in ipairs(VISUAL_KEYS[group]) do
        if visualDefaults[key] == nil then
            local ok, value = pcall(GetVisualSettingFloat, key)
            visualDefaults[key] = ok and type(value) == "number" and value or false
        end
        local base = visualDefaults[key]
        if base then SetVisualSettingFloat(key, base * scale) end
    end
end

local function applyWater(still)
    local amplitude = still and 0.0 or 1.0
    WaterOverrideSetOceanwaveamplitude(amplitude)
    WaterOverrideSetShorewaveamplitude(amplitude)
    WaterOverrideSetRipplebumpiness(amplitude)
    WaterOverrideSetRippledisturb(amplitude)
    WaterOverrideSetStrength(still and 1.0 or 0.0)
end

local entityLodDone = {}
local entityLodReset = false

-- Only what changed since the last apply is sent to the game.
local function applyEffective()
    for key, value in pairs(effective) do
        if applied[key] ~= value then
            applied[key] = value
            if key == "lights" then
                applyLights(value)
            elseif key == "shadows" then
                applyShadows(value)
            elseif key == "flatWater" then
                applyWater(value)
            elseif key == "entityLod" then
                entityLodDone = {}
                entityLodReset = true
            elseif VISUAL_KEYS[key] then
                applyVisual(key, value)
            end
        end
    end
end

local function recompute()
    -- the strongest temporary layer wins: preview, then away, pause and auto boost
    effective = layers.preview or layers.afk or layers.pause or layers.auto or user
    applyEffective()
end

-- Ultra low cleanup touches only the player's ped and leftovers, never weather, radar, GPS or camera.
function FpsGraphics.cleanUp(ped)
    ClearBrief()
    ClearPrints()
    ClearSmallPrints()
    ClearReplayStats()
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearAllBrokenGlass()
    ClearAllHelpMessages()
    LeaderboardsReadClearAll()
    LeaderboardsClearCacheData()
    DistantCopCarSirens(false)
end

-- ═══ Public ═══

function FpsGraphics.get()
    local out = copy(user)
    out.preset = preset
    return out
end

function FpsGraphics.preset()
    return preset
end

local function save()
    SetResourceKvp(KVP, json.encode({ preset = preset, values = user }))
end

local function commit(values, id)
    local wasUltraLow = preset == "ulow"
    user = values
    preset = id
    save()
    recompute()
    if preset == "ulow" and not wasUltraLow then
        FpsGraphics.cleanUp(cache.ped)
        lib.notify({ description = locale("notify.ulow_enabled"), type = "success", duration = 5000 })
    end
end

function FpsGraphics.setPreset(id)
    if not PRESETS[id] or not FpsGraphics.presetAllowed(id) then return false end
    commit(clean(PRESETS[id]), id)
    return true
end

function FpsGraphics.setValues(values)
    local merged = copy(user)
    for key, value in pairs(type(values) == "table" and values or {}) do merged[key] = value end
    merged = clean(merged)
    local id = matchPreset(merged)
    if id ~= "custom" and not FpsGraphics.presetAllowed(id) then id = "custom" end
    commit(merged, id)
    return id
end

---@param name "preview"|"pause"|"afk"|"auto"
---@param id string? a preset id, or nil to drop the layer
function FpsGraphics.setLayer(name, id)
    layers[name] = id and clean(PRESETS[id], true) or nil
    recompute()
end

-- The panel can lock city lights or presets at any time; the saved choice is reapplied through the locks.
function FpsGraphics.reapplyLocks()
    local values = clean(user)
    if preset ~= "custom" and not FpsGraphics.presetAllowed(preset) then
        commit(clean(PRESETS.default), "default")
    elseif not same(values, user) then
        commit(values, matchPreset(values))
    end
end

function FpsGraphics.load()
    local saved = GetResourceKvpString(KVP)
    local ok, data = pcall(json.decode, saved or "")
    if ok and type(data) == "table" and type(data.values) == "table" then
        -- a saved preset takes its current values, so a preset tuned in an update reaches old saves
        if PRESETS[data.preset] then
            user, preset = clean(PRESETS[data.preset]), data.preset
        else
            user = clean(data.values)
            preset = matchPreset(user)
        end
    else
        -- 1.0 saves kept only three sliders and the preset name
        local old = GetResourceKvpString("mri_Qfps:PresetFps") or "default"
        local values = copy(PRESETS[old] or PRESETS.default)
        values.lod = tonumber(GetResourceKvpString("mri_Qfps:LodDistance")) or values.lod
        values.lights = tonumber(GetResourceKvpString("mri_Qfps:LightsCutoff")) or values.lights
        values.shadows = tonumber(GetResourceKvpString("mri_Qfps:ShadowsCutoff")) or values.shadows
        user = clean(values)
        preset = matchPreset(user)
        for _, key in ipairs({ "PresetFps", "LodDistance", "LightsCutoff", "ShadowsCutoff" }) do
            DeleteResourceKvp("mri_Qfps:" .. key)
        end
        save()
    end
    if preset ~= "custom" and not FpsGraphics.presetAllowed(preset) then
        user, preset = clean(PRESETS.default), "default"
    end
    recompute()
    if preset == "ulow" then FpsGraphics.cleanUp(cache.ped) end
end

-- ═══ Per frame ═══

FpsGraphics.interiorRelief = false

-- Ped and vehicle LOD is per entity: new ones get it on the next scan.
local function scanEntityLod(lod)
    local seen = {}
    for _, ped in ipairs(GetGamePool("CPed")) do
        seen[ped] = true
        if not entityLodDone[ped] and ped ~= cache.ped and not IsPedAPlayer(ped) then
            SetPedLodMultiplier(ped, lod)
        end
    end
    local own = cache.vehicle
    for _, veh in ipairs(GetGamePool("CVehicle")) do
        seen[veh] = true
        if not entityLodDone[veh] and veh ~= own then
            SetVehicleLodMultiplier(veh, lod)
        end
    end
    entityLodDone = seen
end

function FpsGraphics.startLoop()
    CreateThread(function()
        local nextScan = 0
        while true do
            local lod = Config.LoadingDistanceEnabled and effective.lod ~= 1.0 and effective.lod or nil
            local perFrame = lod ~= nil or not effective.decals or FpsGraphics.interiorRelief

            if lod then OverrideLodscaleThisFrame(lod) end
            if not effective.decals then SetDisableDecalRenderingThisFrame() end
            if FpsGraphics.interiorRelief then
                SetAmbientPedRangeMultiplierThisFrame(0.3)
                SetAmbientVehicleRangeMultiplierThisFrame(0.3)
            end

            local now = GetGameTimer()
            if now >= nextScan then
                nextScan = now + 2000
                -- one pass at 1.0 after a change puts every entity back to the game LOD
                if effective.entityLod ~= 1.0 or entityLodReset then
                    entityLodReset = false
                    scanEntityLod(effective.entityLod)
                end
            end

            Wait(perFrame and 0 or 500)
        end
    end)
end

-- A new ped (spawn, skin change) comes back with the game AO blob and without the ultra low cleanup.
lib.onCache("ped", function(ped)
    if effective.shadows ~= 1.0 then SetPedAoBlobRendering(ped, effective.shadows ~= 0) end
    if preset == "ulow" then FpsGraphics.cleanUp(ped) end
end)
