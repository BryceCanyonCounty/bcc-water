Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()
DBG = BccUtils.Debug:Get('bcc-water', Config.devMode.active)

if DBG then
    DBG:Enable()
    DBG:Info('Water debug initialized')
end

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-water')
