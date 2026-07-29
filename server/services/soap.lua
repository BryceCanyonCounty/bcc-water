Core.Callback.Register('bcc-water:CheckSoapItems', function(source, cb)
    local src = source
    if not Core.getUser(src) then
        DBG:Error(string.format('User not found for source: %d', src))
        return cb(false, nil)
    end

    for _, soapItem in ipairs(Config.soapItem) do
        local item = exports.vorp_inventory:getItem(src, soapItem)
        if item and item.count > 0 then
            DBG:Info(string.format('CheckSoapItems for source %d, found soap: %s', src, soapItem))
            return cb(true, soapItem)
        end
    end

    DBG:Info(string.format('CheckSoapItems for source %d: no soap items found', src))
    cb(false, nil)
end)

Core.Callback.Register('bcc-water:UseSoapItem', function(source, cb)
    local src = source
    if not Core.getUser(src) then
        DBG:Error(string.format('User not found for source: %d', src))
        return cb(false, nil)
    end

    local consumeSoap = Config.consumeSoap == true
    local maxUses = math.max(1, tonumber(Config.soapUses) or 1)

    for _, soapItem in ipairs(Config.soapItem) do
        local item = exports.vorp_inventory:getItem(src, soapItem)
        if item and item.count > 0 then
            if not consumeSoap then
                DBG:Info(string.format('Used reusable soap item %s for source %d', soapItem, src))
                return cb(true, soapItem)
            end

            local currentUses = tonumber(item.metadata and item.metadata.uses) or 0
            currentUses = currentUses + 1

            if currentUses >= maxUses then
                if not WaterInventory.removeOneItemById(src, item.id) then
                    return cb(false, soapItem)
                end
                DBG:Info(string.format('Soap item %s used up for source %d after %d uses',
                    soapItem, src, currentUses))
                return cb(true, soapItem)
            end

            local metadata = item.metadata or {}
            metadata.uses = currentUses
            metadata.description = _U('soapDurability') .. ': '
                .. tostring(currentUses) .. '/' .. tostring(maxUses)

            local updated = exports.vorp_inventory:setItemMetadata(src, item.id, metadata, 1)
            if not updated then
                DBG:Error(string.format('Failed to update soap item %s metadata for source %d',
                    soapItem, src))
                return cb(false, soapItem)
            end

            DBG:Info(string.format('Updated soap item %s for source %d: %d/%d uses',
                soapItem, src, currentUses, maxUses))
            return cb(true, soapItem)
        end
    end

    DBG:Warning(string.format('Source %d does not have a configured soap item', src))
    cb(false, nil)
end)
