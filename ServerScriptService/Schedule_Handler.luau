--[[ Services ]]--

local LIGHTING_SERVICE = game:GetService("Lighting")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local SERVER_STORAGE = game:GetService("ServerStorage")
local PLAYERS = game:GetService("Players")
local BADGE_SERVICE = game:GetService("BadgeService")
local MARKETPLACE_SERVICE = game:GetService("MarketplaceService")

--[[ Variables ]]--

local DEFAULT_WAIT_TIME = 128/60 --/40
local SPEED_WAIT_TIME = 37/60 --/40

local SLEEP_TIME = "00:00:00"
local CAFETERIA_TIME = "07:00:00"
local WARNING_TIME = "08:59:00"
local ARRIVAL_TIME = "09:00:00"
local SHIP_ACTIVITY_ONE_TIME = "10:00:00"
local DOCKS_TIME = "10:00:00"
local ACTIVITY_TIME = "12:00:00"
local LUNCH_TIME = "13:00:00"
local ISLAND_LUNCH_TIME = "14:00:00"
local SHIP_ACTIVITY_TWO_TIME = "15:00:00"
local EVENT_TIME = "17:00:00"
local SHIP_DINNER_TIME = "18:00:00"
local MOVIE_TIME = "20:00:00"
local ISLAND_DINNER_TIME = "20:00:00"
local CLUB_TIME = "22:00:00"
local RETURN_TIME = "23:00:00"

local MISCELLANEOUS = REPLICATED_STORAGE.Miscellaneous
local CLIENT_ACCESSIBLE_MODULES = REPLICATED_STORAGE.Client_Accessible_Modules

local current_event_active = MISCELLANEOUS.Current_Event_Active
local current_day = MISCELLANEOUS.Day
local current_island_name = MISCELLANEOUS.Current_Island_Name
local current_teleport_location = MISCELLANEOUS.Teleport_Location
local current_message = MISCELLANEOUS.Current_Message
local current_day_number = 0
local current_island

local island_handler = require(SERVER_STORAGE.Modules.Island_Event_Handlers)
local globals = require(CLIENT_ACCESSIBLE_MODULES.Global_Replacements)
local queues = require(CLIENT_ACCESSIBLE_MODULES.Queues)

local teleport_player = SERVER_STORAGE.Bindables.Teleport_Player

local docking_doors = workspace.DockingDoors:GetDescendants()
--local wake_model = workspace.Wake
local extra_vehicles = workspace.Extra_Vehicles

local remotes = REPLICATED_STORAGE.Remotes
local alert = remotes.Alert
local start_movie = remotes.Start_Movie
local drop_queue_size = remotes.Drop_Queue_Size

local rand_obj = Random.new()
local islands = SERVER_STORAGE.Islands

-- teleport spots

local CAFETERIA = workspace.CafeteriaTP
local PARTY = workspace.PartyTP
local DINING = workspace.DiningTP
local POOL = workspace.PoolTP
local SHIP = workspace.ShipTP
local GYM = workspace.GymTP
local ARCADE = workspace.ArcadeTP
local TOP_DECK = workspace.TopDeckTP
local BACK_DECK = workspace.BackDeckTP

local days = {
	[0] = "Sunday";
	[1] = "Monday";
	[2] = "Tuesday";
	[3] = "Wednesday";
	[4] = "Thursday";
	[5] = "Friday";
	[6] = "Saturday";
}

local event_days = {
	["Monday"] = true;
	["Wednesday"] = true;
	["Friday"] = true;
}

local key_times = {}
local messages = {}

local island_alerts = {
	["Blox City"] = "We have reached the destination! Welcome to Blox City! Rent cars, explore the island, go to the beach, eat at the local restaurants, and more! The main event starts at 5s:00 PM!";
	["Olde Town"] = "We have reached the destination! Welcome to Olde Town! On this medieval island, you can rent a horse or a carriage, explore the island, eat at the local restaurants, and more! The main event starts at 5:00 PM!";
	["Paradise Island"] = "We have reached the destination! Welcome to Paradise Island! Rent cars, explore the island, relax at the hot springs, go camping at the lake, ride zip lines, eat at the local restaurant, and more! The main event starts at 5:00 PM!";
	["Samurai Island"] = "We have reached the destination! Welcome to Samurai Island! Rent cars, explore the island, relax at the hot springs, enjoy the scenery, eat at the local restaurant, and more! The main event starts at 5:00 PM!";
}

