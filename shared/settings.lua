local STATE_KEY <const> = cache.resource .. ':settings'

---@param s table? the settings saved in the panel
function ApplySettings(s)
    if type(s) ~= 'table' or type(s.general) ~= 'table' then return end
    Config.LoadingDistanceEnabled = s.general.loadingDistance
    Config.IconAnimation = s.general.iconAnimation
    if type(s.hitmarker) == 'table' then
        Config.AllowHitmarker = s.hitmarker.marker
        Config.AllowHitSound = s.hitmarker.sound
    end
    if type(s.restrict) == 'table' then
        Config.LockCityLights = s.restrict.lockCityLights
        Config.AllowedPresets = s.restrict.presets
    end
end

if IsDuplicityVersion() then return end

ApplySettings(GlobalState[STATE_KEY])

-- the handler runs before GlobalState holds the new value: use the parameter
AddStateBagChangeHandler(STATE_KEY, 'global', function(_, _, value)
    ApplySettings(value)
    TriggerEvent(cache.resource .. ':client:settingsApplied')
end)
