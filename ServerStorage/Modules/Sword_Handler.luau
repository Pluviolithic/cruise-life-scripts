--[[ Services ]]--

local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local run_service = game:GetService("RunService")
local server_storage = game:GetService("ServerStorage")
local badge_service = game:GetService("BadgeService")

--[[ Variables ]]--

local damage_values = {
	["Base_Damage"] = 5;
	["Slash_Damage"] = 10;
	["Lunge_Damage"] = 30;
}

local olde_town_event_badge_id = 2127252080
local samurai_event_badge_id = 2148716516

-- for r15 avatars, apparently

local grip_cframes = {
	["Up"] = CFrame.new(0, 0, -1.70000005, 0, 0, 1, 1, 0, 0, 0, 1, 0);
	["Out"] = CFrame.new(0, 0, -1.70000005, 0, 1, 0, 1, -0, 0, 0, 0, -1);
}

local developers = {
	["493434533"] = true;
	["45834633"] = true;
	["110103520"] = true;
	["25892359"] = true;
}

local contributors = {
	["128520906"] = true;
	["1232551441"] = true;
	["1765180356"] = true;
	["71446942"] = true;
	["212301624"] = true;
	["212735122"] = true;
	["99422452"] = true;
	["249425831"] = true;
}

for _, obj in ipairs(script:GetChildren()) do
	if obj:IsA("Sound") then
		obj:Destroy()
	end
end

local slash_sound = Instance.new("Sound")
slash_sound.SoundId = "http://www.roblox.com/asset/?id=12222216"
slash_sound.Name = "SwordSlash"
slash_sound.Parent = script
local lunge_sound = Instance.new("Sound")
lunge_sound.SoundId = "http://www.roblox.com/asset/?id=12222208"
lunge_sound.Name = "SwordLunge"
lunge_sound.Parent = script
local unsheath_sound = Instance.new("Sound")
unsheath_sound.Name = "Unsheath"
unsheath_sound.SoundId = "http://www.roblox.com/asset/?id=12222225"
unsheath_sound.Parent = script

local sounds = {
	["Slash"] = slash_sound;
	["Lunge"] = lunge_sound;
	["Unsheath"] = unsheath_sound;
}

local humanoid_rig_type = Enum.HumanoidRigType
local r6_rig_type = humanoid_rig_type.R6
local r15_rig_type = humanoid_rig_type.R15

local modules = server_storage.Modules
local general_functions = require(modules.General_Functions)

local remotes = replicated_storage.Remotes
local alert = remotes.Alert

local bindables = server_storage.Bindables
local player_left = bindables.Player_Left
local teleport_player = bindables.Teleport_Player

local miscellaneous = replicated_storage.Miscellaneous
local current_event_active = miscellaneous.Current_Event_Active

local green_color = Color3.fromRGB(85, 170, 0)
local red_color = Color3.fromRGB(170, 0, 0)

local globals = require(replicated_storage.Client_Accessible_Modules.Global_Replacements)

