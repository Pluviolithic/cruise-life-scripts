local replicated_storage = game:GetService("ReplicatedStorage")
local server_storage = game:GetService("ServerStorage")
local players = game:GetService("Players")
local tween_service = game:GetService("TweenService")

local doors = workspace.Cabin_Doors
local cabins = workspace.Cabins
local server_cabins = server_storage.Cabins

local cabin_info = {}
local owners = {}
local locations = {}
local character_debounce_list = {}
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
	["UnderwaterCabin"] = "Underwater Cabin";
	["CaptainCabin"] = "Captain Cabin"
}

local owned_cabin_color = Color3.fromRGB(127, 60, 60)
local unowned_cabin_color = Color3.fromRGB(89, 111, 108)
local up_vector = Vector3.new(0, 1, 0)

local remotes = replicated_storage.Remotes
local fade = remotes.Fade
local send_cabin_info = remotes.Send_Cabin_Info
local start_arcade = remotes.Start_Arcade
local start_pong = remotes.Start_Pong

local teleported = server_storage.Bindables.Teleported
local get_cabin_refund = server_storage.Bindables.Get_Cabin_Refund

local client_accessible_modules = replicated_storage.Client_Accessible_Modules
local globals = require(client_accessible_modules.Global_Replacements)
local cabin_tv_program = require(client_accessible_modules.Tv_Program)

local function generate_on_tween(obj)
    return tween_service:Create(
    obj,
    TweenInfo.new(0.25),
    {
        ["Transparency"] = 0;
    }
    )
end

local function generate_off_tween(obj)
    return tween_service:Create(
    obj,
    TweenInfo.new(0.25),
    {
        ["Transparency"] = 1;
    }
    )
end

local function switch_lights(player)
    local my_info = owners[player]
    if not my_info then return end
    local power = not my_info.Light_Info.Power
    for _, light in ipairs(my_info.Light_Info.Lights) do
        light.Enabled = power
    end
    my_info.Light_Info.Power = power
end

local function switch_confetti(player)
    local my_info = owners[player]
    if not my_info then return end
    local power = not my_info.Confetti_Info.Power
    for _, emitter in ipairs(my_info.Confetti_Info.Emitters) do
        emitter.Enabled = power
    end
    my_info.Confetti_Info.Power = power
end

local function lock_door(player)
    local my_info = owners[player]
    if not my_info then return end
    my_info.Locked = not my_info.Locked
end

local function switch_tv(player)
    local my_info = owners[player]
    if not my_info then return end
    local tv_info = my_info.Tv_Info
    local power = not tv_info.Power
    tv_info.Power = power
    if power then
        local key = os.time()
        local i = #cabin_tv_program
        tv_info.Key = key
        while tv_info.Power and key == tv_info.Key do
            if i >= #cabin_tv_program then
                i = 1
            else
                i += 1
            end
            tv_info.Screen.Texture = "rbxassetid://"..cabin_tv_program[i][1]
            tv_info[true]:Play()
            tv_info[true].Completed:Wait()
            task.wait(cabin_tv_program[i][2])
            if key == tv_info.Key then
                tv_info[false]:Play()
                tv_info[false].Completed:Wait()
            end
        end
    else
        tv_info[power]:Play() 
    end
end

local function teleport(player, my_info, index, ignore_debounce)
    local character = player.Character
    if not character then return end
    if character_debounce_list[character] and not ignore_debounce then return end
    character_debounce_list[character] = true
    if index == "Cabin_CFrame" then
        my_info.Visitors[player] = true
        locations[player] = my_info
    else
        my_info.Visitors[player] = nil
        locations[player] = nil
    end
    fade:FireClient(player)
    local seat = character.Humanoid.SeatPart
    if seat then
        seat.SeatWeld:Destroy()
    end
    task.wait(0.5)
    character:SetPrimaryPartCFrame(my_info[index])
    task.wait(1.5)
    character_debounce_list[character] = nil
end

local function init_cabin(my_info)

    local cabin = my_info.Default:Clone()
    local decal = Instance.new("Decal")
    local lights = {}

    my_info.Light_Info = {
        ["Power"] = true;
        ["Lights"] = lights;
    }
    my_info.Confetti_Info = {
        ["Power"] = false;
        ["Emitters"] = cabin.Confetti:GetChildren();
    }
    my_info.Tv_Info = {
        ["Power"] = false;
        ["Screen"] = decal;
        ["Key"] = os.time();
        [true] = generate_on_tween(decal);
        [false] = generate_off_tween(decal);
    }

    my_info.Locked = true
    my_info.Init_Time = os.time()
    my_info.Current_Cabin = cabin
    decal.Parent = cabin:FindFirstChild("TvScreen", true)

    for _, obj in ipairs(cabin:GetDescendants()) do
        local event
        if obj:IsA("Light") then
            table.insert(lights, obj)
        elseif obj.Name == "Arcade" then
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

    cabin.TPPart.Touched:Connect(function(hit)
        local player = players:GetPlayerFromCharacter(hit.Parent)
        if player then
            teleport(player, my_info, "Door_CFrame")
        end
    end)

    cabin.Parent = cabins

end

local function give_player_cabin(player, my_info)
    local sign = my_info.Sign
    sign.Owner.Text = "Owner: "..player.Name
    sign.Owner.BackgroundColor3 = owned_cabin_color
    sign.BuyCabin.BackgroundColor3 = owned_cabin_color
    owners[player] = my_info
    owners[my_info] = player
    init_cabin(my_info)
end

