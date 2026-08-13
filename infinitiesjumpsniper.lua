--// Phathub-Fps sniperscript - Ultimate Auto-Hunt Edition (Final V5 - Memory Optimized & Auto-Save)
--// Tích hợp: VIM Stealth Shoot, Auto Patrol, Auto Jump, Auto Respawn, Auto Refresh 120s, Username Config

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// CẤU HÌNH MẶC ĐỊNH & TỰ ĐỘNG LƯU THEO USERNAME
-- Executor tự động trỏ writefile/readfile vào thư mục workspace của nó (ví dụ Xeno/workspace)
local ConfigName = LocalPlayer.Name .. "_config.json"
local CFG = {
	AimEnabled = true,
	ShowFOV = true,
	BoxEnabled = true,
	TracerEnabled = true,
	TeamCheck = false,
	WallCheck = true,
	AimPart = "Head",
	FOV = 100,
	Smooth = 0,
	
	NukeMode = false, 
	AutoShoot = false, 
	AutoHuntReady = false, 
	
	-- Tính năng nhảy (Sống mới nhảy)
	AutoJumpEnabled = false, 
	AutoJumpInterval = 6.0, 
	
	-- Tính năng Spam Space (Để hồi sinh)
	AutoRespawnEnabled = false, 
	AutoRespawnInterval = 5.0, 
	
	Teammates = {},
	Target1v1 = nil 
}

--// HỆ THỐNG LƯU/ĐỌC CONFIG
local function SaveConfig()
	if writefile then
		pcall(function()
			local json = HttpService:JSONEncode(CFG)
			writefile(ConfigName, json)
		end)
	end
end

local function LoadConfig()
	if isfile and isfile(ConfigName) then
		pcall(function()
			local data = readfile(ConfigName)
			local decoded = HttpService:JSONDecode(data)
			for k, v in pairs(decoded) do
				if CFG[k] ~= nil then CFG[k] = v end
			end
		end)
	end
end

-- Load cấu hình ngay khi bật
LoadConfig()

local state = {
	Minimized = true,
	HoldingAim = false,
	LockedTarget = nil,
	AutoHuntActive = false,
	AutoJumpTimer = 0,
	AutoRespawnTimer = 0, 
	WanderTarget = nil,
	WanderTimer = 0, 
	Connections = {}
}

--// MINI HUD CHO AUTO HUNT, AUTO JUMP VÀ AUTO RESPAWN
local customGui = Instance.new("ScreenGui")
customGui.Name = "Phathub_Customs"
customGui.ResetOnSpawn = false
pcall(function() customGui.Parent = CoreGui end)
if not customGui.Parent then customGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local miniHud = Instance.new("Frame", customGui)
miniHud.Size = UDim2.new(0, 180, 0, 100) 
miniHud.Position = UDim2.new(0.5, 250, 0.5, -35)
miniHud.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
miniHud.Active = true
miniHud.Draggable = true
miniHud.Visible = CFG.AutoHuntReady
Instance.new("UICorner", miniHud).CornerRadius = UDim.new(0, 8)
local hudStroke = Instance.new("UIStroke", miniHud)
hudStroke.Color = Color3.fromRGB(255, 60, 60)
hudStroke.Thickness = 2

