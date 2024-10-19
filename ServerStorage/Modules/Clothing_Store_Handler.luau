--[[ Services ]]
--

local marketplace_service = game:GetService "MarketplaceService"

--[[ General ]]
--

local function handle_stand(stand)
	local pants_model = stand.Pants
	local shirt_model = stand.Shirt
	local pants_id = pants_model.ID.Value
	local shirt_id = shirt_model.ID.Value
	local pants_buy = pants_model:FindFirstChild "Buy"
	if pants_buy then
		pants_buy.ClickDetector.MouseClick:Connect(function(player)
			local success, owns = pcall(marketplace_service.PlayerOwnsAsset, marketplace_service, player, pants_id)
			if success and not owns then
				pcall(marketplace_service.PromptPurchase, marketplace_service, player, pants_id)
			end
		end)
	end
	local shirt_buy = shirt_model:FindFirstChild "Buy"
	if shirt_buy then
		shirt_buy.ClickDetector.MouseClick:Connect(function(player)
			local success, owns = pcall(marketplace_service.PlayerOwnsAsset, marketplace_service, player, shirt_id)
			if success and not owns then
				pcall(marketplace_service.PromptPurchase, marketplace_service, player, shirt_id)
			end
		end)
	end
end

return handle_stand
