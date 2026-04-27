--!strict

local SoundPlayer = {}

local _templates: Folder? = nil
local _emitter: BasePart? = nil

function SoundPlayer.Bind(character: Model, soundFolder: Folder)
	_templates = soundFolder
	_emitter = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
end

function SoundPlayer.Play(name: string)
	if not (_templates and _emitter) then return end
	local tpl = _templates:FindFirstChild(name)
	if not (tpl and tpl:IsA("Sound")) then return end
	local s = tpl:Clone()
	s.Parent = _emitter
	s.PlayOnRemove = false
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	-- Failsafe destroy
	task.delay(5, function() if s and s.Parent then s:Destroy() end end)
end

return SoundPlayer