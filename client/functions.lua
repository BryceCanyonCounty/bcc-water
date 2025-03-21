local CanUseCanteen = true

local function LoadAnim(animDict)
    DebugPrint("Loading animation dictionary: " .. animDict)
    if HasAnimDictLoaded(animDict) then return end

    RequestAnimDict(animDict)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not HasAnimDictLoaded(animDict) do
        if GetGameTimer() - startTime > timeout then
            print('Failed to load dictionary:', animDict)
            return
        end
        Wait(10)
    end
    DebugPrint("Animation dictionary loaded: " .. animDict)
end

local function PlayAnim(animDict, animName)
    DebugPrint("Playing animation: " .. animName .. " from dictionary: " .. animDict)
    local playerPed = PlayerPedId()

    LoadAnim(animDict)
    HidePedWeapons(playerPed, 2, true)

    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 17, 1.0, false, false, false)
    Wait(10000)
    ClearPedTasks(playerPed)

    Filling = false
    DebugPrint("Animation played successfully.")
end

local function LoadModel(model, modelName)
    DebugPrint("Loading model: " .. modelName)
    if not IsModelValid(model) then
        print('Invalid model:', modelName)
        return
    end

    if HasModelLoaded(model) then return end

    RequestModel(model, false)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not HasModelLoaded(model) do
        if GetGameTimer() - startTime > timeout then
            print('Failed to load model:', modelName)
            return
        end
        Wait(10)
    end
    DebugPrint("Model loaded: " .. modelName)
end

local function FillContainer(pumpAnim, modelName, modelHash, notificationMessage)
    DebugPrint("Filling container with model: " .. modelName)
    Filling = true
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    if not pumpAnim then
        local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_HAND')
        LoadModel(modelHash, modelName)

        Container = CreateObject(modelHash, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false, false, true)
        SetEntityVisible(Container, true)
        SetEntityAlpha(Container, 255, false)
        SetModelAsNoLongerNeeded(modelHash)
        AttachEntityToEntity(Container, playerPed, boneIndex, 0.12, 0.00, -0.10, 306.0, 18.0, 0.0, true, true, false, true, 2, true)

        local animDict = 'amb_work@world_human_crouch_inspect@male_c@idle_a'
        LoadAnim(animDict)

        TaskSetCrouchMovement(playerPed, true, 0, false)
        Wait(1500)
        TaskPlayAnim(playerPed, animDict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
        Wait(10000)
        TaskSetCrouchMovement(playerPed, false, 0, false)
        Wait(1500)

        DeleteObject(Container)
    else
        local taskRun = false
        local DataStruct = DataView.ArrayBuffer(256 * 4) -- Dataview snippet credit to Xakra and Ricx
        local pointsExist = GetScenarioPointsInArea(PlayerCoords, 2.0, DataStruct:Buffer(), 10)

        if not pointsExist then goto NEXT end

        for i = 1, 1 do
            local scenario = DataStruct:GetInt32(8 * i)
            local hash = GetScenarioPointType(scenario)

            if hash == joaat('PROP_HUMAN_PUMP_WATER') then
                taskRun = true
                ClearPedTasksImmediately(playerPed)
                TaskUseScenarioPoint(playerPed, scenario, '', -1.0, true, false, 0, false, -1.0, true)
                Wait(15000)
                break
            end
        end

        ::NEXT::
        if not taskRun then
            PlayAnim('amb_work@prop_human_pump_water@female_b@idle_a', 'idle_a')
        end
    end

    ClearPedTasks(playerPed)
    Filling = false

    if Config.showMessages then
        Core.NotifyRightTip(notificationMessage, 4000)
    end
    DebugPrint("Container filled successfully.")
end

function CanteenFill(pumpAnim)
    DebugPrint("Filling canteen.")
    FillContainer(pumpAnim, 'p_cs_canteen_hercule', joaat('p_cs_canteen_hercule'), _U('fillingComplete'))
end

function BottleFill(pumpAnim)
    DebugPrint("Filling bottle.")
    FillContainer(pumpAnim, 'p_bottlebeer01a_2', joaat('p_bottlebeer01a_2'), _U('fillingComplete'))
end

function BucketFill(pumpAnim)
    DebugPrint("Filling bucket.")
    Filling = true
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true) -- Hide Guns

    if not pumpAnim then
        TaskStartScenarioInPlaceHash(playerPed, joaat('WORLD_HUMAN_BUCKET_FILL'), -1, true, 0, -1, false)
        Wait(8000)
        ClearPedTasks(playerPed, true, true)
        Wait(4000)
        HidePedWeapons(playerPed, 2, true) -- Hide Bucket
    else
        local taskRun = false
        local DataStruct = DataView.ArrayBuffer(256 * 4) -- Dataview snippet credit to Xakra and Ricx
        local pointsExist = GetScenarioPointsInArea(PlayerCoords, 2.0, DataStruct:Buffer(), 10)

        if not pointsExist then goto NEXT end

        for i = 1, 1 do
            local scenario = DataStruct:GetInt32(8 * i)
            local hash = GetScenarioPointType(scenario)

            if hash == joaat('PROP_HUMAN_PUMP_WATER') or hash == joaat('PROP_HUMAN_PUMP_WATER_BUCKET') then
                taskRun = true
                ClearPedTasksImmediately(playerPed)
                TaskUseScenarioPoint(playerPed, scenario, '', -1.0, true, false, 0, false, -1.0, true)
                Wait(15000)
                ClearPedTasks(playerPed, true, true)
                Wait(5000)
                HidePedWeapons(playerPed, 2, true) -- Hide Bucket
                break
            end
        end

        ::NEXT::
        if not taskRun then
            PlayAnim('amb_work@prop_human_pump_water@female_b@idle_a', 'idle_a')
        end
    end

    Filling = false
    if Config.showMessages then
        Core.NotifyRightTip(_U('fillingComplete'), 4000)
    end
    DebugPrint("Bucket filled successfully.")
