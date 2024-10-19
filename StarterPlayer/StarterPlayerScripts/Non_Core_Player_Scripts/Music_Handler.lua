--[[ Services ]]--

local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local tween_service = game:GetService("TweenService")
local marketplace_service = game:GetService("MarketplaceService")
local run_service = game:GetService("RunService")

--[[ Variables ]]--

local player = players.LocalPlayer

local remotes = replicated_storage:WaitForChild("Remotes")
local play_horn = remotes.Play_Horn
local request_queue = remotes.Request_Queue
local request_song = remotes.Request_Song
local add_song_to_queue = remotes.Add_Song_To_Queue
local remove_song_from_queue = remotes.Remove_Song_From_Queue
local change_boom_box_song = remotes.Change_Boom_Box_Song
local activate_dj_effect = remotes.Activate_DJ_Effect
local change_emitter_ui = remotes.Change_Emitter_UI
local request_badge = remotes.Request_Badge

local player_data_folder = replicated_storage:WaitForChild(player.Name)
local other_radios_enabled = player_data_folder:WaitForChild("Other_Radios_Enabled")
local my_radio_is_enabled = player_data_folder:WaitForChild("Boom_Box_Is_Active")
local area_music_is_enabled = player_data_folder:WaitForChild("Area_Music_Is_Enabled")
local can_play_boom_box = player_data_folder:WaitForChild("Can_Play_Boom_Box")
local has_dj_pass = player_data_folder:WaitForChild("Has_DJ_Pass")

local miscellaneous = replicated_storage:WaitForChild("Miscellaneous")
local disable_ui = miscellaneous.Disable_UI
local current_island_name = miscellaneous.Current_Island_Name

local client_accessible_modules = replicated_storage:WaitForChild("Client_Accessible_Modules")
local globals = require(client_accessible_modules.Global_Replacements)
local song_queue = require(client_accessible_modules.Queues).Song_Queue 

local game_songs = workspace:WaitForChild("Game_Songs")
local tween_info = TweenInfo.new(2)
local volume_tween_objects = {}
local song_changed_connections = {}
local current_area = ""
local last_area_was_party = false
local last_time_was_area_music = false
local changing_music = false

local area_check_time = 0.6
local current_time = 0

local player_gui = player.PlayerGui
local dj_ui = player_gui:WaitForChild("DJ")
local open_dj_ui_button = dj_ui.Open

local musicListUI = dj_ui.MusicListUI
local musicListElement = musicListUI.Background.ScrollingFrame.Song:Clone()

local general_dj_ui = dj_ui.DJ
local close_dj_ui_button = general_dj_ui.Close
local id_text_box = general_dj_ui.MessageBox
local dj_queue_ui = general_dj_ui.Queue.ScrollingFrame

local on_background_color = Color3.fromRGB(102, 255, 102)
local off_background_color = Color3.fromRGB(253, 102, 102)

local horn_sound_id = "rbxassetid://1059214449"
local horn_sound_obj = Instance.new("Sound")
horn_sound_obj.Name = "Horn"
horn_sound_obj.SoundId = horn_sound_id
horn_sound_obj.Volume = 30
horn_sound_obj.Parent = game_songs

local dj_pass_id = 8441258
local was_in_dj_area = false

local last_area = ""

local on_properties = {
	["Volume"] = 0.6;
}
local off_properties = {
	["Volume"] = 0;
}

local sound_areas = {

	["Olde Town1"] = {
		-2743.9;
		211.9;
		249.371;
		951.271;
		193.5;
		2970.8;
	};

	["Olde Town2"] = {
		-7229.107;
		-6770.808;
		-90.943;
		34.457;
		-1183.453;
		-677.353;
	};

	["Blox City1"] = {
		133.046;
		223.916;
		363.304;
		568.854;
		332.692;
		2358.703;
	};

	["Blox City2"] = {
		-5666.75;
		-5313.45;
		-312.7;
		-259.55;
		-2872.8;
		-2366.099;
	};

	["Blox City3"] = {
		-5069.746;
		-4910.046;
		-396.527;
		-308.227;
		-3380.64;
		-3232.14;
	};

	["Blox City4"] = {
		-2191.143;
		135.558;
		363.304;
		813.084;
		332.692;
		2358.703;
	};

	["Paradise Island1"] = {
		-2743.9;
		211.9;
		249.371;
		951.271;
		193.5;
		2970.8;
	};

	["Paradise Island2"] = {
		-4717.651;
		-4161.851;
		-350.778;
		-177.278;
		-1990.511;
		-1312.711;
	};
	
	["Samurai Island1"] = {
		-3329.954;
		214.738;
		371.938;
		1386.835;
		-831.646;
		3693.832;
	};


	["DJ_Area"] = {
		-991.65;
		-513.75;
		-635.15;
		-536.25;
		-3021.55;
		-2712.65;
	};

	["Dining Room"] = {
		1893.55;
		2072.65;
		-652.318;
		-564.017;
		4535.45;
		4825.45;
	}

}

