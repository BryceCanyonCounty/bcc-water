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
            local used = WaterInventory.withItemLock(src, item.id, function()
                local currentItem = WaterInventory.getItemInstance(src, item.id)
                if not currentItem or currentItem.name ~= soapItem then
                    return false
                end

                if not consumeSoap then
                    DBG:Info(string.format('Used reusable soap item %s for source %d', soapItem, src))
                    return true
                end

                local currentUses = (tonumber(currentItem.metadata and currentItem.metadata.uses) or 0) + 1
                if currentUses >= maxUses then
                    if not WaterInventory.removeOneItemById(src, currentItem.id) then
                        return false
                    end
                    DBG:Info(string.format('Soap item %s used up for source %d after %d uses',
                        soapItem, src, currentUses))
                    return true
                end

                local metadata = currentItem.metadata or {}
                metadata.uses = currentUses
                metadata.description = _U('soapDurability') .. ': '
                    .. tostring(currentUses) .. '/' .. tostring(maxUses)

                local updated = exports.vorp_inventory:setItemMetadata(
                    src, currentItem.id, metadata, 1)
                if not updated then
                    DBG:Error(string.format('Failed to update soap item %s metadata for source %d',
                        soapItem, src))
                    return false
                end

                DBG:Info(string.format('Updated soap item %s for source %d: %d/%d uses',
                    soapItem, src, currentUses, maxUses))
                return true
            end)

            return cb(used == true, soapItem)
        end
    end

    DBG:Warning(string.format('Source %d does not have a configured soap item', src))
    cb(false, nil)
end)
