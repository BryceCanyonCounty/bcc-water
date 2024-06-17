-- Fill Canteen Animations
function CanteenFill(pumpAnim)
    Filling = true
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    if not pumpAnim then
        local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_HAND')
        local modelHash = joaat('p_cs_canteen_hercule')
        LoadModel(modelHash)
        Canteen = CreateObject(modelHash, PlayerCoords, true, true, false, false, true)
        SetEntityVisible(Canteen, true)
        SetEntityAlpha(Canteen, 255, false)
        SetModelAsNoLongerNeeded(modelHash)
        AttachEntityToEntity(Canteen, playerPed, boneIndex, 0.12, 0.09, -0.05, 306.0, 18.0, 0.0, true, true, false, true, 2, true)

        local dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a'
        LoadAnim(dict)
        TaskSetCrouchMovement(playerPed, true, 0, false)
        Wait(1500)
        TaskPlayAnim(playerPed, dict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
        Wait(10000)
        TaskSetCrouchMovement(playerPed, false, 0, false)
        Wait(1500)
        DeleteObject(Canteen)

    else
        local taskRun = false
        -- Dataview snippet credit to Xakra and Ricx
        local DataStruct = DataView.ArrayBuffer(256 * 4)
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
        VORPcore.NotifyRightTip(_U('fullCanteen'), 5000)
    end
end

-- Fill Bucket Animations
function BucketFill(pumpAnim)
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
        -- Dataview snippet credit to Xakra and Ricx
        local DataStruct = DataView.ArrayBuffer(256 * 4)
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
        VORPcore.NotifyRightTip(_U('fullBucket'), 5000)
    end
end

function PlayAnim(dict, anim)
    local playerPed = PlayerPedId()
    LoadAnim(dict)
    HidePedWeapons(playerPed, 2, true)
    TaskPlayAnim(playerPed, dict, anim, 1.0, 1.0, -1, 17, 1.0, false, false, false)
    Wait(10000)
    ClearPedTasks(playerPed)
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
    if not PromptsStarted then
        FillCanteenPrompt = PromptRegisterBegin()
        PromptSetControlAction(FillCanteenPrompt, Config.keys.fillCanteen)
        PromptSetText(FillCanteenPrompt, CreateVarString(10, 'LITERAL_STRING', _U('fillCanteen')))
        PromptSetEnabled(FillCanteenPrompt, true)
        PromptSetHoldMode(FillCanteenPrompt, 1000)
        PromptSetGroup(FillCanteenPrompt, WaterGroup)
        PromptSetGroup(FillCanteenPrompt, PumpGroup)
        PromptRegisterEnd(FillCanteenPrompt)

        FillBucketPrompt = PromptRegisterBegin()
        PromptSetControlAction(FillBucketPrompt, Config.keys.fillBucket)
        PromptSetText(FillBucketPrompt, CreateVarString(10, 'LITERAL_STRING', _U('fillBucket')))
        PromptSetEnabled(FillBucketPrompt, true)
        PromptSetHoldMode(FillBucketPrompt, 1000)
        PromptSetGroup(FillBucketPrompt, WaterGroup)
        PromptSetGroup(FillBucketPrompt, PumpGroup)
        PromptRegisterEnd(FillBucketPrompt)

        WashPrompt = PromptRegisterBegin()
        PromptSetControlAction(WashPrompt, Config.keys.wash)
        PromptSetText(WashPrompt, CreateVarString(10, 'LITERAL_STRING', _U('wash')))
        PromptSetEnabled(WashPrompt, true)
        PromptSetHoldMode(WashPrompt, 1000)
        PromptSetGroup(WashPrompt, WaterGroup)
        PromptSetGroup(WashPrompt, PumpGroup)
        PromptRegisterEnd(WashPrompt)

        DrinkPrompt = PromptRegisterBegin()
        PromptSetControlAction(DrinkPrompt, Config.keys.drink)
        PromptSetText(DrinkPrompt, CreateVarString(10, 'LITERAL_STRING', _U('drink')))
        PromptSetEnabled(DrinkPrompt, true)
        PromptSetHoldMode(DrinkPrompt, 1000)
        PromptSetGroup(DrinkPrompt, WaterGroup)
        PromptSetGroup(DrinkPrompt, PumpGroup)
        PromptRegisterEnd(DrinkPrompt)

        PromptsStarted = true
    end
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
    PromptDelete(FillCanteenPrompt)
    PromptDelete(FillBucketPrompt)
    PromptDelete(WashPrompt)
    PromptDelete(DrinkPrompt)
end)