local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local addOutfit = ReplicatedStorage.Remotes.AddOutfit
local getOutfits = ReplicatedStorage.Remotes.GetOutfits
local deleteOutfit = ReplicatedStorage.Remotes.DeleteOutfit
local updateOutfit = ReplicatedStorage.Remotes.UpdateOutfit
local saveDescription = ReplicatedStorage.Remotes.SaveDescription
local resetDescription = ReplicatedStorage.Remotes.ResetDescription
local applyDescription = ReplicatedStorage.Remotes.ApplyDescription

local loadCharacter = ServerStorage.Bindables.Load_Character
local getAppearanceData = ServerStorage.Bindables.Get_Appearance_Data
local sendAppearanceData = ServerStorage.Bindables.Send_Appearance_Data

local welcomeBadgeId = 2127252035

local debounceList = {}
local allOutfitData = {}

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

local debounces = {
	addOutfit = {},
	updateOutfit = {},
	deleteOutfit = {},
	requestSpawn = {},
	saveDescription = {},
	resetDescription = {},
	applyDescription = {},
}

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

local function serializeForDataStore(serializedHumanoidDescription)
	local serialized = deepCopy(serializedHumanoidDescription)
	for _, accessory in serialized.Accessories do
		accessory.AccessoryType = accessory.AccessoryType.Value
		accessory.Position = nil
		accessory.Rotation = nil
		accessory.Scale = nil
	end
	return serialized
end

local function deserializeFromDataStore(serializedHumanoidDescription)
	local deserialized = deepCopy(serializedHumanoidDescription)
	for _, accessory in deserialized.Accessories do
		accessory.AccessoryType = enumLookupTable[accessory.AccessoryType]
	end
	return deserialized
end

-- local function countIdsInString(IdString: string): number
--      return #IdString:split(",")
-- end
--

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

-- local function fullSerialize(description: HumanoidDescription)
--      return serializeForDataStore(serializeHumanoidDescription(description))
-- end

local function fullDeserialize(serializedHumanoidDescription)
	return deserializeHumanoidDescription(deserializeFromDataStore(serializedHumanoidDescription))
end

local function playerAdded(player: Player)
	player:LoadCharacter()
end

loadCharacter.Event:Connect(function(player)
	player:LoadCharacter()
end)

sendAppearanceData.Event:Connect(function(player: Player, outfitData: any)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	if outfitData.CurrentOutfit then
		humanoid:ApplyDescription(fullDeserialize(outfitData.CurrentOutfit))
	end
	
	allOutfitData[player.UserId] = outfitData
	
	if player.Character then
		player.Character:WaitForChild("Humanoid").Died:Connect(function()
			player:LoadCharacterWithHumanoidDescription(fullDeserialize(outfitData.CurrentOutfit))
		end)
	end
	
	player.CharacterAdded:Connect(function(new_character)
		new_character:WaitForChild("Humanoid").Died:Connect(function()
			player:LoadCharacterWithHumanoidDescription(fullDeserialize(outfitData.CurrentOutfit))
		end)
	end)
end)

getAppearanceData.OnInvoke = function(player: Player, last: boolean)
	if not allOutfitData[player.UserId] then
		return nil
	end
	
	local outfitData = deepCopy(allOutfitData[player.UserId])
	
	if last then
		allOutfitData[player.UserId] = nil
		debounceList[player.UserId] = nil
	end
	
	return outfitData
end

applyDescription.OnServerEvent:Connect(function(player, serializedHumanoidDescription)
	if debounces.applyDescription[player.UserId] then
		return
	end
	
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end
	
	debounces.applyDescription[player.UserId] = true

	humanoid:ApplyDescription(deserializeHumanoidDescription(serializedHumanoidDescription))
	
	task.wait(0.25)
	debounces.applyDescription[player.UserId] = nil
end)

resetDescription.OnServerEvent:Connect(function(player)
	if debounces.resetDescription[player.UserId] then
		return
	end
	debounces.resetDescription[player.UserId] = true
	
	player.Character.Humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(player.UserId))
	
	task.wait(0.25)
	debounces.resetDescription[player.UserId] = nil
end)