local statusLbl = Instance.new("TextLabel", miniHud)
statusLbl.Size = UDim2.new(1, 0, 0.3, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "AUTO HUNT: OFF [K]"
statusLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 13

-- NÚT AUTO JUMP (Hàng 1)
local jumpFrame = Instance.new("Frame", miniHud)
jumpFrame.Size = UDim2.new(1, 0, 0.3, 0)
jumpFrame.Position = UDim2.new(0, 0, 0.3, 0)
jumpFrame.BackgroundTransparency = 1

local jumpBtn = Instance.new("TextButton", jumpFrame)
jumpBtn.Size = UDim2.new(0.6, 0, 0.8, 0)
jumpBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
jumpBtn.Text = "Auto Jump: " .. (CFG.AutoJumpEnabled and "ON" or "OFF")
jumpBtn.BackgroundColor3 = CFG.AutoJumpEnabled and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(60, 60, 70)
jumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpBtn.Font = Enum.Font.GothamBold;
jumpBtn.TextSize = 11
Instance.new("UICorner", jumpBtn).CornerRadius = UDim.new(0, 4)

local jumpTimeBox = Instance.new("TextBox", jumpFrame)
jumpTimeBox.Size = UDim2.new(0.25, 0, 0.8, 0)
jumpTimeBox.Position = UDim2.new(0.7, 0, 0.1, 0)
jumpTimeBox.Text = tostring(CFG.AutoJumpInterval)
jumpTimeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
jumpTimeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpTimeBox.Font = Enum.Font.GothamBold;
jumpTimeBox.TextSize = 11
Instance.new("UICorner", jumpTimeBox).CornerRadius = UDim.new(0, 4)

jumpBtn.MouseButton1Click:Connect(function()
	CFG.AutoJumpEnabled = not CFG.AutoJumpEnabled
	jumpBtn.Text = "Auto Jump: " .. (CFG.AutoJumpEnabled and "ON" or "OFF")
	jumpBtn.BackgroundColor3 = CFG.AutoJumpEnabled and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(60, 60, 70)
	SaveConfig()
end)

jumpTimeBox.FocusLost:Connect(function()
	local val = tonumber(jumpTimeBox.Text)
	if val then CFG.AutoJumpInterval = val else jumpTimeBox.Text = tostring(CFG.AutoJumpInterval) end
	SaveConfig()
end)

-- NÚT AUTO RESPAWN (Hàng 2)
local respawnFrame = Instance.new("Frame", miniHud)
respawnFrame.Size = UDim2.new(1, 0, 0.3, 0)
respawnFrame.Position = UDim2.new(0, 0, 0.65, 0)
respawnFrame.BackgroundTransparency = 1

local respawnBtn = Instance.new("TextButton", respawnFrame)
respawnBtn.Size = UDim2.new(0.6, 0, 0.8, 0)
respawnBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
respawnBtn.Text = "Auto Space: " .. (CFG.AutoRespawnEnabled and "ON" or "OFF")
respawnBtn.BackgroundColor3 = CFG.AutoRespawnEnabled and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(60, 60, 70)
respawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
respawnBtn.Font = Enum.Font.GothamBold; respawnBtn.TextSize = 11
Instance.new("UICorner", respawnBtn).CornerRadius = UDim.new(0, 4)

local respawnTimeBox = Instance.new("TextBox", respawnFrame)
respawnTimeBox.Size = UDim2.new(0.25, 0, 0.8, 0)
respawnTimeBox.Position = UDim2.new(0.7, 0, 0.1, 0)
respawnTimeBox.Text = tostring(CFG.AutoRespawnInterval)
respawnTimeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
respawnTimeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
respawnTimeBox.Font = Enum.Font.GothamBold;
respawnTimeBox.TextSize = 11
Instance.new("UICorner", respawnTimeBox).CornerRadius = UDim.new(0, 4)

respawnBtn.MouseButton1Click:Connect(function()
	CFG.AutoRespawnEnabled = not CFG.AutoRespawnEnabled
	respawnBtn.Text = "Auto Space: " .. (CFG.AutoRespawnEnabled and "ON" or "OFF")
	respawnBtn.BackgroundColor3 = CFG.AutoRespawnEnabled and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(60, 60, 70)
	SaveConfig()
end)

respawnTimeBox.FocusLost:Connect(function()
	local val = tonumber(respawnTimeBox.Text)
	if val then CFG.AutoRespawnInterval = val else respawnTimeBox.Text = tostring(CFG.AutoRespawnInterval) end
	SaveConfig()
end)


--// HỆ THỐNG DRAWING (ESP)
local espPool = {}

local function getESP(player)
	if not espPool[player.Name] then
		local b = Drawing.new("Square")
		b.Visible = false; b.Filled = false; b.Thickness = 1.5
		
		local t = Drawing.new("Line")
		t.Visible = false; t.Thickness = 1.5
		
		espPool[player.Name] = {Box = b, Tracer = t}
	end
	return espPool[player.Name]
end

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true; fovCircle.Filled = false;
fovCircle.Thickness = 1.5; fovCircle.NumSides = 90; fovCircle.Color = Color3.fromRGB(255, 255, 255)

local function getCenter()
	-- Luôn luôn dùng tâm màn hình chuẩn, không bị lệch
	return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function getPlayerStatus(player)
	if player == LocalPlayer then return "None" end
	if CFG.Teammates[player.Name] then return "Excluded" end
	if CFG.TeamCheck and player.Team == LocalPlayer.Team then return "Excluded" end
	if CFG.Target1v1 ~= nil and CFG.Target1v1 ~= "" then
		if player.Name ~= CFG.Target1v1 then return "Excluded" end
	end
	return "Valid"
end

local function isValidTarget(char)
	if not char or char == LocalPlayer.Character then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return false end
	if not head then return false end
	return true
end

local function hasLineOfSight(targetPart)
	if not CFG.WallCheck then return true end 
	local origin = Camera.CFrame.Position
	local direction = targetPart.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local ignoreList = {targetPart.Parent}
	if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
	params.FilterDescendantsInstances = ignoreList
	local result = workspace:Raycast(origin, direction, params)
	return result == nil
end

table.insert(state.Connections, Players.PlayerRemoving:Connect(function(player)
	if espPool[player.Name] then
		pcall(function() espPool[player.Name].Box:Remove() end)
		pcall(function() espPool[player.Name].Tracer:Remove() end)
		espPool[player.Name] = nil
	end
	if state.LockedTarget and state.LockedTarget.Parent == player.Character then
		state.LockedTarget = nil
	end
	CFG.Teammates[player.Name] = nil
	if CFG.Target1v1 == player.Name then CFG.Target1v1 = nil end
	
	if player == LocalPlayer then SaveConfig() end
end))

--// UI SETUP CHÍNH
local gui = Instance.new("ScreenGui")
gui.Name = "PhathubFPS_Script";
gui.ResetOnSpawn = false
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 460, 0, 450); -- Mở to sẵn
main.Position = UDim2.new(0.5, -230, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25); main.Active = true; main.Draggable = true
main.ClipsDescendants = true;
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(70, 130, 255);
stroke.Thickness = 2

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -80, 0, 40); title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1;
title.Text = "Phathub-Fps sniperscript (RShift = Hide)"
title.TextColor3 = Color3.fromRGB(255, 255, 255); title.Font = Enum.Font.GothamBold; title.TextSize = 14;
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.new(0, 28, 0, 28);
closeBtn.Position = UDim2.new(1, -35, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold;
closeBtn.TextSize = 14; Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local miniBtn = Instance.new("TextButton", main)
miniBtn.Size = UDim2.new(0, 28, 0, 28);
miniBtn.Position = UDim2.new(1, -70, 0, 6)
miniBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80); miniBtn.Text = "-"; miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.Font = Enum.Font.GothamBold;
miniBtn.TextSize = 16; Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 6)

