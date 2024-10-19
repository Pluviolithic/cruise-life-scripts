--[[ Services ]]
--

local tween_service = game:GetService "TweenService"
local players = game:GetService "Players"
local run_service = game:GetService "RunService"
local replicated_storage = game:GetService "ReplicatedStorage"

--[[ Variables ]]
--

local globals = require(replicated_storage.Client_Accessible_Modules.Global_Replacements)

--[[ Functions ]]
--

local function handle_sliding_door(door)
	local scanner = door.Scanner
	local left = door.Left.PrimaryPart
	local right = door.Right.PrimaryPart
	local tween_info = TweenInfo.new(1)
	local doors_open = false
	local doors_opening = false

	local function generate_open_tweens(door, add)
		local cframe = door.CFrame
		local look_vector = cframe.LookVector
		local up_vector = cframe.UpVector
		local new_pos
		if add then
			new_pos = door.Position + look_vector:Cross(up_vector) * 4.05
		else
			new_pos = door.Position - look_vector:Cross(up_vector) * 4.05
		end
		return tween_service:Create(door, tween_info, {
			["CFrame"] = CFrame.new(new_pos.X, new_pos.Y, new_pos.Z, select(4, door.CFrame:GetComponents())),
		})
	end

	local open_tweens = {
		generate_open_tweens(right, false),
		generate_open_tweens(left, true),
	}
	local close_tweens = {
		tween_service:Create(right, tween_info, {
			["CFrame"] = right.CFrame,
		}),
		tween_service:Create(left, tween_info, {
			["CFrame"] = left.CFrame,
		}),
	}

	local function open_doors()
		doors_opening = true
		for _, t in ipairs(open_tweens) do
			t:Play()
		end
		open_tweens[2].Completed:Wait()
		doors_opening = false
		doors_open = true
	end

	local function close_doors()
		doors_opening = false
		doors_open = false
		for _, t in ipairs(close_tweens) do
			t:Play()
		end
		close_tweens[2].Completed:Wait()
	end

	while true do
		task.wait(0.25)
		local found_player_in_range
		for _, player in ipairs(players:GetPlayers()) do
			local humanoid_root_part = player.Character and player.Character:FindFirstChild "HumanoidRootPart"
			if humanoid_root_part and (scanner.Position - humanoid_root_part.Position).Magnitude < 15 then
				found_player_in_range = true
				if not doors_opening and not doors_open then
					open_doors()
				end
				break
			end
		end
		if not found_player_in_range and (doors_open or doors_opening) then
			close_doors()
		end
	end
end

return handle_sliding_door
