local MaxCanteenDrinks = Config.usesPerFill.canteen
local PurifyEventPrefix = 'bcc-water:PurifyContainer:'
local usableItemData = WaterInventory.usableItemData
local withItemLock = WaterInventory.withItemLock
local useOnCooldown = WaterInventory.useOnCooldown
local startUseCooldown = WaterInventory.startUseCooldown
local getItemInstance = WaterInventory.getItemInstance
local removeOneItemById = WaterInventory.removeOneItemById
local addInventoryItem = WaterInventory.addItem

---@return table|nil
local function purificationContext()
    if not Config.purification.enabled then
        return nil
    end

    local context = {}
    for methodName, method in pairs(Config.purification.methods) do
        if method.enabled then
            context[#context + 1] = {
                text = method.label,
                close = true,
                event = { server = PurifyEventPrefix .. methodName },
            }
        end
    end

    return #context > 0 and context or nil
end

---@param item table
---@param extra table|nil
---@param itemType string
---@return table
local function containerMetadata(item, extra, itemType)
    local metadata = extra or {}
    local itemMetadata = item and item.metadata

    if itemMetadata and itemMetadata.durability ~= nil then
        metadata.durability = itemMetadata.durability
    else
        metadata.durability = Config.durability.defaults[itemType]
    end

    return metadata
end

---@param metadata table
---@param itemType string
---@param waterType string
local function setContainerDescription(metadata, itemType, waterType)
    local containerName = itemType == 'bucket' and 'Bucket' or 'Bottle'
    local state = waterType == 'empty' and 'Empty'
        or (waterType == 'dirty' and 'Dirty Water' or 'Clean Water')

    metadata.waterType = waterType
    metadata.description = containerName .. ' : ' .. state .. '<br>'
        .. _U('Durability') .. ' : ' .. tostring(metadata.durability) .. '%'
    if waterType ~= 'empty' then
        metadata.description = metadata.description .. '<br>'
            .. 'Uses Left : ' .. tostring(metadata.usesLeft)
            .. '/' .. tostring(Config.usesPerFill[itemType])
    end
end

---@param item table
---@param itemType string
---@return boolean
local function consumeContainerUnlocked(item, itemType)
    local usableItem, src, itemId = usableItemData(item)
    if not usableItem or not src or not itemId then
        DBG:Error('Cannot consume container: usable-item data is required')
        return false
    end

    local emptyItem
    local cleanItem
    local dirtyItem

    if itemType == 'bucket' then
        emptyItem = Config.emptyBucket
        cleanItem = Config.cleanBucket
        dirtyItem = Config.dirtyBucket
    elseif itemType == 'bottle' then
        emptyItem = Config.emptyBottle
        cleanItem = Config.cleanBottle
        dirtyItem = Config.dirtyBottle
    else
        DBG:Error(string.format('Cannot consume container: invalid type %s', tostring(itemType)))
        return false
    end

    local currentItem = getItemInstance(src, itemId)
    if not currentItem then
        return false
    end

    if currentItem.name ~= cleanItem and currentItem.name ~= dirtyItem then
        DBG:Warning(string.format('Refused to consume unexpected %s item for source %d: %s',
            itemType, src, tostring(currentItem.name)))
        return false
    end

    local metadata = containerMetadata(currentItem, nil, itemType)
    local durability = tonumber(metadata.durability) or Config.durability.defaults[itemType]
    local durabilityUsage = math.max(0, tonumber(Config.durability.usage[itemType]) or 0)
    local maxUses = math.max(1, tonumber(Config.usesPerFill[itemType]) or 1)
    local usesLeft = tonumber(currentItem.metadata and currentItem.metadata.usesLeft) or maxUses

    if durabilityUsage > 0 and durability < durabilityUsage then
        DBG:Warning(string.format('%s %d cannot be used by source %d: durability %d%%',
            itemType, currentItem.id, src, durability))
        return false
    end

    local newDurability = math.max(0, durability - durabilityUsage)
    local newUsesLeft = math.max(0, usesLeft - 1)

    if durabilityUsage > 0 and newDurability < durabilityUsage then
        if not removeOneItemById(src, currentItem.id) then
            return false
        end
        if Config.showMessages then
            local messageKey = itemType == 'bucket' and 'brokeBucket' or 'brokeBottle'
            Core.NotifyRightTip(src, _U(messageKey), 4000)
        end
        DBG:Info(string.format('%s %d broke for source %d after use: durability %d%%',
            itemType, currentItem.id, src, newDurability))
        return true
    end

    metadata.durability = newDurability
    if newUsesLeft > 0 then
        metadata.usesLeft = newUsesLeft
        metadata.source = currentItem.metadata and currentItem.metadata.source
        metadata.context = currentItem.metadata and currentItem.metadata.context
        setContainerDescription(metadata, itemType,
            currentItem.metadata and currentItem.metadata.waterType or 'clean')

        local updated = exports.vorp_inventory:setItemMetadata(src, currentItem.id, metadata, 1)
        if not updated then
            DBG:Error(string.format('Failed to update %s %d metadata for source %d',
                itemType, currentItem.id, src))
            return false
        end

        DBG:Info(string.format('Used %s %d for source %d: %d/%d uses, %d%% durability',
            itemType, currentItem.id, src, newUsesLeft, maxUses, newDurability))
        return true
    end

    if not removeOneItemById(src, currentItem.id) then
        return false
    end

    metadata.usesLeft = nil
    setContainerDescription(metadata, itemType, 'empty')
    if not exports.vorp_inventory:canCarryItem(src, emptyItem, 1) then
        DBG:Error(string.format('Could not return empty %s to source %d', itemType, src))
        addInventoryItem(src, currentItem.name, currentItem.metadata)
        return false
    end

    if not addInventoryItem(src, emptyItem, metadata) then
        addInventoryItem(src, currentItem.name, currentItem.metadata)
        return false
    end
    DBG:Info(string.format('Replaced used %s with %s for source %d at %d%% durability',
        itemType, emptyItem, src, newDurability))
    return true
