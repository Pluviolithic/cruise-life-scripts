--[[ Services ]]--

local server_storage = game:GetService("ServerStorage")
local replicated_storage = game:GetService("ReplicatedStorage")
local sound_service = game:GetService("SoundService")
local marketplace_service = game:GetService("MarketplaceService")
local log_service = game:GetService("LogService")

--[[ Variables ]]--

local remotes = replicated_storage.Remotes
local request_song = remotes.Request_Song
local add_song_to_queue = remotes.Add_Song_To_Queue
local remove_song_from_queue = remotes.Remove_Song_From_Queue
local change_boom_box_song = remotes.Change_Boom_Box_Song
local request_queue = remotes.Request_Queue
local activate_dj_effect = remotes.Activate_DJ_Effect
local change_emitter_ui = remotes.Change_Emitter_UI

local miscellaneous = replicated_storage.Miscellaneous
local client_accessible_modules = replicated_storage.Client_Accessible_Modules

local globals = require(client_accessible_modules.Global_Replacements)
local song_queue = require(client_accessible_modules.Queues).Song_Queue

local dj_area = workspace.DJ_Area

local rand_obj = Random.new()
local dimensions = {
	-893.785;
	-818.025;
	-610.15;
	-554.75;
	-2834.75;
	-2811.287;
}
local x_one, x_two, y_one, y_two, z_one, z_two = dimensions[1], dimensions[2], dimensions[3], dimensions[4], dimensions[5], dimensions[6]

local random_song_ids = {
	"5409360995";
	"7029051434";
	"7024332460";
	"7029017448";
	"7028977687";
	"7024101188";
	"7023598688";
	"7028557220";
	"7023445033";
	"7023828725";
}

local main_soundtrack_ids = {
    ["Ship"] = {
        "3481674945";
        "5276498439";
        "5276490033";
        "5276509681";
        "5276488696";
    };
    ["Olde Town"] = {
        "3466257337";
    };
    ["Blox City"] = {
        "3481678977";
    };
    ["Paradise Island"] = {
        "2157977223";
	};
	["Samurai Island"] = {
		"1839872620";
	};
	["Dining Room"] = {
		"1840434123";
	}
}

local function fisher_yates_shuffle(t)
    for n = #t, 1, -1 do
        local k = rand_obj:NextInteger(1, n)
        t[n], t[k] = t[k], t[n]
    end
    return t
end

local function player_is_in_area(position)
    local x, y, z = position.X, position.Y, position.Z
    if x_one <= x and x_two >= x and y_one <= y and y_two >= y and z_one <= z and z_two >= z then
        return true
    end
    return false
end

local dj_id_transfer = Instance.new("StringValue")
dj_id_transfer.Name = "DJ_Area_Song"
dj_id_transfer.Parent = miscellaneous

local temp_music_list = fisher_yates_shuffle({table.unpack(random_song_ids)})
local last_song_was_dj = false
local last_song_id
local latest_call_time = tick()

