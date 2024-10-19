--[[ Services ]]--

local replicated_storage = game:GetService("ReplicatedStorage")
local text_service = game:GetService("TextService")
local server_storage = game:GetService("ServerStorage")
local team_service = game:GetService("Teams")
local players = game:GetService("Players")
local badge_service = game:GetService("BadgeService")

--[[ Variabes ]]--

local remotes = replicated_storage.Remotes
local play_horn = remotes.Play_Horn
local announce = remotes.Announce
local add_island_to_queue = remotes.Add_Island_To_Queue
local fade = remotes.Fade
local start_arcade = remotes.Start_Arcade
local start_pong = remotes.Start_Pong

local bindables = server_storage.Bindables
local teleported = bindables.Teleported
local change_backpack = bindables.Change_Backpack

local ice_cream = server_storage.Food.Ice_Cream
local cone_model = ice_cream.IceCream
local placements = {"Bottom", "Mid", "Top"}

local foods = server_storage.Food
local souvenirs = replicated_storage.Souvenirs

local client_accessible_modules = replicated_storage.Client_Accessible_Modules
local globals = require(client_accessible_modules.Global_Replacements)
local queues = require(client_accessible_modules.Queues)

local miscellaneous = replicated_storage.Miscellaneous
local horn_timer = miscellaneous.Horn_Timer
local announcement_timer = miscellaneous.Announcement_Timer
local teleport_location = miscellaneous.Teleport_Location

local vehicles = server_storage.Vehicles
local islands = server_storage.Islands

local ran_obj = Random.new()

local name_max_length = 20
local bio_max_length = 100

local jumping_enum = Enum.HumanoidStateType.Jumping
local extra_vehicles = workspace.Extra_Vehicles
local teleport_offset = Vector3.new(0, 7, 0)

