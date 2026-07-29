--[[ SKILLBAR DEMO ]]
--
local scDelay = 5000
local scPass = 1
RegisterNetEvent("Minigame:Client:Skillbar", function()
	plsr.Minigame.Play:Skillbar(scDelay, 10 - scPass, {
		onSuccess = "Minigame:Client:DemoSkillbarSuccess",
		onFail = "Minigame:Client:DemoSkillbarFail",
	})
end)

AddEventHandler("Minigame:Client:DemoSkillbarSuccess", function(data)
	if scDelay <= 1000 then
		plsr.Notification:Success("Won All The Things")
		scDelay = 5000
		scPass = 1
	else
		scDelay = scDelay - 1000
		scPass = scPass + 1
		Wait(400)
		TriggerEvent("Minigame:Client:Skillbar")
	end
end)

AddEventHandler("Minigame:Client:DemoSkillbarFail", function(data)
	plsr.Notification:Error("Skill Check Failed")
	scDelay = 5000
	scPass = 1
end)

--[[ ROUND SKILLBAR DEMO ]]
--
RegisterNetEvent("Minigame:Client:Round", function()
	plsr.Minigame.Play:RoundSkillbar(0.5, 4, {
		onSuccess = "Minigame:Client:DemoRoundResult",
		onFail = "Minigame:Client:DemoRoundResult",
	})
end)

AddEventHandler("Minigame:Client:DemoRoundResult", function(data)
	plsr.Notification:Success("Round Skillbar Done")
end)

--[[ SCANNER DEMO ]]
--
local scanTimer = 50
local scanPass = 1
RegisterNetEvent("Minigame:Client:Scanner", function()
	plsr.Minigame.Play:Scanner(5, scanTimer, 5000, 20, 5 - scanPass, true, {
		onPerfect = "Minigame:Client:DemoScannerPerfect",
		onSuccess = "Minigame:Client:DemoScannerSuccess",
		onFail = "Minigame:Client:DemoScannerFail",
	})
end)

AddEventHandler("Minigame:Client:DemoScannerPerfect", function(data)
	plsr.Notification:Success("PERFECTION!")
end)

AddEventHandler("Minigame:Client:DemoScannerSuccess", function(data)
	if scanPass >= 5 then
		plsr.Notification:Success("Won All The Things")
		scanPass = 1
	else
		scanPass = scanPass + 1
		Wait(400)
		TriggerEvent("Minigame:Client:Scanner")
	end
end)

AddEventHandler("Minigame:Client:DemoScannerFail", function(data)
	plsr.Notification:Error("Scanner Failed")
	scanPass = 1
end)

--[[ SEQUENCER DEMO ]]
--
local seqPass = 1
RegisterNetEvent("Minigame:Client:Sequencer", function()
	plsr.Minigame.Play:Sequencer(5, 250, 10000 - (1000 * seqPass), 3 + seqPass, false, {
		onPerfect = "Minigame:Client:DemoSequencerPerfect",
		onSuccess = "Minigame:Client:DemoSequencerSuccess",
		onFail = "Minigame:Client:DemoSequencerFail",
	})
end)

AddEventHandler("Minigame:Client:DemoSequencerPerfect", function(data)
	plsr.Notification:Success("PERFECTION!")
end)

AddEventHandler("Minigame:Client:DemoSequencerSuccess", function(data)
	if seqPass >= 3 then
		plsr.Notification:Success("Won All The Things")
		seqPass = 1
	else
		seqPass = seqPass + 1
		Wait(1000)
		TriggerEvent("Minigame:Client:Sequencer")
	end
end)

AddEventHandler("Minigame:Client:DemoSequencerFail", function(data)
	plsr.Notification:Error("Sequencer Failed")
	seqPass = 1
end)

--[[ KEYPAD DEMO ]]
--
RegisterNetEvent("Minigame:Client:Keypad", function()
	plsr.Minigame.Play:Keypad("1234", 3, 10000, false, {
		onSuccess = "Minigame:Client:DemoKeypadSuccess",
		onFail = "Minigame:Client:DemoKeypadFail",
	})
end)

AddEventHandler("Minigame:Client:DemoKeypadSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoKeypadFail", function(data)
	plsr.Notification:Error("Keypad Failed")
end)

--[[ SCRAMBLER DEMO ]]
--
local scramblerStage = 0
RegisterNetEvent("Minigame:Client:Scrambler", function()
	scramblerStage = 0
	DoScramblerStage()
end)

function DoScramblerStage()
	plsr.Minigame.Play:Scrambler(5, 3000, 14000 + (scramblerStage * 2000), 3, 16 + (scramblerStage * 4), {
		onPerfect = function()
			if scramblerStage < 3 then
				scramblerStage = scramblerStage + 1
				DoScramblerStage()
			else
				TriggerEvent("Minigame:Client:DemoScramblerPerfect")
			end
		end,
		onSuccess = function()
			if scramblerStage < 3 then
				scramblerStage = scramblerStage + 1
				DoScramblerStage()
			else
				TriggerEvent("Minigame:Client:DemoScramblerSuccess")
			end
		end,
		onFail = "Minigame:Client:DemoScramblerFail",
	})