local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -20, 0, 35);
tabBar.Position = UDim2.new(0, 10, 0, 45); tabBar.BackgroundTransparency = 1

local function createTabBtn(name, x)
	local b = Instance.new("TextButton", tabBar)
	b.Size = UDim2.new(0.25, -5, 1, 0);
	b.Position = UDim2.new(x, 0, 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(35, 35, 45); b.Text = name; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold;
	b.TextSize = 11; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local btnMain = createTabBtn("MAIN", 0);
local btnTeam = createTabBtn("TEAM", 0.25)
local btn1v1 = createTabBtn("1V1", 0.5); local btnGui = createTabBtn("GUI", 0.75)

local pageContainer = Instance.new("Frame", main)
pageContainer.Size = UDim2.new(1, -20, 1, -90);
pageContainer.Position = UDim2.new(0, 10, 0, 85); pageContainer.BackgroundTransparency = 1

local function createPage(name)
	local p = Instance.new("ScrollingFrame", pageContainer)
	p.Name = name;
	p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = false
	p.ScrollBarThickness = 4;
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0, 8)
	return p
end

local pMain = createPage("Main"); pMain.Visible = true
local pTeam = createPage("Team")
local p1v1 = createPage("1v1")
local pGui = createPage("Gui")

btnMain.MouseButton1Click:Connect(function() pMain.Visible = true; pTeam.Visible = false; p1v1.Visible = false; pGui.Visible = false end)
btnTeam.MouseButton1Click:Connect(function() pMain.Visible = false; pTeam.Visible = true; p1v1.Visible = false; pGui.Visible = false end)
btn1v1.MouseButton1Click:Connect(function() pMain.Visible = false; pTeam.Visible = false; p1v1.Visible = true; pGui.Visible = false end)
btnGui.MouseButton1Click:Connect(function() pMain.Visible = false; pTeam.Visible = false; p1v1.Visible = false; pGui.Visible = true end)

