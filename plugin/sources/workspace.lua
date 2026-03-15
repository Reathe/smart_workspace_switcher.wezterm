local wezterm = require("wezterm") --- @type Wezterm
local act = wezterm.action
local mux = wezterm.mux

---InputSelector callback when workspace element is chosen
---@param window MuxWindow
---@param pane Pane
---@param workspace string
---@param label_workspace string
local function workspace_chosen(window, pane, workspace, label_workspace)
	if workspace == "" then
		---@diagnostic disable-next-line: undefined-field
		window:perform_action(act.SwitchToWorkspace({}), pane)

		local new_workspace = mux.get_active_workspace()
		wezterm.emit(
			"smart_workspace_switcher.workspace_switcher.created",
			Get_current_mux_window(new_workspace),
			new_workspace,
			label_workspace
		)
	else
		---@diagnostic disable-next-line: undefined-field
		window:perform_action(
			act.SwitchToWorkspace({
				name = workspace,
			}),
			pane
		)
		wezterm.emit(
			"smart_workspace_switcher.workspace_switcher.chosen",
			Get_current_mux_window(workspace),
			workspace,
			label_workspace
		)
	end
end

---@param formatter fun(label:string):string
---@param _? table
---@return Choice[]
local function get_workspaces(formatter, _)
	local choice_table = {
		{ id = "", label = formatter("New random workspace") },
	}

	for _, workspace in ipairs(mux.get_workspace_names()) do
		table.insert(choice_table, {
			id = workspace,
			label = formatter(workspace),
		})
	end
	return choice_table
end

---@param label string
---@return string
local function workspace_formatter(label)
	return wezterm.format({
		{ Text = "󱂬 : " .. label },
	})
end

---@type ChoiceSource
return {
	get_list = get_workspaces,
	action = workspace_chosen,
	formatter = workspace_formatter,
}
