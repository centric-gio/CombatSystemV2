--!strict

local AnimationPlayer = {}

local _tracks: { [string]: AnimationTrack } = {}
local _humanoid: Humanoid? = nil
local _animator: Animator? = nil

function AnimationPlayer.Bind(character: Model, animFolder: Folder)
	_tracks = {}
	_humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not _humanoid then return end

	local found = _humanoid:FindFirstChildOfClass("Animator")
	local animator: Animator
	if found then
		animator = found
	else
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = _humanoid
		animator = newAnimator
	end
	_animator = animator

	for _, child in ipairs(animFolder:GetChildren()) do
		if child:IsA("Animation") then
			local track = animator:LoadAnimation(child)
			_tracks[child.Name] = track
		end
	end
end

function AnimationPlayer.Play(name: string, fadeIn: number?, weight: number?, speed: number?)
	local track = _tracks[name]
	if not track then return end
	track:Play(fadeIn or 0.1, weight or 1, speed or 1)
end

function AnimationPlayer.Stop(name: string, fadeOut: number?)
	local track = _tracks[name]
	if not track then return end
	track:Stop(fadeOut or 0.1)
end

function AnimationPlayer.StopAll(fadeOut: number?)
	for _, track in pairs(_tracks) do
		track:Stop(fadeOut or 0.1)
	end
end

return AnimationPlayer