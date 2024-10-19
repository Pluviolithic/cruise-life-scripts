--[[ Services ]]
--

local replicated_storage = game:GetService "ReplicatedStorage"
local server_storage = game:GetService "ServerStorage"
local players = game:GetService "Players"
local tween_service = game:GetService "TweenService"
local run_service = game:GetService "RunService"
local badge_service = game:GetService "BadgeService"

--[[ Variables ]]
--

local general_functions = require(server_storage.Modules.General_Functions)
local remotes = replicated_storage.Remotes
local alert = remotes.Alert
local fade = remotes.Fade
local spawn_cframe
local hit_checkpoints
local character_debounce_list
local running = false
local miscellaneous = replicated_storage.Miscellaneous
local current_event_active = miscellaneous.Current_Event_Active
local teleport_player = server_storage.Bindables.Teleport_Player

local globals = require(replicated_storage.Client_Accessible_Modules.Global_Replacements)

local event_badge_ids = {
	["Blox City"] = 2127252077,
	["Paradise Island"] = 2127252073,
}

local function kill_player(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if player and not character_debounce_list[character] and running then
		character_debounce_list[character] = true
		fade:FireClient(player)
		task.wait(0.5)
		local humanoid_root_part = character.HumanoidRootPart
		humanoid_root_part.CFrame = hit_checkpoints[humanoid_root_part] or spawn_cframe
		task.wait(0.5)
		character_debounce_list[character] = nil
	end
end

local function initialize_obby(obby, prize)
	local self = {}
	local connections = {}
	local tweens = {}

	local award_part = obby.AwardPart
	local tween_info = TweenInfo.new(2)
	local checkpoints = obby:FindFirstChild "Checkpoints"

	character_debounce_list = {}
	hit_checkpoints = {}
	spawn_cframe = CFrame.new(obby.ObbySpawn.Position + Vector3.new(0, 7, 0))

	self.stop = function()
		running = false
		for i = #connections, 1, -1 do
			connections[i]:Disconnect()
			connections[i] = nil
		end
		for i = #tweens, 1, -1 do
			tweens[i]:Destroy()
			tweens[i] = nil
		end
	end

	self.start = function()
		running = true

		table.insert(
			connections,
			award_part.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = players:GetPlayerFromCharacter(character)
				if player and not character_debounce_list[character] then
					character_debounce_list[character] = true
					local completed_event = replicated_storage[character.Name].Completed_Event

					if not completed_event.Value then
						completed_event.Value = true
						general_functions.Give_Cash(player, prize, true)
						alert:FireClient(
							player,
							"Reward",
							"Congratulations! You've been awarded "
								.. prize
								.. " cash for completing the "
								.. obby.Parent.Name
								.. " event! You can do the obby again, but you can not be awarded again during this island visit."
						)
						task.spawn(function()
							if
								not badge_service:UserHasBadgeAsync(player.UserId, event_badge_ids[obby.Parent.Name])
							then
								badge_service:AwardBadge(player.UserId, event_badge_ids[obby.Parent.Name])
							end
						end)
					end
					local humanoid_root_part = character:FindFirstChild "HumanoidRootPart"
					if humanoid_root_part then
						hit_checkpoints[humanoid_root_part] = nil
					end
					teleport_player:Fire(player)
					task.wait(1)
					character_debounce_list[character] = nil
				end
			end)
		)

		for _, obj in ipairs(obby:GetDescendants()) do
			local intermittent_time = obj:FindFirstChild "IntermittentTime"

			if intermittent_time then
				local particle_emitter = obj:FindFirstChildWhichIsA "ParticleEmitter"
				table.insert(
					connections,
					obj.Touched:Connect(function(hit)
						if particle_emitter.Enabled then
							kill_player(hit)
						end
					end)
				)
				task.spawn(function()
					while current_event_active.Value do
						task.wait(intermittent_time.Value)
						particle_emitter.Enabled = not particle_emitter.Enabled
					end
				end)
			elseif obj.Name == "Death" then
				table.insert(connections, obj.Touched:Connect(kill_player))
			end

			local start_pos, end_pos = obj:FindFirstChild "StartPosition", obj:FindFirstChild "EndPosition"
			if start_pos and end_pos then
				local tween_time = obj:FindFirstChild "TweenTime"
				local tween_info = tween_time and TweenInfo.new(tween_time.Value) or tween_info

				local toward_end_tween = tween_service:Create(obj, tween_info, { Position = end_pos.Value })
				local toward_start_tween = tween_service:Create(obj, tween_info, { Position = start_pos.Value })

				table.insert(tweens, toward_end_tween)
				table.insert(tweens, toward_start_tween)

				toward_end_tween.Completed:Connect(function()
					toward_start_tween:Play()
				end)
				toward_start_tween.Completed:Connect(function()
					toward_end_tween:Play()
				end)

				toward_end_tween:Play()
			end

			local boulder_start = obj:FindFirstChild "Boulder_Start"
			if boulder_start then
				task.spawn(function()
					local boulder_start = boulder_start.Value
					local death_time = obj.Death_Time.Value
					local spawn_time = obj.Spawn_Time.Value
					local function update_boulder(old_boulder)
						local parent = old_boulder.Parent
						local new_boulder = old_boulder:Clone()
						old_boulder:Destroy()
						task.wait(spawn_time)
						new_boulder.Position = boulder_start
						new_boulder.Parent = parent
						if new_boulder.Name == "Death" then
							new_boulder.Touched:Connect(kill_player)
						end
						task.wait(death_time)
						if running then
							update_boulder(new_boulder)
						end
					end
					update_boulder(obj)
				end)
			end
		end
	end

	if checkpoints then
		for _, checkpoint in ipairs(checkpoints:GetChildren()) do
			local checkpoint_cframe = CFrame.new(checkpoint.Position)
			checkpoint.Touched:Connect(function(hit)
				local character = hit.Parent
				if character and players:GetPlayerFromCharacter(character) then
					local humanoid_root_part = character.HumanoidRootPart
					hit_checkpoints[humanoid_root_part] = checkpoint_cframe
				end
			end)
		end
	end

	return self
end

return initialize_obby