local function handle_sword(player, sword)
	
	for _, sound in pairs(sounds) do
		sound:Clone().Parent = sword.Handle
	end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character.Humanoid
	local head = character.Head
	local health = player.Health
	local damage_to_deal = 0
	local last_wait = 0
	
	local player_info_display_ui = head:FindFirstChild("Display_Gui")
	
	if not player_info_display_ui then
		player_info_display_ui = replicated_storage.Display_Gui:Clone()
		local display_gui_frame = player_info_display_ui.Frame
		local player_team = player.Team

		local bio = display_gui_frame.Player_Display_Bio
		local name = display_gui_frame.Player_Display_Name
		local team = display_gui_frame.Player_Team
		local player_id = tostring(player.UserId)

		bio.Text = replicated_storage[player.Name].Role_Play_Bio.Value
		name.Text = replicated_storage[player.Name].Role_Play_Name.Value

		if developers[player_id] then
			team.Text = "Developer"
			team.TextColor3 = Color3.fromRGB(255, 0, 0)
		elseif contributors[player_id] then
			team.Text = "Contributor"
			team.TextColor3 = Color3.fromRGB(75, 151, 75)
		else
			team.Text = player.Team.Name
			team.TextColor3 = player_team.TeamColor.Color
		end

		if team.Text == "Passenger" then
			team.TextTransparency = 1
			team.TextStrokeTransparency = 1
		end

		player_info_display_ui.Parent = head
	end
	
	local player_info_display_frame = player_info_display_ui.Frame
	local health_background = player_info_display_frame.Background
	local health_bar = player_info_display_frame.Health
	
	local player_data_folder = replicated_storage[player.Name]
	local kills = player_data_folder.Kills
	local is_in_arena = player_data_folder.Is_In_Arena
	
	local handle = sword.Handle
	local sounds = {
		["Slash"] = sword.Handle.SwordSlash;
		["Lunge"] = sword.Handle.SwordLunge;
		["Unsheath"] = sword.Handle.Unsheath;
	}
	
	local slash_animation_id, lunge_animation_id
	
	if humanoid.RigType == r6_rig_type then
		slash_animation_id, lunge_animation_id = "rbxassetid://522635514", "rbxassetid://522638767"
	elseif humanoid.RigType == r15_rig_type then
		slash_animation_id, lunge_animation_id = "rbxassetid://522635514", "rbxassetid://522638767"
	end
	
	local slash_animation = Instance.new("Animation")
	slash_animation.Name = "Slash"
	slash_animation.AnimationId = slash_animation_id
	slash_animation.Parent = sword
	
	local lunge_animation = Instance.new("Animation")
	lunge_animation.Name = "Lunge"
	lunge_animation.AnimationId = lunge_animation_id
	lunge_animation.Parent = sword
	
	local loaded_slash_animation = humanoid:LoadAnimation(slash_animation)
	local loaded_lunge_animation = humanoid:LoadAnimation(lunge_animation)
	
	sword.Grip = grip_cframes.Up

	health_bar.Size = UDim2.new(health.Value*0.287/100, 0, health_bar.Size.Y.Scale, 0)
	health_background.Visible = true
	health_bar.Visible = true
	
	health:GetPropertyChangedSignal("Value"):Connect(function()
		health_bar.Size = UDim2.new(health.Value*0.287/100, 0, health_bar.Size.Y.Scale, 0)
		health_bar.ImageColor3 = red_color:Lerp(green_color, health.Value/100)
		if health.Value <= 0 and not player_data_folder.Teleporting.Value then
			teleport_player:Fire(player, true)
			health_bar.Visible = false
			health_background.Visible = false
			is_in_arena.Value = false
			task.wait(2)
			health.Value = 100
		end
	end)
	
	sword.Activated:Connect(function()
		if sword.Enabled and health.Value > 0 then
			sword.Enabled = false
			
			local this_wait = run_service.Stepped:Wait()
			
			if this_wait - last_wait < 0.2 then
				damage_to_deal = damage_values.Lunge_Damage
				sounds.Lunge:Play()
				loaded_lunge_animation:Play(0)
				task.wait(0.2)
				sword.Grip = grip_cframes.Out
				task.wait(0.6)
				sword.Grip = grip_cframes.Up
				damage_to_deal = damage_values.Slash_Damage
			else
				damage_to_deal = damage_values.Slash_Damage
				sounds.Slash:Play()
				loaded_slash_animation:Play(0)
			end
			
			last_wait = this_wait
			damage_to_deal = damage_values.Base_Damage
			sword.Enabled = true
			
		end
	end)
	
	sword.Equipped:Connect(function()
		sounds.Unsheath:Play()
	end)
	
	sword.Unequipped:Connect(function()
		sword.Grip = grip_cframes.Up
	end)
	
	local player_debounces = {}
	
	handle.Touched:Connect(function(hit)
		
		local other_player = players:GetPlayerFromCharacter(hit.Parent)
		
		if other_player and other_player ~= player then
		
			if not player_debounces[other_player] then
				local kill_delay
				player_debounces[other_player] = true
				local other_player_health = other_player.Health
				local other_player_data_folder = replicated_storage:FindFirstChild(other_player.Name)
				if other_player_data_folder and other_player_data_folder.Is_In_Arena.Value and other_player_health.Value > 0 and not other_player_data_folder.Teleporting.Value then
					if other_player_health.Value - damage_to_deal <= 0 then
						kill_delay = 1
						other_player_health.Value = 0
						kills.Value += 1
					else
						other_player_health.Value -= damage_to_deal
					end
				end
				task.wait(kill_delay)
				player_debounces[other_player] = nil
			end
		end
		
	end)
	
	local connection_a, connection_b, connection_c, connection_d, connection_e
	
	connection_a = humanoid.Died:Connect(function()
		sword:Destroy()
		connection_a:Disconnect()
		connection_e:Disconnect()
		connection_b:Disconnect()
	end)
	
	connection_c = is_in_arena:GetPropertyChangedSignal("Value"):Connect(function()
		if not is_in_arena.Value then
			health_bar.Visible = false
			health_background.Visible = false
			sword:Destroy()
			connection_c:Disconnect()
			connection_e:Disconnect()
		end
	end)
	
	connection_b = player_left.Event:Connect(function(leaving_player)
		if leaving_player == player then
			sword:Destroy()
			connection_b:Disconnect()
			connection_c:Disconnect()
		end
	end)
	
	connection_e = kills:GetPropertyChangedSignal("Value"):Connect(function()
		if kills.Value == 4 then
			local prize = 250
			if workspace:FindFirstChild("Olde Town") then
				alert:FireClient(player, "Reward", "Congratulations! You've been awarded "..prize.." cash for completing the Olde Town event! You can go back and fight, but you can not be awarded again during this island visit.")
			else
				alert:FireClient(player, "Reward", "Congratulations! You've been awarded "..prize.." cash for completing the Samurai Island event! You can go back and fight, but you can not be awarded again during this island visit.")
			end
			general_functions.Give_Cash(player, prize, true)
			teleport_player:Fire(player, true)
			connection_e:Disconnect()
			if workspace:FindFirstChild("Samurai Island") then
				if not badge_service:UserHasBadgeAsync(player.UserId, samurai_event_badge_id) then
					badge_service:AwardBadge(player.UserId, samurai_event_badge_id)
				end
			else
				if not badge_service:UserHasBadgeAsync(player.UserId, olde_town_event_badge_id) then
					badge_service:AwardBadge(player.UserId, olde_town_event_badge_id)
				end
			end
		end
	end)
	
	connection_d = current_event_active:GetPropertyChangedSignal("Value"):Connect(function()	
		health_bar.Visible = false
		health_background.Visible = false
		sword:Destroy()
		connection_c:Disconnect()
		connection_d:Disconnect()
		connection_e:Disconnect()	
	end)
	
end

return handle_sword

