local wezterm = require("wezterm") --- @type Wezterm
local act = wezterm.action

local is_windows = string.find(wezterm.target_triple, "windows") ~= nil

---@param cmd string
---@return string
local run_child_process = function(cmd)
	local process_args = { os.getenv("SHELL"), "-c", cmd }
	if is_windows then
		process_args = { "cmd", "/c", cmd }
	end
	local success, stdout, stderr = wezterm.run_child_process(process_args)

	if not success then
		wezterm.log_error("Child process '" .. cmd .. "' failed with stderr: '" .. stderr .. "'")
	end
	return stdout
end

---InputSelector callback when zoxide supplied element is chosen
---@param window MuxWindow
---@param pane Pane
---@param path string
---@param label_path string
local function zoxide_chosen(window, pane, path, label_path)
	---@diagnostic disable-next-line: undefined-field
	window:perform_action(
		act.SwitchToWorkspace({
			name = label_path,
			spawn = {
				label = label_path,
				cwd = path,
			},
		}),
		pane
	)
	wezterm.emit(
		"smart_workspace_switcher.workspace_switcher.created",
		Get_current_mux_window(label_path),
		path,
		label_path
	)
	-- increment zoxide path score
	run_child_process("zoxide" .. " add " .. path)
end

local function get_zoxide_elements(formatter, opts)
	local choice_table = {}

	local stdout = run_child_process(opts.zoxide_path .. " query -l " .. opts.extra_args)

	for _, path in ipairs(wezterm.split_by_newlines(stdout)) do
		local updated_path = string.gsub(path, wezterm.home_dir, "~")
		table.insert(choice_table, {
			id = path,
			label = formatter(updated_path),
		})
	end
	return choice_table
end

---@type ChoiceSource
local zoxide = {
	opts = { zoxide_path = "zoxide", extra_args = "" },
	get_list = get_zoxide_elements,
	action = zoxide_chosen,
}
return zoxide