--// LOGIC TEAM & LIST RELOAD & RESET ESP
local teamListFrame = Instance.new("Frame", pTeam); teamListFrame.Size = UDim2.new(1, 0, 0, 0); teamListFrame.BackgroundTransparency = 1; teamListFrame.AutomaticSize = Enum.AutomaticSize.Y
local layout1 = Instance.new("UIListLayout", teamListFrame); layout1.Padding = UDim.new(0, 5)

local oneVOneListFrame = Instance.new("Frame", p1v1); oneVOneListFrame.Size = UDim2.new(1, 0, 0, 0); oneVOneListFrame.BackgroundTransparency = 1; oneVOneListFrame.AutomaticSize = Enum.AutomaticSize.Y
local layout2 = Instance.new("UIListLayout", oneVOneListFrame); layout2.Padding = UDim.new(0, 5)

local function reloadLists()
	for _, child in ipairs(teamListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, child in ipairs(oneVOneListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		
		local tBtn = Instance.new("TextButton", teamListFrame)
		tBtn.Size = UDim2.new(1, -10, 0, 30);
		tBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
		tBtn.BackgroundColor3 = CFG.Teammates[p.Name] and Color3.fromRGB(220, 200, 50) or Color3.fromRGB(35, 35, 45)
		tBtn.TextColor3 = CFG.Teammates[p.Name] and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
		tBtn.Font = Enum.Font.GothamSemibold;
		tBtn.TextSize = 12; Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 4)
		tBtn.MouseButton1Click:Connect(function() CFG.Teammates[p.Name] = not CFG.Teammates[p.Name]; SaveConfig(); reloadLists() end)
		
		local oBtn = Instance.new("TextButton", oneVOneListFrame)
		oBtn.Size = UDim2.new(1, -10, 0, 30);
		oBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
		local isTarget = (CFG.Target1v1 == p.Name)
		oBtn.BackgroundColor3 = isTarget and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(35, 35, 45)
		oBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		oBtn.Font = Enum.Font.GothamSemibold;
		oBtn.TextSize = 12; Instance.new("UICorner", oBtn).CornerRadius = UDim.new(0, 4)
		oBtn.MouseButton1Click:Connect(function()
			if CFG.Target1v1 == p.Name then CFG.Target1v1 = nil else CFG.Target1v1 = p.Name end
			SaveConfig()
			reloadLists()
		end)
	end
end

--// CHỨC NĂNG DỌN RÁC ESP VÀ TẠO LẠI BỘ NHỚ (RESET ESP)
local function ForceResetESP()
	-- Xóa bộ nhớ cũ
	for _, esp in pairs(espPool) do
		pcall(function() esp.Box:Remove(); esp.Tracer:Remove() end)
	end
	table.clear(espPool)
	state.LockedTarget = nil
	state.WanderTarget = nil
	
	-- Quét lại danh sách player
	reloadLists()
	print("ESP Memory Cleared and Reloaded!")
end

--// NÚT RESET ESP Ở TRÊN CÙNG MAIN TAB
local resetEspBtn = Instance.new("TextButton", pMain)
resetEspBtn.Size = UDim2.new(1, -10, 0, 35)
resetEspBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
resetEspBtn.Text = "FORCE RESET ESP & TARGETS"
resetEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetEspBtn.Font = Enum.Font.GothamBold
resetEspBtn.TextSize = 14
Instance.new("UICorner", resetEspBtn).CornerRadius = UDim.new(0, 6)
resetEspBtn.MouseButton1Click:Connect(ForceResetESP)

--// CÁC NÚT CÀI ĐẶT
local function createToggle(name, configKey, callback)
	local btn = Instance.new("TextButton", pMain)
	btn.Size = UDim2.new(1, -10, 0, 35);
	btn.BackgroundColor3 = CFG[configKey] and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(45, 45, 55)
	btn.Text = name .. ": " .. (CFG[configKey] and "ON" or "OFF");
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14;
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.MouseButton1Click:Connect(function()
		CFG[configKey] = not CFG[configKey]
		btn.BackgroundColor3 = CFG[configKey] and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(45, 45, 55)
		btn.Text = name .. ": " .. (CFG[configKey] and "ON" or "OFF")
		SaveConfig() -- Tự lưu khi thay đổi toggle
		if callback then callback() end
	end)
end

local function createInput(name, configKey)
	local frame = Instance.new("Frame", pMain)
	frame.Size = UDim2.new(1, -10, 0, 35);
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(0.5, 0, 1, 0);
	lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1
	lbl.Text = name; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.Font = Enum.Font.GothamSemibold;
	lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left
	local box = Instance.new("TextBox", frame)
	box.Size = UDim2.new(0.4, 0, 0.8, 0);
	box.Position = UDim2.new(0.55, 0, 0.1, 0); box.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	box.TextColor3 = Color3.fromRGB(255, 255, 255); box.Font = Enum.Font.GothamBold;
	box.TextSize = 14; box.Text = tostring(CFG[configKey])
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then CFG[configKey] = val else box.Text = tostring(CFG[configKey]) end
		SaveConfig() -- Tự lưu khi nhập số mới
	end)
