" MarkdowneyJr
"
" Format Markdown files with simple keystrokes in Vim.
"
" Created and currently maintained by boson joe.
" https://github.com/boson-joe
"
" ':h MDJLicense' in Vim or open the 'license.txt' file in the root
" directory of this plugin to read the license this software is distributed on.
"
" ':h MDJUserGuide' in Vim or go to the link below to view the User Guide.
" https://github.com/boson-joe/markdowneyJR/wiki/MarkdowneyJr-User-Guide

let s:markdowneyjr_version = 110



" ---------- Guards

if v:version < 802
    finish
endif

if exists("g:MARKDOWNEYJR_plugin_is_loaded")
    finish
endif

" This file is loaded twice as definitions of classes` methods
" should be in place when classes are described - errors otherwise.
if !exists("g:MARKDOWNEYJR_source_count")
    let g:MARKDOWNEYJR_source_count = 0
    let s:MARKDOWNEYJR_max_sources  = 2
endif



" ---------- Customization 
if g:MARKDOWNEYJR_source_count == 1 

" User can define their own functions to determine the full name of the
" file that is put as an address in a link. Default functions are provided.
let s:MARKDOWNEYJR_GetPathForUrl = 
  \get(g:, "MARKDOWNEYJR_GetPathForUrl", 
  \function("<SID>MARKDOWNEYJR_GetPathForUrl_DEF"))
let s:MARKDOWNEYJR_GetPathForImg = 
  \get(g:, "MARKDOWNEYJR_GetPathForImg", 
  \function("<SID>MARKDOWNEYJR_GetPathForImg_DEF"))

" Users can define time that plugin will wait for a subsequent keystroke.
let s:MARKDOWNEYJR_time_for_repeated_action =
  \get(g:, "MARKDOWNEYJR_time_for_repeated_action",
  \1600)

" Allows integration with YANP note taking plugin.
let s:MARKDOWNEYJR_integration_with_YANP =
  \get(g:, "MARKDOWNEYJR_integration_with_YANP",
  \0)
endif



" ---------- User Interface 

" Mappings
if !exists("g:MARKDOWNEYJR_mappings_loaded")

" User is expected to customize mappings with setting a mapping for
" <Plug>MarkdowneyJrLeader in their vimrc. Default mapping is set otherwise,
" in case the mapping is available (not yet defined).
if !hasmapto('<Plug>MarkdowneyJrLeader', 'nv') && (mapcheck('<leader>m') == '')
    :nmap <leader>m <Plug>MarkdowneyJrLeader
    :vmap <leader>m <Plug>MarkdowneyJrLeader
endif

vnoremap <Plug>MarkdowneyJrLeaderl 
            \:<c-u>call MARKDOWNEYJR_OperatorLink(visualmode())<cr>
nnoremap <Plug>MarkdowneyJrLeaderl 
            \:set operatorfunc=MARKDOWNEYJR_OperatorLink<cr>g@
vnoremap <Plug>MarkdowneyJrLeadere 
            \:<c-u>call MARKDOWNEYJR_OperatorEphasis(visualmode())<cr>
nnoremap <Plug>MarkdowneyJrLeadere 
            \:set operatorfunc=MARKDOWNEYJR_OperatorEphasis<cr>g@
nnoremap <Plug>MarkdowneyJrLeaderh :MARKDOWNEYJRhd<cr>
vnoremap <Plug>MarkdowneyJrLeaderb :MARKDOWNEYJRbq<cr>
nnoremap <Plug>MarkdowneyJrLeaderb :MARKDOWNEYJRbq<cr>
vnoremap <Plug>MarkdowneyJrLeaderu :MARKDOWNEYJRul<cr>
nnoremap <Plug>MarkdowneyJrLeaderu :MARKDOWNEYJRul<cr>
vnoremap <Plug>MarkdowneyJrLeadero :MARKDOWNEYJRol<cr>
nnoremap <Plug>MarkdowneyJrLeadero :MARKDOWNEYJRol<cr>

let g:MARKDOWNEYJR_mappings_loaded = 1
endif


" User Interface Implementation
if !exists("g:MARKDOWNEYJR_UI_implementation_loaded")

