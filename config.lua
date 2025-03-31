Config = {}
Config.PoliceAlertChance = 30 -- Tỷ lệ % cảnh sát nhận thông báo (mặc định 30%)

Config.RestrictedZones = {
    -- Khu vực hình tròn
    {type = "circle", center = vector3(440.84, -983.14, 30.69), radius = 70.0}, -- Trụ sở cảnh sát
    {type = "circle", center = vector3(1853.23, 3687.49, 34.27), radius = 50.0}, -- Đồn cảnh sát Sandy Shores
    {type = "circle", center = vector3(335.48, -582.64, 79.24), radius = 70.0}, -- Benh vien
    -- Khu vực đa giác (polyzone)
    {
        type = "polygon",
        points = { -- Khu Chợ Xe
            vector3(239.6, -820.44, 30.08), 
            vector3(259.52, -768.4, 30.8), 
            vector3(218.76, -754.48, 30.84), 
            vector3(199.96, -805.8, 31.08)
        }
    },
    {
        type = "polygon",
        points = { -- Sân FNPD
            vector3(411.12, -1034.16, 29.44),
            vector3(459.04, -1026.92, 28.44),
            vector3(459.12, -1009.32, 28.24),
            vector3(456.32, -1009.44, 28.36),
            vector3(456.2, -1011.56, 28.4),
            vector3(454.8, -1011.28, 28.48),
            vector3(454.48, -1002.36, 26.0),
            vector3(445.24, -1001.92, 25.84),
            vector3(444.76, -1012.96, 28.56),
            vector3(427.28, -1012.88, 28.96),
            vector3(427.08, -1010.2, 28.96),
            vector3(420.44, -1010.96, 29.16),
            vector3(411.36, -1018.16, 29.36)
        }
    },
    {
        type = "polygon",
        points = { -- Bãi Xe Benh Vien
            vector3(356.24, -622.08, 28.96),
            vector3(347.24, -636.68, 29.2),
            vector3(320.6, -626.88, 29.28),
            vector3(326.4, -611.24, 29.28)
        }
    },
    {
        type = "polygon",
        points = { -- Sanh truoc Benh Vien
            vector3(296.84, -617.96, 43.44),
            vector3(290.92, -616.0, 43.44),
            vector3(290.44, -617.08, 43.44),
            vector3(267.56, -607.92, 42.6),
            vector3(286.08, -563.68, 43.12),
            vector3(298.96, -569.52, 43.36),
            vector3(301.08, -574.72, 43.28),
            vector3(293.32, -599.32, 43.32),
            vector3(301.92, -602.76, 43.36)
        }
    },
}

Config.Cooldown = {
    enable = true,
    time = 1800 -- Thời gian cooldown (giây)
}
Config.BlacklistedJobs = {"police", "ambulance", "sheriff"}
Config.MinPolice = 0 -- Số lượng cảnh sát tối thiểu
Config.RewardZones = {
    downtown = {"rolex"},
    beach = {"diamond_ring"},
    random = {"lphone1"}
}
Config.WebhookURL = 'YOUR_DISCORD_WEBHOOK_URL_HERE' -- Thay bằng URL webhook thực tế của bạn

function hasBlacklistedJob(job)
    for _, blacklistedJob in ipairs(Config.BlacklistedJobs) do
        if job == blacklistedJob then return true end
    end
    return false
end
