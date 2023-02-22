--credits to vorp_goldpanning

local entity
local Filling = false

local WaterTypes = {
    [1] = { ["name"] = "Sea of Coronado", ["waterhash"] = -247856387, ["watertype"] = "lake" },
    [2] = { ["name"] = "San Luis River", ["waterhash"] = -1504425495, ["watertype"] = "river" },
    [3] = { ["name"] = "Lake Don Julio", ["waterhash"] = -1369817450, ["watertype"] = "lake" },
    [4] = { ["name"] = "Flat Iron Lake", ["waterhash"] = -1356490953, ["watertype"] = "lake" },
    [5] = { ["name"] = "Upper Montana River", ["waterhash"] = -1781130443, ["watertype"] = "river" },
    [6] = { ["name"] = "Owanjila", ["waterhash"] = -1300497193, ["watertype"] = "river" },
    [7] = { ["name"] = "HawkEye Creek", ["waterhash"] = -1276586360, ["watertype"] = "river" },
    [8] = { ["name"] = "Little Creek River", ["waterhash"] = -1410384421, ["watertype"] = "river" },
    [9] = { ["name"] = "Dakota River", ["waterhash"] = 370072007, ["watertype"] = "river" },
    [10] = { ["name"] = "Beartooth Beck", ["waterhash"] = 650214731, ["watertype"] = "river" },
    [11] = { ["name"] = "Lake Isabella", ["waterhash"] = 592454541, ["watertype"] = "lake" },
    [12] = { ["name"] = "Cattail Pond", ["waterhash"] = -804804953, ["watertype"] = "lake" },
    [13] = { ["name"] = "Deadboot Creek", ["waterhash"] = 1245451421, ["watertype"] = "river" },
    [14] = { ["name"] = "Spider Gorge", ["waterhash"] = -218679770, ["watertype"] = "river" },
    [15] = { ["name"] = "O'Creagh's Run", ["waterhash"] = -1817904483, ["watertype"] = "lake" },
    [16] = { ["name"] = "Moonstone Pond", ["waterhash"] = -811730579, ["watertype"] = "lake" },
    [17] = { ["name"] = "Roanoke Valley", ["waterhash"] = -1229593481, ["watertype"] = "river" },
    [18] = { ["name"] = "Elysian Pool", ["waterhash"] = -105598602, ["watertype"] = "lake" },
    [19] = { ["name"] = "Heartland Overflow", ["waterhash"] = 1755369577, ["watertype"] = "swamp" },
    [20] = { ["name"] = "Lagras", ["waterhash"] = -557290573, ["watertype"] = "swamp" },
    [21] = { ["name"] = "Lannahechee River", ["waterhash"] = -2040708515, ["watertype"] = "river" },
    [22] = { ["name"] = "Dakota River", ["waterhash"] = 370072007, ["watertype"] = "river" },
    [23] = { ["name"] = "Random1", ["waterhash"] = 231313522, ["watertype"] = "river" },
    [24] = { ["name"] = "Random2", ["waterhash"] = 2005774838, ["watertype"] = "river" },
    [25] = { ["name"] = "Random3", ["waterhash"] = -1287619521, ["watertype"] = "river" },
    [26] = { ["name"] = "Random4", ["waterhash"] = -1308233316, ["watertype"] = "river" },
    [27] = { ["name"] = "Random5", ["waterhash"] = -196675805, ["watertype"] = "river" },
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local player = PlayerPedId()
        local Coords = GetEntityCoords(player)
        local waterpump = DoesObjectOfTypeExistAtCoords(Coords.x, Coords.y, Coords.z, 1.0, GetHashKey("p_waterpump01x"),
            0) -- prop required to interact
        if waterpump ~= false then
            DrawTxt("Fill Canteen ~t6~[ENTER]", 0.50, 0.95, 0.7, 0.5, true, 255, 255, 255, 255, true)
            if IsControlJustPressed(0, 0xC7B5340A) then
                TriggerServerEvent('checkcanteen')
            end
        end
    end
end)


RegisterNetEvent('green:StartFilling')
AddEventHandler('green:StartFilling', function()
    if not Filling then
        Filling = true
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local Water = Citizen.InvokeNative(0x5BA7A68A346A5A91, coords.x, coords.y, coords.z)
        local foundwater = false
        for k, v in pairs(WaterTypes) do
            if Water == WaterTypes[k]["waterhash"] then
                foundwater = true
                CrouchAnimAndAttach()
                TriggerEvent("vorp:TipRight", Config.fill_1, 500)
                Wait(6000)
                ClearPedTasks(ped)
                w = 1
                local seconds = w / 1
                for i = 1, seconds, 1 do
                    Wait(335)
                end
                -- Wait(w)
                ClearPedTasks(ped)
                DeleteObject(entity)
                DeleteEntity(entity)
                TriggerServerEvent("fillup")
                break
            end
        end
        Filling = false
        if foundwater == false then
            TriggerEvent("vorp:TipRight", Config.cantfill, 10000)
        end
    end
end)


function CrouchAnimAndAttach()
    local dict = "script_rc@cldn@ig@rsc2_ig1_questionshopkeeper"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_HAND")
    local modelHash = GetHashKey("p_cs_canteen_hercule")
    LoadModel(modelHash)
    entity = CreateObject(modelHash, coords.x, coords.y, coords.z, true, false, false)
    SetEntityVisible(entity, true)
    SetEntityAlpha(entity, 255, false)
    Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
    SetModelAsNoLongerNeeded(modelHash)
    AttachEntityToEntity(entity, ped, boneIndex, 0.12, 0.09, -0.05, 306.0, 18.0, 0.0, false, false, false, true, 2, true)

    TaskPlayAnim(ped, dict, "inspectfloor_player", 1.0, 8.0, -1, 1, 0, false, false, false)
end

function LoadModel(model)
    local attempts = 0
    while attempts < 100 and not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    return IsModelValid(model)
end

RegisterNetEvent('canteencheck')
AddEventHandler('canteencheck', function()
    doPromptAnim("amb_work@prop_human_pump_water@female_b@idle_a", "idle_a", 2);
    Wait(10000)
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent("fillup")

end)

RegisterNetEvent('green:drink')
AddEventHandler('green:drink', function()
    TriggerEvent("vorpmetabolism:changeValue", "Thirst", 500)
    --TriggerEvent("fred_meta:consume", 0, 50, 0, 0, 0, 0, 0, 0) -- UNCOMMENT AND COMMENT ABOVE IF USING FRED_METABOLISM
    drinkinganim()
end)

function drinkinganim()
    local ped = PlayerPedId()
    if IsPedMale(ped) then
        TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_DRINK_FLASK'), 10000, true, false, false,
            false)
        Wait(10000)
        TriggerEvent("vorp:TipRight", Config.drink_1, 500)
        ClearPedTasksImmediately(PlayerPedId())
    else
        -- FEMALE SCENARIO
        TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_DRINKING'), 10000, true, false, false, false)
        Wait(10000)
        TriggerEvent("vorp:TipRight", Config.drink_1, 500)
        ClearPedTasksImmediately(PlayerPedId())
    end
end

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

function doPromptAnim(dict, anim, loop)
    activate = false
    toggle = 0
    local playerPed = PlayerPedId()
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, 13000, loop, 0, true, 0, false, 0, false)
    play_anim = false
end
