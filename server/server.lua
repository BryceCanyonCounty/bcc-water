local VORPcore = {}
local VORPInv = {}
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

VORPInv = exports.vorp_inventory:vorp_inventoryApi()

RegisterNetEvent("oss_water:CheckIfEmpty")
AddEventHandler("oss_water:CheckIfEmpty", function()
	local _source = source
	local empty = VORPInv.getItemCount(_source, 'canteenempty')
	if empty > 0 then
		TriggerClientEvent("oss_water:CanteenEmpty", _source)
	else
		VORPcore.NotifyRightTip(_source, _U("not_empty"), 5000)
	end
end)

RegisterNetEvent("oss_water:FillCanteen")
AddEventHandler("oss_water:FillCanteen", function()
    local _source = source
	VORPInv.subItem(_source, "canteenempty", 1)
	VORPInv.addItem(_source, "canteen", 1)
	VORPcore.NotifyRightTip(_source, _U("full"), 5000)
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteenempty", function(data)
		TriggerClientEvent('oss_water:StartFilling', data.source)
	end)
end)


Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteen", function(data)
		local _source = data.source
		VORPInv.subItem(_source, "canteen", 1)
		VORPInv.addItem(_source, "canteen_75", 1)
		TriggerClientEvent('oss_water:Drink', _source)
		Wait(15000)
		VORPcore.NotifyRightTip(_source, _U("canteen_75"), 5000)
	end)
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteen_75", function(data)
		local _source = data.source
		VORPInv.subItem(_source, "canteen_75", 1)
        VORPInv.addItem(_source, "canteen_50", 1)
		TriggerClientEvent('oss_water:Drink', _source)
		Wait(15000)
		VORPcore.NotifyRightTip(_source, _U("canteen_50"), 5000)
	end)
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteen_50", function(data)
		local _source = data.source
		VORPInv.subItem(_source, "canteen_50", 1)
        VORPInv.addItem(_source, "canteen_25", 1)
		TriggerClientEvent('oss_water:Drink', _source)
		Wait(15000)
		VORPcore.NotifyRightTip(_source, _U("canteen_25"), 5000)
	end)
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORPInv.RegisterUsableItem("canteen_25", function(data)
		local _source = data.source
		VORPInv.subItem(_source, "canteen_25", 1)
        VORPInv.addItem(_source, "canteenempty", 1)
		TriggerClientEvent('oss_water:Drink', _source)
		Wait(15000)
		VORPcore.NotifyRightTip(_source, _U("canteen_empty"), 5000)
	end)
end)