saveDescription.OnServerEvent:Connect(function(player, serializedHumanoidDescription)
	if debounces.saveDescription[player.UserId] then
		return
	end
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end
	
	debounces.saveDescription[player.UserId] = true

	humanoid:ApplyDescription(deserializeHumanoidDescription(serializedHumanoidDescription))
	allOutfitData[player.UserId].CurrentOutfit = serializeForDataStore(serializedHumanoidDescription)
	
	task.wait(0.25)
	debounces.saveDescription[player.UserId] = nil
end)

addOutfit.OnServerEvent:Connect(function(player, serializedHumanoidDescription)
	if debounces.addOutfit[player.UserId] then
		return
	end
	
	debounces.addOutfit[player.UserId] = true
	
	if allOutfitData[player.UserId] and #allOutfitData[player.UserId].Outfits < 10 then
		table.insert(allOutfitData[player.UserId].Outfits, serializeForDataStore(serializedHumanoidDescription))
	end
	
	task.wait(0.25)
	debounces.addOutfit[player.UserId] = nil
end)

deleteOutfit.OnServerEvent:Connect(function(player, outfitIndex)
	if debounces.deleteOutfit[player.UserId] then
		return
	end
	
	debounces.deleteOutfit[player.UserId] = true
	
	if allOutfitData[player.UserId] and #allOutfitData[player.UserId].Outfits >= outfitIndex then
		table.remove(allOutfitData[player.UserId].Outfits, outfitIndex)
	end
	
	task.wait(0.25)
	debounces.deleteOutfit[player.UserId] = nil
end)

updateOutfit.OnServerEvent:Connect(function(player, outfitIndex, serializedHumanoidDescription)
	if debounces.updateOutfit[player.UserId] then
		return
	end
	
	debounces.updateOutfit[player.UserId] = true
	
	if allOutfitData[player.UserId] and #allOutfitData[player.UserId].Outfits >= outfitIndex then
		allOutfitData[player.UserId].Outfits[outfitIndex] = serializeForDataStore(serializedHumanoidDescription)
	end
	
	task.wait(0.25)
	debounces.updateOutfit[player.UserId] = nil
end)

getOutfits.OnServerInvoke = function(player)
	return allOutfitData[player.UserId] and allOutfitData[player.UserId].Outfits
end

ReplicatedStorage.Remotes.Request_Spawn.OnServerEvent:Connect(function(player: Player, location: string?)
	if debounces.requestSpawn[player.UserId] then
		return
	end
	
	debounces.requestSpawn[player.UserId] = true
	
	task.delay(0.25, function()
		debounces.requestSpawn[player.UserId] = nil
	end)
	
	if ReplicatedStorage[player.Name].Did_Tutorial.Value then
		player.ReplicationFocus = nil
	end
	
	task.spawn(function()
		if debounceList[player.UserId] then
			return
		end
		debounceList[player.UserId] = true
		if not BadgeService:UserHasBadgeAsync(player.UserId, welcomeBadgeId) then
			BadgeService:AwardBadge(player.UserId, welcomeBadgeId)
		end
	end)
	
	if location == "Teleport1" then
		if allOutfitData[player.UserId] and allOutfitData[player.UserId].CurrentOutfit then
			player:LoadCharacterWithHumanoidDescription(fullDeserialize(allOutfitData[player.UserId].CurrentOutfit))
		else
			player:LoadCharacter()
		end
	end
	
	if type(location) ~= "string" or not workspace.MenuSpawns:FindFirstChild(location) then
		return
	end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local teleporting = ReplicatedStorage[player.Name].Teleporting
	
	teleporting.Value = true
	ReplicatedStorage.Remotes.Fade:FireClient(player)
	
	task.wait(0.5)
	
	local seat = character:WaitForChild("Humanoid").SeatPart
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
	
	character:SetPrimaryPartCFrame(CFrame.new(workspace.MenuSpawns[location].Position + Vector3.new(0, 7, 0)))
	
	task.wait(1)
	
	teleporting.Value = false
end)

Players.PlayerAdded:Connect(playerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		playerAdded(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	for _, debounceMap in pairs(debounces) do
		debounceMap[player.UserId] = nil
	end
end)