local function sell_cabin(player)

    local my_info = owners[player]
    if not my_info then return end

    local player_data_folder = replicated_storage[player.Name]
    local sign = my_info.Sign
    local current_cabin = my_info.Current_Cabin

    if not player_data_folder.Has_Free_Cabins_Pass.Value and my_info.Price then
        if player_data_folder.Has_VIP_Pass.Value then
            player_data_folder.Cash.Value += my_info.Price*0.6
        else
            player_data_folder.Cash.Value += my_info.Price*0.3
        end
    end

    player_data_folder.Owned_Cabin.Value = ""
    owners[my_info] = nil
    owners[player] = nil

    for visitor in pairs(my_info.Visitors) do
        if locations[visitor] ~= my_info then continue end
        task.spawn(function()
            teleport(visitor, my_info, "Door_CFrame", true)
        end)
    end

    sign.Owner.Text = "Owner: Nobody"
    sign.Owner.BackgroundColor3 = unowned_cabin_color
    sign.BuyCabin.BackgroundColor3 = unowned_cabin_color

    task.delay(3, function()
        current_cabin:Destroy()
    end)

end

for _, door in ipairs(doors:GetChildren()) do
    local cabin = server_cabins[door.Name]
    local my_info = {}

    local door_tp = door.TPPart
    local cabin_tp = cabin.TPPart
    local sign = door.CabinSign.BuyCabin
    local click_detector = door:FindFirstChildWhichIsA("ClickDetector", true)

    my_info.Visitors = {}

    my_info.Default = cabin
	my_info.Price = prices[door.Name:match("%D+")]
	my_info.Captain = door.Name:match("Captain")
    my_info.Cabin_CFrame = CFrame.fromMatrix(cabin_tp.Position + cabin_tp.CFrame.LookVector*5, cabin_tp.CFrame.LookVector:Cross(up_vector), up_vector)
    my_info.Door_CFrame = CFrame.fromMatrix(door_tp.Position + door_tp.CFrame.LookVector*5, door_tp.CFrame.LookVector:Cross(up_vector), up_vector)
    my_info.Sign = sign

    door_tp.Touched:Connect(function(hit)
        local player = players:GetPlayerFromCharacter(hit.Parent)
        if player and owners[my_info] and (owners[player] == my_info or not my_info.Locked) then
            if os.time() - my_info.Init_Time < 2 then return end
            teleport(player, my_info, "Cabin_CFrame")
        end
    end)

    click_detector.MouseClick:Connect(function(player)
        if owners[player] then
            send_cabin_info:FireClient(player, false)
            return
        end
        if owners[my_info] then return end
        local player_data_folder = replicated_storage[player.Name]
        if my_info.Price and not my_info.Captain then
            if player_data_folder.Has_Free_Cabins_Pass.Value then 
                give_player_cabin(player, my_info)
                player_data_folder.Owned_Cabin.Value = cabin.Name
            else
                send_cabin_info:FireClient(player, cabin.Name)
			end
		elseif my_info.Price and my_info.Captain then
			if player_data_folder.Has_Captain_Pass.Value then
				if player_data_folder.Has_Free_Cabins_Pass.Value then 
					give_player_cabin(player, my_info)
					player_data_folder.Owned_Cabin.Value = cabin.Name
				else
					send_cabin_info:FireClient(player, cabin.Name)
				end
			else
				send_cabin_info:FireClient(player, cabin.Name, true)
			end
        else
            if player_data_folder.Has_Underwater_Pass.Value then
                give_player_cabin(player, my_info)
                player_data_folder.Owned_Cabin.Value = cabin.Name
            else
                send_cabin_info:FireClient(player, cabin.Name)
            end
        end
    end)

    if my_info.Price then
        sign.CostText.Text = "Cost: "..my_info.Price.." Cash"
    else
        sign.CostText.Text = "Gamepass"
    end

    sign.Owner.Text = "Owner: Nobody"
    sign.ClassText.Text = labels[door.Name:match("%D+")]
    sign.Owner.BackgroundColor3 = unowned_cabin_color
    sign.BuyCabin.BackgroundColor3 = unowned_cabin_color

    cabin_info[door.Name] = my_info
end

remotes.Buy_Cabin.OnServerInvoke = function(player, cabin_name)
    local player_data_folder = replicated_storage[player.Name]
    local my_info = cabin_info[cabin_name]
    if owners[player] then
        return "You already own a cabin."
    elseif owners[my_info] then
        return "Someone already owns this cabin."
    end
    if my_info.Price then
        if player_data_folder.Has_Free_Cabins_Pass.Value then
            give_player_cabin(player, my_info)
        elseif player_data_folder.Cash.Value >= my_info.Price then
            player_data_folder.Cash.Value -= my_info.Price
            give_player_cabin(player, my_info)
        else
            return "You don't have enough cash to buy this cabin."
        end
        player_data_folder.Owned_Cabin.Value = cabin_name
    elseif player_data_folder.Has_Underwater_Pass.Value then
        give_player_cabin(player, my_info)
    end
end

remotes.Sell_Cabin.OnServerEvent:Connect(sell_cabin)
remotes.Switch_Lights.OnServerEvent:Connect(switch_lights)
remotes.Switch_Confetti.OnServerEvent:Connect(switch_confetti)
remotes.Lock_Door.OnServerEvent:Connect(lock_door)
remotes.Switch_Tv.OnServerEvent:Connect(switch_tv)
get_cabin_refund.OnInvoke = sell_cabin

remotes.Teleport_To_Cabin.OnServerEvent:Connect(function(player)
	teleport(player, owners[player], "Door_CFrame")
end)

teleported.Event:Connect(function(player)
    locations[player] = nil
end)

players.PlayerRemoving:Connect(function(player)
    locations[player] = nil
end)
