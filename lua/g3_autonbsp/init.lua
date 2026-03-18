local M = {}

local prepositions = {
  "[a-z]", "by", "co", "či", "do", "je", "ke", "ku", "na", "no", "od", "po", "se", "ta", "to", "ve", "za", "ze", "že",
  "aby", "byl", "což", "jen", "když", "kde", "kdy", "který", "která", "které", "nad", "pod", "pro", "před", "při", "tak", "p%."
}

local months = {
  "leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec",
}

local months_all_cases = {
  "leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec",
  "ledna", "únoru", "března", "dubna", "května", "června", "července", "srpna", "září", "října", "listopadu", "prosince"
}

local titles_pre = {
  "Bc%.", "BcA%.", "Ing%.", "Ing%. arch%.", "MUDr%.", "MVDr%.", "MgA%.", "Mgr%.", "JUDr%.", "PhDr%.", "RNDr%.",
  "PharmDr%.", "ThLic%.", "ThDr%.", "prof%.", "doc%.", "PaedDr%.", "Dr%.", "PhMr%.", "Pí%.", "pí", "sv%."
}

local titles_post = {
  "DiS%.", "DrSc%.", "CSc%.", "Th%.D%.", "Ph%.D%."
}

local units = {
  "°", "€", "%$", "%%", "atm", "bar", "cal", "cl", "cm", "dB", "dkg", "dl", "g", "GB", "ha", "hl", "hod", "HP", "hPa",
  "J", "kB", "kg", "kHz", "km", "km/h", "kPa", "kp·m", "ks", "kW", "kWh", "Kč", "l", "m", "m/min", "m/s", "MB", "mbar",
  "mg", "MHz", "min", "ml", "mm", "MPa", "MPH", "MW", "nbar", "Pa", "psi", "q", "t", "w", "Wh", "tun", "kilo", "gram",
  "mili", "litr", "deci", "osob", "lidí", "promil", "hodin", "metrů", "centi", "tydnů", "let", "roků", "dnů", "dní",
  "korun", "euro", "dolarů", "liber"
}

local number_orders = {
  "sta", "stě", "tisíc", "tisíce", "milion", "milionu", "milionů", "miliony",
  "miliarda", "miliardy", "miliard", "bilion", "bilionů"
}

local protected_block_tags = {
  code = true,
  pre = true,
  script = true,
  style = true,
}

local function build_regex_or(list)
  local escaped = {}
  for _, item in ipairs(list) do
    local vim_item = item:gsub("%%%.", "\\."):gsub("%%%$", "\\$"):gsub("%%%%", "%%")
    table.insert(escaped, vim_item)
  end
  return "\\%(" .. table.concat(escaped, "\\|") .. "\\)"
end

local function build_regexes()
  return {
    prep = build_regex_or(prepositions),
    months = build_regex_or(months),
    months_all = build_regex_or(months_all_cases),
    titles_pre = build_regex_or(titles_pre),
    titles_post = build_regex_or(titles_post),
    units = build_regex_or(units),
    orders = build_regex_or(number_orders),
  }
end

function M.apply_rules(text, replacement, regexes)
  if text == "" then
    return ""
  end

  local repl = vim.fn.escape(replacement, [[&\]])

  local function sub(input, pattern, output)
    return vim.fn.substitute(input, pattern, output, "g")
  end

  local result = text
  local boundary = [[\%(\^\|[[:space:]<>\.,;&()/]\)]]

  result = sub(result, [[\c]] .. boundary .. [[\zs]] .. regexes.prep .. [[\zs\s]], repl)
  result = sub(result, [[\c]] .. boundary .. [[\zs]] .. regexes.months .. [[\zs\s\ze\d]], repl)
  result = sub(result, [[\c\d\.\?\zs\s\ze]] .. regexes.months_all, repl)
  result = sub(result, [[\c]] .. boundary .. [[\zs]] .. regexes.titles_pre .. [[\zs\s]], repl)
  result = sub(result, [[\c\s\ze]] .. regexes.titles_post, repl)
  result = sub(result, [[\d\.\?\zs\s\ze]] .. regexes.units, repl)
  result = sub(result, [[\d\.\?\zs\s\ze]] .. regexes.orders, repl)
  result = sub(result, [[\d\.\?\zs\s\ze\d]], repl)
  result = sub(result, [[\c]] .. boundary .. [[\(d\?\)ič\(:\?\)\zs\s\ze\([a-z]\{-0,2\}\)\d\{8\}]], repl)
  result = sub(result, [[\s\ze\c\%(s\.r\.o\.\|s\.\s\?r\.\s\?o\.\|a\.s\.\|a\.\s\?s\.\|spol\.\s\?s\s\?r\.\s\?o\.\)]], repl)
  result = sub(result, [[\czák\.\zs\s\zeč\.]], repl)
  result = sub(result, [[\cč\.\zs\s\ze\d]], repl)
  result = sub(result, [[\d\zs\s\zeSb\.]], repl)
  result = sub(result, [[Sb\.,\zs\s\zeo\s]], repl)
  result = sub(result, [[ - ]], [[ – ]])
  result = sub(result, [[\d\s\?,\zs[-–—]\s[kK]č]], [[–]] .. repl .. [[Kč]])
  result = sub(result, [[\d\s\?[a-z]\{1,2\}\zs2\ze\%([\s<>\.,;&()/]\|$\)]], [[²]])
  result = sub(result, [[\d\s\?[a-z]\{1,2\}\zs3\ze\%([\s<>\.,;&()/]\|$\)]], [[³]])

  return result
