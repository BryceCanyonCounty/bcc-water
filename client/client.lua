local VORPcore = {}
-- Prompts
local PumpPrompt
local FillPrompt
local WashPrompt
local DrinkPrompt
local PumpGroup = GetRandomIntInRange(0, 0xffffff)
local WaterGroup = GetRandomIntInRange(0, 0xffffff)
-- Water
local Canteen
local PumpAnim
local Filling = false
local IsWild
local UseCanteen = true

TriggerEvent('getCore', function(core)
    VORPcore = core
end)

CreateThread(function()
    -- Start Prompts
    Waterpump()
    FillCanteen()
    Wash()
    DrinkWater()
    --Start Water
    while true do
        Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player, true, true)
        local sleep = true
        local dead = IsEntityDead(player)
        if not dead then
            -- Waterpumps
            local pumpLoc = Citizen.InvokeNative(0xBFA48E2FF417213F, coords.x, coords.y, coords.z, 0.75, joaat('p_waterpump01x'), 0) -- DoesObjectOfTypeExistAtCoords
            local wellLoc = Citizen.InvokeNative(0xBFA48E2FF417213F, coords.x, coords.y, coords.z, 0.75, joaat('p_wellpumpnbx01x'), 0) -- DoesObjectOfTypeExistAtCoords
            if pumpLoc or wellLoc then
                if IsPedOnFoot(player) then
                    sleep = false
                    if Config.usePrompt then
                        local waterpump = CreateVarString(10, 'LITERAL_STRING', 'Waterpump')
                        PromptSetActiveGroupThisFrame(PumpGroup, waterpump)
                        if Citizen.InvokeNative(0xC92AC953F0A982AE, PumpPrompt) then -- UiPromptHasStandardModeCompleted
                            PumpWater()
                        end
                    else
                        DrawText3Ds(coords.x, coords.y, coords.z, '~t6~F~q~ - '.. _U('fill'))
                        if IsControlJustReleased(0, Config.keys.fill) then -- [F]
                            PumpWater()
                        end
                    end
                end
            else
                -- Wild Waters
                local water = Citizen.InvokeNative(0x5BA7A68A346A5A91, coords.x, coords.y, coords.z) -- GetWaterMapZoneAtCoords
                for k, _ in pairs(Config.locations) do
                    if water == Config.locations[k].hash and IsPedOnFoot(player) then
                        if IsEntityInWater(player) and Citizen.InvokeNative(0xD5FE956C70FF370B, player) then -- GetPedCrouchMovement
                            if Citizen.InvokeNative(0xAC29253EEF8F0180, player) then -- IsPedStill
                                sleep = false
                                local waterSource = CreateVarString(10, 'LITERAL_STRING', Config.locations[k].name)
                                PromptSetActiveGroupThisFrame(WaterGroup, waterSource)
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, FillPrompt) then -- UiPromptHasStandardModeCompleted
                                    Filling = true
                                    PumpAnim = false
                                    TriggerServerEvent('bcc-water:CheckEmpty')
                                    break
                                end
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, WashPrompt) then -- UiPromptHasStandardModeCompleted
                                    if not Filling then
                                        WashPlayer()
                                    end
                                    break
                                end
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, DrinkPrompt) then -- UiPromptHasStandardModeCompleted
                                    if not Filling then
                                        WildDrink()
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if sleep then
                Wait(1000)
            end
        end
    end
end)

