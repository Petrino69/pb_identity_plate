local using = false

local function progressWithAnim(label, duration)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'MACHINIC_WALKOFF_MECHANDPLAYER', 0, true)
    local ok = lib.progressCircle({
        duration = duration,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true }
    })
    ClearPedTasks(ped)
    return ok
end

RegisterNetEvent('cs_identity_plate:promptName', function()
    if using then return end
    using = true
    local input = lib.inputDialog('VIP změna jména', {
        { type = 'input', label = 'Jméno', placeholder = 'Jan', required = true, min = 2, max = 12 },
        { type = 'input', label = 'Příjmení', placeholder = 'Novák', required = true, min = 2, max = 12 }
    })
    using = false
    if not input then return end
    local first, last = input[1], input[2]
    TriggerServerEvent('cs_identity_plate:submitName', first, last)
end)

local function getPlateBone(veh)
    local bones = { 'numberplate', 'platelight' }
    for _, b in ipairs(bones) do
        local idx = GetEntityBoneIndexByName(veh, b)
        if idx ~= -1 then return idx end
    end
    return -1
end

CreateThread(function()
    if not Config.plates.useTarget then return end
    if not exports.ox_target then return end

    exports.ox_target:addGlobalVehicle({
        {
            name = 'cs_plate_remove',
            icon = 'fa-solid fa-screwdriver-wrench',
            label = 'Sundat SPZ',
            bones = { 'numberplate', 'platelight' },
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
                if distance > 2.0 then return false end
                if GetEntitySpeed(entity) > 0.5 then return false end
                if Config.plates.engineMustBeOff and GetIsVehicleEngineRunning(entity) then return false end

                local state = Entity(entity).state
                if state and state.plateRemoved then return false end
                return true
            end,
            onSelect = function(data)
                local veh = data.entity
                if using then return end
                using = true
                local ok = progressWithAnim('Demontuji SPZ...', Config.plates.durationMs or 8000)
                using = false
                if not ok then return end
                local netId = NetworkGetNetworkIdFromEntity(veh)
                local plate = GetVehicleNumberPlateText(veh)
                TriggerServerEvent('cs_identity_plate:confirmPlateAction', 'remove_outside', netId, plate, nil)
            end
        },
        {
            name = 'cs_plate_attach',
            icon = 'fa-solid fa-screwdriver',
            label = 'Připevnit SPZ',
            bones = { 'numberplate', 'platelight' },
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
                if distance > 2.0 then return false end
                if GetEntitySpeed(entity) > 0.5 then return false end
                if Config.plates.engineMustBeOff and GetIsVehicleEngineRunning(entity) then return false end
                local state = Entity(entity).state
                if state and state.plateRemoved then return true end
                return false
            end,
            onSelect = function(data)
                local veh = data.entity
                if using then return end
                using = true
                local ok = progressWithAnim('Připevňuji SPZ...', Config.plates.durationMs or 8000)
                using = false
                if not ok then return end
                local netId = NetworkGetNetworkIdFromEntity(veh)
                local current = GetVehicleNumberPlateText(veh)
                TriggerServerEvent('cs_identity_plate:confirmPlateAction', 'attach_outside', netId, current, nil)
            end
        }
    })
end)

RegisterNetEvent('cs_identity_plate:applyPlate', function(netId, plateText)
    local veh = NetworkGetEntityFromNetworkId(netId or 0)
    if not veh or veh == 0 then return end
    SetVehicleNumberPlateText(veh, tostring(plateText or ' '):sub(1,8))
end)
