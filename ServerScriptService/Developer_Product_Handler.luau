--[[ Services ]]--

local players = game:GetService("Players")
local marketplace_service = game:GetService("MarketplaceService")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_storage = game:GetService("ServerStorage")
local run_service = game:GetService("RunService")

--[[ Variables ]]--

local product_purchase_decision = Enum.ProductPurchaseDecision
local not_processed_enum = product_purchase_decision.NotProcessedYet
local purchase_granted_enum = product_purchase_decision.PurchaseGranted

local modules = server_storage.Modules
local general_functions = require(modules.General_Functions)

local bindables = server_storage.Bindables
local player_joined = bindables.Player_Joined
local player_left = bindables.Player_Left
local get_used_codes = bindables.Get_Used_Codes

local rand_obj = Random.new()

local buy_cash_products = {
	[963443669] = 1500;
	[963446529] = 3250;
	[963446647] = 7500;
	[963446181] = 16000;
	[963446597] = 36000;
	[963446798] = 85000;
}

local buy_spins_products = {
	[963446897] = 2;
	[1132109720] = 5;
	[1132109946] = 10;
	[1132110191] = 25;
}

local buy_bait_products = {
	[1317445380] = 2;
	[1317445545] = 5;
	[1317445723] = 8;
	[1317445257] = 12;
}

local game_pass_ids = {
	[8441246] = "Has_Free_Cabins_Pass";
	[8441242] = "Has_VIP_Pass";
	[8441259] = "Has_Boom_Box_Pass";
	[8441245] = "Has_Captain_Pass";
	[8441258] = "Has_DJ_Pass";
	[8441243] = "Has_Starter_Pass";
	[10671713] = "Has_Free_Cars_Pass";
	[11355885] = "Has_Underwater_Pass";
	[45319605] = "Has_Luxury_Pass";
}

local already_redeemed_codes = {}

local codes = {
	["Discord!"] = function(player)
		local soaker = replicated_storage["Souvenirs"]["Rewards"]["Super Soaker"]
		soaker:Clone().Parent = replicated_storage[player.Name].Souvenirs
	end;

	["SPOOKY!"] = function(player)
		replicated_storage[player.Name].Spins.Value += 2

	end;
}

local expired_codes = {
	["NewIslandAlmostDone!!"] = true;
	["45kLikes!!"] = true;
	["NewSamuraiIsland!!"] = true;
	["BetterCars!!"] = true;
	["NewIslandUpdateInJuly!!"] = true;
	["May2023!!"] = true;
	["NewYears2023!!"] = true;
	["AprilShowers!!"] = true;
	["4kFollowers!!"] = true;
	["40kMembers!!"] = true;
	["Thanksgiving!!"] = true;
	["HappyHolidays!!"] = true;
	["40kLikes!!"] = true;
	["FishingUpdateSoon!!"] = true;
	["TwoSpinz!!"] = true;
	["35kGroupMembers!!"] = true;
	["3kTwitterFollowers!!"] = true;
	["NoMoreLag!!"] = true;
	["2500Followers!"] = true;
	["GymFix!!"] = true;
	["VehicleColors!!"] = true;
	["LessLag!!"] = true;
	["CaptainCabin!!"] = true;
	["TwoYears!!"] = true;
	["MUSIC!!"] = true;
	["ClubBubble!!"] = true;
	["30kLikes!!"] = true;
	["20mVisits!!"] = true;
	["BugFix"] = true;
	["2022!"] = true;
	["TripleSpinz!"] = true;
	["Spoooky!"] = true;
	["NewIslands!!"] = true;
	["25kLikes!!"] = true;
	["20kMembers!"] = true;
	["20kLikes!!"] = true;
	["NatusVincere"] = true;
	["ThankYou!"] = true;
	["12kLikes!!"] = true;
	["HappyHolidays!"] = true;
	["10kLikes!!"] = true;
	["3MVisits!"] = true;
	["PlayTogether!"] = true;
	["5kLikes!"] = true;
	["LuckySpinz"] = true;
	["FreeCars!"] = true;
	["1MVisits!"] = true;
	["DoubleSpin"] = true;
	["BetaSpins"] = true;
	["TESTERS"] = true;
	["TopSecretCode"] = true;
	["BetaCash"] = true;
	["Cruising"] = true;
	["500Likes!"] = true;
	["1000Likes!"] = true;
	["1500Followers!"] = true
}

local function fisher_yates_shuffle(t)
	for n = #t, 1, -1 do
		local k = rand_obj:NextInteger(1, n)
		t[n], t[k] = t[k], t[n]
	end
	return t
end

