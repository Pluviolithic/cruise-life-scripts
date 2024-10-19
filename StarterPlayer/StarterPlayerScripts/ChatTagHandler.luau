local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new "TextChatMessageProperties"

	if message.TextSource then
		local prefixText = ""
		local sendingPlayer = Players:GetPlayerByUserId(message.TextSource.UserId)

		if sendingPlayer:GetAttribute "isVIP" == true then
			prefixText = '<font color="rgb(255, 176, 0)">[VIP]</font>'
		end
		
		if sendingPlayer:GetAttribute "isDeveloper" then
			prefixText = '<font color="rgb(255, 0, 0)">[Developer]</font>' .. prefixText
		elseif sendingPlayer:GetAttribute "isContributor" then
			prefixText = '<font color="rgb(75, 151, 75)">[Contributor]</font> ' .. prefixText
		end
		
		if prefixText ~= "" then
			props.PrefixText = `{prefixText} {message.PrefixText}`
		end
	end

	return props
end
