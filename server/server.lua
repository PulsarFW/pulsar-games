local _uircd = {}

function RegisterChatCommands()
	plsr.Chat:RegisterAdminCommand("notif", function(source, args, rawCommand)
		plsr.Execute:Client(source, "Notification", "Success", "This is a test, lul")
	end, {
		help = "Test Notification",
	})

	plsr.Chat:RegisterAdminCommand("list", function(source, args, rawCommand)
		TriggerClientEvent("ListMenu:Client:Test", source)
	end, {
		help = "Test List Menu",
	})

	plsr.Chat:RegisterAdminCommand("input", function(source, args, rawCommand)
		TriggerClientEvent("Input:Client:Test", source)
	end, {
		help = "Test Input",
	})

	plsr.Chat:RegisterAdminCommand("confirm", function(source, args, rawCommand)
		TriggerClientEvent("Confirm:Client:Test", source)
	end, {
		help = "Test Confirm Dialog",
	})

	plsr.Chat:RegisterAdminCommand("skill", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Skillbar", source)
	end, {
		help = "Test Skill Bar",
	})

	plsr.Chat:RegisterAdminCommand("scan", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Scanner", source)
	end, {
		help = "Test Scanner",
	})

	plsr.Chat:RegisterAdminCommand("sequencer", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Sequencer", source)
	end, {
		help = "Test Sequencer",
	})

	plsr.Chat:RegisterAdminCommand("keypad", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Keypad", source)
	end, {
		help = "Test Keypad",
	})

	plsr.Chat:RegisterAdminCommand("scrambler", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Scrambler", source)
	end, {
		help = "Test Scrambler",
	})

	plsr.Chat:RegisterAdminCommand("memory", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Memory", source)
	end, {
		help = "Test Memory",
	})

	plsr.Chat:RegisterAdminCommand("round", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Round", source)
	end, {
		help = "Test Round Skillbar",
	})

	plsr.Chat:RegisterAdminCommand("aim", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Aim", source)
	end, {
		help = "Test Aim",
	})

	plsr.Chat:RegisterAdminCommand("captcha", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Captcha", source)
	end, {
		help = "Test Captcha",
	})

	plsr.Chat:RegisterAdminCommand("keymaster", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Keymaster", source)
	end, {
		help = "Test Keymaster",
	})

	plsr.Chat:RegisterAdminCommand("pattern", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Pattern", source)
	end, {
		help = "Test Pattern",
	})

	plsr.Chat:RegisterAdminCommand("icons", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Icons", source)
	end, {
		help = "Test Icons",
	})

	plsr.Chat:RegisterAdminCommand("tracking", function(source, args, rawCommand)
		TriggerClientEvent("Minigame:Client:Tracking", source)
	end, {
		help = "Test Tracking",
	})
end

RegisterChatCommands()
