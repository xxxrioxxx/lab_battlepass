ESX = nil

TriggerEvent('rio:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('lab_battlepass:onVehicleReward')
AddEventHandler('lab_battlepass:onVehicleReward', function(plate, props)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    MySQL.Async.execute('INSERT INTO owned_vehicles(owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',{
        ['@owner'] = identifier,
        ['@plate'] = plate,
        ['@vehicle'] = json.encode(props)
    })
end)

RegisterServerEvent('lab_battlepass:addXP')
AddEventHandler('lab_battlepass:addXP', function(xp, isTime)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local prevXP = MySQL.Sync.fetchScalar('SELECT xp FROM lab_battlepass WHERE identifier = @identifier', {['@identifier'] = identifier})
    if isTime then
        if prevXP == 1500 then xPlayer.showNotification('You can get battlepass reward') return end
        MySQL.Async.execute('UPDATE lab_battlepass SET xp = @xp WHERE identifier = @identifier', {
            ['@identifier'] = identifier, 
            ['@xp'] = prevXP + xp
        })
    else
        return
    end
end)

ESX.RegisterServerCallback('lab_battlepass:getData', function(source, cb) 
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
     MySQL.Async.fetchAll('SELECT * FROM lab_battlepass WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(results)
        if results ~= nil then
            cb(results[1])
        end
    end)
end)

RegisterServerEvent('lab_battlepass:buyLootbox')
AddEventHandler('lab_battlepass:buyLootbox', function(lootbox, useCoins)
    local xPlayer = ESX.GetPlayerFromId(source) 
    local identifier = xPlayer.identifier
    local donatecoins = MySQL.Sync.fetchScalar('SELECT coins FROM users WHERE identifier = @identifier',{['@identifier'] = identifier})

    if useCoins then
        if donatecoins >= Config.Lootboxes[lootbox].coinPrice then
            TriggerClientEvent('lab_battlepass:clientDC', xPlayer.source, Config.Lootboxes[lootbox].coinPrice)
            xPlayer.addInventoryItem(Config.Lootboxes[lootbox].name, 1)
        else
            xPlayer.showNotification('Error : Not enough Donate Coins')
        end
    else
        if  xPlayer.getMoney() >= Config.Lootboxes[lootbox].moneyPrice then
            if xPlayer.canCarryItem(Config.Lootboxes[lootbox].name, 1) then
                xPlayer.removeMoney(Config.Lootboxes[lootbox].moneyPrice)
                xPlayer.addInventoryItem(Config.Lootboxes[lootbox].name, 1)
                xPlayer.showNotification('Success : ???????????????? ?????? '..Config.Lootboxes[lootbox].title..' !')
            else
                xPlayer.showNotification('Error : ?????? ?????????????? ???? ?????????????????????? ???????? '..Config.Lootboxes[lootbox].title..' !')
            end
        else
            xPlayer.showNotification('Error : Not enough Money')
        end
    end
end)


RegisterServerEvent('lab_battlepass:reward')
AddEventHandler('lab_battlepass:reward', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    MySQL.Async.fetchAll('SELECT * FROM lab_battlepass WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(results)
        if results then
            local level = results[1].level
            local type = Config.LevelRewards[level].type
            if type == 'money' then
                xPlayer.addMoney(Config.LevelRewards[level].amount)
                xPlayer.showNotification('Success : ?????????? '..Config.LevelRewards[level].amount..'$ ???????????? ??????????????')
                LevelUP(xPlayer.source)
            elseif type == 'weapon' then
                if not xPlayer.hasWeapon(Config.LevelRewards[level].item) then
                    xPlayer.addWeapon(Config.LevelRewards[level].item, math.random(100, 200))
                    xPlayer.showNotification('Success : ?????????? ?????? '..Config.LevelRewards[level].item..'')
                    LevelUP(xPlayer.source)
                else
                    xPlayer.showNotification('Error : You already have this weapon')
                end
            elseif type == 'black_money' then
                xPlayer.addAccountMoney('black_money', Config.LevelRewards[level].amount)
                xPlayer.showNotification('Success : ?????????? '..Config.LevelRewards[level].amount..'$ ?????????? ??????????????')
                LevelUP(xPlayer.source)
            elseif type == 'coin' then
                TriggerEvent('gods_xpsystem:server:adddc', xPlayer.source, Config.LevelRewards[level].amount)
                xPlayer.showNotification('Success : ?????????? '..Config.LevelRewards[level].amount..' Donate Coins')
                LevelUP(xPlayer.source)
            elseif type == 'item' then
                xPlayer.addInventoryItem(Config.LevelRewards[level].item, Config.LevelRewards[level].amount)
                xPlayer.showNotification('Success : ?????????? x'..Config.LevelRewards[level].amount..' '..ESX.Items[Config.LevelRewards[level].item].label)
                LevelUP(xPlayer.source)
            end
        end
    end)
end)

RegisterServerEvent('lab_battlepass:buyLevel')
AddEventHandler('lab_battlepass:buyLevel', function()
    local xPlayer = ESX.GetPlayerFromId(source) 
    local identifier = xPlayer.identifier
    local donatecoins = MySQL.Sync.fetchScalar('SELECT coins FROM users WHERE identifier = @identifier', {['@identifier'] = identifier})
    if donatecoins >= 20 then
        TriggerClientEvent('lab_battlepass:clientDC', xPlayer.source, 20)
        LevelUP(xPlayer.source)
        xPlayer.showNotification('Success : ???????????????? ?????? Level ?????? Battlepass')
    else
        xPlayer.showNotification('Error : ?????? ?????????? ???????????? donate coins')
        return
    end
end)

function LevelUP(id)
    local xPlayer = ESX.GetPlayerFromId(id)
    local identifier = xPlayer.identifier
    local prevLevel = MySQL.Sync.fetchScalar('SELECT level FROM lab_battlepass WHERE identifier = @identifier', {['@identifier'] = identifier})
    local prevXP = MySQL.Sync.fetchScalar('SELECT xp FROM lab_battlepass WHERE identifier = @identifier', {['@identifier'] = identifier})
    if prevXP >= 1500 then
        MySQL.Async.execute('UPDATE lab_battlepass SET xp = @xp, level = @level WHERE identifier = @identifier', {
            ['@identifier'] = identifier, 
            ['@xp'] = prevXP - 1500,
            ['@level'] = prevLevel + 1
        })
        xPlayer.showNotification('Success : ???????????????? level ?????? battlepass!')
    else
        MySQL.Async.execute('UPDATE lab_battlepass SET xp = @xp, level = @level WHERE identifier = @identifier', {
            ['@identifier'] = identifier, 
            ['@xp'] = prevXP,
            ['@level'] = prevLevel + 1
        })
        xPlayer.showNotification('Success : ???????????????? level ?????? battlepass!')
    end
end

-- ESX.RegisterServerCallback('lab_battlepass:checkSubscription', function(source, cb)
--     local xPlayer = ESX.GetPlayerFromId(source)
--     local identifier = xPlayer.identifier
--     MySQL.Async.fetchAll('SELECT xp FROM lab_battlepass WHERE identifier = @identifier', {
--         ['@identifier'] = identifier
--     }, function(results)
--         if #results > 0 then
--             cb(true)
--         else
--             cb(false)
--         end
--     end)
-- end)

RegisterCommand('addbp', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local group = xPlayer.getGroup()
    local xTarget = ESX.GetPlayerFromId(args[1])
    if group ~= 'superadmin' then
        return
    end
    if xTarget then
        MySQL.Async.execute('INSERT INTO lab_battlepass(identifier, level, xp) VALUES (@identifier, @level, @xp)', {
            ['@identifier'] = xTarget.identifier,
            ['@xp'] = 0,
            ['@level'] = 1
        })
        xTarget.showNotification('Success : ?????????? ?????????? Battlepass')
        xPlayer.showNotification('Success : ???????????? Battlepass ???????? '..xTarget.getName())
        TriggerClientEvent('lab_battlepass:checkBattlepass', xTarget.source, true)
    else
        xPlayer.showNotification('Error : Player not online')
    end
end, false)

RegisterCommand('removebp', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local group = xPlayer.getGroup()
    local xTarget = ESX.GetPlayerFromId(args[1])
    if group ~= 'superadmin' then
        return
    end
    if xTarget then
        MySQL.Async.execute('DELETE FROM lab_battlepass WHERE identifier = @identifier', {
            ['@identifier'] = xTarget.identifier
        })
        TriggerClientEvent('lab_battlepass:checkBattlepass', xTarget.source, false)
        xTarget.showNotification('Success : ?????????? ???????????? ???? Battlepass')
        xPlayer.showNotification('Success : ?????????????? ???? Battlepass ???????? '..xTarget.getName())
    else
        xPlayer.showNotification('Error : Player not online')
    end
end, false)


-- Lootboxes


ESX.RegisterUsableItem('lb_vehicle', function(source)
    local id = math.random(#Config.LootboxesRewards[6])
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('lb_vehicle', 1)
    for k, v in pairs(Config.LootboxesRewards[6]) do
        if k == id then
            local model = v.name
            xPlayer.showNotification('Success : ?????????? ?????????? ?????? '..v.label)
            TriggerClientEvent('lab_battlepass:onVehicleReward', xPlayer.source, model)
        end
    end
end)


ESX.RegisterUsableItem('lb_aio', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local chances = math.random(0, 100)
    xPlayer.removeInventoryItem('lb_aio', 1)
    if chances >= 0 and chances <= 10 then
        if not xPlayer.hasWeapon('WEAPON_ISY') then
            xPlayer.addWeapon('WEAPON_ISY', math.random(0, 400))
            xPlayer.showNotification('Success : ?????????? ?????? ISY')
        else
            xPlayer.showNotification('Error : ?????????? ?????? ?????? ISY ???????? ??????')
        end
    elseif chances > 10 and chances <= 40 then
        xPlayer.addInventoryItem('bandage', 10)
        xPlayer.showNotification('Success : ?????????? x10 ??????????')
    elseif chances > 40 and chances <= 70 then
        xPlayer.addInventoryItem('militaryvest', 3)
        xPlayer.showNotification('Success : ?????????? x3 Military Vest')
    elseif chances > 70 and chances <= 85 then
        xPlayer.addMoney(60000)
        xPlayer.showNotification('Success : ?????????? 60.000$ ???????????? ??????????????')
    elseif chances > 85 then
        xPlayer.addAccountMoney('black_money', 30000)
        xPlayer.showNotification('Success : ?????????? 30.000$ ?????????? ??????????????')
    end

end)

ESX.RegisterUsableItem('lb_medkit', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('lb_medkit', 1)
    local chances = math.random(0, 100)
    if chances >= 0 and chances <= 34 then
        xPlayer.addInventoryItem('bandage', 10)
        xPlayer.showNotification('Success : ?????????? x10 ??????????')
    elseif chances > 34 and chances <= 77 then
        xPlayer.addInventoryItem('xapi', 3)
        xPlayer.showNotification('Success : ?????????? x3 ???????????????? ??????????')
    elseif chances > 77 then
        xPlayer.addInventoryItem('medikit', 3)
        xPlayer.showNotification('Success : ?????????? x3 ?????? ???????????? ????????????????')
    end
end)

ESX.RegisterUsableItem('lb_money', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('lb_money', 1)
    local chances = math.random(0, 100)
    if chances >= 0 and chances <= 40 then
        xPlayer.addMoney(30000)
        xPlayer.showNotification('Success : ?????????? 30.000$ ???????????? ??????????????')
    elseif chances > 40 and chances <= 80 then
        xPlayer.addAccountMoney('black_money', 15000)
        xPlayer.showNotification('Success : ?????????? 15.000$ ?????????? ??????????????')
    elseif chances > 80 and chances <= 90 then
        xPlayer.addMoney(60000)
        xPlayer.showNotification('Success : ?????????? 60.000$ ???????????? ??????????????')
    elseif chances > 90 then
        xPlayer.addAccountMoney('black_money', 30000)
        xPlayer.showNotification('Success : ?????????? 60.000$ ?????????? ??????????????')
    end
end)

ESX.RegisterUsableItem('lb_vest', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('lb_vest', 1)
    local chances = math.random(0, 100)
    if chances >= 0 and chances <= 30 then
        xPlayer.addInventoryItem('bulletproof', 10)
        xPlayer.showNotification('Success : ?????????? x10 ?????????????????????? ????????????')
    elseif chances > 30 and chances <= 55 then
        xPlayer.addInventoryItem('militaryvest', 3)
        xPlayer.showNotification('Success : ?????????? x3 Military Vest')
    elseif chances > 55 then
        xPlayer.addInventoryItem('armorpill', 20)
        xPlayer.showNotification('Success : ?????????? x20 ?????????? Armor')
    end
end)

ESX.RegisterUsableItem('lb_weapon', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('lb_weapon', 1)
    local chances = math.random(0, 100)
    if chances >= 0 and chances <= 20 then
        xPlayer.addWeapon('WEAPON_SCARMK17', math.random(0,400))
        xPlayer.showNotification('Success : ?????????? ?????? SCAR-MK17')
    elseif chances > 20 and chances <= 50 then
        xPlayer.addWeapon('WEAPON_AK103', math.random(0,400))
        xPlayer.showNotification('Success : ?????????? ?????? AK103')
    elseif chances > 50 and chances <= 80 then
        xPlayer.addWeapon('WEAPON_ARMK4', math.random(0,400))
        xPlayer.showNotification('Success : ?????????? ?????? AR MK4')
    elseif chances > 80 and chances <= 90 then
        xPlayer.addWeapon('WEAPON_M4A5', math.random(0,400))
        xPlayer.showNotification('Success : ?????????? ?????? M4A5')
    elseif chances > 90 then
        xPlayer.addWeapon('WEAPON_ISY', math.random(0,400))
        xPlayer.showNotification('Success : ?????????? ?????? ISY')
    end
end)