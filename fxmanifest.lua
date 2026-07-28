fx_version("cerulean")


name 'Pulsar Games'
description 'Shared minigame framework'
author 'Artmines - maintained for Pulsar Framework'
url 'https://pulsarframe.work'
version 'v1.0.0'

version_check 'yes'
github 'https://github.com/PulsarFW/pulsar_games'
games({ "gta5" })
lua54("yes")
client_script("@pulsar_core/components/cl_error.lua")
shared_script("@pulsar_core/core/sh_pulsar.lua")
client_script("@pulsar_pwnzor/client/check.lua")

-- data_file "SCALEFORM_DLC_FILE" "stream/int3232302352.gfx"

client_scripts({
	"config.lua",
	"client/*.lua",
	--'demo_games.lua',
})

server_scripts({
	"config.lua",
	"server/*.lua",
})

ui_page("ui/dist/index.html")
files({
	"ui/dist/index.html",
	"ui/dist/*.png",
	"ui/dist/*.webp",
	"ui/dist/*.js",
	"ui/dist/*.mp3",
	"ui/dist/*.ogg",
	"ui/dist/*.ttf",
})
