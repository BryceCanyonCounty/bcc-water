local VORPcore = exports.vorp_core:GetCore()

local Needs = {}
TriggerEvent('Outsider_Needs', function(cb)
    Needs = cb
end)

VORPcore.Callback.Register('bcc-water:GetCanteenLevel', function(source, cb)
	local src = source
    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)

    if canteen == nil then
        VORPcore.NotifyRightTip(src, _U('needCanteen'), 4000)
        cb(false)
        return
    end

    local meta = canteen['metadata']
    if next(meta) == nil then
        exports.vorp_inventory:subItem(src, itemCanteen, 1, {})
        exports.vorp_inventory:addItem(src, itemCanteen, 1, {
            description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. Config.lang.full .. '</span>' .. ' ' .. Config.lang.Durability .. ' : ' .. '<span style=color:yellow;>' .. '100' .. '</span>', level = 5, durability = 100
        })
    else
        local level = meta.level
        local durability = meta.durability
        if level < 5 then
            exports.vorp_inventory:subItem(src, itemCanteen, 1, meta)
            exports.vorp_inventory:addItem(src, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. Config.lang.full .. '</span>' .. ' ' .. Config.lang.Durability .. ' : ' .. '<span style=color:yellow;>' .. tostring(durability - Config.CanteenUsage) .. '</span>', level = 5, durability = durability - Config.CanteenUsage
            })
        else
            VORPcore.NotifyRightTip(src, _U('notEmpty'), 4000)
            cb(false)
            return
        end
    end
    cb(true)
end)

exports.vorp_inventory:registerUsableItem(Config.canteen, function(data)
    local src = data.source
    exports.vorp_inventory:closeInventory(src)
    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)
    local meta = canteen['metadata']
    local durability = meta.durability
    local canteenUsage = Config.CanteenUsage
    print(durability)
    if (durability == nil) or (durability >= canteenUsage) then
        TriggerClientEvent('bcc-water:UseCanteen', src)
    elseif durability < canteenUsage then
        exports.vorp_inventory:subItem(src, itemCanteen, 1, meta)
        VORPcore.NotifyRightTip(src, _U('needCanteen'), 4000)
    end
end)

VORPcore.Callback.Register('bcc-water:UpdateCanteen', function(source, cb)
    local src = source
    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)
    local meta = canteen['metadata']
    local level = meta.level
    local durability = meta.durability
    local canteenUpdate = {
        [1] = function()
            VORPcore.NotifyRightTip(src, _U('message_1'), 4000)
        end,

        [2] = function()
            exports.vorp_inventory:subItem(src, itemCanteen, 1, meta)
            exports.vorp_inventory:addItem(src, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:red;>' .. Config.lang.empty .. '</span>' .. ' ' .. Config.lang.Durability .. ' : ' .. '<span style=color:yellow;>' .. tostring(durability - Config.CanteenUsage) .. '</span>', level = 1, durability = durability
            })
        end,

        [3] = function()
            exports.vorp_inventory:subItem(src, itemCanteen, 1, meta)
            exports.vorp_inventory:addItem(src, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '25%' .. '</span>' .. ' ' .. Config.lang.Durability .. ' : ' .. '<span style=color:yellow;>' .. tostring(durability - Config.CanteenUsage) .. '</span>', level = 2, durability = durability - Config.CanteenUsage
            })
        end,

        [4] = function()
            exports.vorp_inventory:subItem(src, itemCanteen, 1, meta)
            exports.vorp_inventory:addItem(src, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '50%' .. '</span>' .. ' ' .. Config.lang.Durability .. ' : ' .. '<span style=color:yellow;>' .. tostring(durability - Config.CanteenUsage) .. '</span>', level = 3, durability = durability - Config.CanteenUsage
            })
        end,

        [5] = function()
            exports.vorp_inventory:subItem(src, itemCanteen, 1, meta)
            exports.vorp_inventory:addItem(src, itemCanteen, 1, {
                description = Config.lang.level .. ' : ' .. '<span style=color:green;>' .. '75%' .. '</span>' .. ' ' .. Config.lang.Durability .. ' : ' .. '<span style=color:yellow;>' .. tostring(durability - Config.CanteenUsage) .. '</span>', level = 4, durability = durability - Config.CanteenUsage
            })
        end
    }
    if canteenUpdate[level] then
	    canteenUpdate[level]()
    end

    if not level then
        VORPcore.NotifyRightTip(src, _U('message_1'), 4000)
        cb(false)
    elseif level > 1 then
        cb(level)
    end
end)

-- Check if Player has an Empty Bucket and Update
VORPcore.Callback.Register('bcc-water:GetBucket', function(source, cb)
    local src = source
    local hasItem = exports.vorp_inventory:getItem(src, Config.emptyBucket)

    if not hasItem then
        VORPcore.NotifyRightTip(src, _U('needBucket'), 4000)
        cb(false)
        return
    end

    exports.vorp_inventory:subItem(src, Config.emptyBucket, 1)
    exports.vorp_inventory:addItem(src, Config.fullBucket, 1)
    cb(true)
end)

RegisterNetEvent('outsider_needs:Thirst', function(wild)
    local src = source
    local data = {}
    if wild then
        data = {water = Config.wildThirst}
    else
        data = {water = Config.thirst}
    end
    Needs.addStats(src, data)
end)