end

createToggle("AUTO HUNT (Standby Mode)", "AutoHuntReady", function()
	miniHud.Visible = CFG.AutoHuntReady
	if not CFG.AutoHuntReady then
		state.AutoHuntActive = false
		statusLbl.Text = "AUTO HUNT: OFF [K]"
		statusLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
		hudStroke.Color = Color3.fromRGB(255, 60, 60)
	end
end)

createToggle("Aimbot (Hold RMB)", "AimEnabled")
createToggle("NUKE MODE (360 Lock)", "NukeMode")
createToggle("Auto Shoot (On Hold)", "AutoShoot")
createToggle("Wallbang (No Raycast)", "WallCheck") 
createToggle("Show FOV Circle", "ShowFOV")
createToggle("ESP Boxes", "BoxEnabled")
createToggle("ESP Tracers", "TracerEnabled")
createInput("FOV Radius", "FOV")
createInput("Smooth (0 for Snap)", "Smooth")

local function createInfoLabel(parent, text)
	local l = Instance.new("TextLabel", parent)
	l.Size = UDim2.new(1, -10, 0, 40);
	l.BackgroundTransparency = 1; l.TextWrapped = true
	l.Text = text; l.TextColor3 = Color3.fromRGB(200, 200, 200); l.Font = Enum.Font.Gotham; l.TextSize = 12;
	l.TextYAlignment = Enum.TextYAlignment.Top
end
local function createReloadBtn(parent)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1, -10, 0, 30);
	b.BackgroundColor3 = Color3.fromRGB(220, 140, 30)
	b.Text = "RELOAD PLAYER LIST [Key O]"; b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Font = Enum.Font.GothamBold; b.TextSize = 12;
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

createInfoLabel(pTeam, "Tick your team and remove here form aimbot and esp (Turned Yellow & Ignored)")
local reloadTeamBtn = createReloadBtn(pTeam)
reloadTeamBtn.MouseButton1Click:Connect(reloadLists)

createInfoLabel(p1v1, "Select ONLY ONE target for 1v1. Unselected players will be Yellow & Ignored.")
local reload1v1Btn = createReloadBtn(p1v1)
reload1v1Btn.MouseButton1Click:Connect(reloadLists)

