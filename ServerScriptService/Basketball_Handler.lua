local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local basketballs = workspace.Basketballs

for _, tool in ipairs(basketballs:GetChildren()) do

    local default = tool:Clone()
    local basketball = tool.Handle
    local start_cframe = basketball.CFrame
    local debounce, debounce_two = true, true
    local event = Instance.new("BindableEvent")

    local handle_changes; handle_changes = function()
        tool.Fire.OnServerEvent:Connect(function(player, v)
            if tool:FindFirstAncestor(player.Name) then
                tool.Parent = workspace
                tool.Handle.Position = player.Character.Head.Position + v*5
                tool.Handle.Velocity = v*100
            end
        end)
        tool.Handle.Touched:Connect(function(hit)
            if hit.Name == "Boundary" then
                tool:Destroy()
                return
            end
            if not debounce then return end
            if not debounce_two then return end
            local character = hit.Parent
            if players:GetPlayerFromCharacter(character) and character.Humanoid.Health > 0 and not character:FindFirstChildWhichIsA("Tool") then
                tool.Parent = character
                debounce = false
                task.wait(1)
                debounce = true
            end
        end)
        tool.AncestryChanged:Connect(function()
            if not tool:IsDescendantOf(game) then
                tool = default:Clone()
                tool.Handle.CFrame = start_cframe
                tool.Parent = workspace
                handle_changes()
            elseif not tool.Parent:FindFirstChildWhichIsA("Humanoid") then
                debounce_two = false
                task.wait(0.25)
                tool.Parent = workspace
                task.wait(0.5)
                debounce_two = true
            end
        end)
    end

    handle_changes()

    event.Event:Connect(function()
        while (tool.Handle.Position - start_cframe.Position).Magnitude < 60 do
            tool.GripPos = Vector3.new(0, 0.5, 0)
            task.wait(0.1)
            tool.GripPos = Vector3.new(0, 1, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 1.5, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 2, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 2.5, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 3, 0)
            task.wait(0.1)
            tool.GripPos = Vector3.new(0, 2.5, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 2, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 1.5, 0)
            task.wait(0.05)
            tool.GripPos = Vector3.new(0, 1, 0)
	        task.wait(0.05)
        end
        tool:Destroy()
        event:Fire()
    end)
    event:Fire()

end
