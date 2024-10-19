--[[ Services ]]--

local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local marketplace_service = game:GetService("MarketplaceService")
local team_service = game:GetService("Teams")
local lighting_service = game:GetService("Lighting")
local starter_gui = game:GetService("StarterGui")
local tween_service = game:GetService("TweenService")
local user_input_service = game:GetService("UserInputService")
local content_provider = game:GetService("ContentProvider")
local run_service = game:GetService("RunService")
local asset_service = game:GetService("AssetService")
local gui_service = game:GetService("GuiService")

--[[ General Variables ]]--

local player = players.LocalPlayer
local remotes = replicated_storage:WaitForChild("Remotes")
local player_data_folder = remotes.Get_Folder:InvokeServer()
local is_in_arena = player_data_folder:WaitForChild("Is_In_Arena")
local player_cash = player_data_folder:WaitForChild("Cash")
local spins = player_data_folder:WaitForChild("Spins")

local player_gui = player.PlayerGui
local left_ui = player_gui:WaitForChild("LeftUI")
local clock_ui = player_gui:WaitForChild("Clock")
local buttons_frame = left_ui.Buttons.Background

local run_button
local walk_button
local toggle_running

local client_accessible_modules = replicated_storage:WaitForChild("Client_Accessible_Modules")
local format_number = require(client_accessible_modules.Number_Formatter)
local globals = require(client_accessible_modules.Global_Replacements)

local miscellaneous = replicated_storage:WaitForChild("Miscellaneous")
local wake_model = replicated_storage:WaitForChild("Wake"):Clone()
local current_island_name = miscellaneous.Current_Island_Name
local event_alerts_ui = player_gui:WaitForChild("Event Alerts")
local current_speed = 16

local main_cash_display_text = left_ui.Cash.TextLabel
local hidden_open_shop_button = left_ui.Cash.OpenCash
local souvenirs_folder = replicated_storage:WaitForChild("Souvenirs")
local disable_ui = miscellaneous.Disable_UI
local current_arrow_direction = "<"

local spinning = false
local can_reopen = true
local can_view_starter_pass_ad = true
local can_teleport = true

local open_guis = {}

-- gui colors

local on_background_color = Color3.fromRGB(102, 255, 102)
local off_background_color = Color3.fromRGB(253, 102, 102)
local disabled_background_color = Color3.fromRGB(129, 129, 129)
local blue_background_color = Color3.fromRGB(43, 152, 230)
local super_souvenir_color = Color3.fromRGB(255, 245, 208)
local companion_souvenir_color = Color3.fromRGB(196, 238, 255)

-- Enums 

local easing_style = Enum.EasingStyle
local easing_out_enum = Enum.EasingDirection.Out
local quint_enum = easing_style.Quint

-- guis

local shop_ui
local player_ui
local cabin_purchase_verification_ui
local cabin_ui
local emotes_ui
local captain_ui
local settings_ui
local boom_box_ui
local hide_button
local cafeteria_ui
local dinner_ui
local inventory_ui
local ship_shop_ui
local menu
local spin_ui
local vehicle_shop_ui
local schedule_ui
local ice_cream_shop_ui
local current_game_shop_ui
local avatar_ui
local fade_ui
local updates_ui
local ad_ui
local tutorial_ui
local elevator_ui
local underwater_ad_ui
local captain_ad_ui
local cabin_teleport_ui
local fish_ui
local bait_shop
local treasure_ui

local island_names = {
	["Blox City"] = true;
	["Olde Town"] = true;
	["Paradise Island"] = true;
}

local souvenir_names = {}

local alternative_ids = {
	5409360995,
	7029051434,
	7028907200,
	7028856935,
	7024233823,
	7029024726,
	7024332460,
	7029092469,
	7024254685,
	7029017448,
	7023407320,
	7028799370,
	7028977687,
	7024183256,
	7029031068,
	7023771708,
	7023704173,
	7028919492,
	7028518546,
	7028997537,
	7023617400,
	7028877251,
	7023733671,
	7024101188,
	7023670701,
	7029070008,
	7028913008,
	7023598688,
	7028557220,
	7028527348,
	7023635858,
	7023680426,
	7023760529,
	7024132063,
	7023370016,
	7024245182,
	7028548115,
	7024340270,
	7024121782,
	7029099738,
	7023435987,
	7028970358,
	7023445033,
	7024165463,
	7024280102,
	7028932563,
	7023720291,
	7023741506,
	7023887630,
	7029041793,
	7024154355,
	7023846047,
	7023861220,
	7028570258,
	7028985831,
	7023800698,
	7029005367,
	7023650590,
	5410080857,
	7024109415,
	7023785633,
	7023459476,
	7024220835,
	7028540590,
	7024143472,
	7028957903,
	7023690024,
	7024324344,
	7023749823,
	7029083554,
	7024349679,
	7024035759,
	7024357019,
	7024028859,
	7029011778,
	7029061992,
	7023828725,
}

--[[ Functions and General ]]--

local function tween_obj(object, position)
	object:TweenPosition(
		position,
		easing_out_enum,
		quint_enum,
		1,
		true
	)
end

local function update_cash_displays()
	if not spinning then
		local cash_value_to_display = "Cash: $"..format_number(player_cash.Value)
		main_cash_display_text.Text = cash_value_to_display
	end
end

local function selectively_remove_children(object)
	local object_children = object:GetChildren()
	for i = 1, #object_children do
		local child = object_children[i]
		if child.Name ~= "Gray_Image" then
			child:Destroy()
		end
	end
end

local function switch_wake(on)
	for _, obj in ipairs(wake_model:GetDescendants()) do
		if obj:IsA("Beam") then
			obj.Enabled = on
		end
	end
end

local function close_open_guis(close_left_ui, ignore)
	can_reopen = false
	if close_left_ui then
		for gui in pairs(open_guis) do
			gui.Close(true)
		end
		open_guis = {}
	else
		for gui in pairs(open_guis) do
			if gui ~= hide_button and gui ~= tutorial_ui and gui ~= ignore then
				gui.Close(true)
			end
		end
		local old = open_guis
		open_guis = {[hide_button] = true}
		if old[tutorial_ui] then
			open_guis[tutorial_ui] = true
		end
		if ignore and type(ignore) == "table" then
			open_guis[ignore] = true
		end
	end
	can_reopen = true
end

local function init_standard_gui(gui)

	local self = {}
	local open_position = UDim2.new(0.038, 0, 0.43, 0)
	local closed_position = UDim2.new(-1.2, 0, 0.43, 0)

	self.Open = function(ignore)
		if can_reopen then
			if open_guis[self] then
				self.Close()
			else
				close_open_guis()
				repeat task.wait() until can_reopen
				tween_obj(gui, open_position)
				open_guis[self] = true
			end
		end
	end

	self.Close = function(looping)
		if open_guis[self] then
			tween_obj(gui, closed_position)
			if not looping then
				open_guis[self] = nil
			end
		end
	end

	return self

end

local function init_closeable_gui(gui, alternate_name)

	local self = {}

	local property_to_change = gui:IsA("ScreenGui") and "Enabled" or "Visible"

	self.Open = function(ignore)
		if can_reopen then
			if open_guis[self] then
				self.Close()
			else
				close_open_guis(false, ignore)
				repeat task.wait() until can_reopen
				gui[property_to_change] = true
				open_guis[self] = true
			end
		end
	end

	self.Close = function(looping)
		gui[property_to_change] = false
		if not looping then
			open_guis[self] = nil
		end
	end

	local close_ui_button = gui:FindFirstChild(alternate_name or "Close", true)
	if close_ui_button and gui.Name ~= "Tutorial" then
		close_ui_button.Activated:Connect(function()
			self.Close(nil, true)
		end)
	end

	if gui.Name ~= "Cash Shop" then
		local base = self.Open
		self.Open = function(ignore)
			current_game_shop_ui = self
			base(ignore)
		end
		local base = self.Close
		self.Close = function(looping)
			if current_game_shop_ui == self then
				current_game_shop_ui = nil
			end
			base(looping)
		end
	end

	return self
end

local function init_generic_shop(gui)

	local self = init_closeable_gui(gui)

	local background = gui.Background
	local top_row = background["Top Row"]

	local code_background = top_row["Code Background"]
	local code_box = code_background["Code Box"]
	local redeem_button = code_background["Redeem Button"]
	local last_time_code_box_text_changed = 0
	local redeem_code = remotes.Redeem_Code

	local cash_background = top_row["Cash Background"]
	local buy_cash_button = cash_background["Buy Cash Button"]
	local cash_display = cash_background.Cash

	local gamepasses_button = top_row.Gamepasses["Gamepasses Button"]

	local function display_cash()
		cash_display.Text = "Cash: $"..format_number(player_cash.Value)
	end

	redeem_button.Activated:Connect(function()

		local code = code_box.Text
		local was_valid

		if #code > 0 then

			was_valid = redeem_code:InvokeServer(code)

			if was_valid then
				code_box.Text = was_valid
			else
				code_box.Text = "ERROR"
			end

		end

		task.delay(2, function()
			if code_box.Text == was_valid or (not was_valid and code_box.Text == "ERROR") then
				code_box.Text = "Follow @CruiseLifeRBX on twitter for codes!"
			end
		end)

	end)

	code_box:GetPropertyChangedSignal("Text"):Connect(function()

		local this_text_change = tick()
		last_time_code_box_text_changed = this_text_change

		task.wait(5)

		if this_text_change == last_time_code_box_text_changed and code_box.Text ~= "Follow @CruiseLifeRBX on twitter for codes!" then
			code_box:ReleaseFocus()
			code_box.Text = "Follow @CruiseLifeRBX on twitter for codes!"
		end

	end)

	buy_cash_button.Activated:Connect(function()
		shop_ui.Switch_Sides()
		if gui.Name ~= "Cash Shop" then
			shop_ui.Open()
		end
	end)
	if gui.Name ~= "Cash Shop" then
		gamepasses_button.Activated:Connect(function()
			shop_ui.Switch_Sides(true)
			shop_ui.Open()
		end)
	end

	display_cash()
	player_cash:GetPropertyChangedSignal("Value"):Connect(display_cash)

	return self

end

local function init_food_shop_ui(gui)

	local self = init_closeable_gui(gui)

	local background = gui.Background
	local top_row = background["Top Row"]

	local cash_background = top_row["Cash Background"]
	local buy_cash_button = cash_background["Buy Cash Button"]
	local cash_display = cash_background.Cash

	local side_background = background["Side Background"]
	local preview_area = side_background["Item Preview Background"]
	local gray_image = preview_area.Gray_Image
	local buy_button = side_background["Buy Button Background"]["Buy Button"]
	local price_display = side_background.Price

	local buy_food = remotes.Buy_Food
	local get_food_parents = remotes.Get_Food_Parents

	local food_parents = get_food_parents:InvokeServer()

	local function display_cash()
		cash_display.Text = "Cash: $"..format_number(player_cash.Value)
	end

	local function clean_display_info()
		selectively_remove_children(preview_area)
		gray_image.Visible = true
		price_display.Visible = false
	end

	local function display_info(image_button)
		selectively_remove_children(preview_area)
		gray_image.Visible = false	
		local stuff_to_preview = image_button:GetChildren()
		for i = 1, #stuff_to_preview do
			local display_obj = stuff_to_preview[i]
			display_obj:Clone().Parent = preview_area
		end
		local food_name = preview_area:FindFirstChildWhichIsA("TextLabel").Text
		local parent_name = food_parents[food_name]
		if parent_name == "Drinks" or parent_name == "Smoothies" or parent_name == "Tea & Coffee" then
			price_display.Text = "$15"
		elseif parent_name == "Dinner" then
			price_display.Text = "$35"
		else
			price_display.Text = "$25"
		end
		price_display.Visible = true
	end

	buy_cash_button.Activated:Connect(function()
		shop_ui.Switch_Sides()
		shop_ui.Open()
	end)

	display_cash()
	player_cash:GetPropertyChangedSignal("Value"):Connect(display_cash)

	local last_open_page
	for _, gui_obj in pairs(background:GetChildren()) do
		if gui_obj:FindFirstChild("Items Scrolling Frame") then
			if gui_obj.Visible then
				last_open_page = gui_obj
			end
		end
	end
	for _, button_holder in pairs(top_row:GetChildren()) do
		local button = button_holder:FindFirstChildWhichIsA("TextButton")
		if button then
			local associated_page = background:FindFirstChild(button.Text)
			local can_open_page = true
			if associated_page then
				if gui.Name == "Dinner Shop" then
					last_open_page = background.Dinner
					local associated_page_holder = associated_page
					local unavailable_page = background.Unavailable
					lighting_service:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
						local hour = tonumber(lighting_service.TimeOfDay:match("%d+"))
						if hour >= 18 and hour < 23 then
							can_open_page = true
							if unavailable_page.Visible then
								unavailable_page.Visible = false
								last_open_page.Visible = true
							end
						else
							can_open_page = false
							if not unavailable_page.Visible then
								last_open_page.Visible = false
								unavailable_page.Visible = true
								if preview_area:FindFirstChild("Food Name") then
									clean_display_info()
								end
							end
						end
					end)
				end
				button.Activated:Connect(function()
					clean_display_info()
					if can_open_page then
						last_open_page.Visible = false
						associated_page.Visible = true
					end
					last_open_page = associated_page
				end)
				for _, image_button in pairs(associated_page["Items Scrolling Frame"]:GetChildren()) do
					image_button.Activated:Connect(function()
						display_info(image_button)
					end)
				end
			end
		end
	end

	clean_display_info()

	local base = self.Open
	self.Open = function()
		close_open_guis(true)
		base()
	end

	local base = self.Close
	self.Close = function()
		clean_display_info()
		hide_button.Open()
		base()
	end

	local debounce = true
	buy_button.Activated:Connect(function()
		if debounce then
			debounce = false
			local food = preview_area:FindFirstChildWhichIsA("TextLabel")
			if food then
				if player_cash.Value >= tonumber(price_display.Text:match("%d+")) then
					buy_food:FireServer(food.Text)
				else
					shop_ui.Open()
				end
			end
			task.wait(0.25)
			debounce = true
		end
	end)

	return self
end
task.spawn(function()
	wake_model.Parent = workspace
	switch_wake(current_island_name.Value == "")
	current_island_name:GetPropertyChangedSignal("Value"):Connect(function()
		switch_wake(current_island_name.Value == "")
	end)
end)

--[[
gui_service:SetGameplayPausedNotificationEnabled(false)
player:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
	if player.GameplayPaused then
		player_gui.StreamingFade.Enabled = true
	else
		task.wait(1)
		player_gui.StreamingFade.Enabled = false
	end
end)
--]]
task.spawn(function()
	fade_ui = (function()
		local self = {}

		local fade_ui = player_gui:WaitForChild("TpFade")
		local fade_image = fade_ui.ImageLabel
		local tween_info = TweenInfo.new(0.6)

		local tween_black = tween_service:Create(
			fade_image,
			tween_info,
			{BackgroundTransparency = 0}
		)
		local tween_clear = tween_service:Create(
			fade_image,
			tween_info,
			{BackgroundTransparency = 1}
		)

		self.Fade = function(long)
			if long then
				tween_black:Play()
				tween_black.Completed:Wait()
				task.wait(1)
				tween_clear:Play()
			else
				tween_black:Play()
				tween_black.Completed:Wait()
				tween_clear:Play()
			end
		end

		remotes.Fade.OnClientEvent:Connect(self.Fade)

		return self
	end)()
end)

task.spawn(function()
	tutorial_ui = (function()
		local tutorial = player_gui:WaitForChild("Tutorial")
		local self = init_closeable_gui(tutorial)

		local blur = lighting_service:WaitForChild("Tutorial Blur")
		local current_page = 1
		local last_page = #tutorial:GetChildren() - 4
		local close_button = tutorial.Close
		local current_thread
		local callback

		local base = self.Open
		self.Open = function(c)
			callback = c
			current_thread = coroutine.running()
			blur.Enabled = true
			base()
			coroutine.yield(current_thread)
		end
		local base = self.Close
		self.Close = function()
			callback()
			blur.Enabled = false
			remotes.Finish_Tutorial:FireServer()
			base()
			coroutine.resume(current_thread)
		end

		self._NAME = "TUTORIAL"

		tutorial.Back.Activated:Connect(function()
			if current_page > 1 then
				tutorial[current_page].Visible = false
				current_page = current_page - 1
				tutorial[current_page].Visible = true
			end
		end)

		tutorial.Next.Activated:Connect(function()
			if current_page < last_page then
				tutorial[current_page].Visible = false
				current_page += 1
				tutorial[current_page].Visible = true
				if current_page == last_page then
					close_button.Visible = true
				end
			end
		end)

		close_button.Activated:Connect(function()
			if current_page == last_page then
				self.Close()
			end
		end)

		return self
	end)()
end)