-- Fill Canteen Animations
RegisterNetEvent('bcc-water:FillCanteen', function()
    local player = PlayerPedId()
    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
    if not PumpAnim then
        local coords = GetEntityCoords(player, true, true)
        local boneIndex = GetEntityBoneIndexByName(player, 'SKEL_R_HAND')
        local modelHash = joaat('p_cs_canteen_hercule')
        LoadModel(modelHash)
        Canteen = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false, false, true)
        SetEntityVisible(Canteen, true)
        SetEntityAlpha(Canteen, 255, false)
        SetModelAsNoLongerNeeded(modelHash)
        AttachEntityToEntity(Canteen, player, boneIndex, 0.12, 0.09, -0.05, 306.0, 18.0, 0.0, true, true, false, true, 2, true)
        PlayAnim('amb_work@world_human_crouch_inspect@male_c@idle_a', 'idle_a')
        DeleteObject(Canteen)
        Filling = false
    else
        --Dataview snippet credit to Xakra and Ricx, used in the scenario menu for getting closest scenario
        local DataStruct = DataView.ArrayBuffer(256 * 4)
        local is_data_exists = Citizen.InvokeNative(0x345EC3B7EBDE1CB5, GetEntityCoords(PlayerPedId()), 2.0,
            DataStruct:Buffer(), 10)
        if is_data_exists ~= false then
            for i = 1, 1 do
                local scenario = DataStruct:GetInt32(8 * i)
                local scenario_hash = Citizen.InvokeNative(0xA92450B5AE687AAF, scenario)
                if GetHashKey("PROP_HUMAN_PUMP_WATER") == scenario_hash or GetHashKey("PROP_HUMAN_PUMP_WATER_BUCKET") == scenario_hash then
                    ClearPedTasksImmediately(PlayerPedId())
                    Citizen.InvokeNative(0xFCCC886EDE3C63EC, PlayerPedId(), false, true)
                    TaskUseScenarioPoint(PlayerPedId(), scenario, "", -1.0, true, false, 0, false, -1.0, true)
                    Wait(10000)
                    break
                end
            end
        end
        ClearPedTasks(PlayerPedId())
        end
    if Config.showMessages then
        VORPcore.NotifyRightTip(_U('full'), 5000)
    end
end)

function PumpWater()
    PumpAnim = true
    TriggerServerEvent('bcc-water:CheckEmpty')
end

-- Drink from Canteen
RegisterNetEvent('bcc-water:Drink', function(level)
    local player = PlayerPedId()
    local coords = GetEntityCoords(player, true, true)
    local boneIndex = GetEntityBoneIndexByName(player, 'SKEL_R_Finger12')
    local modelHash = joaat('p_cs_canteen_hercule')
    local dict = 'amb_rest_drunk@world_human_drinking@male_a@idle_a'
    local anim = 'idle_a'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    LoadModel(modelHash)
    Canteen = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false, false, true)
    SetEntityVisible(Canteen, true)
    SetEntityAlpha(Canteen, 255, false)
    SetModelAsNoLongerNeeded(modelHash)
    TaskPlayAnim(player, dict, anim, 1.0, 1.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(Canteen, player, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true)
    Wait(6000)
    DeleteObject(Canteen)
    ClearPedTasks(player, false, false)
    IsWild = false
    PlayerStats()

    -- Canteen Level Messages
    local levelMessage = {
        [1] = _U('message_1'),
        [2] = _U('message_2'),
        [3] = _U('message_3'),
        [4] = _U('message_4')
    }
    if Config.showMessages then
        VORPcore.NotifyRightTip(levelMessage[level], 5000)
    end
end)

-- Drink Directly from Wild Waters
function WildDrink()
    PlayAnim('amb_rest_drunk@world_human_bucket_drink@ground@male_a@idle_c', 'idle_h')
    IsWild = true
    PlayerStats()
end

-- Wash Player in Wild Waters
function WashPlayer()
    local player = PlayerPedId()
    PlayAnim('amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d', 'idle_l')
    Citizen.InvokeNative(0x6585D955A68452A5, player) -- ClearPedEnvDirt
    Citizen.InvokeNative(0x523C79AEEFCC4A2A, player, 10, 'ALL') -- ClearPedDamageDecalByZone
    Citizen.InvokeNative(0x8FE22675A5A45817, player) -- ClearPedBloodDamage
    Citizen.InvokeNative(0xE3144B932DFDFF65, player, 0.0, -1, 1, 1) -- SetPedDirtCleaned
end

