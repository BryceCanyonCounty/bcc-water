local VORPcore = {}
-- Prompts
local FillCanteenPrompt
local FillBucketPrompt
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
    StartPrompts()
    --Start Water
    while true do
        Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local sleep = true
        if not IsEntityDead(player) then
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

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, FillCanteenPrompt) then -- UiPromptHasStandardModeCompleted
                                VORPcore.RpcCall('GetCanteenLevel', function(canFillCanteen)
                                    if canFillCanteen then
                                        CanteenFill(true)
                                    else
                                        Filling = false
                                    end
                                end)
                            end
                            if Citizen.InvokeNative(0xC92AC953F0A982AE, FillBucketPrompt) then -- UiPromptHasStandardModeCompleted
                                VORPcore.RpcCall('GetBucketLevel', function(canFillBucket)
                                    if canFillBucket then
                                        BucketFill(true)
                                    else
                                        Filling = false
                                    end
                                end)
                            end
                        end
                    else
                        if not Filling then
                            DrawText3Ds(coords.x, coords.y, coords.z, '~t6~F~q~ - '.. _U('fillCanteen') .. ' ' .. '~t6~L~q~ - ' .. _U('fillBucket'))

                            if IsControlJustReleased(0, Config.keys.fillCanteen) then
                                VORPcore.RpcCall('GetCanteenLevel', function(canFillCanteen)
                                    if canFillCanteen then
                                        CanteenFill(true)
                                    else
                                        Filling = false
                                    end
                                end)
                            end
                            if IsControlJustReleased(0, Config.keys.fillBucket) then
                                VORPcore.RpcCall('GetBucketLevel', function(canFillBucket)
                                    if canFillBucket then
                                        BucketFill(true)
                                    else
                                        Filling = false
                                    end
                                end)
                            end
                        end
                    end
                end
            else
                -- Wild Waters
                local water = Citizen.InvokeNative(0x5BA7A68A346A5A91, coords.x, coords.y, coords.z) -- GetWaterMapZoneAtCoords
                for k, _ in pairs(Config.locations) do
                    if water == Config.locations[k].hash and IsPedOnFoot(player) and IsEntityInWater(player) then
                        if Config.crouch then
                            if  Citizen.InvokeNative(0xD5FE956C70FF370B, player) then -- GetPedCrouchMovement
                            else
                                break
                            end
                        end
                        if Citizen.InvokeNative(0xAC29253EEF8F0180, player) then -- IsPedStill
                            sleep = false
                            if not Filling then
                                local waterSource = CreateVarString(10, 'LITERAL_STRING', Config.locations[k].name)
                                PromptSetActiveGroupThisFrame(WaterGroup, waterSource)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, FillCanteenPrompt) then -- UiPromptHasStandardModeCompleted
                                    VORPcore.RpcCall('GetCanteenLevel', function(canFillCanteen)
                                        if canFillCanteen then
                                            CanteenFill(false)
                                        else
                                            Filling = false
                                        end
                                    end)
                                    break
                                end
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, FillBucketPrompt) then -- UiPromptHasStandardModeCompleted
                                    VORPcore.RpcCall('GetBucketLevel', function(canFillBucket)
                                        if canFillBucket then
                                            BucketFill(false)
                                        else
                                            Filling = false
                                        end
                                    end)
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
            if sleep then
                Wait(1000)
            end
        end
    end
end)

