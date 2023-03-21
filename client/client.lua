local VORPcore = {}
local Canteen
local Filling = false

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local player = PlayerPedId()
        local Coords = GetEntityCoords(player)
        local waterpump = DoesObjectOfTypeExistAtCoords(Coords.x, Coords.y, Coords.z, 1.0, GetHashKey("p_waterpump01x"), 0) -- prop required to interact
        if waterpump and IsPedOnFoot(player) then
            DrawTxt("Fill Canteen ~t6~[ENTER]", 0.50, 0.95, 0.7, 0.5, true, 255, 255, 255, 255, true)
            if IsControlJustPressed(0, 0xC7B5340A) then
                TriggerServerEvent('oss_water:CheckIfEmpty')
            end
        end
    end
end)

RegisterNetEvent('oss_water:CanteenEmpty')
AddEventHandler('oss_water:CanteenEmpty', function()
    DoPromptAnim("amb_work@prop_human_pump_water@female_b@idle_a", "idle_a", 2);
    Wait(10000)
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent("oss_water:FillCanteen")
end)

function DoPromptAnim(dict, anim, loop)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), dict, anim, 1.0, 1.0, -1, 17, 1.0, false, false, false)
end

RegisterNetEvent('oss_water:StartFilling')
AddEventHandler('oss_water:StartFilling', function()
    if not Filling then
        Filling = true
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local water = Citizen.InvokeNative(0x5BA7A68A346A5A91, coords.x, coords.y, coords.z) -- GetWaterMapZoneAtCoords
        local foundWater = false
        for k, _ in pairs(Config.waterTypes) do
            if water == Config.waterTypes[k]["waterhash"] then
                foundWater = true
                CrouchAnimAndAttach()
                VORPcore.NotifyRightTip(_U("filling"), 5000)
                Wait(15000)
                ClearPedTasks(player, false, false)
                DeleteObject(Canteen)
                DeleteEntity(Canteen)
                TriggerServerEvent("oss_water:FillCanteen")
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

RegisterNetEvent('oss_water:Drink')
AddEventHandler('oss_water:Drink', function()
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
    TriggerEvent("vorpmetabolism:changeValue", "Thirst", 500)
end)

function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    --Citizen.InvokeNative(0x66E0276CC5F6B9DA, 2)
    SetTextScale(w, h)
    SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    Citizen.InvokeNative(0xADA9255D, 1);
    DisplayText(str, x, y)
end