--// VÒNG LẶP TỰ ĐỘNG RESET ESP & TẢI LẠI DANH SÁCH (120 GIÂY)
task.spawn(function()
	while true do
		task.wait(120) 
		pcall(function()
			ForceResetESP()
		end)
	end
end)

--// MINIMIZE VÀ CLEANUP
miniBtn.MouseButton1Click:Connect(function()
	state.Minimized = not state.Minimized
	if state.Minimized then
		miniBtn.Text = "+"; main.Size = UDim2.new(0, 460, 0, 40) 
	else
		miniBtn.Text = "-"; main.Size = UDim2.new(0, 460, 0, 450)
	end
end)

local function killScript()
	RunService:UnbindFromRenderStep("Phathub_AimAssist")
	for _, conn in ipairs(state.Connections) do if conn.Connected then conn:Disconnect() end end
	table.clear(state.Connections)
	pcall(function() fovCircle:Remove() end)
	for _, esp in pairs(espPool) do pcall(function() esp.Box:Remove(); esp.Tracer:Remove() end) end
	table.clear(espPool)
	if gui then gui:Destroy() end
	if customGui then customGui:Destroy() end
end
closeBtn.MouseButton1Click:Connect(killScript)

--// LOGIC CHUỘT VÀ BÀN PHÍM
table.insert(state.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then state.HoldingAim = true end
	if not gpe then
		if input.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
		if input.KeyCode == Enum.KeyCode.O then reloadLists() end
		if input.KeyCode == Enum.KeyCode.F10 then SaveConfig() end
		
		if input.KeyCode == Enum.KeyCode.K and CFG.AutoHuntReady then
			state.AutoHuntActive = not state.AutoHuntActive
			if state.AutoHuntActive then
				statusLbl.Text = "AUTO HUNT: ON [K]"
				statusLbl.TextColor3 = Color3.fromRGB(50, 255, 50)
				hudStroke.Color = Color3.fromRGB(50, 255, 50)
			else
				statusLbl.Text = "AUTO HUNT: OFF [K]"
				statusLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
				hudStroke.Color = Color3.fromRGB(255, 60, 60)
				state.LockedTarget = nil
				state.WanderTarget = nil
			end
		end
	end
end))

table.insert(state.Connections, UserInputService.InputEnded:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		state.HoldingAim = false
		if not state.AutoHuntActive then state.LockedTarget = nil end
		fovCircle.Color = Color3.fromRGB(255, 255, 255)
	end
end))

local function getClosestTarget()
	local bestPart = nil
	local bestDist = CFG.NukeMode and math.huge or CFG.FOV
	local center = getCenter()
	local camPos = Camera.CFrame.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if getPlayerStatus(player) == "Valid" and player.Character and isValidTarget(player.Character) then
			local targetPart = player.Character:FindFirstChild(CFG.AimPart) or player.Character:FindFirstChild("LowerTorso") or player.Character:FindFirstChild("Head")
			
			if targetPart and hasLineOfSight(targetPart) then
				if CFG.NukeMode then
					local dist3D = (targetPart.Position - camPos).Magnitude
					if dist3D < bestDist then
						bestDist = dist3D;
						bestPart = targetPart
					end
				else
					local screenPos, visible = Camera:WorldToViewportPoint(targetPart.Position)
					if visible then
						local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
						if dist2D < bestDist then
							bestDist = dist2D;
							bestPart = targetPart
						end
					end
				end
			end
		end
	end
	return bestPart
end

