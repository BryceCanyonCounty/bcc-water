VORP = exports.vorp_inventory:vorp_inventoryApi()

local VorpCore = {}

TriggerEvent("getCore",function(core)
    VorpCore = core
end)


Citizen.CreateThread(function()
	Citizen.Wait(2000)
	VORP.RegisterUsableItem("canteenempty", function(data)
		TriggerClientEvent('green:StartFilling', data.source)
	end)
end)


Citizen.CreateThread(function()
    local item2 = "canteen_75"
	Citizen.Wait(2000)
	VORP.RegisterUsableItem("canteen", function(data)
		VORP.subItem(data.source, "canteen", 1)
        VORP.addItem(data.source, item2, 1)
		TriggerClientEvent('green:drink', data.source)
	end)
end)

Citizen.CreateThread(function()
    local item3 = "canteen_50"
	Citizen.Wait(2000)
	VORP.RegisterUsableItem("canteen_75", function(data)
		VORP.subItem(data.source, "canteen_75", 1)
        VORP.addItem(data.source, item3, 1)
		TriggerClientEvent('green:drink', data.source)
	end)
end)

Citizen.CreateThread(function()
    local item4 = "canteen_25"
	Citizen.Wait(2000)
	VORP.RegisterUsableItem("canteen_50", function(data)
		VORP.subItem(data.source, "canteen_50", 1)
        VORP.addItem(data.source, item4, 1)
		TriggerClientEvent('green:drink', data.source)
	end)
end)

Citizen.CreateThread(function()
    local item5 = "canteenempty"
	Citizen.Wait(2000)
	VORP.RegisterUsableItem("canteen_25", function(data)
		VORP.subItem(data.source, "canteen_25", 1)
        VORP.addItem(data.source, item5, 1)
		TriggerClientEvent('green:drink', data.source)
	end)
end)

RegisterNetEvent("fillup")
AddEventHandler("fillup", function()
    local item = "canteen"
    local r = 1
    local _source = source 
    if r then
		VORP.subItem(_source, "canteenempty", 1)
        VORP.addItem(_source, item, 1)
        TriggerClientEvent("vorp:TipBottom", _source, Config.fullup, 6000)
    end
end)

RegisterServerEvent("checkcanteen")
AddEventHandler("checkcanteen", function(rock)
	local _source = source
	local Character = VorpCore.getUser(_source).getUsedCharacter
	local empty = VORP.getItemCount(_source, 'canteenempty')

	if empty > 0 then
		TriggerClientEvent("canteencheck", _source)
	else
		TriggerClientEvent("vorp:TipRight", _source, Config.cantfill, 2000)
	end
end)

	