local teams = {
	["Captain"] = team_service.Captain;
	["Passenger"] = team_service.Passenger;
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

--[[ Functions ]]--

local function is_in_water(position)
	local x, y, z = position.X, position.Y, position.Z
	return (x >= -2866 and x <= 1472 and y >= 362 and y <= 460.3 and z >= -1187 and z <= 3723)
end

local function switch_value(obj)
	obj.Value = not obj.Value
end

local function count_down_timer(timer_obj)
	for i = 299, 0, -1 do
		task.wait(1)
		timer_obj.Value = i
	end
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

local function get_table_length(t)
	local counter = 0
	for _ in pairs(t) do
		counter += 1
	end
	return counter
end

local function teleport_player_func(player, dont_fade)
	local teleport_location = teleport_location.Value
	if not teleport_location then return end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local teleporting = replicated_storage[player.Name].Teleporting
	local spawn_parts = teleport_location:GetChildren()
	
	teleporting.Value = true
	if not dont_fade then
		fade:FireClient(player)
		task.wait(0.5)
	end
	
	local seat = character:WaitForChild("Humanoid").SeatPart	
	if seat then
		--character.Humanoid.Jump = true
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		seat.Disabled = true
		task.delay(3, function()
			seat.Disabled = false
		end)
	end
	
	task.wait(.25)
	
	character:PivotTo(CFrame.new(spawn_parts[ran_obj:NextInteger(1, #spawn_parts)].Position + teleport_offset))
	teleported:Fire(player)
	task.wait(1)
	teleporting.Value = false
end

--[[ Event Listeners ]]--

remotes.Change_Role_Play_Name.OnServerEvent:Connect(function(player, new_name)
	
	local player_data_folder = replicated_storage:FindFirstChild(player.Name)
	
	if player_data_folder and type(new_name) == "string" and #new_name <= name_max_length then
		
		local character = player.Character or player.CharacterAdded:Wait()
		local head = character.Head
		local display_gui = head.Display_Gui
		local display_gui_frame = display_gui.Frame
		local success
		
		if #new_name > 0 then
			
			success, new_name = pcall(text_service.FilterStringAsync, text_service, new_name, player.UserId)
			
			if success then
				success, new_name = pcall(new_name.GetNonChatStringForBroadcastAsync, new_name)
				if success then
					display_gui_frame.Player_Display_Name.Text = new_name
					player_data_folder.Role_Play_Name.Value = new_name
				else
					display_gui_frame.Player_Display_Name.Text = "######"
					player_data_folder.Role_Play_Name.Value = "######"
				end
			else
				display_gui_frame.Player_Display_Name.Text = "######"
				player_data_folder.Role_Play_Name.Value = "######"
			end
		else
			display_gui_frame.Player_Display_Name.Text = player.Name
			player_data_folder.Role_Play_Name.Value = player.Name
		end		
		
	end
	
end)

remotes.Change_Role_Play_Bio.OnServerEvent:Connect(function(player, new_bio)
	
	local player_data_folder = replicated_storage:FindFirstChild(player.Name)
	
	if player_data_folder and type(new_bio) == "string" and #new_bio <= bio_max_length then
		
		local character = player.Character or player.CharacterAdded:Wait()
		local head = character.Head
		local display_gui = head.Display_Gui
		local display_gui_frame = display_gui.Frame
		local success
		
		success, new_bio = pcall(text_service.FilterStringAsync, text_service, new_bio, player.UserId)
		
		if success then
			success, new_bio = pcall(new_bio.GetNonChatStringForBroadcastAsync, new_bio)
			if success then
				display_gui_frame.Player_Display_Bio.Text = new_bio
				player_data_folder.Role_Play_Bio.Value = new_bio
			else
				display_gui_frame.Player_Display_Bio.Text = "######"
				player_data_folder.Role_Play_Bio.Value = "######"
			end
		else
			display_gui_frame.Player_Display_Bio.Text = "######"
			player_data_folder.Role_Play_Bio.Value = "######"
		end
	end
end)

remotes.Power_Switch_Other_Radios.OnServerEvent:Connect(function(player)
	switch_value(replicated_storage[player.Name].Other_Radios_Enabled)
end)

remotes.Switch_Area_Music.OnServerEvent:Connect(function(player)
	switch_value(replicated_storage[player.Name].Area_Music_Is_Enabled)
end)

remotes.Switch_VIP_Prefix.OnServerEvent:Connect(function(player)
	switch_value(replicated_storage[player.Name].VIP_Prefix_Enabled)
end)

play_horn.OnServerEvent:Connect(function(player)
	if player.Team == teams["Captain"] and horn_timer.Value == 0 then
		horn_timer.Value = 300
		play_horn:FireAllClients()
		count_down_timer(horn_timer)
	end
end)

announce.OnServerEvent:Connect(function(player, text)
	
	local player_data_folder = replicated_storage[player.Name]
	local has_captain_pass = player_data_folder.Has_Captain_Pass
	
	if player.Team == teams["Captain"] and type(text) == "string" and has_captain_pass.Value and announcement_timer.Value == 0 and #text <= 200 then
		
		local success, text = pcall(text_service.FilterStringAsync, text_service, text, player.UserId)
		
		if not success then
			text = "######"
		else
			success, text = pcall(text.GetNonChatStringForBroadcastAsync, text)
			if not success then
				text = "######"
			end
		end
		
		announcement_timer.Value = 300
		announce:FireAllClients(player, text)
		count_down_timer(announcement_timer)
		
	end
	
end)

add_island_to_queue.OnServerEvent:Connect(function(player, island_name)
	
	local player_data_folder = replicated_storage[player.Name]
	local player_has_captain_pass = player_data_folder.Has_Captain_Pass
	local can_select_island = player_data_folder.Can_Select_Island
	
	for island_vote in queues.Island_Queue:iterator() do
		if island_vote[2] == player.Name then
			return
		end
	end
	
	if player_has_captain_pass.Value and queues.Island_Queue:length() < 4 and type(island_name) == "string" and islands:FindFirstChild(island_name) and os.time() - can_select_island.Value >= 1200 then
		local island_vote = {island_name, player.Name}
		can_select_island.Value = os.time()
		queues.Island_Queue:queue(island_vote)
		add_island_to_queue:FireAllClients(island_vote)
	end
	
end)

remotes.Request_Island_Queue.OnServerInvoke = function()
	local transferable_queue = {}
	for island_vote in queues.Island_Queue:iterator() do
		table.insert(transferable_queue, island_vote)
	end
	return transferable_queue
end

remotes.Teleport_To_Event.OnServerEvent:Connect(teleport_player_func)
bindables.Teleport_Player.Event:Connect(teleport_player_func)

local function disable_cars(container)
	for _, obj in pairs(container:GetDescendants()) do
		if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
			obj.Disabled = true
		end
	end
end

local all_color_values = {
	Black = Color3.fromRGB(36, 36, 36);
	Blue = Color3.fromRGB(7, 106, 255);
	Brown = Color3.fromRGB(122, 87, 49);
	Cyan = Color3.fromRGB(0, 255, 255);
	Gold = Color3.fromRGB(255, 245, 133);
	Green = Color3.fromRGB(0, 140, 0);
	Orange = Color3.fromRGB(255, 170, 0);
	Pink = Color3.fromRGB(170, 0, 127);
	Purple = Color3.fromRGB(85, 0, 127);
	Red = Color3.fromRGB(170, 0, 0);
	White = Color3.fromRGB(255, 255, 255);
	Yellow = Color3.fromRGB(255, 255, 0);
}

local default_colors = {
	Stagecoach = Color3.fromRGB(109, 91, 79);
	Horse = Color3.fromRGB(27, 42, 53);
	Jeep = Color3.fromRGB(255, 170, 0);
	Buggy = Color3.fromRGB(39, 70, 45);

	["Basic Car"] = Color3.fromRGB(82, 124, 174);
	["Super Car"] = Color3.fromRGB(60, 93, 165);
}

remotes.Change_Car_Color.OnServerEvent:Connect(function(player, current_name, color)
	if type(color) == "string" and (all_color_values[color] or color == "Default") and current_name and default_colors[current_name] then
		replicated_storage[player.Name].Last_Color_Change.Value = current_name..":"..color
	end
end)

remotes.Buy_Vehicle.OnServerEvent:Connect(function(player, vehicle_type, color)
	
	if type(vehicle_type) ~= "string" or type(color) ~= "string" then return end
	
	local player_data_folder = replicated_storage[player.Name]
	local player_cash = player_data_folder.Cash
	local has_free_cars = player_data_folder.Has_Free_Cars_Pass.Value
	local vehicle = vehicles[miscellaneous.Current_Island_Name.Value]:FindFirstChild(vehicle_type)

	
	if not vehicle then return end
	local island = workspace:FindFirstChild(vehicle.Parent.Name)
	if not island then return end
	
	local price = vehicle.Price
	if player_cash.Value >= price.Value or has_free_cars then
		
		local parking_lot = player_data_folder.Last_Parking_Lot.Value or island["Parking Lot"]
		local owned_parking_spot = player_data_folder.Last_Parking_Spot.Value
		
		if owned_parking_spot then
			local old_vehicle = owned_parking_spot:FindFirstChildWhichIsA("Model") or extra_vehicles:FindFirstChild(player.Name)
			if old_vehicle and old_vehicle.Name == player.Name then
				disable_cars(old_vehicle)
				task.delay(2, function()
					old_vehicle:Destroy()
				end)
			end
		end
		
		if not has_free_cars then
			player_cash.Value -= price.Value
		end
		
		local parking_spot = get_parking_spot(parking_lot:GetChildren())
		local previous_vehicle = parking_spot:FindFirstChildWhichIsA("Model")
		if previous_vehicle then
			previous_vehicle.Parent = extra_vehicles
		end
		
		local vehicle = vehicle:Clone()
		local player_left = bindables.Player_Left
		local character = player.Character or player.CharacterAdded:Wait()
		local parking_spot_cframe = parking_spot.CFrame
		
		local spawn_cframe = CFrame.fromMatrix(
			parking_spot_cframe.Position + Vector3.new(0, 15, 0), 
			parking_spot_cframe.LookVector:Cross(Vector3.new(0, 1, 0)), 
			Vector3.new(0, 1, 0)
		)

        local driver_seat
        if vehicle.Name == "Horse" or vehicle.Name == "Stagecoach" then
            driver_seat = vehicle.Seat
        else
            driver_seat = vehicle.Chassis.VehicleSeat
		end
		
		local color3_value
		if color == "NO_CHANGE" or player_data_folder.Used_Color_Change_Purchase.Value or not player_data_folder.Last_Color_Change.Value:match(vehicle.Name) then
			color3_value = all_color_values[player_data_folder[vehicle.Name.."_Color"].Value]
		elseif all_color_values[color] and not player_data_folder.Used_Color_Change_Purchase.Value then
			color3_value = all_color_values[color]
			player_data_folder[vehicle.Name.."_Color"].Value = color
			player_data_folder.Used_Color_Change_Purchase.Value = true
		else
			color3_value = false
		end
		
		if color3_value then
			for _, part in ipairs(vehicle:GetDescendants()) do
				if part.Name == "Color" then
					part.Color = color3_value
				end
			end
		end
		
		-- find player's parking spot
		-- task.spawn in car
		parking_spot.Spawn_Time.Value = tick()
		vehicle:SetPrimaryPartCFrame(spawn_cframe)
		fade:FireClient(player)
		parking_spot.Name = player.Name
		player_data_folder.Last_Parking_Spot.Value = parking_spot
		vehicle.Name = player.Name
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
			if occupant and players:GetPlayerFromCharacter(occupant.Parent) ~= player then
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
		
		while vehicle.Parent do
			if is_in_water(vehicle:GetPrimaryPartCFrame().Position) then
				disable_cars(vehicle)
				replicated_storage[vehicle.Name].Last_Parking_Spot.Value = nil
				task.delay(2, function()
					vehicle:Destroy()
				end)
				break
			end
			task.wait(1)
		end
	end
end)

remotes.Buy_Food.OnServerEvent:Connect(function(player, food)
	if type(food) == "string" then
		local player_data_folder = replicated_storage[player.Name]
		local player_cash = player_data_folder.Cash
		local food_obj = foods:FindFirstChild(food, true)
		if not food_obj then return end
		local parent_name = food_obj.Parent.Name
		local price
		if parent_name == "Drinks" or parent_name == "Smoothies" or parent_name == "Tea & Coffee" then
			price = 15
		elseif parent_name == "Dinner" then
			price = 35
		else
			price = 25
		end
		if player_cash.Value >= price and food_obj then
			player_cash.Value -= price
			food_obj:Clone().Parent = player.Backpack
		end
	end
end)

remotes.Buy_Souvenir.OnServerInvoke = function(player, souvenir_name)
	if type(souvenir_name) ~= "string" then return end
	local souvenir = souvenirs:FindFirstChild(souvenir_name, true)
	local player_data_folder = replicated_storage[player.Name]
	if souvenir and player_data_folder.Cash.Value >= souvenir.Price.Value then
		player_data_folder.Cash.Value -= souvenir.Price.Value
		souvenir:Clone().Parent = player_data_folder.Souvenirs
		return true
	end
end

remotes.Add_Item_To_Backpack.OnServerEvent:Connect(function(player, item_name, unequip)
	local character = player.Character
	if type(item_name) == "string" and character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
		if unequip then
			local souvenir = player.Backpack:FindFirstChild(item_name) --or player.Character:FindFirstChild(item_name, true)
			if souvenir then
				change_backpack:Fire(player, souvenir, false)
				souvenir:Destroy()
				if workspace:FindFirstChild(player.Name..item_name) then
					workspace:FindFirstChild(player.Name..item_name):Destroy()
				end
			end
		else
			local souvenirs_folder = replicated_storage[player.Name].Souvenirs
			local souvenir = souvenirs_folder:FindFirstChild(item_name)
			if souvenir then
				change_backpack:Fire(player, souvenir, true)
				souvenir:Clone().Parent = player.Backpack
			end
		end
	end
end)

remotes.Finish_Tutorial.OnServerEvent:Connect(function(player)
	player.ReplicationFocus = nil
	replicated_storage[player.Name].Did_Tutorial.Value = true
end)

remotes.Get_Folder.OnServerInvoke = function(player, name)
	local name = type(name) == "string" and name or player.Name
	return replicated_storage:WaitForChild(name, 10)
end

remotes.Get_Cone.OnServerEvent:Connect(function(player, scoops)
	local number_of_scoops = type(scoops) == "table" and get_table_length(scoops) or 0
	if number_of_scoops > 0 and number_of_scoops < 4 then
		local player_cash = replicated_storage[player.Name].Cash
		local price = 10*number_of_scoops
		if player_cash.Value >= price then
			local new_tool = ice_cream["Ice Cream"]:Clone()
			local new_cone = cone_model:Clone()
			new_cone.Cone.Name = "Group"..(price/2 + 1).."Delete"
			player_cash.Value -= price
			for placement, colour in ipairs(scoops) do
				local n = number_of_scoops*3
				local number = placement == 1 and n + 1 or placement == 2 and n - 2 or n - 5
				for i = 1, 3 do
					local segment = new_cone[i..placements[placement]]
					local group = Instance.new("Model")
					segment.Color = colour
					segment.Transparency = 0
					segment.Parent = group
					group.Name = "Group"..(number - i).."Delete"
					group.PrimaryPart = segment
					group.Parent = new_cone
				end
			end
			new_cone.Parent = new_tool
			new_tool.Parent = player:WaitForChild("Backpack")
		end
	end
end)

remotes.RemoteSpawn.OnServerEvent:Connect(function(player)
	replicated_storage[player.Name].Last_Parking_Lot.Value = nil
end)

for _, obj in ipairs(workspace:GetDescendants()) do
	local event
	if obj.Name == "Arcade" then
		event = start_arcade
	elseif obj.Name == "Pong" then
		event = start_pong
	end
	if event then
		obj:FindFirstChildWhichIsA("ClickDetector", true).MouseClick:Connect(function(player)
			event:FireClient(player, obj:FindFirstChild("PointCF", true).CFrame, obj:FindFirstChild("Screen", true))
		end)
	end
end

local food_parents = {}
for _, obj in ipairs(foods:GetDescendants()) do
	if obj:IsA("Tool") then
		food_parents[obj.Name] = obj.Parent.Name
	end
end

remotes.Get_Food_Parents.OnServerInvoke = function()
	return food_parents
end

bindables.Fix_Frog_Transformation.Event:Connect(function(frog_model, frog_script_model, character_array)
	task.wait(5)
	frog_model:Destroy()
	for _, descendant_info in ipairs(character_array) do
		descendant_info.instance[descendant_info.property] = descendant_info.property_value
	end
	frog_script_model:Destroy()
end)

remotes.SouvenirTeleport.OnServerEvent:Connect(function(player, is_island)
	local character = player.Character or player.CharacterAdded:Wait()
	local teleporting = replicated_storage[player.Name].Teleporting
	local spawn_parts = teleport_location:GetChildren()

	teleporting.Value = true
	
	fade:FireClient(player)
	task.wait(0.5)

	local seat = character:WaitForChild("Humanoid").SeatPart	
	if seat then
		--character.Humanoid.Jump = true
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		seat.Disabled = true
		task.delay(3, function()
			seat.Disabled = false
		end)
	end

	task.wait(.25)
	
	if is_island then
		local current_island_name = miscellaneous.Current_Island_Name.Value
		if current_island_name ~= "" then
			character:PivotTo(CFrame.new(workspace[current_island_name].SouvenirTP.Position + teleport_offset))
		end
	else
		character:PivotTo(CFrame.new(workspace.ShipSouvenirTP.Position + teleport_offset))
	end
	
	teleported:Fire(player)
	task.wait(1)
	teleporting.Value = false
end)

remotes.FixOverheadUI.OnServerEvent:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local head = character:WaitForChild("Head")
	
	local playerDataFolder = replicated_storage:FindFirstChild(player.Name)
	
	if not playerDataFolder then
		return
	end
	
	if not head:FindFirstChild("Display_Gui") then
		local newDisplayGui = replicated_storage.Display_Gui:Clone()
		local teamDisplay = newDisplayGui.Frame.Player_Team
		
		newDisplayGui.Frame.Player_Display_Bio.Text = playerDataFolder.Role_Play_Bio.Value
		newDisplayGui.Frame.Player_Display_Name.Text = playerDataFolder.Role_Play_Name.Value
		
		if developers[player.UserId] then
			teamDisplay.Text = "Developer"
			teamDisplay.TextColor3 = Color3.fromRGB(255, 0, 0)
		elseif contributors[player.UserId] then
			teamDisplay.Text = "Contributor"
			teamDisplay.TextColor3 = Color3.fromRGB(75, 151, 75)
		else
			teamDisplay.Text = player.Team.Name
			teamDisplay.TextColor3 = player.Team.TeamColor.Color
		end
		newDisplayGui.Parent = head
	end
end)
