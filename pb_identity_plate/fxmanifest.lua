fx_version 'cerulean'
game 'gta5'

name 'pb_identity_plate'
author 'Petrino + ChatGPT'
description 'VIP změna jména přes item + sundání SPZ pro kriminálníky (ox_inventory, ox_lib, okokNotify, ESX).'
version '1.0.0'

lua54 'yes'

shared_script 'config/config.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}