local island_activities = {
	["Blox City"] = workspace.BloxCityActivityTP;
	["Olde Town"] = workspace.OldeTownActivityTP;
	["Paradise Island"] = workspace.ParadiseIslandActivityTP;
	["Samurai Island"] = workspace.SamuraiIslandActivityTP;
}

local island_activity_messages = {
	["Blox City"] = "Head to the beach to relax or eat some food!";
	["Olde Town"] = "Head to the park to relax or eat some food!";
	["Paradise Island"] = "Head to the hot springs for a soak!";
	["Samurai Island"] = "Head to the hot springs for a soak!";
}

local area_dimensions = {
	["Ship"] = {
		x_a = 193.6;
		x_b = 436.9;
		y_a = 477.231;
		y_b = 708.031;
		z_a = 748.25;
		z_b = 1977.703;
	};
	["Captain_Room"] = {
		x_a = 2510.488;
		x_b = 2642.008;
		y_a = -425.093;
		y_b = -350.903;
		z_a = -1126.352;
		z_b = -944.133;
	};
	["Blox City"] = {
		x_a = -5666.75;
		x_b = -5313.45;
		y_a = -312.7;
		y_b = -259.55;
		z_a = -2872.8;
		z_b = -2366.099;		
	};
	["Paradise Island"] = {
		x_a = -4689.689;
		x_b = -4177.148;
		y_a = -325.055;
		y_b = -208.345;
		z_a = -2001.332;
		z_b = -1280.242;
	};
	["Olde Town"] = islands["Olde Town"].ArenaFloor.Position;
	["Samurai Island"] = islands["Samurai Island"].ArenaFloor.Position;
}

local island_names = {}

--[[ Functions ]]--

local function fisher_yates_shuffle(t)
	for n = #t, 1, -1 do
		local k = rand_obj:NextInteger(1, n)
		t[n], t[k] = t[k], t[n]
	end
	return t
end

local function is_in_area(pos, area_name)
	local dimensions = area_dimensions[area_name]
	if typeof(dimensions) == "Vector3" then
		if area_name == "Samurai Island" then
			return (dimensions - pos).Magnitude <= 107.5
		else
			return (dimensions - pos).Magnitude <= 242
		end
	else
		local x, y, z = pos.X, pos.Y, pos.Z
		local x_a, x_b, y_a, y_b, z_a, z_b = dimensions.x_a, dimensions.x_b, dimensions.y_a, dimensions.y_b, dimensions.z_a, dimensions.z_b
		return x_a <= x and x_b >= x and y_a <= y and y_b >= y and z_a <= z and z_b >= z
	end
end

local function switch_wake(on)
	--
	--if on then
	--	DEFAULT_WAIT_TIME = 128/60/40
	--	SPEED_WAIT_TIME = 37/60/40
	--else
	--	DEFAULT_WAIT_TIME = 128/60
	--	SPEED_WAIT_TIME = 37/60
	--end
	--[[
	for _, obj in ipairs(wake_model:GetDescendants()) do
		if obj:IsA("Beam") then
			obj.Enabled = on
		end
	end
	]]
end

local function disable_cars(container)
	for _, obj in pairs(container:GetDescendants()) do
		if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
			obj.Disabled = true
		end
	end
end

local function is_in_water(position)
	local x, y, z = position.X, position.Y, position.Z
	return (x >= -2866 and x <= 1472 and y >= 362 and y <= 460.3 and z >= -1187 and z <= 3723)
end

local function get_parking_spot(parking_spots)
	for _, spot in ipairs(parking_spots) do
		if spot.Name == "Unowned" then
			return spot
		end
	end
	local smallest_time, best_spot = math.huge, nil
	for _, spot in ipairs(parking_spots) do
		if spot.Spawn_Time.Value < smallest_time then
			smallest_time = spot.Spawn_Time.Value
			best_spot = spot
		end
	end
	return best_spot
end

local temp_island_names = {}
local last_island_name

