local VORPcore = {}
-- Prompts
local PumpCanteenPrompt
local PumpBucketPrompt
local WildCanteenPrompt
local WildBucketPrompt
local WashPrompt
local DrinkPrompt
local PumpGroup = GetRandomIntInRange(0, 0xffffff)
local WaterGroup = GetRandomIntInRange(0, 0xffffff)
-- Water
local Canteen
local Filling = false
local UseCanteen = true

TriggerEvent('getCore', function(core)
    VORPcore = core
end)

CreateThread(function()
    -- Start Prompts
    PumpCanteen()
    PumpBucket()
    WildCanteen()
    WildBucket()
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
                        if not Filling then
                            local waterpump = CreateVarString(10, 'LITERAL_STRING', _U('waterPump'))
                            PromptSetActiveGroupThisFrame(PumpGroup, waterpump)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, PumpCanteenPrompt) then -- [F] UiPromptHasStandardModeCompleted
                                TriggerServerEvent('bcc-water:CheckCanteen', true)
                            end
                            if Citizen.InvokeNative(0xC92AC953F0A982AE, PumpBucketPrompt) then -- [L] UiPromptHasStandardModeCompleted
                                TriggerServerEvent('bcc-water:CheckBucket', true)
                            end
                        end
                    else
                        if not Filling then
                            DrawText3Ds(coords.x, coords.y, coords.z, '~t6~F~q~ - '.. _U('fillCanteen') .. ' ' .. '~t6~L~q~ - ' .. _U('fillBucket'))

                            if IsControlJustReleased(0, Config.keys.fillCanteen) then -- [F]
                                TriggerServerEvent('bcc-water:CheckCanteen', true)
                            end
                            if IsControlJustReleased(0, Config.keys.fillBucket) then -- [L]
                                TriggerServerEvent('bcc-water:CheckBucket', true)
                            end
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
                                if not Filling then
                                    local waterSource = CreateVarString(10, 'LITERAL_STRING', Config.locations[k].name)
                                    PromptSetActiveGroupThisFrame(WaterGroup, waterSource)

                                    if Citizen.InvokeNative(0xC92AC953F0A982AE, WildCanteenPrompt) then -- UiPromptHasStandardModeCompleted
                                        TriggerServerEvent('bcc-water:CheckCanteen', false)
                                        break
                                    end
                                    if Citizen.InvokeNative(0xC92AC953F0A982AE, WildBucketPrompt) then -- UiPromptHasStandardModeCompleted
                                        TriggerServerEvent('bcc-water:CheckBucket', false)
                                        break
                                    end
                                    if Citizen.InvokeNative(0xC92AC953F0A982AE, WashPrompt) then -- UiPromptHasStandardModeCompleted
                                        WashPlayer()
                                        break
                                    end
                                    if Citizen.InvokeNative(0xC92AC953F0A982AE, DrinkPrompt) then -- UiPromptHasStandardModeCompleted
                                        WildDrink()
                                        break
                                    end
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
RegisterNetEvent('bcc-water:FillCanteen', function(pumpAnim)
    Filling = true
    local player = PlayerPedId()
    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
    if not pumpAnim then
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
    else
        -- Dataview snippet credit to Xakra and Ricx
        local DataStruct = DataView.ArrayBuffer(256 * 4)
        local hasData = Citizen.InvokeNative(0x345EC3B7EBDE1CB5, GetEntityCoords(player), 2.0, DataStruct:Buffer(), 10) -- GetScenarioPointsInArea
        if hasData then
            for i = 1, 1 do
                local scenario = DataStruct:GetInt32(8 * i)
                local hash = Citizen.InvokeNative(0xA92450B5AE687AAF, scenario) -- GetScenarioPointType
                if hash == joaat('PROP_HUMAN_PUMP_WATER') then
                    ClearPedTasksImmediately(player)
                    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
                    TaskUseScenarioPoint(player, scenario, '', -1.0, true, false, 0, false, -1.0, true)
                    Wait(15000)
                    break
                else
                    PlayAnim('amb_work@prop_human_pump_water@female_b@idle_a', 'idle_a')
                end
            end
        else
            PlayAnim('amb_work@prop_human_pump_water@female_b@idle_a', 'idle_a')
        end
    end
    ClearPedTasksImmediately(player)
    Filling = false
    if Config.showMessages then
        VORPcore.NotifyRightTip(_U('fullCanteen'), 5000)
    end
end)

