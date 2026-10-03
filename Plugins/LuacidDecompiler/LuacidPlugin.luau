--!nocheck

local LUACID_KEY = "NO_KEY"

--// PLUGIN DATA //--
local pluginData = {
	Name = "Luacid",
	FriendlyName = "Luacid Decompiler",
}

local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, Notebook
local API, RMD, env, service, plr, create, createSimple

local function initDeps(data)
	Main = data.Main ; Lib = data.Lib
	Apps = data.Apps ; Settings = data.Settings
	API = data.API ; RMD = data.RMD
	env = data.env ; service = data.service
	plr = data.plr ; create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer ; Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer ; Notebook = Apps.Notebook
end

--// HELPERS & VARIABLES //--
local make, typ, eep = Instance.new, type, task.wait
local UD2, UD, rgb, tostr = UDim2.new, UDim.new, Color3.fromRGB, tostring

local function setprops(object, props, parent)
	local instance = typ(object) == "string" and make(object) or object
	for key, value in props do
		instance[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function MAIN_SCRIPT_ROOT()
	
	--// Luacid Loader
	local HttpService, writefs = service.HttpService, env.writefile
	
	if LUACID_KEY ~= "NO_KEY" then
		_G.DecompilerKey = LUACID_KEY
	end
	
	env.loadstring(game:HttpGet("https://luacid.dev/script.lua"))()
	local DecompilerOptions = _G.DecompilerOptions
	
	local LuacidConfigs = {
		Indent = "tab",
		type_annotations = "functions",
		discard_names = "named",
		generated_names = "readable",
		inferred_name_case = "preserve",
		prefer_const = false,
		if_expressions = true,
		early_return = true,
		early_continue = true,
		interpolated_strings = true,
		math_constants = true,
		fold_single_use_temps = true,
		uninline_local_functions = true,
		reroll_unrolled_loops = true,
		unfold_module_tables = false,
		keep_dead_functions = true,
		unicode_strings = true,
		upvalue_comments = false,
		function_line_comments = false
	}
	
	if env.isfile("LuacidConfigs.json") then
		LuacidConfigs = HttpService:JSONDecode(env.readfile("LuacidConfigs.json"))
	else
		writefs("LuacidConfigs.json", HttpService:JSONEncode(LuacidConfigs))
	end
	
	_G.DecompilerOptions = LuacidConfigs
	
	local function EditConfig(name, value)
		LuacidConfigs[name] = value
		DecompilerOptions[name] = value
	end
	
	--// UI Functions
	local LuacidUI = {}
	local ListFrame
	
	local function AddDropdown(title, options, default, allowEmpty, sizeX)
		local frame = Lib.Frame.new()
		setprops(frame.Gui, {
			Transparency = 1,
			Size = UD2(1,0,0,20)
		}, ListFrame)
		
		local listlayout = setprops("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UD(0, 10)
		}, frame.Gui)
		
		local dropdown = Lib.DropDown.new()
		setprops(dropdown, {
			CanBeEmpty = allowEmpty,
			Size = UD2(0,sizeX or 75,0,15),
		}, frame.Gui)
		dropdown:SetOptions(options)
		if default then dropdown:SetSelected(default) end
		
		frame.Gui.AutomaticSize = Enum.AutomaticSize.X
		
		local label = Lib.Label.new()
		setprops(label, {
			Size = UD2(1, 0,1, -15),
			Text = title,
			TextTruncate = Enum.TextTruncate.AtEnd
		}, frame.Gui)
		
		return dropdown
	end
	
	local function AddText(text, color)
		local frame = Lib.Frame.new()
		setprops(frame.Gui, {
			Transparency = 1,
			Size = UD2(1,0,0,15),
		}, ListFrame)
		
		local label = setprops(Lib.Label.new(), {
			Size = UD2(1, 0,1, 0),
			TextColor3 = color or rgb(185,185,185),
			Text = text,
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd
		}, frame.Gui)
		
		return label
	end
	
	--// Main UI
	LuacidUI.Init = function()
		local window = Lib.Window.new()
		window:SetTitle("Luacid Configs")
		window:Resize(250, 375)
		LuacidUI.Window = window
		
		local content = window.GuiElems.Content
		
		ListFrame = setprops("ScrollingFrame", {
			Size = UD2(1, 0,1, -20),
			Position = UD2(0, 0, 0, 0),
			Transparency = 1,
			CanvasSize = UD2(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 16,
			BottomImage = "",
			TopImage = "",
			ScrollBarImageColor3 = rgb(70, 70, 70),
			ScrollBarImageTransparency = 0,
			ZIndex = 2,
			BorderSizePixel = 0
		}, content)
		
		local scrollbar = Lib.ScrollBar.new()
		setprops(scrollbar.Gui, {
			Size = UD2(1, 0,1, -40),
		}, content)
		scrollbar.Gui.Up.ZIndex = 3
		scrollbar.Gui.Down.ZIndex = 3
		
		local ScrollGui = scrollbar.Gui
		ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			if ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize then
				ScrollGui.Visible = true
			else
				ScrollGui.Visible = false
			end
		end)
		
		local ListLayout = setprops("UIListLayout", {
			Padding = UD(0, 5)
		}, ListFrame)
		
		local Padding = setprops("UIPadding", {
			PaddingBottom = UD(0, 5),
			PaddingLeft = UD(0, 10),
			PaddingRight = UD(0, 10),
			PaddingTop = UD(0, 5)
		}, ListFrame)
		
		AddText("Luacid Decompiler has been loaded in the background.\nmake sure your `Prefer fallback decompiler` is disabled!")
		
		--// Settings/Configs
		local Indent = AddDropdown("Indentation", {"tab", "1", "2"}, tostr(LuacidConfigs.Indent), false, 100)
		Indent.OnSelect:Connect(function()
			EditConfig("Indent", Indent.Selected)
		end)
		
		local type_annotations = AddDropdown("Type Annotations", {"functions", "off", "useful"}, LuacidConfigs.type_annotations, false, 100)
		type_annotations.OnSelect:Connect(function()
			EditConfig("type_annotations", type_annotations.Selected)
		end)
		
		local discard_names = AddDropdown("Discard Names", {"named", "bare"}, LuacidConfigs.discard_names, false, 100)
		discard_names.OnSelect:Connect(function()
			EditConfig("discard_names", discard_names.Selected)
		end)
		
		local generated_names = AddDropdown("Generated Names", {"readable", "compact"}, LuacidConfigs.generated_names, false, 100)
		generated_names.OnSelect:Connect(function()
			EditConfig("generated_names", generated_names.Selected)
		end)

		local inferred_name_case = AddDropdown("Inferred Name Case", {"preserve", "camel", "snake"}, LuacidConfigs.inferred_name_case, false, 100)
		inferred_name_case.OnSelect:Connect(function()
			EditConfig("inferred_name_case", inferred_name_case.Selected)
		end)
		
		local prefer_const = AddDropdown("Prefer Const", {"true", "false"}, tostr(LuacidConfigs.prefer_const), false, 100)
		prefer_const.OnSelect:Connect(function()
			EditConfig("prefer_const", prefer_const.Selected == "true")
		end)
		
		local if_expressions = AddDropdown("If Expressions", {"true", "false"}, tostr(LuacidConfigs.if_expressions), false, 100)
		if_expressions.OnSelect:Connect(function()
			EditConfig("if_expressions", if_expressions.Selected == "true")
		end)
		
		local early_return = AddDropdown("Early Return", {"true", "false"}, tostr(LuacidConfigs.early_return), false, 100)
		early_return.OnSelect:Connect(function()
			EditConfig("early_return", early_return.Selected == "true")
		end)
		
		local early_continue = AddDropdown("Early Continue", {"true", "false"}, tostr(LuacidConfigs.early_continue), false, 100)
		early_continue.OnSelect:Connect(function()
			EditConfig("early_continue", early_continue.Selected == "true")
		end)
		
		local interpolated_strings = AddDropdown("Interpolated Strings", {"true", "false"}, tostr(LuacidConfigs.interpolated_strings), false, 100)
		interpolated_strings.OnSelect:Connect(function()
			EditConfig("interpolated_strings", interpolated_strings.Selected == "true")
		end)
		
		local math_constants = AddDropdown("Math Constants", {"true", "false"}, tostr(LuacidConfigs.math_constants), false, 100)
		math_constants.OnSelect:Connect(function()
			EditConfig("math_constants", math_constants.Selected == "true")
		end)
		
		local fold_single_use_temps = AddDropdown("Fold Single Use Temps", {"true", "false"}, tostr(LuacidConfigs.fold_single_use_temps), false, 100)
		fold_single_use_temps.OnSelect:Connect(function()
			EditConfig("fold_single_use_temps", fold_single_use_temps.Selected == "true")
		end)
		
		local uninline_local_functions = AddDropdown("Uninline Local Functions", {"true", "false"}, tostr(LuacidConfigs.uninline_local_functions), false, 100)
		uninline_local_functions.OnSelect:Connect(function()
			EditConfig("uninline_local_functions", uninline_local_functions.Selected == "true")
		end)
		
		local reroll_unrolled_loops = AddDropdown("Reroll Unrolled Loops", {"true", "false"}, tostr(LuacidConfigs.reroll_unrolled_loops), false, 100)
		reroll_unrolled_loops.OnSelect:Connect(function()
			EditConfig("reroll_unrolled_loops", reroll_unrolled_loops.Selected == "true")
		end)
		
		local unfold_module_tables = AddDropdown("Unfold Module Tables", {"true", "false"}, tostr(LuacidConfigs.unfold_module_tables), false, 100)
		unfold_module_tables.OnSelect:Connect(function()
			EditConfig("unfold_module_tables", unfold_module_tables.Selected == "true")
		end)
		
		local keep_dead_functions = AddDropdown("Keep Dead Functions", {"true", "false"}, tostr(LuacidConfigs.keep_dead_functions), false, 100)
		keep_dead_functions.OnSelect:Connect(function()
			EditConfig("keep_dead_functions", keep_dead_functions.Selected == "true")
		end)
		
		local unicode_strings = AddDropdown("Unicode Strings", {"true", "false"}, tostr(LuacidConfigs.unicode_strings), false, 100)
		unicode_strings.OnSelect:Connect(function()
			EditConfig("unicode_strings", unicode_strings.Selected == "true")
		end)
		
		local upvalue_comments = AddDropdown("Upvalue Comments", {"true", "false"}, tostr(LuacidConfigs.upvalue_comments), false, 100)
		upvalue_comments.OnSelect:Connect(function()
			EditConfig("upvalue_comments", upvalue_comments.Selected == "true")
		end)
		
		local function_line_comments = AddDropdown("Function Line Comments", {"true", "false"}, tostr(LuacidConfigs.function_line_comments), false, 100)
		function_line_comments.OnSelect:Connect(function()
			EditConfig("function_line_comments", function_line_comments.Selected == "true")
		end)
		
		AddText("if don't know what these configs do please visit:")
		AddText("https://luacid.dev/docs/decompile", rgb(29, 78, 216))
		AddText("NOTE! that when you edit a setting it automatically updates the decompile live!\nthis is just for if you want to save the settings the next time you open dex.")
		
		--// Save Button
		local BackgroundSaveBtn = Lib.Frame.new()
		setprops(BackgroundSaveBtn, {
			Size = UD2(1,0, 0,20),
			Position = UD2(0,0, 1,-20)
		})
		BackgroundSaveBtn.Gui.Parent = window.GuiElems.Content
		
		local LabelSaveBtn = Lib.Label.new()
		setprops(LabelSaveBtn, {
			Size = UD2(1,0, 0,20),
			Position = UD2(0,0, 1,-20),
		}, window.GuiElems.Content)
		LabelSaveBtn.Gui.Text = "Save Configs"
		LabelSaveBtn.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local SaveButton = setprops("TextButton", {
			Size = UD2(1,0, 1,0),
			Position = UD2(0,0, 0,0),
			Transparency = 1
		}, BackgroundSaveBtn.Gui)
		
		SaveButton.Activated:Connect(function()
			writefs("LuacidConfigs.json", HttpService:JSONEncode(LuacidConfigs))
			window:SetTitle("Luacid Configs - Saved!")
			eep(2)
			window:SetTitle("Luacid Configs")
		end)
	end
	
	return LuacidUI
	
end

if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = MAIN_SCRIPT_ROOT}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = MAIN_SCRIPT_ROOT, PluginData = pluginData}
end
