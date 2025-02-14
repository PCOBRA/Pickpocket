local ESX = exports["es_extended"]:getSharedObject()
-- Hàm tìm NPC gần nhất trong bán kính 5m
local function GetClosestNPC(coords)
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
-- Kiểm tra nếu tọa độ của người chơi nằm trong khu vực cấm
local function isInRestrictedZone(coords)
    for _, zone in ipairs(Config.RestrictedZones) do
        if zone.type == "circle" then
            -- Kiểm tra khu vực hình tròn
            local dist = #(coords - zone.center)
            if dist < zone.radius then
                return true
            end
        elseif zone.type == "polygon" then
            -- Kiểm tra khu vực đa giác bằng thuật toán Ray-Casting
            local inside = false
            local j = #zone.points
            for i = 1, #zone.points do
                local xi, yi = zone.points[i].x, zone.points[i].y
                local xj, yj = zone.points[j].x, zone.points[j].y
                if ((yi > coords.y) ~= (yj > coords.y)) and
                   (coords.x < (xj - xi) * (coords.y - yi) / (yj - yi) + xi) then
                    inside = not inside
                end
                j = i
            end
            if inside then
                return true
            end
        end
    end
    return false
end

RegisterNetEvent('pickpocket:attempt')
AddEventHandler('pickpocket:attempt', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local playerJob = string.lower(xPlayer.getJob().name) -- Chuyển về chữ thường
    print("📌 Nghề nghiệp của người chơi:", playerJob) -- Debug log
    
    -- Kiểm tra nếu nghề bị cấm
    for _, job in ipairs(Config.BlacklistedJobs) do
        if playerJob == string.lower(job) then
            print("⛔ Người chơi có nghề bị cấm đang cố gắng móc túi!", playerJob) -- Debug log
            TriggerClientEvent('pickpocket:cancelAction', src) -- Hủy ngay hành động
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Cảnh báo",
                description = "Bạn không thể thực hiện hành động này!",
                type = "error",
                position = "center-right"
            })
            return
        end
    end
    
    -- Nếu hợp lệ, tiếp tục thực hiện hành động
    local rewards = {"rolex", "diamond_ring", "lphone1"}
    local reward = rewards[math.random(#rewards)]
    
    xPlayer.addInventoryItem(reward, 1)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = "Móc túi thành công!",
        description = "Bạn nhận được " .. reward .. "!",
        type = "success",
        position = "center-right"
    })
end)

RegisterNetEvent('pickpocket:checkPolice')
AddEventHandler('pickpocket:checkPolice', function(npcNetId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local currentTime = os.time()

    -- Kiểm tra nếu cooldown được bật
    if Config.Cooldown.enable then
        playerCooldowns = playerCooldowns or {} -- Đảm bảo biến tồn tại
        local cooldownTime = Config.Cooldown.time -- Lấy thời gian từ config.lua
        
        if playerCooldowns[src] and (currentTime - playerCooldowns[src]) < cooldownTime then
            local remaining = cooldownTime - (currentTime - playerCooldowns[src])
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Cảnh báo",
                description = "Bạn cần chờ " .. remaining .. " giây trước khi móc túi tiếp!",
                type = "error",
                position = "center-right",
            })
            return
        end
    
        -- Đặt cooldown nếu người chơi được phép móc túi
        playerCooldowns[src] = currentTime
    end
    

    -- Kiểm tra số lượng cảnh sát online
    local policePlayers = ESX.GetExtendedPlayers('job', 'police')
    if #policePlayers < Config.MinPolice then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Cảnh báo",
            description = "Không đủ cảnh sát để thực hiện hành vi này!",
            type = "error",
            position = "center-right",
        })
        return
    end

    -- Kiểm tra nếu đang ở khu vực cấm
    if isInRestrictedZone(playerCoords) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Cảnh báo",
            description = "Bạn không thể móc túi ở khu vực này!",
            type = "error",
            position = "center-right",
        })
        return
    end

    -- Xác nhận NPC từ network ID được gửi từ client
    local npc = NetworkGetEntityFromNetworkId(npcNetId)
    if not npc or not DoesEntityExist(npc) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Cảnh báo",
            description = "Không tìm thấy NPC hợp lệ!",
            type = "error",
            position = "center-right",
        })
        return
    end

    local policePlayers = ESX.GetExtendedPlayers('job', 'police')

    -- Xác suất cảnh sát nhận thông báo từ config.lua
    if math.random(1, 100) <= Config.PoliceAlertChance then
        for _, police in pairs(policePlayers) do
            TriggerClientEvent('pickpocket:notifyPolice', police.source)
            TriggerClientEvent('pickpocket:setPoliceBlip', police.source, playerCoords)
        end
    end

    TriggerClientEvent('pickpocket:startProgress', src)
end)