end

local function consumeContainerData(item, itemType)
    local _, src, itemId = usableItemData(item)
    if not src or not itemId then
        return false
    end
    if useOnCooldown(src, itemType) then
        DBG:Info(string.format('Ignored %s use during cooldown for source %d', itemType, src))
        return false
    end

    local consumed = withItemLock(src, itemId, function()
        return consumeContainerUnlocked(item, itemType)
    end)
    if consumed then
        startUseCooldown(src, itemType)
    end
    return consumed
end

---@param playerSource number|string
---@param itemType 'bucket'|'bottle'
---@param itemId? number|string
---@return boolean
local function consumeContainer(playerSource, itemType, itemId)
    local src = tonumber(playerSource)
    if not src or not Core.getUser(src) then
        return false
    end

    if itemType ~= 'bucket' and itemType ~= 'bottle' then
        DBG:Warning(string.format('Source %d requested invalid external container type: %s',
            src, tostring(itemType)))
        return false
    end

    local container
    local targetId = tonumber(itemId)
    if itemId ~= nil and not targetId then
        DBG:Warning(string.format('Source %d supplied invalid external container ID: %s',
            src, tostring(itemId)))
        return false
    end

    if targetId then
        container = getItemInstance(src, targetId)
    elseif itemType == 'bucket' then
        container = exports.vorp_inventory:getItem(src, Config.cleanBucket)
            or exports.vorp_inventory:getItem(src, Config.dirtyBucket)
    else
        container = exports.vorp_inventory:getItem(src, Config.cleanBottle)
            or exports.vorp_inventory:getItem(src, Config.dirtyBottle)
    end

    if not container then
        return false
    end

    return consumeContainerData({
        source = src,
        item = container,
    }, itemType)
end

-- Public server integration for buckets and bottles. bcc-water owns item names,
-- uses, durability, breakage, and empty-container replacement.
exports('ConsumeContainer', consumeContainer)

