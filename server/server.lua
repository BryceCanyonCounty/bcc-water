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
            VORPInv.addItem(_source, "canteen", 1, {description = "Level: Full", level = 5})
            TriggerClientEvent("oss_water:CanteenEmpty", _source)
        else
            local level = meta.level
            if level == 1 then
                VORPInv.subItem(_source, "canteen", 1, meta)
                VORPInv.addItem(_source, "canteen", 1, {description = "Level: Full", level = 5})
                TriggerClientEvent("oss_water:CanteenEmpty", _source)
            else
                VORPcore.NotifyRightTip(_source, _U("not_empty"), 5000)
            end
        end
    else
        VORPcore.NotifyRightTip(_source, _U("needcanteen"), 5000)
    end
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteen", function(data)
		local _source = data.source
        local canteen = VORPInv.getItem(_source, "canteen")
        local meta = canteen["metadata"]
        local level = meta.level
        if level == 5 then
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level: 75%", level = 4})
            TriggerClientEvent("oss_water:Drink", _source, "level4")
        elseif level == 4 then
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level: 50%", level = 3})
            TriggerClientEvent("oss_water:Drink", _source, "level3")
        elseif level == 3 then
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen", 1, {description = "Level: 25%", level = 2})
            TriggerClientEvent("oss_water:Drink", _source, "level2")
        elseif level == 2 then
            VORPInv.subItem(_source, "canteen", 1, meta)
            VORPInv.addItem(_source, "canteen_empty", 1, {description = "Level: Empty", level = 1})
            TriggerClientEvent("oss_water:Drink", _source, "level1")
        end
	end)
end)
