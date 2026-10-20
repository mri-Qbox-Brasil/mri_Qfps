fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"

name "mri_Qfps"
description "Menu de FPS, filtros gráficos e mira customizada, com aba de ajustes no mri_Qadmin"
author "GFive, GH & MRI Qbox"
version "1.1.0"
repository "https://github.com/mri-Qbox-Brasil/mri_Qfps"

ox_lib "locale"

shared_scripts {
    "@ox_lib/init.lua",
    "shared/config.lua",
    "shared/settings.lua",
}

server_scripts {
    "server/main.lua",
    "server/settings.lua",
    "server/report.lua",
}

client_scripts {
    "client/graphics.lua",
    "client/metrics.lua",
    "client/auto.lua",
    "client/main.lua",
}

ui_page "html/index.html"

files {
    "locales/*.json",
    "html/**/*",
}

dependencies {
    "ox_lib",
}