local function run_music(my_call_time)
    
    if #temp_music_list < 1 then
        temp_music_list = fisher_yates_shuffle({table.unpack(random_song_ids)})
        if last_song_id == temp_music_list[#temp_music_list] then
            temp_music_list[#temp_music_list], temp_music_list[1] = temp_music_list[1], temp_music_list[#temp_music_list]
        end
    end

    local current_song = song_queue:unqueue()
    if current_song then
        current_song = current_song[1]
        last_song_was_dj = true
        remove_song_from_queue:FireAllClients()
    else
        current_song = table.remove(temp_music_list)
        last_song_was_dj = false
    end

    local sound_obj = Instance.new("Sound")
    sound_obj.SoundId = "rbxassetid://"..current_song
    sound_obj.Parent = server_storage
    last_song_id = current_song

    dj_id_transfer.Value = sound_obj.SoundId

	 if sound_obj.IsLoaded then
		local time_to_yield = sound_obj.TimeLength
		task.wait(time_to_yield)
	else
		task.wait(3)
		if sound_obj.IsLoaded then
			local time_to_yield = sound_obj.TimeLength
			task.wait(time_to_yield)
		end
    end

    if my_call_time == latest_call_time then
        run_music(my_call_time)
    end

end

request_song.OnServerInvoke = function(player, song_id)

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
    local player_data_folder = replicated_storage[player.Name]
    local has_dj_pass = player_data_folder.Has_DJ_Pass

    if player_is_in_area(humanoid_root_part.Position) and has_dj_pass.Value and type(song_id) == "string" and tonumber(song_id) then

        local success, info_type = pcall(marketplace_service.GetProductInfo, marketplace_service, tonumber(song_id))

		    if success and info_type.AssetTypeId == 3 and info_type.IsPublicDomain then
                local player_requests = 0
                for song_request in song_queue:iterator() do
                    if song_request[2] == player.Name then
                        player_requests += 1
                    end
                end
                if player_requests > 1 then
                    return "You already have two songs in the queue."
                elseif song_queue:length() > 5 then
                    return "Limit of six songs in the queue."
                else
                    local song_request = {song_id, player.Name} 
                    song_queue:queue(song_request)
                    if song_queue:length() > 1 or last_song_was_dj then
                        add_song_to_queue:FireAllClients(song_request)
                    else
                        task.spawn(function()
                            latest_call_time = tick()
                            run_music(latest_call_time)
                        end)
                    end

                    return "Song added to queue successfully!"
                end

            else
                return "Invalid song id."
            end
        end

end

for island_name, ids in pairs(main_soundtrack_ids) do
    task.spawn(function()
        local temp_main_area_music = {}
        local song_id_transfer = Instance.new("StringValue")
        local local_last_song_id
        song_id_transfer.Name = island_name.."_Song"
        song_id_transfer.Parent = miscellaneous
        while true do
            if #temp_main_area_music < 1 then
                temp_main_area_music = {table.unpack(fisher_yates_shuffle(ids))}
                if local_last_song_id == temp_main_area_music[#temp_main_area_music] then
                    temp_main_area_music[1], temp_main_area_music[#temp_main_area_music] = temp_main_area_music[#temp_main_area_music], temp_main_area_music[1]
                end
            end
            local song_id = table.remove(temp_main_area_music)
            local song_obj = Instance.new("Sound")
            song_obj.SoundId = "rbxassetid://"..song_id
            song_obj.Parent = server_storage
            song_id_transfer.Value = song_obj.SoundId
            local_last_song_id = song_id
			if not song_obj.IsLoaded then
				song_obj.Loaded:Wait()
            end
            local time_to_yield = song_obj.TimeLength
            song_obj:Destroy()	
            task.wait(time_to_yield)
        end
    end)
end

task.spawn(function()
    latest_call_time = tick()
    run_music(latest_call_time)
end)

request_queue.OnServerInvoke = function()
    local transferable_queue = {}
    for song_request in song_queue:iterator() do
        table.insert(transferable_queue, song_request)
    end
    return transferable_queue
end

change_boom_box_song.OnServerInvoke = function(player, song_id)

    local player_data_folder = replicated_storage[player.Name]
    local player_has_boom_box_pass = player_data_folder.Has_Boom_Box_Pass
    local current_song = player_data_folder.Current_Song
    local boom_box_is_active = player_data_folder.Boom_Box_Is_Active

    if player_has_boom_box_pass.Value and type(song_id) == "string" and tonumber(song_id) then

        local success, info_type = pcall(marketplace_service.GetProductInfo, marketplace_service, tonumber(song_id))
        local not_moderated = pcall(function()
            Instance.new("Sound").SoundId = "rbxassetid://"..song_id
        end)

        if success and not_moderated and info_type.AssetTypeId == 3 then
            boom_box_is_active.Value = true
            current_song.Value = "rbxassetid://"..song_id
            return "Song turned on successfully!"
        else
            return "Not a valid song ID."
        end

    elseif player_has_boom_box_pass.Value and type(song_id) == "boolean" and not song_id then
        boom_box_is_active.Value = false
        current_song.Value = ""
        return "Song turned off successfully!"
    end

    return "Error"

end

local particle_names = {
	["Fire"] = true;
	["Smoke"] = true;
	["Confetti"] = true;
}

local valid_emitters = {}
for _, obj in ipairs(dj_area:GetDescendants()) do
	if not particle_names[obj.Name] or not (obj:IsA("ParticleEmitter") or obj:IsA("Fire")) then continue end
	table.insert(valid_emitters, obj)
end

local function change_particles(name, auto)
    local switch_value
    for _, obj in pairs(valid_emitters) do
        if obj.Name == name then
            if auto then
                switch_value = not obj.Enabled
                obj.Enabled = not obj.Enabled
            else
                obj.Enabled = auto
            end
        end
    end
    if not auto then
        switch_value = false
    end
    change_emitter_ui:FireAllClients(name, switch_value)
end

local function start_clock(time_obj, name)
    for i = 1, 60 do
        if time_obj.Value == i - 1 then
            time_obj.Value = i
            task.wait(1)
        else
            break
        end
    end
    if time_obj.Value == 60 then
        change_particles(name, false)
    end
end

local fire_time = Instance.new("IntValue")
fire_time.Name = "Fire_Time"
fire_time.Value = -1

local smoke_time = Instance.new("IntValue")
smoke_time.Name = "Smoke_Time"
smoke_time.Value = -1

local confetti_time = Instance.new("IntValue")
confetti_time.Name = "Confetti_Time"
confetti_time.Value = -1

fire_time.Parent, smoke_time.Parent, confetti_time.Parent = miscellaneous, miscellaneous, miscellaneous

activate_dj_effect.OnServerEvent:Connect(function(player, particle_name)
    local humanoid_root_part = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if replicated_storage[player.Name].Has_DJ_Pass.Value and particle_names[particle_name] and humanoid_root_part and player_is_in_area(humanoid_root_part.Position) then
        local time_left = miscellaneous:FindFirstChild(particle_name.."_Time")
        if time_left.Value >= 10 or time_left.Value == -1 then
            change_particles(particle_name, true)
            time_left.Value = 0
            start_clock(time_left, particle_name)
        end
    end
end)

sound_service.RespectFilteringEnabled = true