end

RegisterNetEvent('bcc-water:UseCanteen', function()
    DebugPrint("Using canteen.")
    if CanUseCanteen then
        local result = Core.Callback.TriggerAwait('bcc-water:UpdateCanteen')
        if not result then return end

        DrinkCanteen()
        CanUseCanteen = false
        Wait(6000)
        CanUseCanteen = true
    end
end)

function DrinkCanteen()
    DebugPrint("Drinking from canteen.")
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    local modelHash = joaat('p_cs_canteen_hercule')
    local animDict = 'amb_rest_drunk@world_human_drinking@male_a@idle_a'

    LoadAnim(animDict)
    LoadModel(modelHash, 'p_cs_canteen_hercule')

    Canteen = CreateObject(modelHash, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false, false, true)
    SetEntityVisible(Canteen, true)
    SetEntityAlpha(Canteen, 255, false)
    SetModelAsNoLongerNeeded(modelHash)

    TaskPlayAnim(playerPed, animDict, 'idle_a', 1.0, 1.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(Canteen, playerPed, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true, false, false)
    Wait(5500)
    DeleteObject(Canteen)
    ClearPedTasks(playerPed)
    PlayerStats(false)
end

function WildDrink()
    DebugPrint("Drinking from wild water.")
    PlayAnim('amb_rest_drunk@world_human_bucket_drink@ground@male_a@idle_c', 'idle_h')
    PlayerStats(true)
end

function PumpDrink()
    DebugPrint("Drinking from pump water.")
    PlayAnim('amb_work@prop_human_pump_water@male_a@idle_c', 'idle_g')
    PlayerStats(true)
end

function WashPlayer(animType)
    DebugPrint("Washing player with animation type: " .. animType)
    local playerPed = PlayerPedId()
    local animMap = {
        ground = 'amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d',
        stand = 'amb_misc@world_human_wash_face_bucket@table@male_a@idle_d'
    }

    if animMap[animType] then
        PlayAnim(animMap[animType], 'idle_l')
    else
        print('Invalid animType provided:', animType)
        return
    end

    ClearPedEnvDirt(playerPed)
    ClearPedDamageDecalByZone(playerPed, 10, 'ALL')
    ClearPedBloodDamage(playerPed)
    SetPedDirtCleaned(playerPed, 0.0, -1, true, true)
    DebugPrint("Player washed successfully.")
end

function PlayerStats(isWild)
    DebugPrint("Updating player stats.")
    local playerPed = PlayerPedId()
    local health = GetAttributeCoreValue(playerPed, 0, Citizen.ResultAsInteger())
    local stamina = GetAttributeCoreValue(playerPed, 1, Citizen.ResultAsInteger())
    local thirst = isWild and Config.wildDrink.thirst or Config.canteenDrink.thirst
    local app = tonumber(Config.app)

    local appUpdate = {
        [1] = function() TriggerEvent('vorpmetabolism:changeValue', 'Thirst', thirst * 10) end,
        [2] = function() TriggerEvent('fred:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0) end,
        [3] = function() local data = {AddThirst = thirst} exports.outsider_needs:SetNeedsData(data) end,
        [4] = function() TriggerEvent('fred_meta:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0) end,
        [5] = function() exports.fred_metabolism:consume('thirst' , thirst) end,
        [6] = function() TriggerEvent('rsd_metabolism:SetMeta', {drink = thirst}) end,
        [7] = function() TriggerServerEvent('hud.decrease', 'thirst', thirst * 10) end,
        [8] = function() TriggerEvent('hud:client:changeValue', 'Thirst', thirst) end,
        [9] = function() exports['fx-hud']:setStatus('thirst', thirst) end,
    }

    local function updateAttribute(attributeIndex, value, maxValue)
        local newValue = math.max(0, math.min(maxValue, value))
        SetAttributeCoreValue(playerPed, attributeIndex, newValue)
    end

    if appUpdate[app] then
        appUpdate[app]()

        local healthConfig = isWild and Config.wildDrink.health or Config.canteenDrink.health
        local staminaConfig = isWild and Config.wildDrink.stamina or Config.canteenDrink.stamina
        local gainHealth = isWild and Config.wildDrink.gainHealth or true
        local gainStamina = isWild and Config.wildDrink.gainStamina or true

        if healthConfig > 0 then
            updateAttribute(0, gainHealth and (health + healthConfig) or (health - healthConfig), 100)
        end

        if staminaConfig > 0 then
            updateAttribute(1, gainStamina and (stamina + staminaConfig) or (stamina - staminaConfig), 100)
        end

        PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
    else
        DebugPrint('Check Config.app setting for correct metabolism value')
    end
    DebugPrint("Player stats updated successfully.")
end