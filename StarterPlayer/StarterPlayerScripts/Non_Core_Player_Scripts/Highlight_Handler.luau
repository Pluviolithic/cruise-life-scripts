local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local CollectionService = game:GetService "CollectionService"

local chests = {}
local player = Players.LocalPlayer

local function addChest(chest)
	chests[chest] = true
end

local function removeChest(chest)
	chests[chest] = nil
end

for _, obj in CollectionService:GetTagged "TreasureChest" do
	addChest(obj)
end

CollectionService:GetInstanceAddedSignal("TreasureChest"):Connect(addChest)
CollectionService:GetInstanceRemovedSignal("TreasureChest"):Connect(removeChest)

while true do
	for chest in chests do
		if player:DistanceFromCharacter(chest.Position) > 300 then
			chest.Parent.Highlight.Enabled = false
		else
			chest.Parent.Highlight.Enabled = true
		end
	end
	task.wait(1)
end
