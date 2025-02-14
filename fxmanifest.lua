fx_version 'cerulean'
game 'gta5'

name 'ESX Pickpocket'
author 'Pin Cobra'
description 'Móc túi NPC với hệ thống phần thưởng và cảnh báo cảnh sát'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib'
}