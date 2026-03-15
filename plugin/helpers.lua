local wezterm = require("wezterm") --- @type Wezterm
local mux = wezterm.mux

---@param workspace string
---@return MuxWindow
function Get_current_mux_window(workspace)
	for _, mux_win in ipairs(mux.all_windows()) do
		if mux_win:get_workspace() == workspace then
			return mux_win
		end
	end
	error("Could not find a workspace with the name: " .. workspace)
end
