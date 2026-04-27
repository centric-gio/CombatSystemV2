--!strict

local CombatTypes = require(game:GetService("ReplicatedStorage").Combat.CombatTypes)

type EntityState = CombatTypes.EntityState

local EntityAnim = {}

local _animFolder: Folder? = nil

function EntityAnim.Init(animFolder: Folder)
	_animFolder = animFolder
end

function EntityAnim.Setup(entity: EntityState)
	if not entity.isDummy then return end
	if not _animFolder then return end

	local found = entity.humanoid:FindFirstChildOfClass("Animator")
	local animator: Animator
	if found then
		animator = found
	else
		local newAnim = Instance.new("Animator")
		newAnim.Parent = entity.humanoid
		animator = newAnim
	end

	local tracks: { [string]: AnimationTrack } = {}
	for _, child in ipairs((_animFolder :: Folder):GetChildren()) do
		if child:IsA("Animation") then
			local ok, track = pcall(function()
				return animator:LoadAnimation(child)
			end)
			if ok and track then
				tracks[child.Name] = track
			end
		end
	end
	entity.animTracks = tracks
end

function EntityAnim.Play(entity: EntityState, animName: string, fadeIn: number?)
	local tracks = entity.animTracks
	if not tracks then return end
	local track = tracks[animName]
	if not track then return end
	track:Play(fadeIn or 0.1)
end

function EntityAnim.Stop(entity: EntityState, animName: string, fadeOut: number?)
	local tracks = entity.animTracks
	if not tracks then return end
	local track = tracks[animName]
	if not track then return end
	track:Stop(fadeOut or 0.1)
end

function EntityAnim.StopAll(entity: EntityState, fadeOut: number?)
	local tracks = entity.animTracks
	if not tracks then return end
	for _, track in pairs(tracks) do
		track:Stop(fadeOut or 0.1)
	end
end

return EntityAnim