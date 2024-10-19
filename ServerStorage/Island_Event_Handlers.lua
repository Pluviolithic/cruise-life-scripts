--[[
	By Eric/AetherProgrammer.
--]]

--[[ Services ]]--

local tween_service = game:GetService("TweenService")
local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local server_storage = game:GetService("ServerStorage")
local lighting_service = game:GetService("Lighting")
local run_service = game:GetService("RunService")

--[[ Variables ]]--

local modules = server_storage.Modules
local sword_handler = require(modules.Sword_Handler)
local general_functions = require(modules.General_Functions)
local obby_handler = require(modules.Obby_Handler)

local miscellaneous = replicated_storage.Miscellaneous
local sword = miscellaneous.Sword
local katana = miscellaneous.Katana
local current_event_active = miscellaneous.Current_Event_Active
local remotes = replicated_storage.Remotes
local alert = remotes.Alert
local fade = remotes.Fade

local islands = server_storage.Islands
local olde_town_model = islands["Olde Town"]
local samurai_island_model = islands["Samurai Island"]
local arena_floor = olde_town_model.ArenaFloor
local samurai_arena_floor = samurai_island_model.ArenaFloor

local functions = {}
local area_dimensions = {
	["Colosseum"] = arena_floor.Position;
	["SamuraiArena"] = samurai_arena_floor.Position;
}

local globals = require(replicated_storage.Client_Accessible_Modules.Global_Replacements)

local function is_in_area(pos, area_name)
	local dimensions = area_dimensions[area_name]
	if typeof(dimensions) == "Vector3" then
		if area_name == "SamuraiArena" then
			return (dimensions - pos).Magnitude <= 67.5
		else
			return (dimensions - pos).Magnitude <= 167.1
		end
	else
		local x, y, z = pos.X, pos.Y, pos.Z
		local x_a, x_b, y_a, y_b, z_a, z_b = dimensions.x_a, dimensions.x_b, dimensions.y_a, dimensions.y_b, dimensions.z_a, dimensions.z_b
		return x_a > x and x_b < x and y_a > y and y_b < y and z_a > z and z_b < z
	end
end

functions["Blox City"] = function()
	
	alert:FireAllClients("EventDesc", "The Blox City event has started! The mayor of Blox City wants you to test their new security system for their bank. Make it to the vault for an award!")
	
	local player_list = players:GetPlayers()
	local island = workspace["Blox City"]
	local bank_obby = island.BankObby
	local handler = obby_handler(bank_obby, 250)
	
	local bank_interior = island["Bank Interior"]
	local gate = bank_interior.Gate
	
	gate.Transparency = 1
	gate.CanCollide = false
	
	local lights = island:FindFirstChild("Lights")
	if lights then
		local connection; connection = lighting_service:GetPropertChangedSignal("ClockTime"):Connect(function()
			if lighting_service.ClockTime >= 17.7 then
				connection:Disconnect()
				for _, light in ipairs(lights:GetDescendants()) do
					if light:IsA("Light") then
						light.Enabled = true
					end
				end
			end
		end)
	end
	
	for i = 1, #player_list do
		local player = player_list[i]
		local player_data_folder = replicated_storage:FindFirstChild(player.Name)
		if player_data_folder then
			player_data_folder.Completed_Event.Value = false
		end
	end	
	
	handler.start()
	current_event_active:GetPropertyChangedSignal("Value"):Wait()
	gate.Transparency = 0
	gate.CanCollide = true
	handler.stop()
	
end

