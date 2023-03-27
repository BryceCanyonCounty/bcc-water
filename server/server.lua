local VORPcore = {}
local VORPInv = {}
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

VORPInv = exports.vorp_inventory:vorp_inventoryApi()

RegisterNetEvent("oss_water:CheckEmpty")
AddEventHandler("oss_water:CheckEmpty", function()
	local _source = source
    local canteen = VORPInv.getItem(_source, "canteen")
    if canteen ~= nil then
        local meta = canteen["metadata"]
        if next(meta) == nil then
            VORPInv.subItem(_source, "canteen", 1, {})
            VORPInv.addItem(_source, "canteen", 1, {description = "Level : Full", level = 5})
        else
            local level = meta.level
            if level == 1 then
                VORPInv.subItem(_source, "canteen", 1, meta)
                VORPInv.addItem(_source, "canteen", 1, {description = "Level : Full", level = 5})
            else
                VORPcore.NotifyRightTip(_source, _U("not_empty"), 5000)
                TriggerClientEvent('oss_water:Filling', _source)
                return
            end
        end
        TriggerClientEvent("oss_water:FillCanteen", _source)
    else
        VORPcore.NotifyRightTip(_source, _U("needcanteen"), 5000)
    end
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteen", function(data)
		local _source = data.source
        TriggerClientEvent('oss_water:UseCanteen', _source, data)
	end)
end)

RegisterNetEvent("oss_water:UpdateCanteen")
AddEventHandler("oss_water:UpdateCanteen", function(data)
    local _source = data.source
    local canteen = VORPInv.getItem(_source, "canteen")
    local meta = canteen["metadata"]
    local level = meta.level
    local message = nil
    local canteenUpdate = {
        [1] = function()
            VORPcore.NotifyRightTip(_source, _U("level_1"), 5000)
        end,
        [2] = function()
            message = 1
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level : Empty", level = 1})
        end,
        [3] = function()
            message = 2
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level : 25%", level = 2})
        end,
        [4] = function()
            message = 3
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level : 50%", level = 3})
        end,
        [5] = function()
            message = 4
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level : 75%", level = 4})
        end
    }
        if canteenUpdate[level] then
            canteenUpdate[level]()
        end
        if level == nil then
            VORPcore.NotifyRightTip(_source, _U("level_1"), 5000)
            return
        elseif level > 1 then
            TriggerClientEvent('oss_water:Drink', _source, message)
        end
end)
