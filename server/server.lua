local VORPcore = {}
local VORPInv = {}
local Needs = {}

TriggerEvent('getCore', function(core)
    VORPcore = core
end)

VORPInv = exports.vorp_inventory:vorp_inventoryApi()

TriggerEvent('Outsider_Needs', function(cb)
    Needs = cb
end)

RegisterNetEvent('bcc-water:CheckEmpty', function()
	local _source = source
    local canteen = VORPInv.getItem(_source, 'canteen')
    if canteen ~= nil then
        local meta = canteen['metadata']
        if next(meta) == nil then
            VORPInv.subItem(_source, 'canteen', 1, {})
            VORPInv.addItem(_source, 'canteen', 1, {description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. Config.lang.full .. '</span>', level = 5})
        else
            local level = meta.level
            if level == 1 then
                VORPInv.subItem(_source, 'canteen', 1, meta)
                VORPInv.addItem(_source, 'canteen', 1, {description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. Config.lang.full .. '</span>', level = 5})
            else
                VORPcore.NotifyRightTip(_source, _U('not_empty'), 5000)
                TriggerClientEvent('bcc-water:Filling', _source)
                return
            end
        end
        TriggerClientEvent('bcc-water:FillCanteen', _source)
    else
        VORPcore.NotifyRightTip(_source, _U('needcanteen'), 5000)
    end
end)

VORPInv.RegisterUsableItem('canteen', function(data)
    local _source = data.source
    VORPInv.CloseInv(_source)
    TriggerClientEvent('bcc-water:UseCanteen', _source, data)
end)

RegisterNetEvent('bcc-water:UpdateCanteen', function(data)
    local _source = data.source
    local canteen = VORPInv.getItem(_source, 'canteen')
    local meta = canteen['metadata']
    local level = meta.level
    local message = nil
    local canteenUpdate = {
        [1] = function()
            VORPcore.NotifyRightTip(_source, _U('message_1'), 5000)
        end,
        [2] = function()
            message = 1
            VORPInv.subItem(_source, 'canteen', 1, meta)
            VORPInv.addItem(_source, 'canteen', 1, {description = Config.lang.level .. ' : ' .. '<span style=color:red;>' .. Config.lang.empty .. '</span>', level = 1})
        end,
        [3] = function()
            message = 2
            VORPInv.subItem(_source, 'canteen', 1, meta)
            VORPInv.addItem(_source, 'canteen', 1, {description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '25%' .. '</span>', level = 2})
        end,
        [4] = function()
            message = 3
            VORPInv.subItem(_source, 'canteen', 1, meta)
            VORPInv.addItem(_source, 'canteen', 1, {description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '50%' .. '</span>', level = 3})
        end,
        [5] = function()
            message = 4
            VORPInv.subItem(_source, 'canteen', 1, meta)
            VORPInv.addItem(_source, 'canteen', 1, {description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '75%' .. '</span>', level = 4})
        end
    }
        if canteenUpdate[level] then
            canteenUpdate[level]()
        end
        if not level then
            VORPcore.NotifyRightTip(_source, _U('message_1'), 5000)
            return
        elseif level > 1 then
            TriggerClientEvent('bcc-water:Drink', _source, message)
        end
end)

RegisterNetEvent('outsider_needs:Thirst', function(wild)
    local _source = source
    local data = {}
    if wild then
        data = {water = Config.WildThirst}
    else
        data = {water = Config.Thirst}
    end
    Needs.addStats(_source, data)
end)

