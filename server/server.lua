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

RegisterNetEvent('bcc-water:CheckCanteen', function(pumpAnim)
	local _source = source
    local itemCanteen = Config.canteen
    local canteen = VORPInv.getItem(_source, itemCanteen)
    if canteen ~= nil then
        local meta = canteen['metadata']
        if next(meta) == nil then
            VORPInv.subItem(_source, itemCanteen, 1, {})
            VORPInv.addItem(_source, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. Config.lang.full .. '</span>', level = 5
            })
        else
            local level = meta.level
            if level == 1 then
                VORPInv.subItem(_source, itemCanteen, 1, meta)
                VORPInv.addItem(_source, itemCanteen, 1, {
                    description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. Config.lang.full .. '</span>', level = 5
                })
            else
                VORPcore.NotifyRightTip(_source, _U('notEmpty'), 5000)
                TriggerClientEvent('bcc-water:Filling', _source)
                return
            end
        end
        TriggerClientEvent('bcc-water:FillCanteen', _source, pumpAnim)

    else
        VORPcore.NotifyRightTip(_source, _U('needCanteen'), 5000)
        TriggerClientEvent('bcc-water:Filling', _source)
    end
end)

VORPInv.RegisterUsableItem(Config.canteen, function(data)
    local _source = data.source
    VORPInv.CloseInv(_source)
    TriggerClientEvent('bcc-water:UseCanteen', _source, data)
end)

RegisterNetEvent('bcc-water:UpdateCanteen', function(data)
    local _source = data.source
    local itemCanteen = Config.canteen
    local canteen = VORPInv.getItem(_source, itemCanteen)
    local meta = canteen['metadata']
    local level = meta.level
    local message = nil
    local canteenUpdate = {
        [1] = function()
            VORPcore.NotifyRightTip(_source, _U('message_1'), 5000)
        end,
        [2] = function()
            message = 1
            VORPInv.subItem(_source, itemCanteen, 1, meta)
            VORPInv.addItem(_source, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:red;>' .. Config.lang.empty .. '</span>', level = 1
            })
        end,
        [3] = function()
            message = 2
            VORPInv.subItem(_source, itemCanteen, 1, meta)
            VORPInv.addItem(_source, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '25%' .. '</span>', level = 2
            })
        end,
        [4] = function()
            message = 3
            VORPInv.subItem(_source, itemCanteen, 1, meta)
            VORPInv.addItem(_source, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '50%' .. '</span>', level = 3
            })
        end,
        [5] = function()
            message = 4
            VORPInv.subItem(_source, itemCanteen, 1, meta)
            VORPInv.addItem(_source, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '75%' .. '</span>', level = 4
            })
        end
    }
        if canteenUpdate[level] then
            canteenUpdate[level]()
        end
        if not level then
            VORPcore.NotifyRightTip(_source, _U('message_1'), 5000)
            return
        elseif level > 1 then
            TriggerClientEvent('bcc-water:DrinkCanteen', _source, message)
        end
end)

-- Check if Player has an Empty Bucket and Update
RegisterNetEvent('bcc-water:CheckBucket', function(pumpAnim)
    local _source = source
    local itemCount = VORPInv.getItemCount(_source, Config.emptyBucket)
    if itemCount > 0 then
        VORPInv.subItem(_source, Config.emptyBucket, 1)
        VORPInv.addItem(_source, Config.fullBucket, 1)
        TriggerClientEvent('bcc-water:FillBucket', _source, pumpAnim)
    else
        VORPcore.NotifyRightTip(_source, _U('needBucket'))
        TriggerClientEvent('bcc-water:Filling', _source)
    end
end)

RegisterNetEvent('outsider_needs:Thirst', function(wild)
    local _source = source
    local data = {}
    if wild then
        data = {water = Config.wildThirst}
    else
        data = {water = Config.thirst}
    end
    Needs.addStats(_source, data)
end)

