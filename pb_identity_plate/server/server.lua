local ESX = exports['es_extended']:getSharedObject()
local lastNameChange = {} -- [identifier] = os.time()

-- utils
local function normalize(str)
    str = (str or ''):lower()
    local from,to = {'á','č','ď','é','ě','í','ň','ó','ř','š','ť','ú','ů','ý','ž'}, {'a','c','d','e','e','i','n','o','r','s','t','u','u','y','z'}
    for i=1,#from do str = str:gsub(from[i], to[i]) end
    str = str:gsub('[^%w%s%-]', '')
    return str
end

local function isBlacklisted(name)
    local n = normalize(name)
    for _, w in ipairs(Config.vip.blacklist or {}) do
        if n:find(normalize(w), 1, true) then return true end
    end
    return false
end

local function hasAceVip(src)
    if not Config.vip.requireVipAce then return true end
    local allowed = IsPlayerAceAllowed(src, 'vip')
    return allowed
end

local function logDiscord(title, fields)
    if not Config.discordWebhook or Config.discordWebhook == '' then return end
    local embed = {
        title = title,
        color = 5814783,
        fields = fields,
        footer = { text = 'cs_identity_plate' },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    PerformHttpRequest(Config.discordWebhook, function() end, 'POST',
        json.encode({ embeds = { embed } }),
        { ['Content-Type'] = 'application/json' })
end


ESX.RegisterUsableItem(Config.vip.item, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if not hasAceVip(source) then
        Config.notify(source, 'VIP', 'Nemáš oprávnění k VIP změně jména.', 'error')
        return
    end

    local id = xPlayer.getIdentifier()
    local now = os.time()
    local last = lastNameChange[id] or 0
    local cd = (Config.vip.cooldownMinutes or 1440) * 60
    if now - last < cd then
        local rem = math.floor((cd - (now - last)) / 60)
        Config.notify(source, 'VIP', ('Změnu jména lze znovu až za %d min.'):format(rem), 'warning')
        return
    end

    TriggerClientEvent('cs_identity_plate:promptName', source)
end)

RegisterNetEvent('cs_identity_plate:submitName', function(first, last)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not hasAceVip(src) then
        Config.notify(src, 'VIP', 'Nemáš oprávnění k VIP změně jména.', 'error')
        return
    end

    local full = (first or '') .. ' ' .. (last or '')
    full = full:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')

    if #full < (Config.vip.name.minLen or 3) or #full > (Config.vip.name.maxLen or 18) then
        Config.notify(src, 'VIP', 'Neplatná délka jména.', 'error')
        return
    end

    if (Config.vip.name.requireSpace and not full:find('%s')) then
        Config.notify(src, 'VIP', 'Uveď jméno i příjmení.', 'error')
        return
    end

    if not Config.vip.name.allowHyphen and full:find('%-') then
        Config.notify(src, 'VIP', 'Spojovník v jméně není povolen.', 'error')
        return
    end

    if isBlacklisted(full) then
        Config.notify(src, 'VIP', 'Toto jméno obsahuje zakázané slovo.', 'error')
        return
    end


    local identifier = xPlayer.getIdentifier()
    local firstName = (first or ''):gsub('^%s*(.-)%s*$', '%1')
    local lastName  = (last or ''):gsub('^%s*(.-)%s*$', '%1')

    local mode = (Config.identity and Config.identity.mode) or 'esx_identity'
    if mode == 'esx_identity' then

        MySQL.update.await('UPDATE users SET firstname = ?, lastname = ? WHERE identifier = ?', { firstName, lastName, identifier })
        if xPlayer.setName then
            xPlayer.setName(('%s %s'):format(firstName, lastName))
        end
        TriggerClientEvent('esx_identity:showRegisterIdentity', src, { new = false }) -- některé verze obnoví UI jména
    elseif mode == 'users_table' then
        local cols = Config.identity.usersTableColumns or { firstname = 'firstname', lastname = 'lastname' }
        MySQL.update.await(('UPDATE users SET `%s` = ?, `%s` = ? WHERE identifier = ?'):format(cols.firstname, cols.lastname), { firstName, lastName, identifier })
        if xPlayer.setName then xPlayer.setName(('%s %s'):format(firstName, lastName)) end
    elseif mode == 'xplayer_setname' then
        if xPlayer.setName then
            xPlayer.setName(('%s %s'):format(firstName, lastName))
        else
            Config.notify(src, 'VIP', 'Tvoje verze ESX nepodporuje setName.', 'error')
            return
        end
    else
        Config.notify(src, 'VIP', 'Neznámý režim změny jména v Config.identity.mode', 'error')
        return
    end


    if xPlayer.getInventoryItem(Config.vip.item)?.count > 0 then
        xPlayer.removeInventoryItem(Config.vip.item, 1)
    end

    lastNameChange[identifier] = os.time()
    Config.notify(src, 'VIP', ('Jméno změněno na %s %s.'):format(firstName, lastName), 'success')
    logDiscord('VIP Změna jména', {
        { name = 'Hráč', value = ('%s (%s)'):format(GetPlayerName(src), identifier), inline = false },
        { name = 'Nové jméno', value = ('%s %s'):format(firstName, lastName), inline = true }
    })
end)



ESX.RegisterUsableItem(Config.plates.removeItem, function(source)
    TriggerClientEvent('cs_identity_plate:startPlateAction', source, 'remove')
end)

ESX.RegisterUsableItem(Config.plates.attachItem, function(source)
    TriggerClientEvent('cs_identity_plate:startPlateAction', source, 'attach')
end)


RegisterNetEvent('cs_identity_plate:confirmPlateAction', function(action, netId, originalPlate, newPlateText)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local veh = NetworkGetEntityFromNetworkId(netId or 0)
    if not veh or veh == 0 then
        Config.notify(src, 'SPZ', 'Vozidlo nebylo nalezeno.', 'error')
        return
    end

    local ped = GetPlayerPed(src)
    if not DoesEntityExist(ped) then return end


    local pcoords = GetEntityCoords(ped)
    local vcoords = GetEntityCoords(veh)
    local dist = #(pcoords - vcoords)
    if dist > 5.0 then
        Config.notify(src, 'SPZ', 'Jsi příliš daleko od vozidla.', 'warning')
        return
    end
    if (Config.plates.requireStopped and (GetEntitySpeed(veh) > 0.5)) then
        Config.notify(src, 'SPZ', 'Vozidlo musí stát.', 'warning')
        return
    end
    if (Config.plates.engineMustBeOff and GetIsVehicleEngineRunning(veh)) then
        Config.notify(src, 'SPZ', 'Vypni motor.', 'warning')
        return
    end

    local state = Entity(veh).state
    state.originalPlate = state.originalPlate or originalPlate

if action == 'remove_outside' then

    if Config.plates.removeItem then
        local item = xPlayer.getInventoryItem(Config.plates.removeItem)
        if not item or (item.count or 0) < 1 then
            Config.notify(src, 'SPZ', 'Chybí sada na sundání SPZ.', 'error')
            return
        end
    end

  
        local ok = false
        if exports.ox_inventory then
            ok = exports.ox_inventory:AddItem(src, Config.plates.licensePlateItem or 'license_plate', 1, {
                plate = originalPlate or '',
                model = GetEntityModel(veh)
            }) == true
        end
        if not ok then

            xPlayer.addInventoryItem(Config.plates.licensePlateItem or 'license_plate', 1)
        end

        state.plateRemoved = true
        local tmp = (Config.plates.removedPlateText or 'ANON'):sub(1, 8)
        TriggerClientEvent('cs_identity_plate:applyPlate', -1, netId, tmp)

        Config.notify(src, 'SPZ', ('SPZ %s demontována.'):format(originalPlate or ''), 'success')
        logDiscord('SPZ Sundána', {
            { name = 'Hráč', value = ('%s'):format(GetPlayerName(src)), inline = true },
            { name = 'Původní SPZ', value = originalPlate or 'unknown', inline = true }
        })

    elseif action == 'attach_outside' then

    if Config.plates.attachItem then
        local it = xPlayer.getInventoryItem(Config.plates.attachItem)
        if not it or (it.count or 0) < 1 then
            Config.notify(src, 'SPZ', 'Chybí montážní sada SPZ.', 'error')
            return
        end
    end


        local foundMeta = nil
        if exports.ox_inventory then
            local items = exports.ox_inventory:GetInventoryItems(src)
            for _, it in pairs(items or {}) do
                if it?.name == (Config.plates.licensePlateItem or 'license_plate') then
                    local pl = it?.metadata?.plate
                    if pl and state.originalPlate and pl == state.originalPlate then
                        foundMeta = it.metadata

                        exports.ox_inventory:RemoveItem(src, it.name, 1, it.metadata)
                        break
                    end
                end
            end
        end
        if not foundMeta then

            local count = xPlayer.getInventoryItem(Config.plates.licensePlateItem or 'license_plate')?.count or 0
            if count < 1 then
                Config.notify(src, 'SPZ', 'Nemáš správnou SPZ v inventáři.', 'error')
                return
            end
            xPlayer.removeInventoryItem(Config.plates.licensePlateItem or 'license_plate', 1)
        end

        if Config.plates.attachItem then
            xPlayer.removeInventoryItem(Config.plates.attachItem, 1)
        end
        state.plateRemoved = false
        local plate = (state.originalPlate or newPlateText or 'REPAIRED'):sub(1, 8)
        TriggerClientEvent('cs_identity_plate:applyPlate', -1, netId, plate)

        Config.notify(src, 'SPZ', ('SPZ připevněna: %s'):format(plate), 'success')
        logDiscord('SPZ Připevněna', {
            { name = 'Hráč', value = ('%s'):format(GetPlayerName(src)), inline = true },
            { name = 'SPZ', value = plate or 'unknown', inline = true }
        })
    else

        if action == 'remove' or action == 'attach' then
            Config.notify(src, 'SPZ', 'Tato akce je nyní dostupná přímo u SPZ (ox_target).', 'info')
        end
    end
end)