-- Fill Bucket Animations
RegisterNetEvent('bcc-water:FillBucket', function(pumpAnim)
    Filling = true
    local player = PlayerPedId()
    if not pumpAnim then
        TaskStartScenarioInPlace(player, joaat('WORLD_HUMAN_BUCKET_FILL'), -1, true, false, false, false)
        Wait(10000)
        ClearPedTasks(player, true, true)
    else
        -- Dataview snippet credit to Xakra and Ricx
        local DataStruct = DataView.ArrayBuffer(256 * 4)
        local hasData = Citizen.InvokeNative(0x345EC3B7EBDE1CB5, GetEntityCoords(player), 2.0, DataStruct:Buffer(), 10) -- GetScenarioPointsInArea
        if hasData then
            for i = 1, 1 do
                local scenario = DataStruct:GetInt32(8 * i)
                local hash = Citizen.InvokeNative(0xA92450B5AE687AAF, scenario) -- GetScenarioPointType
                if hash == joaat('PROP_HUMAN_PUMP_WATER') or hash == joaat('PROP_HUMAN_PUMP_WATER_BUCKET') then
                    ClearPedTasksImmediately(player)
                    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
                    TaskUseScenarioPoint(player, scenario, '', -1.0, true, false, 0, false, -1.0, true)
                    Wait(15000)
                    break
                end
            end
        else
            PlayAnim('amb_work@prop_human_pump_water@female_b@idle_a', 'idle_a')
        end
    end
    ClearPedTasksImmediately(player)
    Filling = false
    if Config.showMessages then
        VORPcore.NotifyRightTip(_U('fullBucket'), 5000)
    end
end)

