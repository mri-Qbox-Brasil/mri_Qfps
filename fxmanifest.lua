fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"

description "FPS Boost Script"
author "GFive & MRI Qbox"
version "1.0.0"

ox_lib "locale"

shared_scripts {
    "@ox_lib/init.lua",
    "shared/*.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/*.lua"
}

client_scripts {
    "@qbx_core/modules/playerdata.lua",
    "client/*.lua"
}

dependencies {
    "ox_lib",
}

files {
    "locales/*.json"
}

dependencies {
    "ox_lib"
}
