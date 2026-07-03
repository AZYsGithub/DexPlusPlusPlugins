--[[
	Secret Service Panel Module
	
	Ported from Serversided to Clientsided.
]]
local loadstring = (game:GetService("RunService"):IsStudio() and require(script.Parent.Loadstring)) or loadstring
-- Common Locals
local pluginData = {
	Name = "SecretServicePanel",
	FriendlyName = "Secret Service Panel",
}

local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, SecretServicePanel, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals



local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local SecretServicePanel = {}

	local window,codeFrame

	local output = {}
	local outputMax = 1000
	local outputOn = true

	SecretServicePanel.ViewScript = function(scr)
		local s,source = pcall(env.decompile or function() end,scr)
		if not s or not source then
			source = "local test = 5\n\nlocal c = test + tick()\ngame.Workspace.Board:Destroy()\nstring.match('wow\\'f',\"yes\",3.4e-5,true)\ngame. Workspace.Wow\nfunction bar() print(54) end\n string . match() string 4 .match()"
			source = source.."\n"..[==[
			function a.sad() end
			function a.b:sad() end
			function 4.why() end
			function a b() end
			function string.match() end
			function string.match.why() end
			function local() end
			function local.thing() end
			string  . "sad" match
			().magnitude = 3
			a..b
			a..b()
			a...b
			a...b()
			a....b
			a....b()
			string..match()
			string....match()
			]==]
		end

		codeFrame:SetText(source)
		window:Show()
	end

	SecretServicePanel.Init = function()
		local colorOutput = {
			[0] = Color3.new(1,1,1),
			[1] = Color3.new(0.4, 0.5, 1),
			[2] = Color3.new(1, 0.6, 0.4),
			[3] = Color3.new(1, 0, 0)	
		}

		window = Lib.Window.new()
		window:SetTitle("Secret Service Panel")
		window:Resize(500,350)
		window.PosX = 20
		window.PosY = workspace.CurrentCamera.ViewportSize.Y - 400
		SecretServicePanel.Window = window

		local exeFrame = Instance.new("Frame")
		exeFrame.BackgroundTransparency = 1
		exeFrame.Position = UDim2.new(0,0,0,20)
		exeFrame.Size = UDim2.new(1,0,1,-20)
		exeFrame.Parent = window.GuiElems.Content

		local consoleFrame = Instance.new("Frame")
		consoleFrame.BackgroundTransparency = 1
		consoleFrame.Position = UDim2.new(0,0,0,20)
		consoleFrame.Size = UDim2.new(1,0,1,-20)
		consoleFrame.Visible = false
		consoleFrame.Parent = window.GuiElems.Content

		local console

		local function switchTab(tab)
			if tab == "Executor" then
				exeFrame.Visible = true
				consoleFrame.Visible = false
			else
				exeFrame.Visible = false
				consoleFrame.Visible = true

				--[[
				-- TODO: Remove Later when fixed
				local f = Instance.new("Frame")
				f.BackgroundTransparency = 1
				f.Parent = console
				f:Destroy()
				]]
			end
		end

		-- Exec
		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,0)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-25)
		codeFrame.Frame.Parent = exeFrame

		-- TODO: REMOVE AND MAKE BETTER
		local copy = Instance.new("TextButton",window.GuiElems.Content)
		copy.BackgroundTransparency = 1
		copy.Size = UDim2.new(0.5,0,0,20)
		copy.Text = "Executor"
		copy.TextColor3 = Color3.new(1,1,1)

		copy.MouseButton1Click:Connect(function()
			switchTab("Executor")
		end)

		local save = Instance.new("TextButton",window.GuiElems.Content)
		save.BackgroundTransparency = 1
		save.Position = UDim2.new(0.5,0,0,0)
		save.Size = UDim2.new(0.5,0,0,20)
		save.Text = "Console"
		save.TextColor3 = Color3.new(1,1,1)

		save.MouseButton1Click:Connect(function()
			switchTab("Console")
		end)

		local exe = Instance.new("TextButton",exeFrame)
		exe.BackgroundTransparency = 1
		exe.Position = UDim2.new(0,0,1,-25)
		exe.Size = UDim2.new(1/3,0,0,25)
		exe.Text = "Execute"
		exe.TextColor3 = Color3.new(1,1,1)

		exe.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			loadstring(source)()
		end)

		local exeC = Instance.new("TextButton",exeFrame)
		exeC.BackgroundTransparency = 1
		exeC.Position = UDim2.new(1/3,0,1,-25)
		exeC.Size = UDim2.new(1/3,0,0,25)
		exeC.Text = "Execute & Console"
		exeC.TextColor3 = Color3.new(1,1,1)

		exeC.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			loadstring(source)()

			switchTab("Console")
		end)

		local clear = Instance.new("TextButton",exeFrame)
		clear.BackgroundTransparency = 1
		clear.Position = UDim2.new(2/3,0,1,-25)
		clear.Size = UDim2.new(1/3,0,0,25)
		clear.Text = "Clear"
		clear.TextColor3 = Color3.new(1,1,1)

		clear.MouseButton1Click:Connect(function()
			codeFrame:SetText("")
		end)

		-- Console

		console = Instance.new("Frame")
		console.BackgroundColor3 = Color3.fromRGB(35,35,35)
		console.BorderSizePixel = 0
		console.Size = UDim2.new(1,-16,1,-25-16)
		console.ClipsDescendants = true
		console.Parent = consoleFrame

		local toggle = Instance.new("TextButton",consoleFrame)
		toggle.BackgroundTransparency = 1
		toggle.Position = UDim2.new(0,0,1,-25)
		toggle.Size = UDim2.new(1/2,0,0,25)
		toggle.Text = "Toggle"
		toggle.TextColor3 = Color3.new(1,1,1)

		local update = Instance.new("TextButton",consoleFrame)
		update.BackgroundTransparency = 1
		update.Position = UDim2.new(1/2,0,1,-25)
		update.Size = UDim2.new(1/2,0,0,25)
		update.Text = "Update"
		update.TextColor3 = Color3.new(1,1,1)

		local scrollV = Lib.ScrollBar.new()
		scrollV.Gui.Parent = consoleFrame
		scrollV.Gui.Size = UDim2.new(0,16,1,-25-16)
		scrollV:Update()

		local scrollH = Lib.ScrollBar.new(true)
		scrollH.Gui.Parent = consoleFrame
		scrollH.Gui.Position = UDim2.new(0,0,1,-25-16)
		scrollH.Gui.Size = UDim2.new(1,-16,0,16)
		scrollH:Update()

		local labels = {}

		local function refreshConsole()
			local ySize = console.AbsoluteSize.Y
			local xSize = console.AbsoluteSize.X

			local rows = math.ceil(ySize/18)

			local maxCols = 0
			for i = 1,#output do
				local len = #output[i].Text
				if len > maxCols then
					maxCols = len
				end
			end

			local atBottom = scrollV.Index + scrollV.VisibleSpace >= scrollV.TotalSpace

			scrollH.VisibleSpace = xSize
			scrollH.TotalSpace = maxCols*8
			scrollV.VisibleSpace = math.ceil(ySize/18)
			scrollV.TotalSpace = #output+1

			if atBottom then scrollV.Index = scrollV.TotalSpace - scrollV.VisibleSpace end

			scrollH:Update()
			scrollV:Update()

			for i = 1,rows do
				local label = labels[i]
				if not label then
					label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.SourceSans
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextColor3 = Color3.new(1,1,1)
					label.TextSize = 14
					label.Parent = console
					labels[i] = label
				end
				label.Position = UDim2.new(0,-scrollH.Index,0,(i-1)*18)
				label.Size = UDim2.new(1,scrollH.Index,0,18)

				local msgData = output[i+scrollV.Index]
				if not msgData then
					label.Visible = false
				else
					label.Text = msgData.Time.." -- "..msgData.Text
					label.TextColor3 = msgData.Color
					label.Visible = true
				end
			end

			if rows >= 0 then
				for i = rows+1,#labels do
					labels[i]:Destroy()
					labels[i] = nil
				end
			end
		end

		console:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshConsole)

		scrollH.Increment = 8
		scrollH.WheelIncrement = 8

		scrollV.WheelIncrement = 3
		scrollV:SetScrollFrame(console)

		scrollV.Scrolled:Connect(refreshConsole)
		scrollH.Scrolled:Connect(refreshConsole)

		local function numberWithZero(num)
			return (num < 10 and "0" or "") .. num
		end

		local function ConvertTimeStamp(timeStamp)
			local localTime = timeStamp - os.time() + math.floor(tick())
			local dayTime = localTime % 86400

			local hour = math.floor(dayTime/3600)

			dayTime = dayTime - (hour * 3600)
			local minute = math.floor(dayTime/60)

			dayTime = dayTime - (minute * 60)
			local second = dayTime

			local h = numberWithZero(hour)
			local m = numberWithZero(minute)
			local s = numberWithZero(dayTime)

			s = string.format("%.2f",s)

			return string.format("%s:%s:%s", h, m, s)
		end

		local function addOutput(data,norefresh)
			data.Time = ConvertTimeStamp(data.Time)
			local lines = string.split(data.Text,"\n")

			for i = 1,#lines do
				output[#output+1] = {
					Text = lines[i],
					Color = data.Color,
					Time = data.Time
				}
				if #output > outputMax then
					table.remove(output,1)
				end
			end

			if not norefresh then refreshConsole() end
		end

		toggle.MouseButton1Click:Connect(function()
			outputOn = not outputOn
			addOutput({
				Text = "Console is "..(outputOn and "Enabled" or "Disabled"),
				Color = Color3.new(1,1,1),
				Time = tick()
			}, true)
			refreshConsole()
		end)

		game:GetService("LogService").MessageOut:Connect(function(msg, msgtype)
			if not outputOn then return end
			local data = {
				Text = msg,
				Time = tick(),
				Color = colorOutput[msgtype.Value]
			}
			addOutput(data,true)
			refreshConsole()
		end)

		local function getOutput()
			table.clear(output)
			local allOutput = game:GetService("LogService"):GetLogHistory()

			for i = 1,outputMax do
				local data = allOutput[i]
				if not data then break end

				-- parse text
				local parsedData = {
					Text = data.message,
					Time = data.timestamp,
					Color = colorOutput[data.messageType.Value]
				}

				addOutput(parsedData,true)
			end
			refreshConsole()
		end
		getOutput()

		update.MouseButton1Click:Connect(function()
			getOutput()
		end)

		codeFrame:SetText("-- This is CLIENT SIDED")
	end

	return SecretServicePanel
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main, PluginData = pluginData}
end