task.spawn(function()

	menu = player_gui:WaitForChild("Menu Screen")

	local blur = lighting_service:WaitForChild("Blur")
	local change_team = remotes.Change_Team
	local player_has_captain_pass = player_data_folder.Has_Captain_Pass
	local captain_pass_id = 8441245
	local cutscenes = workspace:WaitForChild("Cutscenes")
	local tween_info = TweenInfo.new(10, Enum.EasingStyle.Linear)
	local loop_cutscenes = true
	local camera = workspace.CurrentCamera
	local scriptable_enum = Enum.CameraType.Scriptable

	local tween_objects = {}
	local tween_functions = {}
	local current_tween_number = 1

	local function destroy_tweens()
		for i = 1, #tween_objects do
			tween_objects[i]:Cancel()
			tween_objects[i]:Destroy()
		end
	end

	local connection = player.CharacterAdded:Connect(function()
		if camera.CameraType ~= scriptable_enum then
			camera.CameraType = scriptable_enum
			camera.CFrame = CFrame.new(349.894409, 633.720581, 1359.57397, -1, 0, 0, 0, 1, 0, 0, 0, -1)
		end
	end)

	local function close_menu(open_spawn_chooser)

		menu.Enabled = false

		local thread = coroutine.running()
		if open_spawn_chooser then	
			for _, button in ipairs(player_gui:WaitForChild("Spawn").SelectSpawn:GetChildren()) do
				button.Activated:Connect(function()
					player_gui.Spawn:Destroy()
					remotes:WaitForChild("Request_Spawn"):FireServer(button.Name)
					coroutine.resume(thread)
				end)
			end
			player_gui.Spawn.Enabled = true
		else
			for _, button in ipairs(player_gui:WaitForChild("CaptainSpawn").SelectSpawn:GetChildren()) do
				button.Activated:Connect(function()
					player_gui.CaptainSpawn:Destroy()
					remotes:WaitForChild("Request_Spawn"):FireServer(button.Name)
					coroutine.resume(thread)
				end)
			end
			player_gui.CaptainSpawn.Enabled = true
		end

		coroutine.yield()

		tween_objects[current_tween_number]:Cancel()
		loop_cutscenes = false
		destroy_tweens()

		if player_data_folder:WaitForChild("Did_Tutorial").Value then
			connection:Disconnect()
		else
			camera.CFrame = CFrame.new(349.894409, 633.720581, 1359.57397, -1, 0, 0, 0, 1, 0, 0, 0, -1)
			repeat
				task.wait(0.25)
			until tutorial_ui
			tutorial_ui.Open(function()
				connection:Disconnect()
			end)
		end

		task.spawn(function()
			fade_ui.Fade(true)
			left_ui.Enabled = true
			clock_ui.Enabled = true
		end)
		task.wait(1)
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")
		camera.CameraSubject = humanoid
		camera.CameraType = Enum.CameraType.Custom
		blur.Enabled = false
		repeat
			task.wait(0.25)
		until spin_ui
		spin_ui.Open()		
	end

	tween_functions[1] = function()
		camera.CFrame = CFrame.new(349.894409, 633.720581, 1359.57397, -1, 0, 0, 0, 1, 0, 0, 0, -1)
		current_tween_number = 1
	end

	tween_objects[1] = tween_service:Create(
		camera,
		tween_info,
		{["CFrame"] = CFrame.new(282.482605, 633.720581, 1359.57397, -1, 0, 0, 0, 1, 0, 0, 0, -1)}
	)

	tween_functions[2] = function()
		camera.CFrame = CFrame.new(544.83551, 607.349121, 1956.52661, 0.559192836, 0, 0.829037726, 0, 1, 0, -0.829037726, 0, 0.559192836)
		current_tween_number = 1
	end

	tween_objects[2] = tween_service:Create(
		camera,
		tween_info,
		{["CFrame"] = CFrame.new(553.164063, 607.349121, 1891.42834, 0.529917955, 0, 0.848048866, 0, 1, 0, -0.848048866, 0, 0.529917955)}
	)

	tween_functions[3] = function()
		camera.CFrame = CFrame.new( 127.968903, 610.0672, 743.273743, -0.587783337, 0, -0.809018493, 0, 1, 0, 0.809018493, 0, -0.587783337)
		current_tween_number = 1
	end

	tween_objects[3] = tween_service:Create(
		camera,
		tween_info,
		{["CFrame"] = CFrame.new(119.107903, 610.0672, 844.555908, -0.390728921, 0, -0.920505762, 0, 1, 0, 0.920505762, 0, -0.390728921)}
	)

	camera.CFrame = CFrame.new(349.894409, 633.720581, 1359.57397, -1, 0, 0, 0, 1, 0, 0, 0, -1)

	if player_gui:FindFirstChild("Loading") then
		player_gui.ChildRemoved:Wait()
	end

	task.spawn(function()
		menu.Enabled = true
		blur.Enabled = true
		repeat
			camera.CameraType = scriptable_enum
			task.wait()
		until camera.CameraType == scriptable_enum
		-- was getting bugs without this, so don't judge
		-- I dislike using a loop in this way as well
		-- But, until Roblox fixes this assignment issue,
		-- it's all I can do.
		camera.CameraSubject = nil	
		while loop_cutscenes do
			for i = 1, 3 do
				local tween_obj = tween_objects[i]
				current_tween_number = i
				tween_functions[i]()
				tween_obj:Play()
				tween_obj.Completed:Wait()
				if not loop_cutscenes then
					break
				end
			end
		end
	end)

	menu.Passenger.Activated:Connect(function()
		if player_gui.EditAvatar.Enabled then return end
		change_team:FireServer("Passenger")
		close_menu(true)
	end)

	menu.Captain.Activated:Connect(function()
		if player_gui.EditAvatar.Enabled then return end
		if player_has_captain_pass.Value or marketplace_service:UserOwnsGamePassAsync(player.UserId, captain_pass_id) then
			change_team:FireServer("Captain", true)
			close_menu()
		else
			marketplace_service:PromptGamePassPurchase(player, captain_pass_id)
		end
	end)

	--task.spawn(function()
	--	repeat
	--		task.wait(0.25)
	--	until avatar_ui
	--	menu.Avatar.Activated:Connect(avatar_ui.Open)	
	--end)

	updates_ui = (function()
		local self = init_closeable_gui(menu.Updates)
		local base = self.Open
		self.Open = function()
			for _, ui in ipairs(menu:GetChildren()) do
				if ui.Name ~= "Updates" then
					ui.Visible = false
				end
			end
			base()
		end
		local base = self.Close
		self.Close = function()
			for _, ui in ipairs(menu:GetChildren()) do
				if ui.Name ~= "Updates" then
					ui.Visible = true
				end
			end
			base()
		end
		return self
	end)()

	menu.Expand.Activated:Connect(updates_ui.Open)

end)

task.spawn(function()
	hide_button = (function()
		local hide_left_ui_button = left_ui.Hide
		local show_left_ui_button = left_ui.Show
		local self = {}

		local open_position = UDim2.new(0, 0, 0.928, 0)
		local closed_position = UDim2.new(-1.2, 0, 0.928, 0)
		local buttons_frame_open_position = UDim2.new(0.004, 0, -0.15, 0)
		local buttons_frame_closed_position = UDim2.new(-1.2, 0, -0.15, 0)

		open_guis[self] = true

		self.Open = function()
			if current_arrow_direction == "<" then
				tween_obj(buttons_frame, buttons_frame_open_position)
				tween_obj(hide_left_ui_button, open_position)
			else
				tween_obj(hide_left_ui_button, open_position)
			end
			open_guis[self] = true
		end

		self.Close = function()
			if current_arrow_direction == "<" then
				tween_obj(buttons_frame, buttons_frame_closed_position)
				tween_obj(hide_left_ui_button, closed_position)
			else
				tween_obj(hide_left_ui_button, closed_position)
			end
		end

		local function handle_hide_and_show_buttons()
			if current_arrow_direction == "<" then
				current_arrow_direction = ">"
				close_open_guis()
				tween_obj(buttons_frame, buttons_frame_closed_position)
			else
				current_arrow_direction = "<"
				tween_obj(buttons_frame, buttons_frame_open_position)
			end
			if hide_left_ui_button.Visible then
				hide_left_ui_button.Visible = false
				show_left_ui_button.Visible = true
			else
				show_left_ui_button.Visible = false
				hide_left_ui_button.Visible = true
			end
		end

		hide_left_ui_button.Activated:Connect(handle_hide_and_show_buttons)
		show_left_ui_button.Activated:Connect(handle_hide_and_show_buttons)

		return self
	end)()
end)

task.spawn(function()
	ad_ui = (function()
		local ad = player_gui:WaitForChild("Starter Pack Offer")
		local self = init_closeable_gui(ad)
		local base = self.Close
		self.Close = function(_, client_initiated)
			if client_initiated then
				can_view_starter_pass_ad = false
			end
			base()
		end
		ad.StarterPack.Purchase.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, 8441243)
		end)
		ad.LuxuryPack.Purchase.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, 45319605)
		end)
		local debounce = true
		ad.CloseForever.Activated:Connect(function()
			if debounce then
				ad.CloseForever.Text = "Click again to hide deals forever."
				debounce = false
			else
				remotes.Disable_Ad:FireServer()
				self.Close()
			end
		end)
		return self
	end)()
end)

task.spawn(function()
	underwater_ad_ui = (function()
		local ad = player_gui:WaitForChild("Underwater Pack Offer")
		local self = init_closeable_gui(ad)
		ad:WaitForChild("Offer").Purchase.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, 11355885)
		end)
		return self
	end)()
end)

task.spawn(function()
	captain_ad_ui = (function()
		local ad = player_gui:WaitForChild("Captain Offer")
		local self = init_closeable_gui(ad)
		ad:WaitForChild("Offer").Purchase.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, 8441245)
		end)
		return self
	end)()
end)

task.spawn(function()
	spin_ui = (function()	
		local daily_reward_ui = player_gui:WaitForChild("Prize Wheel")
		local self = init_closeable_gui(daily_reward_ui)

		local spins_background = daily_reward_ui.SpinsBackground
		local spins_display = spins_background.TextLabel
		local spin = remotes.Spin
		local spin_frame = daily_reward_ui.SpinnerBackground.Frame
		local spin_frame_default_position = spin_frame.Position
		local spin_frame_default_x = spin_frame_default_position.X.Scale
		local total_y_gap = 0.24
		local ran_obj = Random.new()
		local quart_enum = easing_style.Quart
		local line = daily_reward_ui.SpinPoint

		local reward_display_open = UDim2.new(0.274, 0, 0.192, 0)
		local reward_display_closed = UDim2.new(0.274, 0, -1, 0)
		local reward_display_screen = daily_reward_ui["Reward Screen"]
		local reward_display_text = reward_display_screen.TextLabel
		local reward_display_prize_image = reward_display_screen.Prize
		local reward_display_item_image = reward_display_screen.Item

		local cloneable_crate = miscellaneous.Cloneable_Crate
		local reward_data = require(client_accessible_modules.Reward_Data)

		local base = self.Close
		self.Close = function()
			if can_view_starter_pass_ad and not (player_data_folder:WaitForChild("Has_Starter_Pass").Value and player_data_folder.Has_Luxury_Pass.Value) and not player_data_folder.Disabled_Advertisement.Value then
				ad_ui.Open()
			end
			base()
		end

		local buy_spins_ui = (function()
			local purchasing_frame = daily_reward_ui.BuySpins
			local self = init_closeable_gui(purchasing_frame, "Exit")
			for _, button in ipairs(purchasing_frame:GetChildren()) do
				local id = tonumber(button.Name)
				if not id then continue end
				button.Activated:Connect(function()
					marketplace_service:PromptProductPurchase(player, id)
				end)
			end
			return self
		end)()

		spins_background.BuySpins.Activated:Connect(function()
			buy_spins_ui.Open(self)
		end)

		spins_background.Spin.Activated:Connect(function()
			if spins.Value > 0 and not spinning then
				spinning = true
				local winning_item_info = spin:InvokeServer()
				if type(winning_item_info) == "table" then

					local items = winning_item_info.Items
					local winning_item_index = winning_item_info.Winner_Index
					local winning_item = items[winning_item_index]
					local winning_item_value = winning_item.Value
					local tween_info = TweenInfo.new(ran_obj:NextInteger(5, 8), quart_enum)
					local goal_pos

					for i = 1, #items do

						local new_crate = cloneable_crate:Clone()
						new_crate.Image = items[i].Image_ID
						new_crate.Name = "Prize"..i
						new_crate.Position = UDim2.new(0.055, 0, (-0.308 + total_y_gap*(i - 1)), 0)
						new_crate.Parent = spin_frame

						if i == winning_item_index then
							local distance = line.Position.Y.Scale - new_crate.Position.Y.Scale
							goal_pos = UDim2.new(spin_frame_default_x, 0, distance, 0)
						end

					end

					local tween = tween_service:Create(
						spin_frame,
						tween_info,
						{Position = goal_pos}
					)
					tween:Play()
					tween.Completed:Wait()
					tween:Destroy()

					if winning_item_info.Was_Duplicate then -- will need to modify this significantly, ofc.
						local prize_value = reward_data[winning_item.Group_Index].Rarity.Duplicate_Value
						reward_display_item_image.Visible = true
						reward_display_item_image.Image = winning_item.Item_Image_ID
						reward_display_prize_image.Image = winning_item.Image_ID
						reward_display_text.Text = "This is a duplicate item. You will receive "..prize_value.." instead!"
					else	
						if type(winning_item_value) == "number" then
							reward_display_item_image.Visible = false
							reward_display_prize_image.Image = winning_item.Image_ID
							reward_display_text.Text = winning_item.Text
						else
							reward_display_item_image.Visible = true
							reward_display_item_image.Image = winning_item.Item_Image_ID
							reward_display_prize_image.Image = winning_item.Image_ID
							reward_display_text.Text = winning_item.Text
						end 		
					end

					tween_obj(reward_display_screen, reward_display_open)
					task.wait(2)
					tween_obj(reward_display_screen, reward_display_closed)
					spin_frame:ClearAllChildren()
					spin_frame.Position = spin_frame_default_position

				end
				spinning = false
				update_cash_displays()
			end
		end)

		spins_display.Text = tostring(spins.Value)
		spins:GetPropertyChangedSignal("Value"):Connect(function()
			spins_display.Text = tostring(spins.Value)
			if not daily_reward_ui.Enabled and not menu.Enabled and not player_gui:FindFirstChild("Loading") then
				self.Open()
			end
		end)

		return self
	end)()
end)

task.spawn(function()
	shop_ui = (function()
		local cash_shop = player_gui:WaitForChild("Cash Shop")
		local self = init_generic_shop(cash_shop)

		local main_cash_shop_background = cash_shop.Background

		local cash_purchasing_background = main_cash_shop_background.Cash
		local cash_purchasing_frame = cash_purchasing_background["Items Scrolling Frame"]

		local gamepass_purchasing_background = main_cash_shop_background.Gamepass
		local gamepass_purchasing_frame = gamepass_purchasing_background["Items Scrolling Frame"]
		local gamepass_purchasing_frame_children = gamepass_purchasing_frame:GetChildren()

		local side_background = main_cash_shop_background["Side Background"]
		local buy_button = side_background["Buy Button"]
		local robux_cost_display = side_background.Robux
		local preview_area = side_background["Item Preview Background"]
		local gray_image = preview_area.Gray_Image
		local description = side_background.Description
		local cost = side_background.Cost

		local cash_shop_top_row = main_cash_shop_background["Top Row"]
		local open_gamepass_shop_image = cash_shop_top_row.Gamepasses
		local open_gamepass_shop_button = open_gamepass_shop_image["Gamepasses Button"]

		local shop_name_display = main_cash_shop_background.TextLabel

		local cash_purchasing_frame_children = cash_purchasing_frame:GetChildren()

		local product_ids = {
			["1500"] = 963443669;
			["3250"] = 963446529;
			["7500"] = 963446647;
			["16000"] = 963446181;
			["36000"] = 963446597;
			["85000"] = 963446798;
		}
		local robux_prices = {
			["1500"] = 150;	
			["3250"] = 280;
			["7500"] = 490;
			["16000"] = 850;
			["36000"] = 1500;
			["85000"] = 2200;
		}
		local gamepass_prices = {
			["Boombox"] = {"399 R$", "This pass gives you the ability to play music for you and other players anywhere you go!"};
			["DJ"] = {"349 R$", "With the DJ pass, you can play music in party areas and clubs. You can also set off fire, smoke, and confetti!"};
			["Free Cabins"] = {"450 R$", "All cabins will become free, forever! You will be able to buy cabins instantly, at the small price of 0 cash! "};
			["Starter Pack"] = {"99 R$", "Save tons of robux with the Starter Pack! You get 1,000 cash, 2 spins, and the exclusive Tiny Clone souvenir, valuing over 700 robux!"};
			["Ship Captain"] = {"899 R$", "The captain Gamepass will grant you command over the ship. You can: Blow the ship's horn, choose the next island, and make announcements! You also get access to the Captain's Cabin!"};
			["VIP"] = {"499 R$", "This pass grants you 2x Cash Income, 2x Daily Spins, 2x Cash When Selling Cabins, 2x Event Rewards, 2x Free Fishing Bait, 2,500 Cash On Purchase, And a VIP Tag!"};
			["Free Vehicles"] = {"499 R$", "All vehicles will become free, forever! You will be able to buy any vehicle on any island for the small price of 0 cash!"};
			["Underwater Pack"] = {"1250 R$", "Rule the seas in luxury with the Underwater Pack! This pack includes the exclusive Underwater Cabin, the exclusive Trident and Sea Dragon Mount souvenirs, and 12,500 cash!"};
			["Luxury Pack"] = {"899 R$", "Instantly become rich with the Luxury Pack! You get 30,000 Cash, 10 Spins, the Fame Potion souvenir, and the Money Bag souvenir, valuing over 2,500 robux!"}
		}

		selectively_remove_children(preview_area)
		gray_image.Visible = true
		robux_cost_display.Visible = false

		local base = self.Close
		self.Close = function()
			selectively_remove_children(preview_area)
			gray_image.Visible = true
			robux_cost_display.Visible = false
			description.Visible = false
			cost.Visible = false
			gamepass_purchasing_background.Visible = false
			open_gamepass_shop_button.Text = "Gamepasses"
			shop_name_display.Text = "Cash Shop"
			cash_purchasing_background.Visible = true
			base()
		end

		self.Switch_Sides = function(open_gamepasses)
			selectively_remove_children(preview_area)
			gray_image.Visible = true
			robux_cost_display.Visible = false
			description.Visible = false
			cost.Visible = false
			gamepass_purchasing_background.Visible = false
			cash_purchasing_background.Visible = true
			if open_gamepasses then
				cash_purchasing_background.Visible = false
				open_gamepass_shop_button.Text = "Cash Shop"
				shop_name_display.Text = "Gamepasses"
				gamepass_purchasing_background.Visible = true
			else
				gamepass_purchasing_background.Visible = false
				open_gamepass_shop_button.Text = "Gamepasses"
				shop_name_display.Text = "Cash Shop"
				cash_purchasing_background.Visible = true	
			end
		end

		for i = 1, #cash_purchasing_frame_children do

			local image_button = cash_purchasing_frame_children[i]

			if image_button:IsA("ImageButton") then

				image_button.Activated:Connect(function()

					selectively_remove_children(preview_area)
					gray_image.Visible = false

					local stuff_to_preview = image_button:GetChildren()

					for j = 1, #stuff_to_preview do
						local display_obj = stuff_to_preview[j]
						display_obj:Clone().Parent = preview_area
					end

					local cash_amount = preview_area["Cash Amount"]
					local price = cash_amount.Text:gsub(",", ""):match("%d+")

					robux_cost_display.Text = "R$"..robux_prices[price]
					robux_cost_display.Visible = true

				end)

			end

		end

		for i = 1, #gamepass_purchasing_frame_children do

			local image_button = gamepass_purchasing_frame_children[i]

			if image_button:IsA("ImageButton") then

				image_button.Activated:Connect(function()

					selectively_remove_children(preview_area)
					gray_image.Visible = false

					local stuff_to_preview = image_button:GetChildren()

					for j = 1, #stuff_to_preview do
						local display_obj = stuff_to_preview[j]
						display_obj:Clone().Parent = preview_area
					end

					local info = gamepass_prices[image_button.Name]
					cost.Text = info[1]
					description.Text = info[2]
					description.Visible = true
					cost.Visible = true

				end)		
			end	
		end

		buy_button.Activated:Connect(function()

			local cash_amount = preview_area:FindFirstChild("Cash Amount")

			if cash_amount then

				local price = cash_amount.Text:gsub(",", ""):match("%d+")
				local product_id = product_ids[price]

				if product_id then
					marketplace_service:PromptProductPurchase(player, product_id)
				end

			else
				local id = preview_area:FindFirstChild("ID")
				if id then
					marketplace_service:PromptGamePassPurchase(player, id.Value)
				end
			end

		end)

		open_gamepass_shop_button.Activated:Connect(function()
			if shop_name_display.Text == "Cash Shop" then
				self.Switch_Sides(true)
			else
				self.Switch_Sides()
			end
		end)

		return self
	end)()
	buttons_frame.Shop.Activated:Connect(shop_ui.Open)
	hidden_open_shop_button.Activated:Connect(shop_ui.Open)
end)

task.spawn(function()
	player_ui = (function()
		local player_frame = left_ui.PlayerFrame
		local self = init_standard_gui(player_frame)

		run_button = player_frame.Run
		walk_button = player_frame.Walk

		local change_role_play_bio = remotes.Change_Role_Play_Bio
		local change_role_play_name = remotes.Change_Role_Play_Name

		local default_player_frame_position = UDim2.new(-1.2, 0, 0.35, 0)
		local player_frame_open_position = UDim2.new(0, 0, 0.35, 0)
		local bio_text_box = player_frame.BioBox
		local name_text_box = player_frame.RPNameBox

		local open_inventory_button = player_frame.Inventory
		local open_customization_ui_button = player_frame.Avatar

		local key_code_enum = Enum.KeyCode
		local left_ctrl_enum = key_code_enum.LeftControl
		local right_ctrl_enum = key_code_enum.RightControl

		local name_max_length = 20
		local bio_max_length = 100

		local base = self.Open
		self.Open = function()
			if not is_in_arena.Value then
				base()
			end
		end

		bio_text_box.FocusLost:Connect(function()
			local bio = bio_text_box.Text
			if #bio <= bio_max_length then
				change_role_play_bio:FireServer(bio)
			end
		end)

		name_text_box.FocusLost:Connect(function()
			local name = name_text_box.Text
			if #name <= name_max_length then
				change_role_play_name:FireServer(name)
			end
		end)

		toggle_running = function(disabling)
			if not is_in_arena.Value or disabling then
				local character = player.Character or player.CharacterAdded:Wait()
				local humanoid = character:WaitForChild("Humanoid")
				if not character:FindFirstChild("Spy Drone") then
					if current_speed == 16 then
						walk_button.ImageColor3 = off_background_color
						run_button.ImageColor3 = on_background_color
						humanoid.WalkSpeed = 25
						current_speed = 25
					else
						run_button.ImageColor3 = off_background_color
						walk_button.ImageColor3 = on_background_color
						humanoid.WalkSpeed = 16
						current_speed = 16
					end
				end
			end
		end

		run_button.Activated:Connect(toggle_running)
		walk_button.Activated:Connect(toggle_running)

		user_input_service.InputBegan:Connect(function(input_obj, game_processed_event)
			if not game_processed_event and (input_obj.KeyCode == left_ctrl_enum or input_obj.KeyCode == right_ctrl_enum) then
				toggle_running()
			end
		end)

		open_inventory_button.Activated:Connect(function()
			inventory_ui.Open()
		end)

		open_customization_ui_button.Activated:Connect(function()
			avatar_ui.Open()
		end)

		return self
	end)()
	buttons_frame.Player.Activated:Connect(player_ui.Open)
end)