local function spawn_island()
	local island_name = queues.Island_Queue:unqueue()
	if island_name then
		island_name = island_name[1]
		drop_queue_size:FireAllClients()
	else
		if 1 > #temp_island_names then
			temp_island_names = fisher_yates_shuffle({table.unpack(island_names)})
			if last_island_name == temp_island_names[#temp_island_names] then
				temp_island_names[1], temp_island_names[#temp_island_names] = temp_island_names[#temp_island_names], temp_island_names[1]
			end
		end
		island_name = table.remove(temp_island_names)
	end

	local island = islands:FindFirstChild(island_name)
	local island_copy = island:Clone()

	task.delay(5, function()
		for _, door in ipairs(docking_doors) do
			door.Transparency = 1
			if not door:IsA("BasePart") then continue end
			door.CanCollide = false
		end
		if island_name == "Paradise Island" then
			current_island.Zipline.Disabled = false
		end
	end)

	task.spawn(function()
		local debounce = true
		for _, obj in ipairs(island_copy:GetChildren()) do
			if obj.Name == "CarSpawner" then
				obj:FindFirstChildWhichIsA("ClickDetector", true).MouseClick:Connect(function(player)

					if not debounce then return end
					debounce = false

					local owned_parking_spot = REPLICATED_STORAGE[player.Name].Last_Parking_Spot.Value

					if owned_parking_spot then
						local old_vehicle = owned_parking_spot:FindFirstChildWhichIsA("Model") or extra_vehicles:FindFirstChild(player.Name)

						if not old_vehicle or old_vehicle.Name ~= player.Name then
							REPLICATED_STORAGE[player.Name].Last_Parking_Lot.Value = obj["Parking Lot"]
							REPLICATED_STORAGE[player.Name].Last_Parking_Spot.Value = nil
							remotes.RemoteSpawn:FireClient(player)

							task.wait(2)

							debounce = true
							return
						end

						local copy = old_vehicle:Clone()
						if old_vehicle then
							disable_cars(old_vehicle)
							task.delay(2, function()
								old_vehicle:Destroy()
							end)
						end

						local parking_spot = get_parking_spot(obj["Parking Lot"]:GetChildren())
						local previous_vehicle = parking_spot:FindFirstChildWhichIsA("Model")
						if previous_vehicle then
							previous_vehicle.Parent = extra_vehicles
						end

						local vehicle = copy
						local player_left = SERVER_STORAGE.Bindables.Player_Left
						local character = player.Character or player.CharacterAdded:Wait()
						local parking_spot_cframe = parking_spot.CFrame

						local spawn_cframe = CFrame.fromMatrix(
							parking_spot_cframe.Position + Vector3.new(0, 15, 0), 
							parking_spot_cframe.LookVector:Cross(Vector3.new(0, 1, 0)), 
							Vector3.new(0, 1, 0)
						)

						local driver_seat
						if vehicle:FindFirstChild("HorseHumanoid", true) then
							driver_seat = vehicle.Seat
						else
							driver_seat = vehicle.Chassis.VehicleSeat
						end

						-- find player's parking spot
						-- task.spawn in car
						parking_spot.Spawn_Time.Value = tick()
						vehicle:SetPrimaryPartCFrame(spawn_cframe)
						remotes.Fade:FireClient(player)
						parking_spot.Name = player.Name
						REPLICATED_STORAGE[player.Name].Last_Parking_Spot.Value = parking_spot
						vehicle.Parent = parking_spot
						task.wait(0.25)
						character:SetPrimaryPartCFrame(spawn_cframe)

						local connection; connection = player_left.Event:Connect(function(leaving_player)
							if leaving_player == player then
								connection:Disconnect()
								if vehicle.Parent == parking_spot then
									disable_cars(vehicle)
									task.delay(2, function()
										vehicle:Destroy()
									end)
									parking_spot.Name = "Unowned"
								end
							end	
						end)

						-- handle the owner/driver situation here

						driver_seat:GetPropertyChangedSignal("Occupant"):Connect(function()
							local occupant = driver_seat.Occupant
							if occupant and PLAYERS:GetPlayerFromCharacter(occupant.Parent) ~= player then
								while driver_seat.Occupant == occupant do
									occupant:TakeDamage(15)
									task.wait(0.25)
									local seat_weld = driver_seat:FindFirstChild("SeatWeld")
									if seat_weld then
										seat_weld:Destroy()
									end
									task.wait(0.75)
								end
							end
						end)
						task.spawn(function()
							while vehicle.Parent do
								if is_in_water(vehicle:GetPrimaryPartCFrame().Position) then
									disable_cars(vehicle)
									REPLICATED_STORAGE[vehicle.Name].Last_Parking_Spot.Value = nil
									task.delay(2, function()
										vehicle:Destroy()
									end)
									break
								end
								task.wait(1)
							end
						end)
					else
						remotes.RemoteSpawn:FireClient(player)
					end

					REPLICATED_STORAGE[player.Name].Last_Parking_Lot.Value = obj["Parking Lot"]

					task.wait(2)

					debounce = true

				end)
			end
		end
	end)
	
	local fishing_debounce = {}
	island_copy.FishingHitbox.Touched:Connect(function(hit)
		local player = PLAYERS:GetPlayerFromCharacter(hit.Parent)
		if not player or fishing_debounce[player] then return end
		fishing_debounce[player] = true
		remotes.Open_Fishing_UI:FireClient(player)
		task.wait(1)
		fishing_debounce[player] = nil
	end)
	
	local bait_debounce = {}
	
	island_copy.BaitShop.Touched:Connect(function(hit)
		local player = PLAYERS:GetPlayerFromCharacter(hit.Parent)
		if not player or bait_debounce[player] then return end
		bait_debounce[player] = true
		remotes.Open_Fishing_UI:FireClient(player, true)
		task.wait(1)
		bait_debounce[player] = nil
	end)
	
	island_copy.TreasureBoard.SpawnTreasure.Sign.CD.MouseClick:Connect(function(player)
		if island_copy.TreasureCounter.Value > 39 then return end
		MARKETPLACE_SERVICE:PromptProductPurchase(player, 1317445952)
	end)
	
	island_copy.TreasureCounter:GetPropertyChangedSignal("Value"):Connect(function()
		island_copy.TreasureBoard.TreasureSpawned.SurfaceGui.TextLabel.Text = "Treasure Spawned: "..island_copy.TreasureCounter.Value
	end)

	switch_wake(false)
	current_island = island_copy
	current_island_name.Value = island_name
	last_island_name = island_name
	current_teleport_location.Value = workspace:FindFirstChild(current_island.Name.."TP")
	island_copy.Parent = workspace

end

local function despawn_island()
	disable_cars(current_island["Parking Lot"])
	disable_cars(extra_vehicles)
	local player_list = PLAYERS:GetPlayers()
	for i = 1, #player_list do
		local player = player_list[i]
		local character = player.Character
		if character then
			local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
			if humanoid_root_part and not (is_in_area(humanoid_root_part.Position, "Ship") or is_in_area(humanoid_root_part.Position, "Captain_Room") or humanoid_root_part.Position.Y < -450.625) then
				teleport_player:Fire(player)
			end
		end
	end
	for _, door in ipairs(docking_doors) do
		door.Transparency = 0
		if not door:IsA("BasePart") then continue end
		door.CanCollide = true
	end
	switch_wake(true)
	task.wait(1)
	current_island:Destroy()
	current_island = nil
	current_island_name.Value = ""

end

--[[ Event Listeners ]]--

LIGHTING_SERVICE:GetPropertyChangedSignal("TimeOfDay"):Connect(function()

	local time_of_day = LIGHTING_SERVICE.TimeOfDay
	local time_index = current_day.Value..time_of_day

	local time_priority
	local message

	if current_island then
		time_priority = key_times[time_index..current_island.Name] or key_times[time_index]
		message = messages[time_index..current_island.Name] or messages[time_index]
		
		if time_of_day == "10:30:00" and math.random(1, 3) == 1 then
			alert:FireAllClients("TreasureSpawned", "A treasure chest has spawned on the island! Find it and be among the first three to claim the treasure.")
			local spots = fisher_yates_shuffle(current_island.TreasureSpawns:GetChildren())
			for _, spot in ipairs(spots) do
				if spot:FindFirstChild("TreasureModel") then continue end
				local new_chest = SERVER_STORAGE.TreasureModel:Clone()
				new_chest:SetPrimaryPartCFrame(spot.CFrame)
				new_chest.Parent = spot
				break
			end
		end
		
	else
		time_priority = key_times[time_index]
		message = messages[time_index]
	end

	if time_priority then

		if type(time_priority) == "userdata" then
			current_teleport_location.Value = time_priority
		elseif type(time_priority) == "string" then

			if time_priority == "Dinner" and current_island then

				for _, player in ipairs(PLAYERS:GetPlayers()) do

					local player_data_folder = REPLICATED_STORAGE:FindFirstChild(player.Name)
					local character = player.Character

					if player_data_folder then
						player_data_folder.Is_In_Arena.Value = false
						player_data_folder.Completed_Event.Value = false
					end

					if character then
						local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
						if is_in_area(humanoid_root_part.Position, current_island.Name) then
							teleport_player:Fire(player)
						end
					end

				end
				current_event_active.Value = false
			end

			current_teleport_location.Value = workspace[current_island.Name..time_priority.."TP"]

		elseif time_priority == 0 then
			current_teleport_location.Value = SHIP
		elseif time_priority == 1 then
			--DEFAULT_WAIT_TIME *= 40
			--SPEED_WAIT_TIME *= 40
			spawn_island()
			alert:FireAllClients("IslandDesc", island_alerts[current_island.Name])
		elseif time_priority == 2 then
			current_event_active.Value = true
			current_teleport_location.Value = workspace:FindFirstChild(current_island.Name.."EventTP")
			task.spawn(island_handler[current_island.Name])
		elseif time_priority == 3 then
			despawn_island()
		elseif time_priority == 4 then
			alert:FireAllClients("IslandDesc", messages[time_index])
		end

	end

	if message then
		current_message.Value = message
		if time_of_day == MOVIE_TIME then
			task.delay(10, function()
				start_movie:FireAllClients()
			end)
		end
	end

end)

local island_badges = {
	["Paradise Island"] = 2127252038;
	["Blox City"] = 2127252044;
	["Olde Town"] = 2127252056;
	["Samurai Island"] = 2148716498;
}

local debounce_list = {}

remotes.Request_Badge.OnServerEvent:Connect(function(player)
	if debounce_list[player] then return end
	debounce_list[player] = true
	task.delay(9, function()
		debounce_list[player] = nil
	end)
	if island_badges[current_island_name.Value] and not BADGE_SERVICE:UserHasBadgeAsync(player.UserId, island_badges[current_island_name.Value]) then		
		BADGE_SERVICE:AwardBadge(player.UserId, island_badges[current_island_name.Value])
	end
end)

--[[ General Code ]]--

for _, island in ipairs(islands:GetChildren()) do
	for _, spot in ipairs(island["Parking Lot"]:GetChildren()) do
		if spot.Name == "Unowned" then
			local vehicle_spawn_time = Instance.new("NumberValue")
			vehicle_spawn_time.Name = "Spawn_Time" 
			vehicle_spawn_time.Parent = spot
		end
	end
	for _, obj in ipairs(island:GetChildren()) do
		if obj.Name == "CarSpawner" then
			for _, spot in ipairs(obj["Parking Lot"]:GetChildren()) do
				if spot.Name == "Unowned" then
					local vehicle_spawn_time = Instance.new("NumberValue")
					vehicle_spawn_time.Name = "Spawn_Time" 
					vehicle_spawn_time.Parent = spot
				end
			end
		end
	end
	table.insert(island_names, island.Name)
end

for day_number, day_name in pairs(days) do

	key_times[day_name..CAFETERIA_TIME] = CAFETERIA
	messages[day_name..SLEEP_TIME] = "It’s night time. Sleep or have fun around the ship."

	if event_days[day_name] then

		key_times[day_name..SLEEP_TIME] = 3
		key_times[day_name..WARNING_TIME] = 4
		key_times[day_name..ARRIVAL_TIME] = 1
		key_times[day_name..ISLAND_LUNCH_TIME] = "Lunch"
		key_times[day_name..EVENT_TIME] = 2
		key_times[day_name..ISLAND_DINNER_TIME] = "Dinner"
		key_times[day_name..RETURN_TIME] = 0
		
		key_times[day_name..DOCKS_TIME] = "Docks"
		messages[day_name..DOCKS_TIME] = "Head to the docks to fish and win cash! You can also task.spawn treasure!"

		messages[day_name..CAFETERIA_TIME] = "It's morning! Head to the Cafeteria for breakfast. We will be arriving at an island at 9:00 AM!"
		messages[day_name..WARNING_TIME] = "Warning! The island is loading in. May cause lag."
		messages[day_name..ARRIVAL_TIME] = "We have arrived at the island! All activities today will be on land!"
		messages[day_name..ISLAND_LUNCH_TIME] = "Lunch is available at a local restaurant! Grab a bite to eat!"
		messages[day_name..EVENT_TIME] = "It is time for this island's event! You are able to earn cash during the event!"
		messages[day_name..ISLAND_DINNER_TIME] = "Dinner is available at a local restaurant! Grab a bite to eat!"
		messages[day_name..RETURN_TIME] = "It is time to get on the ship! You must be back before 12:00 AM."

		for _, island_name in ipairs(island_names) do    
			key_times[day_name..ACTIVITY_TIME..island_name] = island_activities[island_name]
			messages[day_name..ACTIVITY_TIME..island_name] = island_activity_messages[island_name]
		end

	else

		key_times[day_name..LUNCH_TIME] = CAFETERIA
		key_times[day_name..SHIP_DINNER_TIME] = DINING
		key_times[day_name..MOVIE_TIME] = TOP_DECK
		key_times[day_name..CLUB_TIME] = PARTY

		messages[day_name..CAFETERIA_TIME] = "It's morning! Head to the Cafeteria for breakfast."
		messages[day_name..LUNCH_TIME] = "It's the afternoon! Head to the cafeteria for lunch."
		messages[day_name..SHIP_DINNER_TIME] = "The dining room is now serving dinner! Grab some fancy dishes!"
		messages[day_name..MOVIE_TIME] = "It's time for movie night! Head to the top deck to watch a Roblox short film!"
		messages[day_name..CLUB_TIME] = "Want to dance? Head to the club for a Party!"

		if day_number == 0 or day_number == 4 then
			key_times[day_name..SHIP_ACTIVITY_ONE_TIME] = TOP_DECK
			key_times[day_name..SHIP_ACTIVITY_TWO_TIME] = ARCADE
			messages[day_name..SHIP_ACTIVITY_ONE_TIME] = "Head to the top deck to eat, swim, watch TV, play games, or relax!"
			messages[day_name..SHIP_ACTIVITY_TWO_TIME] = "Want to play some games and win some prizes? Head to the Arcade!"
		else
			key_times[day_name..SHIP_ACTIVITY_ONE_TIME] = BACK_DECK
			messages[day_name..SHIP_ACTIVITY_ONE_TIME] = "Head to the back of the ship to eat, relax, or sit in the hot tubs!"
			if day_number == 2 then
				key_times[day_name..SHIP_ACTIVITY_TWO_TIME] = GYM
				messages[day_name..SHIP_ACTIVITY_TWO_TIME] = "Want to workout or play sports? Head to the Sports and Gym!"
			else
				key_times[day_name..SHIP_ACTIVITY_TWO_TIME] = POOL
				messages[day_name..SHIP_ACTIVITY_TWO_TIME] = "Want to swim or relax? Head to the Pool and Spa!"
			end
		end

	end

end

LIGHTING_SERVICE:SetMinutesAfterMidnight(300)

while true do

	local minutes_after_midnight = LIGHTING_SERVICE:GetMinutesAfterMidnight()

	if minutes_after_midnight > 59 and minutes_after_midnight < 421 then
		task.wait(SPEED_WAIT_TIME)
	else
		task.wait(DEFAULT_WAIT_TIME)
	end

	LIGHTING_SERVICE:SetMinutesAfterMidnight(minutes_after_midnight + 1)

	if LIGHTING_SERVICE:GetMinutesAfterMidnight() == 0 then
		current_day_number += 1
		current_day_number %= 7
		current_day.Value = days[current_day_number]
	end

end
