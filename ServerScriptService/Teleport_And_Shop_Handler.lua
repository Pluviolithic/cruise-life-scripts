--[[
By Eric/AetherProgrammer.
--]]

--[[ Services ]]--

local server_storage = game:GetService("ServerStorage")
local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local run_service = game:GetService("RunService")

--[[ Variables ]]--

local current_island_name = replicated_storage.Miscellaneous.Current_Island_Name
local globals = require(replicated_storage.Client_Accessible_Modules.Global_Replacements)

local remotes = replicated_storage.Remotes
local fade = remotes.Fade
local get_shop_areas = remotes.Get_Shop_Areas
local elevator_request = remotes.Elevator_Request
local ran_obj = Random.new()
local teleport_receivers = {}
local y_increase_vector = Vector3.new(0, 1, 0)
local up_vector = Vector3.new(0, 1, 0)
local teleport_offset = Vector3.new(0, 7, 0)
local areas = {}
local character_debounce_list = {}

local ship = workspace.Ship

--[[ Functions ]]--

local function update_events(island)

	for _, obj in ipairs(island:GetDescendants()) do
		local obj_name = obj.Name:lower()

		if obj_name:match("tp%d+%a") or obj_name:match("tp%d+%b") then
			local obj_cframe = obj.CFrame
			local look_vector = obj_cframe.LookVector
			local right_vector = look_vector:Cross(up_vector)

			teleport_receivers[obj_name] = CFrame.fromMatrix(obj_cframe.Position + look_vector*5 + y_increase_vector, right_vector, up_vector)

			local receiver_name = obj_name:sub(1, -2)..(obj_name:match("a") and "b" or "a")

			if not obj:FindFirstChildWhichIsA("BoolValue") then
				obj.Touched:Connect(function(hit)
					local character = hit.Parent
					local humanoid_root_part = character and character:FindFirstChild("HumanoidRootPart")
					local player = players:GetPlayerFromCharacter(character)
					if humanoid_root_part and player then
						local humanoid = character:WaitForChild("Humanoid")
						if not character_debounce_list[character] and humanoid then
							character_debounce_list[character] = true
							fade:FireClient(player)
							task.wait(0.5)
							local seat = humanoid.SeatPart
							if seat then
								local weld = seat:FindFirstChild("SeatWeld")
								if weld then
									weld:Destroy()
								end
								seat.Disabled = true
								task.delay(3, function()
									seat.Disabled = false
								end)
							end
							humanoid_root_part.CFrame = teleport_receivers[receiver_name]
							task.wait(1.5)
							character_debounce_list[character] = nil
						end
					end
				end)
			end
		end
	end
end

local int = 0
local function handle_shops(shops, island_name)
	for _, obj in ipairs(shops) do
		if obj:IsA("BasePart") then
			int += 1
			areas[obj.Name..int..island_name] = obj.Position
		end
	end
end

update_events(workspace)
current_island_name:GetPropertyChangedSignal("Value"):Connect(function()
	if current_island_name.Value ~= "" then
		update_events(workspace:WaitForChild(current_island_name.Value))
	end
end)

handle_shops(ship.SouvenirShop:GetDescendants(), ship.Name)
handle_shops(ship.FoodShops:GetDescendants(), ship.Name)
handle_shops(ship.PrizeShop:GetDescendants(), ship.Name)
for _, island in ipairs(server_storage.Islands:GetChildren()) do
	handle_shops(island.SouvenirShop:GetDescendants(), island.Name)
	handle_shops(island.FoodShops:GetDescendants(), island.Name)
	handle_shops(island["Vehicle Shop Cashier"]:GetDescendants(), island.Name)
end

local elevator_doors = {}

for _, obj in ipairs(workspace.Elevators:GetChildren()) do
	local floor_name = obj.Name:gsub("Elevator", "")
	local cframe = obj.CFrame
	local look_vector = cframe.LookVector
	local right_vector = look_vector:Cross(up_vector)
	local teleport_cframe = CFrame.fromMatrix(cframe.Position + look_vector*5 + y_increase_vector, right_vector, up_vector)
	if #floor_name > 3 then
		if elevator_doors[floor_name] then
			table.insert(elevator_doors[floor_name], teleport_cframe)
		else
			elevator_doors[floor_name] = {teleport_cframe}
		end
	end
	obj.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid_root_part = character and character:FindFirstChild("HumanoidRootPart")
		local player = players:GetPlayerFromCharacter(character)
		if player and humanoid_root_part then
			if not character_debounce_list[character] then
				character_debounce_list[character] = true
				elevator_request:FireClient(player)
				task.wait(2)
				character_debounce_list[character] = nil
			end
		end
	end)
