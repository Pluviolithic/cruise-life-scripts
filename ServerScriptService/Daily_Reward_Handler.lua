--[[
	By Eric/AetherProgrammer.
--]]

--[[ Services ]]--

local replicated_storage = game:GetService("ReplicatedStorage")
local server_storage = game:GetService("ServerStorage")

--[[ Variables]]--

local reward_data = require(replicated_storage.Client_Accessible_Modules.Reward_Data)
local remotes = replicated_storage.Remotes
local spin = remotes.Spin
local number_of_crates_min = 35
local number_of_crates_max = 45
local ran_obj = Random.new()
local general_functions = require(server_storage.Modules.General_Functions)

--[[ Event Listeners ]]--

spin.OnServerInvoke = function(player)
	
	local player_data_folder = replicated_storage[player.Name]
	local souvenirs = player_data_folder.Souvenirs
	local spins = player_data_folder.Spins

	if spins.Value > 0 then
		
		spins.Value -=  1
		local items = {}
		local number_of_crates = ran_obj:NextInteger(number_of_crates_min, number_of_crates_max)
		
		for i = 1, number_of_crates do
			
			local cumulative_chance = 0
			local rarity_type
			local random_chance = ran_obj:NextInteger(0, 100)/100
			
			for i = 1, #reward_data do
				local group = reward_data[i]
				local odds = group.Rarity.Odds
				cumulative_chance +=  odds
				if random_chance <= cumulative_chance then
					rarity_type = group
					break
				end
			end
			if not rarity_type then
				rarity_type = reward_data[1]
			end
			local new_rewards_group = rarity_type.Rewards
			local new_item = new_rewards_group[ran_obj:NextInteger(1, #new_rewards_group)]
			table.insert(items, new_item)
		end
		
		local winner_index = number_of_crates - 7
		local winner_item = items[winner_index]
		local was_duplicate = false
		
		if type(winner_item.Value) ~= "number" then
			if souvenirs:FindFirstChild(winner_item.Value.Name) then
				local rarity_group = reward_data[winner_item.Group_Index]
				was_duplicate = true
				general_functions.Give_Cash(player, rarity_group.Rarity.Duplicate_Value)
			else
				winner_item.Value:Clone().Parent = souvenirs
			end
		else
			general_functions.Give_Cash(player, winner_item.Value)
		end
		
		return {
			["Items"] = items;
			["Winner_Index"] = winner_index;
			["Was_Duplicate"] = was_duplicate;
		}
		
	end
end