end

AddEventHandler("Minigame:Client:DemoScramblerPerfect", function(data)
	plsr.Notification:Success("PERFECTION!")
end)

AddEventHandler("Minigame:Client:DemoScramblerSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoScramblerFail", function(data)
	plsr.Notification:Error("Scrambler Failed")
end)

--[[ MEMORY DEMO ]]
--
local memPass = 1
RegisterNetEvent("Minigame:Client:Memory", function()
	plsr.Minigame.Play:Memory(5, 2000, 10000, 3, 3, 4 + memPass, 3, {
		onPerfect = "Minigame:Client:DemoMemoryPerfect",
		onSuccess = "Minigame:Client:DemoMemorySuccess",
		onFail = "Minigame:Client:DemoMemoryFail",
	})
end)

AddEventHandler("Minigame:Client:DemoMemoryPerfect", function(data)
	plsr.Notification:Success("PERFECTION!")
	memPass = 1
end)

AddEventHandler("Minigame:Client:DemoMemorySuccess", function(data)
	if memPass >= 4 then
		plsr.Notification:Success("Won All The Things")
		memPass = 1
	else
		memPass = memPass + 1
		Wait(400)
		TriggerEvent("Minigame:Client:Memory")
	end
end)

AddEventHandler("Minigame:Client:DemoMemoryFail", function(data)
	plsr.Notification:Error("Memory Failed")
	memPass = 1
end)

--[[ AIM DEMO ]]
--
RegisterNetEvent("Minigame:Client:Aim", function()
	plsr.Minigame.Play:Aim(3, 5000, 1000, 25, 75, 25, 25, true, {
		onPerfect = "Minigame:Client:DemoAimResult",
		onSuccess = "Minigame:Client:DemoAimResult",
		onFail = "Minigame:Client:DemoAimResult",
	})
end)

AddEventHandler("Minigame:Client:DemoAimResult", function(data)
	plsr.Notification:Success("Aim Done")
end)

--[[ CAPTCHA DEMO ]]
--
RegisterNetEvent("Minigame:Client:Captcha", function()
	plsr.Minigame.Play:Captcha(3, 5000, 30000, 5, 2, {
		onSuccess = "Minigame:Client:DemoCaptchaSuccess",
		onFail = "Minigame:Client:DemoCaptchaFail",
	})
end)

AddEventHandler("Minigame:Client:DemoCaptchaSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoCaptchaFail", function(data)
	plsr.Notification:Error("Captcha Failed")
end)

--[[ KEYMASTER DEMO ]]
--
RegisterNetEvent("Minigame:Client:Keymaster", function()
	plsr.Minigame.Play:Keymaster(3, { 3500, 3500 }, 35000, 4, 10, false, {
		onSuccess = "Minigame:Client:DemoKeymasterSuccess",
		onFail = "Minigame:Client:DemoKeymasterFail",
	})
end)

AddEventHandler("Minigame:Client:DemoKeymasterSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoKeymasterFail", function(data)
	plsr.Notification:Error("Keymaster Failed")
end)

--[[ PATTERN DEMO ]]
--
RegisterNetEvent("Minigame:Client:Pattern", function()
	plsr.Minigame.Play:Pattern(3, 350000, 6, 4, 2, "braille", {
		onSuccess = "Minigame:Client:DemoPatternSuccess",
		onFail = "Minigame:Client:DemoPatternFail",
	})
end)

AddEventHandler("Minigame:Client:DemoPatternSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoPatternFail", function(data)
	plsr.Notification:Error("Pattern Failed")
end)

--[[ ICONS DEMO ]]
--
RegisterNetEvent("Minigame:Client:Icons", function()
	plsr.Minigame.Play:Icons(3, 5, 15000, 1500, 8, 8, {
		onSuccess = "Minigame:Client:DemoIconsSuccess",
		onFail = "Minigame:Client:DemoIconsFail",
	})
end)

AddEventHandler("Minigame:Client:DemoIconsSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoIconsFail", function(data)
	plsr.Notification:Error("Icons Failed")
end)

--[[ TRACKING DEMO ]]
--
RegisterNetEvent("Minigame:Client:Tracking", function()
	plsr.Minigame.Play:Tracking(3, 1500, 15000, 3, {
		onSuccess = "Minigame:Client:DemoTrackingSuccess",
		onFail = "Minigame:Client:DemoTrackingFail",
	})
end)

AddEventHandler("Minigame:Client:DemoTrackingSuccess", function(data)
	plsr.Notification:Success("Won All The Things")
end)

AddEventHandler("Minigame:Client:DemoTrackingFail", function(data)
	plsr.Notification:Error("Tracking Failed")
end)
