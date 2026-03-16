local wezterm = require("wezterm") --- @type Wezterm
local act = wezterm.action

---InputSelector callback when an SSH domain element is chosen
---@param window MuxWindow
---@param pane Pane
---@param domain string
---@param label_domain string
local function ssh_chosen(window, pane, domain, label_domain)
	---@diagnostic disable-next-line: undefined-field
	window:perform_action(
		act.SwitchToWorkspace({
			name = domain,
			spawn = {
				label = label_domain,
				domain = { DomainName = domain },
			},
		}),
		pane
	)
	wezterm.emit(
		"smart_workspace_switcher.workspace_switcher.created",
		Get_current_mux_window(domain),
		domain,
		label_domain
	)
end

---@param formatter fun(label:string):string
---@param _? table
---@return Choice[]
local function get_ssh_elements(formatter, _)
	local choice_table = {}

	for _, domain in ipairs(wezterm.default_ssh_domains()) do
		table.insert(choice_table, {
			id = domain.name,
			label = formatter(domain.name),
		})
	end

	return choice_table
end

---@param label string
---@return string
local function ssh_formatter(label)
	return wezterm.format({
		{ Text = "󰢹 : " .. label },
	})
end

---@type ChoiceSource
return {
	get_list = get_ssh_elements,
	action = ssh_chosen,
	formatter = ssh_formatter,
}