local dj_area_dimensions = {
	-893.785;
	-818.025;
	-610.15;
	-554.75;
	-2834.75;
	-2811.287;
}

local main_area_names = {}

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

local function get_player_area_id(position)
	local x, y, z = position.X, position.Y, position.Z
	for song_id, dimensions in pairs(sound_areas) do
		if song_id == "DJ_Area" or song_id == "Dining Room" or song_id:match("%D+") == current_island_name.Value then
			local x_one, x_two, y_one, y_two, z_one, z_two = dimensions[1], dimensions[2], dimensions[3], dimensions[4], dimensions[5], dimensions[6]
			if x_one <= x and x_two >= x and y_one <= y and y_two >= y and z_one <= z and z_two >= z then
				return song_id:match("%D+")
			end
		end
	end
	return "Ship"
end

local function is_in_dj_area(pos)
	local dimensions = dj_area_dimensions
	local x, y, z = pos.X, pos.Y, pos.Z
	local x_one, x_two, y_one, y_two, z_one, z_two = dimensions[1], dimensions[2], dimensions[3], dimensions[4], dimensions[5], dimensions[6]
	if x_one <= x and x_two >= x and y_one <= y and y_two >= y and z_one <= z and z_two >= z then
		return true
	end
end

local function update_queue_ui()
	local i = 1
	for song_request in song_queue:iterator() do
		local gui_obj = dj_queue_ui["Song"..i]
		gui_obj.ID.Text = "ID: "..song_request[1]
		gui_obj.NAME.Text = "Played by: "..song_request[2]
		gui_obj.Visible = true
		i += 1
	end
	if i < 6 then
		for j = i, 6 do
			dj_queue_ui["Song"..j].Visible = false
		end
	end
end

local function tween_volume_on(song_obj)
	return tween_service:Create(
		song_obj,
		tween_info,
		on_properties
	)
end

local function tween_volume_off(song_obj)
	return tween_service:Create(
		song_obj,
		tween_info,
		off_properties
	)
end

local function handle_music_volume(player, can_always_play)

	local player_data_folder = replicated_storage:WaitForChild(player.Name)
	local boom_box_is_active = player_data_folder:WaitForChild("Boom_Box_Is_Active")
	local current_song = player_data_folder:WaitForChild("Current_Song")

	if boom_box_is_active.Value then

		local song_id = current_song.Value
		local song_obj = Instance.new("Sound")

		song_obj.Name = player.Name
		song_obj.SoundId = song_id
		song_obj.Volume = 0
		song_obj:Play()

		local tween_obj = tween_volume_on(song_obj)

		volume_tween_objects[player.Name.."_On"] = tween_obj
		volume_tween_objects[player.Name.."_Off"] = tween_volume_off(song_obj)

		song_obj.Parent = game_songs

		if (other_radios_enabled.Value or can_always_play) and tonumber(current_area) then
			tween_obj:Play()	
		end

	end

	song_changed_connections[player.Name] = current_song:GetPropertyChangedSignal("Value"):Connect(function()

		local last_song = game_songs:FindFirstChild(player.Name)
		if last_song then
			last_song:Destroy()
		end

		if boom_box_is_active.Value then

			local song_id = current_song.Value
			local song_obj = Instance.new("Sound")

			song_obj.Name = player.Name
			song_obj.SoundId = song_id
			song_obj.Volume = 0
			song_obj.Looped = true
			song_obj:Play()

			volume_tween_objects[player.Name.."_On"] = tween_volume_on(song_obj)
			volume_tween_objects[player.Name.."_Off"] = tween_volume_off(song_obj)

			song_obj.Parent = game_songs

		end

	end)

end

players.PlayerAdded:Connect(handle_music_volume)

players.PlayerRemoving:Connect(function(other_player)

	local on_tween_obj = volume_tween_objects[other_player.Name.."_On"]
	local off_tween_obj = volume_tween_objects[other_player.Name.."_Off"]
	local song_obj = game_songs:FindFirstChild(other_player.Name)

	if on_tween_obj then
		on_tween_obj:Destroy()
		volume_tween_objects[other_player.Name.."_On"] = nil
	end

	if off_tween_obj then
		if song_obj.Volume > 0 then
			off_tween_obj:Play()
			off_tween_obj.Completed:Wait()
		end
		off_tween_obj:Destroy()
		volume_tween_objects[other_player.Name.."_Off"] = nil
	end

	if song_obj then
		song_obj:Destroy()
	end

end)

