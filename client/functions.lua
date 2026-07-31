local IsSick = false

local LoadAnim = WaterClient.LoadAnim
local LoadModel = WaterClient.LoadModel
local PlayAnim = WaterClient.PlayAnim
local SicknessAnimations = { 'idle_a', 'idle_b', 'idle_c' }
local FemaleRiverWashAnimations = { 'idle_a', 'idle_b', 'idle_c' }
local MaleRiverWashAnimations = { 'idle_d', 'idle_e', 'idle_f' }
local ScenarioPointLimit = 10
local ScenarioPointAlignment = 8
local GetScenarioPointsInAreaHash = 0x345EC3B7EBDE1CB5

local function genderedAnimation(playerPed, maleDict, femaleDict, animName)
    return IsPedMale(playerPed) and maleDict or femaleDict, animName
end

---@param acceptedHashes table<number, boolean>
---@return number|nil
local function findNearbyScenarioPoint(acceptedHashes)
    local coords = WaterClient.GetCoords()
    local data = DataView.ArrayBuffer((ScenarioPointLimit + 1) * ScenarioPointAlignment)
    local count = Citizen.InvokeNative(
        GetScenarioPointsInAreaHash,
        coords.x,
        coords.y,
        coords.z,
        2.0,
        data:Buffer(),
        ScenarioPointLimit,
        Citizen.ResultAsInteger()
    )

    count = math.floor(math.min(math.max(tonumber(count) or 0, 0), ScenarioPointLimit))
    for index = 1, count do
        local scenario = data:GetInt32(ScenarioPointAlignment * index)
        if scenario and acceptedHashes[GetScenarioPointType(scenario)] then
            return scenario
        end
    end

    return nil
end

local PumpScenarioHashes = {
    [joaat('PROP_HUMAN_PUMP_WATER')] = true,
    [joaat('PROP_HUMAN_PUMP_WATER_FEMALE_B')] = true,
    [joaat('PROP_HUMAN_PUMP_WATER_MALE_A')] = true,
}

local BucketPumpScenarioHashes = {
    [joaat('PROP_HUMAN_PUMP_WATER')] = true,
    [joaat('PROP_HUMAN_PUMP_WATER_BUCKET')] = true,
    [joaat('PROP_HUMAN_PUMP_WATER_BUCKET_MALE_A')] = true,
    [joaat('PROP_HUMAN_PUMP_WATER_FEMALE_B')] = true,
    [joaat('PROP_HUMAN_PUMP_WATER_MALE_A')] = true,
}

local function FillContainer(pumpAnim, modelName, modelHash, notificationMessage)
    DBG:Info(string.format('Filling container with model: %s', tostring(modelName)))
    WaterClient.SetFilling(true)
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    if not pumpAnim then
        local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_HAND')
        if not LoadModel(modelHash, modelName) then
            WaterClient.SetFilling(false)
            return
        end

        local container = WaterClient.CreateTrackedObject(modelHash, WaterClient.GetCoords())
        if not container then
            WaterClient.SetFilling(false)
            return
        end
        AttachEntityToEntity(container, playerPed, boneIndex, 0.12, 0.00, -0.10, 306.0, 18.0, 0.0, true, true, false, true, 2, true, false, false)

        local animDict, animName = genderedAnimation(
            playerPed,
            'amb_work@world_human_crouch_inspect@male_a@idle_a',
            'amb_work@world_human_crouch_inspect@female_a@idle_a',
            'idle_a'
        )
        local exitDict = IsPedMale(playerPed)
            and 'amb_work@world_human_crouch_inspect@male_a@stand_exit'
            or 'amb_work@world_human_crouch_inspect@female_a@stand_exit'

        if not LoadAnim(animDict) or not LoadAnim(exitDict) then
            WaterClient.DeleteTrackedObject(container)
            WaterClient.SetFilling(false)
            return
        end

        TaskSetCrouchMovement(playerPed, true, 0, false)
        Wait(1500)
        TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 3, 1.0, false, false, false)
        Wait(10000)
        TaskPlayAnim(playerPed, exitDict, 'exit_front', 1.0, 1.0, 1200, 1, 0.0, false, false, false)
        Wait(1200)
        TaskSetCrouchMovement(playerPed, false, 0, false)

        WaterClient.DeleteTrackedObject(container)
    else
        local scenario = findNearbyScenarioPoint(PumpScenarioHashes)
        local taskRun = scenario ~= nil

        if scenario then
            ClearPedTasksImmediately(playerPed)
            TaskUseScenarioPoint(playerPed, scenario, '', -1.0, true, false, 0, false, -1.0, true)
            Wait(15000)
        end

        if not taskRun then
            local animDict, animName = genderedAnimation(
                playerPed,
                'amb_work@prop_human_pump_water@male_a@idle_a',
                'amb_work@prop_human_pump_water@female_b@idle_a',
                'idle_a_waterpump'
            )
            PlayAnim(animDict, animName, 1, 10000)
        end
    end

    ClearPedTasks(playerPed)
    WaterClient.SetFilling(false)

    if Config.showMessages then
        Core.NotifyRightTip(notificationMessage, 4000)
    end
    DBG:Info('Container filled successfully.')
