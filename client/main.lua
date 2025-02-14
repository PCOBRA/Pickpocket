local ESX = exports["es_extended"]:getSharedObject()

-- Hàm tìm NPC gần nhất
function GetClosestNPC(coords)
    local pedList = GetGamePool('CPed')
    local closestPed = nil
    local closestDist = 3.0 -- Bán kính tối đa

    for _, ped in ipairs(pedList) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
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

local cooldownActive = false
local isPickpocketing = false -- Biến kiểm tra trạng thái móc túi

RegisterNetEvent('pickpocket:cancelAction')
AddEventHandler('pickpocket:cancelAction', function()
    if isPickpocketing then -- Chỉ hủy nếu đang thực hiện hành động móc túi
        ClearPedTasksImmediately(PlayerPedId()) -- Hủy ngay animation nếu có
        isPickpocketing = false -- Reset trạng thái
        TriggerEvent('ox_lib:notify', {
            title = "Hành động bị hủy!",
            description = "Bạn không thể thực hiện hành động này!",
            type = "error",
            position = "center-right"
        })
    end
end)

RegisterCommand('pickpocket', function()
    if isPickpocketing then
        return -- Không hiển thị thông báo nếu không đang thực hiện móc túi
    end
    
    local playerPed = PlayerPedId()
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.job then return end
    
    local playerJob = string.lower(playerData.job.name) -- Chuyển về chữ thường
    
    -- Kiểm tra nếu nghề bị cấm ngay từ đầu
    for _, job in ipairs(Config.BlacklistedJobs) do
        if playerJob == string.lower(job) then
            TriggerEvent('ox_lib:notify', {
                title = "Cảnh báo",
                description = "Bạn không thể thực hiện hành động này!",
                type = "error",
                position = "center-right"
            })
            return
        end
    end
    
    local coords = GetEntityCoords(playerPed)
    local npc = GetClosestNPC(coords) -- Tìm NPC gần nhất

    if not npc or not DoesEntityExist(npc) or not IsPedDeadOrDying(npc, true) then
        return -- Không hiển thị thông báo nếu NPC không hợp lệ
    end

    isPickpocketing = true -- Đánh dấu đang móc túi
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

    -- Hiển thị progress bar
    local success = exports['ox_lib']:progressBar({
        duration = 60000, -- 60 giây
        label = "Đang móc túi...",
        useWhileDead = false,
        canCancel = false,
        disableMovement = true,
        disableCombat = true
    })

    ClearPedTasks(playerPed)
    isPickpocketing = false -- Reset trạng thái sau khi hoàn thành

    if success then
        TriggerServerEvent('pickpocket:attempt')
    else
        TriggerEvent('ox_lib:notify', {
            title = "Móc túi",
            description = "Bạn đã hủy hành động!",
            type = "error",
            position = "center-right"
        })
    end
end)

RegisterNetEvent('pickpocket:notifyPolice')
AddEventHandler('pickpocket:notifyPolice', function()
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
    lib.notify({
        title = "🚨 Cảnh báo móc túi!",
        description = "Có báo cáo về một vụ móc túi gần đây!",
        type = "warning",
        position = "center-right",
        duration = 7000
    })
end)

RegisterNetEvent('pickpocket:setPoliceBlip')
AddEventHandler('pickpocket:setPoliceBlip', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
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
