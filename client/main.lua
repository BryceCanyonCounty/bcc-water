VORPcore = exports.vorp_core:GetCore()
-- Prompts
PumpGroup = GetRandomIntInRange(0, 0xffffff)
WaterGroup = GetRandomIntInRange(0, 0xffffff)
-- Water
Filling = false
UseCanteen = true
PromptsStarted = false
PlayerCoords = vector3(0, 0, 0)

CreateThread(function()
    StartPrompts()

    if Config.pumpsEnabled then
        TriggerEvent('bcc-water:PumpWater')
    end

    if Config.wildEnabled then
        TriggerEvent('bcc-water:WildWater')
    end

    while true do
        Wait(1000)
        PlayerCoords = GetEntityCoords(PlayerPedId())
    end
end)

AddEventHandler('bcc-water:PumpWater', function()
    local objects, objectExists
    local pumpCanteen = Config.pumpCanteen
    local pumpBucket = Config.pumpBucket
    while true do
        local playerPed = PlayerPedId()
        local sleep = 1000

        if IsEntityDead(playerPed) then goto END end

        objects = Config.objects
        for i = 1, #objects do
            local object = objects[i]
            objectExists = DoesObjectOfTypeExistAtCoords(PlayerCoords, 0.75, joaat(object), 0)
            if objectExists then break end
        end

        if not objectExists then goto END end

        if not IsPedOnFoot(playerPed) or Filling then goto END end

        sleep = 0
        if Config.usePrompt then

            PromptSetActiveGroupThisFrame(PumpGroup, CreateVarString(10, 'LITERAL_STRING', _U('waterPump')))
            PromptSetVisible(FillCanteenPrompt, pumpCanteen)
            PromptSetVisible(FillBucketPrompt, pumpBucket)

            if pumpCanteen and PromptHasHoldModeCompleted(FillCanteenPrompt) then
                local canFillCanteen = VORPcore.Callback.TriggerAwait('bcc-water:GetCanteenLevel')
                if not canFillCanteen then
                    Filling = false
                    goto END
                end
                CanteenFill(true)
            end

            if pumpBucket and PromptHasHoldModeCompleted(FillBucketPrompt) then
                local canFillBucket = VORPcore.Callback.TriggerAwait('bcc-water:GetBucket')
                if not canFillBucket then
                    Filling = false
                    goto END
                end
                BucketFill(true)
            end

        else
            if pumpCanteen then
                DrawText3Ds(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z + 0.1, '~t6~R~q~ - '.. _U('fillCanteen'))

                if IsControlJustReleased(0, Config.keys.fillCanteen) then
                    local canFillCanteen = VORPcore.Callback.TriggerAwait('bcc-water:GetCanteenLevel')
                    if not canFillCanteen then
                        Filling = false
                        goto END
                    end
                    CanteenFill(true)
                end
            end

            if pumpBucket then
                DrawText3Ds(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, '~t6~E~q~ - ' .. _U('fillBucket'))

                if IsControlJustReleased(0, Config.keys.fillBucket) then
                    local canFillBucket = VORPcore.Callback.TriggerAwait('bcc-water:GetBucket')
                    if not canFillBucket then
                        Filling = false
                        goto END
                    end
                    BucketFill(true)
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

AddEventHandler('bcc-water:WildWater', function()
    local water, foundWater, waterName
    local wildCanteen = Config.wildCanteen
    local wildBucket = Config.wildBucket
    local wildWash = Config.wildWash
    local wildDrink = Config.wildDrink
    while true do
        local playerPed = PlayerPedId()
        local sleep = 1000

        if IsEntityDead(playerPed) then goto END end

        water = GetWaterMapZoneAtCoords(PlayerCoords)
        for _, locationCfg in pairs(Locations) do
            foundWater = false
            if water == locationCfg.hash then
                foundWater = true
                waterName = locationCfg.name
                break
            end
        end

        if not foundWater then goto END end

        if not IsPedOnFoot(playerPed) or not IsEntityInWater(playerPed) then goto END end

        if Config.crouch then
            local crouched = GetPedCrouchMovement(playerPed)
            if crouched == 0 then goto END end
        end

        if not IsPedStill(playerPed) or Filling then goto END end

        sleep = 0
        PromptSetActiveGroupThisFrame(WaterGroup, CreateVarString(10, 'LITERAL_STRING', waterName))
        PromptSetVisible(FillCanteenPrompt, wildCanteen)
        PromptSetVisible(FillBucketPrompt, wildBucket)
        PromptSetVisible(WashPrompt, wildWash)
        PromptSetVisible(DrinkPrompt, wildDrink)

        if wildCanteen and PromptHasHoldModeCompleted(FillCanteenPrompt) then
            local canFillCanteen = VORPcore.Callback.TriggerAwait('bcc-water:GetCanteenLevel')
            if not canFillCanteen then
                Filling = false
                goto END
            end
            CanteenFill(false)
        end
        if wildBucket and PromptHasHoldModeCompleted(FillBucketPrompt) then
            local canFillBucket = VORPcore.Callback.TriggerAwait('bcc-water:GetBucket')
            if not canFillBucket then
                Filling = false
                goto END
            end
            BucketFill(false)
        end
        if wildWash and PromptHasHoldModeCompleted(WashPrompt) then
            WashPlayer()
        end
        if wildDrink and PromptHasHoldModeCompleted(DrinkPrompt) then
            WildDrink()
        end
        ::END::
        Wait(sleep)
    end
end)
