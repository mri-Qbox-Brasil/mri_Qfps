local ACE <const> = 'command.fps'

function IsAdmin(source)
    return IsPlayerAceAllowed(source, ACE)
end

-- Suite colors follow the convars live; the menu listens for these events.
AddConvarChangeListener('mri:color', function()
    local color = GetConvar('mri:color', '#00E699')
    if color:match('^#%x%x%x%x%x%x') then
        TriggerClientEvent('mri_Qfps:client:accentColor', -1, color:sub(1, 7))
    end
end)

AddConvarChangeListener('mri:backgroundColor', function()
    local color = GetConvar('mri:backgroundColor', '')
    if color == '' or color:match('^#%x%x%x%x%x%x$') then
        TriggerClientEvent('mri_Qfps:client:backgroundColor', -1, color)
    end
end)

local function registerPlugin()
    if GetResourceState('mri_Qadmin') ~= 'started' then return end
    local ok, err = pcall(function()
        return exports.mri_Qadmin:RegisterPlugin({
            id = 'fps',
            label = 'FPS',
            icon = 'gauge',
            resource = cache.resource,
            htmlPath = 'html/index.html',
            requiredPerms = { ACE },
            description = locale('plugin_description'),
        })
    end)
    if not ok then lib.print.warn(('could not register the mri_Qadmin plugin: %s'):format(err)) end
end

-- Both hooks are needed: pluginsReady covers a Qadmin restart, the start check covers us starting last.
AddEventHandler('mri_Qadmin:server:pluginsReady', registerPlugin)
AddEventHandler('onResourceStart', function(resource)
    if resource == cache.resource or resource == 'mri_Qadmin' then
        SetTimeout(500, registerPlugin)
    end
end)