end

function CanteenFill(pumpAnim)
    DBG:Info('Filling canteen.')
    FillContainer(pumpAnim, 'p_cs_canteen_hercule', joaat('p_cs_canteen_hercule'), _U('fillingComplete'))
end

function BottleFill(pumpAnim)
    DBG:Info('Filling bottle.')
    FillContainer(pumpAnim, 'p_bottlebeer01a_2', joaat('p_bottlebeer01a_2'), _U('fillingComplete'))
end

function BucketFill(pumpAnim)
    DBG:Info('Filling bucket.')
    WaterClient.SetFilling(true)
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    if not pumpAnim then
        local conditionalAnim = (IsPedMale(playerPed) and 'WORLD_HUMAN_BUCKET_FILL_MALE_B') or 'WORLD_HUMAN_BUCKET_FILL_FEMALE_A'

        TaskStartScenarioInPlaceHash(playerPed, joaat('WORLD_HUMAN_BUCKET_FILL'), 8000, true, joaat(conditionalAnim), -1, false)
        Wait(8000)
        ClearPedTasks(playerPed, true, true)
        Wait(4000)
        HidePedWeapons(playerPed, 2, true)
    else
        local scenario = findNearbyScenarioPoint(BucketPumpScenarioHashes)
        local taskRun = scenario ~= nil

        if scenario then
            ClearPedTasksImmediately(playerPed)
            TaskUseScenarioPoint(playerPed, scenario, '', -1.0, true, false, 0, false, -1.0, true)
            Wait(15000)
            ClearPedTasks(playerPed, true, true)
            Wait(5000)
            HidePedWeapons(playerPed, 2, true)
        end

        if not taskRun then
            local animDict, animName = genderedAnimation(
                playerPed,
                'amb_work@prop_human_pump_water@male_a@idle_a',
                'amb_work@prop_human_pump_water@female_b@idle_a',
                'idle_a_waterpump'
            )
            PlayAnim(animDict, animName, 1, 10000)
        end
    end

    WaterClient.SetFilling(false)
    if Config.showMessages then
        Core.NotifyRightTip(_U('fillingComplete'), 4000)
    end
    DBG:Info('Bucket filled successfully.')
end

RegisterNetEvent('bcc-water:UseCanteen', function(dirty)
    DBG:Info('Using canteen.')
    DrinkCanteen(dirty)
end)

function DrinkCanteen(dirty)
    DBG:Info('Drinking from canteen.')
    WaterClient.SetFilling(true)
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    local modelHash = joaat('p_cs_canteen_hercule')

    local animDict = 'amb_rest_drunk@world_human_drinking@flask@male_a@idle_a'
    local exitDict = dirty
        and 'amb_rest_drunk@world_human_drinking@flask@male_a@react_look@exit@dismissive'
        or 'amb_rest_drunk@world_human_drinking@flask@male_a@react_look@exit@relieved'

    if not LoadAnim(animDict) or not LoadAnim(exitDict)
            or not LoadModel(modelHash, 'p_cs_canteen_hercule') then
        WaterClient.SetFilling(false)
        return
    end
    local canteen = WaterClient.CreateTrackedObject(modelHash, WaterClient.GetCoords())
    if not canteen then
        WaterClient.SetFilling(false)
        return
    end

    TaskPlayAnim(playerPed, animDict, 'idle_a', 1.0, 1.0, -1, 31, 0.0, false, false, false)
    AttachEntityToEntity(canteen, playerPed, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true, false, false)
    Wait(4500)
    TaskPlayAnim(playerPed, exitDict, 'react_look_front_exit', 1.0, 1.0, 1500, 1, 0.0, false, false, false)
    Wait(1500)
    WaterClient.DeleteTrackedObject(canteen)
    ClearPedTasks(playerPed)
    WaterClient.SetFilling(false)
    PlayerStats(dirty)
    if dirty and Core.Callback.TriggerAwait('bcc-water:RollSickness') then
        ApplySicknessEffect()
    end
