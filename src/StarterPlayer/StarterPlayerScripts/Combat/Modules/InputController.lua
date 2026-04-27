--!strict

local UserInputService = game:GetService("UserInputService")
local CombatConfig = require(game:GetService("ReplicatedStorage").Combat.CombatConfig)

local InputController = {}

export type Callbacks = {
	onM1: () -> (),
	onBlockStart: () -> (),
	onBlockEnd: () -> (),
	onJumpStart: () -> (),
	onJumpEnd: () -> (),
	onDebugToggle: () -> (),
}

local _lastM1: number = 0
local _blockHeld: boolean = false
local _spaceHeld: boolean = false

local _connections: { RBXScriptConnection } = {}

function InputController.Bind(cb: Callbacks)
	InputController.Unbind()

	table.insert(_connections, UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local now = os.clock()
			if now - _lastM1 >= CombatConfig.MinClientM1Interval then
				_lastM1 = now
				cb.onM1()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2
			or input.KeyCode == Enum.KeyCode.F then
			if not _blockHeld then
				_blockHeld = true
				cb.onBlockStart()
			end
		elseif input.KeyCode == Enum.KeyCode.Space then
			if not _spaceHeld then
				_spaceHeld = true
				cb.onJumpStart()
			end
		elseif input.KeyCode == Enum.KeyCode.L then
			cb.onDebugToggle()
		end
	end))

	table.insert(_connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton2
			or input.KeyCode == Enum.KeyCode.F then
			if _blockHeld then
				_blockHeld = false
				cb.onBlockEnd()
			end
		elseif input.KeyCode == Enum.KeyCode.Space then
			if _spaceHeld then
				_spaceHeld = false
				cb.onJumpEnd()
			end
		end
	end))
end

function InputController.Unbind()
	for _, c in ipairs(_connections) do c:Disconnect() end
	_connections = {}
end

return InputController