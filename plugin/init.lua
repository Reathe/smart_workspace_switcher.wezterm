local wezterm = require("wezterm") --- @type Wezterm
local act = wezterm.action

local function findPluginPackagePath(myProject)
	local separator = package.config:sub(1, 1) == "\\" and "\\" or "/"
	for _, v in ipairs(wezterm.plugin.list()) do
		if v.url == myProject then
			return v.plugin_dir .. separator .. "plugin" .. separator .. "?.lua"
		end
	end
	--- TODO: Add error fail here
end

package.path = package.path
	.. ";"
	.. findPluginPackagePath("https://github.com/Reathe/smart_workspace_switcher.wezterm")

require("helpers")

---@class Choice
---@field id string The internal ID (e.g., "source|payload")
---@field label string The formatted text shown in the UI

---@class ChoiceSource
---@field get_list fun(formatter: (fun(label:string):string), opts: table): Choice[]
---@field action fun(window: Window, pane: Pane, arg: string, label: string)
---@field formatter? fun(label: string): string
---@field opts? table

---@class PublicModule
---@field choice_sources table<string, ChoiceSource>
---@field choices Choice[]
local pub = {
	choices = {},
	choice_sources = {
		zoxide = require("sources.zoxide"),
		workspace = require("sources.workspace"),
	},
}

---sets default keybind to ALT-s
---@param config table
function pub.apply_to_config(config)
	if config == nil then
		config = {}
	end

	if config.keys == nil then
		config.keys = {}
	end

	table.insert(config.keys, {
		key = "s",
		mods = "LEADER",
		action = pub.switch_workspace(),
	})
	table.insert(config.keys, {
		key = "S",
		mods = "LEADER",
		action = pub.switch_to_prev_workspace(),
	})
end

function pub.switch_to_prev_workspace()
	return wezterm.action_callback(function(window, pane)
		local current_workspace = window:active_workspace()
		local previous_workspace = wezterm.GLOBAL.previous_workspace

		if current_workspace == previous_workspace or previous_workspace == nil then
			return
		end

		wezterm.GLOBAL.previous_workspace = current_workspace

		window:perform_action(
			act.SwitchToWorkspace({
				name = tostring(previous_workspace),
			}),
			pane
		)
		wezterm.emit("smart_workspace_switcher.workspace_switcher.switched_to_prev", window, pane, previous_workspace)
	end)
end

---@return any # Returns a WezTerm Action?
function pub.switch_workspace()
	return wezterm.action_callback(function(window, pane)
		wezterm.emit("smart_workspace_switcher.workspace_switcher.start", window, pane)
		local choices = pub.get_choices()

		window:perform_action(
			act.InputSelector({
				action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
					if not id or not label then
						wezterm.emit("smart_workspace_switcher.workspace_switcher.canceled", window, pane)
						return
					end

					wezterm.emit("smart_workspace_switcher.workspace_switcher.selected", window, id, label)

					-- split id by pipe | to know which source to use
					local source, arg = id:match("^(.-)|(.*)$")
					local choice_source = pub.choice_sources[source]
					choice_source.action(inner_window, inner_pane, arg, label)
				end),
				title = "Choose Workspace",
				description = "Select a workspace and press Enter = accept, Esc = cancel, / = filter",
				fuzzy_description = "Workspace to switch: ",
				choices = choices,
				fuzzy = true,
			}),
			pane
		)
	end)
end

---Returns choices for the InputSelector
---@return Choice[]
function pub.get_choices()
	local choices = {} ---@type Choice[]
	for key, el in pairs(pub.choice_sources) do
		if el.opts == nil then
			el.opts = {}
		end

		local source_choices = el.get_list(el.formatter or function(str)
			return str
		end, el.opts)

		-- Loop through them and prepend the key to the ID
		for _, choice in ipairs(source_choices) do
			table.insert(choices, {
				id = key .. "|" .. choice.id,
				label = choice.label,
			})
		end
	end
	return choices
end

wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(window, _, _)
	wezterm.GLOBAL.previous_workspace = window:active_workspace()
end)

return pub
