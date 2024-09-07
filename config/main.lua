Config = {}

Config.defaultlang = 'en_lang'
---------------------------------------------------------------

-- Vorp Metabolism              = 1
-- Fred Metabolism Free         = 2
-- Outsider Needs               = 3
-- Fred Metabolism Paid v1.4    = 4
-- Fred Metabolism Paid v2      = 5
-- RSD Metabolism Paid          = 6
-- NXT Metabolism Paid          = 7
-- Andrade Metabolism Paid      = 8
-- FX-HUD                       = 9
Config.app = 1
---------------------------------------------------------------

Config.keys = {
    drink       = 0x760A9C6F, -- [G] Drink at Water Pumps and Wild Waters
    wash        = 0x80F28E95, -- [L] Wash Player at Water Pumps and Wild Waters
    fillBucket  = 0xCEFD9220, -- [E] Fill Bucket at Water Pumps and Wild Waters
    fillCanteen = 0x27D1C284, -- [R] Fill Canteen at Water Pumps and Wild Waters
}
---------------------------------------------------------------

Config.pumpsEnabled = true -- Enable the Use of Water Pumps

Config.pumpCanteen  = true -- Fill Canteen at Pumps
Config.pumpBucket   = true -- Fill Bucket at Pumps
Config.pumpWash     = true -- Wash at Pumps
Config.pumpDrink    = true -- Drink at Pumps
---------------------------------------------------------------

Config.wildEnabled = true -- Enable the Use of Rivers and Lakes (Wild Waters)

Config.wildCanteen = true -- Fill Canteen in Wild Waters
Config.wildBucket  = true -- Fill Bucket in Wild Waters
Config.wildWash    = true -- Wash in Wild Waters
Config.wildDrink   = true -- Drink Directly from Wild Waters
---------------------------------------------------------------

-- Item Names from Database
Config.emptyBucket = 'wateringcan_empty'

Config.fullBucket  = 'wateringcan'

Config.canteen     = 'canteen'
---------------------------------------------------------------

-- Crouch in Wild Water to Show Prompts
Config.crouch = true -- Default: true / Set to false to Remove Crouch Requirement
---------------------------------------------------------------

Config.usePrompt = true -- true = Show Prompt Button at Water Pumps / false = Show Text at Water Pumps (no button)
---------------------------------------------------------------

Config.showMessages = true -- Show / Hide Canteen Level Messages
---------------------------------------------------------------

-- Boosts Drinking from Canteen
Config.health  = 10 -- Default: 10 / Value is 0 - 100 / Set to 0 to Disable

Config.stamina = 20 -- Default: 20 / Value is 0 - 100 / Set to 0 to Disable

Config.thirst  = 50 -- Default: 50 / Value is 0 - 100
---------------------------------------------------------------

-- Effects Drinking from Wild Waters
Config.gainHealth = true -- true = Gain Health by wildHealth Value / false = Lose by Value
Config.wildHealth  = 5  -- Default: 5 / Value is 0 - 100 / Set to 0 to Disable

Config.gainStamina = true -- true = Gain Stamina by wildStamina Value / false = Lose by Value
Config.wildStamina = 10 -- Default: 10 / Value is 0 - 100 / Set to 0 to Disable

Config.wildThirst  = 25 -- Default: 25 / Value is 0 - 100
---------------------------------------------------------------

Config.CanteenUsage = 5 -- Default: 5 / Durability used per Drink
---------------------------------------------------------------

-- Translate Canteen Metadata
Config.lang = {
    level = 'Level',
    empty = 'Empty',
    full  = 'Full',
    Durability = 'Durability',
}
---------------------------------------------------------------

-- Objects Where You Can Get Water
Config.objects = {
    'p_waterpump01x',
    'p_wellpumpnbx01x',
    'p_sink02x',
    'p_drysink01x',
    'p_drysink01x',
    'p_sink03x',
    'p_barrel_ladle01x',
    'p_barrel_wash01x',
}
---------------------------------------------------------------
