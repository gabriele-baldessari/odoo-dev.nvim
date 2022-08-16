local M = {}

M.setup = function(opts)
	M.odoo_bin_path = opts.odoo_bin_path .. " "
	M.python_path = opts.python_path .. " "
	M.template_path = opts.template_path .. " "
end

M.scaffold = function()
	local mpath = ""
	local mname = ""
	local pwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")

	vim.ui.input({ prompt = "Module Path:  ", default = pwd }, function(path)
		mpath = path .. " "
	end)
	vim.ui.input({ prompt = "Module Name:  " }, function(name)
		mname = name .. " "
	end)
	local cmd = M.python_path .. M.odoo_bin_path .. " scaffold -t" .. M.template_path .. mname .. mpath
	local result = vim.fn.system(cmd)
	print(result)
end

M.match_selection = function()
	local re = vim.regex([[\v(<_name>|<_inherit>)\zs\_s*\=\_s*\zs("|')\zs.*\ze("|')]])
	local row = vim.api.nvim_get_current_line()
	local row_len = string.len(row)
	local match = re:match_str(row)
	if match == nil then
		return nil
	else
		return string.sub(row, match + 1, row_len - 1)
	end
end

M.get_access_rule = function()
	local dot_model = M.match_selection()
	if dot_model == nil then
		print("invalid model definition")
		return
	end
	local underscore_model = dot_model:gsub("%.", "_")

	-- assume odoo/oca module structure when getting module name
	local b = vim.api.nvim_win_get_buf(0)
	local buff_name = vim.api.nvim_buf_get_name(b)
	local split = {}
	for i in string.gmatch(buff_name, "([^/]+)") do
		table.insert(split, i)
	end
	local module_name = split[#split - 2]

	local access_rule =
		-- rule_id
		"access_"
		.. underscore_model
		.. "_user,"
		-- rule name
		.. module_name
		.. "."
		.. dot_model
		.. ","
		-- rule model_id
		.. "model_"
		.. underscore_model
		.. ","
		-- rule group_id
		.. "base.group_user"
		.. ","
		-- rule perms
		.. "1,1,1,1"

	vim.fn.setreg(vim.fn.getreg("o"), access_rule)
	print("security rule created:", access_rule)
end

return M