task.spawn(function()
	cabin_purchase_verification_ui = (function()
		local verification_ui = player_gui:WaitForChild("Purchase Cabin")
		local self = init_closeable_gui(verification_ui)

		local prices = {
			["A"] = 1600;
			["B"] = 800;
			["C"] = 300;
			["CaptainCabin"] = 800;
		}
		local labels = {
			["A"] = "1st Class Cabin";
			["B"] = "2nd Class Cabin";
			["C"] = "3rd Class Cabin";
			["CaptainCabin"] = "Captain Cabin"
		}

		local buy_cabin = remotes.Buy_Cabin
		local purchase_cabin_frame = verification_ui.Purchase
		local cabin_price_display = purchase_cabin_frame.Cash
		local cabin_purchase_cost_display = cabin_price_display.Cost
		local cabin_purchase_class_display = cabin_price_display.Class
		local robux_cabin_price_display = purchase_cabin_frame.Robux
		local cabin_purchase_exit_button = cabin_price_display.Close
		local confirm_cabin_purchase_button = cabin_price_display.Confirm
		local confirm_cabin_robux_purchase_button = robux_cabin_price_display.Confirm
		local confirm_cabin_purchase_button_text = cabin_price_display.Confirm.TextLabel.TextLabel
		local notification_ui = left_ui.TextLabel
		local confirm_debounce = true
		local free_cabins_game_pass_id = 8441246
		local current_cabin_name

		confirm_cabin_purchase_button_text.Text = "Confirm"

		local base = self.Open
		self.Open = function()
			base()
		end

		local base = self.Close
		self.Close = function()
			confirm_cabin_purchase_button_text.Text = "Confirm"
			hide_button.Open()
			base()
		end

		remotes.Send_Cabin_Info.OnClientEvent:Connect(function(cabin_name, lacking_captain_pass)
			if cabin_name then
				if cabin_name:match("UnderwaterCabin") then
					underwater_ad_ui.Open()
				elseif cabin_name:match("Captain") and lacking_captain_pass then
					captain_ad_ui.Open()
				else
					current_cabin_name = cabin_name
					close_open_guis(true)
					cabin_purchase_cost_display.Text = "Cash: "..prices[cabin_name:match("%D+")]
					cabin_purchase_class_display.Text = "Purchase "..labels[cabin_name:match("%D+")]
					self.Open()
				end
			else
				notification_ui.Text = "You already have a cabin!"
				notification_ui.Visible = true
				task.wait(3)
				notification_ui.Visible = false
				notification_ui.Text = "You don't own a cabin!"
			end
		end)

		local debounce = true
		confirm_cabin_purchase_button.Activated:Connect(function()
			if not debounce then return end
			debounce = false
			local result = buy_cabin:InvokeServer(current_cabin_name)
			if type(result) == "string" then
				confirm_cabin_purchase_button_text.Text = result
			else
				self.Close()
				hide_button.Open()
			end
			task.wait(2)
			debounce = true
		end)

		confirm_cabin_robux_purchase_button.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, free_cabins_game_pass_id)
			self.Close()
			hide_button.Open()
		end)

		return self

	end)()
end)

task.spawn(function()
	cabin_teleport_ui = (function()
		local cabin_teleport_frame = player_gui:WaitForChild("CabinTeleport"):WaitForChild("SelectSpawn")
		local self = init_closeable_gui(player_gui.CabinTeleport)

		local owned_cabin = player_data_folder.Owned_Cabin
		local notification_ui = left_ui.TextLabel

		for _, button in ipairs(cabin_teleport_frame:GetChildren()) do
			if button:IsA("TextButton") then
				button.Activated:Connect(function()
					if not can_teleport then return end
					if button.Name == "Cabin" then
						if owned_cabin.Value ~= "" then
							remotes:WaitForChild("Teleport_To_Cabin"):FireServer()
							self.Close()
						else
							notification_ui.Visible = true
							task.wait(3)
							if notification_ui.Text == "You don't own a cabin!" then
								notification_ui.Visible = false
							end
						end
					else
						remotes:WaitForChild("Request_Spawn"):FireServer(button.Name)
						self.Close()
					end
				end)
			end
		end
		return self
	end)()
end)

task.spawn(function()
	cabin_ui = (function()
		local cabin_frame = left_ui.CabinFrame
		local self = init_standard_gui(cabin_frame)

		local sell_cabin = remotes.Sell_Cabin
		local switch_lights = remotes.Switch_Lights
		local lock_door = remotes.Lock_Door
		local switch_confetti = remotes.Switch_Confetti
		local switch_tv = remotes.Switch_Tv

		local player_has_vip_pass = player_data_folder.Has_VIP_Pass
		local player_has_cabin_pass = player_data_folder.Has_Free_Cabins_Pass
		local cabin_doors = workspace:WaitForChild("Cabin_Doors")
		local switch_lights_button = cabin_frame.Lights
		local owned_cabin = player_data_folder.Owned_Cabin
		local sell_cabin_button = cabin_frame.SellCabin
		local verify_sell_cabin_frame = cabin_frame.SellFrame
		local verify_sell_cabin_yes = verify_sell_cabin_frame.Yes
		local verify_sell_cabin_no = verify_sell_cabin_frame.No
		local sell_cabin_value = verify_sell_cabin_frame.Price
		local cabin_frame_is_open = false
		local switch_tv_button = cabin_frame.TV
		local switch_tv_button_text = switch_tv_button.TextLabel	
		local change_lights_button = cabin_frame.Lights
		local lock_door_button = cabin_frame.Door
		local change_lights_button_text = change_lights_button.TextLabel
		local lock_door_button_text = lock_door_button.TextLabel
		local confetti_button = cabin_frame.Confetti
		local confetti_button_text = confetti_button.TextLabel
		local lights_can_be_activated = true
		local vip_pass_id = 8441242
		local notification_ui = left_ui.TextLabel
		local prices = {
			["A"] = 1600;
			["B"] = 800;
			["C"] = 300;
			["CaptainCabin"] = 800;
		}

		change_lights_button.ImageColor3 = on_background_color
		change_lights_button_text.Text = "Lights: On"
		lock_door_button.ImageColor3 = off_background_color
		lock_door_button_text.Text = "Door: Locked"
		switch_tv_button.ImageColor3 = off_background_color
		switch_tv_button_text.Text = "TV: Off"

		local base = self.Open
		self.Open = function()
			if not notification_ui.Visible then
				if owned_cabin.Value ~= "" then
					base()
				else
					cabin_teleport_ui.Open()
					notification_ui.Visible = true
					task.wait(3)
					if notification_ui.Text == "You don't own a cabin!" then
						notification_ui.Visible = false
					end
				end
			end
		end

		if player_has_vip_pass.Value then
			confetti_button.ImageColor3 = off_background_color
			confetti_button_text.Text = "Confetti: Off"
		else
			confetti_button.ImageColor3 = disabled_background_color
			confetti_button_text.Text = "[VIP] Confetti"
		end

		sell_cabin_button.Activated:Connect(function()
			local sell_value
			local cabin_price = prices[owned_cabin.Value:match("%D+")]
			if player_has_cabin_pass.Value then
				sell_value = 0
			else		
				if player_has_vip_pass.Value then
					sell_value = 0.6*cabin_price
				else
					sell_value = 0.3*cabin_price
				end
			end

			sell_cabin_value.Text = "Are you sure you want to sell your cabin for $"..sell_value.."?"
			verify_sell_cabin_frame.Visible = true

		end)

		verify_sell_cabin_yes.Activated:Connect(function()
			if verify_sell_cabin_frame.Visible then
				sell_cabin:FireServer()
				verify_sell_cabin_frame.Visible = false
				self.Close()
				change_lights_button.ImageColor3 = on_background_color
				change_lights_button_text.Text = "Lights: On"
				lock_door_button.ImageColor3 = off_background_color
				lock_door_button_text.Text = "Door: Locked"
				if confetti_button_text.Text == "Confetti: On" then
					confetti_button.ImageColor3 = off_background_color
					confetti_button_text.Text = "Confetti: Off"
				end
				if switch_tv_button_text.Text == "TV: On" then
					switch_tv_button.ImageColor3 = off_background_color
					switch_tv_button_text.Text = "TV: Off"
				end
			end
		end)

		verify_sell_cabin_no.Activated:Connect(function()
			verify_sell_cabin_frame.Visible = false
		end)

		switch_lights_button.Activated:Connect(function()	
			if lights_can_be_activated then
				lights_can_be_activated = false
				switch_lights:FireServer()
				if change_lights_button.ImageColor3 == on_background_color then
					change_lights_button.ImageColor3 = off_background_color
					change_lights_button_text.Text = "Lights: Off"
				else
					change_lights_button.ImageColor3 = on_background_color
					change_lights_button_text.Text = "Lights: On"
				end
				task.wait(0.5)
				lights_can_be_activated = true
			end
		end)

		lock_door_button.Activated:Connect(function()
			lock_door:FireServer()
			if lock_door_button.ImageColor3 == on_background_color then
				lock_door_button.ImageColor3 = off_background_color
				lock_door_button_text.Text = "Door: Locked"
			else
				lock_door_button.ImageColor3 = on_background_color
				lock_door_button_text.Text = "Door: Unlocked"
			end
		end)

		switch_tv_button.Activated:Connect(function()
			switch_tv:FireServer()
			if switch_tv_button.ImageColor3 == on_background_color then
				switch_tv_button.ImageColor3 = off_background_color
				switch_tv_button_text.Text = "TV: Off"
			else
				switch_tv_button.ImageColor3 = on_background_color
				switch_tv_button_text.Text = "TV: On"
			end
		end)

		confetti_button.Activated:Connect(function()
			if player_has_vip_pass.Value then
				switch_confetti:FireServer()
				if confetti_button_text.Text == "Confetti: On" then
					confetti_button.ImageColor3 = off_background_color
					confetti_button_text.Text = "Confetti: Off"
				elseif confetti_button_text.Text == "Confetti: Off" then
					confetti_button.ImageColor3 = on_background_color
					confetti_button_text.Text = "Confetti: On"	
				end
			else
				marketplace_service:PromptGamePassPurchase(player, vip_pass_id)
			end
		end)

		player_has_vip_pass:GetPropertyChangedSignal("Value"):Connect(function()
			if player_has_vip_pass.Value then
				confetti_button.ImageColor3 = off_background_color
				confetti_button_text.Text = "Confetti: Off"
			else
				confetti_button.ImageColor3 = disabled_background_color
				confetti_button_text.Text = "[VIP] Confetti"
			end
		end)

		local debounce = true
		cabin_frame.Teleport.Activated:Connect(function()
			if not debounce then return end
			debounce = false
			remotes.Teleport_To_Cabin:FireServer()
			task.wait(1)
			debounce = true
		end)

		return self
	end)()
	buttons_frame.Cabin.Activated:Connect(cabin_ui.Open)
end)

task.spawn(function()
	emotes_ui = (function()
		local emotes_frame = left_ui.EmotesFrame
		local self = init_standard_gui(emotes_frame)

		local swimming = miscellaneous.Swimming

		local open_dance_ui_button = emotes_frame.Dances
		local open_gesture_ui_button = emotes_frame.Gestures
		local priority = Enum.AnimationPriority.Action

		local current_emote_gui
		local current_animation
		local dance_ui
		local gesture_ui

		local function activate_emote(animation, button)
			local can_loop = true
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:WaitForChild("Humanoid")
			if current_emote_gui and current_animation then
				if current_animation.Name ~= animation.Name then	
					current_emote_gui.ImageColor3 = off_background_color
					button.ImageColor3 = on_background_color
					current_animation:Stop()
					current_animation = humanoid:LoadAnimation(animation)
					current_animation.Priority = priority
					current_animation:Play()
					current_emote_gui = button
				else
					can_loop = false
					current_emote_gui = nil
					current_animation:Stop()
					current_animation = nil
					button.ImageColor3 = off_background_color
				end
			else
				button.ImageColor3 = on_background_color
				current_animation = humanoid:LoadAnimation(animation)
				current_animation.Priority = priority
				current_animation:Play()
				current_emote_gui = button
			end

			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
			local original_position = humanoid_root_part.Position

			task.spawn(function()
				if can_loop then
					current_animation.Stopped:Wait()
					button.ImageColor3 = off_background_color
					can_loop = false
				end
			end)

			while can_loop do

				if (humanoid_root_part.Position - original_position).Magnitude > 10 then
					button.ImageColor3 = off_background_color
					current_animation:Stop()
					current_animation, current_emote_gui = nil, nil
					break
				end

				task.wait(1)

			end

		end

		local function init_dance_ui()

			local dance_frame = emotes_frame.DancesFrame
			local self = init_closeable_gui(dance_frame)

			local base = self.Open
			self.Open = function()
				if open_guis[gesture_ui] then
					gesture_ui.Close()
				end
				base(emotes_ui)
			end

			local dance_frame_children = dance_frame.DancesFrame:GetChildren()

			for i = 1, #dance_frame_children do
				local dance_button = dance_frame_children[i]
				if dance_button:IsA("ImageButton") then
					local animation = dance_button:FindFirstChildWhichIsA("Animation")
					if animation then
						dance_button.Activated:Connect(function()
							local character = player.Character or player.CharacterAdded:Wait()
							local humanoid = character:WaitForChild("Humanoid")
							if humanoid.Health > 0 then
								activate_emote(animation, dance_button)
							end
						end)
					end
				end
			end

			return self

		end

		local function init_gesture_ui()

			local gesture_frame = emotes_frame.GestureFrame
			local self = init_closeable_gui(gesture_frame)

			local base = self.Open
			self.Open = function()
				if open_guis[dance_ui] then
					dance_ui.Close()
				end
				base(emotes_ui)
			end

			local gesture_frame_children = gesture_frame.GestureFrame:GetChildren()

			for i = 1, #gesture_frame_children do
				local gesture_button = gesture_frame_children[i]
				if gesture_button:IsA("ImageButton") then
					local animation = gesture_button:FindFirstChildWhichIsA("Animation")
					if animation then
						gesture_button.Activated:Connect(function()
							local character = player.Character or player.CharacterAdded:Wait()
							local humanoid = character:WaitForChild("Humanoid")
							if humanoid.Health > 0 then
								activate_emote(animation, gesture_button)
							end
						end)
					end
				end
			end

			return self

		end

		swimming:GetPropertyChangedSignal("Value"):Connect(function()
			self.Close()
		end)

		dance_ui = init_dance_ui()
		gesture_ui = init_gesture_ui()

		open_dance_ui_button.Activated:Connect(dance_ui.Open)
		open_gesture_ui_button.Activated:Connect(gesture_ui.Open)

		local base = self.Open
		self.Open = function()
			if not swimming.Value then
				base()
			end
		end

		local base = self.Close
		self.Close = function()
			dance_ui.Close()
			gesture_ui.Close()
			base()
		end

		player.CharacterAdded:Connect(function(new_character)
			local camera = workspace.CurrentCamera
			if current_emote_gui then
				current_emote_gui.ImageColor3 = off_background_color
			end
			if not starter_gui:FindFirstChild("Loading") and menu.Enabled == false and camera.CameraType ~= Enum.CameraType.Custom then
				camera.CameraType = Enum.CameraType.Custom
			end
			if current_game_shop_ui then
				if current_game_shop_ui._NAME ~= "TUTORIAL" then
					current_game_shop_ui.Close()
				end
			end
			local humanoid = new_character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = current_speed
		end)

		return self
	end)()
	buttons_frame.Emotes.Activated:Connect(emotes_ui.Open)
end)

