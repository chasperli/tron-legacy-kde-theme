" Tron Legacy — Vim Colorscheme
" Inspired by the Tron: Legacy visual aesthetic
" Use: :colorscheme tron_legacy

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = "tron_legacy"

" ── Palette ───────────────────────────────────────────────────────────────
" Background  #050A0E    Card        #0A141E
" Cyan        #00F5FF    CyanMed     #0096A8
" CyanDim     #004858    Text        #80E8F0
" TextDim     #507080    Orange      #FF9500
" Red         #FF3030    Green       #00C8A0

" ── UI ────────────────────────────────────────────────────────────────────
hi Normal           guifg=#D0E8F0 guibg=#050A0E ctermfg=253 ctermbg=232
hi Cursor           guifg=#050A0E guibg=#00F5FF ctermfg=232 ctermbg=51
hi CursorLine                     guibg=#080E16 ctermbg=233
hi CursorLineNr     guifg=#00B4CC guibg=#080E16 ctermfg=44  ctermbg=233
hi LineNr           guifg=#304858 guibg=#06090E ctermfg=239 ctermbg=233
hi StatusLine       guifg=#80E8F0 guibg=#0A141E ctermfg=116 ctermbg=234 gui=NONE
hi StatusLineNC     guifg=#507080 guibg=#050A0E ctermfg=244 ctermbg=232 gui=NONE
hi VertSplit        guifg=#004858 guibg=#050A0E ctermfg=238 ctermbg=232
hi Folded           guifg=#507080 guibg=#0A141E ctermfg=244 ctermbg=234
hi FoldColumn       guifg=#507080 guibg=#050A0E ctermfg=244 ctermbg=232
hi SignColumn                     guibg=#050A0E ctermbg=232
hi ColorColumn                    guibg=#080E16 ctermbg=233
hi Visual                         guibg=#003848 ctermbg=238
hi Search           guifg=#00F5FF guibg=#003040 ctermfg=51  ctermbg=235
hi IncSearch        guifg=#050A0E guibg=#00F5FF ctermfg=232 ctermbg=51
hi MatchParen       guifg=#00F5FF guibg=#004858 ctermfg=51  ctermbg=238 gui=bold
hi Pmenu            guifg=#80E8F0 guibg=#0A141E ctermfg=116 ctermbg=234
hi PmenuSel         guifg=#050A0E guibg=#00F5FF ctermfg=232 ctermbg=51
hi PmenuSbar                      guibg=#0A141E ctermbg=234
hi PmenuThumb                     guibg=#0096A8 ctermbg=31
hi WildMenu         guifg=#050A0E guibg=#00F5FF ctermfg=232 ctermbg=51
hi Title            guifg=#00F5FF               ctermfg=51  gui=bold
hi ModeMsg          guifg=#00F5FF               ctermfg=51  gui=bold
hi MoreMsg          guifg=#00C8A0               ctermfg=79
hi Question         guifg=#00C8A0               ctermfg=79
hi WarningMsg       guifg=#FF9500               ctermfg=214
hi ErrorMsg         guifg=#FF3030               ctermfg=196 gui=bold
hi DiffAdd                        guibg=#002818 ctermbg=234
hi DiffChange                     guibg=#001A30 ctermbg=234
hi DiffDelete       guifg=#FF3030 guibg=#1A0505 ctermfg=196 ctermbg=233
hi DiffText                       guibg=#003848 ctermbg=238 gui=NONE
hi Directory        guifg=#00F5FF               ctermfg=51
hi SpellBad         guisp=#FF3030               ctermfg=196 gui=undercurl
hi SpellCap         guisp=#FF9500               ctermfg=214 gui=undercurl

" ── Syntax ────────────────────────────────────────────────────────────────
hi Comment          guifg=#507080               ctermfg=244 gui=italic
hi Constant         guifg=#FFB340               ctermfg=221
hi String           guifg=#00E5CC               ctermfg=44
hi Character        guifg=#00E5CC               ctermfg=44
hi Number           guifg=#FF9500               ctermfg=214
hi Boolean          guifg=#FF9500               ctermfg=214
hi Float            guifg=#FF9500               ctermfg=214
hi Identifier       guifg=#D0E8F0               ctermfg=253
hi Function         guifg=#C8E6F0               ctermfg=252
hi Statement        guifg=#00F5FF               ctermfg=51  gui=NONE
hi Conditional      guifg=#00F5FF               ctermfg=51
hi Repeat           guifg=#00F5FF               ctermfg=51
hi Label            guifg=#00F5FF               ctermfg=51
hi Operator         guifg=#0096A8               ctermfg=31
hi Keyword          guifg=#00F5FF               ctermfg=51
hi Exception        guifg=#FF3030               ctermfg=196
hi PreProc          guifg=#FF9500               ctermfg=214
hi Include          guifg=#FF9500               ctermfg=214
hi Define           guifg=#FF9500               ctermfg=214
hi Macro            guifg=#FF9500               ctermfg=214
hi PreCondit        guifg=#FF9500               ctermfg=214
hi Type             guifg=#00BFFF               ctermfg=39
hi StorageClass     guifg=#00F5FF               ctermfg=51
hi Structure        guifg=#00BFFF               ctermfg=39
hi Typedef          guifg=#00BFFF               ctermfg=39
hi Special          guifg=#00C8B4               ctermfg=44
hi SpecialChar      guifg=#00C8B4               ctermfg=44
hi Tag              guifg=#00F5FF               ctermfg=51
hi Delimiter        guifg=#0096A8               ctermfg=31
hi SpecialComment   guifg=#406070               ctermfg=245 gui=italic
hi Debug            guifg=#FF9500               ctermfg=214
hi Underlined       guifg=#00F5FF               ctermfg=51  gui=underline
hi Ignore           guifg=#507080               ctermfg=244
hi Error            guifg=#FF3030               ctermfg=196 gui=underline
hi Todo             guifg=#FF9500 guibg=#050A0E ctermfg=214 ctermbg=232 gui=bold

" ── Terminal ──────────────────────────────────────────────────────────────
if has('terminal')
    let g:terminal_ansi_colors = [
        \ '#050A0E', '#C83232', '#00C8A0', '#C88C00',
        \ '#0096C8', '#C800FF', '#00B4CC', '#80E8F0',
        \ '#304858', '#FF5050', '#00F5B4', '#FFB340',
        \ '#00BFFF', '#FF80FF', '#00F5FF', '#B4F8FF' ]
endif
