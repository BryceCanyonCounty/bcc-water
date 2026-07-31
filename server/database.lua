local SEED_VERSION = 4

local UPSERT_SQL = [[
INSERT INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`)
VALUES (?, ?, ?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
  `label` = VALUES(`label`),
  `limit` = VALUES(`limit`),
  `can_remove` = VALUES(`can_remove`),
  `type` = VALUES(`type`),
  `usable` = VALUES(`usable`),
  `desc` = VALUES(`desc`);
]]

local CREATE_MIGRATIONS_SQL = [[
CREATE TABLE IF NOT EXISTS `resource_migrations` (
  `resource` VARCHAR(128) NOT NULL PRIMARY KEY,
  `version` INT NOT NULL
);
]]

local SET_MIGRATION_SQL = [[
INSERT INTO `resource_migrations` (`resource`, `version`)
VALUES (?, ?)
ON DUPLICATE KEY UPDATE `version` = VALUES(`version`);
]]

---@param value boolean
---@return integer
local function usableFlag(value)
    return value == true and 1 or 0
end

---@return table
local function buildItems()
    local items = {}
    local seen = {}

    local function add(name, label, limit, usable, description)
        if type(name) ~= 'string' or name == '' or seen[name] then return end
        seen[name] = true
        items[#items + 1] = {
            name,
            label,
            limit,
            1,
            'item_standard',
            usableFlag(usable),
            description,
        }
    end

    add(Config.canteen, 'Canteen', 1, true,
        'A portable container to carry water.')
    add(Config.cleanBucket, 'Water Jug', 10, Config.useable.cleanBucket,
        'A bucket of clean water.')
    add(Config.emptyBucket, 'Empty Watering Jug', 10, false,
        'An empty water bucket.')
    add(Config.dirtyBucket, 'Dirty Water Jug', 10, Config.useable.dirtyBucket,
        'A bucket filled with dirty water.')
    add(Config.emptyBottle, 'Empty Bottle', 15, false,
        'An empty bottle.')
    add(Config.cleanBottle, 'Clean Water Bottle', 15, Config.useable.cleanBottle,
        'A bottle filled with clean water.')
    add(Config.dirtyBottle, 'Dirty Water Bottle', 15, Config.useable.dirtyBottle,
        'A bottle filled with dirty water.')

    -- The first configured list entry receives the bundled default definition.
    -- Additional custom entries require their own database definitions.
    add(Config.antidoteItems[1], 'Antidote', 5, Config.useable.antidotes,
        'A remedy to cure sickness.')
    add(Config.soapItem[1], 'Soap Bar', 10, false,
        'A bar of soap for washing.')

    local tabletMethod = Config.purification.methods.tablets
    local tabletRequirement = tabletMethod and tabletMethod.requiredItems
        and tabletMethod.requiredItems[1]
    add(tabletRequirement and tabletRequirement.name, 'Purification Tablet', 20, false,
        'Purifies one container of dirty water.')

    return items
end

---@param maxAttempts? integer
---@param delay? integer
---@return boolean
local function waitForDB(maxAttempts, delay)
    maxAttempts = maxAttempts or 20
    delay = delay or 500

    for _ = 1, maxAttempts do
        if MySQL and MySQL.query and MySQL.query.await then
            local ok = pcall(function()
                return MySQL.query.await('SELECT 1')
            end)
            if ok then return true end
        end
        Wait(delay)
    end

    return false
end

local function ensureMigrationTable()
    MySQL.query.await(CREATE_MIGRATIONS_SQL)
end

---@return integer
local function getMigrationVersion()
    local version = MySQL.scalar.await(
        'SELECT `version` FROM `resource_migrations` WHERE `resource` = ?',
        { GetCurrentResourceName() }
    )
    return tonumber(version) or 0
end

---@param force boolean
local function seedItems(force)
    if Config.autoSeedDatabase == false and not force then
        DBG:Info('autoSeedDatabase disabled in config; skipping DB seeding.')
        return
    end

    if not waitForDB() then
        DBG:Warning('Database not available after retries; skipping seeding.')
        return
    end

    local setupOk, setupError = pcall(ensureMigrationTable)
    if not setupOk then
        DBG:Error(string.format('Failed to create migration table: %s', tostring(setupError)))
        return
    end

    local versionOk, currentVersion = pcall(getMigrationVersion)
    if not versionOk then
        DBG:Error(string.format('Failed to get migration version: %s', tostring(currentVersion)))
        return
    end

    if currentVersion >= SEED_VERSION and not force then
        DBG:Info(string.format('Items already seeded (version %s), skipping.',
            tostring(currentVersion)))
        return
    end

    local items = buildItems()
    local queries = {}
    for _, item in ipairs(items) do
        queries[#queries + 1] = {
            query = UPSERT_SQL,
            values = item,
        }
    end
    queries[#queries + 1] = {
        query = SET_MIGRATION_SQL,
        values = { GetCurrentResourceName(), SEED_VERSION },
    }

    DBG:Info(string.format('Seeding %d configured items...', #items))
    local transactionOk, transactionResult = pcall(function()
        return MySQL.transaction.await(queries)
    end)
    if not transactionOk or transactionResult ~= true then
        DBG:Error(string.format('Item seed transaction failed: %s',
            transactionOk and 'transaction rolled back' or tostring(transactionResult)))
        return
    end

    DBG:Info(string.format('Seeding complete; set seed version to %d.', SEED_VERSION))
end

-- Console-only manual seed
RegisterCommand('bcc-water:seed', function(source)
    if source ~= 0 then
        DBG:Warning('bcc-water:seed can only be run from server console')
        return
    end
    seedItems(true)
end, true)

-- Console-only verification of bundled/config-derived item definitions
RegisterCommand('bcc-water:verify', function(source)
    if source ~= 0 then
        DBG:Warning('bcc-water:verify can only be run from server console')
        return
    end

    if not waitForDB() then
        DBG:Warning('Database not available; cannot verify items.')
        return
    end

    local missing = {}
    for _, item in ipairs(buildItems()) do
        local exists = MySQL.scalar.await(
            'SELECT 1 FROM `items` WHERE `item` = ? LIMIT 1',
            { item[1] }
        )
        if not exists then
            missing[#missing + 1] = item[1]
        end
    end

    if #missing == 0 then
        DBG:Info('All configured default items are present in the items table.')
    else
        DBG:Warning(string.format('Missing items: %s', table.concat(missing, ', ')))
    end
end, true)

-- Auto-run on resource start when enabled in config
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(1000)
        seedItems(false)
    end)
end)