end

local function DrinkFromBucket(dirty)
    DBG:Info(('Drinking from bucket. Dirty: %s'):format(tostring(dirty)))
    local playerPed = PlayerPedId()
    local animDict, animName = genderedAnimation(
        playerPed,
        'amb_rest_drunk@world_human_bucket_drink@ground@male_a@idle_a',
        'amb_rest_drunk@world_human_bucket_drink_ladle@ground@female_b@idle_a',
        'idle_a'
    )
    PlayAnim(animDict, animName, 1, 10000)
    PlayerStats(dirty)
    if dirty and Core.Callback.TriggerAwait('bcc-water:RollSickness') then
        ApplySicknessEffect()
    end
end

function WildDrink()
    DBG:Info('Drinking from wild water.')
    DrinkFromBucket(true)
end

RegisterNetEvent('bcc-water:DrinkBucket', function(dirty)
    DrinkFromBucket(dirty == true)
end)

RegisterNetEvent('bcc-water:BeginPurification', function(methodName, itemId)
    if WaterClient.IsFilling() or IsEntityDead(PlayerPedId()) then
        TriggerServerEvent('bcc-water:CancelPurification')
        return
    end

    local animation = Config.purification.animation
    local animationDictionary = IsPedMale(PlayerPedId())
        and animation.maleDictionary
        or animation.femaleDictionary
    local completed = PlayAnim(
        animationDictionary,
        animation.name,
        1,
        math.max(0, tonumber(animation.duration) or 3000)
    )

    if completed and not IsEntityDead(PlayerPedId()) then
        TriggerServerEvent('bcc-water:CompletePurification', methodName, itemId)
    else
        TriggerServerEvent('bcc-water:CancelPurification')
    end
end)

RegisterNetEvent('bcc-water:DrinkBottle', function(wild)
    DBG:Info(string.format('Drinking from bottle. Wild: %s', tostring(wild)))
    WaterClient.SetFilling(true)
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    local modelHash = joaat('p_bottlebeer01a_2')
    local animDict = 'amb_rest_drunk@world_human_drinking@male_a@idle_a'
    local animName = 'idle_a'

    if not LoadAnim(animDict) or not LoadModel(modelHash, 'p_bottlebeer01a_2') then
        WaterClient.SetFilling(false)
        return
    end
    local bottle = WaterClient.CreateTrackedObject(modelHash, WaterClient.GetCoords())
    if not bottle then
        WaterClient.SetFilling(false)
        return
    end

    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(bottle, playerPed, boneIndex, 0.05, 0.0, 0.05, 15.0, 175.0, 0.0, true, true, false, true, 1, true, false, false)
    Wait(5500)
    WaterClient.DeleteTrackedObject(bottle)
    ClearPedTasks(playerPed)
    WaterClient.SetFilling(false)

    -- Apply effects
    if wild and Core.Callback.TriggerAwait('bcc-water:RollSickness') then
        ApplySicknessEffect()
    end

    PlayerStats(wild)
end)

function PumpDrink()
    DBG:Info('Drinking from pump water.')
    local animDict, animName = genderedAnimation(
        PlayerPedId(),
        'amb_work@prop_human_pump_water@male_a@idle_c',
        'amb_work@prop_human_pump_water@female_b@idle_c',
        'idle_g_waterpump'
    )
    PlayAnim(animDict, animName, 1, 5000)
    PlayerStats(false)
end

