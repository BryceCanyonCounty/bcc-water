Core = exports.vorp_core:GetCore()
FeatherMenu = exports['feather-menu'].initiate()
BccUtils = exports['bcc-utils'].initiate()
DBG = BccUtils.Debug:Get('bcc-water', Config.devMode.active)

if DBG then
    DBG:Enable()
    DBG:Info('Water debug initialized')
end

-- Shared client state and asset helpers are initialized here so every later
-- client file can safely use them regardless of resource packaging.
WaterClient = {
    filling = false,
    objects = {}
}

function WaterClient.GetCoords()
    return GetEntityCoords(PlayerPedId())
end

function WaterClient.SetFilling(value)
    WaterClient.filling = value == true
end

function WaterClient.IsFilling()
    return WaterClient.filling
end

function WaterClient.LoadAnim(animDict)
    if HasAnimDictLoaded(animDict) then
        return true
    end

    DBG:Info(('Loading animation dictionary: %s'):format(tostring(animDict)))
    RequestAnimDict(animDict)
    local deadline = GetGameTimer() + 10000

    while not HasAnimDictLoaded(animDict) do
        if GetGameTimer() >= deadline then
            DBG:Error(('Failed to load animation dictionary: %s'):format(tostring(animDict)))
            return false
        end
        Wait(10)
    end

    return true
end

function WaterClient.LoadModel(modelHash, modelName)
    if not IsModelValid(modelHash) then
        DBG:Error(('Invalid model: %s'):format(tostring(modelName)))
        return false
    end

    if HasModelLoaded(modelHash) then
        return true
    end

    DBG:Info(('Loading model: %s'):format(tostring(modelName)))
    RequestModel(modelHash, false)
    local deadline = GetGameTimer() + 10000

    while not HasModelLoaded(modelHash) do
        if GetGameTimer() >= deadline then
            DBG:Error(('Failed to load model: %s'):format(tostring(modelName)))
            return false
        end
        Wait(10)
    end

    return true
end

function WaterClient.CreateTrackedObject(modelHash, coords)
    local object = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false, false, true)
    if not object or object == 0 then
        return nil
    end

    WaterClient.objects[object] = true
    SetEntityVisible(object, true)
    SetEntityAlpha(object, 255, false)
    SetModelAsNoLongerNeeded(modelHash)
    return object
end

function WaterClient.DeleteTrackedObject(object)
    if not object then return end

    WaterClient.objects[object] = nil
    if DoesEntityExist(object) then
        DeleteObject(object)
    end
end

function WaterClient.PlayAnim(animDict, animName, flagValue, waitTime)
    WaterClient.SetFilling(true)
    if not WaterClient.LoadAnim(animDict) then
        WaterClient.SetFilling(false)
        return false
    end

    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)
    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, flagValue or 1, 1.0, false, false, false)
    Wait(waitTime or 5000)
    ClearPedTasks(playerPed)
    WaterClient.SetFilling(false)
    return true
end

function WaterClient.Cleanup()
    WaterClient.SetFilling(false)
    for object in pairs(WaterClient.objects) do
        if DoesEntityExist(object) then
            DeleteObject(object)
        end
    end
    WaterClient.objects = {}
end
