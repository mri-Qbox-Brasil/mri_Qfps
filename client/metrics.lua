-- Real numbers only: FPS from the frame counter (always, nearly free) and per frame times
-- for the lows, sampled only while someone looks at them (menu, counter, preview).
FpsMetrics = {}

local HISTORY_SIZE <const> = 900
local history = {}
local detailDemand = {}
local frameTimes = {}
-- one sampler thread at most, even when demand drops and returns within a frame
local sampling = false

FpsMetrics.hud = { enabled = false, position = "top-right", frametime = true, low = true }

local function avgOf(list, from)
    local sum, n = 0, 0
    for i = math.max(from or 1, 1), #list do
        sum, n = sum + list[i], n + 1
    end
    return n > 0 and sum / n or 0
end

---@param seconds number
function FpsMetrics.average(seconds)
    return avgOf(history, #history - seconds + 1)
end

-- Mean of the slowest share of frames, as FPS: 1% low and 0.1% low.
local function low(times, share)
    if #times == 0 then return nil end
    local sorted = {}
    for i = 1, #times do sorted[i] = times[i] end
    table.sort(sorted, function(a, b) return a > b end)
    local n = math.max(math.floor(#sorted * share), 1)
    local sum = 0
    for i = 1, n do sum = sum + sorted[i] end
    return 1000 / (sum / n)
end

function FpsMetrics.stats()
    local now = history[#history] or 0
    local frametime = #frameTimes > 0 and avgOf(frameTimes) or (now > 0 and 1000 / now or 0)
    local spark = {}
    for i = math.max(#history - 59, 1), #history do spark[#spark + 1] = math.floor(history[i] + 0.5) end
    return {
        fps = math.floor(now + 0.5),
        avg = math.floor(FpsMetrics.average(60) + 0.5),
        low1 = low(frameTimes, 0.01),
        low01 = low(frameTimes, 0.001),
        min = #spark > 0 and math.min(table.unpack(spark)) or 0,
        max = #spark > 0 and math.max(table.unpack(spark)) or 0,
        frametime = frametime,
        spark = spark,
        preset = FpsGraphics.preset(),
        layer = FpsAuto.layer(),
    }
end

local function wantsDetail()
    return next(detailDemand) ~= nil
end

---@param reason string
---@param on boolean
function FpsMetrics.detail(reason, on)
    detailDemand[reason] = on or nil
    if not sampling and wantsDetail() then
        sampling = true
        frameTimes = {}
        CreateThread(function()
            while wantsDetail() do
                frameTimes[#frameTimes + 1] = GetFrameTime() * 1000
                -- keep roughly the last 10 seconds, trimming in one go instead of every frame
                if #frameTimes > 3000 then frameTimes = { table.unpack(frameTimes, 1501) } end
                Wait(0)
            end
            frameTimes = {}
            sampling = false
        end)
    end
end

local function pushHud(stats)
    if not FpsMetrics.hud.enabled then return end
    SendNUIMessage({ action = "hud", data = { fps = stats.fps, low1 = stats.low1 and math.floor(stats.low1 + 0.5), frametime = stats.frametime, prefs = FpsMetrics.hud } })
end

FpsMetrics.menuOpen = false
FpsMetrics.previewing = false

function FpsMetrics.start()
    CreateThread(function()
        local lastFrames, lastTime = GetFrameCount(), GetGameTimer()
        local nextReport = GetGameTimer() + 45000
        while true do
            Wait(1000)
            local frames, time = GetFrameCount(), GetGameTimer()
            local fps = (frames - lastFrames) * 1000 / math.max(time - lastTime, 1)
            lastFrames, lastTime = frames, time
            history[#history + 1] = fps
            if #history > HISTORY_SIZE then table.remove(history, 1) end

            if FpsMetrics.menuOpen or FpsMetrics.hud.enabled then
                local stats = FpsMetrics.stats()
                if FpsMetrics.menuOpen then SendNUIMessage({ action = "metrics", data = stats }) end
                if not FpsMetrics.menuOpen and not FpsMetrics.previewing then pushHud(stats) end
            end

            -- the admin table in mri_Qadmin reads this; numbers are checked on the server
            if time >= nextReport then
                nextReport = time + 30000
                local stats = FpsMetrics.stats()
                TriggerServerEvent("mri_Qfps:server:report", { fps = stats.avg, low1 = stats.low1, preset = stats.preset })
            end
        end
    end)
end

function FpsMetrics.setHud(prefs)
    if type(prefs) == "table" then
        for key, value in pairs(prefs) do FpsMetrics.hud[key] = value end
    end
    FpsMetrics.detail("hud", FpsMetrics.hud.enabled and FpsMetrics.hud.low)
    if not FpsMetrics.hud.enabled then SendNUIMessage({ action = "hud", data = false }) end
end

-- ═══ Preview ═══

local function measure(ms)
    frameTimes = {}
    Wait(ms)
    local sum = 0
    for i = 1, #frameTimes do sum = sum + frameTimes[i] end
    return {
        avg = #frameTimes > 0 and math.floor(1000 / (sum / #frameTimes) + 0.5) or 0,
        low1 = low(frameTimes, 0.01) and math.floor(low(frameTimes, 0.01) + 0.5) or 0,
    }
end

-- Measures where the player stands: current settings, then the preset, then back to how it was.
---@param id string
---@param onStep fun(step: string, progress: number)
function FpsMetrics.preview(id, onStep)
    FpsMetrics.previewing = true
    FpsMetrics.detail("preview", true)
    onStep("before", 0)
    Wait(1500)
    local before = measure(8000)
    onStep("after", 50)
    FpsGraphics.setLayer("preview", id)
    -- streaming settles first; those frames are thrown away
    Wait(1500)
    local after = measure(8000)
    FpsGraphics.setLayer("preview", nil)
    FpsMetrics.detail("preview", false)
    FpsMetrics.previewing = false
    return { preset = id, before = before, after = after }
end
