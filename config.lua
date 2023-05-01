Config = {}

Config.defaultlang = "en_lang"

Config.usePrompt = true -- true = Show Prompt Button at Pumps / false = Show Text at Pumps (no button)

Config.vorpMeta = true -- Vorp Metabolism = true / Fred Metabolism Free = false

-- Fill Canteen at Water Pumps and Wild Waters
Config.fillKey = 0xB2F377E8 -- [F] - 0xB2F377E8

-- Wash Player in Wild Waters
Config.washKey = 0xD9D0E1C0 -- [Space] - 0xD9D0E1C0

-- Drink from Wild Waters
Config.drinkKey = 0x760A9C6F -- [G] - 0x760A9C6F

-- Show / Hide Canteen Level Messages
Config.showMessages = true

---------------------------------------------------------------

-- Boosts Drinking from Canteen
Config.health = 10 -- Default: 10 / Value is 0 - 100

Config.stamina = 20 -- Default: 20 / Value is 0 - 100

-- Using Vorp Metabolism
Config.vorpThirst = 500 -- Default: 500 / Value is 0 - 1000

-- Using Fred Metabolism Free
Config.fredThirst = 50 -- Default: 50 / Value is 0 - 100

---------------------------------------------------------------

-- Boosts Drinking Directly from Wild Waters
Config.wildHealth = 5 -- Default: 5 / Value is 0 - 100

Config.wildStamina = 10 -- Default: 10 / Value is 0 - 100

-- Using Vorp Metabolism
Config.vorpWildThirst = 250 -- Default: 250 / Value is 0 - 1000

-- Using Fred Metabolism Free
Config.fredWildThirst = 25 -- Default: 25 / Value is 0 - 100

---------------------------------------------------------------

Config.locations = { -- Wild Water Locations
    [1]  = { name = "Sea of Coronado",     hash = -247856387  },
    [2]  = { name = "San Luis River",      hash = -1504425495 },
    [3]  = { name = "Lake Don Julio",      hash = -1369817450 },
    [4]  = { name = "Flat Iron Lake",      hash = -1356490953 },
    [5]  = { name = "Upper Montana River", hash = -1781130443 },
    [6]  = { name = "Owanjila",            hash = -1300497193 },
    [7]  = { name = "Hawks Eye Creek",     hash = -1276586360 },
    [8]  = { name = "Little Creek River",  hash = -1410384421 },
    [9]  = { name = "Dakota River",        hash =  370072007  },
    [10] = { name = "Beartooth Beck",      hash =  650214731  },
    [11] = { name = "Lake Isabella",       hash =  592454541  },
    [12] = { name = "Cattail Pond",        hash = -804804953  },
    [13] = { name = "Deadboot Creek",      hash =  1245451421 },
    [14] = { name = "Spider Gorge",        hash = -218679770  },
    [15] = { name = "O'Creagh's Run",      hash = -1817904483 },
    [16] = { name = "Moonstone Pond",      hash = -811730579  },
    [17] = { name = "Kamassa River",       hash = -1229593481 },
    [18] = { name = "Elysian Pool",        hash = -105598602  },
    [19] = { name = "Heartlands Overflow", hash =  1755369577 },
    [20] = { name = "Lagras Bayou",        hash = -557290573  },
    [21] = { name = "Lannahechee River",   hash = -2040708515 },
    [22] = { name = "Calmut Ravine",       hash =  231313522  },
    [23] = { name = "Ringneck Creek",      hash =  2005774838 },
    [24] = { name = "Stillwater Creek",    hash = -1287619521 },
    [25] = { name = "Lower Montana River", hash = -1308233316 },
    [27] = { name = "Aurora Basin",        hash = -196675805  },
    [28] = { name = "Barrow Lagoon",       hash =  795414694  },
    [29] = { name = "Arroyo De La Vibora", hash = -49694339   },
    [30] = { name = "Bahia De La Paz",     hash = -1168459546 },
    [31] = { name = "Dewberry Creek",      hash =  469159176  },
    [32] = { name = "Whinyard Strait",     hash = -261541730  },
    [33] = { name = "Cairn Lake",          hash = -1073312073 },
    [34] = { name = "Hot Springs",         hash =  1175365009 },
    [35] = { name = "Mattlock Pond",       hash =  301094150  },
    [36] = { name = "Southfield Flats",    hash = -823661292  },
}