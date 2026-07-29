local sickPlayers = {}
local pendingAntidotes = {}

local function getCharacterId(src)
    local user = Core.getUser(src)
    if not user then
        DBG:Error(string.format('User not found for source: %d', src))
        return nil
    end

    local character = user.getUsedCharacter
    return character and character.charIdentifier or nil
end

Core.Callback.Register('bcc-water:RollSickness', function(source, cb)
    local src = source
    local charid = getCharacterId(src)
    if not charid then
        return cb(false)
    end

    local deadline = sickPlayers[charid]
    if deadline then
        if deadline <= os.time() then
            TriggerClientEvent('bcc-water:ForceSicknessDeath', src)
        end
        return cb(false)
    end

    local chance = tonumber(Config.sickness.chance) or 0
    local becameSick = chance > 0 and math.random(1, 100) <= chance
    if becameSick then
        sickPlayers[charid] = os.time() + math.max(1, tonumber(Config.sickness.duration) or 1)
        DBG:Info(string.format('Character ID %d became sick', charid))
    end

    cb(becameSick)
end)

RegisterNetEvent('bcc-water:ClearSickness', function()
    local src = source
    local charid = getCharacterId(src)
    if not charid then
        return
    end

    local playerPed = GetPlayerPed(src)
    local isDead = playerPed and playerPed > 0 and GetEntityHealth(playerPed) <= 0
    if sickPlayers[charid] and isDead then
        sickPlayers[charid] = nil
        DBG:Info(string.format('Cleared sickness after death for character ID: %d', charid))
    else
        DBG:Warning(string.format('Refused sickness clear without confirmed death for character ID: %d', charid))
    end
end)

Core.Callback.Register('bcc-water:CheckSickness', function(source, cb)
    local src = source
    local charid = getCharacterId(src)
    if not charid then
        return cb(false)
    end

    local deadline = sickPlayers[charid]
    if deadline then
        local remaining = math.max(0, deadline - os.time())
        DBG:Info(string.format('Sickness detected for character ID %d: %d seconds remaining',
            charid, remaining))
        if remaining == 0 then
            TriggerClientEvent('bcc-water:ForceSicknessDeath', src)
            return cb(false)
        end
        return cb({ sick = true, remaining = remaining })
    end

    DBG:Info(string.format('No sickness detected for character ID %d', charid))
    return cb(false)
end)

local function registerAntidote(antidoteItem)
    DBG:Info(string.format('Registering antidote item as usable: %s', antidoteItem))
    exports.vorp_inventory:registerUsableItem(antidoteItem, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)

        local charid = getCharacterId(src)
        local deadline = charid and sickPlayers[charid]
        if not charid or not deadline then
            DBG:Info(string.format('Source %d tried to use an antidote while not sick', src))
            return
        end
        if deadline <= os.time() then
            TriggerClientEvent('bcc-water:ForceSicknessDeath', src)
            DBG:Info(string.format('Source %d tried to use an antidote after the sickness deadline', src))
            return
        end

        local _, _, itemId = WaterInventory.usableItemData(data)
        local antidote = itemId and WaterInventory.getItemInstance(src, itemId) or nil
        if not antidote or antidote.name ~= antidoteItem then
            DBG:Warning(string.format('Refused invalid antidote %s for source %d', tostring(itemId), src))
            return
        end

        if pendingAntidotes[src] then
            DBG:Info(string.format('Ignored duplicate antidote use from source %d', src))
            return
        end

        local duration = math.max(0, tonumber(Config.antidoteAnimation.duration) or 2000)
        pendingAntidotes[src] = {
            itemId = antidote.id,
            itemName = antidoteItem,
            charid = charid,
            expiresAt = GetGameTimer() + duration + 10000,
        }
        TriggerClientEvent('bcc-water:BeginAntidote', src, antidote.id)
    end, GetCurrentResourceName())
end

if Config.useable.antidotes then
    for _, antidoteItem in ipairs(Config.antidoteItems) do
        registerAntidote(antidoteItem)
    end
end

RegisterNetEvent('bcc-water:CompleteAntidote', function(itemId)
    local src = source
    local pending = pendingAntidotes[src]
    pendingAntidotes[src] = nil

    if not pending or pending.expiresAt < GetGameTimer()
            or pending.itemId ~= tonumber(itemId) then
        DBG:Warning(string.format('Source %d submitted an invalid antidote completion', src))
        return
    end

    local deadline = sickPlayers[pending.charid]
    local currentCharid = getCharacterId(src)
    if currentCharid ~= pending.charid then
        DBG:Warning(string.format('Source %d changed character during antidote use', src))
        return
    end
    if not deadline or deadline <= os.time() then
        if deadline then
            TriggerClientEvent('bcc-water:ForceSicknessDeath', src)
        end
        return
    end

    WaterInventory.withItemLock(src, pending.itemId, function()
        local antidote = WaterInventory.getItemInstance(src, pending.itemId)
        if not antidote or antidote.name ~= pending.itemName then
            DBG:Warning(string.format('Refused changed antidote %s for source %d',
                tostring(pending.itemId), src))
            return false
        end
        if not WaterInventory.removeOneItemById(src, antidote.id) then
            return false
        end

        sickPlayers[pending.charid] = nil
        TriggerClientEvent('bcc-water:CureSickness', src)
        DBG:Info(string.format('Antidote %d cured character ID %d',
            antidote.id, pending.charid))
        return true
    end)
end)

RegisterNetEvent('bcc-water:CancelAntidote', function()
    pendingAntidotes[source] = nil
end)

AddEventHandler('playerDropped', function()
    pendingAntidotes[source] = nil
end)
