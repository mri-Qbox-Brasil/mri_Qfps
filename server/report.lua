-- Each client reports its own FPS every 30 seconds; the mri_Qadmin tab lists them, worst first.
local PRESET_IDS <const> = { default = true, medium = true, low = true, ulow = true, custom = true }
local reports = {}

RegisterNetEvent("mri_Qfps:server:report", function(data)
    local src = source
    if type(data) ~= "table" then return end
    local fps = tonumber(data.fps)
    if not fps or fps < 0 or fps > 1000 then return end
    local now = os.time()
    local last = reports[src]
    if last and now - last.at < 20 then return end
    local low1 = tonumber(data.low1)
    reports[src] = {
        fps = math.floor(fps),
        low1 = low1 and low1 >= 0 and math.floor(math.min(low1, 1000)) or nil,
        preset = PRESET_IDS[data.preset] and data.preset or "custom",
        at = now,
    }
end)

AddEventHandler("playerDropped", function()
    reports[source] = nil
end)

lib.callback.register("mri_Qfps:players", function(source)
    if not IsAdmin(source) then return false end
    local now = os.time()
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local r = reports[src]
        list[#list + 1] = {
            id = src,
            name = GetPlayerName(src),
            ping = GetPlayerPing(src),
            fps = r and r.fps or nil,
            low1 = r and r.low1 or nil,
            preset = r and r.preset or nil,
            age = r and now - r.at or nil,
        }
    end
    table.sort(list, function(a, b)
        if a.fps and b.fps then return a.fps < b.fps end
        return a.fps ~= nil
    end)
    return list
end)

lib.callback.register("mri_Qfps:forcePreset", function(source, target, preset)
    if not IsAdmin(source) then return false end
    if preset == "custom" or not PRESET_IDS[preset] then return false end
    -- the client refuses a locked preset anyway; saying so here keeps the panel honest
    if preset ~= "default" and type(Config.AllowedPresets) == "table" and Config.AllowedPresets[preset] == false then return false end
    if target == "all" then
        TriggerClientEvent("mri_Qfps:client:forcePreset", -1, preset)
        return true
    end
    local id = tonumber(target)
    if not id or not GetPlayerName(id) then return false end
    TriggerClientEvent("mri_Qfps:client:forcePreset", id, preset)
    return true
end)