task.spawn(function()
	captain_ui = (function()
		local captain_frame = left_ui.CaptainFrame
		local self = init_standard_gui(captain_frame)

		local announce = remotes.Announce
		local play_horn = remotes.Play_Horn
		local change_team = remotes.Change_Team
		local add_island_to_queue = remotes.Add_Island_To_Queue
		local drop_queue_size = remotes.Drop_Queue_Size
		local request_island_queue = remotes.Request_Island_Queue

		local player_has_captain_pass = player_data_folder.Has_Captain_Pass
		local player_can_select_island = player_data_folder.Can_Select_Island
		local announcement_timer = miscellaneous.Announcement_Timer
		local horn_timer = miscellaneous.Horn_Timer
		local horn_button = captain_frame.Horn
		local horn_button_text = horn_button.TextLabel
		local captain_message_box = captain_frame.MessageBox
		local captain_message_counter = captain_message_box.Counter
		local announce_button = captain_frame.Announce
		local announce_button_text = announce_button.TextLabel
		local team_options_ui = captain_frame.Teams
		local this_player_in_queue = false
		local captain_pass_id = 8441245

		local change_team_button = captain_frame.ChangeTeam
		local passenger_team_button = team_options_ui.ChangeTeamPassenger
		local captain_team_button = team_options_ui.ChangeTeamCaptain

		local announcement_display_gui = player_gui:WaitForChild("Announcement")
		local announcement_display_background = announcement_display_gui.Background
		local announcement_display_text = announcement_display_background.TextLabel
		local announcement_display_default_position = UDim2.new(0.305, 0, -1, 0)
		local announcement_display_open_position = UDim2.new(0.305, 0, 0.032, 0)

		local open_island_ui_button = captain_frame.Island
		local open_island_ui_button_text = open_island_ui_button.TextLabel
		local island_queue_ui = captain_frame.Queue
		local switch_to_selection_ui_button = island_queue_ui.SelectorButton
		local switch_to_selection_ui_button_text = switch_to_selection_ui_button.TextLabel
		local island_selection_ui = captain_frame["Island Selector"]
		local switch_to_queue_ui_button = island_selection_ui.QueueButton
		local island_buttons = island_selection_ui:GetChildren()
		local queue = require(client_accessible_modules.Queue)
		local queues = require(client_accessible_modules.Queues)

		local teams = {
			["Captain"] = team_service.Captain;
			["Passenger"] = team_service.Passenger;
		}

		for _, island_vote in ipairs(request_island_queue:InvokeServer()) do
			queues.Island_Queue:queue(island_vote)
		end

		local base = self.Open
		self.Open = function()
			if player_has_captain_pass.Value then
				base()
			else
				marketplace_service:PromptGamePassPurchase(player, captain_pass_id)
			end
		end

		local base = self.Close
		self.Close = function()
			island_queue_ui.Visible = false
			island_selection_ui.Visible = false
			team_options_ui.Visible = false
			announce_button.Visible = false
			captain_message_box.Text = ""
			base()
			if current_arrow_direction == "<" and can_reopen then
				settings_ui.Open()
			end
		end

		local function update_queue_ui()
			local i = 1
			for island_vote in queues.Island_Queue:iterator() do
				island_queue_ui["Island"..i].TextLabel.Text = island_vote[1]
				island_queue_ui["SelectedBy"..i].TextLabel.Text = "Selected by: "..island_vote[2]
				i += 1
			end
			if i < 4 then
				for j = i, 4 do
					island_queue_ui["Island"..j].TextLabel.Text = "Island"
					island_queue_ui["SelectedBy"..j].TextLabel.Text = "Selected by:"
				end
			end
		end

		update_queue_ui()

		local function open_island_ui()

			if team_options_ui.Visible then
				team_options_ui.Visible = false
			end

			if island_selection_ui.Visible then
				island_selection_ui.Visible = false
			end

			if island_queue_ui.Visible then
				island_queue_ui.Visible = false
			else
				if queues.Island_Queue:length() < 5 then
					if player.Team == teams["Captain"] then
						if not queues.Island_Queue.Visible then
							island_queue_ui.Visible = true
						end
					else
						open_island_ui_button_text.Text = "You must be on the Captain team to do this."
						task.delay(3, function()
							if open_island_ui_button_text.Text == "You must be on the Captain team to do this." then
								open_island_ui_button_text.Text = "Pick The Next Island"
							end
						end)
					end
				end
			end

		end

		horn_button.Activated:Connect(function()
			if player_has_captain_pass.Value and horn_timer.Value == 0 then
				if player.Team == teams["Captain"] then
					play_horn:FireServer()
				elseif horn_button_text.Text == "Blow Ship's Horn" then
					horn_button_text.Text = "You must be on the Captain team to do this."
					task.delay(3, function()
						if horn_button_text.Text == "You must be on the Captain team to do this." then
							horn_button_text.Text = "Blow Ship's Horn"
						end
					end)
				end
			end
		end)

		horn_timer:GetPropertyChangedSignal("Value"):Connect(function()
			if horn_timer.Value == 0 then
				horn_button_text.Text = "Blow Ship's Horn"
				horn_button.ImageColor3 = blue_background_color
			else
				horn_button_text.Text = "A captain used a horn recently. Wait "..horn_timer.Value.." seconds."
				horn_button.ImageColor3 = off_background_color
			end
		end)

		announce_button.Activated:Connect(function()
			if player_has_captain_pass.Value and #captain_message_box.Text <= 200 and #captain_message_box.Text > 0 and announcement_timer.Value == 0 then
				if player.Team == teams["Captain"] then
					announce:FireServer(captain_message_box.Text)
				elseif announce_button_text.Text == "Make Announcement" then
					announce_button_text.Text = "You must be on the Captain team to do this."
					task.delay(3, function()
						if announce_button_text.Text == "You must be on the Captain team to do this." then
							announce_button_text.Text = "Make Announcement"
						end
					end)
				end
			end
		end)

		announce.OnClientEvent:Connect(function(captain_player, text)

			local text_to_display = "Captain "..captain_player.Name.." says: "..text

			tween_obj(announcement_display_background, announcement_display_open_position)

			for i = 1, #text_to_display do
				task.wait()
				announcement_display_text.Text = string.sub(text_to_display, 1, i)
			end

			task.wait(10)
			tween_obj(announcement_display_background, announcement_display_default_position)
			announcement_display_text.Text = ""

		end)

		captain_message_box:GetPropertyChangedSignal("Text"):Connect(function()
			local text_length = #captain_message_box.Text
			if text_length == 0 then
				announce_button.Visible = false
			else
				announce_button.Visible = true
			end
			captain_message_counter.Text = text_length
		end)

		announcement_timer:GetPropertyChangedSignal("Value"):Connect(function()
			if announcement_timer.Value == 0 then
				announce_button.ImageColor3 = blue_background_color
				announce_button_text.Text = "Make Announcement"
			else
				announce_button.ImageColor3 = off_background_color
				announce_button_text.Text = "A captain made an announcement recently. Wait "..announcement_timer.Value.." seconds."
			end
		end)

		change_team_button.Activated:Connect(function()
			if team_options_ui.Visible then
				team_options_ui.Visible = false
			else
				island_queue_ui.Visible = false
				island_selection_ui.Visible = false
				team_options_ui.Visible = true
			end
		end)

		passenger_team_button.Activated:Connect(function()
			if player.Team ~= teams["Passenger"] then
				change_team:FireServer("Passenger")
			end
			team_options_ui.Visible = false
		end)

		captain_team_button.Activated:Connect(function()
			if player.Team ~= teams["Captain"] then
				change_team:FireServer("Captain")
			end
			team_options_ui.Visible = false
		end)

		open_island_ui_button.Activated:Connect(open_island_ui)
		switch_to_queue_ui_button.Activated:Connect(open_island_ui)

		switch_to_selection_ui_button.Activated:Connect(function()
			for island_vote in queues.Island_Queue:iterator() do
				if island_vote[2] == player.Name then
					return
				end
			end
			if queues.Island_Queue:length() < 5 then
				if os.time() - player_can_select_island.Value >= 1200  then
					island_queue_ui.Visible = false
					island_selection_ui.Visible = true
				else
					switch_to_selection_ui_button.ImageColor3 = off_background_color
					switch_to_selection_ui_button_text.Text = "You cannot select another island for another "..((1200 + player_can_select_island.Value) - os.time()).." seconds."
					task.delay(3, function()
						if switch_to_selection_ui_button_text.Text:match("You cannot select another island for another ") then -- decided to be lazy here.
							switch_to_selection_ui_button.ImageColor3 = blue_background_color
							switch_to_selection_ui_button_text.Text = "Pick The Next Island"
						end
					end)
				end
			end
		end)

		add_island_to_queue.OnClientEvent:Connect(function(island_vote, remove)
			if remove then
				local new_island_queue = queue.new()
				for queue_element in queues.Island_Queue:iterator() do
					if queue_element[2] == island_vote then continue end -- island vote is player's name if remove is false
					new_island_queue:queue(queue_element)
				end
				queues.Island_Queue = new_island_queue
				update_queue_ui()
				return
			end
			queues.Island_Queue:queue(island_vote)
			update_queue_ui()
			if island_vote[2] == player.Name then
				switch_to_selection_ui_button.ImageColor3 = off_background_color
				switch_to_selection_ui_button_text.Text = "You have an island in the queue already."
				this_player_in_queue = true
			elseif queues.Island_Queue:length() > 3 then
				if switch_to_selection_ui_button_text.Text ~= "You have an island in the queue already." then
					switch_to_selection_ui_button.ImageColor3 = off_background_color
					switch_to_selection_ui_button_text.Text = "Queue Full"
					open_island_ui_button.ImageColor3 = off_background_color
					open_island_ui_button_text.Text = "Queue Full"
				end
			end
		end)

		drop_queue_size.OnClientEvent:Connect(function()
			local island_vote = queues.Island_Queue:unqueue()
			update_queue_ui()
			if island_vote[2] == player.Name then
				switch_to_selection_ui_button.ImageColor3 = blue_background_color
				switch_to_selection_ui_button_text.Text = "Island Selector"
				this_player_in_queue = false
			elseif queues.Island_Queue:length() == 3 and not this_player_in_queue then
				switch_to_selection_ui_button.ImageColor3 = blue_background_color
				switch_to_selection_ui_button_text.Text = "Island Selector"
			end
		end)

		for i = 1, #island_buttons do

			local island_button = island_buttons[i]
			local is_island = island_button:FindFirstChild("Is_Island")
			local island_name_text = island_button:FindFirstChild("TextLabel")

			if island_button:IsA("ImageButton") and is_island and is_island.Value and island_name_text then
				island_button.Activated:Connect(function()
					if queues.Island_Queue:length() < 4 then
						add_island_to_queue:FireServer(island_name_text.Text)
						open_island_ui()
					else
						open_island_ui()
					end
				end)
			end
		end

		return self
	end)()
end)

task.spawn(function()
	settings_ui = (function()
		local settings_frame = left_ui.OptionsFrame
		local self = init_standard_gui(settings_frame)

		local player_has_vip_pass = player_data_folder.Has_VIP_Pass
		local player_vip_prefix_enabled = player_data_folder.VIP_Prefix_Enabled
		local player_has_captain_pass = player_data_folder.Has_Captain_Pass
		local player_has_boom_box_pass = player_data_folder.Has_Boom_Box_Pass
		local area_music_is_enabled = player_data_folder.Area_Music_Is_Enabled

		local switch_area_music = remotes.Switch_Area_Music
		local power_switch_other_radios = remotes.Power_Switch_Other_Radios
		local switch_vip_prefix = remotes.Switch_VIP_Prefix

		local boom_box_control_button = settings_frame.Boomboxes
		local control_boom_box_text_box = boom_box_control_button.TextLabel

		local control_area_music_button = settings_frame.Music
		local control_area_music_button_text = control_area_music_button.TextLabel

		local open_captain_ui_button = settings_frame.Captain
		local open_boom_box_ui_button = settings_frame.Boombox

		local vip_prefix_button = settings_frame.VipPrefix
		local vip_prefix_button_text = vip_prefix_button.TextLabel
		local vip_pass_id = 8441242

		if player_has_vip_pass.Value then
			if player_vip_prefix_enabled.Value then
				vip_prefix_button.ImageColor3 = on_background_color
				vip_prefix_button_text.Text = "VIP Prefix Enabled"
			else
				vip_prefix_button.ImageColor3 = off_background_color
				vip_prefix_button_text.Text = "VIP Prefix Disabled"
			end
		end

		if player_has_captain_pass.Value then
			open_captain_ui_button.ImageColor3 = blue_background_color
		end

		if player_has_boom_box_pass.Value then
			open_boom_box_ui_button.ImageColor3 = blue_background_color
		end

		player_has_vip_pass:GetPropertyChangedSignal("Value"):Connect(function()
			if player_has_vip_pass.Value then
				if player_vip_prefix_enabled.Value then
					vip_prefix_button.ImageColor3 = on_background_color
					vip_prefix_button_text.Text = "VIP Prefix Enabled"
				else
					vip_prefix_button.ImageColor3 = off_background_color
					vip_prefix_button_text.Text = "VIP Prefix Disabled"
				end
				for _, obj in ipairs(workspace:WaitForChild("VIPAreaBlocks"):GetChildren()) do
					obj.CanCollide = false
				end
			end
		end)

		player_vip_prefix_enabled:GetPropertyChangedSignal("Value"):Connect(function()
			if player_has_vip_pass.Value then
				if player_vip_prefix_enabled.Value then
					vip_prefix_button.ImageColor3 = on_background_color
					vip_prefix_button_text.Text = "VIP Prefix Enabled"
				else
					vip_prefix_button.ImageColor3 = off_background_color
					vip_prefix_button_text.Text = "VIP Prefix Disabled"
				end
			end
		end)

		vip_prefix_button.Activated:Connect(function()
			if player_has_vip_pass.Value then
				switch_vip_prefix:FireServer()
			else
				marketplace_service:PromptGamePassPurchase(player, vip_pass_id)
			end
		end)

		boom_box_control_button.Activated:Connect(function()
			power_switch_other_radios:FireServer()
			if control_boom_box_text_box.Text == "Mute Boomboxes" then
				boom_box_control_button.ImageColor3 = off_background_color
				control_boom_box_text_box.Text = "Enable Boomboxes"
			else
				boom_box_control_button.ImageColor3 = on_background_color
				control_boom_box_text_box.Text = "Mute Boomboxes"
			end
		end)

		control_area_music_button.Activated:Connect(function()
			switch_area_music:FireServer()
		end)

		area_music_is_enabled:GetPropertyChangedSignal("Value"):Connect(function()
			if area_music_is_enabled.Value then
				control_area_music_button_text.Text = "Background Music: On"
				control_area_music_button.ImageColor3 = on_background_color
			else
				control_area_music_button_text.Text = "Background Music: Off"
				control_area_music_button.ImageColor3 = off_background_color
			end
		end)

		player_has_captain_pass:GetPropertyChangedSignal("Value"):Connect(function()
			if player_has_captain_pass.Value then
				open_captain_ui_button.ImageColor3 = blue_background_color
			end
		end)

		player_has_boom_box_pass:GetPropertyChangedSignal("Value"):Connect(function()
			open_boom_box_ui_button.ImageColor3 = blue_background_color
		end)

		-- done this way since boom_box_ui, captain_ui, and spin_ui may not be defined at runtime

		open_boom_box_ui_button.Activated:Connect(function()
			boom_box_ui.Open()
		end)

		open_captain_ui_button.Activated:Connect(function()
			captain_ui.Open()
		end)

		settings_frame.DailyReward.Activated:Connect(function()
			spin_ui.Open()
		end)

		return self
	end)()
	buttons_frame.Options.Activated:Connect(function()
		settings_ui.Open()
	end)
end)

task.spawn(function()
	boom_box_ui = (function()
		local boom_box_screen_gui = player_gui:WaitForChild("Boombox")
		local self = init_closeable_gui(boom_box_screen_gui)

		local musicListUI = boom_box_screen_gui.MusicListUI
		local musicListElement = musicListUI.Background.ScrollingFrame.Song:Clone()

		local change_boom_box_song = remotes.Change_Boom_Box_Song
		local player_has_boom_box_pass = player_data_folder.Has_Boom_Box_Pass
		local boom_box_is_enabled = player_data_folder.Boom_Box_Is_Active
		local can_play_boom_box = player_data_folder.Can_Play_Boom_Box
		local boom_box = boom_box_screen_gui.Boombox
		local song_id_text_box = boom_box.SongID
		local last_time_music_text_changed = tick()
		local play_song_button = boom_box.Play
		local stop_song_button = boom_box.Stop
		local boom_box_pass_id = 8441259

		local base = self.Open
		self.Open = function()
			if can_play_boom_box.Value then
				if player_has_boom_box_pass.Value then
					base()
				else
					marketplace_service:PromptGamePassPurchase(player, boom_box_pass_id)
				end
			end
		end

		local base = self.Close
		self.Close = function()
			song_id_text_box.Text = ""
			base()
		end

		can_play_boom_box:GetPropertyChangedSignal("Value"):Connect(function()
			if not can_play_boom_box.Value then
				self.Close()
			end
		end)

		play_song_button.Activated:Connect(function()
			if player_has_boom_box_pass.Value and #song_id_text_box.Text > 0 then
				song_id_text_box.Text = change_boom_box_song:InvokeServer(song_id_text_box.Text)
			end
		end)

		stop_song_button.Activated:Connect(function()
			if player_has_boom_box_pass.Value and boom_box_is_enabled.Value then
				song_id_text_box.Text =  change_boom_box_song:InvokeServer(false)
			end
		end)

		boom_box_screen_gui.OpenMusicList.Activated:Connect(function()
			musicListUI.Visible = true
		end)

		musicListUI.Back.Activated:Connect(function()
			musicListUI.Visible = false
		end)

		musicListUI.Background.ScrollingFrame.Song:Destroy()
		for _, id in ipairs(alternative_ids) do
			task.spawn(function()
				local newElement = musicListElement:Clone()
				local success, songInfo

				repeat
					success, songInfo = pcall(marketplace_service.GetProductInfo, marketplace_service, id)
					if not success then
						task.wait(3)
					end
				until success

				newElement.Play.Activated:Connect(function()
					change_boom_box_song:InvokeServer(tostring(id))
					musicListUI.Visible = false
				end)

				newElement.Text = songInfo.Name
				newElement.Parent = musicListUI.Background.ScrollingFrame
			end)
		end

		return self
	end)()
end)

task.spawn(function()
	schedule_ui = (function()
		local schedule_frame = left_ui.ScheduleFrame
		local current_day = miscellaneous.Day
		local self = init_closeable_gui(schedule_frame)
		local previous_day = current_day.Value
		local current_page

		local days = {
			"Sunday";
			"Monday";
			"Tuesday";
			"Wednesday";
			"Thursday";
			"Friday";
			"Saturday";
		}

		schedule_frame[previous_day].Visible = true
		current_page = table.find(days, previous_day)

		local base = self.Close
		self.Close = function()
			schedule_frame[days[current_page]].Visible = false
			current_page = table.find(days, current_day.Value)
			schedule_frame[days[current_page]].Visible = true
			base()
		end

		current_day:GetPropertyChangedSignal("Value"):Connect(function()
			schedule_frame[previous_day].Visible = false
			schedule_frame[current_day.Value].Visible = true
			previous_day = current_day.Value
			current_page = table.find(days, previous_day)
		end)

		schedule_frame.Back.Activated:Connect(function()
			if current_page > 1 then
				schedule_frame[days[current_page]].Visible = false
				current_page -= 1
				schedule_frame[days[current_page]].Visible = true
			end
		end)

		schedule_frame.Next.Activated:Connect(function()
			if current_page < 7 then
				schedule_frame[days[current_page]].Visible = false
				current_page += 1
				schedule_frame[days[current_page]].Visible = true
			end
		end)

		return self
	end)()
	buttons_frame.Schedule.Activated:Connect(schedule_ui.Open)
end)

task.spawn(function()

	local food_uis = player_gui:WaitForChild("Food Shops")
	local food_ui_names = {}

	for _, gui_obj in pairs(food_uis:GetChildren()) do
		food_ui_names[gui_obj.Name] = init_food_shop_ui(gui_obj)
	end

	local function open_shop(method, name, full_name)
		local island_name = full_name and full_name:reverse():match("%D+"):reverse() or ""
		if method == "Close" or not island_names[island_name] or current_island_name.Value == island_name then
			if food_ui_names[name] then
				food_ui_names[name][method]()
			elseif name == "IceCream Shop" then
				ice_cream_shop_ui[method]()
			elseif name == "PrizeShop" then
				spin_ui[method]()
			elseif name == "Part" then
				vehicle_shop_ui[method]()
				remotes.RemoteSpawn:FireServer()
			else
				ship_shop_ui[method](name)
			end
		end
	end

	local character = player.Character or player.CharacterAdded:Wait()
	player.CharacterAdded:Connect(function(new_character)
		character = new_character
	end)

	local areas = remotes.Get_Shop_Areas:InvokeServer()
	local current_area
	while true do
		task.wait(1)
		local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
		if humanoid_root_part then
			local position = humanoid_root_part.Position
			local found_area
			for name, area in pairs(areas) do
				if (position - area).Magnitude <= 6 then
					found_area = true
					local first_name = name:match("%D+")
					if current_area then
						if first_name ~= current_area then
							open_shop("Close", current_area)
							open_shop("Open", first_name, name)
						end
					else
						open_shop("Open", first_name, name)
					end
					current_area = first_name
				end
			end
			if not found_area and current_area then
				open_shop("Close", current_area)
				current_area = nil
			end
		end
	end

end)

for _, obj in ipairs(souvenirs_folder:GetDescendants()) do
	if not obj:IsA("Tool") then continue end
	if obj:FindFirstAncestor("Rewards") then
		souvenir_names[obj.Name] = "Rewards"
		continue
	end
	souvenir_names[obj.Name] = obj.Parent.Name
end