function! MARKDOWNEYJR_OperatorLink(type)
    if IsVisualSelection(a:type)
        eval <SID>MakeMarkdowneyJrDoSomething('<', '>',
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker'))
    else
        eval <SID>MakeMarkdowneyJrDoSomething('[', ']', 
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker'))
    endif
endfunction

function! MARKDOWNEYJR_OperatorEphasis(type)
    if IsVisualSelection(a:type)
        eval <SID>MakeMarkdowneyJrDoSomething('<', '>',
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('emphasis_maker'))
    else
        eval <SID>MakeMarkdowneyJrDoSomething('[', ']', 
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('emphasis_maker'))
    endif
endfunction

command! MARKDOWNEYJRhd call MARKDOWNEYJR_FunctionHD()
function! MARKDOWNEYJR_FunctionHD()
    eval <SID>MakeMarkdowneyJrDoSomething(0, 0, 
         \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('header_maker'))
endfunction

command! -range MARKDOWNEYJRbq <line1>,<line2>call MARKDOWNEYJR_FunctionBQ()
function! MARKDOWNEYJR_FunctionBQ() range
    eval <SID>MakeMarkdowneyJrDoSomething(a:firstline, a:lastline, 
         \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('bq_maker'))
endfunction

command! -range MARKDOWNEYJRul <line1>,<line2>call MARKDOWNEYJR_FunctionUList()
function! MARKDOWNEYJR_FunctionUList() range
    eval <SID>MakeMarkdowneyJrDoSomething(a:firstline, a:lastline, 
         \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('list_maker_u'))
endfunction

command! -range MARKDOWNEYJRol <line1>,<line2>call MARKDOWNEYJR_FunctionOList()
function! MARKDOWNEYJR_FunctionOList() range
    eval <SID>MakeMarkdowneyJrDoSomething(a:firstline, a:lastline, 
         \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('list_maker_o'))
endfunction

" This is the main client function that 
" does manipulations via action maker objects.
function! <SID>MakeMarkdowneyJrDoSomething(first_l, last_l, action_maker)
    if !a:action_maker.IsRepeatedCall()
        eval a:action_maker.ResetState(a:first_l, a:last_l)
        eval a:action_maker.ToggleRepeatedCall()
    else
        eval a:action_maker.UpdateState()
        eval a:action_maker.ToggleRepeatedCall()
    endif
    
    eval g:MARKDOWNEYJR_Vim_state.SaveState(a:action_maker)
    eval g:MARKDOWNEYJR_Vim_state.SetState(a:action_maker)

    eval a:action_maker.MakeAction()

    eval g:MARKDOWNEYJR_Vim_state.RestoreState(a:action_maker)
endfunction

let g:MARKDOWNEYJR_UI_implementation_loaded = 1
endif



" ---------- OOP module

" General Object Functions
function! Inherit(parent, ...)
    let l:new_class = deepcopy(a:parent)
    if len(a:000) != 0
        for [k,V] in items(a:1)
            let l:new_class[k] = V
        endfor
    endif
    return l:new_class
endfunction

function! s:VIRTUAL_FUN(...) dict
    return 0
endfunction


" START - Vim state class
if g:MARKDOWNEYJR_source_count == 1 

let s:vim_state = 
\{
    \'class_name'           :'vim_state',
    \'saved_state'          :
        \{
            \'registers'        :0,
            \'clipboard'        :0,
            \'selection'        :0,
            \'cursor_pos'       :0,
        \},
    \'state_is_saved'       :0,
    \'who_saved_state'      :0,
    \'copies_count'         :0, 
    \'max_copies'           :1,
    \'MakeSingleton'        :function('<SID>VSMakeSingleton'),
    \'SaveState'            :function("<SID>VSSaveState"),
    \'SetState'             :function("<SID>VSSetState"),
    \'RestoreState'         :function("<SID>VSRestoreState"),
\}

endif

function! s:VSMakeSingleton() dict
    if self.copies_count >= self.max_copies
        return 0
    else
        let self.copies_count += 1
        return deepcopy(get(s:, self.class_name))
    endif
endfunction

function! s:VSSaveState(visitor) dict
    if self.state_is_saved
        return 0
    endif

    let l:ss = self.saved_state
    let ss['registers']  = getreginfo('"')
    let ss['clipboard']  = &clipboard
    let ss['selection']  = &selection
    let ss['cursor_pos'] = getcurpos()
    let self.state_is_saved  = 1
    let self.who_saved_state = a:visitor

    return 1
endfunction

function! s:VSSetState(visitor) dict
    if !self.state_is_saved || self.who_saved_state != a:visitor
        return 0
    endif

    eval a:visitor.SetVimState() 

    return 1
endfunction

function! s:VSRestoreState(visitor) dict
    if !self.state_is_saved || self.who_saved_state != a:visitor
        return 0
    endif

    let l:ss = self.saved_state
    call setreg('"', ss['registers'])
    let &clipboard = ss['clipboard'] 
    let &selection = ss['selection']
    eval setpos('.', ss['cursor_pos'])
    let self.state_is_saved  = 0
    let self.who_saved_state = 0

    return 1
endfunction

" END - Vim state class


" START - Action Maker abstract class
if g:MARKDOWNEYJR_source_count == 1 

let s:action_maker_abstract = 
\{
    \'class_name'           :'action_maker_abstract',
    \'repeated_call'        :0,
    \'time'                 :s:MARKDOWNEYJR_time_for_repeated_action,
    \'timer'                :0,
    \'action_start'         :0,
    \'action_end'           :0,
    \'send_mes_to_yanp'     :0,
    \'New'                  :function('<SID>VIRTUAL_FUN'),
    \'Copy'                 :function('<SID>AMCopy'),
    \'IsRepeatedCall'       :function('<SID>AMIsRepeated'),
    \'ToggleRepeatedCall'   :function('<SID>AMToggleRepeatedCall'),
    \'RepeatedCallDownTimer':function('<SID>AMRepeatedCallDownTimer'),
    \'ResetState'           :function('<SID>AMResetState'),
    \'UpdateState'          :function('<SID>VIRTUAL_FUN'),
    \'MakeAction'           :function('<SID>VIRTUAL_FUN'),
    \'SetVimState'          :function('<SID>AMSetVimState'),
    \'SendMesToYANP'        :function('<SID>AMSendMesToYANP'),
\}

endif

function! s:AMNew() dict
    return deepcopy(get(s:, self.class_name))
endfunction

function! s:AMCopy() dict
    return deepcopy(self)
endfunction

function! s:AMIsRepeated() dict
    return self.repeated_call
endfunction

function! s:AMToggleRepeatedCall() dict
    if self.timer != 0
        eval timer_stop(self.timer)
        let self.timer = 0
    endif

    if self.repeated_call == 0
        let self.repeated_call = 1
    endif

    let self.timer         =
        \ timer_start(self.time, function(self.RepeatedCallDownTimer))
endfunction

function! s:AMRepeatedCallDownTimer(timer_id, ...) dict
    let l:_self = self
    if a:0 != 0
        let l:_self = a:1
    endif
    eval s:MARKDOWNEYJR_action_maker_factory.UnRegisterObject(l:_self.class_name)
endf

function! s:AMResetState(first_l, last_l, ...) dict
    let l:_self = self
    if a:0 != 0
        let l:_self = a:1
    endif
    let l:_self.action_start   = a:first_l
    let l:_self.action_end     = a:last_l
    let l:_self.repeated_call  = 0
    let l:_self.timer          = 0
endfunction

function! s:AMSetVimState() dict
	set clipboard= selection=old
endfunction

function! s:AMSendMesToYANP(key) dict
    eval s:MARKDOWNEYJR_yanp_registry.SubjectAction(a:key)
endfunction

" END - Action Maker abstract class


" START - Wrong Action class
if g:MARKDOWNEYJR_source_count == 1 

let s:wrong_action = Inherit(s:action_maker_abstract,
\{
    \'class_name'           :'wrong_action',
    \'New'                  :function('<SID>AMNew'),
    \'IsRepeatedCall'       :function('<SID>VIRTUAL_FUN'),
    \'ToggleRepeatedCall'   :function('<SID>VIRTUAL_FUN'),
    \'RepeatedCallDownTimer':function('<SID>VIRTUAL_FUN'),
    \'ResetState'           :function('<SID>VIRTUAL_FUN'),
    \'UpdateState'          :function('<SID>VIRTUAL_FUN'),
    \'MakeAction'           :function('<SID>VIRTUAL_FUN'),
    \'SetVimState'          :function('<SID>VIRTUAL_FUN'),
\}
\)

endif

function! s:WANew() dict
    return deepcopy(s:wrong_action)
endfunction

" END - Wrong Action class


" START - Blockquote Maker class
if g:MARKDOWNEYJR_source_count == 1 

let s:bq_maker = Inherit(s:action_maker_abstract,
\{
    \'class_name'           :'bq_maker',
    \'New'                  :function('<SID>AMNew'),
    \'TransformLine'        :function('<SID>BQTransformLine'),
    \'MakeAction'           :function('<SID>BQMakeBQ'),
\}
\)

endif

function! s:BQNew() dict
    return deepcopy(s:bq_maker)
endfunction

function! s:BQTransformLine() dict
    let l:insert_text = '^'
    if GetChar() !=# '^'
        let l:insert_text = l:insert_text..' '
    endif
    return InsertText(l:insert_text)
endfunction

function! s:BQMakeBQ() dict
    let l:cur_line = self.action_start
    while l:cur_line <= self.action_end
        eval cursor(l:cur_line, 1)
        let l:cur_line += 1
        eval self.TransformLine()
    endwhile
endfunction

" END - Blockquote Maker class


" START - Header Maker class
if g:MARKDOWNEYJR_source_count == 1 

let s:header_maker = Inherit(s:action_maker_abstract,
\{
    \'class_name'           :'header_maker',
    \'header_types'         :
        \[
        \   '=', '-', 1, 2, 3, 4, 5, 6, 
        \],
    \'header_idx'           :0,
    \'New'                  :function('<SID>AMNew'),
    \'ResetState'           :function('<SID>HDResetState'),
    \'UpdateState'          :function('<SID>HDUpdateState'),
    \'TransformLine'        :function('<SID>HDTransformLine'),
    \'MakeAction'           :function('<SID>HDMakeHD'),
\}
\)

endif

function! s:HDNew() dict
    return deepcopy(s:header_maker)
endfunction

function! s:HDResetState(first_l, last_l) dict
    eval s:action_maker_abstract.ResetState(a:first_l, a:first_l, self)
    let self.header_idx = 0
endfunction

function! s:HDUpdateState() dict
    let self.header_idx = (self.header_idx + 1) % 8
endfunction

function s:HDTransformLine() dict
    let l:insert_text = ''
    let l:header_type = self.header_types[self.header_idx]
    if l:header_type ==# '=' || l:header_type ==# '-'
        let l:insert_text = repeat(l:header_type, strchars(getline('.')))
        eval InsertTextBelow(l:insert_text)
    else
        let l:insert_text = repeat('#', l:header_type+0) .. ' '
        eval InsertTextInFrontOfLine(l:insert_text)
    endif
endfunction

function! s:HDMakeHD() dict
    let l:save_cursor = getcurpos()
    eval cursor(line('.'), 1)

    let l:char = GetChar()
    while l:char == '#' || l:char == ' '
        eval DeleteChar()
        let l:char = GetChar()
    endwhile

    eval cursor(line('.') + 1, 1)
    let l:char = GetChar()
    if l:char == '=' || l:char == '-'
        eval DeleteLine()
    endif
    eval cursor(line('.') - 1, 1)
    
   eval self.TransformLine() 
   eval setpos('.', l:save_cursor)
endfunction

" END - Header Maker class


" START - Text action abstract class
if g:MARKDOWNEYJR_source_count == 1 

let s:text_action_abstract = Inherit(s:action_maker_abstract,
\{
    \'class_name'               :'text_action_abstract',
    \'text_manipulators'        :
        \{
        \},
    \'text_manipulators_are_set':0,
    \'text_making_strategies'   :
        \[
        \],
    \'text_strategies_idx'      :0,
    \'New'                      :function('<SID>VIRTUAL_FUN'), 
    \'ResetState'               :function('<SID>TAAResetState'),
    \'UpdateState'              :function('<SID>TAAUpdateState'),
    \'MakeAction'               :function('<SID>TAAMakeAction'),
    \'RepeatedCallDownTimer'    :function('<SID>TAARepeatedCallDownTimer'),
    \'MakeText'                 :function('<SID>VIRTUAL_FUN'),
    \'ReplaceTMS'               :function('<SID>TAAReplaceTMS'),
\}
\)

endif

function! s:TAANew() dict
    deepcopy(s:text_action_abstract)
endfunction

function! s:TAAResetState(first_l, last_l) dict
    eval s:action_maker_abstract.ResetState(
       \ getpos("'"..a:first_l), getpos("'"..a:last_l), self)
    let self.text_strategies_idx  = 0
    
    if !self.text_manipulators_are_set
        let self.text_manipulators['retriever'] = s:text_retriever.New()
        let self.text_manipulators['inserter']  = s:text_inserter.New()
        let self.text_manipulators['remover']   = s:text_remover.New()
        let self.text_manipulators_are_set      = 1
    endif
endfunction

function! s:TAAUpdateState() dict
    let self.text_strategies_idx = 
        \(self.text_strategies_idx + 1) % len(self.text_making_strategies)
endfunction

function! s:TAAMakeAction() dict
    eval setpos("'[", self.action_start)
    eval setpos("']", self.action_end)

    eval <SID>MakeMarkdowneyJrDoSomething(
                \"[", "]", self.text_manipulators['retriever'])
    let l:text_to_insert = self.MakeText()
    eval <SID>MakeMarkdowneyJrDoSomething(
                \"[", "]", self.text_manipulators['remover'])
    eval <SID>MakeMarkdowneyJrDoSomething(
                \"[", l:text_to_insert, self.text_manipulators['inserter'])
   
    let self.action_start   = getpos("'[")
    let self.action_end     = getpos("']")
    let self.action_end[2]  -= 1
endfunction

function! s:TAARepeatedCallDownTimer(timerid) dict
    if self.send_mes_to_yanp
        let self.send_mes_to_yanp = 0
        eval self.SendMesToYANP(
            \s:MARKDOWNEYJR_yanp_registry.GetCorrectKey('Regular'))
    endif

    let self.action_start = '['
    let self.action_end   = ']'
    
    eval self.text_manipulators['retriever'].RepeatedCallDownTimer(0)
    eval self.text_manipulators['inserter'].RepeatedCallDownTimer(0)
    eval self.text_manipulators['remover'].RepeatedCallDownTimer(0)

    eval s:action_maker_abstract.RepeatedCallDownTimer(a:timerid, self)
endfunction

function! s:TAAReplaceTMS(new_TMS) dict
    unlet self.text_making_strategies
    let self.text_making_strategies = a:new_TMS
endfunction

" END - Text action abstract class


" START - Emphasis Maker class
if g:MARKDOWNEYJR_source_count == 1 

let s:emphasis_maker = Inherit(s:text_action_abstract,
\{
    \'class_name'               :'emphasis_maker',
    \'text_making_strategies'   :
        \[
            \'*', '**', '***', '`',
        \],
    \'New'                      :function('<SID>AMNew'), 
    \'MakeText'                 :function('<SID>EMMakeText'),
\}
\)

endif

function! s:EMNew() dict
    return deepcopy(s:emphasis_maker)
endfunction

function! s:EMMakeText() dict
    let l:text = self.text_manipulators['retriever'].GetText()
    let l:sur  = self.text_making_strategies[self.text_strategies_idx]
    return l:text[0] .. SurroundText(l:text[1], l:sur, l:sur) .. l:text[2]
endfunction

" END - Emphasis Maker class


" START - Link Maker class

if g:MARKDOWNEYJR_source_count == 1 
let s:link_maker = Inherit(s:text_action_abstract,
\{
    \'class_name'               :'link_maker',
    \'last_path'                :'',
    \'text_making_strategies'   :
        \[
            \function("<SID>GetRegularLink", [s:MARKDOWNEYJR_GetPathForUrl]),
            \function("<SID>GetImgLink",     [s:MARKDOWNEYJR_GetPathForImg]),
        \],
    \'New'                      :function('<SID>AMNew'), 
    \'MakeText'                 :function('<SID>LMMakeText'),
    \'SaveLastPath'             :function('<SID>LMSaveLastPath'),
    \'GetLastPath'              :function('<SID>LMGetLastPath'),
\}
\)

endif

function! s:LMNew() dict
    return deepcopy(s:link_maker)
endfunction

function! s:LMMakeText() dict
    let l:text = self.text_manipulators['retriever'].GetText()
    let l:Strt = self.text_making_strategies[self.text_strategies_idx]

    return l:text[0] .. l:Strt(l:text[1]) .. l:text[2]
endfunction

function! s:LMSaveLastPath(path) dict
    let self.last_path = copy(a:path)
endfunction

function! s:LMGetLastPath() dict
    return copy(self.last_path)
endfunction

" Class helper functions
function! s:MARKDOWNEYJR_GetPathForImg_DEF()
    if exists("g:MARKDOWNEYJR_no_IMG_link")
        return ''
    else
        return expand("%:p:h") .. '/Img'
    endif
endfunction

function! s:MARKDOWNEYJR_GetPathForUrl_DEF()
    if exists("g:MARKDOWNEYJR_no_URL")
        return ''
    else
        return expand("%:p:h")
    endif
endfunction

function! s:GetRegularLink(GetFPath, f_name, ...)
    let l:f_path = a:GetFPath()
    let l:f_name = a:f_name

    if !empty(a:f_name)
        let l:f_path = l:f_path .. '/' .. ReplaceBlanksWithUnderscore(a:f_name)    
    endif

    if a:0 != 0
        let l:f_name = a:1 
    endif

    eval s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
                \.SaveLastPath(l:f_path) 
    return <SID>GetLinkForm(l:f_path, l:f_name)
endfunction

function! s:GetImgLink(GetIPath, i_name, ...)
    let l:i_name = ReplaceBlanksWithUnderscore(a:i_name)
    let l:i_path = a:GetIPath() .. '/' .. l:i_name
    eval s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
                \.SaveLastPath(l:i_path) 
    return '!' .. <SID>GetLinkForm(l:i_path, a:i_name)
endfunction

function! s:GetLinkForm(f_abs_path, alt_text, ...)
    return "["..a:alt_text.."]("..a:f_abs_path..")" 
endfunction

" END - Link Maker class


" START - List Maker abstract class
if g:MARKDOWNEYJR_source_count == 1 

let s:list_maker_abstract = Inherit(s:action_maker_abstract,
\{
    \'class_name'           :'list_maker_abstract',
    \'suffix'               :'',
    \'prev_line_info'       :'',
    \'indent_lev'           :0,
    \'saved_line_no'        :-1,
    \'saved_indent_lev'     :-1,
    \'New'                  :function('<SID>VIRTUAL_FUN'),
    \'CurLineIsFine'        :function('<SID>LMACurLineIsFine'),
    \'RepeatedCallDownTimer':function('<SID>LMARepeatedCallDownTimer'),
    \'ResetState'           :function('<SID>LMAResetState'),
    \'ResetPrevLineInfo'    :function('<SID>LMAResetPLI'),
    \'ResetIndentLevNSuf'   :function('<SID>LMAResetILevNSuf'),
    \'ResetLines'           :function('<SID>LMAResetLines'),
    \'ResetSuffix'          :function('<SID>VIRTUAL_FUN'),
    \'UpdateState'          :function('<SID>LMAUpdateState'),
    \'UpdatePrevLineInfo'   :function('<SID>LMAUpdatePLI'),
    \'UpdateSuffix'         :function('<SID>VIRTUAL_FUN'),
    \'IncereaseIndentLevel' :function('<SID>LMAIncreaseILev'),
    \'RetrievePrevLineSuf'  :function('<SID>VIRTUAL_FUN'),
    \'RetrievePrevLineInd'  :function('<SID>LMARetrievePrevLineInd'),
    \'MakeAction'           :function('<SID>LMAMakeList'),
    \'TransformLine'        :function('<SID>VIRTUAL_FUN'),
    \'ContinueTransform'    :function('<SID>VIRTUAL_FUN'),
\}
\)

endif

function! s:LMACurLineIsFine() dict
    let line_info = ExchaustWrongChars(getline(line('.')),
                \ function('IsNotBlank'))
    if line_info[1] ==? ''
        return 0
    else
        return 1
    endif
endfunction

function! s:LMARepeatedCallDownTimer(timer_id) dict
    eval self.ContinueTransform()
    eval s:action_maker_abstract.RepeatedCallDownTimer(a:timer_id, self)
endfunction

function! s:LMAResetState(first_l, last_l) dict
    eval self.ResetLines(a:first_l, a:last_l)
    eval self.ResetPrevLineInfo()
    eval self.ResetIndentLevNSuf()
    let self.repeated_call    = 0
    let self.timer            = 0
    let self.saved_indent_lev = -1 
    let self.saved_line_no    = -1
endfunction

function! s:LMAResetPLI() dict
    let l:prev_line         = getline(self.action_start - 1)
    let self.prev_line_info = 
                \ ExchaustWrongChars(l:prev_line, function("IsNotBlank"))
endfunction

function! s:LMAResetILevNSuf() dict
    if self.RetrievePrevLineSuf()
        eval self.RetrievePrevLineInd()
    else
        let self.indent_lev = 0
    endif
endfunction

function! s:LMAResetLines(first, last) dict
    let self.action_start = a:first
    let self.action_end  = a:last
endfunction

function! s:LMAUpdatePLI() dict
    let l:prev_line         = getline(line('.') - 1)
    let self.prev_line_info = 
                \ ExchaustWrongChars(l:prev_line, function("IsNotBlank"))
endfunction

function! s:LMAIncreaseILev() dict
    let self.indent_lev += 4
endfunction

function! s:LMARetrievePrevLineInd() dict
    let self.indent_lev = GetIndentLevelInSpces(self.prev_line_info[0])
endfunction

function! s:LMAMakeList() dict
    let l:cur_line = self.action_start
    while l:cur_line <= self.action_end
        eval cursor(l:cur_line, 1)
        let l:cur_line += 1
        if !self.CurLineIsFine()
            continue
        endif
        eval self.TransformLine()
        eval self.UpdateSuffix()
    endwhile
    eval self.ResetSuffix()
endfunction

function! s:LMAUpdateState() dict
    let l:save_cursor = getcurpos()
    if self.saved_line_no ==? -1
        let self.saved_line_no    = self.action_start
        let self.saved_indent_lev = self.indent_lev
        call self.IncereaseIndentLevel()
    else
        let self.saved_line_no -= 1
        while self.saved_line_no    > 0
            eval cursor(self.saved_line_no, 1)
            eval self.UpdatePrevLineInfo()
            eval self.RetrievePrevLineInd()
            let suf_retrieved = self.RetrievePrevLineSuf() 
            if suf_retrieved && self.saved_indent_lev == self.indent_lev
                let self.saved_line_no -= 1
                continue
            elseif suf_retrieved && self.saved_indent_lev != self.indent_lev
                let  self.saved_indent_lev = self.indent_lev
                "eval self.UpdateSuffix()
                break
            else
                let self.saved_line_no = -1
            endif
        endwhile
        if self.saved_line_no <= 0
            eval cursor(self.action_start, 1)
            eval self.ResetState(self.action_start, self.action_end)
        endif
    endif
    eval setpos('.', l:save_cursor)
endfunction

" END - List Maker abstract class


" START - Unordered List Maker class
if g:MARKDOWNEYJR_source_count == 1 

let s:list_maker_u = Inherit(s:list_maker_abstract,
\{
    \'class_name'           :'list_maker_u',
    \'New'                  :function('<SID>AMNew'),
    \'TransformLine'        :function('<SID>ULTransformLine'),
    \'RetrievePrevLineSuf'  :function('<SID>ULPrevLineIsPartOfList'),
\}
\)
endif

function! s:ULNew() dict
    return deepcopy(s:list_maker_u)
endfunction

function! s:ULTransformLine() dict
    if !self.CurLineIsFine()
        return -1
    endif

    let l:char = GetChar()
    while !IsNotBlank(l:char) || l:char ==# '+'
        eval execute("normal! dw")
        let l:char = GetChar()
    endwhile

    let l:indentation = repeat(' ', self.indent_lev)
    let l:insert_text = l:indentation .. '+' .. ' '
    return InsertText(l:insert_text)
endfunction

function! s:ULPrevLineIsPartOfList() dict
    return (self.prev_line_info[1][0] ==# '+')
endfunction

" END - Unordered List Maker class


" START - Ordered List Maker class
if g:MARKDOWNEYJR_source_count == 1 

let s:list_maker_o = Inherit(s:list_maker_abstract,
\{
    \'class_name'           :'list_maker_o',
    \'New'                  :function('<SID>AMNew'),
    \'TransformLine'        :function('<SID>OLTransformLine'),
    \'RetrievePrevLineSuf'  :function('<SID>OLRetrievePrevLineSuf'),
    \'UpdateSuffix'         :function('<SID>OLUpdateSuffix'),
    \'ResetSuffix'          :function('<SID>OLResetSuffix'),
    \'ContinueTransform'    :function('<SID>OLContinueTransform'),
    \'PeepPrevLineSuf'      :function('<SID>OLPeepPrevLineSuf'),
\}
\)

endif

function! s:OLNew() dict
    return deepcopy(s:list_maker_o)
endfunction

function! s:OLTransformLine() dict
    if !self.CurLineIsFine()
        return -1
    endif

    let l:char = GetChar()
    while !IsNotBlank(l:char) || IsNum(l:char) || l:char ==# ')'
        eval execute("normal! dw")
        let l:char = GetChar()
    endwhile

    let l:indentation = repeat(' ', self.indent_lev)
    let l:insert_text = l:indentation .. self.suffix .. ') '
    return InsertText(l:insert_text)
endfunction

function! s:OLPeepPrevLineSuf() dict
    let l:line      = self.prev_line_info[1]
    let l:line_len  = strchars(l:line)
    let l:list_char = []
    let l:idx       = 0
    while idx < l:line_len
        let l:char = l:line[l:idx]
        if IsNum(l:char)
            let l:idx += 1
            eval extend(l:list_char, [l:char])
        else
            break
        endif
    endwhile
    if l:idx == 0 || l:idx >= l:line_len || l:line[l:idx] !=# ')'
        return -1
    else
        return str2nr(join(l:list_char))
    endif
endfunction

function! s:OLRetrievePrevLineSuf() dict
    let self.suffix = self.PeepPrevLineSuf() + 1
    if self.suffix == 0 
        let self.suffix = 1
        return 0
    else
        return 1
    endif
endfunction

function! s:OLUpdateSuffix() dict
    let self.suffix += 1
endfunction

function! s:OLResetSuffix() dict
    let self.suffix = 1
endfunction

function! s:OLContinueTransform() dict
    let l:save_cursor = getcurpos()

    eval cursor(self.action_end, 1)
    let self.suffix = self.PeepPrevLineSuf() + 1

    let l:line = self.action_end + 1
    eval cursor(l:line, 1)

    let l:saved_indent_lev = self.indent_lev
    let l:no_go_suf        = 1

    while self.CurLineIsFine()
        eval cursor(l:line + 1, 1)
        eval self.UpdatePrevLineInfo()
        eval cursor(l:line, 1)
        eval self.RetrievePrevLineInd()
        let peeped_line_suf = self.PeepPrevLineSuf()
        let l:line += 1

        if l:saved_indent_lev == self.indent_lev &&
         \ l:peeped_line_suf != -1
            if l:peeped_line_suf == l:no_go_suf
                let l:no_go_suf += 1
                continue
            endif

            eval self.UpdateSuffix()
            eval self.TransformLine()
        else
            let l:no_go_suf = 1
        endif
    endwhile
    eval setpos('.', l:save_cursor)
endfunction

" END - Ordered List Maker class


" START - Text Manipulator Abstract class
if g:MARKDOWNEYJR_source_count == 1 

let s:text_manipulator_abstract = Inherit(s:action_maker_abstract,
\{
    \'class_name'           :'text_manipulator_abstract',
    \'text'                 :'',
    \'New'                  :function('<SID>VIRTUAL_FUN'),
    \'ResetState'           :function('<SID>TMAResetState'),
    \'ToggleRepeatedCall'   :function('<SID>TMAToggleRepeatedCall'),
    \'RepeatedCallDownTimer':function('<SID>TMARepeatedCallDownTimer'),
    \'MakeAction'           :function('<SID>VIRTUAL_FUN'),
    \'GetText'              :function('<SID>TMAGetText'),
    \'SetVimState'          :function('<SID>TMASetVimState'),
\}
\)

endif

function! s:TMANew() dict
    return deepcopy(s:text_manipulator_abstract)
endfunction

function! s:TMAResetState(first_l, last_l) dict
    eval s:action_maker_abstract.ResetState(a:first_l, a:last_l, self)
    eval remove(self, 'text')
    let self.text = ''
endfunction

function! s:TMAToggleRepeatedCall() dict
    if self.repeated_call == 0
        let self.repeated_call = 1
    endif
endfunction

function! s:TMARepeatedCallDownTimer(timerid) dict
    " Cannot unlet self, unfortunately. 
    " Hope garbage collector does its job.
endfunction

function! s:TMAGetText() dict
    return deepcopy(self.text)
endfunction

function! s:TMASetVimState() dict
    " leave it empty
endfunction

" END - Text Manipulator Abstract class


" START - Text Retriever class
if g:MARKDOWNEYJR_source_count == 1 

let s:text_retriever = Inherit(s:text_manipulator_abstract,
\{
    \'class_name'           :'text_retriever',
    \'New'                  :function('<SID>AMNew'),
    \'MakeAction'           :function('<SID>TTMakeAction'),
    \'GetDirtyText'         :function('<SID>TTGetDirtyText'),
    \'GetCleanText'         :function('<SID>TTGetCleanText'),
\}
\)

endif

function! s:TTNew() dict
    return deepcopy(s:text_retriever)
endfunction

function! s:TTMakeAction() dict
    if empty(self.text)
        eval self.GetDirtyText()
        eval self.GetCleanText()
    endif
endfunction

function s:TTGetDirtyText() dict
    let l:saved_register = @@
    eval execute('normal! `'..self.action_start..'v`'..self.action_end..'y')
    
    let l:ret            = @@
    let @@               = l:saved_register

    let self.text        = l:ret
endfunction

function! s:TTGetCleanText() dict
    let self.text = ExchaustWrongChars(self.text, function("IsAlpha"))
endfunction

" END - Text Retriever class


" START - Text Remover class
if g:MARKDOWNEYJR_source_count == 1 

let s:text_remover = Inherit(s:text_manipulator_abstract,
\{
    \'class_name'           :'text_remover',
    \'New'                  :function('<SID>AMNew'),
    \'MakeAction'           :function('<SID>TRMakeAction'),
\}
\)
endif

function! s:TRNew() dict
    return deepcopy(s:text_remover)
endfunction

function! s:TRMakeAction() dict
    let l:saved_register = @@

    eval execute('normal! `'..self.action_start..'v`'..self.action_end..'d')
    
    let l:ret            = @@
    let @@               = l:saved_register

    let self.text        = l:ret
endfunction

" END - Text Remover class


" START - Text Inserter class
if g:MARKDOWNEYJR_source_count == 1 

let s:text_inserter = Inherit(s:text_manipulator_abstract,
\{
    \'class_name'           :'text_inserter',
    \'New'                  :function('<SID>AMNew'),
    \'MakeAction'           :function('<SID>TIMakeAction'),
    \'ToggleRepeatedCall'   :function('<SID>TIToggleRepeatedCall'),
\}
\)

endif

function! s:TINew() dict
    return deepcopy(s:text_inserter)
endfunction

function! s:TIMakeAction() dict
    let l:saved_pos = getpos('.')  
    let self.text   = self.action_end
    
    eval cursor(getpos('`'..self.action_start))
    eval execute("normal! i" .. self.text .. "\<esc>")

    eval cursor(l:saved_pos)
endfunction

function! s:TIToggleRepeatedCall() dict
    "leave it empty
endfunction

" END - Text Inserter class


" START - Action Maker Generator class
if g:MARKDOWNEYJR_source_count == 1 

let s:MARKDOWNEYJR_action_maker_factory =
\ {
    \ 'class_name'          :'MARKDOWNEYJR_action_maker_factory',
    \ 'objects_registry'    :
            \{
            \},
    \ 'prototypes_registry'  :
            \{
            \},
    \ 'GetActionMaker'      :function('<SID>AMFGetActionMaker'),
    \ 'RegisterObject'      :function('<SID>AMFRegisterObject'),
    \ 'UnRegisterObject'    :function('<SID>AMFUnRegisterObject'),
    \ 'ObjectIsRegistered'  :function('<SID>AMFObjectIsRegistered'),
    \ 'RegisterPrototypes'  :function('<SID>AMFRegisterPrototypes'),
    \ 'UnRegisterPrototypes':function('<SID>AMFUnRegisterPrototypes'),
    \ 'HasPrototype'        :function('<SID>AMFHasPrototype'),
\ }

endif

function! s:AMFGetActionMaker(object_key) dict
    let l:ret = self.prototypes_registry["wrong_action"]

    if !self.ObjectIsRegistered(a:object_key)
        if self.RegisterObject(a:object_key)
            let l:ret = self.objects_registry[a:object_key]
        endif
    else
        let l:ret = self.objects_registry[a:object_key]
    endif

    return l:ret
endfunction

function! s:AMFObjectIsRegistered(object_key) dict
    return (has_key(self.objects_registry, a:object_key))
endfunction

function! s:AMFRegisterObject(object_key) dict
    if self.HasPrototype(a:object_key) && 
      \self.prototypes_registry[a:object_key] != s:wrong_action
        let self.objects_registry[a:object_key] = 
                    \self.prototypes_registry[a:object_key].Copy()
        return 1
    else
        return 0
    endif
endfunction

function! s:AMFUnRegisterObject(object_key) dict
    if self.ObjectIsRegistered(a:object_key)
        eval remove(self.objects_registry, a:object_key)
    endif
endfunction

function! s:AMFRegisterPrototypes(...) dict
    for p in a:000
        if !self.HasPrototype(p.class_name)
            let self.prototypes_registry[p.class_name] = p.New()
        endif
    endfor
endfunction

function! s:AMFUnRegisterPrototypes(...) dict
    for p in a:000
        if self.HasPrototype(p.class_name)
            eval remove(self.prototypes_registry, p.class_name)
        endif
    endfor
endfunction

function! s:AMFHasPrototype(prototype_key) dict
    return (has_key(self.prototypes_registry, a:prototype_key))
endfunction
" END - Action Maker Generator class



" ---------- HELPERS

function! ExchaustWrongChars(word, IsCorrectChar)
    let l:word_len          = strchars(a:word)
    let l:last_char         = l:word_len - 1
    let l:wrong_chars_h     = []
    let l:wrong_chars_t     = []
    let l:text_new_start    = 0
    let l:text_new_end      = l:last_char
    let l:word_is_gargabe   = 0

    let l:cur_char_idx      = 0
    while IsWithinBorders(l:cur_char_idx, 0, l:last_char)
        if !a:IsCorrectChar(a:word[l:cur_char_idx])
            eval extend(l:wrong_chars_h, [a:word[l:cur_char_idx]])
        else 
            let l:text_new_start = l:cur_char_idx
            break
        endif

        let l:cur_char_idx += 1
    endwhile
   
    if l:cur_char_idx != l:word_len
        let l:cur_char_idx = l:last_char 
        while IsWithinBorders(l:cur_char_idx, l:text_new_start, l:last_char)
            if !a:IsCorrectChar(a:word[l:cur_char_idx])
                eval extend(l:wrong_chars_t, [a:word[l:cur_char_idx]])
            else 
                let l:text_new_end  = l:cur_char_idx
                break
            endif

            let l:cur_char_idx -= 1
        endwhile
    else
        let l:wrong_chars_h   = []
        let l:word_is_gargabe = 1
    endif

    let l:new_word = a:word[l:text_new_start:l:text_new_end] 

    return [join(l:wrong_chars_h, ''), l:new_word,
                \ join(reverse(l:wrong_chars_t), ''), l:word_is_gargabe]
endfunction

function! IsWithinBorders(idx, start, end)
    return (a:idx >= a:start && a:idx <= a:end)
endfunction

function! ReplaceBlanksWithUnderscore(text)
    return join(split(a:text, " "), "_")
endfunction

let s:alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
let s:numeric  = '1234567890'
function! IsAlpha(char)
    return CharMatches(s:alphabet, a:char)
endfunction

function! IsNum(char)
    return CharMatches(s:numeric, a:char)
endfunction

function! IsNotBlank(char)
    return !CharMatches(["\V\<Space>", "\V\<Tab>"], a:char)
endfunction

function! CharMatches(matching_text, char)
    let l:char = '\V' .. a:char

    if match(a:matching_text, l:char) !=? -1 
        return 1
    endif

    return 0
endfunction

function! IncrementInt(int)
    return a:int + 1
endfunction

function! DecrementInt(int)
    return a:int - 1
endfunction

function! SurroundText(text, left, right)
    return a:left..a:text..a:right
endfunction

function! GetChar()
    return strcharpart(strpart(getline('.'), col('.') - 1), 0, 1)
endfunction

function! IsVisualSelection(motion_type)
    return (a:motion_type ==? 'v' || a:motion_type ==# '<CTRL-V>')
endfunction

function! InsertText(text)
    eval execute("normal! i" .. a:text .. "\<esc>")
endfunction

function! InsertTextBelow(text)
    eval execute("normal! o\<esc>")
    eval InsertText(a:text)
endfunction

function! InsertTextInFrontOfLine(text)
    eval execute("normal! ^\<esc>")
    eval InsertText(a:text)
endfunction

function! DeleteWord()
    eval execute("normal! daW")
endfunction

function! DeleteChar()
    eval execute("normal! x")
endfunction

function! DeleteLine()
    eval execute("normal! dd")
endfunction

function! DeleteSelection(from, to)
    eval execute("normal! `"..a:from.."v `"..a:to.."d")
endfunction

function! GetIndentLevelInSpces(indent)
    let l:i_lev = 0
    let l:i_len = strchars(a:indent)
    let l:idx   = 0
    while l:idx < l:i_len
        let l:suffix = a:indent[l:idx]
        if l:suffix == "\<Space>"
            let l:i_lev += 1
        elseif l:suffix == "\<Tab>"
            let l:i_lev += &tabstop
        endif
        let l:idx += 1
    endwhile
    return l:i_lev
endfunction



" ---------- YANP plugin integration


" START - YANP Integrator class
if g:MARKDOWNEYJR_source_count == 1 

let s:yanp_integrator = 
\{
    \'class_name'           :'yanp_integrator',
    \'prototypes_factory'   :0,
    \'link_to_return'       :'',
    \'unique_instance'      :{},
    \'Instance'             :function('<SID>YIInstance'),
    \'GetLink'              :0,
    \'Integrate'            :0,
    \'SourceYanp'           :0,
\}

endif

function! s:YIIntegrate() dict
    if !exists("g:YANP_plugin_is_loaded") || !g:YANP_plugin_is_loaded
        eval self.SourceYanp()
    endif

    let s:MARKDOWNEYJR_yanp_registry = g:YANP_syntax_mediator.Instance()
    let s:MARKDOWNEY_yanp_subject    = g:YANP_subject.New(
                \s:MARKDOWNEYJR_yanp_registry.GetCorrectKey('Regular'),
                \function('<SID>YIGetLink'))

    eval s:MARKDOWNEYJR_yanp_registry.RegisterAsSubject(
                \s:MARKDOWNEY_yanp_subject)
    
    eval s:InitYANPCommands()
    eval s:InitYANPVariables()
endfunction

function! s:YIGetLink() dict
    let _self          = s:yanp_integrator.Instance()
    let l:action_maker = 
        \_self.prototypes_factory.GetActionMaker('link_maker')

    return l:action_maker.GetLastPath()
endfunction

function! s:YISourceYANP() dict
    let l:runtimepaths = split(&runtimepath, ",") 
    let l:ret = 0

    for p in l:runtimepaths
        let l:yanp = p..'/plugin/yanp.vim'
        if !empty(glob(l:yanp))
            eval execute("source " .. l:yanp)
            let l:ret = 1
        endif
    endfor

    unlet l:runtimepaths
    unlet l:yanp

    return l:ret
endfunction

function! s:YIInstance() dict
    if empty(self.unique_instance)
        let self.unique_instance = {'i':1}
        let l:unique_instance    = deepcopy(self)
       
        let l:unique_instance.prototypes_factory = 
                    \s:MARKDOWNEYJR_action_maker_factory 

        let l:unique_instance.Instance  = 0
        let l:unique_instance.Integrate = function('<SID>YIIntegrate')
        let l:unique_instance.GetLink   = function('<SID>YIGetLink')
        let l:unique_instance.SourceYanp= function('<SID>YISourceYANP')

        let self.unique_instance = l:unique_instance 
    endif

    return self.unique_instance
endfunction

" END - YANP Integrator class


" YANP integration functions for performing syntax manipulations

function! s:InitYANPCommands()
    vnoremap <Plug>YanpRegularFile 
                \:<c-u>call <SID>HandleRegularLinkForYANP(visualmode())<cr>
    nnoremap <Plug>YanpRegularFile 
                \:set operatorfunc=<SID>HandleRegularLinkForYANP<cr>g@

    vnoremap <Plug>YanpImage 
                \:<c-u>call <SID>HandleImgLinkForYANP(visualmode())<cr>
    nnoremap <Plug>YanpImage 
                \:set operatorfunc=<SID>HandleImgLinkForYANP<cr>g@

    vnoremap <Plug>YanpIndexFile 
                \:<c-u>call <SID>HandleIndexLinkForYANP(visualmode())<cr>
    nnoremap <Plug>YanpIndexFile 
                \:set operatorfunc=<SID>HandleIndexLinkForYANP<cr>g@

    vnoremap <Plug>YanpSelectedPath 
                \:<c-u>call <SID>HandleSelectiveLinkForYANP(visualmode())<cr>
    nnoremap <Plug>YanpSelectedPath 
                \:set operatorfunc=<SID>HandleSelectiveLinkForYANP<cr>g@
endfunction

function! s:InitYANPVariables()
    let g:YANP_GetRegularLinkToThis = function("<SID>GetRegularLinkForYanp")
endfunction
            
function! s:HandleRegularLinkForYANP(type)
    eval s:MARKDOWNEY_yanp_subject.ChangeObserver(
                \s:MARKDOWNEYJR_yanp_registry.GetCorrectKey('Regular'))

    let l:action_maker = 
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
    eval l:action_maker.ReplaceTMS(
          \[function('<SID>GetRegularLink', 
              \[g:YANP_access_facade.Instance().GetRefToDictPathForRegFile()])
          \])

    let l:action_maker.send_mes_to_yanp = 1
    if IsVisualSelection(a:type)
        eval <SID>MakeMarkdowneyJrDoSomething('<', '>', l:action_maker)
    else
        eval <SID>MakeMarkdowneyJrDoSomething('[', ']', l:action_maker) 
    endif
endfunction

function! s:HandleImgLinkForYANP(type)
    eval s:MARKDOWNEY_yanp_subject.ChangeObserver(
                \s:MARKDOWNEYJR_yanp_registry.GetCorrectKey('Image'))
    
    let l:action_maker = 
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
    eval l:action_maker.ReplaceTMS(
          \[function("<SID>GetImgLink", 
              \[g:YANP_access_facade.Instance().GetRefToDictPathForImg()])
          \])

    let l:action_maker.send_mes_to_yanp = 1
    if IsVisualSelection(a:type)
        eval <SID>MakeMarkdowneyJrDoSomething('<', '>', l:action_maker)
    else
        eval <SID>MakeMarkdowneyJrDoSomething('[', ']', l:action_maker) 
    endif
endfunction

function! s:HandleIndexLinkForYANP(type)
    eval s:MARKDOWNEY_yanp_subject.ChangeObserver(
                \s:MARKDOWNEYJR_yanp_registry.GetCorrectKey('Index'))

    let l:action_maker = 
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
    eval l:action_maker.ReplaceTMS(
          \[function("<SID>GetIndexLink", 
              \[g:YANP_access_facade.Instance().GetRefToPathForIndexFile()])
          \])

    let l:action_maker.send_mes_to_yanp = 1
    if IsVisualSelection(a:type)
        eval <SID>MakeMarkdowneyJrDoSomething('<', '>', l:action_maker)
    else
        eval <SID>MakeMarkdowneyJrDoSomething('[', ']', l:action_maker) 
    endif
endfunction

function! s:HandleSelectiveLinkForYANP(type)
    let l:action = g:YANP_path_selector.New(
            \function('<SID>HandleSelectiveLinkForYANP_Callback', [a:type]),
            \g:YANP_access_facade.Instance().GetRefToPathSelectorGetter()
        \)

    eval l:action.MakeAction()
endfunction

function! s:GetIndexLink(GetIPath, i_name)
    let l:i_name = ReplaceBlanksWithUnderscore(a:i_name)
    let l:i_path = a:GetIPath(l:i_name)
    eval s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
                \.SaveLastPath(l:i_path) 
    return <SID>GetLinkForm(l:i_path, a:i_name)
endfunction

function! s:GetRegularLinkForYanp(file_path)
    return s:GetLinkForm(a:file_path, fnamemodify(a:file_path, ":t"))
endfunction

function! s:HandleSelectiveLinkForYANP_Callback(type) dict
    eval s:MARKDOWNEY_yanp_subject.ChangeObserver(
                \s:MARKDOWNEYJR_yanp_registry.GetCorrectKey('Selective'))

    let l:action_maker = 
          \s:MARKDOWNEYJR_action_maker_factory.GetActionMaker('link_maker')
    eval l:action_maker.ReplaceTMS([
             \function("<SID>GetRegularLink", [ 
                 \function('<SID>GetSelectivePath', [self.selection]),
                 \''
             \])
         \])

    let l:action_maker.send_mes_to_yanp = 1
    if IsVisualSelection(a:type)
        eval <SID>MakeMarkdowneyJrDoSomething('<', '>', l:action_maker)
    else
        eval <SID>MakeMarkdowneyJrDoSomething('[', ']', l:action_maker) 
    endif
endfunction

function! s:GetSelectivePath(path, ...)
    return YANP_CorrectPathIfNeeded(a:path)
endfunction



" ---------- Plugin's main function

let g:MARKDOWNEYJR_source_count += 1
if g:MARKDOWNEYJR_source_count < s:MARKDOWNEYJR_max_sources
    source <sfile>
else
    let g:MARKDOWNEYJR_Vim_state = s:vim_state.MakeSingleton()

    eval s:MARKDOWNEYJR_action_maker_factory.RegisterPrototypes(
                \s:wrong_action,
                \s:header_maker,
                \s:emphasis_maker,
                \s:link_maker,
                \s:bq_maker,
                \s:list_maker_u,
                \s:list_maker_o,
        \)

    let g:MARKDOWNEYJR_plugin_is_loaded = 1

    if s:MARKDOWNEYJR_integration_with_YANP
        let s:integrator_with_yanp = 
            \s:yanp_integrator.Instance()
        eval s:integrator_with_yanp.Integrate()
    endif
endif

