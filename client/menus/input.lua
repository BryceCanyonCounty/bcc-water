local InputMenu = FeatherMenu:RegisterMenu('input:menu', {
    top = '3%',
    left = '3%',
    ['720width'] = '400px',
    ['1080width'] = '500px',
    ['2kwidth'] = '600px',
    ['4kwidth'] = '800px',
    style = {},
    contentslot = {
        style = {
            ['height'] = '6.019vh',
            ['min-height'] = '6.019vh'
        }
    },
    draggable = true,
    canclose = true
})

local ActiveInputPage

---@param itemType string
---@param pump boolean
function OpenInputMenu(itemType, pump)
    if ActiveInputPage then
        InputMenu:Close()
        ActiveInputPage:UnRegister()
        ActiveInputPage = nil
    end

    local InputPage = InputMenu:RegisterPage('input:page')
    ActiveInputPage = InputPage
    local itemAmount = 1
    local confirming = false
    local headerText = itemType == 'bucket' and _U('headerFillBuckets') or _U('headerFillBottles')
    local configKey = pump and Config.pump.multi or Config.wild.multi
    local amountKey = itemType == 'bucket' and 'bucketAmount' or 'bottleAmount'
    local maxAmount = math.max(1, math.floor(tonumber(configKey[amountKey]) or 1))
    local amountOptions = {}

    for amount = 1, maxAmount do
        amountOptions[#amountOptions + 1] = amount
    end

    InputPage:RegisterElement('header', {
        value = headerText,
        slot = 'header',
        style = {}
    })

    InputPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    InputPage:RegisterElement('arrows', {
        label = _U('quantity'),
        start = 1,
        options = amountOptions,
        slot = 'content',
        style = {},
        persist = true,
    }, function(data)
        local value = tonumber(data.value)
        if value then
            itemAmount = math.max(1, math.min(maxAmount, math.floor(value)))
        end
    end)

    InputPage:RegisterElement('line', { slot = 'footer', style = {} })

    InputPage:RegisterElement('button', {
        label = _U('confirm'),
        slot = 'footer',
        style = {}
    }, function()
        if confirming then return end
        confirming = true

        local amount = math.max(1, math.min(maxAmount, math.floor(tonumber(itemAmount) or 1)))
        local hasItems = Core.Callback.TriggerAwait('bcc-water:GetItem', itemType, amount, pump)
        if hasItems then
            InputMenu:Close()
            if itemType == 'bucket' then
                BucketFill(pump)
            else
                BottleFill(pump)
            end
        else
            confirming = false
        end
    end)

    InputPage:RegisterElement('line', { slot = 'footer', style = {} })

    InputMenu:Open({ startupPage = InputPage })
end