task.spawn(function()
	inventory_ui = (function()	
		local inventory_screen_gui = player_gui:WaitForChild("Inventory")
		local self = init_generic_shop(inventory_screen_gui)

		local add_item_to_backpack = remotes.Add_Item_To_Backpack
		local souvenir_teleport = remotes.SouvenirTeleport

		local souvenirs = player_data_folder.Souvenirs
		local background = inventory_screen_gui.Background

		local scrolling_frame = background.Items["Items Scrolling Frame"]
		local default_item = miscellaneous.Item
		local super_item = default_item:Clone()
		local companion_item = default_item:Clone()

		super_item.ImageColor3 = super_souvenir_color
		companion_item.ImageColor3 = companion_souvenir_color

		local current_event_text = event_alerts_ui.EventDesc.TextLabel
		local create_new_item

		local comparison_values = {
			["Rewards"] = 1;
			["SuperShop"] = 2;
			["CompanionShop"] = 3;
		}

		local found_fame = false
		local found_bag = false

		if user_input_service.MouseEnabled then

			function create_new_item(souvenir)

				local new_item
				if souvenir_names[souvenir.Name] == "Rewards" or souvenir_names[souvenir.Name] == "SuperShop" then
					new_item = super_item:Clone()
					new_item.Name = "F"
				elseif souvenir_names[souvenir.Name] == "CompanionShop" then
					new_item = companion_item:Clone()
					new_item.Name = "G"
				else
					new_item = default_item:Clone()
					new_item.Name = "H"
				end
				local item_desc = new_item.ItemDesc
				new_item["Gear Name"].Text = souvenir.Name
				new_item["Gear Image"].Image = souvenir:WaitForChild("ImageID").Value
				item_desc.DescText.Text = souvenir:WaitForChild("Description").Value
				new_item.Parent = scrolling_frame

				local debounce = true
				item_desc.Activated:Connect(function()
					if debounce and current_event_text.Text ~= "Warning! The island is loading in. May cause lag." then
						debounce = false
						if player.Backpack:FindFirstChild(souvenir.Name) or player.Character:FindFirstChild(souvenir.Name, true) then
							add_item_to_backpack:FireServer(souvenir.Name, true)
						else
							add_item_to_backpack:FireServer(souvenir.Name)
						end
						task.wait(0.25)
						debounce = true
					end
				end)
				new_item.MouseEnter:Connect(function()
					item_desc.Visible = true
				end)
				new_item.MouseLeave:Connect(function()
					item_desc.Visible = false
				end)

			end

		else
			default_item.ItemDesc:Destroy()
			companion_item.ItemDesc:Destroy()
			super_item.ItemDesc:Destroy()
			function create_new_item(souvenir)
				local new_item
				if souvenir_names[souvenir.Name] == "Rewards" or souvenir_names[souvenir.Name] == "SuperShop" then
					new_item = super_item:Clone()
					new_item.Name = "F"
				elseif souvenir_names[souvenir.Name] == "CompanionShop" then
					new_item = companion_item:Clone()
					new_item.Name = "G"
				else
					new_item = default_item:Clone()
					new_item.Name = "H"
				end
				new_item["Gear Name"].Text = souvenir.Name
				new_item["Gear Image"].Image = souvenir:WaitForChild("ImageID").Value
				new_item.Parent = scrolling_frame
				local debounce = true
				new_item.Activated:Connect(function()
					if debounce and current_event_text.Text ~= "Warning! The island is loading in. May cause lag." then
						debounce = false
						if player.Backpack:FindFirstChild(souvenir.Name) or player.Character:FindFirstChild(souvenir.Name, true) then
							add_item_to_backpack:FireServer(souvenir.Name, true)
						else
							add_item_to_backpack:FireServer(souvenir.Name)
						end
						task.wait(0.25)
						debounce = true
					end
				end)
			end
		end

		for _, souvenir in ipairs(souvenirs:GetChildren()) do
			if souvenir.Name == "Fame Potion" then
				found_fame = true
			elseif souvenir.Name == "Moneybag" then
				found_bag = true
			end
			create_new_item(souvenir)
		end

		souvenirs.ChildAdded:Connect(function(child)
			if child.Name == "Fame Potion" and scrolling_frame:FindFirstChild("D") then
				scrolling_frame.D:Destroy()
			elseif child.Name == "Moneybag" and scrolling_frame:FindFirstChild("E") then
				scrolling_frame.E:Destroy()
			end
			create_new_item(child)
		end)

		if not player_data_folder.Has_Underwater_Pass.Value then
			player_data_folder.Has_Underwater_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				if not scrolling_frame:FindFirstChild("A") then return end
				scrolling_frame.A:Destroy()
			end)
			if user_input_service.MouseEnabled then
				scrolling_frame.A.ItemDesc.Activated:Connect(function()
					underwater_ad_ui.Open()
				end)
				scrolling_frame.A.MouseEnter:Connect(function()
					scrolling_frame.A.ItemDesc.Visible = true
				end)
				scrolling_frame.A.MouseLeave:Connect(function()
					scrolling_frame.A.ItemDesc.Visible = false
				end)
			else
				scrolling_frame.A.Activated:Connect(function()
					underwater_ad_ui.Open()
				end)
			end
		else
			scrolling_frame.A:Destroy()
		end

		if not player_data_folder.Has_Underwater_Pass.Value then		
			player_data_folder.Has_Underwater_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				if not scrolling_frame:FindFirstChild("B") then return end
				scrolling_frame.B:Destroy()
			end)
			if user_input_service.MouseEnabled then
				scrolling_frame.B.ItemDesc.Activated:Connect(function()
					underwater_ad_ui.Open()
				end)
				scrolling_frame.B.MouseEnter:Connect(function()
					scrolling_frame.B.ItemDesc.Visible = true
				end)
				scrolling_frame.B.MouseLeave:Connect(function()
					scrolling_frame.B.ItemDesc.Visible = false
				end)
			else
				scrolling_frame.B.Activated:Connect(function()
					underwater_ad_ui.Open()
				end)
			end
		else
			scrolling_frame.B:Destroy()
		end

		if not player_data_folder.Has_Starter_Pass.Value then
			player_data_folder.Has_Starter_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				if not scrolling_frame:FindFirstChild("C") then return end
				scrolling_frame.C:Destroy()
			end)
			if user_input_service.MouseEnabled then
				scrolling_frame.C.ItemDesc.Activated:Connect(function()
					ad_ui.Open()
				end)
				scrolling_frame.C.MouseEnter:Connect(function()
					scrolling_frame.C.ItemDesc.Visible = true
				end)
				scrolling_frame.C.MouseLeave:Connect(function()
					scrolling_frame.C.ItemDesc.Visible = false
				end)
			else
				scrolling_frame.C.Activated:Connect(function()
					ad_ui.Open()
				end)
			end
		else
			scrolling_frame.C:Destroy()
		end

		if not player_data_folder.Has_Luxury_Pass.Value and not found_fame then	
			player_data_folder.Has_Luxury_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				if not scrolling_frame:FindFirstChild("D") then return end
				scrolling_frame.D:Destroy()
			end)
			if user_input_service.MouseEnabled then
				scrolling_frame.D.ItemDesc.Activated:Connect(function()
					ad_ui.Open()
				end)
				scrolling_frame.D.MouseEnter:Connect(function()
					scrolling_frame.D.ItemDesc.Visible = true
				end)
				scrolling_frame.D.MouseLeave:Connect(function()
					scrolling_frame.D.ItemDesc.Visible = false
				end)
			else
				scrolling_frame.D.Activated:Connect(function()
					ad_ui.Open()
				end)
			end
		else
			scrolling_frame.D:Destroy()
		end

		if not player_data_folder.Has_Luxury_Pass.Value and not found_bag then
			player_data_folder.Has_Luxury_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				if not scrolling_frame:FindFirstChild("E") then return end
				scrolling_frame.E:Destroy()
			end)
			if user_input_service.MouseEnabled then
				scrolling_frame.E.ItemDesc.Activated:Connect(function()
					ad_ui.Open()
				end)
				scrolling_frame.E.MouseEnter:Connect(function()
					scrolling_frame.E.ItemDesc.Visible = true
				end)
				scrolling_frame.E.MouseLeave:Connect(function()
					scrolling_frame.E.ItemDesc.Visible = false
				end)
			else
				scrolling_frame.E.Activated:Connect(function()
					ad_ui.Open()
				end)
			end
		else
			scrolling_frame.E:Destroy()
		end

		local debounce = false
		background.IslandTeleport.Activated:Connect(function()
			if debounce then return end
			debounce = true
			task.delay(1, function()
				debounce = false
			end)
			if current_island_name.Value == "" then
				background.IslandTeleport.NotArrived.Visible = true
				task.wait(3)
				background.IslandTeleport.NotArrived.Visible = false
				return
			end
			souvenir_teleport:FireServer(true)
		end)

		background.ShipTeleport.Activated:Connect(function()
			souvenir_teleport:FireServer(false)
		end)

		return self
	end)()
end)

task.spawn(function()
	ship_shop_ui = (function()
		if player_gui:FindFirstChild("Loading") then
			player_gui.ChildRemoved:Wait()
		end

		local ship_shop_screen_gui = player_gui:WaitForChild("Ship Shop")
		local self = init_generic_shop(ship_shop_screen_gui)

		local background = ship_shop_screen_gui.Background
		local shop_display_name = background.ShopName
		local owned_image = miscellaneous.OwnedImage
		local buy_souvenir = remotes.Buy_Souvenir

		local default_item = miscellaneous.Shop_Item
		local super_item = default_item:Clone()
		local companion_item = default_item:Clone()

		super_item.ImageColor3 = super_souvenir_color
		companion_item.ImageColor3 = companion_souvenir_color

		local side_background = background["Side Background"]
		local buy_button_background = side_background["Buy Button Background"]
		local buy_button = buy_button_background["Buy Button"]
		local preview_area = side_background["Item Preview Background"]
		local gray_image = preview_area.Gray_Image
		local description = side_background.Description
		local current_ui = "Ship"

		local player_souvenirs = player_data_folder.Souvenirs:GetChildren()

		local base = self.Open
		self.Open = function(ui_to_open)
			if ui_to_open == "SuperShop" then
				shop_display_name.Text = "Super Souvenirs"
			elseif ui_to_open == "CompanionShop" then
				shop_display_name.Text = "Companions"
			else
				shop_display_name.Text = "Souvenirs"
			end
			background[ui_to_open].Visible = true
			if current_ui ~= ui_to_open then
				background[current_ui].Visible = false
			end
			current_ui = ui_to_open
			base()
		end

		local base = self.Close
		self.Close = function()
			selectively_remove_children(preview_area)
			gray_image.Visible = true
			description.Text = ""
			base()
		end

		selectively_remove_children(preview_area)
		gray_image.Visible = true
		description.Text = ""

		for _, souvenir_folder in ipairs(souvenirs_folder:GetChildren()) do

			if background:FindFirstChild(souvenir_folder.Name) then

				local scrolling_frame = background[souvenir_folder.Name]["Items Scrolling Frame"]
				local souvenir_folder_children = souvenir_folder:GetChildren()

				table.sort(souvenir_folder_children, function(a, b)
					return a.Price.Value < b.Price.Value
				end)

				for _, souvenir in ipairs(souvenir_folder_children) do

					local new_item
					if souvenir_names[souvenir.Name] == "Rewards" or souvenir_names[souvenir.Name] == "SuperShop" then
						new_item = super_item:Clone()
					elseif souvenir_names[souvenir.Name] == "CompanionShop" then
						new_item = companion_item:Clone()
					else
						new_item = default_item:Clone()
					end

					new_item["Item Image"].Image = souvenir.ImageID.Value
					new_item["Item Price"].Text = "$"..souvenir.Price.Value
					new_item["Item Name"].Text = souvenir.Name
					new_item.Description.Value = souvenir.Description.Value
					new_item.Name = souvenir.Name

					for _, player_souvenir in pairs(player_souvenirs) do
						if player_souvenir:WaitForChild("ID").Value == souvenir:WaitForChild("ID").Value then -- was erroring, so added wait for child. Will modify if infinite yield occurs.
							owned_image:Clone().Parent = new_item
						end
					end

					new_item.Parent = scrolling_frame

					new_item.Activated:Connect(function()
						if not new_item:FindFirstChild("OwnedImage") then

							selectively_remove_children(preview_area)
							gray_image.Visible = false
							description.Text = new_item.Description.Value

							local stuff_to_preview = new_item:GetChildren()

							for j = 1, #stuff_to_preview do
								local display_obj = stuff_to_preview[j]
								if not display_obj:IsA("ValueBase") then
									display_obj:Clone().Parent = preview_area
								end
							end

						end
					end)

				end

			end
		end

		buy_button.Activated:Connect(function()
			local item_name, item_price = preview_area:FindFirstChild("Item Name"), preview_area:FindFirstChild("Item Price")
			if item_name and item_price then
				if player_cash.Value >= tonumber(item_price.Text:match("%d+")) then
					local success = buy_souvenir:InvokeServer(item_name.Text)
					if success then
						owned_image:Clone().Parent = background[current_ui]["Items Scrolling Frame"][item_name.Text]
						selectively_remove_children(preview_area)
						gray_image.Visible = true
						description.Text = ""
					end
				else
					shop_ui.Open()
				end
			end
		end)

		return self
	end)()
end)

task.spawn(function()
	vehicle_shop_ui = (function()
		local vehicle_shops = player_gui:WaitForChild("Vehicle Shops")
		local self = init_closeable_gui(vehicle_shops)

		local vehicle_uis = vehicle_shops:GetChildren()
		local buy_vehicle = remotes.Buy_Vehicle
		local change_car_color = remotes.Change_Car_Color
		local has_free_cars = player_data_folder.Has_Free_Cars_Pass
		local vehicle_spawn_ui = vehicle_shops.Spawn
		local vehicle_color_ui = vehicle_shops.Color
		local chosen_color_label = vehicle_color_ui.TextLabel

		local current_name = ""
		local selected_color = "NO_CHANGE"
		local last_island_name

		local default_colors = {
			Stagecoach = Color3.fromRGB(109, 91, 79);
			Horse = Color3.fromRGB(27, 42, 53);
			Jeep = Color3.fromRGB(255, 170, 0);
			Buggy = Color3.fromRGB(39, 70, 45);

			["Basic Car"] = Color3.fromRGB(82, 124, 174);
			["Super Car"] = Color3.fromRGB(60, 93, 165);
		}

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

		local base = self.Open
		self.Open = function()
			if last_island_name then
				vehicle_shops[last_island_name].Visible = false
			end
			vehicle_shops[current_island_name.Value].Visible = true
			last_island_name = current_island_name.Value
			base()
		end

		local base = self.Close
		self.Close = function()
			vehicle_spawn_ui.Visible = false
			vehicle_color_ui.Visible = false
			chosen_color_label.Text = "Choose a color"
			vehicle_shops.Close.Visible = true
			selected_color = "NO_CHANGE"
			base()
		end

		local function change_price()
			for _, obj in ipairs(vehicle_shops:GetDescendants()) do
				if obj.Name == "Amount" then
					obj.Text = "Free"
				elseif obj.Name == "Ad" then
					obj.Visible = false
				end
			end
		end

		if has_free_cars.Value then
			change_price()
		end
		has_free_cars:GetPropertyChangedSignal("Value"):Connect(change_price)

		for _, ui in pairs(vehicle_uis) do
			if ui.Name == "Spawn" or ui.Name == "Color" or ui.Name == "Close" then continue end
			for _, button in pairs(ui:GetChildren()) do
				if button:IsA("ImageButton") then
					local debounce = true -- needed debounce cause event was firing twice for no reason
					button.Activated:Connect(function()
						if debounce then
							debounce = false
							ui.Visible = false
							current_name = button.Name
							vehicle_spawn_ui.Visible = true
							vehicle_color_ui.Colors.Default.VehicleColor.BackgroundColor3 = default_colors[button.Name]

							vehicle_spawn_ui.CurrentColor.Text = "Current Color: "..(player_data_folder[current_name.."_Color"].Value)
							vehicle_spawn_ui.Color.Button.BackgroundColor3 = all_color_values[player_data_folder[current_name.."_Color"].Value] or default_colors[current_name]
							vehicle_spawn_ui.Visible = true
							vehicle_color_ui.Visible = false
							vehicle_shops.Close.Visible = false

							change_car_color:FireServer(current_name, selected_color)
							task.wait(0.5)
							debounce = true
						end
					end)
				end
			end
			if ui.Name ~= "Close" then
				ui.Ad.Purchase.Activated:Connect(function()
					if ui.Ad.Visible then
						marketplace_service:PromptGamePassPurchase(player, 10671713)
					end
				end)
			end
		end

		vehicle_spawn_ui.Change.Activated:Connect(function()
			selected_color = "NO_CHANGE"
			vehicle_spawn_ui.Visible = false
			vehicle_color_ui.Visible = true
			vehicle_shops.Close.Visible = false
		end)

		for _, button in ipairs(vehicle_color_ui.Colors:GetChildren()) do
			local button = button:FindFirstChild("VehicleColor")
			if button then
				button.Activated:Connect(function()
					selected_color = button.Parent.Name
					chosen_color_label.Text = button.Parent.Name
				end)
			end
		end

		vehicle_color_ui.Purchase.Activated:Connect(function()
			if selected_color == "NO_CHANGE" or selected_color == player_data_folder[current_name.."_Color"].Value then
				vehicle_spawn_ui.Visible = true
				vehicle_color_ui.Visible = false
				return
			end
			change_car_color:FireServer(current_name, selected_color)
			marketplace_service:PromptProductPurchase(player, 1269958304)
		end)

		vehicle_spawn_ui.Purchase.Activated:Connect(function()
			buy_vehicle:FireServer(current_name, selected_color)
			self.Close()
		end)

		vehicle_color_ui.Close.Activated:Connect(function()
			vehicle_spawn_ui.Visible = true
			vehicle_color_ui.Visible = false
			selected_color = "NO_CHANGE"
		end)

		change_car_color.OnClientEvent:Connect(function()
			vehicle_spawn_ui.CurrentColor.Text = "Current Color: "..(selected_color ~= "NO_CHANGE" and selected_color or player_data_folder[current_name.."_Color"].Value)
			local color3_value
			if selected_color == "NO_CHANGE" then
				color3_value = all_color_values[player_data_folder[current_name.."_Color"].Value] or default_colors[current_name]
			elseif all_color_values[selected_color] then
				color3_value = all_color_values[selected_color]
			else
				color3_value = default_colors[current_name]
			end
			vehicle_spawn_ui.Color.Button.BackgroundColor3 = color3_value
			vehicle_spawn_ui.Visible = true
			vehicle_color_ui.Visible = false
		end)

		remotes:WaitForChild("RemoteSpawn").OnClientEvent:Connect(function()
			self.Open()
		end)

		return self
	end)()
end)

task.spawn(function()
	ice_cream_shop_ui = (function()

		local ice_cream_shop = player_gui:WaitForChild("IceCream Shop")
		local self = init_closeable_gui(ice_cream_shop)

		local get_cone = remotes.Get_Cone
		local ice_cream_shop = player_gui:WaitForChild("IceCream Shop")
		local main = ice_cream_shop:WaitForChild("Main")
		local close = main.Close
		local flavors = main.Flavors.ScrollingFrame

		local preview = main.Preview
		local real_view = preview.Real
		local viewable_model = real_view.IC
		local example_segments = viewable_model:GetChildren()

		local create_button = main.Create
		local create_button_text = create_button.TextLabel

		local clear_button = main.Clear
		local camera = Instance.new("Camera")
		local camera_position = viewable_model.Cone.Position + Vector3.new(0, 0.5, -2)
		local current_cone = {}

		local function clear_cone_ui()
			for _, obj in pairs(example_segments) do
				if obj.Name ~= "Cone" then
					obj.Transparency = 1
				end
			end
			current_cone = {}
			create_button_text.Text = "Create: $0"
		end

		local base = self.Close
		self.Close = function()
			clear_cone_ui()
			base()
		end

		camera.Parent = real_view
		camera.CFrame = CFrame.new(camera_position, viewable_model.F1.Position)
		real_view.CurrentCamera = camera

		for _, gui_button in pairs(flavors:GetChildren()) do
			if gui_button:IsA("TextButton") then
				gui_button.Activated:Connect(function()
					for i = 1, 3 do
						if viewable_model["F"..i].Transparency == 1 then
							for _, segment in pairs(viewable_model:GetChildren()) do
								if segment.Name:match(tostring(i)) then
									segment.Color = gui_button.BackgroundColor3
									segment.Transparency = 0
								end
							end
							current_cone[i] = gui_button.BackgroundColor3
							create_button_text.Text = "Create: $"..(10*i)
							break
						end
					end
				end)
			end
		end

		clear_button.Activated:Connect(clear_cone_ui)

		create_button.Activated:Connect(function()
			if player_cash.Value >= tonumber(create_button_text.Text:match("%d+")) then
				get_cone:FireServer(current_cone)
			else
				shop_ui.Open()
			end
			clear_cone_ui()
		end)

		return self

	end)()
end)

update_cash_displays()
player_cash:GetPropertyChangedSignal("Value"):Connect(update_cash_displays)

disable_ui.Event:Connect(function(disable)
	if disable then
		close_open_guis(true)
	else
		hide_button.Open()
	end
end)