end

local function find_tag_end(text, start_pos)
  return text:find(">", start_pos + 1, true)
end

local function find_html_span(text, lower_text, start_pos)
  local tag_end = find_tag_end(text, start_pos)
  if not tag_end then
    return start_pos, #text
  end

  local is_closing = lower_text:match("^<%s*/", start_pos) ~= nil
  local tag_name = lower_text:match("^<%s*/?%s*([%a][%w:-]*)", start_pos)
  if not tag_name or is_closing or not protected_block_tags[tag_name] then
    return start_pos, tag_end
  end

  local close_pattern = string.format("</%s%%s*>", tag_name)
  local _, close_end = lower_text:find(close_pattern, tag_end + 1)
  if close_end then
    return start_pos, close_end
  end

  return start_pos, #text
end

local function process_lines(lines, replacement)
  local text = table.concat(lines, "\n")
  local new_text = M.process_text(text, replacement)
  return vim.split(new_text, "\n", { plain = true })
end

local function replace_line_range(bufnr, start_line, end_line, replacement)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  local new_lines = process_lines(lines, replacement)
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_lines)
end

function M.process_text(text, replacement)
  local regexes = build_regexes()
  local lower_text = text:lower()
  local result = ""
  local pos = 1

  while pos <= #text do
    local next_html = text:find("<", pos, true)
    local next_bracket = text:find("[", pos, true)
    local start_tag

    if next_html and next_bracket then
      start_tag = math.min(next_html, next_bracket)
    else
      start_tag = next_html or next_bracket
    end

    if not start_tag then
      result = result .. M.apply_rules(text:sub(pos), replacement, regexes)
      break
    end

    result = result .. M.apply_rules(text:sub(pos, start_tag - 1), replacement, regexes)
    local opener = text:sub(start_tag, start_tag)
    local span_start, span_end

    if opener == "<" then
      span_start, span_end = find_html_span(text, lower_text, start_tag)
    else
      local end_tag = text:find("]", start_tag + 1, true)
      if end_tag then
        span_start, span_end = start_tag, end_tag
      else
        span_start, span_end = start_tag, #text
      end
    end

    result = result .. text:sub(span_start, span_end)
    pos = span_end + 1
  end

  return result
end

function M.run(replacement, range)
  local actual_replacement = replacement or " "
  local bufnr = vim.api.nvim_get_current_buf()

  if range and range.start_line and range.end_line then
    replace_line_range(bufnr, range.start_line, range.end_line, actual_replacement)
  else
    replace_line_range(bufnr, 0, -1, actual_replacement)
  end

  vim.notify("Autonbsp: Formátování dokončeno.", vim.log.levels.INFO)
end

function M.setup(opts)
  opts = opts or {}
  local command = opts.command
  local keymaps = opts.keymaps
  local hard_space = opts.hard_space or "\194\160"
  local html_space = opts.html_space or "&nbsp;"

  if command ~= false then
    vim.api.nvim_create_user_command(command or "G3Autonbsp", function(args)
      local replacement = args.args ~= "" and args.args or hard_space
      local range = args.range > 0 and {
        start_line = args.line1 - 1,
        end_line = args.line2,
      } or nil
      M.run(replacement, range)
    end, { nargs = "?", range = true, desc = "Vloží nedělitelné mezery" })
  end

  if keymaps ~= false then
    local hard_key = type(keymaps) == "table" and keymaps.hard or "<F7>"
    local html_key = type(keymaps) == "table" and keymaps.html or "<F6>"

    vim.keymap.set({ "n", "i" }, hard_key, function()
      M.run(hard_space)
    end, { desc = "Autonbsp (hard space)" })

    vim.keymap.set("x", hard_key, string.format(":<C-u>'<,'>%s %s<CR>", command or "G3Autonbsp", hard_space), {
      silent = true,
      desc = "Autonbsp (hard space)",
    })

    vim.keymap.set({ "n", "i" }, html_key, function()
      M.run(html_space)
    end, { desc = "Autonbsp (&nbsp;)" })

    vim.keymap.set("x", html_key, string.format(":<C-u>'<,'>%s %s<CR>", command or "G3Autonbsp", html_space), {
      silent = true,
      desc = "Autonbsp (&nbsp;)",
    })
  end
end

return M
