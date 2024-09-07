function DrinkCanteen(level)
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)
    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    local modelHash = joaat('p_cs_canteen_hercule')
    local dict = 'amb_rest_drunk@world_human_drinking@male_a@idle_a'
    local anim = 'idle_a'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    LoadModel(modelHash)
    Canteen = CreateObject(modelHash, PlayerCoords, true, true, false, false, true)
    SetEntityVisible(Canteen, true)
    SetEntityAlpha(Canteen, 255, false)
    SetModelAsNoLongerNeeded(modelHash)
    TaskPlayAnim(playerPed, dict, anim, 1.0, 1.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(Canteen, playerPed, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true, false, false)
    Wait(5500)
    DeleteObject(Canteen)
    ClearPedTasks(playerPed)
    PlayerStats(false)

    -- Canteen Level Messages
    local levelMessage = {
        [2] = _U('message_1'),
        [3] = _U('message_2'),
        [4] = _U('message_3'),
        [5] = _U('message_4')
    }
    if Config.showMessages then
        VORPcore.NotifyRightTip(levelMessage[level], 4000)
    end
end

function WildDrink()
    PlayAnim('amb_rest_drunk@world_human_bucket_drink@ground@male_a@idle_c', 'idle_h')
    PlayerStats(true)
end

function PumpDrink()
    PlayAnim('amb_work@prop_human_pump_water@male_a@idle_c', 'idle_g')
    PlayerStats(true)
end

function WashPlayer(animType)
    local playerPed = PlayerPedId()
    if animType == "ground" then
        PlayAnim('amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d', 'idle_l')
    elseif animType == "stand" then
        PlayAnim('amb_misc@world_human_wash_face_bucket@table@male_a@idle_d', 'idle_l')
    end
    ClearPedEnvDirt(playerPed)
    ClearPedDamageDecalByZone(playerPed, 10, 'ALL')
    ClearPedBloodDamage(playerPed)
    SetPedDirtCleaned(playerPed, 0.0, -1, true, true)
end

RegisterNetEvent('bcc-water:UseCanteen', function()
    if UseCanteen then
        local canDrink = VORPcore.Callback.TriggerAwait('bcc-water:UpdateCanteen')

        if not canDrink then return end

        DrinkCanteen(canDrink)
        UseCanteen = false
        Wait(6000)
        UseCanteen = true
    end
end)

function PlayerStats(isWild)
    local playerPed = PlayerPedId()
    local health = GetAttributeCoreValue(playerPed, 0, Citizen.ResultAsInteger())
    local stamina = GetAttributeCoreValue(playerPed, 1, Citizen.ResultAsInteger())
    local thirst = Config.thirst
    if isWild then
        thirst = Config.wildThirst
    end
    local app = tonumber(Config.app)
    local appUpdate = {
        [1] = function()
            TriggerEvent('vorpmetabolism:changeValue', 'Thirst', thirst * 10)
        end,

        [2] = function()
            TriggerEvent('fred:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
        end,

        [3] = function()
            TriggerServerEvent('outsider_needs:Thirst', isWild)
        end,

        [4] = function()
            TriggerEvent('fred_meta:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0)
        end,

        [5] = function()
            exports.fred_metabolism:consume('thirst' , thirst)
        end,

        [6] = function()
            TriggerEvent('rsd_metabolism:SetMeta', {drink = thirst})
        end,

        [7] = function()
            TriggerServerEvent('hud.decrease', 'thirst', thirst * 10)
        end,

        [8] = function()
            TriggerEvent('hud:client:changeValue', 'Thirst', thirst)
        end,

        [9] = function()
            exports['fx-hud']:setStatus('thirst', thirst)
        end
    }
    if appUpdate[app] then
        appUpdate[app]()
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

                SetAttributeCoreValue(playerPed, 0, newWildHealth)
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

                SetAttributeCoreValue(playerPed, 1, newWildStamina)
            end

            PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
        else
            -- Clean Health
            if Config.health > 0 then
                local newHealth = health + Config.health

                if newHealth > 100 then
                    newHealth = 100
                end

                SetAttributeCoreValue(playerPed, 0, newHealth)
            end

            -- Clean Stamina
            if Config.stamina > 0 then
                local newStamina = stamina + Config.stamina

                if newStamina > 100 then
                    newStamina = 100
                end

                SetAttributeCoreValue(playerPed, 1, newStamina)
            end

            PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
        end
    else
        print('Check Config.app setting for correct metabolism value')
    end
end