fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description "Modern ESX/QBCore Elevator System"

author 'Kedi.ss'

version '2.0.0'

client_scripts {
	'client/*.lua',
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js'
}

dependencies {
	'ox_lib',
	'kedi_ui'
}