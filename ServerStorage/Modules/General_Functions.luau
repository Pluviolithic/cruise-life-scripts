--[[
	By Eric/AetherProgrammer.
--]]

--[[ Services ]]--

local team_service = game:GetService("Teams")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_storage = game:GetService("ServerStorage")

--[[ Variables ]]--

local teams = {
	["Captain"] = team_service.Captain;
	["Passenger"] = team_service.Passenger;
}

local load_character = server_storage.Bindables.Load_Character 

local general_functions = {}

general_functions.Remove_Player_From_Team = function(player)
	local team = player.Team
	if team then
		player.Team = nil
	end
end

general_functions.Add_Player_To_Team = function(player, team_name)
	local new_team = teams[team_name]
	if new_team and player.Team ~= new_team then
		general_functions.Remove_Player_From_Team(player)
		player.Team = teams[team_name]
	end
end

general_functions.Give_Cash = function(player, amount, event_reward)
	local player_data_folder = replicated_storage:WaitForChild(player.Name, 3)
	if player_data_folder then
		local cash = player_data_folder.Cash
		cash.Value += amount
        if event_reward and player_data_folder.Has_VIP_Pass.Value then
            cash.Value += amount
        end
	end
end

return general_functions