-- Boosts from Drinking
function PlayerStats()
    local player = PlayerPedId()
    local health = Citizen.InvokeNative(0x36731AC041289BB1, player, 0) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, player, 1) -- GetAttributeCoreValue
    local app = tonumber(Config.app)
    local appUpdate = {
        [1] = function()
            if IsWild then
                TriggerEvent('vorpmetabolism:changeValue', 'Thirst', Config.wildThirst * 10)
            else
                TriggerEvent('vorpmetabolism:changeValue', 'Thirst', Config.thirst * 10)
            end
        end,
        [2] = function()
            if IsWild then
                TriggerEvent('fred:consume', 0, Config.wildThirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            else
                TriggerEvent('fred:consume', 0, Config.thirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            end
        end,
        [3] = function()
            if IsWild then
                TriggerServerEvent('outsider_needs:Thirst', true)
            else
                TriggerServerEvent('outsider_needs:Thirst', false)
            end
        end,
        [4] = function()
            if IsWild then
                TriggerEvent('fred_meta:consume', 0, Config.wildThirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            else
                TriggerEvent('fred_meta:consume', 0, Config.thirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            end
        end
    }
    if appUpdate[app] then
        appUpdate[app]()
        if IsWild then
            local newWildHealth = health + Config.wildHealth
            local newWildStamina = stamina + Config.wildStamina

            if newWildHealth > 100 then
                newWildHealth = 100
                Citizen.InvokeNative(0xC6258F41D86676E0, player, 0, newWildHealth) -- SetAttributeCoreValue
            end
            if newWildStamina > 100 then
                newWildStamina = 100
                Citizen.InvokeNative(0xC6258F41D86676E0, player, 1, newWildStamina) -- SetAttributeCoreValue
            end
            return
        else
            local newHealth = health + Config.health
            local newStamina = stamina + Config.stamina

            if newHealth > 100 then
                newHealth = 100
                Citizen.InvokeNative(0xC6258F41D86676E0, player, 0, newHealth) -- SetAttributeCoreValue
            end
            if newStamina > 100 then
                newStamina = 100
                Citizen.InvokeNative(0xC6258F41D86676E0, player, 1, newStamina) -- SetAttributeCoreValue
            end
            return
        end
    else
        print('Check Config.app setting for correct metabolism value')
    end
end

RegisterNetEvent('bcc-water:Filling', function()
    Filling = false
end)

RegisterNetEvent('bcc-water:UseCanteen', function(data)
    if UseCanteen then
        TriggerServerEvent('bcc-water:UpdateCanteen', data)
        UseCanteen = false
        Wait(15000)
        UseCanteen = true
    end
end)

function PlayAnim(dict, anim)
    local player = PlayerPedId()
    LoadAnim(dict)
    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
    TaskPlayAnim(player, dict, anim, 1.0, 1.0, -1, 17, 1.0, false, false, false)
    Wait(10000)
    ClearPedTasks(player, false, false)
end

function LoadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
end

-- Menu Prompts
function Waterpump()
    local str = _U('fill')
    PumpPrompt = PromptRegisterBegin()
    PromptSetControlAction(PumpPrompt, Config.keys.fill)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(PumpPrompt, str)
    PromptSetEnabled(PumpPrompt, 1)
    PromptSetVisible(PumpPrompt, 1)
    PromptSetStandardMode(PumpPrompt, 1)
    PromptSetGroup(PumpPrompt, PumpGroup)
    PromptRegisterEnd(PumpPrompt)
end

function FillCanteen()
    local str = _U('fill')
    FillPrompt = PromptRegisterBegin()
    PromptSetControlAction(FillPrompt, Config.keys.fill)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(FillPrompt, str)
    PromptSetEnabled(FillPrompt, 1)
    PromptSetVisible(FillPrompt, 1)
    PromptSetStandardMode(FillPrompt, 1)
    PromptSetGroup(FillPrompt, WaterGroup)
    PromptRegisterEnd(FillPrompt)
end

function Wash()
    local str = _U('wash')
    WashPrompt = PromptRegisterBegin()
    PromptSetControlAction(WashPrompt, Config.keys.wash)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(WashPrompt, str)
    PromptSetEnabled(WashPrompt, 1)
    PromptSetVisible(WashPrompt, 1)
    PromptSetStandardMode(WashPrompt, 1)
    PromptSetGroup(WashPrompt, WaterGroup)
    PromptRegisterEnd(WashPrompt)
end

function DrinkWater()
    local str = _U('drink')
    DrinkPrompt = PromptRegisterBegin()
    PromptSetControlAction(DrinkPrompt, Config.keys.drink)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(DrinkPrompt, str)
    PromptSetEnabled(DrinkPrompt, 1)
    PromptSetVisible(DrinkPrompt, 1)
    PromptSetStandardMode(DrinkPrompt, 1)
    PromptSetGroup(DrinkPrompt, WaterGroup)
    PromptRegisterEnd(DrinkPrompt)
end

function DrawText3Ds(x, y, z, text)
    local _, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, 'LITERAL_STRING', text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str, _x, _y)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    ClearPedTasksImmediately(PlayerPedId())
    if Canteen then
        DeleteObject(Canteen)
    end
    PromptDelete(PumpPrompt)
    PromptDelete(FillPrompt)
    PromptDelete(WashPrompt)
    PromptDelete(DrinkPrompt)
end)