function WashPlayer(animType)
    DBG:Info(string.format('Washing player with animation type: %s', tostring(animType)))
    local playerPed = PlayerPedId()

    -- Check for soap requirement
    if Config.requireSoap then
        local soapUsed, usedSoapItem = Core.Callback.TriggerAwait('bcc-water:UseSoapItem')
        if not soapUsed then
            if Config.showMessages then
                local message = usedSoapItem and _U('failedToUseSoap') or _U('noSoap')
                Core.NotifyRightTip(message, 4000)
            end
            DBG:Info(usedSoapItem and 'Failed to use soap item.'
                or 'Player does not have any required soap items.')
            return
        end

        if Config.consumeSoap then
            DBG:Info(string.format('Soap item used for washing: %s', usedSoapItem or 'unknown'))
        else
            DBG:Info(string.format('Reusable soap item used for washing: %s', usedSoapItem or 'unknown'))
        end
    end

    local animDict
    local animName

    if animType == 'ground' then
        if IsPedMale(playerPed) then
            animDict = 'amb_misc@world_human_wash_kneel_river@male_b@idle_b'
            animName = MaleRiverWashAnimations[math.random(1, #MaleRiverWashAnimations)]
        else
            animDict = 'amb_misc@world_human_wash_kneel_river@female_a@idle_a'
            animName = FemaleRiverWashAnimations[math.random(1, #FemaleRiverWashAnimations)]
        end
    elseif animType == 'stand' then
        animDict = IsPedMale(playerPed)
            and 'amb_misc@world_human_wash_face_bucket@table@male_a@idle_d'
            or 'amb_misc@world_human_wash_face_bucket@table@female_a@idle_d'
        animName = 'idle_l'
    else
        print('Invalid animType provided:', animType)
        return
    end

    PlayAnim(animDict, animName, 1, 10000)

    ClearPedEnvDirt(playerPed)
    ClearPedDamageDecalByZone(playerPed, 10, 'ALL')
    ClearPedBloodDamage(playerPed)
    SetPedDirtCleaned(playerPed, 0.0, -1, true, true)

    if Config.app == 'pos' then
        exports['POS-Metabolism']:ShowerEvent()
    end

    if Config.app == 'bln' then
        exports.bln_hud:PlayerWash()
    end

    if Config.app == 'bcc_corehud' then
        exports['bcc-corehud']:SetCleanStats(100.0)
    end

    DBG:Info('Player washed successfully.')
end

function ApplySicknessEffect(durationOverride)
    if IsSick then
        DBG:Info('Sickness effect already active, skipping.')
        return
    end

    IsSick = true
    local duration = tonumber(durationOverride) or Config.sickness.duration
    local tickInterval = Config.sickness.interval
    local healthPerTick = Config.sickness.health
    local remaining = duration

    DBG:Info('Sickness effect applied.')

    Core.NotifyRightTip(_U('feelingSick'), 4000)

    -- Animation + Health Tick Thread
    CreateThread(function()
        DBG:Info('Starting sickness animation/health tick thread.')
        local playerPed = PlayerPedId()

        while IsSick and remaining > 0 do
            ClearPedTasks(playerPed)
            DBG:Info('Cleared playerPed tasks for sickness animation.')

            local currentHealth = GetEntityHealth(playerPed)
            local newHealth = currentHealth - healthPerTick

            -- Play animation
            if (remaining > (duration / 2)) and (currentHealth > 200) then
                local sickAnimation = SicknessAnimations[
                    math.random(1, #SicknessAnimations)
                ]
                DBG:Info(string.format('Playing sickness animation: %s', sickAnimation))
                PlayAnim('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a',
                    sickAnimation, 1, 5000)
            else
                local vomit = math.random(1, 2) == 1 and 'idle_g' or 'idle_h'
                DBG:Info(string.format('Playing vomiting animation: %s', vomit))
                PlayAnim('amb_misc@world_human_vomit@male_a@idle_c', vomit, 1, 5000)
            end

            -- The antidote may be used while the animation is playing.
            if not IsSick then
                break
            end

            -- Apply health damage
            if newHealth <= 0 then
                DBG:Info('Player health reached 0 during sickness. Killing player.')
                SetEntityHealth(playerPed, 0, 0)
                break
            else
                SetEntityHealth(playerPed, newHealth, 0)
                DBG:Info(string.format('Health reduced by sickness. New health: %d', newHealth))
            end

            Wait(tickInterval * 1000)
            remaining = remaining - tickInterval
        end

        if IsSick then
            DBG:Info('Sickness ended. Forcing death if still alive.')
            Core.NotifyRightTip(_U('succumbed'), 6000)

            SetEntityHealth(playerPed, 0, 0)
            IsSick = false
            ClearPedTasks(playerPed)

            Wait(1000)
            TriggerServerEvent('bcc-water:ClearSickness')
            DBG:Info('Sickness effect fully cleared.')
        end
    end)
end

RegisterNetEvent('bcc-water:ForceSicknessDeath', function()
    IsSick = false
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    Core.NotifyRightTip(_U('succumbed'), 6000)
    SetEntityHealth(playerPed, 0, 0)
    CreateThread(function()
        Wait(1000)
        TriggerServerEvent('bcc-water:ClearSickness')
    end)
end)

RegisterNetEvent('bcc-water:BeginAntidote', function(itemId)
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) then
        TriggerServerEvent('bcc-water:CancelAntidote')
        return
    end

    ClearPedTasks(playerPed)
    local animation = Config.antidoteAnimation
    local completed = PlayAnim(
        animation.dictionary,
        animation.name,
        1,
        math.max(0, tonumber(animation.duration) or 2000)
    )

    if completed and not IsEntityDead(PlayerPedId()) then
        TriggerServerEvent('bcc-water:CompleteAntidote', itemId)
    else
        TriggerServerEvent('bcc-water:CancelAntidote')
    end
end)

RegisterNetEvent('bcc-water:CureSickness', function()
    IsSick = false
    ClearPedTasks(PlayerPedId())
    Core.NotifyRightTip(_U('feelingBetter'), 4000)
    DBG:Info('Sickness cured by antidote.')
end)

function PlayerStats(isWild)
    DBG:Info('Updating player stats.')
    local playerPed = PlayerPedId()
    local health = Citizen.InvokeNative(0x36731AC041289BB1, playerPed, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, playerPed, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local thirst = isWild and Config.wildDrink.thirst or Config.canteenDrink.thirst
    local app = Config.app

    local appUpdate = {
        vorp = function() TriggerEvent('vorpmetabolism:changeValue', 'Thirst', thirst * 10) end,
        fred_free = function() TriggerEvent('fred:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0) end,
        outsider = function() local data = { AddThirst = thirst } exports.outsider_needs:SetNeedsData(data) end,
        fred_paid_v1 = function() TriggerEvent('fred_meta:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0) end,
        fred_paid_v2 = function() exports.fred_metabolism:consume('thirst', thirst) end,
        rsd = function() TriggerEvent('rsd_metabolism:SetMeta', { drink = thirst }) end,
        nxt = function() TriggerServerEvent('hud.decrease', 'thirst', thirst * 10) end,
        andrade = function() TriggerEvent('hud:client:changeValue', 'Thirst', thirst) end,
        fx_hud = function() exports['fx-hud']:setStatus('thirst', thirst) end,
        mega = function() local ClientAPI = exports['mega_metabolism']:api() ClientAPI.addMeta('water', thirst) end,
        pos = function() exports['POS-Metabolism']:UpdateMultipleStatus({ ['water'] = thirst, ['piss'] = thirst * 0.5 }) end,
        bln = function() exports.bln_hud:AddThirst(thirst) end,
        ss = function() exports['SS-Metabolism']:AddThirsty(thirst) end,
        bcc_corehud = function()
            local thirstDelta = tonumber(thirst) or 0
            if thirstDelta > 0 and thirstDelta <= 10 and thirstDelta == math.floor(thirstDelta) then
                thirstDelta = thirstDelta * 10
            end
            exports['bcc-corehud']:AddNeed('thirst', thirstDelta)
        end,
        cas = function() exports['cas-metabolism']:Add('thirst', thirst) end,
    }

    local function updateAttribute(attributeIndex, value, maxValue)
        local newValue = math.max(0, math.min(maxValue, value))
        SetAttributeCoreValue(playerPed, attributeIndex, newValue)
    end

    if appUpdate[app] then
        appUpdate[app]()

        local healthConfig = isWild and Config.wildDrink.health or Config.canteenDrink.health
        local staminaConfig = isWild and Config.wildDrink.stamina or Config.canteenDrink.stamina
        local gainHealth = not isWild or Config.wildDrink.gainHealth == true
        local gainStamina = not isWild or Config.wildDrink.gainStamina == true

        if healthConfig > 0 then
            updateAttribute(0, gainHealth and (health + healthConfig) or (health - healthConfig), 100)
        end

        if staminaConfig > 0 then
            updateAttribute(1, gainStamina and (stamina + staminaConfig) or (stamina - staminaConfig), 100)
        end

        PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
    else
        DBG:Error(('Unsupported Config.app value: %s'):format(tostring(app)))
    end
    DBG:Info('Player stats updated successfully.')
end
