local FILE <const> = 'data/settings.json'
local STATE_KEY <const> = cache.resource .. ':settings'

local DEFAULTS <const> = {
    general = {
        loadingDistance = Config.LoadingDistanceEnabled == true,
        iconAnimation = Config.IconAnimation == true,
    },
    hitmarker = {
        marker = Config.AllowHitmarker == true,
        sound = Config.AllowHitSound == true,
    },
    restrict = {
        lockCityLights = Config.LockCityLights == true,
        presets = {
            medium = Config.AllowedPresets.medium ~= false,
            low = Config.AllowedPresets.low ~= false,
            ulow = Config.AllowedPresets.ulow ~= false,
        },
    },
}

local current = {}

--- Copy of the defaults taking, per key, the new value or else the previous one, only when it keeps the default's type
local function merge(defaults, new, previous)
    local out = {}
    for k, v in pairs(defaults) do
        local n, p
        if type(new) == 'table' then n = new[k] end
        if type(previous) == 'table' then p = previous[k] end
        if type(v) == 'table' then
            out[k] = merge(v, n, p)
        elseif type(n) == type(v) then
            out[k] = n
        elseif type(p) == type(v) then
            out[k] = p
        else
            out[k] = v
        end
    end
    return out
end

local function publish()
    ApplySettings(current)
    GlobalState[STATE_KEY] = current
end

local ok, saved = pcall(json.decode, LoadResourceFile(cache.resource, FILE) or '')
current = merge(DEFAULTS, ok and saved or nil)
publish()

local function save(section, values)
    if not DEFAULTS[section] or type(values) ~= 'table' then return false end
    current[section] = merge(DEFAULTS[section], values, current[section])
    if not SaveResourceFile(cache.resource, FILE, json.encode(current, { indent = true }), -1) then return false end
    publish()
    return true
end

lib.callback.register(cache.resource .. ':getSettings', function(source)
    if not IsAdmin(source) then return false end
    return current
end)

lib.callback.register(cache.resource .. ':saveSettings', function(source, section, values)
    if not IsAdmin(source) then return false end
    return type(section) == 'string' and save(section, values)
end)
