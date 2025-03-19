Core = exports.vorp_core:GetCore()
local Prompts = {}
-- Groups
local PumpGroup = GetRandomIntInRange(0, 0xffffff)
local WaterGroup = GetRandomIntInRange(0, 0xffffff)
-- Water
Filling = false
PlayerCoords = vector3(0, 0, 0)
DevModeActive = Config.devMode.active

function DebugPrint(message)
    if DevModeActive then
        print(message)
    end
end

-- Create and start prompts
local function CreatePrompt(keyCode, textKey, groups)
    DebugPrint("Creating prompt with keyCode: " .. keyCode .. ", textKey: " .. textKey)
    local prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, keyCode)
    UiPromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', _U(textKey)))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetHoldMode(prompt, 1000)
    for _, group in ipairs(groups) do
        UiPromptSetGroup(prompt, group, 0)
    end
    UiPromptRegisterEnd(prompt)
    DebugPrint("Prompt created successfully.")
    return prompt
end

local function StartPrompts()
    DebugPrint("Starting prompts...")
    Prompts.FillCanteenPrompt = CreatePrompt(Config.keys.fillCanteen.code, 'fillCanteen', { WaterGroup, PumpGroup })
    Prompts.FillBucketPrompt = CreatePrompt(Config.keys.fillBucket.code, 'fillBucket', { WaterGroup, PumpGroup })
    Prompts.FillBottlePrompt = CreatePrompt(Config.keys.fillBottle.code, 'fillBottle', { WaterGroup, PumpGroup })
    Prompts.WashPrompt = CreatePrompt(Config.keys.wash.code, 'wash', { WaterGroup, PumpGroup })
    Prompts.DrinkPrompt = CreatePrompt(Config.keys.drink.code, 'drink', { WaterGroup, PumpGroup })
    DebugPrint("Prompts started successfully.")
end

-- Create prompt text on-screen when not using prompt buttons
local function DrawText(x, y, z, text)
    local _, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    BgSetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    BgSetTextColor(255, 255, 255, 215)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text, Citizen.ResultAsLong()), _x, _y)
end

-- Start main functions when character is selected
RegisterNetEvent('vorp:SelectedCharacter', function()
    DebugPrint("Character selected, starting main functions...")
    StartPrompts()

    if Config.pump.active then
        DebugPrint("Triggering PumpWater event.")
        TriggerEvent('bcc-water:PumpWater')
    end

    if Config.wild.active then
        DebugPrint("Triggering WildWater event.")
        TriggerEvent('bcc-water:WildWater')
    end

    while true do
        Wait(1000)
        PlayerCoords = GetEntityCoords(PlayerPedId())
    end
 end)

 -- Command to restart main functions for development
CreateThread(function()
    if Config.devMode.active then
        RegisterCommand(Config.devMode.command, function()
            DebugPrint("Restarting main functions for development...")
            StartPrompts()

            if Config.pump.active then
                DebugPrint("Triggering PumpWater event for development.")
                TriggerEvent('bcc-water:PumpWater')
            end

            if Config.wild.active then
                DebugPrint("Triggering WildWater event for development.")
                TriggerEvent('bcc-water:WildWater')
            end

            while true do
                Wait(1000)
                PlayerCoords = GetEntityCoords(PlayerPedId())
            end
        end, false)
    end
end)

