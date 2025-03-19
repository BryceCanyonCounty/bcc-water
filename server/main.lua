local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()

local DevModeActive = Config.devMode.active
local MaxCanteenDrinks = Config.maxCanteenDrinks

local function DebugPrint(message)
    if DevModeActive then
        print(message)
    end
end

-- Update the canteen's metadata with the current number of drinks left and durability
local function updateCanteenMetadata(src, canteenId, canteenDesc, drinksLeft, durability)
    local description = canteenDesc .. '<br>' .. _U('drinksLeft') .. ' : ' .. tostring(drinksLeft) .. '/' .. MaxCanteenDrinks .. '<br>' .. _U('Durability') .. ' : ' .. tostring(durability) .. '%'

    -- Update the item metadata in the inventory
    exports.vorp_inventory:setItemMetadata(src, canteenId, {
        description = description,
        drinksLeft = drinksLeft,
        durability = durability
    })

    DebugPrint('Updated canteen metadata for source ' .. tostring(src) .. ': Drinks Left = ' .. tostring(drinksLeft) .. ', Durability = ' .. tostring(durability) .. '%')
end

-- Manage Filling a New or Empty Canteen
Core.Callback.Register('bcc-water:GetCanteenLevel', function(source, cb)
	local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)

    -- Check if the canteen exists in the inventory
    if not canteen then
        Core.NotifyRightTip(src, _U('needCanteen'), 4000)
        DebugPrint('Canteen not found for source: ' .. tostring(src))
        return cb(false)
    end

    local meta = canteen['metadata']
    local isNewCanteen = next(meta) == nil

    -- Fill the canteen if it's new or not full
    if isNewCanteen then
        updateCanteenMetadata(src, canteen.id, canteen.desc, MaxCanteenDrinks, 100)
        DebugPrint('Filled new canteen for source: ' .. tostring(src))
    else
        local drinksLeft = meta.drinksLeft
        local durability = meta.durability
        if drinksLeft < MaxCanteenDrinks then
            updateCanteenMetadata(src, canteen.id, canteen.desc, MaxCanteenDrinks, durability)
            DebugPrint('Refilled canteen for source: ' .. tostring(src))
        else
            Core.NotifyRightTip(src, _U('fullCanteen'), 4000)
            DebugPrint('Canteen already full for source: ' .. tostring(src))
            return cb(false)
        end
    end

    cb(true)
end)

-- Manage Drinking from Canteen
Core.Callback.Register('bcc-water:UpdateCanteen', function(source, cb)
    local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)
    local meta = canteen['metadata']
    local drinksLeft = meta.drinksLeft
    local durability = meta.durability
    local canteenUsage = Config.durability.canteen
    local newDurability = durability and durability - canteenUsage or 100

    -- Decrement drinks left and update durability
    if drinksLeft and drinksLeft > 0 then
        updateCanteenMetadata(src, canteen.id, canteen.desc, drinksLeft - 1, newDurability)
        DebugPrint('Used canteen for source ' .. tostring(src) .. ': Drinks Left = ' .. tostring(drinksLeft - 1) .. ', New Durability = ' .. tostring(newDurability) .. '%')

        -- Remove the canteen if durability is too low
        if newDurability and newDurability < canteenUsage then
            exports.vorp_inventory:subItemById(src, canteen.id)
            Core.NotifyRightTip(src, _U('brokeCanteen'), 4000)
            DebugPrint('Canteen broke for source: ' .. tostring(src))
        end
    else
        Core.NotifyRightTip(src, _U('emptyCanteen'), 4000)
        DebugPrint('Canteen empty for source: ' .. tostring(src))
        return cb(false)
    end

    cb(true)
end)

-- Check if Player has an Item and Update Inventory
Core.Callback.Register('bcc-water:GetItem', function(source, cb, itemType)
    local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local emptyItem, fullItem, notification
    if itemType == 'bucket' then
        emptyItem = Config.emptyBucket
        fullItem = Config.fullBucket
        notification = _U('needBucket')
    elseif itemType == 'bottle' then
        emptyItem = Config.emptyBottle
        fullItem = Config.fullBottle
        notification = _U('needBottle')
    else
        DebugPrint('Invalid item type for source: ' .. tostring(src))
        return cb(false)
    end

    -- Check if the player has the required item
    local hasItem = exports.vorp_inventory:getItem(src, emptyItem)
    if not hasItem then
        Core.NotifyRightTip(src, notification, 4000)
        DebugPrint('Source ' .. tostring(src) .. ' does not have the required item: ' .. emptyItem)
        return cb(false)
    end

    -- Update the inventory
    exports.vorp_inventory:subItem(src, emptyItem, 1)
    exports.vorp_inventory:addItem(src, fullItem, 1)
    DebugPrint('Updated inventory for source ' .. tostring(src) .. ': Removed ' .. emptyItem .. ', Added ' .. fullItem)

    cb(true)
end)

-- Register the canteen as a usable item
exports.vorp_inventory:registerUsableItem(Config.canteen, function(data)
    local src = data.source
    exports.vorp_inventory:closeInventory(src)

    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)
    local meta = canteen['metadata']
    local durability = meta.durability
    local canteenUsage = Config.durability.canteen

    -- Check if the canteen can be used
    if durability == nil or durability >= canteenUsage then
        TriggerClientEvent('bcc-water:UseCanteen', src)
        DebugPrint('Canteen used by source: ' .. tostring(src))
    else
        DebugPrint('Canteen cannot be used by source: ' .. tostring(src))
    end
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-water')