local found_names = {}

local function create_song(area_name)	
	task.spawn(function()
		local obj = miscellaneous:WaitForChild(area_name.."_Song")
		local sound_obj = Instance.new("Sound")
		sound_obj.SoundId = obj.Value
		sound_obj.Looped = true
		sound_obj.Volume = 0
		sound_obj.Name = obj.Name
		sound_obj.Parent = game_songs
		volume_tween_objects[obj.Name.."_On"] = tween_volume_on(sound_obj)
		volume_tween_objects[obj.Name.."_Off"] = tween_volume_off(sound_obj)
		main_area_names[obj.Name] = true
		if not sound_obj.IsLoaded then
			sound_obj.Loaded:Wait()
		end		
		sound_obj:Play()
		obj:GetPropertyChangedSignal("Value"):Connect(function()
			sound_obj:Stop()
			sound_obj.SoundId = obj.Value
			if not sound_obj.IsLoaded then
				sound_obj.Loaded:Wait()
			end
			sound_obj:Play()
		end)
	end)
end

create_song("Ship")
for area_name in pairs(sound_areas) do
	local area_name = area_name:match("%D+")
	if not found_names[area_name] then
		found_names[area_name] = true
		create_song(area_name)
	end
end

for _, other_player in ipairs(players:GetPlayers()) do
	task.spawn(function()
		if other_player == player then
			handle_music_volume(other_player, true)
		else
			handle_music_volume(other_player, false)
		end
	end)
end

area_music_is_enabled:GetPropertyChangedSignal("Value"):Connect(function()
	if not area_music_is_enabled.Value and current_area ~= "DJ_Area" then	
		local tween_obj = volume_tween_objects[current_area.."_Off"]	
		if tween_obj then
			tween_obj:Play()
		end	
	end
end)

other_radios_enabled:GetPropertyChangedSignal("Value"):Connect(function()
	if not other_radios_enabled.Value then
		for _, other_player in ipairs(players:GetChildren()) do	
			local song_obj = game_songs:FindFirstChild(other_player.Name)
			if song_obj and song_obj.Volume > 0 and player ~= other_player then
				local tween_obj = volume_tween_objects[other_player.Name.."_Off"]
				if tween_obj then
					tween_obj:Play()
				end
			end
		end
	end
end)

play_horn.OnClientEvent:Connect(function()
	horn_sound_obj:Play()
end)

add_song_to_queue.OnClientEvent:Connect(function(song_request)
	song_queue:queue(song_request)
	update_queue_ui()
end)

remove_song_from_queue.OnClientEvent:Connect(function()
	song_queue:unqueue()
	update_queue_ui()
end)

task.spawn(function()
	for song_request in ipairs(request_queue:InvokeServer()) do
		song_queue:queue(song_request)
	end
	update_queue_ui()
end)

open_dj_ui_button.Activated:Connect(function()
	if has_dj_pass.Value then
		open_dj_ui_button.Visible = false
		disable_ui:Fire(true)
		task.wait()
		general_dj_ui.Visible = true
	else
		marketplace_service:PromptGamePassPurchase(player, dj_pass_id)
	end
end)

close_dj_ui_button.Activated:Connect(function()
	id_text_box.Text = ""
	general_dj_ui.Visible = false
	disable_ui:Fire(false)
	open_dj_ui_button.Visible = true
end)

general_dj_ui.TextButton.Activated:Connect(function()
	local text = id_text_box.Text
	if #text > 0 and tonumber(text) then
		id_text_box.Text = request_song:InvokeServer(text)
	else
		id_text_box.Text = "Not a valid song ID."
	end
end)

general_dj_ui.MusicList.Activated:Connect(function()
	general_dj_ui.Visible = false
	musicListUI.Visible = true
end)

musicListUI.Back.Activated:Connect(function()
	general_dj_ui.Visible = true
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
			request_song:InvokeServer(tostring(id))
			musicListUI.Visible = false
			general_dj_ui.Visible = true
		end)

		newElement.Text = songInfo.Name
		newElement.Parent = musicListUI.Background.ScrollingFrame
	end)

end

local buttons = {
	["Fire"] = true;
	["Smoke"] = true;
	["Confetti"] = true;
}

for name in pairs(buttons) do
	local time_one = miscellaneous[name.."_Time"]
	time_one:GetPropertyChangedSignal("Value"):Connect(function()
		if time_one.Value > -1 and time_one.Value < 10 then
			general_dj_ui[name].TextLabel.Text = name.."("..(10 - time_one.Value)..")"
		else
			general_dj_ui[name].TextLabel.Text = name
		end
	end)
	general_dj_ui[name].Activated:Connect(function()
		if miscellaneous[name.."_Time"].Value >= 10 or miscellaneous[name.."_Time"].Value == -1 then
			activate_dj_effect:FireServer(name)
		end	
	end)
