Core = exports.vorp_core:GetCore()
-- Prompts
local Prompts = {}
local PumpGroup = GetRandomIntInRange(0, 0xffffff)
local WaterGroup = GetRandomIntInRange(0, 0xffffff)
-- Water
Filling = false
PlayerCoords = vector3(0, 0, 0)
DevModeActive = Config.devMode.active


function DebugPrint(message)
    if DevModeActive then
        print('^1[DEV MODE] ^4' .. message)
    end
end

-- Create and start prompts
local function CreatePrompt(keyCode, textKey, groups)
    DebugPrint('Creating prompt with keyCode: ' .. keyCode .. ', textKey: ' .. textKey)
    local prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, keyCode)
    UiPromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', _U(textKey)))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetHoldMode(prompt, 1000)
    for _, group in ipairs(groups) do
        UiPromptSetGroup(prompt, group, 0)
    end
    UiPromptRegisterEnd(prompt)
    DebugPrint('Prompt created successfully.')
    return prompt
end

local function StartPrompts()
    DebugPrint('Starting prompts...')
    Prompts.FillCanteenPrompt = CreatePrompt(Config.keys.fillCanteen.code, 'fillCanteen', { WaterGroup, PumpGroup })
    Prompts.FillBucketPrompt = CreatePrompt(Config.keys.fillBucket.code, 'fillBucket', { WaterGroup, PumpGroup })
    Prompts.FillBottlePrompt = CreatePrompt(Config.keys.fillBottle.code, 'fillBottle', { WaterGroup, PumpGroup })
    Prompts.WashPrompt = CreatePrompt(Config.keys.wash.code, 'wash', { WaterGroup, PumpGroup })
    Prompts.DrinkPrompt = CreatePrompt(Config.keys.drink.code, 'drink', { WaterGroup, PumpGroup })
    DebugPrint('Prompts started successfully.')
end

-- Create prompt text on-screen when not using prompt buttons
local function DrawText(x, y, z, text)
    local _, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    BgSetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    BgSetTextColor(255, 255, 255, 215)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text, Citizen.ResultAsLong()), _x, _y)
end

---@param itemType string
---@param pump boolean
local function ManageItems(itemType, pump)
    DebugPrint('ManageItems function called with itemType: ' .. itemType .. ', pump: ' .. tostring(pump))

    local config = pump and Config.pump or Config.wild

    if (itemType == 'bucket' and config.multi.buckets) or (itemType == 'bottle' and config.multi.bottles) then
        OpenInputMenu(itemType, pump)
    else
        if Core.Callback.TriggerAwait('bcc-water:GetItem', itemType, 1, pump) then
            if itemType == 'bucket' then
                BucketFill(pump)
            else
                BottleFill(pump)
            end
        end
    end
end

local function PlayerLocation()
    CreateThread(function()
        while true do
            Wait(1000)
            PlayerCoords = GetEntityCoords(PlayerPedId())
        end
    end)
end

-- Start main functions when character is selected
RegisterNetEvent('vorp:SelectedCharacter', function()
    DebugPrint('Character selected, starting main functions...')

    StartPrompts()
    PlayerLocation()

    if Config.pump.active then
        DebugPrint('Triggering PumpWater event.')
        TriggerEvent('bcc-water:PumpWater')
    end

    if Config.wild.active then
        DebugPrint('Triggering WildWater event.')
        TriggerEvent('bcc-water:WildWater')
    end

    DebugPrint('Checking server for player sickness.')
    local isSick = Core.Callback.TriggerAwait('bcc-water:CheckSickness')
    if isSick then
        DebugPrint('Waiting to apply sickness effect...')
        Wait(30000)
        ApplySicknessEffect()
    end
end)

 -- Command to restart main functions for development
CreateThread(function()
    if Config.devMode.active then
        RegisterCommand(Config.devMode.command, function()
            DebugPrint('Restarting main functions for development...')

            StartPrompts()
            PlayerLocation()

            if Config.pump.active then
                DebugPrint('Triggering PumpWater event for development.')
                TriggerEvent('bcc-water:PumpWater')
            end

            if Config.wild.active then
                DebugPrint('Triggering WildWater event for development.')
                TriggerEvent('bcc-water:WildWater')
            end

            DebugPrint('Checking server for player sickness.')
            local isSick = Core.Callback.TriggerAwait('bcc-water:CheckSickness')
            if isSick then
                ApplySicknessEffect()
            end
        end, false)
    end
end)

