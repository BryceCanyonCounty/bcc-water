local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()

local DevModeActive = Config.devMode.active
local MaxCanteenDrinks = Config.maxCanteenDrinks
local SickPlayers = {}

local function DebugPrint(message)
    if DevModeActive then
        print('^1[DEV MODE] ^4' .. message)
    end
end

---@param src number
---@param canteenId number
---@param drinksLeft number
---@param durability number
local function updateCanteenMetadata(src, canteenId, drinksLeft, durability)
    local description = _U('canteenDesc') .. '<br>'
    .. _U('drinksLeft') .. ' : ' .. tostring(drinksLeft) .. '/' .. tostring(MaxCanteenDrinks) .. '<br>'
    .. _U('Durability') .. ' : ' .. tostring(durability) .. '%'

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
        updateCanteenMetadata(src, canteen.id, MaxCanteenDrinks, 100)
        DebugPrint('Filled new canteen for source: ' .. tostring(src))
    else
        local drinksLeft = meta.drinksLeft
        local durability = meta.durability
        if drinksLeft < MaxCanteenDrinks then
            updateCanteenMetadata(src, canteen.id, MaxCanteenDrinks, durability)
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
        updateCanteenMetadata(src, canteen.id, drinksLeft - 1, newDurability)
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

RegisterNetEvent('bcc-water:UpdateSickness', function(isSick)
    local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return
    end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier

    DebugPrint('Updating sickness for character ID: ' .. tostring(charid))

    SickPlayers[charid] = isSick and true or nil
    DebugPrint('Sickness status for character ID ' .. tostring(charid) .. ': ' .. tostring(isSick))
end)

Core.Callback.Register('bcc-water:CheckSickness', function(source, cb)
    local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier

    if SickPlayers[charid] then
        DebugPrint('Sickness detected for character ID ' .. tostring(charid) .. ': ' .. tostring(SickPlayers[charid]))
        return cb(true)
    else
        DebugPrint('No sickness detected for character ID ' .. tostring(charid))
        return cb(false)
    end
end)

-- Check if Player has an Item and Update Inventory
---@param itemType string
---@param itemAmount number
---@param pump boolean
Core.Callback.Register('bcc-water:GetItem', function(source, cb, itemType, itemAmount, pump)
    local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    -- Set empty item and notifications based on item type
    local emptyItem = itemType == 'bucket' and Config.emptyBucket or Config.emptyBottle
    local notification = itemType == 'bucket' and _U('needBucket') or _U('needBottle')

    -- Check if the player has the required item
    local item = exports.vorp_inventory:getItem(src, emptyItem)
    if not item or item.count < itemAmount then
        Core.NotifyRightTip(src, notification, 4000)
        DebugPrint('Source ' .. tostring(src) .. ' does not have the required item: ' .. emptyItem)
        return cb(false)
    end

    -- Remove empty items
    exports.vorp_inventory:subItem(src, emptyItem, itemAmount)

    for i = 1, itemAmount do
        local sourceType = pump and 'pump' or 'wild'

        if itemType == 'bottle' then
            local itemName = pump and Config.cleanBottle or Config.dirtyBottle

            exports.vorp_inventory:addItem(src, itemName, 1, { source = sourceType })
            DebugPrint('Added item to source ' .. src .. ': ' .. itemName .. ', Pump: ' .. tostring(pump))

        elseif itemType == 'bucket' then
            local itemName = pump and Config.cleanBucket or Config.dirtyBucket

            exports.vorp_inventory:addItem(src, itemName, 1, { source = sourceType })
            DebugPrint('Added item to source ' .. src .. ': ' .. itemName .. ', Pump: ' .. tostring(pump))
        end
    end

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

-- Clean Bottle (no sickness)
if Config.useable.cleanBottle then
    DebugPrint('Registering clean bottle as usable item')
    exports.vorp_inventory:registerUsableItem(Config.cleanBottle, function(data)
        local src = data.source
        local emptyBottle = Config.emptyBottle

        exports.vorp_inventory:closeInventory(src)
        exports.vorp_inventory:subItemById(src, data.item.id)
        if exports.vorp_inventory:canCarryItem(src, emptyBottle, 1) then
            exports.vorp_inventory:addItem(src, emptyBottle, 1)
        end

        TriggerClientEvent('bcc-water:DrinkBottle', src, false)
    end)
end

-- Dirty Bottle (sickness chance)
if Config.useable.dirtyBottle then
    DebugPrint('Registering dirty bottle as usable item')
    exports.vorp_inventory:registerUsableItem(Config.dirtyBottle, function(data)
        local src = data.source
        local emptyBottle = Config.emptyBottle

        exports.vorp_inventory:closeInventory(src)
        exports.vorp_inventory:subItemById(src, data.item.id)
        if exports.vorp_inventory:canCarryItem(src, emptyBottle, 1) then
            exports.vorp_inventory:addItem(src, emptyBottle, 1)
        end

        TriggerClientEvent('bcc-water:DrinkBottle', src, true)
    end)
end

if Config.useable.antidoteItem then
    DebugPrint('Registering antidote item as usable item')
    exports.vorp_inventory:registerUsableItem(Config.antidoteItem, function(data)
        local src = data.source

        exports.vorp_inventory:closeInventory(src)
        exports.vorp_inventory:subItem(src, Config.antidoteItem, 1)

        TriggerClientEvent('bcc-water:CureSickness', src)
    end)
end

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-water')