end

change_emitter_ui.OnClientEvent:Connect(function(name, enable)
	if enable then
		general_dj_ui[name].ImageColor3 = on_background_color
	else
		general_dj_ui[name].ImageColor3 = off_background_color
	end
end)

local debounce = true

run_service.RenderStepped:Connect(function(delta)
	current_time += delta
	if current_time < area_check_time then return end
	current_time = 0
	local root_part = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) or workspace:FindFirstChild("ReplicationFocusPart")
	if root_part and root_part.Parent then
		current_area = get_player_area_id(root_part.Position).."_Song"
		
		if not current_area:match("DJ_Area") and main_area_names[current_area] then

			if was_in_dj_area then
				disable_ui:Fire(false)
				open_dj_ui_button.Visible = true
				general_dj_ui.Visible = false
				dj_ui.Enabled = false
			end

			was_in_dj_area = false

			if last_area_was_party and last_area and last_area ~= "" then
				can_play_boom_box.Value = true
				volume_tween_objects[last_area.."_Off"]:Play()
			end

			local found_a_player_playing_music_in_range = false
			last_area_was_party = false

			for _, other_player in ipairs(players:GetPlayers()) do

				local other_player_data_folder = replicated_storage:WaitForChild(other_player.Name)
				local other_players_boom_box_is_active = other_player_data_folder:WaitForChild("Boom_Box_Is_Active")
				local other_character = other_player.Character or other_player.CharacterAdded:Wait()
				local other_humanoid_root_part = other_character:FindFirstChild("HumanoidRootPart")

				if other_humanoid_root_part and other_players_boom_box_is_active.Value and (other_player == player or other_radios_enabled.Value) then

					local song_obj = game_songs:FindFirstChild(other_player.Name)

					if song_obj then
						if (player:DistanceFromCharacter(other_humanoid_root_part.Position) <= 30) or player == other_player then

							found_a_player_playing_music_in_range = true

							if song_obj.Volume < 1 then
								local tween_obj = volume_tween_objects[other_player.Name.."_On"]
								if tween_obj then
									tween_obj:Play()
								end
							end

						elseif song_obj.Volume > 0 then
							local tween_obj = volume_tween_objects[other_player.Name.."_Off"]
							if tween_obj then
								tween_obj:Play()
							end
						end

					end

				end

			end

			if area_music_is_enabled.Value then

				if not found_a_player_playing_music_in_range then
					
					local on_tween_obj = volume_tween_objects[current_area.."_On"]

					if on_tween_obj then
						on_tween_obj:Play()
					end

					for _, song in ipairs(game_songs:GetChildren()) do
						if song.Volume > 0 and not song.Name:match(current_area) and song.Name ~= "Horn" then
							local tween_obj = volume_tween_objects[song.Name.."_Off"]
							if tween_obj then
								
								tween_obj:Play()
							end
						end
					end
					
					if current_area == current_island_name.Value.."_Song" and debounce then
						debounce = false
						request_badge:FireServer()
						task.delay(10, function()
							debounce = true
						end)
					end

					last_time_was_area_music = true

				elseif last_time_was_area_music then

					last_time_was_area_music = false

					local tween_obj = volume_tween_objects[current_area.."_Off"]
					if tween_obj then
						tween_obj:Play()
					end

				end
			end

		else
			if not last_area_was_party then
				last_area_was_party = true
				for _, song in ipairs(game_songs:GetChildren()) do
					if song.Volume > 0 and not song.Name:match(current_area) and song.Name ~= "Horn" then
						local tween_obj = volume_tween_objects[song.Name.."_Off"]
						if tween_obj then
							tween_obj:Play()
						end
					end
				end
				can_play_boom_box.Value = false
				if my_radio_is_enabled.Value then
					change_boom_box_song:InvokeServer(false)
				end
			end
			if not changing_music and game_songs[current_area].Volume == 0 then
				volume_tween_objects[current_area.."_On"]:Play()
			end

			if is_in_dj_area(root_part.Position) then
				if not was_in_dj_area then
					dj_ui.Enabled = true
				end
				was_in_dj_area = true
			else
				if was_in_dj_area then
					disable_ui:Fire(false)
					general_dj_ui.Visible = false
					open_dj_ui_button.Visible = true
					dj_ui.Enabled = false
				end
				was_in_dj_area = false
			end

		end

		last_area = current_area
	end
end)