marketplace_service.ProcessReceipt = function(receipt_info)
	local cash_amount_to_give = buy_cash_products[receipt_info.ProductId]
	local spin_amount_to_give = buy_spins_products[receipt_info.ProductId]
	local bait_amount_to_give = buy_bait_products[receipt_info.ProductId]
	local player = players:GetPlayerByUserId(receipt_info.PlayerId)
	if not player then
		return not_processed_enum
	end
	local player_data_folder = replicated_storage[player.Name]
	if cash_amount_to_give then
		general_functions.Give_Cash(player, cash_amount_to_give)
		return purchase_granted_enum
	elseif spin_amount_to_give then
		replicated_storage[player.Name].Spins.Value += spin_amount_to_give
		return purchase_granted_enum
	elseif bait_amount_to_give then
		replicated_storage[player.Name].Bait.Value += bait_amount_to_give
		return purchase_granted_enum
	elseif receipt_info.ProductId == 1269958304 then
		if not (pcall(function()
				local options = player_data_folder.Last_Color_Change.Value:split(":")
				player_data_folder.Used_Color_Change_Purchase.Value = false
				player_data_folder[options[1].."_Color"].Value = options[2]
				replicated_storage.Remotes.Change_Car_Color:FireClient(player)
			end)) then return not_processed_enum end
		return purchase_granted_enum
	elseif receipt_info.ProductId == 1317445952 then
		if not workspace:FindFirstChild(replicated_storage.Miscellaneous.Current_Island_Name.Value) then
			return purchase_granted_enum
		end
		local current_island = workspace[replicated_storage.Miscellaneous.Current_Island_Name.Value]
		local spots = fisher_yates_shuffle(current_island.TreasureSpawns:GetChildren())
		for _, spot in ipairs(spots) do
			if spot:FindFirstChild("TreasureModel") then continue end
			local new_chest = server_storage.TreasureModel:Clone()
			new_chest:SetPrimaryPartCFrame(spot.CFrame)
			new_chest.Parent = spot
			break
		end
		replicated_storage.Remotes.Alert:FireAllClients("Treasure Spawned", player.Name.." has spawned in a treasure chest! Find it on the island and be among the first three to claim the treasure!")
		return purchase_granted_enum
	end
	return not_processed_enum
end

replicated_storage.Remotes.Redeem_Code.OnServerInvoke = function(player, code)

	local redeemed_codes = already_redeemed_codes[player.UserId]

	if type(code) == "string" and #code > 0 then
		if codes[code] then
			if code == "FreeCars!" and not replicated_storage[player.Name].Has_Free_Cars_Pass.Value then
				return "CODE INVALID"
			end
			if redeemed_codes[code] then
				return "ALREADY REDEEMED"
			else
				if type(codes[code]) == "number" then
					general_functions.Give_Cash(player, codes[code])
				elseif type(codes[code]) == "function" then
					codes[code](player)
				end
				redeemed_codes[code] = true;
				return "SUCCESSFULLY REDEEMED CODE!"
			end
		elseif expired_codes[code] then
			return "EXPIRED"
		else
			return "CODE INVALID"
		end
	end

end

replicated_storage.Remotes.Disable_Ad.OnServerEvent:Connect(function(player)
	replicated_storage[player.Name].Disabled_Advertisement.Value = true
end)

marketplace_service.PromptGamePassPurchaseFinished:Connect(function(player, purchased_pass_id, purchase_success)
	if not purchase_success then return end
	replicated_storage[player.Name][game_pass_ids[purchased_pass_id]].Value = true
	if game_pass_ids[purchased_pass_id] ~= "Has_VIP_Pass" or not replicated_storage[player.Name].Completed_Event.Value then return end
	replicated_storage[player.Name].Cash.Value += 250 -- this is hardcoded; may need to make it based on current event's prize value
end)

player_joined.Event:Connect(function(player, codes_redeemed)
	already_redeemed_codes[player.UserId] = codes_redeemed
end)

player_left.Event:Connect(function(player)
	already_redeemed_codes[player.UserId] = nil
end)

get_used_codes.OnInvoke = function(player)	
	return already_redeemed_codes[player.UserId]
end

local captain_clothes = workspace["Captain Clothes"]
local captain_pants = captain_clothes.Stand.Pants
local captain_shirt = captain_clothes.Stand.Shirt

captain_pants.Wear.ClickDetector.MouseClick:Connect(function(player)
	if replicated_storage[player.Name].Has_Captain_Pass.Value then
		local desc = player.Character.Humanoid:GetAppliedDescription()
		desc.Pants = captain_pants.ID.Value
		player.Character.Humanoid:ApplyDescription(desc)
	else
		marketplace_service:PromptGamePassPurchase(player, 8441245)
	end
end)

captain_shirt.Wear.ClickDetector.MouseClick:Connect(function(player)
	if replicated_storage[player.Name].Has_Captain_Pass.Value then
		local desc = player.Character.Humanoid:GetAppliedDescription()
		desc.Shirt = captain_shirt.ID.Value
		player.Character.Humanoid:ApplyDescription(desc)
	else
		marketplace_service:PromptGamePassPurchase(player, 8441245)
	end
end)

local player_debounce_list = {}
for _, obj in ipairs(workspace.VIPAreaBlocks:GetChildren()) do
	obj.Touched:Connect(function(hit)
		local player = players:GetPlayerFromCharacter(hit.Parent)
		if not player or player_debounce_list[player] or replicated_storage[player.Name].Has_VIP_Pass.Value then return end
		player_debounce_list[player] = true
		marketplace_service:PromptGamePassPurchase(player, 8441242)
		task.wait(1)
		player_debounce_list[player] = nil
	end)
end