task.spawn(function() -- default category = hats, so should change to make that happen...
	avatar_ui = (function()

		local avatar_ui = player_gui:WaitForChild("EditAvatar")
		local editor = avatar_ui
		local self = {}

		local Players = game:GetService("Players")
		local StarterGui = game:GetService("StarterGui")
		local AssetService = game:GetService("AssetService")
		local UserInputService = game:GetService("UserInputService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local MarketplaceService = game:GetService("MarketplaceService")
		local AvatarEditorService = game:GetService("AvatarEditorService")

		local Janitor = require(ReplicatedStorage.Client_Accessible_Modules.Janitor)
		local Slider = require(ReplicatedStorage.Client_Accessible_Modules.slidermodule)
		local Distort = require(ReplicatedStorage.Client_Accessible_Modules.distort)
		local DescriptionUI = require(ReplicatedStorage.Client_Accessible_Modules.DescriptionUI)

		local outfits = nil
		local currentPage = 0
		local currentResults = nil
		local accessoryLimit = 15
		local currentCategory = ""
		local currentSearchString = ""
		local currentDescription = nil
		local starterDescription = nil
		local currentSuperCategory = ""
		local scrollingRefreshDebounce = false

		local player = Players.LocalPlayer
		local scaleObliterator = Janitor.new()
		local slotsObliterator = Janitor.new()
		local wearingObliterator = Janitor.new()
		local outfitsObliterator = Janitor.new()
		local bundleDetailsObliterator = Janitor.new()
		local mainDisplayFrameObliterator = Janitor.new()

		local slotTemplate = editor.Main.Slots.Template:Clone()
		local itemTemplate = editor.Main.MainFrame.Items.Template:Clone()
		local bundleTemplate = editor.Main.BundleFrame.Items.Template:Clone()
		local outfitTemplate = editor.Main.OutfitsFrame.Items.Template:Clone()

		local addOutfit = ReplicatedStorage.Remotes.AddOutfit
		local getOutfits = ReplicatedStorage.Remotes.GetOutfits
		local deleteOutfit = ReplicatedStorage.Remotes.DeleteOutfit
		local updateOutfit = ReplicatedStorage.Remotes.UpdateOutfit
		local saveDescription = ReplicatedStorage.Remotes.SaveDescription
		local resetDescription = ReplicatedStorage.Remotes.ResetDescription
		local applyDescription = ReplicatedStorage.Remotes.ApplyDescription
		
		local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		
		local websiteDescriptionFound, websiteDescription = pcall(Players.GetHumanoidDescriptionFromUserId, Players, player.UserId)
		if not websiteDescriptionFound then
			websiteDescription = nil
		end

		local enumLookupTable = {
			Enum.AccessoryType.Hat,
			Enum.AccessoryType.Hair,
			Enum.AccessoryType.Face,
			Enum.AccessoryType.Neck,
			Enum.AccessoryType.Shoulder,
			Enum.AccessoryType.Front,
			Enum.AccessoryType.Back,
			Enum.AccessoryType.Waist,
			Enum.AccessoryType.TShirt,
			Enum.AccessoryType.Shirt,
			Enum.AccessoryType.Pants,
			Enum.AccessoryType.Jacket,
			Enum.AccessoryType.Sweater,
			Enum.AccessoryType.Shorts,
			Enum.AccessoryType.LeftShoe,
			Enum.AccessoryType.RightShoe,
			Enum.AccessoryType.DressSkirt,
		}

		local accessoryTypeRemaps = {
			["3DDress"] = Enum.AccessoryType.DressSkirt,
			["3DLeftShoe"] = Enum.AccessoryType.LeftShoe,
			["3DPants"] = Enum.AccessoryType.Pants,
			["3DRightShoe"] = Enum.AccessoryType.RightShoe,
			["3DShorts"] = Enum.AccessoryType.Shorts,

			["LeftShoeAccessory"] = Enum.AccessoryType.LeftShoe,
			["RightShoeAccessory"] = Enum.AccessoryType.RightShoe,

			["3DJacket"] = Enum.AccessoryType.Jacket,
			["3DShirt"] = Enum.AccessoryType.Shirt,
			["3DSweater"] = Enum.AccessoryType.Sweater,
			["3DTShirt"] = Enum.AccessoryType.TShirt,

			["BackAccessory"] = Enum.AccessoryType.Back,
			["FaceAccessory"] = Enum.AccessoryType.Face,
			["FrontAccessory"] = Enum.AccessoryType.Front,
			["HairAccessory"] = Enum.AccessoryType.Hair,
			["HatAccessory"] = Enum.AccessoryType.Hat,
			["NeckAccessory"] = Enum.AccessoryType.Neck,
			["ShouldersAccessory"] = Enum.AccessoryType.Shoulder,
			["WaistAccessory"] = Enum.AccessoryType.Waist,
		}

		local bodyParts = {
			Face = true,
			Head = true,
			LeftArm = true,
			LeftLeg = true,
			RightArm = true,
			RightLeg = true,
			Torso = true,
		}

		local animationCategories = {
			ClimbAnimation = true,
			FallAnimation = true,
			IdleAnimation = true,
			JumpAnimation = true,
			MoodAnimation = true,
			RunAnimation = true,
			SwimAnimation = true,
			WalkAnimation = true,
		}

		local avatarAssetTypeRemaps = {
			["ShouldersAccessory"] = Enum.AvatarAssetType.ShoulderAccessory,

			["3DDress"] = Enum.AvatarAssetType.DressSkirtAccessory,
			["3DLeftShoe"] = Enum.AvatarAssetType.LeftShoeAccessory,
			["3DPants"] = Enum.AvatarAssetType.PantsAccessory,
			["3DRightShoe"] = Enum.AvatarAssetType.RightShoeAccessory,
			["3DShorts"] = Enum.AvatarAssetType.ShortsAccessory,

			["3DJacket"] = Enum.AvatarAssetType.JacketAccessory,
			["3DShirt"] = Enum.AvatarAssetType.ShirtAccessory,
			["3DSweater"] = Enum.AvatarAssetType.SweaterAccessory,
			["3DTShirt"] = Enum.AvatarAssetType.TShirtAccessory,
		}

		local assetTypeIdRemaps = {}

		local colors = {
			Color3.fromRGB(90, 76, 66),
			Color3.fromRGB(124, 92, 70),
			Color3.fromRGB(175, 148, 131),
			Color3.fromRGB(204, 142, 105),
			Color3.fromRGB(234, 184, 146),
			Color3.fromRGB(86, 66, 54),
			Color3.fromRGB(105, 64, 40),
			Color3.fromRGB(188, 155, 93),
			Color3.fromRGB(199, 172, 120),
			Color3.fromRGB(215, 197, 154),
			Color3.fromRGB(149, 121, 119),
			Color3.fromRGB(163, 75, 75),
			Color3.fromRGB(218, 134, 122),
			Color3.fromRGB(255, 201, 201),
			Color3.fromRGB(255, 152, 220),
			Color3.fromRGB(116, 134, 157),
			Color3.fromRGB(82, 124, 174),
			Color3.fromRGB(128, 187, 220),
			Color3.fromRGB(177, 167, 255),
			Color3.fromRGB(167, 94, 155),
			Color3.fromRGB(0, 143, 156),
			Color3.fromRGB(91, 154, 76),
			Color3.fromRGB(124, 156, 107),
			Color3.fromRGB(161, 196, 140),
			Color3.fromRGB(226, 155, 64),
			Color3.fromRGB(245, 205, 48),
			Color3.fromRGB(248, 217, 109),
			Color3.fromRGB(17, 17, 17),
			Color3.fromRGB(99, 95, 98),
			Color3.fromRGB(205, 205, 205),
			Color3.fromRGB(248, 248, 248),
		}

		local colorFields = {
			"HeadColor",
			"LeftArmColor",
			"LeftLegColor",
			"RightArmColor",
			"RightLegColor",
			"TorsoColor",
		}

		local debounces = {
			close = false, -- don't want them to double click the close button
			search = false, -- not too many searches in a short period of time
			itemSelect = false, -- not too many equip / unequip
			openBundle = false, -- don't open bundles or animations too close together
			changeCategory = false, -- not too many category changes in a short period of time

			reset = false,
			removeAll = false,
			outfitAdd = false,
			outfitApply = false,
			outfitDelete = false,
			outfitUpdate = false,
			
			IDSubmit = false,
		}

		local function getAdjustedCameraAngle(angle: Vector2)
			return CFrame.Angles(0, math.rad(angle.X), 0)
				* CFrame.Angles(0, math.rad(angle.Y), 0)
				* CFrame.Angles(0, math.pi, 0)
				* CFrame.new(Vector3.new(0, 0, 6))
		end

		local function deepCopy(original)
			local copy = {}

			for k, v in pairs(original) do
				if type(v) == "table" then
					v = deepCopy(v)
				end

				copy[k] = v
			end

			return copy
		end

		local function setCategoryColor(categoryName: string, color: Color3)
			if #categoryName == 0 then
				return
			end

			if categoryName == "Pants" then
				editor.Main.PantsFrame.Pants.ImageColor3 = color
			elseif categoryName == "Shirt" then
				editor.Main.ShirtFrame.Shirt.ImageColor3 = color
			else
				editor.Main:FindFirstChild(categoryName, true).ImageColor3 = color
			end
		end

		local function serializeHumanoidDescription(description: HumanoidDescription)
			return {
				Accessories = description:GetAccessories(true),
				Animations = {
					ClimbAnimation = description.ClimbAnimation,
					FallAnimation = description.FallAnimation,
					IdleAnimation = description.IdleAnimation,
					JumpAnimation = description.JumpAnimation,
					MoodAnimation = description.MoodAnimation,
					RunAnimation = description.RunAnimation,
					SwimAnimation = description.SwimAnimation,
					WalkAnimation = description.WalkAnimation,
				},
				Scales = {
					HeightScale = math.clamp(description.HeightScale, 0.75, 1.25),
					WidthScale = math.clamp(description.WidthScale, 0.7, 1),
					HeadScale = math.clamp(description.HeadScale, 0.75, 1.25),
					BodyTypeScale = math.clamp(description.BodyTypeScale, 0, 1),
					ProportionScale = math.clamp(description.ProportionScale, 0, 1),
					DepthScale = math.clamp(description.DepthScale, 0.7, 1),
				},
				Colors = {
					HeadColor = { description.HeadColor.R, description.HeadColor.G, description.HeadColor.B },
					LeftArmColor = { description.LeftArmColor.R, description.LeftArmColor.G, description.LeftArmColor.B },
					LeftLegColor = { description.LeftLegColor.R, description.LeftLegColor.G, description.LeftLegColor.B },
					RightArmColor = { description.RightArmColor.R, description.RightArmColor.G, description.RightArmColor.B },
					RightLegColor = { description.RightLegColor.R, description.RightLegColor.G, description.RightLegColor.B },
					TorsoColor = { description.TorsoColor.R, description.TorsoColor.G, description.TorsoColor.B },
				},
				BodyParts = {
					Face = description.Face,
					Head = description.Head,
					LeftArm = description.LeftArm,
					LeftLeg = description.LeftLeg,
					RightArm = description.RightArm,
					RightLeg = description.RightLeg,
					Torso = description.Torso,
				},
				GraphicTShirt = description.GraphicTShirt,
				Shirt = description.Shirt,
				Pants = description.Pants,
			}
		end

		local function deserializeHumanoidDescription(serializedHumanoidDescription: { [string]: any }): HumanoidDescription
			local serialized = table.clone(serializedHumanoidDescription)
			local description = Instance.new("HumanoidDescription")

			for i = #serialized.Accessories, 16, -1 do
				table.remove(serialized.Accessories)
			end

			description:SetAccessories(serialized.Accessories, true)

			for animationCategory, animationId in pairs(serialized.Animations) do
				description[animationCategory] = animationId
			end

			for scaleCategory, scale in pairs(serialized.Scales) do
				description[scaleCategory] = scale
			end

			for colorCategory, color in pairs(serialized.Colors) do
				description[colorCategory] = Color3.new(table.unpack(color))
			end

			for bodyPartCategory, bodyPartId in pairs(serialized.BodyParts) do
				description[bodyPartCategory] = bodyPartId
			end

			description.GraphicTShirt = serialized.GraphicTShirt
			description.Shirt = serialized.Shirt
			description.Pants = serialized.Pants

			return description
		end

		local function deserializeFromDataStore(serializedHumanoidDescription)
			local deserialized = deepCopy(serializedHumanoidDescription)
			for _, accessory in deserialized.Accessories do
				accessory.AccessoryType = enumLookupTable[accessory.AccessoryType]
			end
			return deserialized
		end

		local function fullDeserialize(serializedHumanoidDescription)
			return deserializeHumanoidDescription(deserializeFromDataStore(serializedHumanoidDescription))
		end

		-- local function clearDisplayFrame(frame: ScrollingFrame)
		--      for _, itemDisplay in ipairs(frame:GetChildren()) do
		--              if itemDisplay:IsA("ImageLabel") then
		--                      itemDisplay:Destroy()
		--              end
		--      end
		-- end

		local function closeAllFrames()
			slotsObliterator:Cleanup()
			scaleObliterator:Cleanup()
			wearingObliterator:Cleanup()
			outfitsObliterator:Cleanup()
			bundleDetailsObliterator:Cleanup()
			mainDisplayFrameObliterator:Cleanup()
			for _, element in ipairs(editor.Main:GetChildren()) do
				if element.Name:match("Frame") then
					element.Visible = false
				end
			end
		end

		local function resetUI()
			closeAllFrames()

			currentPage = 0
			currentResults = nil

			editor.Main.AccessoryFrame.Visible = true
			editor.Main.MainFrame.Visible = true
			editor.Main.MainFrame.Search.Text = ""
		end

		local function getItemIndex(list: { { [string]: any } }, itemId: number): number?
			for index, equippedItem in ipairs(list) do
				if equippedItem.AssetId == itemId then
					return index
				end
			end
			return nil
		end

		local function hasItemEquipped(description: HumanoidDescription, itemId: number): boolean
			if getItemIndex(description:GetAccessories(true), itemId) then
				return true
			end

			for bodyPartType in pairs(bodyParts) do
				if description[bodyPartType] == itemId then
					return true
				end
			end

			for animationCategory in pairs(animationCategories) do
				if description[animationCategory] == itemId then
					return true
				end
			end

			return tonumber(description.Pants) == itemId
				or tonumber(description.Shirt) == itemId
				or tonumber(description.GraphicTShirt) == itemId
				or tonumber(description.Face) == itemId
		end

		local function fixOrderFromIndex(list: { { [string]: any } }, index: number)
			for i = index, #list do
				if list[i].Order then
					list[i].Order -= 1
				end
			end
		end

		local function unequipItem(description: HumanoidDescription, itemId: number, skipApply: boolean?)
			local accessories = description:GetAccessories(true)
			local slotDisplay = editor.Main.Slots:FindFirstChild(itemId)
			local itemDisplay = editor.Main.MainFrame.Items:FindFirstChild(itemId)
			local itemIndex = getItemIndex(accessories, itemId)

			if itemIndex then
				table.remove(accessories, itemIndex)
				fixOrderFromIndex(accessories, itemIndex)
				description:SetAccessories(accessories, true)
			else
				for bodyPartType in pairs(bodyParts) do
					if description[bodyPartType] == itemId then
						description[bodyPartType] = 0
					end
				end

				for animationCategory in pairs(animationCategories) do
					if description[animationCategory] == itemId then
						description[animationCategory] = 0
					end
				end
				
				if description.Pants == itemId then
					description.Pants = 868697782
				elseif description.Shirt == itemId then
					description.Shirt = 868697637
				elseif description.GraphicTShirt == itemId then
					description.GraphicTShirt = 0
				elseif description.Face == itemId then
					description.Face = 144075659
				end
			end

			if slotDisplay then
				slotDisplay:Destroy()
			end

			if itemDisplay then
				itemDisplay.Equipped.Visible = false
			end
			
			if not skipApply then
				applyDescription:FireServer(serializeHumanoidDescription(description))
			end
		end

		local function createSlotForItem(itemId: number)
			if editor.Main.Slots:FindFirstChild(itemId) then
				return
			end

			local slotDisplay = slotTemplate:Clone()

			slotDisplay.Item.Image = `rbxthumb://type=Asset&id={itemId}&w=150&h=150`
			slotDisplay.Name = itemId
			slotDisplay.Parent = editor.Main.Slots
			slotsObliterator:Add(slotDisplay)

			slotDisplay.Item.Activated:Connect(function()
				if debounces.itemSelect then
					return
				end
				debounces.itemSelect = true
				task.delay(0.5, function()
					debounces.itemSelect = false
				end)

				unequipItem(currentDescription, itemId)
			end)
		end

		local function getMapOfEquippedItemsFromCategory(category: string, description: HumanoidDescription)
			if category == "Pants" or category == "Shirt" or category == "GraphicTShirt" or category == "Face" then
				return { [description[category]] = true }
			end

			local equippedMap = {}
			if category:match("Accessory") then
				if description[category] == "" then
					return equippedMap
				end

				for _, stringId in ipairs((description[category] :: string):split(",")) do
					equippedMap[tonumber(stringId)] = true
				end

				return equippedMap
			end

			for _, item in ipairs(description:GetAccessories(false)) do
				if item.AccessoryType == accessoryTypeRemaps[category] then
					equippedMap[item.AssetId] = true
				end
			end

			return equippedMap
		end

		local function getAllEquippedItems(description: HumanoidDescription)
			local list = description:GetAccessories(true)

			if description.Pants > 0 then
				table.insert(list, { AssetId = description.Pants })
			end

			if description.Shirt > 0 then
				table.insert(list, { AssetId = description.Shirt })
			end

			if description.GraphicTShirt > 0 then
				table.insert(list, { AssetId = description.GraphicTShirt })
			end

			if description.Face > 0 then
				table.insert(list, { AssetId = description.Face })
			end

			for bodyPartType in pairs(bodyParts) do
				if description[bodyPartType] and description[bodyPartType] ~= 0 then
					table.insert(list, { AssetId = description[bodyPartType] })
				end
			end

			for animationCategory in pairs(animationCategories) do
				if description[animationCategory] and description[animationCategory] ~= 0 then
					table.insert(list, { AssetId = description[animationCategory] })
				end
			end

			return list
		end

		local function displayColors()
			for _, color in ipairs(colors) do
				local colorDisplay = itemTemplate:Clone()

				colorDisplay.ImageColor3 = color

				colorDisplay.Item.Activated:Connect(function()
					if debounces.itemSelect then
						return
					end
					debounces.itemSelect = true
					task.delay(0.5, function()
						debounces.itemSelect = false
					end)

					for _, colorField in ipairs(colorFields) do
						currentDescription[colorField] = color
					end
					applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
				end)

				colorDisplay.Parent = editor.Main.MainFrame.Items
				mainDisplayFrameObliterator:Add(colorDisplay)
			end
		end

		local function displayCurrentlyWearing()
			local duplicates = {}
			for _, item in ipairs(getAllEquippedItems(currentDescription)) do
				local itemDisplay = itemTemplate:Clone()
				
				if duplicates[item.AssetId] then
					continue
				end
				duplicates[item.AssetId] = true

				itemDisplay.Name = item.AssetId
				itemDisplay.Item.Image = `rbxthumb://type=Asset&id={item.AssetId}&w=150&h=150`

				itemDisplay.Item.Activated:Connect(function()
					if debounces.itemSelect then
						return
					end
					debounces.itemSelect = true
					task.delay(0.5, function()
						debounces.itemSelect = false
					end)

					unequipItem(currentDescription, item.AssetId)
					itemDisplay:Destroy()
				end)

				itemDisplay.Parent = editor.Main.WearingFrame.Items
				wearingObliterator:Add(itemDisplay)
			end
		end

		local function updateOutfitDisplay(outfitDisplay, outfit)
			if not outfitDisplay:FindFirstChild("Character") then
				return
			end
			
			local camera = Instance.new("Camera")
			local characterDisplay = Players:CreateHumanoidModelFromDescription(outfit, Enum.HumanoidRigType.R15)

			camera.CFrame = characterDisplay.Humanoid.RootPart.CFrame * getAdjustedCameraAngle(Vector2.new())
			camera.Parent = outfitDisplay.Character

			outfitDisplay.Character.CurrentCamera = camera
			characterDisplay.Parent = outfitDisplay.Character.WorldModel
			characterDisplay.Humanoid:ApplyDescription(outfit)

			task.spawn(function()
				local angle = Vector2.new()
				while outfitDisplay.Parent do
					angle = angle + Vector2.new(0.5, 0)
					outfitDisplay.Character.CurrentCamera.CFrame = outfitDisplay.Character.WorldModel:FindFirstChildWhichIsA(
						"Model"
					).Humanoid.RootPart.CFrame * getAdjustedCameraAngle(angle)
					task.wait()
				end
			end)

			outfitDisplay.Delete.Activated:Connect(function()
				if debounces.outfitDelete then
					return
				end
				debounces.outfitDelete = true
				task.delay(0.5, function()
					debounces.outfitDelete = false
				end)

				deleteOutfit:FireServer(table.find(outfits, outfit))
				table.remove(outfits, table.find(outfits, outfit))
				outfitDisplay:Destroy()
			end)

			outfitDisplay.Update.Activated:Connect(function()
				if debounces.outfitUpdate then
					return
				end
				debounces.outfitUpdate = true
				task.delay(0.5, function()
					debounces.outfitUpdate = false
				end)

				local i = table.find(outfits, outfit)
				updateOutfit:FireServer(i, serializeHumanoidDescription(currentDescription))
				outfits[i] = currentDescription:Clone()
				outfit = outfits[i]
				local characterClone = outfitDisplay.Character.WorldModel:FindFirstChildWhichIsA("Model")
					or player.Character:Clone()
				characterClone.Parent = outfitDisplay.Character.WorldModel
				characterClone.Humanoid:ApplyDescription(currentDescription)
			end)

			outfitDisplay.Activated:Connect(function()
				if debounces.outfitApply then
					return
				end
				debounces.outfitApply = true
				task.delay(0.5, function()
					debounces.outfitApply = false
				end)

				applyDescription:FireServer(serializeHumanoidDescription(outfit))
				currentDescription = outfit:Clone()
			end)
		end

		local function displayOutfits()
			for _, outfit in ipairs(outfits) do
				local outfitDisplay = outfitTemplate:Clone()
				outfitsObliterator:Add(outfitDisplay)
				outfitDisplay.Parent = editor.Main.OutfitsFrame.Items

				updateOutfitDisplay(outfitDisplay, outfit)
			end
		end

		local function displayResultsInFrame(frame: ScrollingFrame)
			
			if not currentResults then
				return
			end
			
			local currentlySelected = nil
			local page = currentResults:GetCurrentPage()
			local missingSlots = getMapOfEquippedItemsFromCategory(currentCategory, currentDescription)

			currentPage += 1

			for _, item in ipairs(page) do
				local itemDisplay = itemTemplate:Clone()

				itemDisplay.Name = item.Id
				itemDisplay.Item.Image = `rbxthumb://type=Asset&id={item.Id}&w=150&h=150`

				if hasItemEquipped(currentDescription, item.Id) then
					currentlySelected = itemDisplay
					itemDisplay.Equipped.Visible = true
					createSlotForItem(item.Id)
					missingSlots[item.Id] = nil
				end

				itemDisplay.Item.Activated:Connect(function()
					if debounces.itemSelect then
						return
					end
					debounces.itemSelect = true
					task.delay(0.5, function()
						debounces.itemSelect = false
					end)

					if currentCategory == "Shirt" or currentCategory == "Pants" or currentCategory == "GraphicTShirt" or currentCategory == "Face" then
						slotsObliterator:Cleanup()
						if hasItemEquipped(currentDescription, item.Id) then
							currentDescription[currentCategory] = 0
							itemDisplay.Equipped.Visible = false
							applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
							return
						end
						if currentlySelected then
							currentlySelected.Equipped.Visible = false
						end
						currentlySelected = itemDisplay
						createSlotForItem(item.Id)
						itemDisplay.Equipped.Visible = true
						currentDescription[currentCategory] = item.Id
						applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
						return
					end

					local accessories = currentDescription:GetAccessories(true)
					local itemIndex = getItemIndex(accessories, item.Id)

					if itemIndex then
						unequipItem(currentDescription, item.Id)
						return
					elseif #accessories < accessoryLimit then
						table.insert(accessories, {
							AssetId = item.Id,
							IsLayered = if accessoryTypeRemaps[currentCategory] then true else false,
							AccessoryType = accessoryTypeRemaps[currentCategory] or Enum.AccessoryType[currentCategory],
							Order = if accessoryTypeRemaps[currentCategory]
								then #currentDescription:GetAccessories(false) + 1
								else nil,
						})
						itemDisplay.Equipped.Visible = true
						createSlotForItem(item.Id)
					end

					currentDescription:SetAccessories(accessories, true)
					applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
				end)

				mainDisplayFrameObliterator:Add(itemDisplay)
				itemDisplay.Parent = frame
			end

			if currentPage == 1 then
				for itemId in pairs(missingSlots) do
					createSlotForItem(itemId)
				end
			end
		end

		local function displayBundles()
			local page = currentResults:GetCurrentPage()

			for _, bundle in ipairs(page) do
				local bundleDisplay = itemTemplate:Clone()

				bundleDisplay.Name = bundle.Id
				bundleDisplay.Item.Image = `rbxthumb://type=BundleThumbnail&id={bundle.Id}&w=150&h=150`

				bundleDisplay.Item.Activated:Connect(function()
					if debounces.openBundle then
						return
					end
					debounces.openBundle = true
					task.delay(0.5, function()
						debounces.openBundle = false
					end)	

					local success, bundleDetails = pcall(AssetService.GetBundleDetailsAsync, AssetService, bundle.Id)
					if not success then
						return
					end

					bundleDetailsObliterator:Cleanup()

					for _, item in ipairs(bundleDetails.Items) do
						if item.Type ~= "Asset" then
							continue
						end

						local bundleItemDisplay = bundleTemplate:Clone()
						if hasItemEquipped(currentDescription, item.Id) then
							bundleItemDisplay.Equipped.Visible = true
						end

						bundleItemDisplay.Item.Activated:Connect(function()
							if debounces.itemSelect then
								return
							end
							debounces.itemSelect = true
							task.delay(0.5, function()
								debounces.itemSelect = false
							end)

							local assetType = assetTypeIdRemaps[MarketplaceService:GetProductInfo(item.Id).AssetTypeId]
							local accessories = getAllEquippedItems(currentDescription)
							local itemIndex = getItemIndex(accessories, item.Id)

							if assetType == "DynamicHead" then
								--bundleItemDisplay:Destroy()
								--return
								assetType = "Head"
							end

							if itemIndex then
								unequipItem(currentDescription, item.Id)
								bundleItemDisplay.Equipped.Visible = false
								return
							elseif bodyParts[assetType] or animationCategories[assetType] then
								currentDescription[assetType] = item.Id
							elseif #accessories < accessoryLimit then
								table.insert(accessories, {
									AssetId = item.Id,
									IsLayered = if accessoryTypeRemaps[assetType] then true else false,
									AccessoryType = accessoryTypeRemaps[assetType] or Enum.AccessoryType[assetType],
									Order = if accessoryTypeRemaps[assetType]
										then #currentDescription:GetAccessories(false) + 1
										else nil,
								})
							end

							bundleItemDisplay.Equipped.Visible = true
							currentDescription:SetAccessories(accessories, true)
							applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
						end)

						bundleItemDisplay.Item.Image = `rbxthumb://type=Asset&id={item.Id}&w=150&h=150`
						bundleItemDisplay.Parent = editor.Main.BundleFrame.Items
						bundleDetailsObliterator:Add(bundleItemDisplay)
					end

					editor.Main.BundleFrame.Visible = true
				end)

				bundleDetailsObliterator:Add(function()
					editor.Main.BundleFrame.Visible = false
				end, true)

				bundleDisplay.Parent = editor.Main.MainFrame.Items
				mainDisplayFrameObliterator:Add(bundleDisplay)
			end
			mainDisplayFrameObliterator:Add(function()
				bundleDetailsObliterator:Cleanup()
			end, true)
		end

		local function search(text: string?): CatalogPages
			local searchParameters = CatalogSearchParams.new()

			searchParameters.Limit = 60

			if currentCategory == "Bundles" then
				searchParameters.BundleTypes = { Enum.BundleType.BodyParts }
			elseif currentCategory == "3DLeftShoe" or currentCategory == "3DRightShoe" then
				searchParameters.BundleTypes = { Enum.BundleType.Shoes }
			elseif currentCategory == "Animations" then
				searchParameters.BundleTypes = { Enum.BundleType.Animations }
			elseif currentCategory == "Head" then
				searchParameters.BundleTypes = { Enum.BundleType.DynamicHead }
			else
				searchParameters.AssetTypes =
					{ avatarAssetTypeRemaps[currentCategory] or Enum.AvatarAssetType[currentCategory] }
			end

			if text then
				searchParameters.SearchKeyword = text
			end

			return AvatarEditorService:SearchCatalog(searchParameters)
		end

		local function openCategory(categoryName: string, searchString: string)
			if currentCategory == categoryName and searchString == currentSearchString then
				return
			end
			
			editor.Main.MainFrame.Loading.Visible = false

			setCategoryColor(currentCategory, Color3.fromRGB(255, 255, 255))
			setCategoryColor(categoryName, Color3.fromRGB(197, 197, 197))

			currentCategory = categoryName

			local scrollingFrame = editor.Main.MainFrame.Items

			slotsObliterator:Cleanup()
			wearingObliterator:Cleanup()
			outfitsObliterator:Cleanup()
			mainDisplayFrameObliterator:Cleanup()

			currentSearchString = searchString
			
			local success
			success, currentResults = pcall(search, searchString)
			
			if not success then
				editor.Main.MainFrame.Loading.Visible = true
				return
			end
			
			mainDisplayFrameObliterator:Add(function()
				currentPage = 0
				currentResults = nil
				currentSearchString = ""
				scrollingFrame.CanvasPosition = Vector2.new(0, 0)
			end, true)

			if
				currentCategory == "Bundles"
				or currentCategory == "Animations"
				or currentCategory == "3DLeftShoe"
				or currentCategory == "3DRightShoe"
				or currentCategory == "Head"
			then
				displayBundles()
			else
				displayResultsInFrame(scrollingFrame)
			end

			mainDisplayFrameObliterator:Add(
				editor.Main.MainFrame.Items:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
					if
						scrollingFrame.AbsoluteWindowSize.Y * scrollingFrame.CanvasSize.Y.Scale
						+ scrollingFrame.CanvasPosition.Y
						>= scrollingFrame.AbsoluteCanvasSize.Y - 4
						and not scrollingRefreshDebounce
						and currentResults
						and currentCategory == categoryName
					then
						scrollingRefreshDebounce = true

						local success = pcall(currentResults.AdvanceToNextPageAsync, currentResults)
						
						if success then
							if currentCategory == "Bundles" or currentCategory == "Animations" then
								displayBundles()
							else
								displayResultsInFrame(scrollingFrame)
							end
						end
						
						if isMobile then
							task.wait(2)
						else
							task.wait(0.5)
						end
						
						scrollingRefreshDebounce = false
					end
				end)
			)
		end

		-- local sliderStartX, sliderEndX = -0.015, 0.905

		local function handleScaleSlider(slider)
			local sliderConfig = {
				snapFactor = 0.001,
			}
			local extras = {
				DefaultValue = math.round(100*currentDescription[`{slider.Parent.Parent.Name}Scale`]),
				TextBox = slider.Parent.Parent.Percentage
			}
			if slider.Parent.Parent.Name == "Height" or slider.Parent.Parent.Name == "Head" then
				sliderConfig.min = 75
				sliderConfig.max = 125
			elseif slider.Parent.Parent.Name == "Width" or slider.Parent.Parent.Name == "Depth" then
				sliderConfig.min = 70
				sliderConfig.max = 100
			else
				sliderConfig.min = 0
				sliderConfig.max = 100
			end
			
			local newSlider = Slider.new(slider.Parent, slider, slider.Button, sliderConfig, extras)
			
			newSlider.InteractionEnded.Event:Connect(function(lastValue)
				if currentDescription[`{slider.Parent.Parent.Name}Scale`] == lastValue/100 then
					return
				end
				
				currentDescription[`{slider.Parent.Parent.Name}Scale`] = lastValue/100
				applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
			end)
			
			newSlider:Activate()

			scaleObliterator:Add(function()
				newSlider:Deactivate()
			end, true)
		end

		local function handleCategoryButton(button: GuiBase, obliterator: typeof(Janitor.new()))
			if not button:IsA("GuiButton") then
				return
			end
			obliterator:Add(button.Activated:Connect(function()
				if debounces.changeCategory then
					return
				end
				debounces.changeCategory = true
				task.delay(0.5, function()
					debounces.changeCategory = false
				end)

				if currentCategory == "Scale" then
					editor.Main.ScaleFrame.Visible = false
					editor.Main.MainFrame.Visible = true		
				end

				editor.Main.MainFrame.Search.Text = ""
				openCategory(button.Name, "")
			end))
		end

		local function closeEditor(obliterator: typeof(Janitor.new()))
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
			obliterator:Cleanup()
			player.Character.Archivable = false
			editor.Enabled = false
		end

		local function openEditor(obliterator: typeof(Janitor.new()))
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			editor.Enabled = true

			player.Character.Archivable = true
			currentDescription = player.Character.Humanoid:GetAppliedDescription()
			starterDescription = currentDescription:Clone()
			websiteDescription = websiteDescription or starterDescription

			resetUI()

			for _, button in ipairs(editor.Main.AccessoryFrame:GetChildren()) do
				handleCategoryButton(button, obliterator)
			end

			for _, button in ipairs(editor.Main.ShirtFrame:GetChildren()) do
				handleCategoryButton(button, obliterator)
			end

			for _, button in ipairs(editor.Main.PantsFrame:GetChildren()) do
				handleCategoryButton(button, obliterator)
			end

			obliterator:Add(editor.Main.BundleFrame.Close.Activated:Connect(function()
				editor.Main.BundleFrame.Visible = false
				bundleDetailsObliterator:Cleanup()
			end))

			obliterator:Add(editor.Main.BodyFrame.Scale.Activated:Connect(function()
				if debounces.changeCategory then
					return
				end
				debounces.changeCategory = true
				task.delay(0.5, function()
					debounces.changeCategory = false
				end)

				closeAllFrames()
				setCategoryColor(currentCategory, Color3.fromRGB(255, 255, 255))
				setCategoryColor("Scale", Color3.fromRGB(197, 197, 197))
				currentCategory = "Scale"
				editor.Main.BodyFrame.Scale.ImageColor3 = Color3.fromRGB(197, 197, 197)
				editor.Main.MainFrame.Search.Text = ""
				editor.Main.BodyFrame.Visible = true
				editor.Main.ScaleFrame.Visible = true

				for _, frame in ipairs(editor.Main.ScaleFrame.Frame:GetChildren()) do
					local sliderFrame = frame:FindFirstChild("SliderFrame")
					if not sliderFrame then
						continue
					end

					handleScaleSlider(sliderFrame.Slider)
				end
			end))

			obliterator:Add(editor.Main.BodyFrame.Skin.Activated:Connect(function()
				if debounces.changeCategory then
					return
				end
				debounces.changeCategory = true
				task.delay(0.5, function()
					debounces.changeCategory = false
				end)

				closeAllFrames()
				setCategoryColor(currentCategory, Color3.fromRGB(255, 255, 255))
				setCategoryColor("Skin", Color3.fromRGB(197, 197, 197))
				currentCategory = "Skin"
				editor.Main.MainFrame.Search.Text = ""
				editor.Main.BodyFrame.Visible = true
				editor.Main.MainFrame.Visible = true
				displayColors()
			end))

			handleCategoryButton(editor.Main.BodyFrame.Animations, obliterator)
			handleCategoryButton(editor.Main.BodyFrame.Bundles, obliterator)
			handleCategoryButton(editor.Main.BodyFrame.Face, obliterator)
			--handleCategoryButton(editor.Main.BodyFrame.Head, obliterator)

			obliterator:Add(editor.Main.OutfitsFrame.CreateOutfit.Activated:Connect(function()
				if debounces.outfitAdd then
					return
				end
				debounces.outfitAdd = true
				task.delay(0.5, function()
					debounces.outfitAdd = false
				end)

				if outfits and #outfits < 10 then
					table.insert(outfits, currentDescription:Clone())
					addOutfit:FireServer(serializeHumanoidDescription(currentDescription))

					local outfitDisplay = outfitTemplate:Clone()
					outfitsObliterator:Add(outfitDisplay)
					outfitDisplay.Parent = editor.Main.OutfitsFrame.Items

					updateOutfitDisplay(outfitDisplay, outfits[#outfits])
				end
			end))

			obliterator:Add(editor.Main.Apply.Activated:Connect(function()
				if debounces.close then
					return
				end
				debounces.close = true
				task.delay(0.5, function()
					debounces.close = false
				end)

				saveDescription:FireServer(serializeHumanoidDescription(currentDescription))
				self.Close()
			end))

			obliterator:Add(editor.Main.WearingFrame.RemoveAll.Activated:Connect(function()
				if debounces.removeAll then
					return
				end
				debounces.removeAll = true
				task.delay(0.5, function()
					debounces.removeAll = false
				end)
				
				--currentDescription.Head = 0
				--currentDescription.Shirt = 868697637
				--currentDescription.Pants = 868697782
				--currentDescription.GraphicTShirt = 0
				--currentDescription.Face = 144075659
				--currentDescription:SetAccessories({}, true)
				
				local duplicates = {}
				for _, item in ipairs(getAllEquippedItems(currentDescription)) do
					if duplicates[item.AssetId] then
						continue
					end
					duplicates[item.AssetId] = true
					unequipItem(currentDescription, item.AssetId, true)
				end
				
				currentDescription.DepthScale = websiteDescription.DepthScale
				currentDescription.HeightScale = websiteDescription.HeightScale
				currentDescription.WidthScale = websiteDescription.WidthScale
				currentDescription.HeadScale = websiteDescription.HeadScale
				currentDescription.BodyTypeScale = websiteDescription.BodyTypeScale
				currentDescription.ProportionScale =websiteDescription.ProportionScale
				
				applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
				
				wearingObliterator:Cleanup()
				displayCurrentlyWearing()
			end))

			obliterator:Add(editor.Main.Cancel.Activated:Connect(function()
				if debounces.close then
					return
				end
				debounces.close = true
				task.delay(0.5, function()
					debounces.close = false
				end)

				applyDescription:FireServer(serializeHumanoidDescription(starterDescription))
				self.Close()
			end))

			obliterator:Add(editor.Main.Reset.Activated:Connect(function()
				if debounces.reset then
					return
				end
				debounces.reset = true
				task.delay(0.5, function()
					debounces.reset = false
				end)

				resetUI()
				resetDescription:FireServer()
				currentDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
			end))

			obliterator:Add(editor.Main.MainFrame.Search.FocusLost:Connect(function(entered)
				if not entered or not currentCategory or debounces.search then
					return
				end
				debounces.search = true
				task.delay(0.5, function()
					debounces.search = false
				end)
				openCategory(currentCategory, editor.Main.MainFrame.Search.Text)
			end))

			obliterator:Add(function()
				if #currentCategory ~= 0 then
					editor.Main:FindFirstChild(currentCategory, true).ImageColor3 = Color3.fromRGB(255, 255, 255)
				end
				if #currentSuperCategory ~= 0 then
					editor.Main[currentSuperCategory].ImageColor3 = Color3.fromRGB(255, 255, 255)
				end
			end, true)
			
			obliterator:Add(editor.Main.ScaleFrame.Frame.IDSubmit.Activated:Connect(function()
				if debounces.IDSubmit then
					return
				end
				debounces.IDSubmit = true
				task.delay(0.5, function()
					debounces.IDSubmit = false
				end)
				
				local ID = tonumber(editor.Main.ScaleFrame.Frame.ID.Text)
				
				if ID then
					local assetType = assetTypeIdRemaps[MarketplaceService:GetProductInfo(ID).AssetTypeId]
					local accessories = getAllEquippedItems(currentDescription)
					local itemIndex = getItemIndex(accessories, ID)

					if assetType == "DynamicHead" then
						--bundleItemDisplay:Destroy()
						--return
						assetType = "Head"
					end

					if itemIndex then
						unequipItem(currentDescription, ID)
						return
					elseif bodyParts[assetType] or animationCategories[assetType] then
						currentDescription[assetType] = ID
					elseif #accessories < accessoryLimit then
						table.insert(accessories, {
							AssetId = ID,
							IsLayered = if accessoryTypeRemaps[assetType] then true else false,
							AccessoryType = accessoryTypeRemaps[assetType] or Enum.AccessoryType[assetType],
							Order = if accessoryTypeRemaps[assetType]
								then #currentDescription:GetAccessories(false) + 1
								else nil,
						})
					end

					currentDescription:SetAccessories(accessories, true)
					applyDescription:FireServer(serializeHumanoidDescription(currentDescription))
				end
			end))

			for _, button in ipairs(editor.Main:GetChildren()) do
				if not button:IsA("GuiButton") then
					continue
				end

				local frame = editor.Main:FindFirstChild(`{button.Name}Frame`)

				if not frame then
					continue
				end

				obliterator:Add(button.Activated:Connect(function()
					if debounces.changeCategory then
						return
					end
					debounces.changeCategory = true
					task.delay(0.5, function()
						debounces.changeCategory = false
					end)
					
					local previousSuperCategory = currentSuperCategory
					if #currentSuperCategory ~= 0 then
						editor.Main[currentSuperCategory].ImageColor3 = Color3.fromRGB(255, 255, 255)
					end
					currentSuperCategory = button.Name
					editor.Main[currentSuperCategory].ImageColor3 = Color3.fromRGB(197, 197, 197)

					if not frame.Visible then
						slotsObliterator:Cleanup()
						mainDisplayFrameObliterator:Cleanup()

						closeAllFrames()

						frame.Visible = true

						if currentSuperCategory == "Accessory" then
							editor.Main.MainFrame.Visible = true
							openCategory("Hat", "")
						elseif currentSuperCategory == "Body" then
							editor.Main.MainFrame.Visible = true
							editor.Main.BodyFrame.Visible = true
							openCategory("Bundles", "")
						elseif currentSuperCategory == "Pants" then
							editor.Main.MainFrame.Visible = true
							openCategory("Pants", "")
						elseif currentSuperCategory == "Shirt" then
							editor.Main.MainFrame.Visible = true
							openCategory("Shirt", "")
						elseif currentSuperCategory == "Wearing" then
							currentCategory = "Wearing"
							editor.Main.MainFrame.Loading.Visible = false
							editor.Main.MainFrame.Visible = true
							wearingObliterator:Cleanup()
							displayCurrentlyWearing()
						elseif currentSuperCategory == "Outfits" then
							currentCategory = "Outfits"
							editor.Main.MainFrame.Loading.Visible = false
							if not outfits then
								outfits = getOutfits:InvokeServer()
								while not outfits do
									outfits = getOutfits:InvokeServer()
									task.wait(5)
								end

								for i, outfit in ipairs(outfits) do
									outfits[i] = fullDeserialize(outfit)
								end
							end
							displayOutfits()
						else
							editor.Main.MainFrame.Visible = true
						end
					end
				end))
			end

			currentSuperCategory = "Accessory"
			editor.Main[currentSuperCategory].ImageColor3 = Color3.fromRGB(197, 197, 197)
			openCategory("Hat", "")
		end

		task.delay(1, function()
			editor.Main.Slots.Template:Destroy()
			editor.Main.MainFrame.Items.Template:Destroy()
			editor.Main.BundleFrame.Items.Template:Destroy()
			editor.Main.OutfitsFrame.Items.Template:Destroy()
		end)

		for _, enumItem in pairs(Enum.AssetType:GetEnumItems()) do
			assetTypeIdRemaps[enumItem.Value] = enumItem.Name
		end

		local obliterator = Janitor.new()
		self.Is_Open = false
		self.Open = function()
			if not player.Character or not player.Character:FindFirstChild("Humanoid") then
				return
			end
			close_open_guis()
			hide_button.Close()
			left_ui.Cash.Visible = false			
			menu.Captain.Active = false
			menu.Passenger.Active = false
			openEditor(obliterator)
			self.Is_Open = true
	
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.FieldOfViewMode = Enum.FieldOfViewMode.MaxAxis
			Distort.Position = UDim2.fromScale(-0.2, 0)
			--Distort.Size = UDim2.fromScale(1, 1)
			Distort.Start()
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("Display_Gui") then
					player.Character.Head.Display_Gui.Enabled = false
				end
			end
		end

		self.Close = function()
			hide_button.Open()
			task.spawn(function()
				fade_ui.Fade()
			end)
			menu.Captain.Active = true
			menu.Passenger.Active = true
			self.Is_Open = false
			resetUI()
			closeEditor(obliterator)
			left_ui.Cash.Visible = true
			currentCategory = ""
			Distort.Position = UDim2.fromScale(0, 0)
			Distort.Size = UDim2.fromScale(1, 1)
			Distort.Stop()
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.FieldOfView = 70
			workspace.CurrentCamera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			editor.Main.MainFrame.Loading.Visible = false
			
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("Display_Gui") then
					player.Character.Head.Display_Gui.Enabled = true
				end
			end
			
			task.delay(1, function()
				replicated_storage.Remotes.FixOverheadUI:FireServer()
			end)
		end
		
		for _, object in ipairs(editor.Main:GetDescendants()) do
			if object:FindFirstChild("Description") then
				DescriptionUI(object, object.Description)
			end
		end

		return self
	end)()
end)

task.spawn(function()

	local kills = player_data_folder.Kills

	local current_event_active = miscellaneous.Current_Event_Active

	local kill_counter_ui = event_alerts_ui.KillCounter
	local kill_counter_ui_text = kill_counter_ui.Knockouts
	local event_alerts_ui_children = event_alerts_ui:GetChildren()
	local message_open
	local alert_uis = {}

	for i = 1, #event_alerts_ui_children do
		local alert_ui = event_alerts_ui_children[i]
		if alert_ui.Name ~= "KillCounter" then
			alert_uis[alert_ui.Name] = alert_ui
		end
	end

	event_alerts_ui.Reward.Ad.Purchase.Activated:Connect(function()
		marketplace_service:PromptGamePassPurchase(player, 8441242)
	end)

	event_alerts_ui.TreasureSpawned.Ad.Purchase.Activated:Connect(function()
		marketplace_service:PromptProductPurchase(player, 1317445952)
	end)

	remotes.Alert.OnClientEvent:Connect(function(alert_ui_name, text)
		if not player_gui:FindFirstChild("Loading") and not menu.Enabled and not avatar_ui.Is_Open then
			if message_open then
				message_open.Visible = false
			end

			local alert_ui = alert_uis[alert_ui_name]
			local alert_ui_text = alert_ui.TextLabel
			local exit_button = alert_ui.Close

			message_open = alert_ui

			alert_ui_text.Text = text
			alert_ui.Visible = true

			if alert_ui_name == "Reward" then
				if player_data_folder.Has_VIP_Pass.Value then
					text = alert_ui_text.Text:gsub("%d+", function(n) return tonumber(n)*2 end)
					alert_ui_text.Text = text
				else
					alert_ui.Ad.Visible = true
				end
			end

			exit_button.Activated:Wait()
			if alert_ui_text.Text == text then
				alert_ui.Visible = false
				if alert_ui_name == "Reward" then
					alert_ui.Ad.Visible = false
				end
			end
		end
	end)

	is_in_arena:GetPropertyChangedSignal("Value"):Connect(function()
		if is_in_arena.Value and current_event_active.Value then
			player_ui.Close()
			if current_speed >= 25 then
				toggle_running(true)
			end
			walk_button.ImageColor3 = on_background_color
			run_button.ImageColor3 = off_background_color
			kill_counter_ui.Visible = true
		else
			kill_counter_ui.Visible = false
		end
	end)

	current_event_active:GetPropertyChangedSignal("Value"):Connect(function()
		if not current_event_active.Value then
			kill_counter_ui.Visible = false
		end
	end)

	kills:GetPropertyChangedSignal("Value"):Connect(function()
		kill_counter_ui_text.Text = "Knockouts: "..kills.Value
	end)

end)

task.spawn(function()

	local teleport_to_event = remotes.Teleport_To_Event

	local current_day = miscellaneous.Day
	local current_message = miscellaneous.Current_Message

	local clock_time_ui = clock_ui.Time
	local clock_time_display = clock_time_ui.Time
	local clock_day_display = clock_time_ui.Day
	local clock_am_or_pm_display = clock_time_ui.AMORPM

	local event_notification_ui = clock_ui.event
	local event_notification_ui_text = event_notification_ui.Description

	local walk_button = event_notification_ui.Walk
	local teleport_button = event_notification_ui.Teleport

	local open_current_event_ui_button = clock_ui.Open

	event_notification_ui_text.Text = current_message.Value
	open_current_event_ui_button.Visible = false
	event_notification_ui.Visible = true

	if event_notification_ui_text.Text == "It’s night time. Sleep or have fun around the ship." then
		teleport_button.Text = "Cabins"
	else
		teleport_button.Text = "Teleport"
	end

	lighting_service:GetPropertyChangedSignal("TimeOfDay"):Connect(function()

		local minutes_display_value = lighting_service:GetMinutesAfterMidnight()
		local hours_display_value = math.floor(minutes_display_value/60)
		local current_day = current_day.Value
		local current_time = lighting_service.TimeOfDay

		if hours_display_value < 12 then
			clock_am_or_pm_display.Text = "AM"
		else
			clock_am_or_pm_display.Text = "PM"
		end

		minutes_display_value %= 60
		minutes_display_value = minutes_display_value > 9 and minutes_display_value or "0"..minutes_display_value
		hours_display_value = (hours_display_value - 1)%12 + 1
		clock_time_display.Text = hours_display_value..":"..minutes_display_value

	end)

	current_message:GetPropertyChangedSignal("Value"):Connect(function()
		event_notification_ui_text.Text = current_message.Value


		if current_message.Value == "It’s night time. Sleep or have fun around the ship." then
			teleport_button.Text = "Cabins"
		else
			teleport_button.Text = "Teleport"
		end


		open_current_event_ui_button.Visible = false
		event_notification_ui.Visible = true
	end)

	open_current_event_ui_button.Activated:Connect(function()
		open_current_event_ui_button.Visible = false
		event_notification_ui.Visible = true
	end)

	clock_day_display.Text = current_day.Value
	current_day:GetPropertyChangedSignal("Value"):Connect(function()
		clock_day_display.Text = current_day.Value
	end)

	walk_button.Activated:Connect(function()
		event_notification_ui.Visible = false
		open_current_event_ui_button.Visible = true
	end)

	local last_changed = -1
	current_island_name:GetPropertyChangedSignal("Value"):Connect(function()
		if current_island_name.Value ~= "" then
			last_changed = tick()
		end
	end)

	teleport_button.Activated:Connect(function()
		if not can_teleport or (tick() - last_changed) < 8 then return end
		if current_message.Value == "It’s night time. Sleep or have fun around the ship." then
			cabin_teleport_ui.Open()
		elseif current_message.Value ~= "Warning! The island is loading in. May cause lag." and not avatar_ui.Is_Open then
			teleport_to_event:FireServer()
			event_notification_ui.Visible = false
			open_current_event_ui_button.Visible = true
		end
	end)

end)

task.spawn(function()
	elevator_ui = (function()
		local elevator = player_gui:WaitForChild("Elevator")
		local self = init_closeable_gui(elevator)
		local background = elevator.Background
		local elevator_request = remotes.Elevator_Request
		local debounce = true	
		local floors = {
			["Floor1"] = true;
			["Floor2"] = true;
			["Floor3"] = true;
			["Deck"] = true;
		}
		local open_time
		local base = self.Open
		self.Open = function()
			base()
			open_time = tick()
			local local_open_time = open_time
			task.delay(15, function()
				if local_open_time == open_time then
					self.Close()
				end
			end)
		end
		for floor_name in pairs(floors) do
			background[floor_name].Activated:Connect(function()
				if debounce then
					debounce = false
					self.Close()
					elevator_request:FireServer(floor_name)
					task.wait(2)
					debounce = true
				end
			end)	
		end
		elevator_request.OnClientEvent:Connect(self.Open)
		return self
	end)()
end)


local function getCurrentTimeFormat(seconds)
	local currentTime = DateTime.fromUnixTimestamp(seconds):ToUniversalTime()

	local hour = currentTime.Hour
	local minute = currentTime.Minute
	local second = currentTime.Second

	if hour < 10 then
		hour = 0 .. hour
	end
	if minute < 10 then
		minute = 0 .. minute
	end
	if second < 10 then
		second = 0 .. second
	end
	return ("%s:%s:%s"):format(hour, minute, second)
end

task.spawn(function()
	local bait_shop_instance = player_gui:WaitForChild("BaitShop")
	bait_shop = (function()
		local self = init_closeable_gui(bait_shop_instance)

		for _, button in ipairs(bait_shop_instance.Background:GetChildren()) do
			if not button:FindFirstChild("ID") then continue end
			button.Activated:Connect(function()
				marketplace_service:PromptProductPurchase(player, button.ID.Value)
			end)
		end

		if player_data_folder.Has_VIP_Pass.Value then
			bait_shop_instance.Background.Ad.Visible = false
		else
			player_data_folder.Has_VIP_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				bait_shop_instance.Background.Ad.Visible = false
			end)
		end

		bait_shop_instance.Background.Ad.Purchase.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, 8441242)
		end)

		return self
	end)()
