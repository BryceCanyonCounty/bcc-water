fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
author 'BCC @Apollyon'

shared_scripts {
	'config/*.lua',
	'locale.lua',
	'languages/*.lua'
}

client_scripts {
	'client/dataview.lua',
    'client/main.lua',
    'client/functions.lua',
    'client/helpers.lua'
}

server_scripts {
	'server/main.lua',
    'server/versioncheck.lua'
}

version '1.2.1'