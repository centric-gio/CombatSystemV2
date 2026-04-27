--!strict
local RunService = game:GetService("RunService")
local CameraShaker = {}

local shakeTime = 0
local shakeIntensity = 0
local duration = 0

function CameraShaker.Shake(intensity: number, timeDur: number)
	shakeIntensity = intensity
	duration = timeDur
	shakeTime = timeDur
end

RunService.RenderStepped:Connect(function(dt: number)
	if shakeTime > 0 then
		shakeTime = math.max(0, shakeTime - dt)
		local cam = workspace.CurrentCamera
		if cam then
			local progress = shakeTime / duration
			local damp = progress * progress -- Eases out smoothly over time
			local x = (math.random() - 0.5) * 2 * shakeIntensity * damp
			local y = (math.random() - 0.5) * 2 * shakeIntensity * damp
			local z = (math.random() - 0.5) * 2 * shakeIntensity * damp
			cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
		end
	end
end)

return CameraShaker