--// VÒNG LẶP RENDER CHÍNH
RunService:BindToRenderStep("Phathub_AimAssist", 201, function(dt)
	local center = getCenter()
	
	fovCircle.Position = center
	fovCircle.Radius = CFG.FOV
	fovCircle.Visible = CFG.ShowFOV
	
	if CFG.NukeMode then fovCircle.Color = Color3.fromRGB(200, 0, 200) else fovCircle.Color = Color3.fromRGB(255, 255, 255) end
	
	-- 1. AUTO HUNT (SAU KHI NHẤN K)
	if CFG.AutoHuntReady and state.AutoHuntActive then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		if not state.LockedTarget or not state.LockedTarget.Parent or not isValidTarget(state.LockedTarget.Parent) or not hasLineOfSight(state.LockedTarget) then
			state.LockedTarget = getClosestTarget()
		end

		if state.LockedTarget then
			fovCircle.Color = Color3.fromRGB(255, 0, 0) 
			local aimPos = state.LockedTarget.Position
			Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPos)
			
			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
				task.wait(0.01)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
			end)
		end
		
		if hum and root then
			state.WanderTimer = state.WanderTimer + dt
			
			if not state.WanderTarget or (root.Position - state.WanderTarget).Magnitude < 5 or state.WanderTimer >= 4 then
				local randX = math.random(-40, 40)
				local randZ = math.random(-40, 40)
				state.WanderTarget = root.Position + Vector3.new(randX, 0, randZ)
				state.WanderTimer = 0 
			end
			hum:MoveTo(state.WanderTarget)
		end
		
	-- 2. AIMBOT CƠ BẢN (HOLD CHUỘT PHẢI)
	elseif state.HoldingAim and CFG.AimEnabled then
		if not state.LockedTarget or not state.LockedTarget.Parent or not isValidTarget(state.LockedTarget.Parent) then
			state.LockedTarget = getClosestTarget()
		end

		if state.LockedTarget then
			fovCircle.Color = Color3.fromRGB(0, 255, 120) 
			local aimPos = state.LockedTarget.Position
			local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, aimPos)
			
			if CFG.Smooth == 0 then
				Camera.CFrame = targetCFrame 
			else
				local alpha = math.clamp(dt * (20 - CFG.Smooth), 0, 1)
				Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
			end

			if CFG.AutoShoot then
				pcall(function()
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
					task.wait(0.01)
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
				end)
			end
		end
	end
	
	-- 3. AUTO JUMP 
	if CFG.AutoJumpEnabled then
		state.AutoJumpTimer = state.AutoJumpTimer + dt
		if state.AutoJumpTimer >= CFG.AutoJumpInterval then
			state.AutoJumpTimer = 0
			pcall(function()
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
					LocalPlayer.Character.Humanoid.Jump = true 
				end
			end)
		end
	end

	-- 4. AUTO RESPAWN 
	if CFG.AutoRespawnEnabled then
		state.AutoRespawnTimer = state.AutoRespawnTimer + dt
		if state.AutoRespawnTimer >= CFG.AutoRespawnInterval then
			state.AutoRespawnTimer = 0
			pcall(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			end)
		end
	end

	-- 5. XỬ LÝ ESP
	local bottomCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		
		local esp = getESP(player)
		local char = player.Character
		local status = getPlayerStatus(player)

		if char and isValidTarget(char) then
			local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
			local head = char:FindFirstChild("Head")

			if root and head then
				local rootPos, rootVisible = Camera:WorldToViewportPoint(root.Position)
				local headPos, headVisible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
				local legPos, legVisible = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

				if rootVisible or headVisible then
					local height = math.abs(headPos.Y - legPos.Y)
					local width = height * 0.5
					
					local espColor
					if status == "Excluded" then
						espColor = Color3.fromRGB(255, 200, 0)
					elseif state.LockedTarget and state.LockedTarget.Parent == char then
						espColor = Color3.fromRGB(0, 255, 120)
					else
						espColor = Color3.fromRGB(255, 60, 60)
					end

					if CFG.BoxEnabled then
						esp.Box.Size = Vector2.new(width, height)
						esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
						esp.Box.Color = espColor; esp.Box.Visible = true
					else
						esp.Box.Visible = false
					end

					if CFG.TracerEnabled then
						esp.Tracer.From = bottomCenter; esp.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
						esp.Tracer.Color = espColor;
						esp.Tracer.Visible = true
					else
						esp.Tracer.Visible = false
					end
				else
					esp.Box.Visible = false; esp.Tracer.Visible = false
				end
			end
		else
			esp.Box.Visible = false;
			esp.Tracer.Visible = false
		end
	end
end)

reloadLists()
state.Minimized = false -- Ép mở Menu từ đầu để dễ thao tác
pcall(function() print("Phathub Ultimate Script V5 Loaded Successfully!") end)