AddEventHandler('bcc-water:PumpWater', function()
    DebugPrint("PumpWater event triggered.")
    local objects, objectExists
    local pumpActions = {
        {configKey = 'canteen', prompt = 'FillCanteenPrompt', callback = 'bcc-water:GetCanteenLevel', func = CanteenFill, param = true, fullKey = 'fillCanteen', offset = 0.2},
        {configKey = 'bucket', prompt = 'FillBucketPrompt', callback = 'bcc-water:GetItem', itemType = 'bucket', func = BucketFill, param = true, fullKey = 'fillBucket', offset = 0.1},
        {configKey = 'bottle', prompt = 'FillBottlePrompt', callback = 'bcc-water:GetItem', itemType = 'bottle', func = BottleFill, param = true, fullKey = 'fillBottle', offset = 0},
        {configKey = 'wash', prompt = 'WashPrompt', func = WashPlayer, param = 'stand', fullKey = 'wash', offset = 0.3},
        {configKey = 'drink', prompt = 'DrinkPrompt', func = PumpDrink, param = nil, fullKey = 'drink', offset = 0.4}
    }

    while true do
        local playerPed = PlayerPedId()
        local sleep = 1000

        if IsEntityDead(playerPed) or not IsPedOnFoot(playerPed) or Filling then goto END end

        objects = Config.objects
        objectExists = false
        for _, object in ipairs(objects) do
            if DoesObjectOfTypeExistAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 0.75, joaat(object), false) then
                objectExists = true
                DebugPrint("Object found: " .. object)
                break
            end
        end

        if not objectExists then goto END end

        sleep = 0

        if Config.usePrompt then
            UiPromptSetActiveGroupThisFrame(PumpGroup, CreateVarString(10, 'LITERAL_STRING', _U('waterPump')))

            for _, action in ipairs(pumpActions) do
                if Config.pump[action.configKey] and PromptHasHoldModeCompleted(Prompts[action.prompt]) then
                    local canPerformAction = true
                    if action.callback then
                        if action.itemType then
                            canPerformAction = Core.Callback.TriggerAwait(action.callback, action.itemType)
                        else
                            canPerformAction = Core.Callback.TriggerAwait(action.callback)
                        end
                    end
                    if canPerformAction then
                        if action.param then
                            action.func(action.param)
                        else
                            action.func()
                        end
                        DebugPrint("Action performed: " .. action.fullKey)
                    else
                        Filling = false
                        goto END
                    end
                end
            end
        else
            for _, action in ipairs(pumpActions) do
                if Config.pump[action.configKey] then
                    local keyCode = Config.keys[action.fullKey].code
                    local keyChar = Config.keys[action.fullKey].char or tostring(keyCode)
                    local text = _U(action.fullKey)
                    DrawText(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z + (action.offset or 0), '~t6~' .. keyChar .. '~q~ - ' .. text)
                    if IsControlJustReleased(0, keyCode) then
                        local canPerformAction = true
                        if action.callback then
                            if action.itemType then
                                canPerformAction = Core.Callback.TriggerAwait(action.callback, action.itemType)
                            else
                                canPerformAction = Core.Callback.TriggerAwait(action.callback)
                            end
                        end
                        if canPerformAction then
                            if action.param then
                                action.func(action.param)
                            else
                                action.func()
                            end
                            DebugPrint("Action performed: " .. action.fullKey)
                        else
                            Filling = false
                            goto END
                        end
                    end
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

AddEventHandler('bcc-water:WildWater', function()
    DebugPrint("WildWater event triggered.")
    local water, foundWater, waterName
    local wildActions = {
        {configKey = 'canteen', prompt = 'FillCanteenPrompt', callback = 'bcc-water:GetCanteenLevel', func = CanteenFill, param = false, fullKey = 'fillCanteen'},
        {configKey = 'bucket', prompt = 'FillBucketPrompt', callback = 'bcc-water:GetItem', itemType = 'bucket', func = BucketFill, param = false, fullKey = 'fillBucket'},
        {configKey = 'bottle', prompt = 'FillBottlePrompt', callback = 'bcc-water:GetItem', itemType = 'bottle', func = BottleFill, param = false, fullKey = 'fillBottle'},
        {configKey = 'wash', prompt = 'WashPrompt', func = WashPlayer, param = 'ground', fullKey = 'wash'},
        {configKey = 'drink', prompt = 'DrinkPrompt', func = WildDrink, param = nil, fullKey = 'drink'}
    }

    while true do
        local playerPed = PlayerPedId()
        local sleep = 1000

        if IsEntityDead(playerPed) or not IsPedOnFoot(playerPed) or not IsEntityInWater(playerPed) then goto END end

        water = GetWaterMapZoneAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
        foundWater = false
        for _, locationCfg in pairs(Locations) do
            if water == locationCfg.hash then
                foundWater = true
                waterName = locationCfg.name
                DebugPrint("Water found: " .. waterName)
                break
            end
        end

        if not foundWater then goto END end

        if (Config.crouch and GetPedCrouchMovement(playerPed) == 0) or not IsPedStill(playerPed) or Filling then goto END end

        sleep = 0
        UiPromptSetActiveGroupThisFrame(WaterGroup, CreateVarString(10, 'LITERAL_STRING', waterName))

        for _, action in ipairs(wildActions) do
            if Config.wild[action.configKey] and PromptHasHoldModeCompleted(Prompts[action.prompt]) then
                local canPerformAction = true
                if action.callback then
                    if action.itemType then
                        canPerformAction = Core.Callback.TriggerAwait(action.callback, action.itemType)
                    else
                        canPerformAction = Core.Callback.TriggerAwait(action.callback)
                    end
                end
                if canPerformAction then
                    if action.param then
                        action.func(action.param)
                    else
                        action.func()
                    end
                    DebugPrint("Action performed: " .. action.fullKey)
                else
                    Filling = false
                    goto END
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    DebugPrint("Resource stopped, cleaning up...")
    ClearPedTasksImmediately(PlayerPedId())

    if Canteen then
        DeleteObject(Canteen)
    end

    if Container then
        DeleteObject(Container)
    end

    for name, prompt in pairs(Prompts) do
        UiPromptDelete(prompt)
        Prompts[name] = nil
    end
    DebugPrint("Cleanup complete.")
end)