functions["Olde Town"] = function()
	
	alert:FireAllClients("EventDesc", "The Olde Town event has started! Head to the colosseum to sword fight other players! You must Knockout 4 players for an award.")
	
	local player_list = players:GetPlayers()
	for i = 1, #player_list do
		local player = player_list[1]
		local player_data_folder = replicated_storage:FindFirstChild(player.Name)
		if player_data_folder then
			player_data_folder.Kills.Value = 0
			player.Health.Value = 100
		end
	end

	local island = workspace["Olde Town"]
	local lights = island:FindFirstChild("Lights")
	if lights then
		local connection; connection = lighting_service:GetPropertChangedSignal("ClockTime"):Connect(function()
			if lighting_service.ClockTime >= 17.7 then
				for _, light in ipairs(lights:GetDescendants()) do
					if light:IsA("Light") then
						light.Enabled = true
					end
				end
				connection:Disconnect()
			end
		end)
	end
	
	while current_event_active.Value do

		for i = 1, #player_list do
			
			local player = player_list[i]
			local player_data_folder = replicated_storage:FindFirstChild(player.Name)
			local character = player.Character
			local humanoid_root_part = character and character:FindFirstChild("HumanoidRootPart") or nil
			
			if player_data_folder then
				local is_in_arena = player_data_folder.Is_In_Arena
				if character and humanoid_root_part then
					if is_in_area(humanoid_root_part.Position, "Colosseum") then
						if not is_in_arena.Value then
							local new_sword = sword:Clone()
							new_sword.Parent = player.Backpack
							task.spawn(function()
								sword_handler(player, new_sword)
							end)
						end
						is_in_arena.Value = true
					else
						is_in_arena.Value = false
					end
				else
					is_in_arena.Value = false
				end
			end
			
		end
		
		task.wait(1)
		player_list = players:GetPlayers()
	end
	
end

functions["Samurai Island"] = function()

	alert:FireAllClients("EventDesc", "The Samurai Island event has started! Head to the Samurai Arena to sword fight other players! You must Knockout 4 players for an award.")
	local player_list = players:GetPlayers()
	for i = 1, #player_list do
		local player = player_list[1]
		local player_data_folder = replicated_storage:FindFirstChild(player.Name)
		if player_data_folder then
			player_data_folder.Kills.Value = 0
			player.Health.Value = 100
		end
	end

	local island = workspace["Samurai Island"]
	local lights = island:FindFirstChild("Lights")
	if lights then
		local connection; connection = lighting_service:GetPropertChangedSignal("ClockTime"):Connect(function()
			if lighting_service.ClockTime >= 17.7 then
				for _, light in ipairs(lights:GetDescendants()) do
					if light:IsA("Light") then
						light.Enabled = true
					end
				end
				connection:Disconnect()
			end
		end)
	end

	while current_event_active.Value do

		for i = 1, #player_list do

			local player = player_list[i]
			local player_data_folder = replicated_storage:FindFirstChild(player.Name)
			local character = player.Character
			local humanoid_root_part = character and character:FindFirstChild("HumanoidRootPart") or nil

			if player_data_folder then
				local is_in_arena = player_data_folder.Is_In_Arena
				if character and humanoid_root_part then
					if is_in_area(humanoid_root_part.Position, "SamuraiArena") then
						if not is_in_arena.Value then
							local new_sword = katana:Clone()
							new_sword.Parent = player.Backpack
							task.spawn(function()
								sword_handler(player, new_sword)
							end)
						end
						is_in_arena.Value = true
					else
						is_in_arena.Value = false
					end
				else
					is_in_arena.Value = false
				end
			end

		end

		task.wait(1)
		player_list = players:GetPlayers()
	end

end

functions["Paradise Island"] = function()
	alert:FireAllClients("EventDesc", "The Paradise Island event has started! Make it to the end of the tomb for a reward! Watch out for traps!")
	local island = workspace["Paradise Island"]
	local tomb_obby = island.Tomb
	local gate = tomb_obby.Gate
	local handler = obby_handler(tomb_obby, 250)
	gate.CanCollide = false
	for _, player in ipairs(players:GetPlayers()) do
		local player_data_folder = replicated_storage:FindFirstChild(player.Name)
		if player_data_folder then
			player_data_folder.Completed_Event.Value = false
		end
	end
	handler.start()
	current_event_active:GetPropertyChangedSignal("Value"):Wait()
	handler.stop()
	gate.CanCollide = true
end

return functions