---@param src number
---@param canteenId number
---@param drinksLeft number
---@param durability number
---@param waterType string
---@return boolean
local function updateCanteenMetadata(src, canteenId, drinksLeft, durability, waterType)
    waterType = waterType or 'clean'
    local waterLabel = waterType == 'dirty' and 'Dirty' or 'Clean'
    local description = _U('canteenDesc') .. '<br>'
        .. _U('drinksLeft') .. ' : ' .. tostring(drinksLeft) .. '/' .. tostring(MaxCanteenDrinks) .. '<br>'
        .. _U('Durability') .. ' : ' .. tostring(durability) .. '%<br>'
        .. 'Water : ' .. waterLabel
    local updated = exports.vorp_inventory:setItemMetadata(src, canteenId, {
        description = description,
        drinksLeft = drinksLeft,
        durability = durability,
        waterType = waterType,
        context = waterType == 'dirty' and purificationContext() or nil,
    }, 1)

    if not updated then
        DBG:Error(string.format('Failed to update canteen %d metadata for source %d', canteenId, src))
        return false
    end

    DBG:Info(string.format('Updated canteen metadata for source %d: Drinks Left = %d, Durability = %d%%', src, drinksLeft,
        durability))
    return true
end

---@param src number
---@param requirements table
---@return boolean
local function consumePurificationItems(src, requirements)
    for _, requirement in ipairs(requirements) do
        local item = exports.vorp_inventory:getItem(src, requirement.name)
        if not item or item.count < requirement.amount then
            DBG:Info(string.format('Source %d is missing purification item %s x%d',
                src, requirement.name, requirement.amount))
            return false
        end
    end

    local removedItems = {}
    for _, requirement in ipairs(requirements) do
        local remaining = requirement.amount
        while remaining > 0 do
            local item = exports.vorp_inventory:getItem(src, requirement.name)
            if not item or not removeOneItemById(src, item.id) then
                for _, removedItem in ipairs(removedItems) do
                    addInventoryItem(src, removedItem)
                end
                return false
            end
            removedItems[#removedItems + 1] = requirement.name
            remaining = remaining - 1
        end
    end

    return true
end

---@param src number
---@param requirements table
local function refundPurificationItems(src, requirements)
    for _, requirement in ipairs(requirements) do
        for _ = 1, requirement.amount do
            addInventoryItem(src, requirement.name)
        end
    end
end

if Config.purification.enabled then
    local purificationEvents = {}
    local pendingPurifications = {}

    local function canBeginPurification(src, methodName, itemId)
        local method = methodName and Config.purification.methods[methodName]
        if not method or not method.enabled then
            return false
        end

        local target = getItemInstance(src, itemId)
        if not target then
            return false
        end

        local isDirtyContainer = target.name == Config.dirtyBottle
            or target.name == Config.dirtyBucket
            or (target.name == Config.canteen and target.metadata
                and target.metadata.waterType == 'dirty')
        if not isDirtyContainer then
            return false
        end

        for _, requirement in ipairs(method.requiredItems or {}) do
            local item = exports.vorp_inventory:getItem(src, requirement.name)
            if not item or item.count < requirement.amount then
                DBG:Info(string.format('Source %d is missing purification item %s x%d',
                    src, requirement.name, requirement.amount))
                return false
            end
        end

        return true
    end

    local function purifyContainer(src, methodName, itemId)
        local method = methodName and Config.purification.methods[methodName]
        if not method or not method.enabled then
            DBG:Warning(string.format('Source %d requested invalid purification method: %s',
                src, tostring(methodName)))
            return
        end

        local targetId = tonumber(itemId)
        if not targetId then
            DBG:Warning(string.format('Source %d supplied an invalid purification item ID', src))
            return
        end

        local target = getItemInstance(src, targetId)
        if not target then
            return
        end

        local itemType
        local cleanItem
        if target.name == Config.dirtyBottle then
            itemType = 'bottle'
            cleanItem = Config.cleanBottle
        elseif target.name == Config.dirtyBucket then
            itemType = 'bucket'
            cleanItem = Config.cleanBucket
        elseif target.name == Config.canteen and target.metadata
                and target.metadata.waterType == 'dirty' then
            itemType = 'canteen'
        else
            DBG:Warning(string.format('Source %d tried to purify a clean or invalid item: %s',
                src, tostring(target.name)))
            return
        end

        local requirements = method.requiredItems or {}
        if not consumePurificationItems(src, requirements) then
            return
        end

        if itemType == 'canteen' then
            local metadata = target.metadata
            if not updateCanteenMetadata(src, target.id,
                    tonumber(metadata.drinksLeft) or 0,
                    tonumber(metadata.durability) or Config.durability.defaults.canteen,
                    'clean') then
                refundPurificationItems(src, requirements)
                return
            end
        else
            local metadata = containerMetadata(target, {
                waterType = 'clean',
                usesLeft = tonumber(target.metadata and target.metadata.usesLeft)
                    or Config.usesPerFill[itemType],
            }, itemType)
            setContainerDescription(metadata, itemType, 'clean')
            if not removeOneItemById(src, target.id) then
                refundPurificationItems(src, requirements)
                return
            end
            if not addInventoryItem(src, cleanItem, metadata) then
                addInventoryItem(src, target.name, target.metadata)
                refundPurificationItems(src, requirements)
                return
            end
        end

        DBG:Info(string.format('Source %d purified %s %d using %s',
            src, itemType, target.id, methodName))
    end

    local function registerPurificationMethod(methodName)
        local eventName = PurifyEventPrefix .. methodName
        purificationEvents[#purificationEvents + 1] = eventName
        exports.vorp_inventory:addAllowedContextMenuEvent(eventName, GetCurrentResourceName())

        AddEventHandler(eventName, function(src, _, itemId)
            local targetId = tonumber(itemId)
            if not targetId then
                DBG:Warning(string.format('Source %d supplied an invalid purification item ID', src))
                return
            end

            if pendingPurifications[src] then
                DBG:Info(string.format('Ignored duplicate purification request from source %d', src))
                return
            end

            if not canBeginPurification(src, methodName, targetId) then
                DBG:Warning(string.format('Source %d cannot begin purification for item %d',
                    src, targetId))
                return
            end

            local duration = math.max(0,
                tonumber(Config.purification.animation and Config.purification.animation.duration) or 3000)
            pendingPurifications[src] = {
                methodName = methodName,
                itemId = targetId,
                expiresAt = GetGameTimer() + duration + 10000,
            }
            TriggerClientEvent('bcc-water:BeginPurification', src, methodName, targetId)
        end)
    end

    for methodName, method in pairs(Config.purification.methods) do
        if method.enabled then
            registerPurificationMethod(methodName)
        end
    end

    RegisterNetEvent('bcc-water:CompletePurification', function(methodName, itemId)
        local src = source
        local pending = pendingPurifications[src]
        pendingPurifications[src] = nil

        if not pending or pending.expiresAt < GetGameTimer()
                or pending.methodName ~= methodName
                or pending.itemId ~= tonumber(itemId) then
            DBG:Warning(string.format('Source %d submitted an invalid purification completion', src))
            return
        end

        withItemLock(src, pending.itemId, function()
            purifyContainer(src, pending.methodName, pending.itemId)
        end)
    end)

    RegisterNetEvent('bcc-water:CancelPurification', function()
        pendingPurifications[source] = nil
    end)

    AddEventHandler('playerDropped', function()
        pendingPurifications[source] = nil
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        if resourceName == GetCurrentResourceName() then
            for _, eventName in ipairs(purificationEvents) do
                exports.vorp_inventory:removeAllowedContextMenuEvent(eventName, resourceName)
            end
        end
    end)
end

---@param data table
---@return boolean used
---@return boolean? dirty
local function useCanteen(data)
    local _, src, itemId = usableItemData(data)
    if not src then
        DBG:Warning('Refused canteen use without a valid source')
        return false
    end

    local canteen = itemId and getItemInstance(src, itemId) or nil
    if not canteen or canteen.name ~= Config.canteen then
        DBG:Warning(string.format('Refused invalid canteen %s for source %d', tostring(itemId), src))
        return false
    end

    local metadata = canteen.metadata or {}
    local drinksLeft = tonumber(metadata.drinksLeft) or 0
    local durability = tonumber(metadata.durability) or Config.durability.defaults.canteen
    local canteenUsage = math.max(0, tonumber(Config.durability.usage.canteen) or 0)

    if drinksLeft <= 0 then
        Core.NotifyRightTip(src, _U('emptyCanteen'), 4000)
        DBG:Info(string.format('Canteen empty for source: %d', src))
        return false
    end

    if durability < canteenUsage then
        DBG:Warning(string.format('Canteen %d cannot be used by source %d: durability %d%%',
            canteen.id, src, durability))
        return false
    end

    local newDurability = math.max(0, durability - canteenUsage)
    local newDrinksLeft = drinksLeft - 1

    if newDurability < canteenUsage then
        if not removeOneItemById(src, canteen.id) then
            return false
        end
        if Config.showMessages then
            Core.NotifyRightTip(src, _U('brokeCanteen'), 4000)
        end
        DBG:Info(string.format('Canteen %d broke for source %d after use', canteen.id, src))
    else
        if not updateCanteenMetadata(src, canteen.id, newDrinksLeft, newDurability, metadata.waterType or 'clean') then
            return false
        end
        DBG:Info(string.format(
            'Used canteen %d for source %d: Drinks Left = %d, New Durability = %d%%',
            canteen.id, src, newDrinksLeft, newDurability))
    end

    return true, metadata.waterType == 'dirty'
end

Core.Callback.Register('bcc-water:GetCanteenLevel', function(source, cb, pump)
    local src = source
    local user = Core.getUser(src)

    if not user then
        DBG:Error(string.format('User not found for source: %d', src))
        return cb(false)
    end
    local itemCanteen = Config.canteen
    local canteen = exports.vorp_inventory:getItem(src, itemCanteen)

    if not canteen then
        Core.NotifyRightTip(src, _U('needCanteen'), 4000)
        DBG:Warning(string.format('Canteen not found for source: %d', src))
        return cb(false)
    end
    local meta = canteen.metadata or {}
    local isNewCanteen = next(meta) == nil
    local waterType = (pump or not Config.wild.dirtyItems) and 'clean' or 'dirty'

    if isNewCanteen then
        if not updateCanteenMetadata(src, canteen.id, MaxCanteenDrinks,
                Config.durability.defaults.canteen, waterType) then
            return cb(false)
        end
        DBG:Info(string.format('Filled new canteen for source: %d', src))
    else
        local drinksLeft = tonumber(meta.drinksLeft) or 0
        local durability = tonumber(meta.durability) or Config.durability.defaults.canteen
        if drinksLeft > 0 and meta.waterType == 'dirty' then
            -- Adding clean water does not purify dirty water already present.
            waterType = 'dirty'
        end
        if drinksLeft < MaxCanteenDrinks then
            if not updateCanteenMetadata(src, canteen.id, MaxCanteenDrinks, durability, waterType) then
                return cb(false)
            end
            DBG:Info(string.format('Refilled canteen for source: %d', src))
        else
            Core.NotifyRightTip(src, _U('fullCanteen'), 4000)
            DBG:Info(string.format('Canteen already full for source: %d', src))
            return cb(false)
        end
    end
    cb(true)
end)

---@param itemType string
---@param itemAmount number
---@param pump boolean
Core.Callback.Register('bcc-water:GetItem', function(source, cb, itemType, itemAmount, pump)
    local src = source
    local user = Core.getUser(src)

    if not user then
        DBG:Error(string.format('User not found for source: %d', src))
        return cb(false)
    end

    if itemType ~= 'bucket' and itemType ~= 'bottle' then
        DBG:Warning(string.format('Source %d requested invalid container type: %s', src, tostring(itemType)))
        return cb(false)
    end

    local amount = tonumber(itemAmount)
    local configType = pump == true and Config.pump or Config.wild
    local multiConfig = configType.multi
    local multiEnabled = itemType == 'bucket' and multiConfig.buckets or multiConfig.bottles
    local maxAmount = multiEnabled
        and (itemType == 'bucket' and multiConfig.bucketAmount or multiConfig.bottleAmount)
        or 1
    if not amount or amount ~= math.floor(amount) or amount < 1 or amount > maxAmount then
        DBG:Warning(string.format('Source %d requested invalid %s fill amount: %s',
            src, itemType, tostring(itemAmount)))
        return cb(false)
    end
    itemAmount = amount
    pump = pump == true

    if not WaterInventory.startFillCooldown(src) then
        DBG:Warning(string.format('Source %d requested container fills too quickly', src))
        return cb(false)
    end


    local emptyItem = itemType == 'bucket' and Config.emptyBucket or Config.emptyBottle
    local notification = itemType == 'bucket' and _U('needBucket') or _U('needBottle')
    local item = exports.vorp_inventory:getItem(src, emptyItem)
    if not item or item.count < itemAmount then
        Core.NotifyRightTip(src, notification, 4000)
        DBG:Warning(string.format('Source %d does not have the required item: %s', src, emptyItem))
        return cb(false)
    end

    for i = 1, itemAmount do
        -- Convert each container individually so its durability follows it.
        -- Removing by name in bulk loses the metadata belonging to each item.
        local emptyContainer = exports.vorp_inventory:getItem(src, emptyItem)
        if not emptyContainer then
            DBG:Error(string.format('Empty container disappeared during fill for source %d: %s', src, emptyItem))
            return cb(false)
        end

        local sourceType = pump and 'pump' or 'wild'
        local wildDirty  = not pump and Config.wild.dirtyItems
        local metadata = containerMetadata(emptyContainer, { source = sourceType }, itemType)
        metadata.waterType = wildDirty and 'dirty' or 'clean'
        metadata.usesLeft = Config.usesPerFill[itemType]
        metadata.context = wildDirty and purificationContext() or nil
        setContainerDescription(metadata, itemType, metadata.waterType)
        if not removeOneItemById(src, emptyContainer.id) then
            return cb(false)
        end

        if itemType == 'bottle' then
            local itemName = (pump or not wildDirty) and Config.cleanBottle or Config.dirtyBottle
            if not addInventoryItem(src, itemName, metadata) then
                addInventoryItem(src, emptyItem, emptyContainer.metadata)
                return cb(false)
            end
            DBG:Info(string.format('Added item to source %d: %s, Pump: %s, WildDirty: %s', src, itemName, tostring(pump), tostring(wildDirty)))
        elseif itemType == 'bucket' then
            local itemName = (pump or not wildDirty) and Config.cleanBucket or Config.dirtyBucket
            if not addInventoryItem(src, itemName, metadata) then
                addInventoryItem(src, emptyItem, emptyContainer.metadata)
                return cb(false)
            end
            DBG:Info(string.format('Added item to source %d: %s, Pump: %s, WildDirty: %s', src, itemName, tostring(pump), tostring(wildDirty)))
        end
    end
    cb(true)
end)

exports.vorp_inventory:registerUsableItem(Config.canteen, function(data)
    local src = data.source
    exports.vorp_inventory:closeInventory(src)

    if useOnCooldown(src, 'canteen') then
        DBG:Info(string.format('Ignored canteen use during cooldown for source %d', src))
        return
    end

    local _, _, itemId = usableItemData(data)
    if not itemId then
        return
    end
    local used, dirty = withItemLock(src, itemId, function()
        return useCanteen(data)
    end)
    if used then
        startUseCooldown(src, 'canteen')
        TriggerClientEvent('bcc-water:UseCanteen', src, dirty)
    end
end, GetCurrentResourceName())

if Config.useable.cleanBottle then
    DBG:Info('Registering clean bottle as usable item')
    exports.vorp_inventory:registerUsableItem(Config.cleanBottle, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)
        if not consumeContainerData(data, 'bottle') then
            return
        end
        TriggerClientEvent('bcc-water:DrinkBottle', src, false)
    end, GetCurrentResourceName())
end

if Config.useable.dirtyBottle then
    DBG:Info('Registering dirty bottle as usable item')
    exports.vorp_inventory:registerUsableItem(Config.dirtyBottle, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)
        if not consumeContainerData(data, 'bottle') then
            return
        end
        TriggerClientEvent('bcc-water:DrinkBottle', src, true)
    end, GetCurrentResourceName())
end

if Config.useable.cleanBucket then
    DBG:Info('Registering clean bucket as usable item')
    exports.vorp_inventory:registerUsableItem(Config.cleanBucket, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)
        if not consumeContainerData(data, 'bucket') then
            return
        end
        TriggerClientEvent('bcc-water:DrinkBucket', src, false)
    end, GetCurrentResourceName())
end

if Config.useable.dirtyBucket then
    DBG:Info('Registering dirty bucket as usable item')
    exports.vorp_inventory:registerUsableItem(Config.dirtyBucket, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)
        if not consumeContainerData(data, 'bucket') then
            return
        end
        TriggerClientEvent('bcc-water:DrinkBucket', src, true)
    end, GetCurrentResourceName())
end
