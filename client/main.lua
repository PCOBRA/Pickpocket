local ESX = exports["es_extended"]:getSharedObject()

-- Hàm tìm NPC gần nhất (chỉ con người)
function GetClosestNPC(coords)
    local pedList = GetGamePool('CPed')
    local closestPed = nil
    local closestDist = 3.0

    for _, ped in ipairs(pedList) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) and IsPedHuman(ped) then
            local pedCoords = GetEntityCoords(ped)
            local dist = #(coords - pedCoords)
            if dist < closestDist then
                closestPed = ped
                closestDist = dist
            end
        end
    end
    return closestPed
end

local isPickpocketing = false
local hasBag = false
local bagObject = nil
local bagSpawnTime = nil

-- Kiểm tra loại phương tiện
local function isVehicleAllowed(vehicle)
    local model = GetEntityModel(vehicle)
    local class = GetVehicleClassFromName(model)
    return class == 13 or class == 8 -- 13: Xe đạp, 8: Moto
end

-- Cấm lên phương tiện không cho phép khi cầm túi
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hasBag then
            local playerPed = PlayerPedId()
            if IsPedGettingIntoAVehicle(playerPed) then
                local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
                if vehicle and not isVehicleAllowed(vehicle) then
                    ClearPedTasks(playerPed)
                    lib.notify({
                        title = "Cảnh báo",
                        description = "Bạn không thể lên xe 4 bánh khi cầm túi!",
                        type = "error",
                        position = "center-left"
                    })
                end
            end
        end
    end
end)

-- Xóa túi sau 30 phút
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if hasBag and bagObject then
            local timeHeld = GetGameTimer() - (bagSpawnTime or 0)
            if timeHeld >= 1800000 then -- 30 phút
                DeleteObject(bagObject)
                hasBag = false
                bagObject = nil
                lib.notify({
                    title = "Cảnh báo",
                    description = "Chiếc túi đã biến mất do bạn không mở kịp thời!",
                    type = "error",
                    position = "center-left"
                })
                TriggerServerEvent('pickpocket:lostBag')
            end
        end
    end
end)

RegisterNetEvent('pickpocket:cancelAction')
AddEventHandler('pickpocket:cancelAction', function()
    if isPickpocketing then
        ClearPedTasksImmediately(PlayerPedId())
        isPickpocketing = false
    end
end)

RegisterCommand('pickpocket', function()
    if isPickpocketing or hasBag then return end
    
    local playerPed = PlayerPedId()
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.job then return end
    
    local playerJob = string.lower(playerData.job.name)
    if hasBlacklistedJob(playerJob) then return end
    
    local coords = GetEntityCoords(playerPed)
    local npc = GetClosestNPC(coords)
    if not npc or not DoesEntityExist(npc) then return end

    isPickpocketing = true
    TriggerServerEvent('pickpocket:checkPolice', NetworkGetNetworkIdFromEntity(npc))
end, false)

RegisterNetEvent('pickpocket:startProgress')
AddEventHandler('pickpocket:startProgress', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("amb@prop_human_bum_bin@idle_b")
    while not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b") do
        Wait(10)
    end
    TaskPlayAnim(playerPed, "amb@prop_human_bum_bin@idle_b", "idle_d", 8.0, 8.0, -1, 1, 0, false, false, false)

    local success = exports['ox_lib']:progressBar({
        duration = 10000,
        label = "Đang móc túi...",
        useWhileDead = false,
        canCancel = false,
        disableMovement = true,
        disableCombat = true
    })

    ClearPedTasks(playerPed)
    isPickpocketing = false

    if success then
        RequestModel("prop_cs_shopping_bag")
        while not HasModelLoaded("prop_cs_shopping_bag") do
            Wait(10)
        end
        bagObject = CreateObject(GetHashKey("prop_cs_shopping_bag"), 0, 0, 0, true, true, true)
        AttachEntityToEntity(bagObject, playerPed, GetPedBoneIndex(playerPed, 57005), 0.12, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)
        hasBag = true
        bagSpawnTime = GetGameTimer()
        lib.notify({
            title = "Móc túi",
            description = "Bạn đã lấy được một chiếc túi! Đi đến điểm mở túi trong 30 phút.",
            type = "success",
            position = "center-left"
        })
    end
end)

RegisterCommand('dropbag', function()
    if not hasBag then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local dropPoint = vector3(2588.76, 4849.24, 34.96)
    if #(coords - dropPoint) > 3.0 then
        lib.notify({
            title = "Cảnh báo",
            description = "Bạn cần đến vị trí mở túi!",
            type = "error",
            position = "center-left"
        })
        return
    end

    DetachEntity(bagObject, true, true)
    PlaceObjectOnGroundProperly(bagObject)
    hasBag = false

    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Wait(10)
    end
    TaskPlayAnim(playerPed, "mini@repair", "fixing_a_ped", 8.0, 8.0, -1, 1, 0, false, false, false)

    local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'e', 'q', 'e'})
    ClearPedTasks(playerPed)
    DeleteObject(bagObject)
    bagObject = nil

    if success then
        TriggerServerEvent('pickpocket:openBag')
    else
        lib.notify({
            title = "Mở túi",
            description = "Bạn đã thất bại khi mở túi!",
            type = "error",
            position = "center-left"
        })
    end
end, false)

RegisterNetEvent('pickpocket:notifyPolice')
AddEventHandler('pickpocket:notifyPolice', function()
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
    lib.notify({
        title = "🚨 Cảnh báo móc túi!",
        description = "Có báo cáo về một vụ móc túi gần đây!",
        type = "warning",
        position = "center-left",
        duration = 7000
    })
end)

RegisterNetEvent('pickpocket:setPoliceBlip')
AddEventHandler('pickpocket:setPoliceBlip', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.2)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🚨 Vụ móc túi")
    EndTextCommandSetBlipName(blip)
    PulseBlip(blip)
    Wait(60000)
    RemoveBlip(blip)
end)

RegisterKeyMapping('pickpocket', '<FONT FACE = "arial font">~y~Móc túi NPC', 'keyboard', 'E')
RegisterKeyMapping('dropbag', '<FONT FACE = "arial font">~y~Đặt túi xuống', 'keyboard', 'G')