-- Drink from Canteen
RegisterNetEvent('bcc-water:DrinkCanteen', function(level)
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
    PlayerStats(false)

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
    PlayerStats(true)
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
function PlayerStats(isWild)
    local player = PlayerPedId()
    local health = tonumber(Citizen.InvokeNative(0x36731AC041289BB1, player, 0)) -- GetAttributeCoreValue
    local stamina = tonumber(Citizen.InvokeNative(0x36731AC041289BB1, player, 1)) -- GetAttributeCoreValue
    local app = tonumber(Config.app)
    local appUpdate = {
        [1] = function()
            if isWild then
                TriggerEvent('vorpmetabolism:changeValue', 'Thirst', Config.wildThirst * 10)
            else
                TriggerEvent('vorpmetabolism:changeValue', 'Thirst', Config.thirst * 10)
            end
        end,
        [2] = function()
            if isWild then
                TriggerEvent('fred:consume', 0, Config.wildThirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            else
                TriggerEvent('fred:consume', 0, Config.thirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            end
        end,
        [3] = function()
            if isWild then
                TriggerServerEvent('outsider_needs:Thirst', true)
            else
                TriggerServerEvent('outsider_needs:Thirst', false)
            end
        end,
        [4] = function()
            if isWild then
                TriggerEvent('fred_meta:consume', 0, Config.wildThirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            else
                TriggerEvent('fred_meta:consume', 0, Config.thirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
            end
        end
    }
    if appUpdate[app] then
        appUpdate[app]()
        if isWild then
            -- Wild Health
            local newWildHealth
            if not Config.hurtHealth then
                newWildHealth = health + Config.wildHealth
            else
                newWildHealth = health - Config.wildHealth
            end

            if newWildHealth > 100 then
                newWildHealth = 100
            end
            if newWildHealth < 0 then
                newWildHealth = 0
            end
            Citizen.InvokeNative(0xC6258F41D86676E0, player, 0, newWildHealth) -- SetAttributeCoreValue

            -- Wild Stamina
            local newWildStamina
            if not Config.hurtStamina then
                newWildStamina = stamina + Config.wildStamina
            else
                newWildStamina = stamina - Config.wildStamina
            end

            if newWildStamina > 100 then
                newWildStamina = 100
            end
            if newWildStamina < 0 then
                newWildStamina = 0
            end
            Citizen.InvokeNative(0xC6258F41D86676E0, player, 1, newWildStamina) -- SetAttributeCoreValue
            print('Health = ', health, ' ', newWildHealth)
            print('Stamina = ', stamina, ' ', newWildStamina)
            return
        else
            -- Clean Health
            local newHealth = health + Config.health
            if newHealth > 100 then
                newHealth = 100
            end
            Citizen.InvokeNative(0xC6258F41D86676E0, player, 0, newHealth) -- SetAttributeCoreValue

            -- Clean Stamina
            local newStamina = stamina + Config.stamina
            if newStamina > 100 then
                newStamina = 100
            end
            Citizen.InvokeNative(0xC6258F41D86676E0, player, 1, newStamina) -- SetAttributeCoreValue
            print('Health = ', health, ' ', newHealth)
            print('Stamina = ', stamina, ' ', newStamina)
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
        Wait(8000)
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
    Filling = false
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
function PumpCanteen()
    local str = _U('fillCanteen')
    PumpCanteenPrompt = PromptRegisterBegin()
    PromptSetControlAction(PumpCanteenPrompt, Config.keys.fillCanteen)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(PumpCanteenPrompt, str)
    PromptSetEnabled(PumpCanteenPrompt, 1)
    PromptSetVisible(PumpCanteenPrompt, 1)
    PromptSetStandardMode(PumpCanteenPrompt, 1)
    PromptSetGroup(PumpCanteenPrompt, PumpGroup)
    PromptRegisterEnd(PumpCanteenPrompt)
end

function PumpBucket()
    local str = _U('fillBucket')
    PumpBucketPrompt = PromptRegisterBegin()
    PromptSetControlAction(PumpBucketPrompt, Config.keys.fillBucket)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(PumpBucketPrompt, str)
    PromptSetEnabled(PumpBucketPrompt, 1)
    PromptSetVisible(PumpBucketPrompt, 1)
    PromptSetStandardMode(PumpBucketPrompt, 1)
    PromptSetGroup(PumpBucketPrompt, PumpGroup)
    PromptRegisterEnd(PumpBucketPrompt)
end

function WildCanteen()
    local str = _U('fillCanteen')
    WildCanteenPrompt = PromptRegisterBegin()
    PromptSetControlAction(WildCanteenPrompt, Config.keys.fillCanteen)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(WildCanteenPrompt, str)
    PromptSetEnabled(WildCanteenPrompt, 1)
    PromptSetVisible(WildCanteenPrompt, 1)
    PromptSetStandardMode(WildCanteenPrompt, 1)
    PromptSetGroup(WildCanteenPrompt, WaterGroup)
    PromptRegisterEnd(WildCanteenPrompt)
end

function WildBucket()
    local str = _U('fillBucket')
    WildBucketPrompt = PromptRegisterBegin()
    PromptSetControlAction(WildBucketPrompt, Config.keys.fillBucket)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(WildBucketPrompt, str)
    PromptSetEnabled(WildBucketPrompt, 1)
    PromptSetVisible(WildBucketPrompt, 1)
    PromptSetStandardMode(WildBucketPrompt, 1)
    PromptSetGroup(WildBucketPrompt, WaterGroup)
    PromptRegisterEnd(WildBucketPrompt)
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
    PromptDelete(PumpCanteenPrompt)
    PromptDelete(PumpBucketPrompt)
    PromptDelete(WildCanteenPrompt)
    PromptDelete(WildBucketPrompt)
    PromptDelete(WashPrompt)
    PromptDelete(DrinkPrompt)
end)