-- Fill Canteen Animations
function CanteenFill(pumpAnim)
    Filling = true
    local player = PlayerPedId()
    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
    if not pumpAnim then
        local coords = GetEntityCoords(player)
        local boneIndex = GetEntityBoneIndexByName(player, 'SKEL_R_HAND')
        local modelHash = joaat('p_cs_canteen_hercule')
        LoadModel(modelHash)
        Canteen = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false, false, true)
        SetEntityVisible(Canteen, true)
        SetEntityAlpha(Canteen, 255, false)
        SetModelAsNoLongerNeeded(modelHash)
        AttachEntityToEntity(Canteen, player, boneIndex, 0.12, 0.09, -0.05, 306.0, 18.0, 0.0, true, true, false, true, 2, true)

        local dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a'
        LoadAnim(dict)
        Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
        TaskSetCrouchMovement(player, true, 0, false)
        Wait(1500)
        TaskPlayAnim(player, dict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
        Wait(10000)
        TaskSetCrouchMovement(player, false, 0, false)
        Wait(1500)
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
    ClearPedTasks(player)
    Filling = false
    if Config.showMessages then
        VORPcore.NotifyRightTip(_U('fullCanteen'), 5000)
    end
end

-- Fill Bucket Animations
function BucketFill(pumpAnim)
    Filling = true
    local player = PlayerPedId()
    if not pumpAnim then
        Citizen.InvokeNative(0x524B54361229154F, player, joaat('WORLD_HUMAN_BUCKET_FILL'), -1, true, 0, -1, false) -- TaskStartScenarioInPlaceHash
        Wait(8000)
        ClearPedTasks(player, true, true)
        Wait(4000)
        Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
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
                    ClearPedTasks(player, true, true)
                    Wait(5000)
                    Citizen.InvokeNative(0xFCCC886EDE3C63EC, player, 2, true) -- HidePedWeapons
                    break
                end
            end
        else
            PlayAnim('amb_work@prop_human_pump_water@female_b@idle_a', 'idle_a')
        end
    end
    Filling = false
    if Config.showMessages then
        VORPcore.NotifyRightTip(_U('fullBucket'), 5000)
    end
end

-- Drink from Canteen
function DrinkCanteen(level)
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
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
    ClearPedTasks(player)
    PlayerStats(false)

    -- Canteen Level Messages
    local levelMessage = {
        [2] = _U('message_1'),
        [3] = _U('message_2'),
        [4] = _U('message_3'),
        [5] = _U('message_4')
    }
    if Config.showMessages then
        VORPcore.NotifyRightTip(levelMessage[level], 5000)
    end
end

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
        if health == nil then
            health = 0
        end
        if stamina == nil then
            stamina = 0
        end
        if isWild then
            -- Wild Health
            if Config.wildHealth > 0 then
                local newWildHealth
                if Config.gainHealth then
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
            end

            -- Wild Stamina
            if Config.wildStamina > 0 then
                local newWildStamina
                if Config.gainStamina then
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
            end
            Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
        else
            -- Clean Health
            if Config.health > 0 then
                local newHealth = health + Config.health
                if newHealth > 100 then
                    newHealth = 100
                end
                Citizen.InvokeNative(0xC6258F41D86676E0, player, 0, newHealth) -- SetAttributeCoreValue
            end

            -- Clean Stamina
            if Config.stamina > 0 then
                local newStamina = stamina + Config.stamina
                if newStamina > 100 then
                    newStamina = 100
                end
                Citizen.InvokeNative(0xC6258F41D86676E0, player, 1, newStamina) -- SetAttributeCoreValue
            end
            Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
        end
    else
        print('Check Config.app setting for correct metabolism value')
    end
end

RegisterNetEvent('bcc-water:UseCanteen', function()
    if UseCanteen then
        VORPcore.RpcCall('UpdateCanteen', function(canDrink)
            if canDrink then
                DrinkCanteen(canDrink)
            else
                return
            end
        end)
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
    ClearPedTasks(player)
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
function StartPrompts()
    local canteenStr = CreateVarString(10, 'LITERAL_STRING', _U('fillCanteen'))
    FillCanteenPrompt = PromptRegisterBegin()
    PromptSetControlAction(FillCanteenPrompt, Config.keys.fillCanteen)
    PromptSetText(FillCanteenPrompt, canteenStr)
    PromptSetEnabled(FillCanteenPrompt, 1)
    PromptSetVisible(FillCanteenPrompt, 1)
    PromptSetStandardMode(FillCanteenPrompt, 1)
    PromptSetGroup(FillCanteenPrompt, WaterGroup)
    PromptSetGroup(FillCanteenPrompt, PumpGroup)
    PromptRegisterEnd(FillCanteenPrompt)

    local bucketStr = CreateVarString(10, 'LITERAL_STRING', _U('fillBucket'))
    FillBucketPrompt = PromptRegisterBegin()
    PromptSetControlAction(FillBucketPrompt, Config.keys.fillBucket)
    PromptSetText(FillBucketPrompt, bucketStr)
    PromptSetEnabled(FillBucketPrompt, 1)
    PromptSetVisible(FillBucketPrompt, 1)
    PromptSetStandardMode(FillBucketPrompt, 1)
    PromptSetGroup(FillBucketPrompt, WaterGroup)
    PromptSetGroup(FillBucketPrompt, PumpGroup)
    PromptRegisterEnd(FillBucketPrompt)

    local washStr = CreateVarString(10, 'LITERAL_STRING', _U('wash'))
    WashPrompt = PromptRegisterBegin()
    PromptSetControlAction(WashPrompt, Config.keys.wash)
    PromptSetText(WashPrompt, washStr)
    PromptSetEnabled(WashPrompt, 1)
    PromptSetVisible(WashPrompt, 1)
    PromptSetStandardMode(WashPrompt, 1)
    PromptSetGroup(WashPrompt, WaterGroup)
    PromptRegisterEnd(WashPrompt)

    local drinkStr = CreateVarString(10, 'LITERAL_STRING', _U('drink'))
    DrinkPrompt = PromptRegisterBegin()
    PromptSetControlAction(DrinkPrompt, Config.keys.drink)
    PromptSetText(DrinkPrompt, drinkStr)
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
    SetTextCentre(true)
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
end)
