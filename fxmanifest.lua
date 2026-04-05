fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'permissions/list.lua',
    'locales/shared.lua',
    'locales/*.lua',
    '@es_extended/imports.lua',
    '@qb-core/shared/locale.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua',
    '@mysql-async/lib/MySQL.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/logo.png',
    'sounds/notification.mp3'
}

escrow_ignore {
    'config.lua',
    'permissions/list.lua'
}

dependency '/assetpacks'