local function HandleWaterInteraction(configType, promptGroup, actions, promptNameFunc, canInteractFunc)
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()

        if IsEntityDead(playerPed) or not IsPedOnFoot(playerPed) or Filling or not canInteractFunc() then
            goto END
        end

        sleep = 0

        if Config.usePrompt then
            UiPromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING', promptNameFunc()))
            for _, action in ipairs(actions) do
                UiPromptSetVisible(Prompts[action.prompt], configType[action.configKey])
            end
        else
            for _, action in ipairs(actions) do
                if configType[action.configKey] then
                    local key = Config.keys[action.fullKey]
                    DrawText(
                        PlayerCoords.x,
                        PlayerCoords.y,
                        PlayerCoords.z + (action.offset or 0.2),
                        ('~t6~%s~q~ - %s'):format(key.char or tostring(key.code), _U(action.fullKey))
                    )
                end
            end
        end

        for _, action in ipairs(actions) do
            if configType[action.configKey] then
                local doAction = false

                if Config.usePrompt then
                    doAction = PromptHasHoldModeCompleted(Prompts[action.prompt])
                else
                    local key = Config.keys[action.fullKey]
                    doAction = IsControlJustReleased(0, key.code)
                end

                if doAction then
                    Wait(500)
                    local canPerform = true
                    if action.callback then
                        canPerform = Core.Callback.TriggerAwait(action.callback, action.itemType)
                    end
                    if canPerform then
                        if action.param then
                            action.func(table.unpack(action.param))
                        else
                            action.func()
                        end
                        DebugPrint('Action performed: ' .. action.fullKey)
                    else
                        Filling = false
                        goto END
                    end
                end
            end
        end

        ::END::
        Wait(sleep)
    end
end

AddEventHandler('bcc-water:PumpWater', function()
    DebugPrint('PumpWater event triggered.')

    local pumpActions = {
        {configKey = 'canteen', prompt = 'FillCanteenPrompt', callback = 'bcc-water:GetCanteenLevel', func = CanteenFill, param = {true}, fullKey = 'fillCanteen', offset = 0.2},
        {configKey = 'bucket',  prompt = 'FillBucketPrompt', func = ManageItems, param = {'bucket', true}, fullKey = 'fillBucket', offset = 0.1},
        {configKey = 'bottle',  prompt = 'FillBottlePrompt', func = ManageItems, param = {'bottle', true}, fullKey = 'fillBottle', offset = 0},
        {configKey = 'wash',    prompt = 'WashPrompt', func = WashPlayer, param = {'stand'}, fullKey = 'wash', offset = 0.3},
        {configKey = 'drink',   prompt = 'DrinkPrompt', func = PumpDrink, param = {}, fullKey = 'drink', offset = 0.4}
    }

    HandleWaterInteraction(
        Config.pump,
        PumpGroup,
        pumpActions,
        function() return _U('waterPump') end,
        function()
            for _, obj in ipairs(Config.objects) do
                if DoesObjectOfTypeExistAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 0.75, joaat(obj), false) then
                    return true
                end
            end
            return false
        end
    )
end)

AddEventHandler('bcc-water:WildWater', function()
    DebugPrint('WildWater event triggered.')

    local wildActions = {
        {configKey = 'canteen', prompt = 'FillCanteenPrompt', callback = 'bcc-water:GetCanteenLevel', func = CanteenFill, param = {false}, fullKey = 'fillCanteen', offset = 0.2},
        {configKey = 'bucket',  prompt = 'FillBucketPrompt', func = ManageItems, param = {'bucket', false}, fullKey = 'fillBucket', offset = 0.1},
        {configKey = 'bottle',  prompt = 'FillBottlePrompt', func = ManageItems, param = {'bottle', false}, fullKey = 'fillBottle', offset = 0},
        {configKey = 'wash',    prompt = 'WashPrompt', func = WashPlayer, param = {'ground'}, fullKey = 'wash', offset = 0.3},
        {configKey = 'drink',   prompt = 'DrinkPrompt', func = WildDrink, param = {}, fullKey = 'drink', offset = 0.4}
    }

    HandleWaterInteraction(
        Config.wild,
        WaterGroup,
        wildActions,
        function()
            local hash = GetWaterMapZoneAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
            for _, loc in pairs(Locations) do
                if loc.hash == hash then return loc.name end
            end
            return _U('wildWater') -- fallback
        end,
        function()
            local playerPed = PlayerPedId()
            if not IsEntityInWater(playerPed) then return false end
            local hash = GetWaterMapZoneAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
            for _, loc in pairs(Locations) do
                if loc.hash == hash then
                    return (not Config.crouch or GetPedCrouchMovement(playerPed) ~= 0) and IsPedStill(playerPed)
                end
            end
            return false
        end
    )
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end

    DebugPrint('Resource stopped, cleaning up...')
    ClearPedTasksImmediately(PlayerPedId())

    if Canteen then
        DeleteObject(Canteen)
    end

    if Bottle then
        DeleteObject(Bottle)
    end

    if Container then
        DeleteObject(Container)
    end

    for name, prompt in pairs(Prompts) do
        UiPromptDelete(prompt)
        Prompts[name] = nil
    end
    DebugPrint('Cleanup complete.')
end)
