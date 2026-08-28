-- Tron Legacy — Neovim Colorscheme
-- Inspired by the Tron: Legacy visual aesthetic
-- Use: vim.cmd.colorscheme('tron_legacy')

local colors = {
    bg         = "#050A0E",
    bg_alt     = "#0A141E",
    bg_cursor  = "#080E16",
    bg_visual  = "#003848",
    bg_search  = "#003040",
    cyan       = "#00F5FF",
    cyan_med   = "#0096A8",
    cyan_dim   = "#004858",
    text       = "#D0E8F0",
    text_bright= "#C8E6F0",
    text_dim   = "#507080",
    text_faint = "#406070",
    orange     = "#FF9500",
    orange_lit = "#FFB340",
    red        = "#FF3030",
    red_dim    = "#C83232",
    green      = "#00C8A0",
    green_lit  = "#00F5B4",
    teal       = "#00E5CC",
    teal_dim   = "#00C8B4",
    blue       = "#00BFFF",
    blue_dim   = "#00B4CC",
    line_nr    = "#304858",
    border     = "#06090E",
}

local function set(hlgroup, opts)
    vim.api.nvim_set_hl(0, hlgroup, opts)
end

-- ── UI ────────────────────────────────────────────────────────────────────
set("Normal",          { fg = colors.text, bg = colors.bg })
set("Cursor",          { fg = colors.bg, bg = colors.cyan })
set("CursorLine",      { bg = colors.bg_cursor })
set("CursorLineNr",    { fg = colors.blue_dim, bg = colors.bg_cursor })
set("LineNr",          { fg = colors.line_nr, bg = colors.border })
set("SignColumn",      { bg = colors.bg })
set("ColorColumn",     { bg = colors.bg_cursor })
set("StatusLine",      { fg = colors.text, bg = colors.bg_alt })
set("StatusLineNC",    { fg = colors.text_dim, bg = colors.bg })
set("VertSplit",       { fg = colors.cyan_dim, bg = colors.bg })
set("Folded",          { fg = colors.text_dim, bg = colors.bg_alt })
set("FoldColumn",      { fg = colors.text_dim, bg = colors.bg })
set("Visual",          { bg = colors.bg_visual })
set("Search",          { fg = colors.cyan, bg = colors.bg_search })
set("IncSearch",       { fg = colors.bg, bg = colors.cyan })
set("MatchParen",      { fg = colors.cyan, bg = colors.cyan_dim, bold = true })
set("Pmenu",           { fg = colors.text, bg = colors.bg_alt })
set("PmenuSel",        { fg = colors.bg, bg = colors.cyan })
set("PmenuSbar",       { bg = colors.bg_alt })
set("PmenuThumb",      { bg = colors.cyan_med })
set("WildMenu",        { fg = colors.bg, bg = colors.cyan })
set("Title",           { fg = colors.cyan, bold = true })
set("ModeMsg",         { fg = colors.cyan, bold = true })
set("MoreMsg",         { fg = colors.green })
set("Question",        { fg = colors.green })
set("WarningMsg",      { fg = colors.orange })
set("ErrorMsg",        { fg = colors.red, bold = true })
set("DiffAdd",         { bg = "#002818" })
set("DiffChange",      { bg = "#001A30" })
set("DiffDelete",      { fg = colors.red, bg = "#1A0505" })
set("DiffText",        { bg = colors.bg_visual })
set("Directory",       { fg = colors.cyan })
set("SpellBad",        { sp = colors.red, undercurl = true })
set("SpellCap",        { sp = colors.orange, undercurl = true })

-- ── Syntax ────────────────────────────────────────────────────────────────
set("Comment",         { fg = colors.text_dim, italic = true })
set("Constant",        { fg = colors.orange_lit })
set("String",          { fg = colors.teal })
set("Character",       { fg = colors.teal })
set("Number",          { fg = colors.orange })
set("Boolean",         { fg = colors.orange })
set("Float",           { fg = colors.orange })
set("Identifier",      { fg = colors.text })
set("Function",        { fg = colors.text_bright })
set("Statement",       { fg = colors.cyan })
set("Conditional",     { fg = colors.cyan })
set("Repeat",          { fg = colors.cyan })
set("Label",           { fg = colors.cyan })
set("Operator",        { fg = colors.cyan_med })
set("Keyword",         { fg = colors.cyan })
set("Exception",       { fg = colors.red })
set("PreProc",         { fg = colors.orange })
set("Include",         { fg = colors.orange })
set("Define",          { fg = colors.orange })
set("Macro",           { fg = colors.orange })
set("PreCondit",       { fg = colors.orange })
set("Type",            { fg = colors.blue })
set("StorageClass",    { fg = colors.cyan })
set("Structure",       { fg = colors.blue })
set("Typedef",         { fg = colors.blue })
set("Special",         { fg = colors.teal_dim })
set("SpecialChar",     { fg = colors.teal_dim })
set("Tag",             { fg = colors.cyan })
set("Delimiter",       { fg = colors.cyan_med })
set("SpecialComment",  { fg = colors.text_faint, italic = true })
set("Debug",           { fg = colors.orange })
set("Underlined",      { fg = colors.cyan, underline = true })
set("Ignore",          { fg = colors.text_dim })
set("Error",           { fg = colors.red, underline = true })
set("Todo",            { fg = colors.orange, bg = colors.bg, bold = true })

-- ── Treesitter / LSP (fallbacks) ─────────────────────────────────────────
set("@variable",       { link = "Identifier" })
set("@function",       { link = "Function" })
set("@function.call",  { link = "Function" })
set("@method",         { link = "Function" })
set("@keyword",        { link = "Keyword" })
set("@keyword.return", { link = "Keyword" })
set("@type",           { link = "Type" })
set("@type.builtin",   { link = "Type" })
set("@string",         { link = "String" })
set("@number",         { link = "Number" })
set("@comment",        { link = "Comment" })
set("DiagnosticError", { fg = colors.red })
set("DiagnosticWarn",  { fg = colors.orange })
set("DiagnosticInfo",  { fg = colors.blue })
set("DiagnosticHint",  { fg = colors.cyan_med })