end)

task.spawn(function()
	local fish_ui_instance = player_gui:WaitForChild("FishUI")
	fish_ui = (function()
		local self = init_closeable_gui(fish_ui_instance)
		local currently_fishing_ui = player_gui:WaitForChild("CurrentlyFishing")
		local fishing_reward = player_gui:WaitForChild("FishingReward")
		local reward_display = fishing_reward.RewardScreen
		local player_controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
		local clicked = false

		if player_data_folder.Has_VIP_Pass.Value then
			fish_ui_instance.Background.Ad.Visible = false
			fish_ui_instance.Background.FreeBait.Text = "+4 Bait in:"
		else
			player_data_folder.Has_VIP_Pass:GetPropertyChangedSignal("Value"):Connect(function()
				fish_ui_instance.Background.Ad.Visible = false
				fish_ui_instance.Background.FreeBait.Text = "+4 Bait in:"
			end)
		end

		fish_ui_instance.Background.Ad.Purchase.Activated:Connect(function()
			marketplace_service:PromptGamePassPurchase(player, 8441242)
		end)

		local texts = {
			["Trash"] = "You have caught trash.";
			["Common"] = "You have caught a Common Fish";
			["Uncommon"] = "You have caught an Uncommon Fish!";
			["Rare"] = "You have caught a Rare Fish!";
			["Legendary"] = "You have caught a Legendary Fish!";
		}

		local is_fishing = false

		currently_fishing_ui.Reel.Activated:Connect(function()
			if clicked then return end

			currently_fishing_ui.Enabled = false
			is_fishing = false
			clicked = true
			local winning_type, winnings = remotes.Fished:InvokeServer(true)

			if player.Character and player.Character:FindFirstChild("Humanoid") then
				for _, track in ipairs(player.Character.Humanoid:GetPlayingAnimationTracks()) do
					track:Stop()
				end
			end
			--local character = player.Character
			--local rod = character:FindFirstChild("TropicalRod") or character:FindFirstChild("MedievalRod") or character:FindFirstChild("CityRod")
			--if rod then
			--	rod:Destroy()
			--end

			for _, obj in ipairs(reward_display:GetChildren()) do
				if obj:IsA("ImageLabel") then
					obj.Visible = false
				end
			end
			reward_display[winning_type].Visible = true
			reward_display.Caught.Text = texts[winning_type]
			reward_display.Reward.Text = "You won " .. winnings .." Cash!"
			fishing_reward.Enabled = true
			task.wait(3)
			fishing_reward.Enabled = false
			can_teleport = true
			player_controls:Enable()
		end)

		fish_ui_instance.Background.StartFishing.Activated:Connect(function()

			if player_data_folder.Bait.Value < 1 or current_island_name.Value == "" or is_fishing then return end

			is_fishing = true
			can_teleport = false
			player_controls:Disable()
			currently_fishing_ui.Enabled = true
			remotes.Fish_Request:FireServer()
			self.Close()

			task.wait(math.random(8, 25))
			currently_fishing_ui.Reel.Visible = true
			task.wait(2)
			currently_fishing_ui.Reel.Visible = false

			if not clicked then
				self.Close()
				player_controls:Enable()
				for _, track in ipairs(player.Character.Humanoid:GetPlayingAnimationTracks()) do
					track:Stop()
				end
				--local character = player.Character
				--local rod = character:FindFirstChild("TropicalRod") or character:FindFirstChild("MedievalRod") or character:FindFirstChild("CityRod")
				--if rod then
				--	rod:Destroy()
				--end
				can_teleport = true
				task.spawn(function()
					remotes.Fished:InvokeServer(false)
				end)
				currently_fishing_ui.Text.Visible = false
				currently_fishing_ui.DidntClick.Visible = true
				is_fishing = false
				task.wait(4)
				currently_fishing_ui.Text.Visible = true
				currently_fishing_ui.DidntClick.Visible = false
				if not is_fishing then
					currently_fishing_ui.Enabled = false
				end
			end

			clicked = false


		end)

		fish_ui_instance.Background.BuyBait.Activated:Connect(function()
			self.Close()
			bait_shop.Open()
		end)

		fish_ui_instance.Background.BaitLeft.Text = player_data_folder.Bait.Value
		player_data_folder.Bait:GetPropertyChangedSignal("Value"):Connect(function()
			fish_ui_instance.Background.BaitLeft.Text = player_data_folder.Bait.Value
		end)

		remotes.Open_Fishing_UI.OnClientEvent:Connect(function(for_bait)
			if for_bait then
				if open_guis[bait_shop] then return end
				bait_shop.Open()
				return
			end
			if open_guis[self] then return end
			self.Open()
		end)

		task.spawn(function()
			while true do
				task.wait(1)
				if player_data_folder.Bait.Value > 0 then
					fish_ui_instance.Background.Timer.Text = "3:00:00"
					continue
				end

				fish_ui_instance.Background.Timer.Text = getCurrentTimeFormat(10800 - (DateTime.now().UnixTimestamp - player_data_folder.Last_Hit_Bait_Zero.Value))

			end
		end)

		current_island_name:GetPropertyChangedSignal("Value"):Connect(function()
			player_controls:Enable()
		end)

		return self
	end)()
end)

task.spawn(function()
	local treasure_ui_instance = player_gui:WaitForChild("TreasureUI")
	treasure_ui = (function()
		local self = init_closeable_gui(treasure_ui_instance)

		treasure_ui_instance.Background.Ad.Purchase.Activated:Connect(function()
			marketplace_service:PromptProductPurchase(player, 1317445952)
		end)

		remotes.FoundChest.OnClientEvent:Connect(function(amount, claim_count)
			treasure_ui_instance.Background.Reward.Text = "You have found a treasure chest worth "..amount.." Cash! Only three people can claim it before it disappears."
			treasure_ui_instance.Background.TreasureLeft.Text = "Claims Left: "..(3-claim_count)
			self.Open()
		end)
		return self
	end)()
end)
