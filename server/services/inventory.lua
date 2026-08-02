WaterInventory = {}

local activeItemOperations = {}
local useCooldowns = {}
local fillCooldowns = {}

function WaterInventory.usableItemData(data)
    local item = data and data.item
    local src = data and data.source
    local itemId = item and item.id
    return item, src, itemId
end

function WaterInventory.withItemLock(src, itemId, operation)
    local key = tostring(src) .. ':' .. tostring(itemId)
    if activeItemOperations[key] then
        DBG:Warning(string.format('Blocked concurrent operation on item %s for source %d',
            tostring(itemId), src))
        return false
    end

    activeItemOperations[key] = true
    local results = table.pack(xpcall(operation, debug.traceback))
    activeItemOperations[key] = nil

    if not results[1] then
        DBG:Error(string.format('Item operation failed for source %d: %s', src, tostring(results[2])))
        return false
    end

    return table.unpack(results, 2, results.n)
end

function WaterInventory.useOnCooldown(src, itemType)
    local now = GetGameTimer()
    local cooldowns = useCooldowns[src]
    return cooldowns and cooldowns[itemType] and cooldowns[itemType] > now or false
end

function WaterInventory.startUseCooldown(src, itemType)
    useCooldowns[src] = useCooldowns[src] or {}
    local duration = math.max(0, tonumber(Config.useCooldowns[itemType]) or 0)
    useCooldowns[src][itemType] = GetGameTimer() + duration
end

function WaterInventory.startFillCooldown(src)
    local now = os.time()
    if fillCooldowns[src] and fillCooldowns[src] > now then
        return false
    end
    fillCooldowns[src] = now + 2
    return true
end

function WaterInventory.getItemInstance(src, itemId)
    local item = exports.vorp_inventory:getItemById(src, itemId)
    if not item then
        DBG:Error(string.format('Item %s was not found for source %d', tostring(itemId), src))
        return nil
    end
    return item
end

function WaterInventory.removeOneItemById(src, itemId)
    local removed = exports.vorp_inventory:subItemById(src, itemId, nil, nil, 1)
    if not removed then
        DBG:Error(string.format('Failed to remove item %s for source %d', tostring(itemId), src))
        return false
    end
    return true
end

function WaterInventory.addItem(src, itemName, metadata)
    local added = exports.vorp_inventory:addItem(src, itemName, 1, metadata)
    if added == false then
        DBG:Error(string.format('Failed to add item %s for source %d', itemName, src))
        return false
    end
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    fillCooldowns[src] = nil
    useCooldowns[src] = nil

    local prefix = tostring(src) .. ':'
    for key in pairs(activeItemOperations) do
        if key:sub(1, #prefix) == prefix then
            activeItemOperations[key] = nil
        end
    end
end)
