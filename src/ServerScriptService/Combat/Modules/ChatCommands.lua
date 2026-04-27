--!strict

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local DummyManager = require(script.Parent.DummyManager)

local ChatCommands = {}

local function aliasFor(name: string): string
	return "/" .. name
end

function ChatCommands.Register()
	local spawnCmd = Instance.new("TextChatCommand")
	spawnCmd.Name = "SpawnDummyCmd"
	spawnCmd.PrimaryAlias = aliasFor("spawn")
	spawnCmd.SecondaryAlias = aliasFor("sp")
	spawnCmd.Parent = TextChatService

	spawnCmd.Triggered:Connect(function(textSource: TextSource, message: string)
		local plr = Players:GetPlayerByUserId(textSource.UserId)
		if not plr then return end

		local arg = string.match(message, "^%S+%s+(%S+)")
		local map: { [string]: string } = {
			idle = "Idle", i = "Idle",
			block = "Blocking", b = "Blocking",
			attack = "Attacking", a = "Attacking",
			perfect = "PerfectBlock", p = "PerfectBlock", pb = "PerfectBlock",
		}

		local aiType: string = "Idle"
		if arg then
			local mapped = map[string.lower(arg)]
			if mapped then aiType = mapped end
		end

		DummyManager.Spawn(plr, aiType)
	end)

	local clearCmd = Instance.new("TextChatCommand")
	clearCmd.Name = "ClearDummiesCmd"
	clearCmd.PrimaryAlias = aliasFor("cleardummies")
	clearCmd.SecondaryAlias = aliasFor("cd")
	clearCmd.Parent = TextChatService

	clearCmd.Triggered:Connect(function(textSource: TextSource, _message: string)
		local plr = Players:GetPlayerByUserId(textSource.UserId)
		DummyManager.ClearAll(plr)
	end)
end

return ChatCommands