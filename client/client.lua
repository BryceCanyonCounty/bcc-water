local VORPcore = {}
local VORPutils = {}
local WaterPump
local Canteen
local Filling = false

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

TriggerEvent("getUtils", function(utils)
    VORPutils = utils
end)

Citizen.CreateThread(function()
    local pumps = VORPutils.Prompts:SetupPromptGroup()
    WaterPump = pumps:RegisterPrompt(_U("fill"), Config.pumpKey, 1, 1, true, 'click')
    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        local Coords = GetEntityCoords(player)
        local pumpLoc = Citizen.InvokeNative(0xBFA48E2FF417213F, Coords.x, Coords.y, Coords.z, 1.0, GetHashKey("p_waterpump01x"), 0) -- DoesObjectOfTypeExistAtCoords
        if pumpLoc and IsPedOnFoot(player) then
            pumps:ShowGroup("Water Pump")
            if WaterPump:HasCompleted() then
                TriggerServerEvent('oss_water:CheckEmpty')
            end
        end
    end
end)

RegisterNetEvent('oss_water:PumpFill')
AddEventHandler('oss_water:PumpFill', function()
    local player = PlayerPedId()
    DoPromptAnim("amb_work@prop_human_pump_water@female_b@idle_a", "idle_a");
    Wait(10000)
    ClearPedTasks(player, false, false)
    VORPcore.NotifyRightTip(_U("full"), 5000)
end)

function DoPromptAnim(dict, anim)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), dict, anim, 1.0, 1.0, -1, 17, 1.0, false, false, false)
end

RegisterNetEvent('oss_water:Drink')
AddEventHandler('oss_water:Drink', function(message)
    local player = PlayerPedId()
    if Citizen.InvokeNative(0x6D9F5FAA7488BA46, player) then -- IsPedMale
        TaskStartScenarioInPlace(player, GetHashKey('WORLD_HUMAN_DRINK_FLASK'), -1, true, false, false, false)
        Wait(15000)
        ClearPedTasks(player, false, false)
    else
        TaskStartScenarioInPlace(player, GetHashKey('WORLD_HUMAN_COFFEE_DRINK'), -1, true, false, false, false)
        Wait(15000)
        ClearPedTasks(player, false, false)
        Wait(5000)
        Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
    end
    if message == 4 then
        VORPcore.NotifyRightTip(_U("level_4"), 5000)
    elseif message == 3 then
        VORPcore.NotifyRightTip(_U("level_3"), 5000)
    elseif message == 2 then
        VORPcore.NotifyRightTip(_U("level_2"), 5000)
    elseif message == 1 then
        VORPcore.NotifyRightTip(_U("level_1"), 5000)
    end
    TriggerEvent('vorpmetabolism:changeValue', "Thirst", Config.thirst)
end)

RegisterNetEvent('oss_water:StartFilling')
AddEventHandler('oss_water:StartFilling', function()
    if not Filling then
        Filling = true
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local water = Citizen.InvokeNative(0x5BA7A68A346A5A91, coords.x, coords.y, coords.z) -- GetWaterMapZoneAtCoords
        local foundWater = false
        for k, _ in pairs(Config.waterTypes) do
            if water == Config.waterTypes[k]["waterhash"] and IsPedOnFoot(player) then
                foundWater = true
                
                CrouchAnimAndAttach()
                Wait(15000)
                ClearPedTasks(player, false, false)
                DeleteObject(Canteen)
                DeleteEntity(Canteen)
                TriggerServerEvent('oss_water:FillCanteen')
                break
            end
        end
        Filling = false
        if foundWater == false then
            VORPcore.NotifyRightTip(_U("cantfill"), 5000)
        end
    end
end)

function CrouchAnimAndAttach()
    local dict = "script_rc@cldn@ig@rsc2_ig1_questionshopkeeper"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local boneIndex = GetEntityBoneIndexByName(player, "SKEL_R_HAND")
    local modelHash = GetHashKey("p_cs_canteen_hercule")
    LoadModel(modelHash)
    Canteen = CreateObject(modelHash, coords.x, coords.y, coords.z, true, false, false)
    SetEntityVisible(Canteen, true)
    SetEntityAlpha(Canteen, 255, false)
    Citizen.InvokeNative(0x283978A15512B2FE, Canteen, true) -- SetRandomOutfitVariation
    SetModelAsNoLongerNeeded(modelHash)
    AttachEntityToEntity(Canteen, player, boneIndex, 0.12, 0.09, -0.05, 306.0, 18.0, 0.0, false, false, false, true, 2, true)
    TaskPlayAnim(player, dict, "inspectfloor_player", 1.0, 1.0, -1, 17, 1.0, false, false, false)
end

function LoadModel(model)
    local attempts = 0
    while attempts < 100 and not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(100)
        attempts = attempts + 1
    end
    return IsModelValid(model)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    ClearPedTasksImmediately(PlayerPedId())
    WaterPump:DeletePrompt()
end)