end

get_shop_areas.OnServerInvoke = function()
	return areas
end

elevator_request.OnServerEvent:Connect(function(player, floor_name)
	local valid_doors = elevator_doors[floor_name]
	if valid_doors then
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:WaitForChild("Humanoid")
		if humanoid_root_part and humanoid then
			fade:FireClient(player)
			task.wait(0.5)
			local seat = humanoid.SeatPart
			if seat then
				local weld = seat:FindFirstChild("SeatWeld")
				if weld then
					weld:Destroy()
				end
				seat.Disabled = true
				task.delay(3, function()
					seat.Disabled = false
				end)
			end
			humanoid_root_part.CFrame = valid_doors[ran_obj:NextInteger(1, #valid_doors)]
		end
	end
end)


local tools = {
	["Blox City"] = server_storage.CityRod;
	["Paradise Island"] = server_storage.TropicalRod;
	["Olde Town"] = server_storage.MedievalRod;
	["Samurai Island"] = server_storage.SamuraiRod;
}

local fish_list = {
	{
		Reward = 20;
		Rarity = .4;
		Name = "Trash";
	},
	{
		Reward = 150;
		Rarity = .3;
		Name = "Common";
	},
	{
		Reward = 400;
		Rarity = .2;
		Name = "Uncommon";
	},
	{
		Reward = 800;
		Rarity = .09;
		Name = "Rare";
	},
	{
		Reward = 1200;
		Rarity = .01;
		Name = "Legendary"
	},
}

local pads = {}

players.PlayerRemoving:Connect(function(player)
	pads[player] = nil
end)

remotes.Fish_Request.OnServerEvent:Connect(function(player)
	local player_data_folder = replicated_storage[player.Name]
	local island = workspace:FindFirstChild(current_island_name.Value)
	if not island or player_data_folder.Bait.Value < 1 then return end
	player_data_folder.Bait.Value -= 1
	
	if player_data_folder.Bait.Value == 0 then
		player_data_folder.Last_Hit_Bait_Zero.Value = DateTime.now().UnixTimestamp
	end
	
	for _, pad in ipairs(island.FishingSpots:GetChildren()) do
		if not pad.Full.Value then
			local character = player.Character
			local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:WaitForChild("Humanoid")
			if humanoid_root_part and humanoid then
				pad.Full.Value = true
				pads[player] = pad
				fade:FireClient(player)
				task.wait(0.5)
				local seat = humanoid.SeatPart
				if seat then
					local weld = seat:FindFirstChild("SeatWeld")
					if weld then
						weld:Destroy()
					end
					seat.Disabled = true
					task.delay(3, function()
						seat.Disabled = false
					end)
				end
				humanoid_root_part.CFrame = pad.CFrame + Vector3.new(0, 5, 0)
				
				local rod = tools[current_island_name.Value]:Clone()
				rod.Parent = player.Backpack
				humanoid:EquipTool(rod)
				rod.Unequipped:Connect(function()
					task.wait()

					humanoid:EquipTool(rod)
				end)
				
			end
			break
		end
	end
end)

remotes.Fished.OnServerInvoke = function(player, success)
	local player_data_folder = replicated_storage[player.Name]
	local character = player.Character
	local humanoid = character.Humanoid
	local rod = character:FindFirstChild("TropicalRod") or character:FindFirstChild("MedievalRod") or character:FindFirstChild("CityRod") or character:FindFirstChild("SamuraiRod")
	if not success then
		task.wait()
		humanoid:UnequipTools()
		rod:Destroy()
		pads[player].Full.Value = false
		return
	end

	local random_chance = ran_obj:NextInteger(0, 100)/100
	local cumulative_chance = 0
	local winnings, winning_type

	for _, fish_type in ipairs(fish_list) do
		local odds = fish_type.Rarity
		cumulative_chance +=  odds
		if random_chance <= cumulative_chance then
			winnings = fish_type.Reward
			winning_type = fish_type.Name
			break
		end
	end
	
	if not winnings then
		winnings = 20
		winning_type = "Trash"
	end

	player_data_folder.Cash.Value += winnings
	task.wait()
	humanoid:UnequipTools()
	rod:Destroy()
	pads[player].Full.Value = false

	return winning_type, winnings

end
