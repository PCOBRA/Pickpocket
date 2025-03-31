local ESX = exports["es_extended"]:getSharedObject()

-- Hàm gửi webhook Discord
local function sendToDiscord(message)
    if Config.WebhookURL and Config.WebhookURL ~= 'YOUR_DISCORD_WEBHOOK_URL_HERE' then
        local embed = {
            {
                ["title"] = "Pickpocket Log",
                ["description"] = message,
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["footer"] = {["text"] = "ESX Pickpocket System"}
            }
        }
        PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

-- Kiểm tra khu vực cấm
local function isInRestrictedZone(coords)
    for _, zone in ipairs(Config.RestrictedZones) do
        if zone.type == "circle" then
            local dist = #(coords - zone.center)
            if dist < zone.radius then return true end
        elseif zone.type == "polygon" then
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
            if inside then return true end
        end
    end
    return false
end

RegisterNetEvent('pickpocket:checkPolice')
AddEventHandler('pickpocket:checkPolice', function(npcNetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local currentTime = os.time()
    local playerName = xPlayer.getName() or "Unknown"

    playerCooldowns = playerCooldowns or {}
    if Config.Cooldown.enable then
        local cooldownTime = Config.Cooldown.time
        if playerCooldowns[src] and (currentTime - playerCooldowns[src]) < cooldownTime then
            local remaining = cooldownTime - (currentTime - playerCooldowns[src])
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Cảnh báo",
                description = "Bạn cần chờ " .. remaining .. " giây trước khi móc túi tiếp!",
                type = "error",
                position = "center-left"
            })
            sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") thất bại khi móc túi: Còn " .. remaining .. " giây cooldown.")
            return
        end
    end

    local policePlayers = ESX.GetExtendedPlayers('job', 'police')
    if #policePlayers < Config.MinPolice then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Cảnh báo",
            description = "Không đủ cảnh sát để thực hiện hành vi này!",
            type = "error",
            position = "center-left"
        })
        sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") thất bại khi móc túi: Không đủ cảnh sát (" .. #policePlayers .. "/" .. Config.MinPolice .. ").")
        return
    end

    if isInRestrictedZone(playerCoords) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Cảnh báo",
            description = "Bạn không thể móc túi ở khu vực này!",
            type = "error",
            position = "center-left"
        })
        sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") thất bại khi móc túi: Trong khu vực cấm.")
        return
    end

    local npc = NetworkGetEntityFromNetworkId(npcNetId)
    if not npc or not DoesEntityExist(npc) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Cảnh báo",
            description = "Không tìm thấy NPC hợp lệ!",
            type = "error",
            position = "center-left"
        })
        sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") thất bại khi móc túi: Không tìm thấy NPC hợp lệ.")
        return
    end

    if math.random(1, 100) <= Config.PoliceAlertChance then
        for _, police in pairs(policePlayers) do
            TriggerClientEvent('pickpocket:notifyPolice', police.source)
            TriggerClientEvent('pickpocket:setPoliceBlip', police.source, playerCoords)
        end
        sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") đã kích hoạt cảnh báo cảnh sát khi móc túi.")
    end

    TriggerClientEvent('pickpocket:startProgress', src)
    playerCooldowns[src] = currentTime
    sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") bắt đầu móc túi.")
end)

RegisterNetEvent('pickpocket:openBag')
AddEventHandler('pickpocket:openBag', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local playerName = xPlayer.getName() or "Unknown"
    local rewards = {"rolex", "diamond_ring", "lphone1"}
    local reward = rewards[math.random(#rewards)]

    local success = xPlayer.addInventoryItem(reward, 1)
    if success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Mở túi thành công!",
            description = "Bạn nhận được " .. reward .. "!",
            type = "success",
            position = "center-left"
        })
        sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") đã mở túi thành công và nhận được " .. reward .. ".")
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Mở túi thất bại!",
            description = "Không thể thêm " .. reward .. " vào kho của bạn!",
            type = "error",
            position = "center-left"
        })
        sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") thất bại khi mở túi: Không thể thêm " .. reward .. " vào kho.")
    end
end)

RegisterNetEvent('pickpocket:lostBag')
AddEventHandler('pickpocket:lostBag', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local playerName = xPlayer.getName() or "Unknown"
    sendToDiscord("Người chơi " .. playerName .. " (ID: " .. src .. ") đã để mất túi do không mở kịp trong 30 phút.")
end)

function hasBlacklistedJob(job)
    for _, blacklistedJob in ipairs(Config.BlacklistedJobs) do
        if job == blacklistedJob then return true end
    end
    return false
end
