if { ! [info exists ::env(__NOREADLINE__)] } {
# FILE: "/home/joze/src/tclreadline/tclreadlineInit.tcl.in"
# LAST MODIFICATION: "Mit, 20 Sep 2000 19:29:26 +0200 (joze)"
# (C) 1998 - 2000 by Johannes Zellner, <johannes@zellner.org>
# $Id: tclreadlineInit.tcl.in,v 2.6 2000/09/20 17:44:34 joze Exp $
# ---
# tclreadline -- gnu readline for tcl
# http://www.zellner.org/tclreadline/
# Copyright (c) 1998 - 2000, Johannes Zellner <johannes@zellner.org>
# This software is copyright under the BSD license.

package provide tclreadline

namespace eval tclreadline:: {
namespace export Init
}

proc ::tclreadline::Init {} {
uplevel #0 {
if ![info exists tclreadline::library] {
if [catch {load [file join /usr/lib libtclreadline[info sharedlibextension]]} msg] {
puts stderr $msg
exit 2
}
}
}
}

tclreadline::Init
::tclreadline::readline customcompleter ::tclreadline::ScriptCompleter

#source [file join [file dirname [info script]] tclreadlineSetup.tcl]

set auto_index(::tclreadline::ScriptCompleter) \
[list source [file join [file dirname [info script]] tclreadlineCompleter.tcl]]
# FILE: "/home/joze/src/tclreadline/tclreadlineSetup.tcl.in"
# LAST MODIFICATION: "Sat, 01 Jul 2000 21:53:28 +0200 (joze)"
# (C) 1998 - 2000 by Johannes Zellner, <johannes@zellner.org>
# $Id: tclreadlineSetup.tcl.in,v 2.9 2000/07/01 22:18:08 joze Exp $
# ---
# tclreadline -- gnu readline for tcl
# http://www.zellner.org/tclreadline/
# Copyright (c) 1998 - 2000, Johannes Zellner <johannes@zellner.org>
# This software is copyright under the BSD license.


package provide tclreadline

proc unknown args {

global auto_noexec auto_noload env unknown_pending tcl_interactive
global errorCode errorInfo

# Save the values of errorCode and errorInfo variables, since they
# may get modified if caught errors occur below.  The variables will
# be restored just before re-executing the missing command.

set savedErrorCode $errorCode
set savedErrorInfo $errorInfo
set name [lindex $args 0]
if ![info exists auto_noload] {
#
# Make sure we're not trying to load the same proc twice.
#
if [info exists unknown_pending($name)] {
return -code error "self-referential recursion in \"unknown\" for command \"$name\""
}
set unknown_pending($name) pending
set ret [catch {auto_load $name [uplevel 1 {namespace current}]} msg]
unset unknown_pending($name)
if {$ret != 0} {
return -code $ret -errorcode $errorCode \
"error while autoloading \"$name\": $msg"
}
if ![array size unknown_pending] {
unset unknown_pending
}
if $msg {
set errorCode $savedErrorCode
set errorInfo $savedErrorInfo
set code [catch {uplevel 1 $args} msg]
if {$code ==  1} {
#
# Strip the last five lines off the error stack (they're
# from the "uplevel" command).
#

set new [split $errorInfo \n]
set new [join [lrange $new 0 [expr [llength $new] - 6]] \n]
return -code error -errorcode $errorCode \
-errorinfo $new $msg
} else {
return -code $code $msg
}
}
}

# REMOVED THE [info script] TEST (joze, SEP 98)
if {([info level] == 1) && [info exists tcl_interactive] && $tcl_interactive} {
if ![info exists auto_noexec] {
set new [auto_execok $name]
if {$new != ""} {
set errorCode $savedErrorCode
set errorInfo $savedErrorInfo
set redir ""
if {[info commands console] == ""} {
set redir ">&@stdout <@stdin"
}
# LOOK FOR GLOB STUFF IN $ARGS (joze, SEP 98)
return [uplevel eval exec $redir $new \
[::tclreadline::Glob [lrange $args 1 end]]]
}
}
set errorCode $savedErrorCode
set errorInfo $savedErrorInfo
if {$name == "!!"} {
set newcmd [history event]
} elseif {[regexp {^!(.+)$} $name dummy event]} {
set newcmd [history event $event]
} elseif {[regexp {^\^([^^]*)\^([^^]*)\^?$} $name dummy old new]} {
set newcmd [history event -1]
catch {regsub -all -- $old $newcmd $new newcmd}
}
if [info exists newcmd] {
tclLog $newcmd
history change $newcmd 0
return [uplevel $newcmd]
}

set ret [catch {set cmds [info commands $name*]} msg]
if {[string compare $name "::"] == 0} {
set name ""
}
if {$ret != 0} {
return -code $ret -errorcode $errorCode \
"error in unknown while checking if \"$name\" is a unique command abbreviation: $msg"
}
if {[llength $cmds] == 1} {
return [uplevel [lreplace $args 0 0 $cmds]]
}
if {[llength $cmds] != 0} {
if {$name == ""} {
return -code error "empty command name \"\""
} else {
return -code error \
"ambiguous command name \"$name\": [lsort $cmds]"
}
}
}
return -code error "invalid command name \"$name\""
}

namespace eval tclreadline {

namespace export Setup Loop InitTclCmds InitTkCmds Print ls

proc ls {args} {
if {[exec uname -s] == "Linux"} {
eval exec ls --color -FC [Glob $args]
} else {
eval exec ls -FC [Glob $args]
}
}

proc Setup {args} {

uplevel #0 {

if {"" == [info commands ::tclreadline::readline]} {
::tclreadline::Init
}

if {"" == [info procs ::tclreadline::prompt1] && [info nameofexecutable] != ""} {

namespace eval ::tclreadline {
variable prompt_string
set base [file tail [info nameofexecutable]]

if {[string match tclsh* $base] && [info exists tcl_version]} {
set prompt_string \
"\[0;31mtclsh$tcl_version\[0m"
} elseif {[string match wish* $base] \
&& [info exists tk_version]} {
set prompt_string "\[0;34mwish$tk_version\[0m"
} else {
set prompt_string "\[0;31m$base\[0m"
}

}

if {"" == [info procs ::tclreadline::prompt1]} {
proc ::tclreadline::prompt1 {} {
variable prompt_string
global env
if {[catch {set pwd [pwd]} tmp]} {
set pwd "unable to get pwd"
}

if [info exists env(HOME)] {
regsub $env(HOME) $pwd "~" pwd
}
return "$prompt_string \[$pwd\]"
}
}
# puts body=[info body ::tclreadline::prompt1]
}

if {"" == [info procs ::tclreadline::prompt2] && [info nameofexecutable] != ""} {

if {"" == [info procs ::tclreadline::prompt2]} {
proc ::tclreadline::prompt2 {} {
return ">"
}
}
# puts body=[info body ::tclreadline::prompt2]
}

if {"" == [info procs exit]} {

catch {rename ::tclreadline::Exit ""}
rename exit ::tclreadline::Exit

proc exit {args} {

if {[catch {
::tclreadline::readline write \
[::tclreadline::HistoryFileGet]
} ::tclreadline::errorMsg]} {
puts stderr $::tclreadline::errorMsg
}

# this call is ignored, if tclreadline.c
# was compiled with CLEANUP_AFER_SIGNAL
# not defined. This is the case for
# older versions of libreadline.
#
::tclreadline::readline reset-terminal

if [catch "eval ::tclreadline::Exit $args" message] {
puts stderr "error:"
puts stderr "$message"
}
# NOTREACHED
}
}

}

global env
variable historyfile

if {[string trim [llength ${args}]]} {
set historyfile ""
catch {
set historyfile [file nativename [lindex ${args} 0]]
}
if {"" == [string trim $historyfile]} {
set historyfile [lindex ${args} 0]
}
} else {
if [info exists env(HOME)] {
set historyfile  $env(HOME)/.tclsh-history
} else {
set historyfile  .tclsh-history
}
}
set ::tclreadline::errorMsg [readline initialize $historyfile]
if {$::tclreadline::errorMsg != ""} {
puts stderr $::tclreadline::errorMsg
}

# InitCmds

rename Setup ""
}

proc HistoryFileGet {} {
variable historyfile
return $historyfile
}

# obsolete
#
proc Glob {string} {

set commandstring ""
foreach name $string {
set replace [glob -nocomplain -- $name]
if {$replace == ""} {
lappend commandstring $name
} else {
lappend commandstring $replace
}
}
# return $commandstring
# Christian Krone <krischan@sql.de> proposed
return [eval concat $commandstring]
}



proc Loop {args} {

eval Setup ${args}

uplevel #0 {

while {1} {

if {[catch {
if {"" != [namespace eval ::tclreadline {info procs prompt1}]} {
set ::tclreadline::LINE [::tclreadline::readline read \
[::tclreadline::prompt1]]
} else {
set ::tclreadline::LINE [::tclreadline::readline read %]
}
while {![::tclreadline::readline complete $::tclreadline::LINE]} {
append ::tclreadline::LINE "\n"
if {"" != [namespace eval ::tclreadline {info procs prompt2}]} {
append ::tclreadline::LINE \
[tclreadline::readline read [::tclreadline::prompt2]]
} else {
append ::tclreadline::LINE [tclreadline::readline read >]
}
}
} ::tclreadline::errorMsg]} {
puts stderr [list tclreadline::Loop: error. \
$::tclreadline::errorMsg]
continue
}

# Magnus Eriksson <magnus.eriksson@netinsight.se> proposed
# to add the line also to tclsh's history.
#
# I decided to add only lines which are different from
# the previous one to the history. This is different
# from tcsh's behaviour, but I found it quite convenient
# while using mshell on os9.
#
if {[string length $::tclreadline::LINE] && \
[history event 0] != $::tclreadline::LINE} {
history add $::tclreadline::LINE
}

if [catch {
set ::tclreadline::result [eval $::tclreadline::LINE]
if {$::tclreadline::result != "" && [tclreadline::Print]} {
puts $::tclreadline::result
}
set ::tclreadline::result ""
} ::tclreadline::errorMsg] {
puts stderr $::tclreadline::errorMsg
puts stderr [list while evaluating $::tclreadline::LINE]
}

}
}
}

proc Print {args} {
variable PRINT
if ![info exists PRINT] {
set PRINT yes
}
if [regexp -nocase \(true\|yes\|1\) $args] {
set PRINT yes
} elseif [regexp -nocase \(false\|no\|0\) $args] {
set PRINT no
}
return $PRINT
}
#
#
# proc InitCmds {} {
#     # XXX
#     return
#     # XXX
#     global tcl_version tk_version
#     if {[info exists tcl_version]} {
#         InitTclCmds
#     }
#     if {[info exists tk_version]} {
#         InitTkCmds
#     }
#     rename InitCmds ""
# }
#
# proc InitTclCmds {} {
#     variable known_cmds
#     foreach line {
#         "after option ?arg arg ...?"
#         "append varName ?value value ...?"
#         "array option arrayName ?arg ...?"
#         "bgerror"
#         "break"
#         "catch command ?varName?"
#         "cd"
#         "clock"
#         "close <channelId>"
#         "concat"
#         "continue"
#         "eof <channelId>"
#         "error message ?errorInfo? ?errorCode?"
#         "eval arg ?arg ...?"
#         "exec ?switches? arg ?arg ...?"
#         "exit ?returnCode?"
#         "fblocked <channelId>"
#         "for start test next command"
#         "foreach varList list ?varList list ...? command"
#         "format formatString ?arg arg ...?"
#         "gets channelId ?varName?"
#         "glob"
#         "global varName ?varName ...?"
#         "incr varName ?increment?"
#         "info option ?arg arg ...?"
#         "interp cmd ?arg ...?"
#         "join list ?joinString?"
#         "lappend varName ?value value ...?"
#         "lindex list index"
#         "linsert list <index> <element> ?element ...?"
#         "list"
#         "llength list"
#         "lrange list first last"
#         "lreplace list first last ?element element ...?"
#         "lsearch ?mode? list pattern"
#         "lsort ?options? list"
#         "namespace"
#         "package option ?arg arg ...?"
#         "proc name args body"
#         "read ?-nonewline? channelId"
#         "regexp ?switches? exp string ?matchVar? ?subMatchVar subMatchVar ...?"
#         "rename oldName newName"
#         "scan <string> <format> ?varName varName ...?"
#         "set varName ?newValue?"
#         "split <string> ?splitChars?"
#         "subst ?-nobackslashes? ?-nocommands? ?-novariables? string"
#         "switch ?switches? string pattern body ... ?default body?"
#         "time <command> ?count?"
#         "unknown <cmdName> ?arg? ?...?"
#         "uplevel ?level? command ?arg ...?"
#         "vwait name"
#         "while test command"
#     } {
#         readline add $line
#         set known_cmds([lindex $line 0]) ${line}
#     }
#     rename InitTclCmds ""
# }
#
# proc InitTkCmds {} {
#     variable known_cmds
#     foreach line {
#         "bind window ?pattern? ?command?"
#         "bindtags window ?tags?"
#         "button pathName ?options?"
#         "canvas pathName ?options?"
#         "checkbutton pathName ?options?"
#         "clipboard option ?arg arg ...?"
#         "entry pathName ?options?"
#         "event option ?arg1?"
#         "font option ?arg?"
#         "frame pathName ?options?"
#         "grab option ?arg arg ...?"
#         "grid option arg ?arg ...?"
#         "image option ?args?"
#         "label pathName ?options?"
#         "listbox pathName ?options?"
#         "lower window ?belowThis?"
#         "menu pathName ?options?"
#         "menubutton pathName ?options?"
#         "message pathName ?options?"
#         "option cmd arg ?arg ...?"
#         "pack option arg ?arg ...?"
#         "radiobutton pathName ?options?"
#         "raise window ?aboveThis?"
#         "scale pathName ?options?"
#         "scrollbar pathName ?options?"
#         "selection option ?arg arg ...?"
#         "send ?options? interpName arg ?arg ...?"
#         "text pathName ?options?"
#         "tk option ?arg?"
#         "tkwait variable|visibility|window name"
#         "toplevel pathName ?options?"
#         "winfo option ?arg?"
#         "wm option window ?arg ...?"
#     } {
#         readline add $line
#         set known_cmds([lindex $line 0]) ${line}
#     }
#     rename InitTkCmds ""
# }
#


}; # namespace tclreadline
# -*- tclsh -*-
# FILE: "/home/joze/src/tclreadline/tclreadlineCompleter.tcl"
# LAST MODIFICATION: "Sat, 01 Jul 2000 16:15:55 +0200 (joze)"
# (C) 1998 - 2000 by Johannes Zellner, <johannes@zellner.org>
# $Id: tclreadlineCompleter.tcl,v 2.23 2000/07/01 14:23:17 joze Exp $
# vim:set ts=4:
# ---
#
# tclreadline -- gnu readline for tcl
# http://www.zellner.org/tclreadline/
# Copyright (c) 1998 - 2000, Johannes Zellner <johannes@zellner.org>
#
# This software is copyright under the BSD license.
#
# ==================================================================


# TODO:
#
#	- tcltest is missing
#	- better completion for CompleteListFromList:
#	  RemoveUsedOptions ...
#	- namespace eval fred {...} <-- continue with a
#								   substitution in fred.
#	- set tclreadline::pro<tab> doesn't work
#	  set ::tclreadline::pro<tab> does
#
#   - TextObj ...
#



namespace eval tclreadline {

# the following three are from the icccm
# and used in complete(selection) and
# descendants.
#
variable selection-selections {
PRIMARY SECONDARY CLIPBOARD
}
variable selection-types {
ADOBE_PORTABLE_DOCUMENT_FORMAT
APPLE_PICT
BACKGROUND
BITMAP
CHARACTER_POSITION
CLASS
CLIENT_WINDOW
COLORMAP
COLUMN_NUMBER
COMPOUND_TEXT
DELETE
DRAWABLE
ENCAPSULATED_POSTSCRIPT
ENCAPSULATED_POSTSCRIPT_INTERCHANGE
FILE_NAME
FOREGROUND
HOST_NAME
INSERT_PROPERTY
INSERT_SELECTION
LENGTH
LINE_NUMBER
LIST_LENGTH
MODULE
MULTIPLE
NAME
ODIF
OWNER_OS
PIXMAP
POSTSCRIPT
PROCEDURE
PROCESS
STRING
TARGETS
TASK
TEXT
TIMESTAMP
USER
}
variable selection-formats {
APPLE_PICT
ATOM
ATOM_PAIR
BITMAP
COLORMAP
COMPOUND_TEXT
DRAWABLE
INTEGER
NULL
PIXEL
PIXMAP7
SPAN
STRING
TEXT
WINDOW
}

namespace export \
TryFromList CompleteFromList DisplayHints Rehash \
PreviousWord CommandCompletion RemoveUsedOptions \
HostList ChannelId InChannelId OutChannelId \
Lindex Llength CompleteBoolean WidgetChildren

# set tclreadline::trace to 1, if you
# want to enable explicit trace calls.
#
variable trace

# set tclreadline::trace_procs to 1, if you
# want to enable tracing every entry to a proc.
#
variable trace_procs

if {[info exists trace_procs] && $trace_procs} {
::proc proc {name arguments body} {
::proc $name $arguments [subst -nocommands {
TraceText [lrange [info level 0] 1 end]
$body
}]
}
} else { ;# !$trace_procs
catch {rename ::tclreadline::proc ""}
}

if {[info exists trace] && $trace} {

::proc TraceReconf {args} {
eval .tclreadline_trace.scroll set $args
.tclreadline_trace.text see end
}

::proc AssureTraceWindow {} {
variable trace
if {![info exists trace]} {
return 0
}
if {!$trace} {
return 0
}
if {![winfo exists .tclreadline_trace.text]} {
toplevel .tclreadline_trace
text .tclreadline_trace.text \
-yscrollcommand { tclreadline::TraceReconf } \
-wrap none
scrollbar .tclreadline_trace.scroll \
-orient vertical \
-command { .tclreadline_trace.text yview }
pack .tclreadline_trace.text -side left -expand yes -fill both
pack .tclreadline_trace.scroll -side right -expand yes -fill y
} else {
raise .tclreadline_trace
}
return 1
}

::proc TraceVar vT {
if {![AssureTraceWindow]} {
return
}
upvar $vT v
if {[info exists v]} {
.tclreadline_trace.text insert end \
"([lindex [info level -1] 0]) $vT=|$v|\n"
}
# silently ignore unset variables.
}

::proc TraceText txt {
if {![AssureTraceWindow]} {
return
}
.tclreadline_trace.text insert end \
[format {%32s %s} ([lindex [info level -1] 0]) $txt\n]
}

} else {
::proc TraceReconf args {}
::proc AssureTraceWindow args {}
::proc TraceVar args {}
::proc TraceText args {}
}

#**
# TryFromList will return an empty string, if
# the text typed so far does not match any of the
# elements in list. This might be used to allow
# subsequent filename completion by the builtin
# completer.
# If inhibit is non-zero, the result will be
# formatted such that readline will not insert
# a space after a complete (single) match.
#
proc TryFromList {text lst {allow ""} {inhibit 0}} {

# puts stderr "(CompleteFromList) \ntext=|$text|"
# puts stderr "(CompleteFromList) lst=|$lst|"
set pre [GetQuotedPrefix ${text}]
set matches [MatchesFromList ${text} ${lst} ${allow}]

# puts stderr "(CompleteFromList) matches=|$matches|"
if {1 == [llength $matches]} { ; # unique match
# puts stderr \nunique=$matches\n
# puts stderr "\n|${pre}${matches}[Right ${pre}]|\n"
set null [string index $matches 0]
if {("<" == ${null} || "?" == ${null}) && \
-1 == [string first ${null} ${allow}]
} {
set completion [string trim "[list $text] $lst"]
} else {
set completion [string trim ${pre}${matches}[Right ${pre}]]
}
if {$inhibit} {
return [list $completion {}]
} else {
return $completion
}
} elseif {"" != ${matches}} {
# puts stderr \nmore=$matches\n
set longest [CompleteLongest ${matches}]
# puts stderr longest=|$longest|
if {"" == $longest} {
return [string trim "[list $text] ${matches}"]
} else {
return [string trim "${pre}${longest} ${matches}"]
}
} else {
return ""; # nothing to complete
}
}

#**
# CompleteFromList will never return an empty string.
# completes, if a completion can be done, or ring
# the bell if not. If inhibit is non-zero, the result
# will be formatted such that readline will not insert
# a space after a complete (single) match.
#
proc CompleteFromList {text lst {allow ""} {inhibit 0}} {
set result [TryFromList ${text} ${lst} ${allow} ${inhibit}]
if {![llength ${result}]} {
Alert
# return [string trim [list ${text}] ${lst}"]
if {[llength ${lst}]} {
return [string trim "${text} ${lst}"]
} else {
return [string trim [list ${text} {}]]
}
} else {
return ${result}
}
}

#**
# CompleteBoolean does a CompleteFromList
# with a list of all valid boolean values.
#
proc CompleteBoolean {text} {
return [CompleteFromList $text {yes no true false 1 0}]
}

#**
# build a list of all executables which can be
# found in $env(PATH). This is (naturally) a bit
# slow, and should not called frequently. Instead
# it is a good idea to check if the variable
# `executables' exists and then just use it's
# content instead of calling Rehash.
# (see complete(exec)).
#
proc Rehash {} {

global env
variable executables

if {![info exists env] || ![array exists env]} {
return
}
if {![info exists env(PATH)]} {
return
}

set executables 0
foreach dir [split $env(PATH) :] {
if {[catch [list set files [glob -nocomplain ${dir}/*]]]} { continue }
foreach file $files {
if {[file executable $file]} {
lappend executables [file tail ${file}]
}
}
}
}

#**
# build a list hosts from the /etc/hosts file.
# this is only done once. This is sort of a
# dirty hack, /etc/hosts is hardcoded ...
# But on the other side, if the user supplies
# a valid host table in tclreadline::hosts
# before entering the event loop, this proc
# will return this list.
#
proc HostList {} {
# read the host table only once.
#
variable hosts
if {![info exists hosts]} {
catch {
set hosts ""
set id [open /etc/hosts r]
if {0 != ${id}} {
while {-1 != [gets ${id} line]} {
regsub {#.*} ${line} {} line
if {[llength ${line}] >= 2} {
lappend hosts [lindex ${line} 1]
}
}
close ${id}
}
}
}
return ${hosts}
}

#**
# never return an empty string, never complete.
# This is useful for showing options lists for example.
#
proc DisplayHints {lst} {
return [string trim "{} ${lst}"]
}

#**
# find (partial) matches for `text' in `lst'. Ring
# the bell and return the whole list, if the user
# tries to complete ?..? options or <..> hints.
#
# MatchesFromList returns a list which is not suitable
# for passing to the readline completer. Thus,
# MatchesFromList should not be called directly but
# from formatting routines as TryFromList.
#
proc MatchesFromList {text lst {allow ""}} {
set result ""
set text [StripPrefix $text]
set null [string index $text 0]
foreach char {< ?} {
if {$char == $null && -1 == [string first $char $allow]} {
Alert
return $lst
}
}
# puts stderr "(MatchesFromList) text=$text"
# puts stderr "(MatchesFromList) lst=$lst"
foreach word $lst {
if {[string match ${text}* ${word}]} {
lappend result ${word}
}
}
return [string trim $result]
}

#**
# invoke cmd with a (hopefully) invalid string and
# parse the error message to get an option list.
# The strings are carefully chosen to match the
# results produced by known tcl routines. It's a
# pity, that not all object commands generate
# standard error messages!
#
# @param   cmd
# @return  list of options for cmd
# @date    Sep-14-1999
#
proc TrySubCmds {text cmd} {

set trystring ----

# try the command with and w/o trystring.
# Some commands, e.g.
#     .canvas bind
# return an error if invoked w/o arguments
# but not, if invoked with arguments. Breaking
# the loop is eventually done at the end ...
#
for {set str ${trystring}} {1} {set str ""} {

set code [catch {set result [eval ${cmd} ${str}]} msg]
set result ""

if {$code} {
set tcmd [string trim ${cmd}]
# puts stderr msg=$msg
# XXX see
#         tclIndexObj.c
#         tkImgPhoto.c
# XXX
if {[regexp \
{(bad|ambiguous|unrecognized) .*"----": *must *be( .*$)} \
${msg} all junk raw]
} {
regsub -all -- , ${raw} { } raw
set len [llength ${raw}]
set len_2 [expr ${len} - 2]
for {set i 0} {${i} < ${len}} {incr i} {
set word [lindex ${raw} ${i}]
if {"or" != ${word} && ${i} != ${len_2}} {
lappend result ${word}
}
}
if {[string length ${result}] && \
-1 == [string first ${trystring} ${result}]
} {
return [TryFromList ${text} ${result}]
}

} elseif {[regexp \
"wrong # args: should be \"?${tcmd}\[^ \t\]*\(.*\[^\"\]\)" \
${msg} all hint]

} {

# XXX see tclIndexObj.c XXX
if {-1 == [string first ${trystring} ${hint}]} {
return [DisplayHints [list <[string trim $hint]>]]
}
} else {
# check, if it's a blt error msg ...
#
set msglst [split ${msg} \n]
foreach line ${msglst} {
if {[regexp "${tcmd}\[ \t\]\+\(\[^ \t\]*\)\[^:\]*$" \
${line} all sub]
} {
lappend result [list ${sub}]
}
}
if {[string length ${result}] && \
-1 == [string first ${trystring} ${result}]
} {
return [TryFromList ${text} ${result}]
}
}
}
if {"" == ${str}} {
break
}
}
return ""
}

#**
# try to get casses for commands which
# allow `configure' (cget).
# @param  command.
# @param  optionsT where the table will be stored.
# @return number of options
# @date   Sat-Sep-18
#
proc ClassTable {cmd} {

# first we build an option table.
# We always use `configure' here,
# because cget will not return the
# option table.
#
if {[catch [list set option_table [eval ${cmd} configure]] msg]} {
return ""
}
set classes ""
foreach optline ${option_table} {
if {5 != [llength ${optline}]} continue else {
lappend classes [lindex ${optline} 2]
}
}
return ${classes}
}

#**
# try to get options for commands which
# allow `configure' (cget).
# @param command.
# @param optionsT where the table will be stored.
# @return number of options
# @date Sep-14-1999
#
proc OptionTable {cmd optionsT} {
upvar $optionsT options
# first we build an option table.
# We always use `configure' here,
# because cget will not return the
# option table.
#
if {[catch [list set option_table [eval ${cmd} configure]] msg]} {
return 0
}
set retval 0
foreach optline ${option_table} {
if {5 == [llength ${optline}]} {
# tk returns a list of length 5
lappend options(switches) [lindex ${optline} 0]
lappend options(value)    [lindex ${optline} 4]
incr retval
} elseif {3 == [llength ${optline}]} {
# itcl returns a list of length 3
lappend options(switches) [lindex ${optline} 0]
lappend options(value)    [lindex ${optline} 2]
incr retval
}
}
return $retval
}

#**
# try to complete a `cmd configure|cget ..' from the command's options.
# @param   text start line cmd, standard tclreadlineCompleter arguments.
# @return  -- a flag indicating, if (cget|configure) was found.
# @return  resultT -- a tclreadline completer formatted string.
# @date    Sep-14-1999
#
proc CompleteFromOptions {text start line resultT} {

upvar ${resultT} result
set result ""

# check if either `configure' or `cget' is present.
#
set lst [ProperList ${line}]
foreach keyword {configure cget} {
set idx [lsearch ${lst} ${keyword}]
if {-1 != ${idx}} {
break
}
}
if {-1 == ${idx}} {
return 0
}

if {[regexp {(cget|configure)$} ${line}]} {
# we are at the end of (configure|cget)
# but there's no space yet.
#
set result ${text}
return 1
}

# separate the command, but exclude (cget|configure)
# because cget won't return the option table. Instead
# OptionTable always uses `configure' to get the
# option table.
#
set cmd [lrange ${lst} 0 [expr ${idx} - 1]]

TraceText ${cmd}
if {0 < [OptionTable ${cmd} options]} {

set prev [PreviousWord ${start} ${line}]
if {-1 != [set found [lsearch -exact $options(switches) ${prev}]]} {

# complete only if the user has not
# already entered something here.
#
if {![llength ${text}]} {

# check first, if the SpecificSwitchCompleter
# knows something about this switch. (note that
# `prev' contains the switch). The `0' as last
# argument makes the SpecificSwitchCompleter
# returning "" if it knows nothing specific
# about this switch.
#
set values [SpecificSwitchCompleter \
${text} ${start} ${line} ${prev} 0]

if [string length ${values}] {
set result ${values}
return 1
} else {
set val [lindex $options(value) ${found}]
if [string length ${val}] {
# return the old value only, if it's non-empty.
# Use this double list to quote option
# values which have to be quoted.
#
set result [list [list ${val}]]
return 1
} else {
set result ""
return 1
}
}
} else {
set result [SpecificSwitchCompleter \
${text} ${start} ${line} ${prev} 1]
return 1
}

} else {
set result [CompleteFromList ${text} \
[RemoveUsedOptions ${line} $options(switches)]]
return 1
}
}
return 1
}

proc ObjectClassCompleter {text start end line pos resultT} {
upvar ${resultT} result
set cmd [Lindex ${line} 0]
if {"." == [string index ${line} 0]} {
# it's a widget. Try to get it's class name.
#
if {![catch [list set class [winfo class [Lindex ${line} 0]]]]} {
if {[string length [info proc ${class}Obj]]} {
set result [${class}Obj ${text} ${start} ${end} ${line} ${pos}]
# puts stderr result=|$result|
# joze, Thu Sep 30 16:43:17 1999
if {[string length $result]} {
return 1
} else {
return 0
}
} else {
return 0
}
}
}
if {![catch {list set type [image type ${cmd}]}]} {
switch -- ${type} {
photo {
set result [PhotoObj ${text} ${start} ${end} ${line} ${pos}]
return 1
}
default {
# let the fallback completers do the job.
return 0
}
}
}
return 0
}

proc CompleteFromOptionsOrSubCmds {text start end line pos} {
if [CompleteFromOptions ${text} ${start} ${line} from_opts] {
# always return, if CompleteFromOptions returns non-zero,
# that means (configure|cget) were present. This ensures
# that TrySubCmds will not configure something by chance.
#
return ${from_opts}
} else {
# puts stderr \n\n[lrange [ProperList ${line}] 0 [expr $pos - 1]]\n
return [TrySubCmds ${text} \
[lrange [ProperList ${line}] 0 [expr $pos - 1]]]
}
return ""
}

#**
# TODO: shit. make this better!
# @param  text, a std completer argument (current word).
# @param  fullpart, the full text of the current position.
# @param  lst, the list to complete from.
# @param  pre, leading `quote'.
# @param  sep, word separator.
# @param  post, trailing `quote'.
# @return a formatted completer string.
# @date   Sep-15-1999
#
proc CompleteListFromList {text fullpart lst pre sep post} {

# puts stderr ""
# puts stderr text=|$text|
# puts stderr lst=|$lst|
# puts stderr pre=|$pre|
# puts stderr sep=|$sep|
# puts stderr post=|$post|

if {![string length ${fullpart}]} {

# nothing typed so far. Insert a $pre
# and inhibit further completion.
#
return [list ${pre} {}]

} elseif {${post} == [String index ${text} end]} {

# finalize, append the post and a space.
#
set diff \
[expr [CountChar ${fullpart} ${pre}] - [CountChar ${fullpart} ${post}]]
for {set i 0} {${i} < ${diff}} {incr i} {
append text ${post}
}
append text " "
return ${text}

} elseif {![regexp -- ^\(.*\[${pre}${sep}\]\)\(\[^${pre}${sep}\]*\)$ \
${text} all left right]
} {
set left {}
set right ${text}
}

# TraceVar left
# TraceVar right

# puts stderr \nleft=|$left|
# puts stderr \nright=|$right|
set exact_matches [MatchesFromList ${right} ${lst}]
# TODO this is awkward. Think of making it better!
#
if {1 == [llength ${exact_matches}] && -1 != [lsearch ${lst} ${right}]
} {
#set completion [CompleteFromList ${right} [list ${sep} ${post}] 1]
return [list ${left}${right}${sep} {}]
} else {
set completion [CompleteFromList ${right} ${lst} "" 1]
}
# puts stderr \ncompletion=|$completion|
if {![string length [lindex $completion 0]]} {
return [concat [list ${left}] [lrange $completion 1 end]]
} elseif {[string length ${left}]} {
return [list ${left}]${completion}
} else {
return ${completion}
}
return ""
}

proc FirstNonOption {line} {
set expr_pos 1
foreach word [lrange ${line} 1 end] {; # 0 is the command itself
if {"-" != [string index ${word} 0]} {
break
} else {
incr expr_pos
}
}
return ${expr_pos}
}

proc RemoveUsedOptions {line opts {terminate {}}} {
if {[llength ${terminate}]} {
if {[regexp -- ${terminate} ${line}]} {
return ""
}
}
set new ""
foreach word ${opts} {
if {-1 == [string first ${word} ${line}]} {
lappend new ${word}
}
}

# check if the last word in the line is an options
# and if this word is at the very end of the line,
# that means no space after.
# If this is so, the word is stuffed into the result,
# so that it can be completed -- probably with a space.
#
set last [Lindex ${line} end]
if {[expr [string last ${last} ${line}] + [string length ${last}]] == \
[string length ${line}]
} {
if {-1 != [lsearch ${opts} ${last}]} {
lappend new ${last}
}
}

return [string trim ${new}]
}

proc Alert {} {
::tclreadline::readline bell
}

#**
# get the longest common completion
# e.g. str == {tcl_version tclreadline_version tclreadline_library}
# --> [CompleteLongest ${str}] == "tcl"
#
proc CompleteLongest {str} {
# puts stderr str=$str
set match0 [lindex ${str} 0]
set len0 [string length $match0]
set no_matches [llength ${str}]
set part ""
for {set i 0} {$i < $len0} {incr i} {
set char [string index $match0 $i]
for {set j 1} {$j < $no_matches} {incr j} {
if {$char != [string index [lindex ${str} $j] $i]} {
break
}
}
if {$j < $no_matches} {
break
} else {
append part $char
}
}
# puts stderr part=$part
return ${part}
}

proc SplitLine {start line} {
set depth 0
# puts stderr SplitLine
for {set i $start} {$i >= 0} {incr i -1} {
set c [string index $line $i]
if {{;} == $c} {
incr i; # discard command break character
return [list [expr $start - $i] [String range $line $i end]]
} elseif {{]} == $c} {
incr depth
} elseif {{[} == $c} {
incr depth -1
if {$depth < 0} {
incr i; # discard command break character
return [list [expr $start - $i] [String range $line $i end]]
}
}
}
return ""
}

proc IsWhite {char} {
if {" " == $char || "\n" == $char || "\t" == $char} {
return 1
} else {
return 0
}
}

proc PreviousWordOfIncompletePosition {start line} {
return [lindex [ProperList [string range ${line} 0 ${start}]] end]
}

proc PreviousWord {start line} {
incr start -1
set found 0
for {set i $start} {$i > 0} {incr i -1} {
set c [string index $line $i]
if {${found} && [IsWhite $c]} {
break
} elseif {!${found} && ![IsWhite $c]} {
set found 1
}
}
return [string trim [string range ${line} $i $start]]
}

proc Quote {value left} {
set right [Right ${left}]
if {1 < [llength $value] && "" == $right} {
return [list \"${value}\"]
} else {
return [list ${left}${value}${right}]
}
}

# the following two channel proc's make use of
# the brandnew (Sep 99) `file channels' command
# but have some fallback behaviour for older
# tcl version.
#
proc InChannelId {text {switches ""}} {
if [catch {set chs [file channels]}] {
set chs {stdin}
}
set result ""
foreach ch $chs {
if {![catch {fileevent $ch readable}]} {
lappend result $ch
}
}
return [ChannelId ${text} <inChannel> $result $switches]
}

proc OutChannelId {text {switches ""}} {
if [catch {set chs [file channels]}] {
set chs {stdout stderr}
}
set result ""
foreach ch $chs {
if {![catch {fileevent $ch writable}]} {
lappend result $ch
}
}
return [ChannelId ${text} <outChannel> $result $switches]
}

proc ChannelId {text {descript <channelId>} {chs ""} {switches ""}} {
if {"" == ${chs}} {
# the `file channels' command is present
# only in pretty new versions.
#
if [catch {set chs [file channels]}] {
set chs {stdin stdout stderr}
}
}
if {[llength [set channel [TryFromList ${text} "${chs} ${switches}"]]]} {
return ${channel}
} else {
return [DisplayHints [string trim "${descript} ${switches}"]]
}
}

proc QuoteQuotes {line} {
regsub -all -- \" $line {\"} line
regsub -all -- \{ $line {\{} line; # \}\} (keep the editor happy)
return $line
}

#**
# get the word position.
# @return the word position
# @note will returned modified values.
# @sa EventuallyEvaluateFirst
# @date Sep-06-1999
#
# % p<TAB>
# % bla put<TAB> $b
# % put<TAB> $b
# part  == put
# start == 0
# end   == 3
# line  == "put $b"
# [PartPosition] should return 0
#
proc PartPosition {partT startT endT lineT} {

upvar $partT part $startT start $endT end $lineT line
EventuallyEvaluateFirst part start end line
return [Llength [string range $line 0 [expr $start - 1]]]

#
#     set local_start [expr $start - 1]
#     set local_start_chr [string index $line $local_start]
#     if {"\"" == $local_start_chr || "\{" == $local_start_chr} {
#         incr local_start -1
#     }
#
#     set pre_text [QuoteQuotes [string range $line 0 $local_start]]
#     return [llength $pre_text]
#
}

proc Right {left} {
# puts left=$left
if {"\"" == $left} {
return "\""
} elseif {"\\\"" == $left} {
return "\\\""
} elseif {"\{" == $left} {
return "\}"
} elseif {"\\\{" == $left} {
return "\\\}"
}
return ""
}

proc GetQuotedPrefix {text} {
set null [string index $text 0]
if {"\"" == $null || "\{" == $null} {
return \\$null
} else {
return {}
}
}

proc CountChar {line char} {
# puts stderr char=|$char|
set found 0
set pos 0
while {-1 != [set pos [string first $char $line $pos]]} {
incr pos
incr found
}
return $found
}

#**
# make a proper tcl list from an icomplete
# string, that is: remove the junk. This is
# complementary to `IncompleteListRemainder'.
# e.g.:
#       for {set i 1} "
#  -->  for {set i 1}
#
proc ProperList {line} {
set last [expr [string length $line] - 1]
for {set i $last} {$i >= 0} {incr i -1} {
if {![catch {llength [string range $line 0 $i]}]} {
break
}
}
return [string range $line 0 $i]
}

#**
# return the last part of a line which
# prevents the line from beeing a list.
# This is complementary to `ProperList'.
#
proc IncompleteListRemainder {line} {
set last [expr [string length $line] - 1]
for {set i $last} {$i >= 0} {incr i -1} {
if {![catch {llength [string range $line 0 $i]}]} {
break
}
}
incr i
return [String range $line $i end]
}

#**
# save `lindex'. works also for non-complete lines
# with opening parentheses or quotes.
# usage as `lindex'.
# Eventually returns the Rest of an incomplete line,
# if the index is `end' or == [Llength $line].
#
proc Lindex {line pos} {
if {[catch [list set sub [lindex ${line} ${pos}]]]} {
if {"end" == ${pos} || [Llength ${line}] == ${pos}} {
return [IncompleteListRemainder ${line}]
}
set line [ProperList ${line}]
# puts stderr \nproper_line=|$proper_line|
if {[catch [list set sub [lindex ${line} ${pos}]]]} { return {} }
}
return ${sub}
}

#**
# save `llength' (see above).
#
proc Llength {line} {
if {[catch [list set len [llength ${line}]]]} {
set line [ProperList ${line}]
if {[catch [list set len [llength ${line}]]]} { return {} }
}
# puts stderr \nline=$line
return ${len}
}

#**
# save `lrange' (see above).
#
proc Lrange {line first last} {
if {[catch [list set range [lrange ${line} ${first} ${last}]]]} {
set rest [IncompleteListRemainder ${line}]
set proper [ProperList ${line}]
if {[catch [list set range [lindex ${proper} ${first} ${last}]]]} {
return {}
}
if {"end" == ${last} || [Llength ${line}] == ${last}} {
append sub " ${rest}"
}
}
return ${range}
}

#**
# Lunique -- remove duplicate entries from a sorted list
# @param   list
# @return  unique list
# @author  Johannes Zellner
# @date    Sep-19-1999
#
proc Lunique lst {
set unique ""
foreach element ${lst} {
if {${element} != [lindex ${unique} end]} {
lappend unique ${element}
}
}
return ${unique}
}

#**
# string function, which works also for older versions
# of tcl, which don't have the `end' index.
# I tried also defining `string' and thus overriding
# the builtin `string' which worked, but slowed down
# things considerably. So I decided to call `String'
# only if I really need the `end' index.
#
proc String args {
if {[info tclversion] < 8.2} {
switch [lindex $args 1] {
range -
index {
if {"end" == [lindex $args end]} {
set str [lindex $args 2]
lreplace args end end [expr [string length $str] - 1]
}
}
}
}
return [eval string $args]
}

proc StripPrefix {text} {
# puts "(StripPrefix) text=|$text|"
set null [string index $text 0]
if {"\"" == $null || "\{" == $null} {
return [String range $text 1 end]
} else {
return $text
}
}

proc VarCompletion {text {level -1}} {
if {"#" != [string index ${level} 0]} {
if {-1 == ${level}} {
set level [info level]
} else {
incr level
}
}
set pre [GetQuotedPrefix ${text}]
set var [StripPrefix ${text}]
# puts stderr "(VarCompletion) pre=|$pre|"
# puts stderr "(VarCompletion) var=|$var|"

# arrays
#
if {[regexp {([^(]*)\((.*)} ${var} all array name]} {
set names [uplevel ${level} array names ${array} ${name}*]
if {1 == [llength $names]} { ; # unique match
return "${array}(${names})"
} elseif {"" != ${names}} {
return "${array}([CompleteLongest ${names}] ${names}"
} else {
return ""; # nothing to complete
}
}

# non-arrays
#
regsub ":$" ${var} "::" var
set namespaces [namespace children :: ${var}*]
if {[llength ${namespaces}] && "::" != [string range ${var} 0 1]} {
foreach name ${namespaces} {
regsub "^::" ${name} "" name
if {[string length ${name}]} {
lappend new ${name}::
}
}
set namespaces ${new}
unset new
}
set matches \
[string trim "[uplevel ${level} info vars ${var}*] ${namespaces}"]
if {1 == [llength $matches]} { ; # unique match

# check if this unique match is an
# array name, (whith no "(" yet).
#
if {[uplevel ${level} array exists $matches]} {
return [VarCompletion ${matches}( ${level}]; # recursion
} else {
return ${pre}${matches}[Right ${pre}]
}
} elseif {"" != $matches} { ; # more than one match
return [CompleteFromList ${text} ${matches}]
} else {
return ""; # nothing to complete
}
}

proc CompleteControlStatement {text start end line pos mod pre new_line} {
set pre [GetQuotedPrefix ${pre}]
set cmd [Lindex $new_line 0]
set diff [expr \
[string length $line] - [string length $new_line]]
if {$diff == [expr $start + 1]} {
set mod1 $mod
} else {
set mod1 $text
set pre ""
}
set new_end [expr $end - $diff]
set new_start [expr $new_end - [string length $mod1]]
# puts ""
# puts new_start=$new_start
# puts new_end=$new_end
# puts new_line=$new_line
# puts mod1=$mod1
if {$new_start < 0} {
return ""; # when does this occur?
}
# puts stderr ""
# puts stderr start=|$start|
# puts stderr end=|$end|
# puts stderr mod=|$mod|
# puts stderr new_start=|$new_start|
# puts stderr new_end=|$new_end|
# puts stderr new_line=|$new_line|
# puts stderr ""
set res [ScriptCompleter $mod1 $new_start $new_end $new_line]
# puts stderr \n\${pre}\${res}=|${pre}${res}|
if {[string length [Lindex ${res} 0]]} {
return ${pre}${res}
} else {
return ${res}
}
return ""
}

proc BraceOrCommand {text start end line pos mod} {
if {![string length [Lindex $line $pos]]} {
return [list \{ {}]; # \}
} else {
set new_line [string trim [IncompleteListRemainder $line]]
if {![regexp {^([\{\"])(.*)$} $new_line all pre new_line]} {
set pre ""
}
return [CompleteControlStatement $text \
$start $end $line $pos $mod $pre $new_line]
}
}

proc FullQualifiedMatches {qualifier matchlist} {
set new ""
if {"" != $qualifier && ![regexp ::$ $qualifier]} {
append qualifier ::
}
foreach entry ${matchlist} {
set full ${qualifier}${entry}
if {"" != [namespace which ${full}]} {
lappend new ${full}
}
}
return ${new}
}

proc ProcsOnlyCompletion {cmd} {
return [CommandCompletion ${cmd} procs]
}

proc CommandsOnlyCompletion {cmd} {
return [CommandCompletion ${cmd} commands]
}

proc CommandCompletion {cmd {action both} {spc ::}} {
# get the leading colons in `cmd'.
regexp {^:*} ${cmd} pre
return [CommandCompletionWithPre $cmd $action $spc $pre]
}

proc CommandCompletionWithPre {cmd action spc pre} {
# puts stderr "(CommandCompletion) cmd=|$cmd|"
# puts stderr "(CommandCompletion) action=|$action|"
# puts stderr "(CommandCompletion) spc=|$spc|"

set cmd [StripPrefix ${cmd}]
set quali [namespace qualifiers ${cmd}]
if {[string length ${quali}]} {
# puts stderr \nquali=|$quali|
set matches [CommandCompletionWithPre \
[namespace tail ${cmd}] ${action} ${spc}${quali} ${pre}]
# puts stderr \nmatches1=|$matches|
return $matches
}
set cmd [string trim ${cmd}]*
# puts stderr \ncmd=|$cmd|\n
if {"procs" != ${action}} {
set all_commands [namespace eval $spc [list info commands ${cmd}]]
# puts stderr all_commands=|$all_commands|
set commands ""
foreach command $all_commands {
if {[namespace eval $spc [list namespace origin $command]] == \
[namespace eval $spc [list namespace which $command]]} {
lappend commands $command
}
}
} else {
set commands ""
}
if {"commands" != ${action}} {
set all_procs [namespace eval $spc [list info procs ${cmd}]]
# puts stderr procs=|$procs|
set procs ""
foreach proc $all_procs {
if {[namespace eval $spc [list namespace origin $proc]] == \
[namespace eval $spc [list namespace which $proc]]} {
lappend procs $proc
}
}
} else {
set procs ""
}
set matches [namespace eval $spc concat ${commands} ${procs}]
set namespaces [namespace children $spc ${cmd}]

if {![llength ${matches}] && 1 == [llength ${namespaces}]} {
set matches [CommandCompletionWithPre {} ${action} ${namespaces} ${pre}]
# puts stderr \nmatches=|$matches|
return $matches
}

# make `namespaces' having exactly
# the same number of colons as `cmd'.
#
regsub -all {^:*} $spc $pre spc

set matches [FullQualifiedMatches ${spc} ${matches}]
# puts stderr \nmatches3=|$matches|
return [string trim "${matches} ${namespaces}"]
}

#**
# check, if the first argument starts with a '['
# and must be evaluated before continuing.
# NOTE: trims the `line'.
#       eventually modifies all arguments.
# DATE: Sep-06-1999
#
proc EventuallyEvaluateFirst {partT startT endT lineT} {
# return; # disabled
upvar $partT part $startT start $endT end $lineT line

set oldlen [string length ${line}]
# set line [string trim ${line}]
set line [string trimleft ${line}]
set diff [expr [string length $line] - $oldlen]
incr start $diff
incr end $diff

set char [string index ${line} 0]
if {{[} != ${char} && {$} != ${char}} {return}

set pos 0
while {-1 != [set idx [string first {]} ${line} ${pos}]]} {
set cmd [string range ${line} 0 ${idx}]
if {[info complete ${cmd}]} {
break;
}
set pos [expr ${idx} + 1]
}

if {![info exists cmd]} {return}
if {![info complete ${cmd}]} {return}
set cmd [string range ${cmd} 1 [expr [string length ${cmd}] - 2]]
set rest [String range ${line} [expr ${idx} + 1] end]

if {[catch [list set result [string trim [eval ${cmd}]]]]} {return}

set line ${result}${rest}
set diff [expr [string length ${result}] - ([string length ${cmd}] + 2)]
incr start ${diff}
incr end ${diff}
}

# if the line entered so far is
# % puts $b<TAB>
# part  == $b
# start == 5
# end   == 7
# line  == "$puts $b"
#
proc ScriptCompleter {part start end line} {

# puts stderr "(ScriptCompleter) |$part| $start $end |$line|"

# if the character before the cursor is a terminating
# quote and the user wants completion, we insert a white
# space here.
#
set char [string index $line [expr $end - 1]]
if {"\}" == $char} {
append $part " "
return [list $part]
}

if {{$} == [string index $part 0]} {

# check for a !$ history event
#
if {$start > 0} {
if {{!} == [string index $line [expr $start - 1]]} {
return ""
}
}
# variable completion. Check first, if the
# variable starts with a plain `$' or should
# be enclosed in braces.
#
set var [String range $part 1 end]

# check if $var is an array name, which
# already has already a "(" somewhere inside.
#
if {"" != [set vc [VarCompletion $var]]} {
if {"" == [lindex $vc 0]} {
return "\$ [lrange ${vc} 1 end]"
} else {
return \$${vc}
}
# puts stderr vc=|$vc|
} else {
return ""
}

# SCENARIO:
#
# % puts bla; put<TAB> $b
# part  == put
# start == 10
# end   == 13
# line  == "puts bla; put $b"
# [SplitLine] --> {1 " put $b"} == sub
# new_start = [lindex $sub 0] == 1
# new_end   = [expr $end - ($start - $new_start)] == 4
# new_part  == $part == put
# new_line  = [lindex $sub 1] == " put $b"
#
} elseif {"" != [set sub [SplitLine $start $line]]} {

set new_start [lindex $sub 0]
set new_end [expr $end - ($start - $new_start)]
set new_line [lindex $sub 1]
# puts stderr "(SplitLine) $new_start $new_end $new_line"
return [ScriptCompleter $part $new_start $new_end $new_line]

} elseif {0 == [set pos [PartPosition part start end line]]} {

# XXX
#     note that line will be [string trimleft'ed]
#     after PartPosition.
# XXX

# puts stderr "(PartPosition) $part $start $end $line"
set all [CommandCompletion ${part}]
# puts stderr "(ScriptCompleter) all=$all"
#puts \nmatches=$matches\n
# return [Format $all $part]
return [TryFromList $part $all]

} else {

# try to use $pos further ...
# puts stderr |$line|
#
# if {"." == [string index [string trim ${line}] 0]} {
# 	set alias WIDGET
# 	set namespc ""; # widgets are always in the global
# } else {

# the double `lindex' strips {} or quotes.
# the subst enables variables containing
# command names.
#
set alias [uplevel [info level] \
subst [lindex [lindex [QuoteQuotes ${line}] 0] 0]]

# make `alias' a fully qualified name.
# this can raise an error, if alias is
# no valid command.
#
if {[catch {set alias [namespace origin $alias]}]} {
return ""
}

# strip leading ::'s.
#
regsub -all {^::} $alias {} alias
set namespc [namespace qualifiers $alias]
set alias [namespace tail $alias]
# }

# try first a specific completer, then, and only then
# the tclreadline_complete_unknown.
#
foreach cmd [list ${alias} tclreadline_complete_unknown] {
# puts stderr ${namespc}complete(${cmd})
if {"" != [namespace eval ::tclreadline::${namespc} \
[list info procs complete(${cmd})]]
} {
# puts found=|complete($cmd)|
# to be more error-proof, we check here,
# if complete($cmd) takes exactly 5 arguments.
#
if {6 != [set arguments [llength \
[namespace eval ::tclreadline::${namespc} \
[list info args complete($cmd)]]]]
} {
error [list complete(${cmd}) takes ${arguments} \
arguments, but should take exactly 6.]
}

# remove leading quotes
#
set mod [StripPrefix $part]
# puts stderr mod=$mod

if {[catch [list set script_result \
[namespace eval ::tclreadline::${namespc} \
[list complete(${cmd}) $part $start $end $line $pos $mod]]]\
::tclreadline::errorMsg]
} {
error [list error during evaluation of `complete(${cmd})']
}
# puts stderr \nscript_result=|${script_result}|
if {![string length ${script_result}] && \
"tclreadline_complete_unknown" == ${cmd}
} {
# as we're here, the tclreadline_complete_unknown
# returned an empty string. Fall thru and try
# further fallback completers.
#
} else {
# return also empty strings, if
# they're from a specific completer.
#
TraceText script_result=|${script_result}|
return ${script_result}
}
}
# set namespc ""; # no qualifiers for tclreadline_complete_unknown
}

# as we've reached here no valid specific completer
# was found. Check, if it's a proc and return the
# arguments.
#
if {![string length ${namespc}]} {
set namespc ::
}
if {[string length [uplevel [info level] \
namespace eval ${namespc} [list ::info proc $alias]]]
} {
if ![string length [string trim $part]] {
set args [uplevel [info level] \
namespace eval ${namespc} [list info args $alias]]
set arg [lindex $args [expr $pos - 1]]
if {"" != $arg && "args" != $arg} {
if {[uplevel [info level] namespace eval \
${namespc} [list info default $alias $arg junk]]} {
return [DisplayHints ?$arg?]
} else {
return [DisplayHints <$arg>]
}
}
} else {
return ""; # enable file name completion
}
}

# check if the command is an object of known class.
#
if [ObjectClassCompleter ${part} ${start} ${end} ${line} ${pos} res] {
return ${res}
}

# Ok, also no proc. Try to do the same as for widgets now:
# try to complete from the option table if the subcommand
# is `configure' or `cget' otherwise try to get further
# subcommands.
#
return [CompleteFromOptionsOrSubCmds \
${part} ${start} ${end} ${line} ${pos}]
}
error "{NOTREACHED (this is probably an error)}"
}


# explicit command completers
#

# -------------------------------------
#                 TCL
# -------------------------------------

proc complete(after) {text start end line pos mod} {
set sub [Lindex $line 1]
# puts \npos=$pos
switch -- $pos {
1 {
return [CompleteFromList ${text} {<ms> cancel idle info}]
}
2 {
switch -- $sub {
cancel {
return [CompleteFromList $text "<script> [after info]"]
}
idle {
return [DisplayHints <script>]
}
info {
return [CompleteFromList $text [after info]]
}
default { return [DisplayHints ?script?] }
}
}
default {
switch -- $sub {
info { return [DisplayHints {}] }
default { return [DisplayHints ?script?] }
}
}
}
return ""
}

proc complete(append) {text start end line pos mod} {
switch -- $pos {
1       { return [VarCompletion ${text}] }
default { return [DisplayHints ?value?] }
}
return ""
}

proc complete(array) {text start end line pos mod} {
switch -- $pos {
1 {
set cmds {
anymore donesearch exists get names
nextelement set size startsearch
}
return [CompleteFromList $text $cmds]
}
2 {
set matches ""
# set vars [uplevel [info level] info vars ${mod}*]
#
# better: this displays a list of array names if the
# user inters with something which cannot be matched.
# The matching against `text' is done by CompleteFromList.
#
set vars [uplevel [info level] info vars]
foreach var ${vars} {
if {[uplevel [info level] array exists ${var}]} {
lappend matches ${var}
}
}
return [CompleteFromList ${text} ${matches}]
}
3 {
set cmd [Lindex $line 1]
set array_name [Lindex $line 2]
switch -- $cmd {
get -
names {
set pattern [Lindex $line 3]
set matches [uplevel [info level] \
array names ${array_name} ${pattern}*]
if {![llength $matches]} {
return [DisplayHints ?pattern?]
} else {
return [CompleteFromList ${text} ${matches}]
}
}
anymore -
donesearch -
nextelement { return [DisplayHints <searchId>] }
}
}
}
return ""
}

# proc complete(bgerror) {text start end line pos mod} {
# }

proc complete(binary) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
return [CompleteFromList $text {format scan}]
}
2 {
switch -- $cmd {
format { return [DisplayHints <formatString>] }
scan   { return [DisplayHints <string>] }
}
}
3 {
switch -- $cmd {
format { return [DisplayHints ?arg?] }
scan   { return [DisplayHints <formatString>] }
}
}
default {
switch -- $cmd {
format { return [DisplayHints ?arg?] }
scan   { return [DisplayHints ?varName?] }
}
}
}
return ""
}

# proc complete(break) {text start end line pos mod} {
# }

proc complete(catch) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <script>] }
2 { return [DisplayHints ?varName?] }
}
return ""
}

proc complete(cd) {text start end line pos mod} {
return ""
}

proc complete(clock) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
return [CompleteFromList $text {clicks format scan seconds}]
}
2 {
switch -- $cmd {
format  { return [DisplayHints <clockValue>] }
scan    { return [DisplayHints <dateString>] }
clicks  -
seconds {}
}
}
3 -
5 {
switch -- $cmd {
format {
set subcmds [RemoveUsedOptions $line {-format -gmt}]
return [TryFromList $text $subcmds]
}
scan {
set subcmds [RemoveUsedOptions $line {-base -gmt}]
return [TryFromList $text $subcmds]
}
clicks  -
seconds {}
}
}
4 -
6 {
set sub [Lindex $line [expr $pos - 1]]
switch -- $cmd {
format {
switch -- $sub {
-format { return [DisplayHints <string>] }
-gmt    { return [DisplayHints <boolean>] }
}
}
scan {
switch -- $sub {
-base { return [DisplayHints <clockVal>] }
-gmt  { return [DisplayHints <boolean>] }
}
}
clicks  -
seconds {}
}
}
}
return ""
}

proc complete(close) {text start end line pos mod} {
switch -- $pos {
1 { return [ChannelId $text] }
}
return ""
}

proc complete(concat) {text start end line pos mod} {
return [DisplayHints ?arg?]
}

# proc complete(continue) {text start end line pos mod} {
# }

# proc complete(dde) {text start end line pos mod} {
#     We're not on windoze here ...
# }

proc complete(encoding) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
return [CompleteFromList $text {convertfrom convertto names system}]
}
2 {
switch -- $cmd {
convertfrom -
convertto -
system {
return [CompleteFromList ${text} [encoding names]]
}
}
}
3 {
switch -- $cmd {
convertfrom { return [DisplayHints <data>] }
convertto { return [DisplayHints <string>] }
}
}
}
return ""
}

proc complete(eof) {text start end line pos mod} {
switch -- $pos {
1 { return [InChannelId $text] }
}
return ""
}

proc complete(error) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <message>] }
2 { return [DisplayHints ?info?] }
3 { return [DisplayHints ?code?] }
}
return ""
}

proc complete(eval) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <arg>] }
default { return [DisplayHints ?arg?] }
}
return ""
}

proc complete(exec) {text start end line pos mod} {
set redir [list | |& < <@ << > 2> >& >> 2>> >>& >@ 2>@ >&@]
variable executables
if {![info exists executables]} {
Rehash
}
switch -- $pos {
1 {
return [TryFromList $text "-keepnewline -- $executables"]
}
default {
set prev [PreviousWord ${start} ${line}]
if {"-keepnewline" == $prev && 2 == $pos} {
return [TryFromList $text "-- $executables"]
}
switch -exact -- $prev {
| -
|& { return [TryFromList $text $executables] }
< -
> -
2> -
>& -
>> -
2>> -
>>& { return "" }
<@ -
>@ -
2>@ -
>&@ { return [ChannelId $text] }
<< { return [DisplayHints <value>] }
default { return [TryFromList $text $redir "<>"] }
}
}
}
return ""
}

proc complete(exit) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints ?returnCode?] }
}
return ""
}

proc complete(expr) {text start end line pos mod} {
set left $text
set right ""
set substitution [regexp -- {(.*)(\(.*)} $text all left right]; #-)

set cmds {
- + ~ !  * / % + - << >> < > <= >= == != & ^ | && || <x?y:z>
acos    cos     hypot   sinh
asin    cosh    log     sqrt
atan    exp     log10   tan
atan2   floor   pow     tanh
ceil    fmod    sin     abs
double  int     rand    round
srand
}

if {")" == [String index $text end] && -1 != [lsearch $cmds $left]} {
return "$text "; # append a space after a closing ')'
}

switch -- $left {
rand { return "rand() " }

abs  -
acos -
asin -
atan -
ceil  -
cos -
cosh -
double -
exp -
floor -
int -
log -
log10 -
round  -
sin  -
sinh  -
sqrt  -
srand  -
tan  -
tanh { return [DisplayHints <value>] }


atan2 -
fmod -
hypot -
pow { return [DisplayHints <value>,<value>] }
}

set completions [TryFromList $left $cmds <>]
if {1 == [llength $completions]} {
if {!$substitution} {
if {"rand" == $completions} {
return "rand() "; # rand() takes no arguments
}
append completions (; #-)
return [list $completions {}]
}
} else {
return $completions
}
return ""
}

proc complete(fblocked) {text start end line pos mod} {
switch -- $pos {
1 { return [InChannelId $text] }
}
return ""
}

proc complete(fconfigure) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
return [ChannelId ${text}]
}
default {
set option [PreviousWord ${start} ${line}]
switch -- $option {
-blocking {
return [CompleteBoolean ${text}]
}
-buffering {
return [CompleteFromList ${text} {full line none}]
}
-buffersize {
if {![llength ${text}]} {
return [DisplayHints <newSize>]
}
}
-encoding {
return [CompleteFromList ${text} [encoding names]]
}
-eofchar {
return [DisplayHints {\{<inChar>\ <outChar>\}}]
}
-translation {
return [CompleteFromList ${text} {auto binary cr crlf lf}]
}
default {return [CompleteFromList $text \
[RemoveUsedOptions $line {
-blocking -buffering -buffersize
-encoding -eofchar -translation}]]
}
}
}
}
return ""
}

proc complete(fcopy) {text start end line pos mod} {
switch -- $pos {
1 {
return [InChannelId ${text}]
}
2 {
return [OutChannelId ${text}]
}
default {
set option [PreviousWord ${start} ${line}]
switch -- $option {
-size    { return [DisplayHints <size>] }
-command { return [DisplayHints <callback>] }
default  { return [CompleteFromList $text \
[RemoveUsedOptions $line {-size -command}]]
}
}
}
}
return ""
}

proc complete(file) {text start end line pos mod} {
switch -- $pos {
1 {
set cmds {
atime attributes channels copy delete dirname executable exists
extension isdirectory isfile join lstat mkdir mtime
nativename owned pathtype readable readlink rename
rootname size split stat tail type volumes writable
}
return [TryFromList $text $cmds]
}
2 {
set cmd [Lindex $line 1]
switch -- $cmd {
atime -
attributes -
channels -
dirname -
executable -
exists -
extension -
isdirectory -
isfile -
join -
lstat -
mtime -
mkdir -
nativename -
owned -
pathtype -
readable -
readlink -
rootname -
size -
split -
stat -
tail -
type -
volumes -
writable {
return ""
}

copy -
delete -
rename {
# return [TryFromList $text "-force [glob *]"]
# this is not perfect. The  `-force' and `--'
# options will not be displayed.
return ""
}
}
}
}
return ""
}

proc complete(fileevent) {text start end line pos mod} {
switch -- $pos {
1 {
return [ChannelId ${text}]
}
2 {
return [CompleteFromList ${text} {readable writable}]
}
3 {
return [DisplayHints ?script?]
}
}
return ""
}

proc complete(flush) {text start end line pos mod} {
switch -- $pos {
1 { return [OutChannelId ${text}] }
}
return ""
}

proc complete(for) {text start end line pos mod} {
switch -- $pos {
1 -
2 -
3 -
4 {
return [BraceOrCommand $text $start $end $line $pos $mod]
}
}
return ""
}

proc complete(foreach) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <varname>] }
2 { return [DisplayHints <list>] }
default {
if {[expr $pos % 2]} {
return [DisplayHints [list ?varname? <body>]]
} else {
return [DisplayHints ?list?]
}
}
}
return ""
}

proc complete(format) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <formatString>] }
default { return [DisplayHints ?arg?] }
}
return ""
}

proc complete(gets) {text start end line pos mod} {
switch -- $pos {
1 { return [InChannelId ${text}] }
2 { return [VarCompletion ${text}]}
}
return ""
}

proc complete(glob) {text start end line pos mod} {
switch -- $pos {
1 {
# This also is not perfect.
# This will not display the options as hints!
set matches [TryFromList ${text} {-nocomplain --}]
if {[llength [string trim ${text}]] && [llength ${matches}]} {
return ${matches}
}
}
}
return ""
}

proc complete(global) {text start end line pos mod} {
return [VarCompletion ${text}]
}

proc complete(history) {text start end line pos mod} {
switch -- $pos {
1 {
set cmds {add change clear event info keep nextid redo}
return [TryFromList $text $cmds]
}
2 {
set cmd [Lindex $line 1]
switch -- $cmd {
add { return [DisplayHints <command>] }
change { return [DisplayHints <newValue>] }

info -
keep { return [DisplayHints ?count?] }

event -
redo { return [DisplayHints ?event?] }

clear -
nextid { return "" }
}
}
}
return ""
}

# --- HTTP PACKAGE ---

# create a http namespace inside
# tclreadline and import some commands.
#
namespace eval http {
catch {
namespace import \
::tclreadline::DisplayHints ::tclreadline::PreviousWord \
::tclreadline::CompleteFromList ::tclreadline::CommandCompletion \
::tclreadline::RemoveUsedOptions ::tclreadline::HostList \
::tclreadline::ChannelId ::tclreadline::Lindex \
::tclreadline::CompleteBoolean
}
}

proc http::complete(config) {text start end line pos mod} {
set prev [PreviousWord ${start} ${line}]
switch -- $prev {
-accept { return [DisplayHints <mimetypes>] }
-proxyhost {
return [CompleteFromList $text [HostList]]
}
-proxyport { return [DisplayHints <number>] }
-proxyfilter {
return [CompleteFromList $text [CommandCompletion $text]]
}
-useragent { return [DisplayHints <string>] }
default {
return [CompleteFromList $text [RemoveUsedOptions $line {
-accept -proxyhost -proxyport -proxyfilter -useragent
}]]
}
}
return ""
}

proc http::complete(geturl) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <url>] }
default {
set prev [PreviousWord ${start} ${line}]
switch -- $prev {
-blocksize { return [DisplayHints <size>] }
-channel { return [ChannelId ${text}] }
-command -
-handler -
-progress {
return [CompleteFromList $text [CommandCompletion $text]]
}
-headers { return [DisplayHints <keyvaluelist>] }
-query { return [DisplayHints <query>] }
-timeout { return [DisplayHints <milliseconds>] }
-validate { return [CompleteBoolean $text] }
default {
return [CompleteFromList $text [RemoveUsedOptions $line {
-blocksize -channel -command -handler -headers
-progress -query -timeout -validate
}]]
}
}
}
}
return ""
}

proc http::complete(formatQuery) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <key>] }
2 { return [DisplayHints <value>] }
default {
switch [expr $pos % 2] {
0 { return [DisplayHints ?value?] }
1 { return [DisplayHints ?key?] }
}
}
}
return ""
}

proc http::complete(reset) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <token>] }
2 { return [DisplayHints ?why?] }
}
return ""
}

# the unknown proc handles the rest
#
proc http::complete(tclreadline_complete_unknown) {text start end line pos mod} {
set cmd [Lindex $line 0]
regsub -all {^.*::} $cmd "" cmd
switch -- $pos {
1 {
switch -- $cmd {
reset -
wait -
data -
status -
code -
size -
cleanup {
return [DisplayHints <token>]
}
}
}
}
return ""
}

# --- END OF HTTP PACKAGE ---

proc complete(if) {text start end line pos mod} {
# we don't offer the completion `then':
# it's optional, more difficult to parse
# and who uses it anyway?
#
switch -- $pos {
1 -
2 {
return [BraceOrCommand $text $start $end $line $pos $mod]
}
default {
set prev [PreviousWord ${start} ${line}]
switch -- $prev {
then -
else -
elseif {
return [BraceOrCommand \
$text $start $end $line $pos $mod]
}
default {
if {-1 == [lsearch [ProperList $line] else]} {
return [CompleteFromList $text {else elseif}]
}
}
}
}
}
return ""
}

proc complete(incr) {text start end line pos mod} {
switch -- $pos {
1 {
set matches [uplevel [info level] info vars ${mod}*]
set integers ""
# check for integers
#
foreach match $matches {
if {[uplevel [info level] array exists $match]} {
continue
}
if {[regexp {^[0-9]+$} [uplevel [info level] set $match]]} {
lappend integers $match
}
}
return [CompleteFromList ${text} ${integers}]
}
2 { return [DisplayHints ?increment?] }
}
return ""
}

proc complete(info) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
set cmds {
args body cmdcount commands complete default exists
globals hostname level library loaded locals nameofexecutable
patchlevel procs script sharedlibextension tclversion vars}
return [CompleteFromList $text $cmds]
}
2 {
switch -- $cmd {
args -
body -
default -
procs { return [complete(proc) ${text} 0 0 ${line} 1 ${mod}] }
complete { return [DisplayHints <command>] }
level { return [DisplayHints ?number?] }
loaded { return [DisplayHints ?interp?] }
commands -
exists -
globals -
locals -
vars {
if {"exists" == $cmd} {
set do vars
} else {
set do $cmd
}
# puts stderr [list complete(info) level = [info level]]
return \
[CompleteFromList ${text} [uplevel [info level] info ${do}]]
}
}
}
3 {
switch -- $cmd {
default {
set proc [Lindex $line 2]
return [CompleteFromList ${text} \
[uplevel [info level] info args $proc]]
}
default {}
}
}
4 {
switch -- $cmd {
default {
return [VarCompletion ${text}]
}
default {}
}
}
}
return ""
}

proc complete(interp) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
set cmds {
alias aliases create delete eval exists expose hide hidden
invokehidden issafe marktrusted share slaves target transfer}
return [TryFromList $text $cmds]
}
2 {
switch -- $cmd {

create {
set cmds [RemoveUsedOptions ${line} {-save --} {--}]
if {[llength $cmds]} {
return [CompleteFromList $text "$cmds ?path?"]
} else {
return [DisplayHints ?path?]
}
}

eval -
exists -
expose -
hide -
hidden -
invokehidden -
marktrusted -
target { return [CompleteFromList ${text} [interp slaves]] }

aliases -
delete -
issafe -
slaves { return [CompleteFromList ${text} [interp slaves]] }

alias -
share -
transfer { return [DisplayHints <srcPath>] }
}
}
3 {
switch -- $cmd {

alias { return [DisplayHints <srcCmd>] }

create {
set cmds [RemoveUsedOptions ${line} {-save --} {--}]
if {[llength $cmds]} {
return [CompleteFromList $text "$cmds ?path?"]
} else {
return [DisplayHints ?path?]
}
}

eval { return [DisplayHints <arg>] }
delete { return [CompleteFromList ${text} [interp slaves]] }

expose { return [DisplayHints <hiddenName>] }
hide { return [DisplayHints <exposedCmdName>] }

invokehidden {
return \
[CompleteFromList $text {?-global? <hiddenCmdName>}]
}

target { return [DisplayHints <alias>] }

exists {}
hidden {}
marktrusted {}
aliases {}
issafe {}
slaves {}

share -
transfer {return [ChannelId ${text}]}
}
}
4 {
switch -- $cmd {

alias { return [DisplayHints <targetPath>] }
eval { return [DisplayHints ?arg?] }

invokehidden {
return [CompleteFromList $text {<hiddenCmdName> ?arg?}]
}

create {
set cmds [RemoveUsedOptions ${line} {-save --} {--}]
if {[llength $cmds]} {
return [CompleteFromList $text "$cmds ?path?"]
} else {
return [DisplayHints ?path?]
}
}

expose { return [DisplayHints ?exposedCmdName?] }
hide { return [DisplayHints ?hiddenCmdName?] }

share -
transfer { return [CompleteFromList ${text} [interp slaves]] }
}
}
5 {
switch -- $cmd {

alias { return [DisplayHints <targetCmd>] }
invokehidden -
eval { return [DisplayHints ?arg?] }

expose { return [DisplayHints ?exposedCmdName?] }
hide { return [DisplayHints ?hiddenCmdName?] }

share -
transfer { return [CompleteFromList ${text} [interp slaves]] }
}
}
}
return ""
}

proc complete(join) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <list>] }
2 { return [DisplayHints ?joinString?] }
}
return ""
}

proc complete(lappend) {text start end line pos mod} {
switch -- $pos {
1 { return [VarCompletion ${text}] }
default { return [TryFromList ${text} ?value?] }
}
return ""
}

# the following routines are described in the
# `library' man page.
# --- LIBRARY ---

proc complete(auto_execok) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <cmd>] }
}
return ""
}

proc complete(auto_load) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <cmd>] }
}
return ""
}

proc complete(auto_mkindex) {text start end line pos mod} {
switch -- $pos {
1 { return "" }
default { return [DisplayHints ?pattern?] }
}
return ""
}

# proc complete(auto_reset) {text start end line pos mod} {
# }

proc complete(tcl_findLibrary) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <basename>] }
2 { return [DisplayHints <version>] }
3 { return [DisplayHints <patch>] }
4 { return [DisplayHints <initScript>] }
5 { return [DisplayHints <enVarName>] }
6 { return [DisplayHints <varName>] }
}
return ""
}

proc complete(parray) {text start end line pos mod} {
switch -- $pos {
1 {
set vars [uplevel [info level] info vars]
foreach var ${vars} {
if {[uplevel [info level] array exists ${var}]} {
lappend matches ${var}
}
}
return [CompleteFromList $text $matches]
}
}
return ""
}

proc complete(tcl_endOfWord) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <str>] }
2 { return [DisplayHints <start>] }
}
return ""
}

proc complete(tcl_startOfNextWord) {text start end line pos mod} {
return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
}

proc complete(tcl_startOfPreviousWord) {text start end line pos mod} {
return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
}

proc complete(tcl_wordBreakAfter) {text start end line pos mod} {
return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
}

proc complete(tcl_wordBreakBefore) {text start end line pos mod} {
return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
}

# --- END OF `LIBRARY' ---

proc complete(lindex) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <list>] }
2 { return [DisplayHints <index>] }
}
return ""
}

proc complete(linsert) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <list>] }
2 { return [DisplayHints <index>] }
3 { return [DisplayHints <element>] }
default { return [DisplayHints ?element?] }
}
return ""
}

proc complete(list) {text start end line pos mod} {
return [DisplayHints ?arg?]
}

proc complete(llength) {text start end line pos mod} {
switch -- $pos {
1 {
return [DisplayHints <list>]
}
}
return ""
}

proc complete(load) {text start end line pos mod} {
switch -- $pos {
1 {
return ""; # filename
}
2 {
if {![llength ${mod}]} {
return [DisplayHints ?packageName?]
}
}
3 {
if {![llength ${mod}]} {
return [DisplayHints ?interp?]
}
}
}
return ""
}

proc complete(lrange) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <list>] }
2 { return [DisplayHints <first>] }
3 { return [DisplayHints <last>] }
}
return ""
}

proc complete(lreplace) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <list>] }
2 { return [DisplayHints <first>] }
3 { return [DisplayHints <last>] }
default { return [DisplayHints ?element?] }
}
return ""
}

proc complete(lsearch) {text start end line pos mod} {
set options {-exact -glob -regexp}
switch -- $pos {
1 {
return [CompleteFromList ${text} "$options <list>"]
}
2 -
3 -
4 {
set sub [Lindex $line 1]
if {-1 != [lsearch $options $sub]} {
incr pos -1
}
switch -- $pos {
1 { return [DisplayHints <list>] }
2 { return [DisplayHints <pattern>] }
}
}
}
return ""
}

proc complete(lsort) {text start end line pos mod} {
set options [RemoveUsedOptions ${line} {
-ascii -dictionary -integer -real -command
-increasing -decreasing -index <list>
}]
switch -- $pos {
1 { return [CompleteFromList ${text} ${options}] }
default {
switch -- [PreviousWord ${start} ${line}] {
-command {
return [CompleteFromList $text [CommandCompletion $text]]
}
-index { return [DisplayHints <index>] }
default { return [CompleteFromList ${text} ${options}] }
}
}
}
return ""
}

# --- MSGCAT PACKAGE ---

# create a msgcat namespace inside
# tclreadline and import some commands.
#
namespace eval msgcat {
catch {namespace import ::tclreadline::DisplayHints}
}

proc msgcat::complete(mc) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <src-string>] }
}
return ""
}

proc msgcat::complete(mclocale) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints ?newLocale?] }
}
return ""
}

# proc msgcat::complete(mcpreferences) {text start end line pos mod} {
# }

proc msgcat::complete(mcload) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <dirname>] }
}
return ""
}

proc msgcat::complete(mcset) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <locale>] }
2 { return [DisplayHints <src-string>] }
3 { return [DisplayHints ?translate-string?] }
}
return ""
}

proc msgcat::complete(mcunknown) {text start end line pos mod} {
switch -- $pos {
1 { return [DisplayHints <locale>] }
2 { return [DisplayHints <src-string>] }
}
return ""
}

# --- END OF MSGCAT PACKAGE ---

# TODO import ! -force
proc complete(namespace) {text start end line pos mod} {
# TODO dosn't work ???
set space_matches [namespace children :: [string trim ${mod}*]]
# puts \nspace_matches=|${space_matches}|
set cmd [Lindex $line 1]
switch -- $pos {
1 {
set cmds {
children code current delete eval export forget
import inscope origin parent qualifiers tail which}
return [TryFromList $text $cmds]
}
2 {
switch -- $cmd {
children -
delete -
eval -
inscope -
forget -
parent -
qualifiers -
tail {
regsub {^([^:])} ${mod} {::\1} mod; # full qual. name
return [TryFromList ${mod} $space_matches]
}
code { return [DisplayHints <script> ] }
current {}
export { return [CompleteFromList ${text} {-clear ?pattern?}] }
import {
if {"-" != [string index ${mod} 0]} {
regsub {^([^:])} ${mod} {::\1} mod; # full qual. name
}
return [CompleteFromList ${mod} "-force $space_matches"]
}
origin { return [DisplayHints <command>] }
# qualifiers -
# tail { return [DisplayHints <string>] }
which { return [CompleteFromList ${mod} {
-command -variable <name>}] }
}
}
3 {
switch -- $cmd {
children -
export -
forget -
import { return [DisplayHints ?pattern?] }
delete { return [TryFromList ${mod} $space_matches] }
eval -
inscope {
return [BraceOrCommand \
$text $start $end $line $pos $mod]
}
which { return [CompleteFromList ${mod} {-variable <name>}] }
}
}
4 {
switch -- $cmd {
export -
forget -
import { return [DisplayHints ?pattern?] }
delete { return [TryFromList ${mod} $space_matches] }
eval -
inscope { return [DisplayHints ?arg?] }
which { return [CompleteFromList ${mod} {<name>}] }
}
}
}
return ""
}

proc complete(open) {text start end line pos mod} {
# 2 { return [DisplayHints ?access?] }
switch -- $pos {
2 {
set access {r r+ w w+ a a+
RDONLY WRONLY RDWR APPEND CREAT EXCL NOCTTY NONBLOCK TRUNC}
return [CompleteFromList ${text} ${access}]
}
3 { return [DisplayHints ?permissions?] }
}
return ""
}

proc complete(package) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
set cmds {
forget ifneeded names present provide require
unknown vcompare versions vsatisfies}
return [TryFromList $text $cmds]
}
2 {
switch -- ${cmd} {
forget -
ifneeded -
provide -
versions { return [CompleteFromList ${mod} [package names]] }
present -
require {
return [CompleteFromList ${mod} "-exact [package names]"] }
names {}
unknown { return [DisplayHints ?command?] }
vcompare -
vsatisfies { return [DisplayHints <version1>] }
}
}
3 {
set versions ""
catch [list set versions [package versions [Lindex ${line} 2]]]
switch -- ${cmd} {
forget {}
ifneeded {
if {"" != $versions} {
return [CompleteFromList ${text} ${versions}]
} else {
return [DisplayHints <version>]
}
}
provide {
if {"" != ${versions}} {
return [CompleteFromList ${text} ${versions}]
} else {
return [DisplayHints ?version?]
}
}
versions {}
present -
require {
if {"-exact" == [PreviousWord ${start} ${line}]} {
return [CompleteFromList ${mod} [package names]]
} else {
if {"" != ${versions}} {
return [CompleteFromList ${text} ${versions}]
} else {
return [DisplayHints ?version?]
}
}
}
names {}
unknown {}
vcompare -
vsatisfies { return [DisplayHints <version2>] }
}
}
}
return ""
}

proc complete(pid) {text start end line pos mod} {
switch -- ${pos} {
1 { return [ChannelId ${text}] }
}
}

proc complete(pkg_mkIndex) {text start end line pos mod} {
set cmds [RemoveUsedOptions ${line} {-direct -load -verbose -- <dir>} {--}]
set res [string trim [TryFromList ${text} ${cmds}]]
set prev [PreviousWord ${start} ${line}]
if {"-load" == ${prev}} {
return [DisplayHints <pkgPat>]
} elseif {"--" == ${prev}} {
return [TryFromList ${text} <dir>]
}
return ${res}
}

proc complete(proc) {text start end line pos mod} {
switch -- ${pos} {
1 {
set known_procs [ProcsOnlyCompletion ${text}]
return [CompleteFromList ${text} ${known_procs}]
}
2 {
set proc [Lindex ${line} 1]
if {[catch {set args [uplevel [info level] info args ${proc}]}]} {
return [DisplayHints <args>]
} else {
return [list "\{${args}\}"]
}
}
3 {
if {![string length [Lindex ${line} ${pos}]]} {
return [list \{ {}]; # \}
} else {
# return [DisplayHints <body>]
return [BraceOrCommand \
${text} ${start} ${end} ${line} ${pos} ${mod}]
}
}
}
return ""
}

proc complete(puts) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
return [OutChannelId ${text} "-nonewline"]
}
2 {
switch -- $cmd {
-nonewline { return [OutChannelId ${text}] }
default { return [DisplayHints <string>] }
}
}
3 {
switch -- $cmd {
-nonewline { return [DisplayHints <string>] }
}
}
}
return ""
}

# proc complete(pwd) {text start end line pos mod} {
# }

proc complete(read) {text start end line pos mod} {
set cmd [Lindex $line 1]
switch -- $pos {
1 {
return [InChannelId ${text} "-nonewline"]
}
2 {
switch -- $cmd {
-nonewline { return [InChannelId ${text}] }
default { return [DisplayHints <numChars>] }
}
}
}
return ""
}

proc complete(regexp) {text start end line pos mod} {
set prev [PreviousWord ${start} ${line}]
if {[llength ${prev}] && "--" != $prev && \
("-" == [string index ${prev} 0] || 1 == $pos)} {
set cmds [RemoveUsedOptions ${line} {
-nocase -indices -expanded -line
-linestop -lineanchor -about <expression> --} {--}]
if {[llength ${cmds}]} {
return [string trim [CompleteFromList ${text} ${cmds}]]
}
} else {
set virtual_pos [expr ${pos} - [FirstNonOption ${line}]]
switch -- ${virtual_pos} {
0 { return [DisplayHints <string>] }
1 { return [DisplayHints ?matchVar?] }
default { return [DisplayHints ?subMatchVar?] }
}
}
return ""
}

# proc complete(regexp) {text start end line pos mod} {
#     We're not on windoze here ...
# }

proc complete(regsub) {text start end line pos mod} {
set prev [PreviousWord ${start} ${line}]
if {[llength ${prev}] && "--" != $prev && \
("-" == [string index ${prev} 0] || 1 == ${pos})} {
set cmds [RemoveUsedOptions ${line} {
-all -nocase --} {--}]
if {[llength ${cmds}]} {
return [string trim [CompleteFromList ${text} ${cmds}]]
}
} else {
set virtual_pos [expr ${pos} - [FirstNonOption ${line}]]
switch -- ${virtual_pos} {
0 { return [DisplayHints <expression>] }
1 { return [DisplayHints <string>] }
2 { return [DisplayHints <subSpec>] }
3 { return [DisplayHints <varName>] }
}
}
return ""
}

proc complete(rename) {text start end line pos mod} {
switch -- $pos {
1 {
return [CompleteFromList ${text} [CommandCompletion ${text}]]
}
2 {
return [DisplayHints <newName>]
}
}
return ""
}

# proc complete(resource) {text start end line pos mod} {
#     This is not a mac ...
# }

proc complete(return) {text start end line pos mod} {
# TODO this is not perfect yet
set cmds {-code -errorinfo -errorcode ?string?}
set res [PreviousWord ${start} ${line}]
switch -- ${res} {
-errorinfo { return [DisplayHints <info>] }
-code -
-errorcode {
set codes {ok error return break continue}
return [TryFromList ${mod} ${codes}]
}
}
return [CompleteFromList ${text} [RemoveUsedOptions ${line} ${cmds}]]
}

# --- SAFE PACKAGE ---

# create a safe namespace inside
# tclreadline and import some commands.
#
namespace eval safe {
catch {
namespace import \
::tclreadline::DisplayHints ::tclreadline::PreviousWord \
::tclreadline::CompleteFromList ::tclreadline::CommandCompletion \
::tclreadline::RemoveUsedOptions ::tclreadline::HostList \
::tclreadline::ChannelId ::tclreadline::Lindex \
::tclreadline::CompleteBoolean \
::tclreadline::WidgetChildren
}
variable opts
set opts {
-accessPath -statics -noStatics -nested -nestedLoadOk -deleteHook
}
proc SlaveOrOpts {text start line pos slave} {
set prev [PreviousWord ${start} ${line}]
variable opts
if {$pos > 1} {
set slave ""
}
switch -- $prev {
-accessPath { return [DisplayHints <directoryList>] }
-statics { return [CompleteBoolean $text] }
-nested { return [CompleteBoolean $text] }
-deleteHook { return [DisplayHints <script>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} "${opts} $slave"]]
}
}
}
}

proc safe::complete(interpCreate) {text start end line pos mod} {
return [SlaveOrOpts ${text} ${start} ${line} ${pos} ?slave?]
}

proc safe::complete(interpInit) {text start end line pos mod} {
return [SlaveOrOpts ${text} ${start} ${line} ${pos} [interp slaves]]
}

proc safe::complete(interpConfigure) {text start end line pos mod} {
return [SlaveOrOpts $text $start $line $pos [interp slaves]]
}

proc safe::complete(interpDelete) {text start end line pos mod} {
return [CompleteFromList ${text} [interp slaves]]
}

proc safe::complete(interpAddToAccessPath) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} [interp slaves]] }
}
}

proc safe::complete(interpFindInAccessPath) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} [interp slaves]] }
}
}

proc safe::complete(setLogCmd) {text start end line pos mod} {
switch -- ${pos} {
1 { return [DisplayHints ?cmd?] }
default { return [DisplayHints ?arg?] }
}
}

proc safe::complete(loadTk) {text start end line pos mod} {
switch -- ${pos} {
1 { return [DisplayHints <slave>] }
default {
switch -- [PreviousWord ${start} ${line}] {
-use {
return [CompleteFromList ${text} \
[::tclreadline::WidgetChildren ${text}]]
}
-display {
return [DisplayHints <display>]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {-use -display}]]
}
}
}
}
}

# --- END OF SAFE PACKAGE ---

proc complete(scan) {text start end line pos mod} {
switch -- ${pos} {
1 { return [DisplayHints <string>] }
2 { return [DisplayHints <format>] }
default { return [VarCompletion ${text}] }
}
return ""
}

proc complete(seek) {text start end line pos mod} {
switch -- ${pos} {
1 { return [ChannelId ${text}] }
2 { return [DisplayHints <offset>] }
3 { return [TryFromList ${text} {start current end}] }
}
return ""
}

proc complete(set) {text start end line pos mod} {
switch -- ${pos} {
1 { return [VarCompletion ${text}] }
2 {
if {${text} == "" || ${text} == "\"" || ${text} == "\{"} {
# set line [QuoteQuotes $line]
if {[catch [list set value [list [uplevel [info level] \
set [Lindex ${line} 1]]]] msg]
} {
return ""
} else {
return [Quote ${value} ${text}]
}
}
}
}
return ""
}

proc complete(socket) {text start end line pos mod} {
set cmd [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
if {"-server" == ${cmd}} {
# server sockets
#
switch -- ${pos} {
2 { return [DisplayHints <command>] }
default {
if {"-myaddr" == ${prev}} {
return [DisplayHints <addr>]
} else {
return [CompleteFromList ${mod} \
[RemoveUsedOptions $line {-myaddr -error -sockname <port>}]]
}
}
}
} else {
# client sockets
#
switch -- ${prev} {
-myaddr { return [DisplayHints <addr>] }
-myport { return [DisplayHints <port>] }
}

set hosts [HostList]
set cmds {-myaddr -myport -async -myaddr -error -sockname -peername}
if {${pos} <= 1} {
lappend cmds -server
}
set cmds [RemoveUsedOptions ${line} ${cmds}]
if {-1 != [lsearch ${hosts} ${prev}]} {
return [DisplayHints <port>]
} else {
return [CompleteFromList ${mod} [concat ${cmds} ${hosts}]]
}
}
return ""
}

proc complete(source) {text start end line pos mod} {
# allow file name completion
return ""
}

proc complete(split) {text start end line pos mod} {
switch -- ${pos} {
1 { return [DisplayHints <string>] }
2 { return [DisplayHints ?splitChars?] }
}
}

proc complete(string) {text start end line pos mod} {
set cmd [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
set cmds {
bytelength compare equal first index is last length map match
range repeat replace tolower toupper totitle trim trimleft
trimright wordend wordstart}
switch -- ${pos} {
1 {
return [CompleteFromList ${text} ${cmds}]
}
2 {
switch -- ${cmd} {
compare -
equal {
return [CompleteFromList ${text} {
-nocase -length <string> }]
}

first -
last { return [DisplayHints <string1>] }

map { return [CompleteFromList ${text} {-nocase <charMap>]} }
match { return [CompleteFromList ${text} {-nocase <pattern>]} }

is {
return [CompleteFromList ${text} {
alnum alpha ascii boolean control digit double
false graph integer lower print punct space
true upper wordchar xdigit
}]
}

bytelength -
index -
length -
range -
repeat -
replace -
tolower -
totitle -
toupper -
trim -
trimleft -
trimright -
wordend -
wordstart { return [DisplayHints <string>] }
}
}
3 {
switch -- ${cmd} {
compare -
equal {
if {"-length" == ${prev}} {
return [DisplayHints <int>]
}
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {-nocase -length <string>}]]
}

first -
last { return [DisplayHints <string2>] }

map {
if {"-nocase" == ${prev}} {
return [DisplayHints <charMap>]
} else {
return [DisplayHints <string>]
}
}
match {
if {"-nocase" == ${prev}} {
return [DisplayHints <pattern>]
} else {
return [DisplayHints <string>]
}
}

is {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {-strict -failindex <string>}]]
}

bytelength {}
index -
wordend -
wordstart { return [DisplayHints <charIndex>] }
range -
replace { return [DisplayHints <first>] }
repeat { return [DisplayHints <count>] }
tolower -
totitle -
toupper { return [DisplayHints ?first?] }
trim -
trimleft -
trimright { return [DisplayHints ?chars?] }
}
}
4 {
switch -- ${cmd} {
compare -
equal {
if {"-length" == ${prev}} {
return [DisplayHints <int>]
}
return [CompleteFromList ${text} \
[RemoveUsedOptions $line {-nocase -length <string>}]]
}

first -
last { return [DisplayHints ?startIndex?] }

map -
match { return [DisplayHints <string>] }

is {
if {"-failindex" == ${prev}} {
return [VarCompletion ${text}]
}
return [CompleteFromList ${text} \
[RemoveUsedOptions $line {-strict -failindex <string>}]]
}

bytelength {}
index {}
length {}
range -
replace { return [DisplayHints <last>] }
repeat {}
tolower -
totitle -
toupper { return [DisplayHints ?last?] }
trim -
trimleft -
trimright {}
wordend -
wordstart {}
}
}
default {
switch -- ${cmd} {
compare -
equal {
if {"-length" == ${prev}} {
return [DisplayHints <int>]
}
return [CompleteFromList ${text} \
[RemoveUsedOptions $line {-nocase -length <string>}]]
}

is {
if {"-failindex" == ${prev}} {
return [VarCompletion ${text}]
}
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {-strict -failindex <string>}]]
}

replace { return [DisplayHints ?newString?] }
}
}
}
return ""
}

proc complete(subst) {text start end line pos mod} {
return [CompleteFromList ${text} [RemoveUsedOptions ${line} {
-nobackslashes -nocommands -novariables <string>}]]
}

proc complete(switch) {text start end line pos mod} {
set prev [PreviousWord ${start} ${line}]
if {[llength ${prev}] && "--" != ${prev} && \
("-" == [string index ${prev} 0] || 1 == ${pos})} {
set cmds [RemoveUsedOptions ${line} {
-exact -glob -regexp --} {--}]
if {[llength ${cmds}]} {
return [string trim [CompleteFromList ${text} ${cmds}]]
}
} else {
set virtual_pos [expr ${pos} - [FirstNonOption ${line}]]
switch -- ${virtual_pos} {
0 { return [DisplayHints <string>] }
1 { return [DisplayHints <pattern>] }
2 { return [DisplayHints <body>] }
default {
switch [expr ${virtual_pos} % 2] {
0 { return [DisplayHints ?body?] }
1 { return [DisplayHints ?pattern?] }
}
}
}
}
return ""
}

# --- TCLREADLINE PACKAGE ---

# create a tclreadline namespace inside
# tclreadline and import some commands.
#
namespace eval tclreadline {
catch {
namespace import \
::tclreadline::DisplayHints \
::tclreadline::CompleteFromList \
::tclreadline::Lindex \
::tclreadline::CompleteBoolean
}
}

proc tclreadline::complete(readline) {text start end line pos mod} {
set cmd [Lindex ${line} 1]
switch -- ${pos} {
1 { return [CompleteFromList ${text} {
read initialize write add complete customcompleter
builtincompleter eofchar reset-terminal bell}]
}
2 {
switch -- ${cmd} {
read {}
initialize {}
write {}
add { return [DisplayHints <completerLine>] }
completer { return [DisplayHints <line>] }
customcompleter { return [DisplayHints ?scriptCompleter?] }
builtincompleter { return [CompleteBoolean ${text}] }
eofchar { return [DisplayHints ?script?] }
reset-terminal {
if {[info exists ::env(TERM)]} {
return [CompleteFromList ${text} $::env(TERM)]
} else {
return [DisplayHints ?terminalName?]
}
}
}
}
}
return ""
}

# --- END OF TCLREADLINE PACKAGE ---

proc complete(tell) {text start end line pos mod} {
switch -- ${pos} {
1 { return [ChannelId ${text}] }
}
return ""
}

proc complete(testthread) {text start end line pos mod} {

set cmd [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} {
-async create errorproc exit id names send wait
}]
}
2 {
switch -- [PreviousWord ${start} ${line}] {
create {
return [BraceOrCommand \
${text} ${start} ${end} ${line} ${pos} ${mod}]
}
-async {
return [CompleteFromList ${text} send]
}
send {
return [CompleteFromList ${text} [testthread names]]
}
default {}
}
}
3 {
if {"send" == [PreviousWord ${start} ${line}]} {
return [CompleteFromList ${text} [testthread names]]
} elseif {"send" == ${cmd}} {
return [BraceOrCommand \
${text} ${start} ${end} ${line} ${pos} ${mod}]
}
}
4 {
if {"send" == [Lindex ${line} 2]} {
return [BraceOrCommand \
${text} ${start} ${end} ${line} ${pos} ${mod}]
}
}
}
return ""
}

proc complete(time) {text start end line pos mod} {
switch -- ${pos} {
1 { return [BraceOrCommand \
${text} ${start} ${end} ${line} ${pos} ${mod}]
}
2 { return [DisplayHints ?count?] }
}
return ""
}

proc complete(trace) {text start end line pos mod} {
set cmd [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [CompleteFromList ${mod} {variable vdelete vinfo}]
}
2 {
return [CompleteFromList ${text} \
[uplevel [info level] info vars "${mod}*"]]
}
3 {
switch -- ${cmd} {
variable -
variable { return [CompleteFromList ${text} {r w u}] }
vdelete {
set var [PreviousWord ${start} ${line}]
set modes ""
foreach info [uplevel [info level] trace vinfo ${var}] {
lappend modes [lindex ${info} 0]
}
return [CompleteFromList ${text} ${modes}]
}
}
}
4 {
switch -- ${cmd} {
variable {
return [CompleteFromList ${text} \
[CommandCompletion ${text}]]
}
vdelete {
set var [Lindex ${line} 2]
set mode [PreviousWord ${start} ${line}]
set scripts ""
foreach info [uplevel [info level] trace vinfo ${var}] {
if {${mode} == [lindex ${info} 0]} {
lappend scripts [list [lindex ${info} 1]]
}
}
return [DisplayHints ${scripts}]
}
}
}
}
return ""
}

proc complete(unknown) {text start end line pos mod} {
switch -- ${pos} {
1 {
return [CompleteFromList ${text} [CommandCompletion ${text}]]
}
default { return [DisplayHints ?arg?] }
}
return ""
}

proc complete(unset) {text start end line pos mod} {
return [VarCompletion ${text}]
}

proc complete(update) {text start end line pos mod} {
switch -- ${pos} {
1 { return idletasks }
}
return ""
}

proc complete(uplevel) {text start end line pos mod} {
set one [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [CompleteFromList \
${text} "?level? [CommandCompletion ${text}]"]
}
2 {
if {"#" == [string index ${one} 0] || [regexp {^[0-9]*$} ${one}]} {
return [CompleteFromList ${text} [CommandCompletion ${text}]]
} else {
return [DisplayHints ?arg?]
}
}
default { return [DisplayHints ?arg?] }
}
return ""
}

proc complete(upvar) {text start end line pos mod} {
set one [Lindex ${line} 1]
switch -- $pos {
1 {
return [DisplayHints {?level? <otherVar>}]
}
2 {
if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
return [DisplayHints <otherVar>]
} else {
return [DisplayHints <myVar>]
}
}
3 {
if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
return [DisplayHints <myVar>]
} else {
return [DisplayHints ?otherVar?]
}
}
default {
set virtual_pos $pos
if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
incr virtual_pos
}
switch [expr $virtual_pos % 2] {
0 { return [DisplayHints ?myVar?] }
1 { return [DisplayHints ?otherVar?] }
}
}
}
return ""
}

proc complete(variable) {text start end line pos mod} {
set modulo [expr $pos % 2]
switch -- $modulo {
1 { return [VarCompletion ${text}] }
0 {
if {$text == "" || $text == "\"" || $text == "\{"} {
set line [QuoteQuotes $line]
if {[catch [list set value [list [uplevel [info level] \
set [PreviousWord $start $line]]]] msg]
} {
return ""
} else {
return [Quote $value ${text}]
}
}
}
}
return ""
}

proc complete(vwait) {text start end line pos mod} {
switch -- $pos {
1 { return [VarCompletion ${mod}] }
}
return ""
}

proc complete(while) {text start end line pos mod} {
switch -- $pos {
1 -
2 {
return [BraceOrCommand $text $start $end $line $pos $mod]
}
}
return ""
}

# -------------------------------------
#                  TK
# -------------------------------------

# GENERIC WIDGET CONFIGURATION

proc WidgetChildren {{pattern .}} {
regsub {^([^\.])} ${pattern} {\.\1} pattern
if {![string length ${pattern}]} {
set pattern .
}
if {[winfo exists ${pattern}]} {
return [concat ${pattern} [winfo children ${pattern}]]
} else {
regsub {.[^.]*$} $pattern {.} pattern
if {[winfo exists ${pattern}]} {
return [concat ${pattern} [winfo children ${pattern}]]
} else {
return ""
}
}
}

proc WidgetDescendants {{pattern .}} {
set tree [WidgetChildren ${pattern}]
foreach widget $tree {
append tree " [WidgetDescendants $widget]"
}
return $tree
}

proc ToplevelWindows {} {
set children [WidgetChildren ""]
set toplevels ""
foreach widget $children {
set toplevel [winfo toplevel $widget]
if {-1 == [lsearch $toplevels $toplevel]} {
lappend toplevels $toplevel
}
}
return $toplevels
}

# TODO
# write a dispatcher here, which gets the widget class name
# and calls specific completers.
#
# proc complete(WIDGET_COMMAND) {text start end line pos mod} {
# 	return [CompleteFromOptionsOrSubCmds ${text} ${start} ${end} ${line} ${pos}]
# }

proc EventuallyInsertLeadingDot {text fallback} {
if {![string length ${text}]} {
return [list . {}]
} else {
return [DisplayHints ${fallback}]
}
}

# TODO
proc CompleteColor {text {add ""}} {

# we set the variable only once to speed up.
#
variable colors
variable numberless_colors

if ![info exists colors] {
# from .. X11R6/lib/X11/rgb.txt
#
set colors {
snow GhostWhite WhiteSmoke gainsboro FloralWhite OldLace linen
AntiqueWhite PapayaWhip BlanchedAlmond bisque PeachPuff NavajoWhite
moccasin cornsilk ivory LemonChiffon seashell honeydew MintCream
azure AliceBlue lavender LavenderBlush MistyRose white black
DarkSlateGray DarkSlateGrey DimGray DimGrey SlateGray SlateGrey
LightSlateGray LightSlateGrey gray grey LightGrey LightGray
MidnightBlue navy NavyBlue CornflowerBlue DarkSlateBlue SlateBlue
MediumSlateBlue LightSlateBlue MediumBlue RoyalBlue blue DodgerBlue
DeepSkyBlue SkyBlue LightSkyBlue SteelBlue LightSteelBlue LightBlue
PowderBlue PaleTurquoise DarkTurquoise MediumTurquoise turquoise
cyan LightCyan CadetBlue MediumAquamarine aquamarine DarkGreen
DarkOliveGreen DarkSeaGreen SeaGreen MediumSeaGreen LightSeaGreen
PaleGreen SpringGreen LawnGreen green chartreuse MediumSpringGreen
GreenYellow LimeGreen YellowGreen ForestGreen OliveDrab DarkKhaki
khaki PaleGoldenrod LightGoldenrodYellow LightYellow yellow
gold LightGoldenrod goldenrod DarkGoldenrod RosyBrown IndianRed
SaddleBrown sienna peru burlywood beige wheat SandyBrown tan
chocolate firebrick brown DarkSalmon salmon LightSalmon orange
DarkOrange coral LightCoral tomato OrangeRed red HotPink DeepPink
pink LightPink PaleVioletRed maroon MediumVioletRed VioletRed
magenta violet plum orchid MediumOrchid DarkOrchid DarkViolet
BlueViolet purple MediumPurple thistle snow1 snow2 snow3 snow4
seashell1 seashell2 seashell3 seashell4 AntiqueWhite1 AntiqueWhite2
AntiqueWhite3 AntiqueWhite4 bisque1 bisque2 bisque3 bisque4
PeachPuff1 PeachPuff2 PeachPuff3 PeachPuff4 NavajoWhite1
NavajoWhite2 NavajoWhite3 NavajoWhite4 LemonChiffon1 LemonChiffon2
LemonChiffon3 LemonChiffon4 cornsilk1 cornsilk2 cornsilk3 cornsilk4
ivory1 ivory2 ivory3 ivory4 honeydew1 honeydew2 honeydew3 honeydew4
LavenderBlush1 LavenderBlush2 LavenderBlush3 LavenderBlush4
MistyRose1 MistyRose2 MistyRose3 MistyRose4 azure1 azure2 azure3
azure4 SlateBlue1 SlateBlue2 SlateBlue3 SlateBlue4 RoyalBlue1
RoyalBlue2 RoyalBlue3 RoyalBlue4 blue1 blue2 blue3 blue4
DodgerBlue1 DodgerBlue2 DodgerBlue3 DodgerBlue4 SteelBlue1
SteelBlue2 SteelBlue3 SteelBlue4 DeepSkyBlue1 DeepSkyBlue2
DeepSkyBlue3 DeepSkyBlue4 SkyBlue1 SkyBlue2 SkyBlue3 SkyBlue4
LightSkyBlue1 LightSkyBlue2 LightSkyBlue3 LightSkyBlue4 SlateGray1
SlateGray2 SlateGray3 SlateGray4 LightSteelBlue1 LightSteelBlue2
LightSteelBlue3 LightSteelBlue4 LightBlue1 LightBlue2 LightBlue3
LightBlue4 LightCyan1 LightCyan2 LightCyan3 LightCyan4
PaleTurquoise1 PaleTurquoise2 PaleTurquoise3 PaleTurquoise4
CadetBlue1 CadetBlue2 CadetBlue3 CadetBlue4 turquoise1
turquoise2 turquoise3 turquoise4 cyan1 cyan2 cyan3 cyan4
DarkSlateGray1 DarkSlateGray2 DarkSlateGray3 DarkSlateGray4
aquamarine1 aquamarine2 aquamarine3 aquamarine4 DarkSeaGreen1
DarkSeaGreen2 DarkSeaGreen3 DarkSeaGreen4 SeaGreen1 SeaGreen2
SeaGreen3 SeaGreen4 PaleGreen1 PaleGreen2 PaleGreen3 PaleGreen4
SpringGreen1 SpringGreen2 SpringGreen3 SpringGreen4 green1 green2
green3 green4 chartreuse1 chartreuse2 chartreuse3 chartreuse4
OliveDrab1 OliveDrab2 OliveDrab3 OliveDrab4 DarkOliveGreen1
DarkOliveGreen2 DarkOliveGreen3 DarkOliveGreen4 khaki1 khaki2
khaki3 khaki4 LightGoldenrod1 LightGoldenrod2 LightGoldenrod3
LightGoldenrod4 LightYellow1 LightYellow2 LightYellow3 LightYellow4
yellow1 yellow2 yellow3 yellow4 gold1 gold2 gold3 gold4 goldenrod1
goldenrod2 goldenrod3 goldenrod4 DarkGoldenrod1 DarkGoldenrod2
DarkGoldenrod3 DarkGoldenrod4 RosyBrown1 RosyBrown2 RosyBrown3
RosyBrown4 IndianRed1 IndianRed2 IndianRed3 IndianRed4 sienna1
sienna2 sienna3 sienna4 burlywood1 burlywood2 burlywood3 burlywood4
wheat1 wheat2 wheat3 wheat4 tan1 tan2 tan3 tan4 chocolate1
chocolate2 chocolate3 chocolate4 firebrick1 firebrick2 firebrick3
firebrick4 brown1 brown2 brown3 brown4 salmon1 salmon2 salmon3
salmon4 LightSalmon1 LightSalmon2 LightSalmon3 LightSalmon4 orange1
orange2 orange3 orange4 DarkOrange1 DarkOrange2 DarkOrange3
DarkOrange4 coral1 coral2 coral3 coral4 tomato1 tomato2 tomato3
tomato4 OrangeRed1 OrangeRed2 OrangeRed3 OrangeRed4 red1 red2
red3 red4 DeepPink1 DeepPink2 DeepPink3 DeepPink4 HotPink1
HotPink2 HotPink3 HotPink4 pink1 pink2 pink3 pink4 LightPink1
LightPink2 LightPink3 LightPink4 PaleVioletRed1 PaleVioletRed2
PaleVioletRed3 PaleVioletRed4 maroon1 maroon2 maroon3 maroon4
VioletRed1 VioletRed2 VioletRed3 VioletRed4 magenta1 magenta2
magenta3 magenta4 orchid1 orchid2 orchid3 orchid4 plum1 plum2
plum3 plum4 MediumOrchid1 MediumOrchid2 MediumOrchid3
MediumOrchid4 DarkOrchid1 DarkOrchid2 DarkOrchid3 DarkOrchid4
purple1 purple2 purple3 purple4 MediumPurple1 MediumPurple2
MediumPurple3 MediumPurple4 thistle1 thistle2 thistle3 thistle4
gray0 grey0 gray1 grey1 gray2 grey2 gray3 grey3 gray4 grey4 gray5
grey5 gray6 grey6 gray7 grey7 gray8 grey8 gray9 grey9 gray10 grey10
gray11 grey11 gray12 grey12 gray13 grey13 gray14 grey14 gray15
grey15 gray16 grey16 gray17 grey17 gray18 grey18 gray19 grey19
gray20 grey20 gray21 grey21 gray22 grey22 gray23 grey23 gray24
grey24 gray25 grey25 gray26 grey26 gray27 grey27 gray28 grey28
gray29 grey29 gray30 grey30 gray31 grey31 gray32 grey32 gray33
grey33 gray34 grey34 gray35 grey35 gray36 grey36 gray37 grey37
gray38 grey38 gray39 grey39 gray40 grey40 gray41 grey41 gray42
grey42 gray43 grey43 gray44 grey44 gray45 grey45 gray46 grey46
gray47 grey47 gray48 grey48 gray49 grey49 gray50 grey50 gray51
grey51 gray52 grey52 gray53 grey53 gray54 grey54 gray55 grey55
gray56 grey56 gray57 grey57 gray58 grey58 gray59 grey59 gray60
grey60 gray61 grey61 gray62 grey62 gray63 grey63 gray64 grey64
gray65 grey65 gray66 grey66 gray67 grey67 gray68 grey68 gray69
grey69 gray70 grey70 gray71 grey71 gray72 grey72 gray73 grey73
gray74 grey74 gray75 grey75 gray76 grey76 gray77 grey77 gray78
grey78 gray79 grey79 gray80 grey80 gray81 grey81 gray82 grey82
gray83 grey83 gray84 grey84 gray85 grey85 gray86 grey86 gray87
grey87 gray88 grey88 gray89 grey89 gray90 grey90 gray91 grey91
gray92 grey92 gray93 grey93 gray94 grey94 gray95 grey95 gray96
grey96 gray97 grey97 gray98 grey98 gray99 grey99 gray100 grey100
DarkGrey DarkGray DarkBlue DarkCyan DarkMagenta DarkRed LightGreen
}
}
if ![info exists numberless_colors] {
set numberless_colors ""
foreach color ${colors} {
regsub -all {[0-9]*} ${color} "" color
lappend numberless_colors ${color}
}
set numberless_colors [Lunique [lsort ${numberless_colors}]]
}
set matches [MatchesFromList ${text} ${numberless_colors}]
if {[llength ${matches}] < 5} {
set matches [MatchesFromList ${text} ${colors}]
if {[llength ${matches}]} {
return [CompleteFromList ${text} [concat ${colors} ${add}]]
} else {
return [CompleteFromList ${text} \
[concat ${numberless_colors} ${add}]]
}
} else {
return [CompleteFromList ${text} [concat ${numberless_colors} ${add}]]
}
}

proc CompleteCursor text {
# from <X11/cursorfont.h>
#
return [CompleteFromList ${text} {
num_glyphs x_cursor arrow based_arrow_down based_arrow_up
boat bogosity bottom_left_corner bottom_right_corner
bottom_side bottom_tee box_spiral center_ptr circle clock
coffee_mug cross cross_reverse crosshair diamond_cross dot
dotbox double_arrow draft_large draft_small draped_box
exchange fleur gobbler gumby hand1 hand2 heart icon iron_cross
left_ptr left_side left_tee leftbutton ll_angle lr_angle
man middlebutton mouse pencil pirate plus question_arrow
right_ptr right_side right_tee rightbutton rtl_logo sailboat
sb_down_arrow sb_h_double_arrow sb_left_arrow sb_right_arrow
sb_up_arrow sb_v_double_arrow shuttle sizing spider spraycan
star target tcross top_left_arrow top_left_corner
top_right_corner top_side top_tee trek ul_angle umbrella
ur_angle watch xterm
}]
}

#**
# SpecificSwitchCompleter
# ---
# @param    text   -- the word to complete.
# @param    start  -- the char index of text's start in line
# @param    line   -- the line gathered so far.
# @param    switch -- the switch to complete for.
# @return   a std tclreadline formatted completer string.
# @sa       CompleteWidgetConfigurations
# @date     Sep-17-1999
#
proc SpecificSwitchCompleter {text start line switch {always 1}} {

switch -- ${switch} {

-activebackground -
-activeforeground -
-fg -
-foreground -
-bg -
-background -
-disabledforeground -
-highlightbackground -
-highlightcolor -
-insertbackground -
-troughcolor -
-selectbackground -
-selectforeground { return [CompleteColor ${text}] }

-activeborderwidth -
-bd -
-borderwidth -
-insertborderwidth -
-insertwidth -
-selectborderwidth -
-highlightthickness -
-padx -
-pady -
-wraplength {
if ${always} {
return [DisplayHints <pixels>]
} else {
return ""
}
}

-anchor {
return [CompleteFromList ${text} {
n ne e se s sw w nw center
}]
}


-bitmap { return [CompleteFromBitmaps ${text} ${always}] }


-cursor {
return [CompleteCursor ${text}]
# return [DisplayHints <cursor>]
}
-exportselection -
-jump -
-setgrid -
-takefocus { return [CompleteBoolean ${text}] }
-font {
set names [font names]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
if ${always} {
return [DisplayHints <font>]
} else {
return ""
}
}
}


-image -
-selectimage { return [CompleteFromImages ${text} ${always}] }
-selectmode {
return [CompleteFromList ${text} {
single browse multiple extended
}]
}

-insertofftime -
-insertontime -
-repeatdelay -
-repeatinterval {
if ${always} {
return [DisplayHints <milliSec>]
} else {
return ""
}
}
-justify {
return [CompleteFromList ${text} {
left center right
}]
}
-orient {
return [CompleteFromList ${text} {
vertical horizontal
}]
}
-relief {
return [CompleteFromList ${text} {
raised sunken flat ridge solid groove
}]
}

-text {
if ${always} {
return [DisplayHints <text>]
} else {
return ""
}
}
-textvariable { return [VarCompletion ${text} #0] }
-underline {
if ${always} {
return [DisplayHints <index>]
} else {
return ""
}
}

-xscrollcommand -
-yscrollcommand {
}

# WIDGET SPECIFIC OPTIONS
# ---

-state {
return [CompleteFromList ${text} {
normal active disabled
}]
}

-columnbreak -
-hidemargin -
-indicatoron {
return [CompleteBoolean ${text}]
}

-variable {
return [VarCompletion ${text} #0]
}

default {
# if ${always} {
#	set prev [PreviousWord ${start} ${line}]
#	return [DisplayHints <[String range ${prev} 1 end]>]
#} else {
return ""
#}
}
}
}
# return [BraceOrCommand ${text} \
# ${start}  ${line} ${pos} ${mod}]

#**
# CompleteWidgetConfigurations
# ---
# @param    text  -- the word to complete.
# @param    start -- the actual cursor position.
# @param    line  -- the line gathered so far.
# @param    lst   -- a list of possible completions.
# @return   a std tclreadline formatted completer string.
# @sa       SpecificSwitchCompleter
# @date     Sep-17-1999
#
proc CompleteWidgetConfigurations {text start line lst} {
set prev [PreviousWord ${start} ${line}]
if {"-" == [string index ${prev} 0]} {
return [SpecificSwitchCompleter ${text} ${start} ${line} ${prev}]
} else {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${lst}]]
}
}

# --------------------------------------
# === SPECIFIC TK COMMAND COMPLETERS ===
# --------------------------------------

proc complete(bell) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} -displayof] }
2 {
if {"-displayof" == [PreviousWord ${start} ${line}]} {
return [CompleteFromList ${text} [ToplevelWindows]]
}
}
}
}

proc CompleteSequence {text fulltext} {
set modifiers {
Alt Control Shift Lock Double Triple
B1 B2 B3 B4 B5 Button1 Button2 Button3 Button4 Button5
M M1 M2 M3 M4 M5
Meta Mod1 Mod2 Mod3 Mod4 Mod5
}
set events {
Activate Button ButtonPress ButtonRelease
Circulate Colormap Configure Deactivate Destroy
Enter Expose FocusIn FocusOut Gravity
Key KeyPress KeyRelease Leave Map Motion
MouseWheel Property Reparent Unmap Visibility
}
set sequence [concat ${modifiers} ${events}]
return [CompleteListFromList ${text} ${fulltext} ${sequence} < - >]
}

proc complete(bind) {text start end line pos mod} {
switch -- ${pos} {
1 {
set widgets [WidgetChildren ${text}]
set toplevels [ToplevelWindows]
if {[catch {set toplevelClass [winfo class .]}]} {
set toplevelClass ""
}
set rest {
Button Canvas Checkbutton Entry Frame Label
Listbox Menu Menubutton Message Radiobutton
Scale Scrollbar Text
all
}
return [CompleteFromList ${text} \
[concat ${toplevels} ${widgets} ${toplevelClass} $rest]]
}
2 {
return [CompleteSequence ${text} [Lindex ${line} 2]]
}
default {
# return [DisplayHints {<script> <+script>}]
return [BraceOrCommand ${text} \
${start} ${end} ${line} ${pos} ${mod}]
}
}
return ""
}

proc complete(bindtags) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} [WidgetChildren ${text}]] }
2 {
# set current_tags \
# [RemoveUsedOptions ${line} [bindtags [Lindex ${line} 1]]]
set current_tags [bindtags [Lindex ${line} 1]]
return [CompleteListFromList ${text} [Lindex ${line} 2] \
${current_tags} \{ { } \}]
}
}
return ""
}

proc complete(button) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground -activeforeground -anchor
-background -bitmap -borderwidth -cursor
-disabledforeground -font -foreground
-highlightbackground -highlightcolor
-highlightthickness -image -justify
-padx -pady -relief -takefocus -text
-textvariable -underline -wraplength
-command -default -height -state -width
}]
}
}
return ""
}

proc complete(canvas) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-background -borderwidth -cursor -highlightbackground
-highlightcolor -highlightthickness -insertbackground
-insertborderwidth -insertofftime -insertontime
-insertwidth -relief -selectbackground -selectborderwidth
-selectforeground -takefocus -xscrollcommand -yscrollcommand
-closeenough -confine -height -scrollregion -width
-xscrollincrement -yscrollincrement
}]
}
}
return ""
}

proc complete(checkbutton) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground activeBackground Foreground
-activeforeground -anchor -background -bitmap
-borderwidth -cursor -disabledforeground -font
-foreground -highlightbackground -highlightcolor
-highlightthickness -image -justify -padx -pady
-relief -takefocus -text -textvariable -underline
-wraplength -command -height -indicatoron -offvalue
-onvalue -selectcolor -selectimage -state -variable
-width
}]
}
}
return ""
}

proc complete(clipboard) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} {append clear}] }
default {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
switch -- ${sub} {
append {
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} [ToplevelWindows]]
}
-format { return [DisplayHints <format>] }
-type { return [DisplayHints <type>] }
default {
set opts [RemoveUsedOptions ${line} {
-displayof -format -type --
} {--}]
if {![string length ${opts}]} {
return [DisplayHints <data>]
} else {
return [CompleteFromList ${text} ${opts}]
}
}
}
}
clear {
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} [ToplevelWindows]]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-displayof
}]]
}
}
}
}
}
}
}

proc complete(destroy) {text start end line pos mod} {
set remaining [RemoveUsedOptions ${line} [WidgetChildren ${text}]]
return [CompleteFromList ${text} ${remaining}]
}

proc complete(entry) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-background -borderwidth -cursor -exportselection
-font -foreground -highlightbackground -highlightcolor
-highlightthickness -insertbackground -insertborderwidth
-insertofftime -insertontime -insertwidth -justify -relief
-selectbackground -selectborderwidth -selectforeground
-takefocus -textvariable -xscrollcommand -show -state
-width
}]
}
}
return ""
}

proc complete(event) {text start end line pos mod} {
set sub [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} { add delete generate info }]
}
2 {
switch -- ${sub} {
add { return [DisplayHints <<virtual>>] }
info -
delete {
return [CompleteFromList ${text} [event info] "<"]
}
generate {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
}
}
3 {
switch -- ${sub} {
add -
delete -
generate {
return [CompleteSequence ${text} [Lindex ${line} 3]]
}
info {}
}
}
default {
switch -- ${sub} {
add -
delete {
return [CompleteSequence ${text} [Lindex ${line} 3]]
}
info {}
generate {

switch -- [PreviousWord ${start} ${line}] {

-above -
-root -
-subwindow {
return [TryFromList ${text} \
[WidgetChildren ${text}]]
}

-borderwidth { return [DisplayHints <size>] }

-button -
-delta -
-keycode -
-serial -
-count { return [DisplayHints <number>] }

-detail {
return [CompleteFromList ${text} {
NotifyAncestor    NotifyNonlinearVirtual
NotifyDetailNone  NotifyPointer
NotifyInferior    NotifyPointerRoot
NotifyNonlinear   NotifyVirtual
}]
}

-focus -
-override -
-sendevent { return [CompleteBoolean ${text}] }

-height -
-width { return [DisplayHints <size>] }

-keysym { return [DisplayHints <name>] }

-mode {
return [CompleteFromList ${text} {
NotifyNormal NotifyGrab
NotifyUngrab NotifyWhileGrabbed
}]
}

-place {
return [CompleteFromList ${text} {
PlaceOnTop PlaceOnBottom
}]
}

-rootx -
-rooty -
-x -
-y { return [DisplayHints <coord>] }

-state {
return [CompleteFromList ${text} {
VisibilityUnobscured
VisibilityPartiallyObscured
VisibilityFullyObscured
<integer>
}]
}

-time { return [DisplayHints <integer>] }
-when {
return [CompleteFromList ${text} {
now tail head mark
}]
}

default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-above -borderwidth -button -count -delta
-detail -focus -height -keycode -keysym
-mode -override -place -root -rootx -rooty
-sendevent -serial -state -subwindow -time
-width -when -x -y
}]]

}
}
default { }
}
}
}
}
return ""
}

proc complete(focus) {text start end line pos mod} {
switch -- ${pos} {
1 {
return [CompleteFromList ${text} \
[concat [WidgetChildren ${text}] -displayof -force -lastfor]]
}
default {
switch -- [PreviousWord ${start} ${line}] {
-displayof -
-force -
-lastfor {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
}
}
}
return ""
}

proc FontConfigure {text line prev} {
set fontopts {-family -overstrike -size -slant -underline -weight}
switch -- ${prev} {
-family {
return [CompleteFromList ${text} [font families]]
}
-underline -
-overstrike { return [CompleteBoolean ${text}] }
-size { return [DisplayHints <size>] }
-slant {
return [CompleteFromList ${text} { roman italic }]
}
-weight {
return [CompleteFromList ${text} { normal bold }]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${fontopts}]]
}
}
}

proc complete(font) {text start end line pos mod} {
set fontopts {-family -overstrike -size -slant -underline -weight}
set fontmetrics {-ascent -descent -linespace -fixed}
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} {
actual configure create delete families measure metrics names
}]
}
2 {
switch -- ${sub} {
actual -
measure -
metrics {
return [DisplayHints <font>]
}
configure -
delete {
set names [font names]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
return [DisplayHints <fontname>]
}
}
create {
return [CompleteFromList ${text} \
[concat ?fontname? ${fontopts}]]
}
families {
return [CompleteFromList ${text} -displayof]
}
names {}
}
}
3 {
switch -- ${sub} {
actual {
return [CompleteFromList ${text} \
[concat -displayof ${fontopts}]]
}
configure -
create {
return [FontConfigure ${text} ${line} ${prev}]
}
delete {
set names [font names]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
return [DisplayHints <fontname>]
}
}
families {
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
}
}
measure {
return [CompleteFromList ${text} {-displayof <text>}]
}
metrics {
return [CompleteFromList ${text} \
[concat -displayof ${fontmetrics}]]
}
names {}
}
}
4 {
switch -- ${sub} {
actual {
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
default {
return [FontConfigure ${text} ${line} ${prev}]
}
}
}
configure -
create {
return [FontConfigure ${text} ${line} ${prev}]
}
delete {
set names [font names]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
return [DisplayHints <fontname>]
}
}
families {}
measure {
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
default {
return [DisplayHints <text>]
}
}
}
metrics {
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
default {
return [CompleteFromList ${text} ${fontmetrics}]
}
}
}
names {}
}
}
default {
switch -- ${sub} {
actual -
configure -
create {
return [FontConfigure ${text} ${line} ${prev}]
}
delete {
set names [font names]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
return [DisplayHints <fontname>]
}
}
families {}
measure {
return [DisplayHints <text>]
}
metrics {
return [CompleteFromList ${text} ${fontmetrics}]
}
names {}
}
}
}
return ""
}

proc complete(frame) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-borderwidth -cursor -highlightbackground -highlightcolor
-highlightthickness -relief -takefocus -background
-class -colormap -container -height -visual -width
}]
}
}
return ""
}

proc complete(grab) {text start end line pos mod} {
switch -- ${pos} {
1 {
return [CompleteFromList ${text} [concat \
current release set status -global [WidgetChildren ${text}]]]
}
2 {
switch -- [Lindex ${line} 1] {
-global -
current -
release -
status {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
set {
return [CompleteFromList ${text} \
[concat -global [WidgetChildren ${text}]]]
}
}
}
3 {
switch -- [Lindex ${line} 1] {
set {
switch -- [PreviousWord ${start} ${line}] {
-global {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
}
}
}
}
}
return ""
}

proc GridConfig {text start line prev} {
set opts {
-column -columnspan -in -ipadx -ipady
-padx -pady -row -rowspan -sticky
}
if {-1 == [string first "-" ${line}]} {
set slave [WidgetChildren ${text}]
} else {
set slave ""
}
switch -- ${prev} {
-column -
-columnspan -
-row -
-rowspan { return [DisplayHints <n>] }

-ipadx -
-ipady -
-padx -
-pady { return [DisplayHints <amount>] }

-in { return [CompleteFromList ${text} [WidgetChildren ${text}]] }
-sticky {
set prev [PreviousWordOfIncompletePosition ${start} ${line}]
return [CompleteListFromList ${text} \
[string trimleft [IncompleteListRemainder ${line}]] \
{n e s w} \{ { } \}]
}


default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} [concat ${opts} ${slave}]]]
}
}
}

proc complete(grid) {text start end line pos mod} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} \
[concat [WidgetChildren ${text}] {
bbox columnconfigure configure forget
info location propagate rowconfigure
remove size slaves
}]]
}
2 {
switch -- ${sub} {
bbox -
columnconfigure -
configure -
forget -
info -
location -
propagate -
rowconfigure -
remove -
size -
slaves {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
default {
return [GridConfig ${text} ${start} ${line} ${prev}]
}
}
}
default {
switch -- ${sub} {
bbox {
switch [expr ${pos} % 2] {
0 { return [DisplayHints ?row?] }
1 { return [DisplayHints ?column?] }
}
}
rowconfigure -
columnconfigure {
switch -- ${pos} {
3 { return [DisplayHints <index>] }
default {
switch -- ${prev} {
-minsize { return [DisplayHints <minsize>] }
-weight { return [DisplayHints <weight>] }
-pad { return [DisplayHints <pad>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line}  {
-minsize -weight -pad
}]]
}
}
}
}
}
configure {
return [GridConfig ${text} ${start} ${line} ${prev}]
}
forget -
remove {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
info {}
location {
switch -- ${pos} {
3 { return [DisplayHints <x>] }
4 { return [DisplayHints <y>] }
}
}
propagate {
switch -- ${pos} {
3 { return [CompleteBoolean ${text}] }
}
}
size {}
slaves {
switch -- ${prev} {
-row { return [DisplayHints <row>] }
-column { return [DisplayHints <column>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line}  { -row -column }]]
}
}
}
default {
return [GridConfig ${text} ${start} ${line} ${prev}]
}
}
}
}
return ""
}

proc complete(image) {text start end line pos mod} {
set sub [Lindex ${line} 1]
switch -- ${pos} {
1 { return [TrySubCmds ${text} image] }
2 {
switch -- ${sub} {
create { return [CompleteFromList ${text} [image types]] }
delete -
height -
type -
width { return [CompleteFromList ${text} [image names]] }
names {}
types {}
}
}
3 {
switch -- ${sub} {
create {
set type [Lindex ${line} 2]
switch -- ${type} {
bitmap {
return [CompleteFromList ${text} {
?name? -background -data -file
-foreground -maskdata -maskfile
}]
}
photo {
return [CompleteFromList ${text} {
?name? -data -format -file -gamma
-height -palette -width
}]
}
default {}
}
}
delete { return [CompleteFromList ${text} [image names]] }
default {}
}
}
default {
switch -- ${sub} {
create {
set type [Lindex ${line} 2]
set prev [PreviousWord ${start} ${line}]
# puts stderr prev=$prev
switch -- ${type} {
bitmap {
switch -- ${prev} {
-background -
-foreground { return [DisplayHints <color>] }
-data -
-maskdata { return [DisplayHints <string>] }
-file -
-maskfile { return "" }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-background -data -file
-foreground -maskdata -maskfile
}]]
}
}
}
photo {
switch -- ${prev} {
-data { return [DisplayHints <string>] }
-file { return "" }
-format { return [DisplayHints <format-name>] }
-gamma { return [DisplayHints <value>] }
-height -
-width { return [DisplayHints <number>] }
-palette {
return [DisplayHints <palette-spec>]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-data -format -file -gamma
-height -palette -width
}]]
}
}
}
}
}
delete { return [CompleteFromList ${text} [image names]] }
default {}
}
}
}
}

proc complete(label) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-anchor -background -bitmap -borderwidth -cursor -font
-foreground -highlightbackground -highlightcolor
-highlightthickness -image -justify -padx -pady -relief
-takefocus -text -textvariable -underline -wraplength
-height -width
}]
}
}
return ""
}

proc complete(listbox) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-background -borderwidth -cursor -exportselection -font
-foreground -height -highlightbackground -highlightcolor
-highlightthickness -relief -selectbackground
-selectborderwidth -selectforeground -setgrid -takefocus
-width -xscrollcommand -yscrollcommand -height -selectmode
-width
}]
}
}
return ""
}

proc complete(lower) {text start end line pos mod} {
switch -- ${pos} {
1 -
2 {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
}
}

proc complete(menu) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground -activeborderwidth -activeforeground
-background -borderwidth -cursor -disabledforeground
-font -foreground -relief -takefocus -postcommand
-selectcolor -tearoff -tearoffcommand -title -type
}]
}
}
return ""
}

proc complete(menubutton) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground -activeforeground -anchor -background
-bitmap -borderwidth -cursor -disabledforeground -font
-foreground -highlightbackground -highlightcolor
-highlightthickness -image -justify -padx -pady -relief
-takefocus -text -textvariable -underline -wraplength
-direction -height -indicatoron -menu -state -width
}]
}
}
return ""
}

proc complete(message) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-anchor -background -borderwidth -cursor -font -foreground
-highlightbackground -highlightcolor -highlightthickness
-padx -pady -relief -takefocus -text -textvariable -width
-aspect -justify -width
}]
}
}
return ""
}

proc OptionPriority text {
return [CompleteFromList ${text} {
widgetDefault startupFile userDefault interactive
}]
}

proc complete(option) {text start end line pos mod} {
set sub [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} {
add clear get readfile
}]
}
2 {
switch -- ${sub} {
add { return [DisplayHints <pattern>] }
get {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
readfile { return "" }
}
}
3 {
switch -- ${sub} {
add { return [DisplayHints <value>] }
get { return [DisplayHints <name>] }
readfile { return [OptionPriority ${text}] }
}
}
4 {
switch -- ${sub} {
add { return [OptionPriority ${text}] }
get {
return [CompleteFromList ${text} \
[ClassTable [Lindex ${line} 2]]]
}
readfile {}
}
}
}
}

proc PackConfig {text line prev} {
set opts {
-after -anchor -before -expand -fill
-in -ipadx -ipady -padx -pady -side
}
if {-1 == [string first "-" ${line}]} {
set slave [WidgetChildren ${text}]
} else {
set slave ""
}
switch -- ${prev} {
-after -
-before  { return [CompleteFromList ${text} [WidgetChildren ${text}]] }
-anchor { return [CompleteAnchor ${text}] }
-expand { return [CompleteBoolean ${text}] }
-fill { return [CompleteFromList ${text} { none x y both }] }

-ipadx -
-ipady -
-padx -
-pady { return [DisplayHints <amount>] }

-in { return [CompleteFromList ${text} [WidgetChildren ${text}]] }
-side { return [CompleteFromList ${text} { left right top bottom }] }

default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} [concat ${opts} ${slave}]]]
}
}
}

proc complete(pack) {text start end line pos mod} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} \
[concat [WidgetChildren ${text}] {
configure forget info propagate slaves
}]]
}
2 {
switch -- ${sub} {
configure -
forget -
info -
propagate -
slaves {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
default {
return [PackConfig ${text} ${line} ${prev}]
}
}
}
default {
switch -- ${sub} {
configure {
return [PackConfig ${text} ${line} ${prev}]
}
forget {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
info {}
propagate {
switch -- ${pos} {
3 { return [CompleteBoolean ${text}] }
}
}
slaves {}
default {
return [PackConfig ${text} ${line} ${prev}]
}
}
}
}
return ""
}

proc PlaceConfig {text line prev} {
set opts {
-in -x -relx -y -rely -anchor -width
-relwidth -height -relheight -bordermode
}
switch -- ${prev} {

-in { return [CompleteFromList ${text} [WidgetChildren ${text}]] }

-x -
-relx -
-y -
-rely { return [DisplayHints <location>] }

-anchor { return [CompleteAnchor ${text}] }

-width -
-relwidth -
-height -
-relheight { return [DisplayHints <size>] }

-bordermode {
return [CompleteFromList ${text} {ignore inside outside}]
}

default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${opts}]]
}
}
}

proc complete(place) {text start end line pos mod} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} \
[concat [WidgetChildren ${text}] {
configure forget info slaves
}]]
}
2 {
switch -- ${sub} {
configure -
forget -
info -
slaves {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
default {
return [PlaceConfig ${text} ${line} ${prev}]
}
}
}
default {
switch -- ${sub} {
configure {
return [PlaceConfig ${text} ${line} ${prev}]
}
forget {}
info {}
slaves {}
default {
return [PlaceConfig ${text} ${line} ${prev}]
}
}
}
}
return ""
}

proc complete(radiobutton) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground -activeforeground -anchor -background
-bitmap -borderwidth -cursor -disabledforeground -font
-foreground -highlightbackground -highlightcolor
-highlightthickness -image -justify -padx -pady -relief
-takefocus -text -textvariable -underline -wraplength -command
-height -indicatoron -selectcolor -selectimage -state -value
-variable -width
}]
}
}
return ""
}

proc complete(raise) {text start end line pos mod} {
return [complete(lower) ${text} ${start} ${end} ${line} ${pos} ${mod}]
}

proc complete(scale) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground -background -borderwidth -cursor -font
-foreground -highlightbackground -highlightcolor
-highlightthickness -orient -relief -repeatdelay
-repeatinterval -takefocus -troughcolor -bigincrement
-command -digits -from -label -length -resolution
-showvalue -sliderlength -sliderrelief -state -tickinterval
-to -variable -width
}]
}
}
return ""
}

proc complete(scrollbar) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-activebackground -background -borderwidth -cursor
-highlightbackground -highlightcolor -highlightthickness
-jump -orient -relief -repeatdelay -repeatinterval
-takefocus -troughcolor -activerelief -command
-elementborderwidth -width
}]
}
}
return ""
}

proc SelectionOpts {text start end line pos mod lst} {
set prev [PreviousWord ${start} ${line}]
if {-1 == [lsearch ${lst} ${prev}]} {
set prev "" ;# force the default arm
}
switch -- ${prev} {
-displayof {
return [CompleteFromList ${text} \
[WidgetChildren ${text}]]
}
-selection {
variable selection-selections
return [CompleteFromList ${text} ${selection-selections}]
}
-type {
variable selection-types
return [CompleteFromList ${text} ${selection-types}]
}
-command {
return [BraceOrCommand ${text} \
${start} ${end} ${line} ${pos} ${mod}]
}
-format {
variable selection-formats
return [CompleteFromList ${text} ${selection-formats}]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${lst}]]
}
}
}

proc complete(selection) {text start end line pos mod} {
switch -- ${pos} {
1 {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
default {
set sub [Lindex ${line} 1]
set widgets [WidgetChildren ${text}]
switch -- ${sub} {
clear {
return [SelectionOpts \
${text} ${start} ${end} ${line} ${pos} ${mod} {
-displayof -selection
}]
}
get {
return [SelectionOpts \
${text} ${start} ${end} ${line} ${pos} ${mod} {
-displayof -selection -type
}]
}
handle {
return [SelectionOpts \
${text} ${start} ${end} ${line} ${pos} ${mod} \
[concat {-selection -type -format} ${widgets}]]
}
own {
return [SelectionOpts \
${text} ${start} ${end} ${line} ${pos} ${mod} \
[concat {-command -selection} ${widgets}]]
}
}
}
}
}

proc complete(send) {text start end line pos mod} {
set prev [PreviousWord ${start} ${line}]
if {"-displayof" == ${prev}} {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
set cmds [RemoveUsedOptions ${line} {
-async -displayof --
} {--}]
if {[llength ${cmds}]} {
return [string trim [CompleteFromList ${text} \
[concat ${cmds} <app>]]]
} else {
if {[regexp -- --$ ${line}]} {
return [list {--}]; # append a blank
} else {
# TODO make this better!
return [DisplayHints [list {<app cmd ?arg ...?>}]]
}
}
return ""
}

proc complete(text) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-background -borderwidth -cursor -exportselection -font
-foreground -highlightbackground -highlightcolor
-highlightthickness -insertbackground -insertborderwidth
-insertofftime -insertontime -insertwidth -padx -pady
-relief -selectbackground -selectborderwidth
-selectforeground -setgrid -takefocus -xscrollcommand
-yscrollcommand -height -spacing1 -spacing2 -spacing3
-state -tabs -width -wrap
}]
}
}
return ""
}

proc complete(tk) {text start end line pos mod} {
switch -- ${pos} {
1 {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
default {
switch -- [Lindex ${line} 1] {
appname { return [DisplayHints ?newName?]  }
scaling {
switch -- [PreviousWord ${start} ${line}] {
-displayof {
return [TryFromList ${text} \
[WidgetChildren ${text}]]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {-displayof ?number?}]]
}
}
}
}
}
}
}

# proc complete(tk_bisque) {text start end line pos mod} {
# }

proc complete(tk_chooseColor) {text start end line pos mod} {
switch -- [PreviousWord ${start} ${line}] {
-initialcolor { return [CompleteColor ${text}] }
-parent { return [TryFromList ${text} [WidgetChildren ${text}]] }
-title { return [DisplayHints <string>] }
default {
return [TryFromList ${text} \
[RemoveUsedOptions ${line} {-initialcolor -parent -title}]]
}
}
}

proc complete(tk_dialog) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} [ToplevelWindows]] }
2 { return [DisplayHints <title>] }
3 { return [DisplayHints <text>] }
4 { return [CompleteFromBitmaps ${text}] }
5 { return [DisplayHints <defaultIndex>] }
default { return [DisplayHints ?buttonName?] }
}
}

proc complete(tk_focusNext) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} [WidgetChildren ${text}]] }
}
}

proc complete(tk_focusPrev) {text start end line pos mod} {
switch -- ${pos} {
1 { return [CompleteFromList ${text} [WidgetChildren ${text}]] }
}
}

# proc complete(tk_focusFollowsMouse) {text start end line pos mod} {
# }

proc GetOpenSaveFile {text start end line pos mod {add ""}} {
# enable filename completion for the first four switches.
switch -- [PreviousWord ${start} ${line}] {
-defaultextension {}
-filetypes {}
-initialdir {}
-initialfile {}
-parent {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
-title { return [DisplayHints <titleString>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} [concat {
-defaultextension -filetypes -initialdir -parent -title
} ${add}]]]
}
}
}

proc complete(tk_getOpenFile) {text start end line pos mod} {
return [GetOpenSaveFile \
${text} ${start} ${end} ${line} ${pos} ${mod}]
}

proc complete(tk_getSaveFile) {text start end line pos mod} {
return [GetOpenSaveFile \
${text} ${start} ${end} ${line} ${pos} ${mod} -initialfile]
}

proc complete(tk_messageBox) {text start end line pos mod} {
switch -- [PreviousWord ${start} ${line}] {
-default {
return [CompleteFromList ${text} {
abort cancel ignore no ok retry yes
}]
}
-icon {
return [CompleteFromList ${text} {
error info question warning
}]
}
-message { return [DisplayHints <string>] }
-parent {
return [CompleteFromList ${text} [WidgetChildren ${text}]]
}
-title { return [DisplayHints <titleString>] }
-type {
return [CompleteFromList ${text} {
abortretryignore ok okcancel retrycancel yesno yesnocancel
}]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-default -icon -message -parent -title -type
}]]
}
}
}

proc complete(tk_optionMenu) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
2 { return [VarCompletion ${text} #0] }
3 { return [DisplayHints <value>] }
default { return [DisplayHints ?value?] }
}
}

proc complete(tk_popup) {text start end line pos mod} {
switch -- ${pos} {
1 {
# display only menu widgets
#
set widgets [WidgetChildren ${text}]
set menu_widgets ""
foreach widget ${widgets} {
if {"Menu" == [winfo class ${widget}]} {
lappend menu_widgets ${widget}
}
}
if {[llength ${menu_widgets}]} {
return [TryFromList ${text} ${menu_widgets}]
} else {
return [DisplayHints <menu>]
}
}
2 { return [DisplayHints <x>] }
3 { return [DisplayHints <y>] }
4 { return [DisplayHints ?entryIndex?] }
}
}

# TODO: the name - value construct didn't work in my wish.
#
proc complete(tk_setPalette) {text start end line pos mod} {
set database {
activeBackground        foreground              selectColor
activeForeground        highlightBackground     selectBackground
background              highlightColor          selectForeground
disabledForeground      insertBackground        troughColor
}
switch -- ${pos} {
1 {
return [CompleteColor ${text} ${database}]
}
default {
switch [expr ${pos} % 2] {
1 {
return [CompleteFromList ${text} ${database}]
}
0 {
return [CompleteColor ${text}]
}
}
}
}
}

proc complete(tkwait) {text start end line pos mod} {
switch -- ${pos} {
1 {
return [CompleteFromList ${text} {
variable visibility window
}]
}
2 {
switch [Lindex ${line} 1] {
variable {
return [VarCompletion ${text} #0]
}
visibility -
window {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
}
}
}
}

proc complete(toplevel) {text start end line pos mod} {
switch -- ${pos} {
1 { return [EventuallyInsertLeadingDot ${text} <pathName>] }
default {
return [CompleteWidgetConfigurations ${text} ${start} ${line} {
-borderwidth -cursor -highlightbackground -highlightcolor
-highlightthickness -relief -takefocus -background
-class -colormap -container -height -menu -screen
-use -visual -width
}]
}
}
return ""
}

proc complete(winfo) {text start end line pos mod} {
set sub [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [TrySubCmds ${text} winfo]
}
2 {
switch -- ${sub} {
atom {
return [TryFromList ${text} {-displayof <name>}]
}
containing {
return [TryFromList ${text} {-displayof <rootX>}]
}
interps {
return [TryFromList ${text} -displayof]
}
atomname -
pathname {
return [TryFromList ${text} {-displayof <id>}]
}
default {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
}
}
default {
switch -- ${sub} {
atom {
switch -- [PreviousWord ${start} ${line}] {
-displayof {
return [TryFromList ${text} \
[WidgetChildren ${text}]]
}
default { return [DisplayHints <name>] }
}
}
containing {
switch -- [Lindex ${line} 2] {
-displayof {
switch -- ${pos} {
3 {
return [TryFromList ${text} \
[WidgetChildren ${text}]]
}
4 {
return [DisplayHints <rootX>]
}
5 {
return [DisplayHints <rootY>]
}
}
}
default { return [DisplayHints <rootY>] }
}
}
interps {
switch -- [PreviousWord ${start} ${line}] {
-displayof {
return [TryFromList ${text} \
[WidgetChildren ${text}]]
}
default {}
}
}
atomname -
pathname {
switch -- [PreviousWord ${start} ${line}] {
-displayof {
return [TryFromList ${text} \
[WidgetChildren ${text}]]
}
default { return [DisplayHints <id>] }
}
}
visualsavailable { return [DisplayHints ?includeids?] }
default {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
}
}
}
return ""
}

proc complete(wm) {text start end line pos mod} {
set sub [Lindex ${line} 1]
switch -- ${pos} {
1 {
return [CompleteFromList ${text} {
aspect client colormapwindows command deiconify focusmodel
frame geometry grid group iconbitmap iconify iconmask iconname
iconposition iconwindow maxsize minsize overrideredirect
positionfrom protocol resizable sizefrom state title transient
withdraw
}]
}
2 {
return [TryFromList ${text} [ToplevelWindows]]
}
3 {
switch -- ${sub} {
aspect { return [DisplayHints ?minNumer?] }
client { return [DisplayHints ?name?] }
colormapwindows {
return [CompleteListFromList ${text} \
[string trimleft [IncompleteListRemainder ${line}]] \
[WidgetChildren .] \{ { } \}]
}
command { return [DisplayHints ?value?] }
focusmodel {
return [CompleteListFromList ${text} {active passive}]
}
geometry {
return [DisplayHints ?<width>x<height>+-<x>+-<y>?]
}
grid { return [DisplayHints ?baseWidth?] }
group {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
iconbitmap -
iconmask { return [CompleteFromBitmaps ${text}] }
iconname { return [DisplayHints ?newName?] }
iconposition { return [DisplayHints ?x?] }
iconwindow {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
maxsize -
minsize { return [DisplayHints ?width?] }
overrideredirect { return [CompleteBoolean ${text}] }
positionfrom -
sizefrom {
return [CompleteFromList ${text} {position user}]
}
protocol {
return [CompleteFromList ${text} {
WM_TAKE_FOCUS WM_SAVE_YOURSELF WM_DELETE_WINDOW
}]
}
resizable { return [DisplayHints ?width?] }
title { return [DisplayHints ?string?] }
transient {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
default {
return [TryFromList ${text} [ToplevelWindows]]
}
}
}
4 {
switch -- ${sub} {
aspect { return [DisplayHints ?minDenom?] }
grid { return [DisplayHints ?baseHeight?] }
iconposition { return [DisplayHints ?y?] }
maxsize -
minsize { return [DisplayHints ?height?] }
protocol {
return [BraceOrCommand ${text} \
${start} ${end} ${line} ${pos} ${mod}]
}
resizable { return [DisplayHints ?height?] }
}
}
5 {
switch -- ${sub} {
aspect { return [DisplayHints ?maxNumer?] }
grid { return [DisplayHints ?widthInc?] }
}
}
6 {
switch -- ${sub} {
aspect { return [DisplayHints ?maxDenom?] }
grid { return [DisplayHints ?heightInc?] }
}
}
}
return ""
}

# ==== ObjCmd completers ==========================
#
# @note when a proc is commented out, the fallback
#       completers do the job rather well.
#
# =================================================


# proc ButtonObj {text start end line pos} {
# 	return ""
# }

proc CompleteFromBitmaps {text {always 1}} {
set inames [image names]
set bitmaps ""
foreach name $inames {
if {"bitmap" == [image type $name]} {
lappend bitmaps ${name}
}
}
if {[string length ${bitmaps}]} {
return [CompleteFromList \
${text} ${bitmaps}]
} else {
if ${always} {
return [DisplayHints <bitmaps>]
} else {
return ""
}
}
}

proc CompleteFromImages {text {always 1}} {
set inames [image names]
if {[string length ${inames}]} {
return [CompleteFromList ${text} ${inames}]
} else {
if ${always} {
return [DisplayHints <image>]
} else {
return ""
}
}
}

proc CompleteAnchor text {
return [CompleteFromList ${text} {
n ne e se s sw w nw center
}]
}

proc CompleteJustify text {
return [CompleteFromList ${text} {
left center right
}]
}

proc CanvasItem {text start end line pos prev type} {

switch -- ${type} {
arc {
switch -- ${prev} {
-extent { return [DisplayHints <degrees>] }
-fill -
-outline { return [DisplayHints <color>] }
-outlinestipple -
-stipple {
set inames [image names]
set bitmaps ""
foreach name $inames {
if {"bitmap" == [image type $name]} {
lappend bitmaps ${name}
}
}
if {[string length ${bitmaps}]} {
return [CompleteFromList \
${text} ${bitmaps}]
} else {
return [DisplayHints <bitmaps>]
}
}
-start { return [DisplayHints <degrees>] }
-style { return [DisplayHints <type>] }
-tags { return [DisplayHints <tagList>] }
-width { return [DisplayHints <outlineWidth>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-extent -fill -outline -outlinestipple
-start -stipple -style -tags -width
}]]
}
}
}
bitmap {
switch -- ${prev} {
-anchor { return [CompleteAnchor ${text}] }
-background -
-foreground { return [DisplayHints <color>] }
-bitmap { return [CompleteFromBitmaps ${text}] }
-tags { return [DisplayHints <tagList>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-anchor -background -bitmap
-foreground -tags
}]]
}
}
}
image {
switch -- ${prev} {
-anchor { return [CompleteAnchor ${text}] }
-image { return [CompleteFromImages ${text}] }
-tags { return [DisplayHints <tagList>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-anchor -image -tags
}]]
}
}
}
line {
switch -- ${prev} {
-arrow {
return [CompleteFromList ${text} {
none first last both
}]
}
-arrowshape { return [DisplayHints <shape>] }
-capstyle {
return [CompleteFromList ${text} {
butt projecting round
}]
}
-fill { return [DisplayHints <color>] }
-joinstyle {
return [CompleteFromList ${text} {
bevel miter round
}]
}
-smooth { return [CompleteBoolean ${text}] }
-splinesteps { return [DisplayHints <number>] }
-stipple { return [CompleteFromBitmaps ${text}] }
-tags { return [DisplayHints <tagList>] }
-width { return [DisplayHints <lineWidth>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-arrow -arrowshape -capstyle -fill -joinstyle
-smooth -splinesteps -stipple -tags -width
}]]
}
}
}
oval {
switch -- ${prev} {
-fill -
-outline { return [DisplayHints <color>] }
-stipple { return [CompleteFromBitmaps ${text}] }
-tags { return [DisplayHints <tagList>] }
-width { return [DisplayHints <lineWidth>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-fill -outline -stipple -tags -width
}]]
}
}
}
polygon {
switch -- ${prev} {
-fill -
-outline { return [DisplayHints <color>] }
-smooth { return [CompleteBoolean ${text}] }
-splinesteps { return [DisplayHints <number>] }
-stipple { return [CompleteFromBitmaps ${text}] }
-tags { return [DisplayHints <tagList>] }
-width { return [DisplayHints <outlineWidth>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-fill -outline -smooth -splinesteps
-stipple -tags -width
}]]
}
}
}
rectangle {
switch -- ${prev} {
-fill -
-outline { return [DisplayHints <color>] }
-stipple { return [CompleteFromBitmaps ${text}] }
-tags { return [DisplayHints <tagList>] }
-width { return [DisplayHints <lineWidth>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-fill -outline -stipple -tags -width
}]]
}
}
}
text {
switch -- ${prev} {
-anchor { return [CompleteAnchor ${text}] }
-fill { return [DisplayHints <color>] }
-font { return [DisplayHints <font>] }
-justify { return [CompleteJustify ${text}] }
-stipple { return [CompleteFromBitmaps ${text}] }
-tags { return [DisplayHints <tagList>] }
-text { return [DisplayHints <string>] }
-width { return [DisplayHints <lineLength>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-anchor -fill -font -justify
-stipple -tags -text -width
}]]
}
}
}
window {
switch -- ${prev} {
-anchor { return [CompleteAnchor ${text}] }
-height { return [DisplayHints <pixels>] }
-tags { return [DisplayHints <tagList>] }
-width { return [DisplayHints <lineWidth>] }
-window {
return [TryFromList ${text} [WidgetChildren ${text}]]
}
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-anchor -height -tags -width -window
}]]
}
}
}
}
}

#**
# WidgetXviewYview
#
# @param    text  -- the word to complete.
# @param    line  -- the line gathered so far.
# @param    pos   -- the current word position.
# @param    prev  -- the previous word.
# @return   a std tclreadline formatted completer string.
# @sa       CanvasObj, EntryObj
# @date     Sep-18-1999
#
proc WidgetXviewYview {text line pos prev} {
switch -- ${pos} {
2 { return [CompleteFromList ${text} {<index> moveto scroll}] }
3 {
switch -- ${prev} {
moveto { return [DisplayHints <fraction>] }
scroll { return [DisplayHints <number>] }
}
}
4 {
set subcmd [Lindex ${line} 2]
switch -- ${subcmd} {
scroll { return [DisplayHints <what>] }
}
}
}
}

#**
# WidgetScan
#
# @param    text  -- the word to complete.
# @param    pos   -- the current word position.
# @return   a std tclreadline formatted completer string.
# @sa       CanvasObj, EntryObj
# @date     Sep-18-1999
#
proc WidgetScan {text pos} {
switch -- ${pos} {
2 { return [CompleteFromList ${text} {mark dragto}] }
3 { return [DisplayHints <x>] }
4 { return [DisplayHints <y>] }
}
}

proc CanvasObj {text start end line pos} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
if {1 == $pos} {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
switch -- ${sub} {
addtag {
switch -- ${pos} {
2 { return [DisplayHints <tag>] }
3 {
return [CompleteFromList ${text} {
above all below closest enclosed
overlapping withtag
}]
}
default {
set search [Lindex ${line} 3]
switch -- ${search} {
all {}
above -
withtag -
below { return [DisplayHints <tagOrId>] }
closest {
switch -- ${pos} {
4 { return [DisplayHints <x>] }
5 { return [DisplayHints <y>] }
6 { return [DisplayHints ?halo?] }
7 { return [DisplayHints ?start?] }
}
}
enclosed -
overlapping {
switch -- ${pos} {
4 { return [DisplayHints <x1>] }
5 { return [DisplayHints <y1>] }
6 { return [DisplayHints <x2>] }
7 { return [DisplayHints <y2>] }
}
}
}
}
}
}
bbox {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
default { return [DisplayHints ?tagOrId?] }
}
}
bind {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 {
set fulltext [Lindex ${line} 3]
return [CompleteSequence ${text} ${fulltext}]
# return [DisplayHints ?sequence?]
}
default {
return [BraceOrCommand ${text} \
${start} ${end} ${line} ${pos} ${text}]
}
}
}
canvasx {
switch -- ${pos} {
2 { return [DisplayHints <screenx>] }
3 { return [DisplayHints ?gridspacing?] }
}
}
canvasy {
switch -- ${pos} {
2 { return [DisplayHints <screeny>] }
3 { return [DisplayHints ?gridspacing?] }
}
}
coords {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
default {
switch [expr ${pos} % 2] {
1 { return [DisplayHints ?x?] }
0 { return [DisplayHints ?y?] }
}
}
}
}
dchars {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints <first>] }
4 { return [DisplayHints ?last?] }
}
}
delete { return [DisplayHints ?tagOrId?] }
dtag {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints ?tagToDelete?] }
}
}
find {
switch -- ${pos} {
2 {
return [TrySubCmds ${text} [Lrange ${line} 0 1]]
}
default { return [DisplayHints ?arg?] }
}
}
focus {
switch -- ${pos} {
2 { return [DisplayHints ?tagOrId?] }
}
}
gettags {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
}
}
icursor -
index {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints <index>] }
}
}
insert {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints <beforeThis>] }
4 { return [DisplayHints <string>] }
}
}
lower {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints ?belowThis?] }
}
}
move {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints <xAmount>] }
4 { return [DisplayHints <yAmount>] }
}
}
postscript {
switch -- ${prev} {
-file { return "" }
-colormap -
-colormode -
-fontmap -
-height -
-pageanchor -
-pageheight -
-pagewidth -
-pagex -
-pagey -
-rotate -
-width -
-x -
-y { return [DisplayHints <[String range ${prev} 1 end]>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-colormap -colormode -file -fontmap -height
-pageanchor -pageheight -pagewidth -pagex
-pagey -rotate -width -x -y
}]]
}
}
}
raise {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints ?aboveThis?] }
}
}
scale {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
3 { return [DisplayHints <xOrigin>] }
4 { return [DisplayHints <yOrigin>] }
5 { return [DisplayHints <xScale>] }
6 { return [DisplayHints <yScale>] }
}
}
scan { return [WidgetScan ${text} ${pos}] }
select {
switch -- ${pos} {
2 {
return [CompleteFromList ${text} {
adjust clear item from to
}]
}
3 {
set sub [Lindex ${line} 2]
switch -- ${sub} {
adjust -
from -
to { return [DisplayHints <tagOrId>] }
}
}
4 {
set sub [Lindex ${line} 2]
switch -- ${sub} {
adjust -
from -
to { return [DisplayHints <index>] }
}
}
}
}
xview -
yview { return [XviewYview ${text} ${line} ${pos} ${prev}] }
create {
switch -- ${pos} {
2 {
return [CompleteFromList ${text} {
arc bitmap image line oval
polygon rectangle text window
}]
}
3 { return [DisplayHints <x1>] }
4 { return [DisplayHints <y1>] }
5 {
set type [Lindex ${line} 2]
switch -- ${type} {
arc -
oval -
rectangle { return [DisplayHints <x2>] }
# TODO items with more than 4 coordinates
default {
return [CanvasItem ${text} ${start} \
${end} ${line} ${pos} ${prev} ${type}]
}
}
}
6 {
set type [Lindex ${line} 2]
switch -- ${type} {
arc -
oval -
rectangle { return [DisplayHints <y2>] }
# TODO items with more than 4 coordinates
default {
return [CanvasItem ${text} ${start} \
${end} ${line} ${pos} ${prev} ${type}]
}
}
}
default {
set type [Lindex ${line} 2]
# TODO items with more than 4 coordinates
return [CanvasItem ${text} ${start} \
${end} ${line} ${pos} ${prev} ${type}]
}
}
}
itemconfigure -
itemcget {
switch -- ${pos} {
2 { return [DisplayHints <tagOrId>] }
default {

set id [Lindex ${line} 2]
set type [[Lindex ${line} 0] type ${id}]
if {![string length ${type}]} {
return ""; # no such element
}

return [CanvasItem ${text} ${start} \
${end} ${line} ${pos} ${prev} ${type}]
}
}
}
}
return ""
}

proc EntryIndex text {
return [CompleteFromList ${text} {
<number> <@number> anchor end sel.first sel.last
}]
}

proc EntryObj {text start end line pos} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
if {1 == $pos} {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
switch -- ${sub} {
bbox -
icursor -
index { return [EntryIndex ${text}] }
cget {}
configure {}
get {}
insert {
switch -- ${pos} {
2 { return [EntryIndex ${text}] }
3 { return [DisplayHints <string>] }
}
}
scan { return [WidgetScan ${text} ${pos}] }
selection {
switch -- ${pos} {
2 {
return [TrySubCmds ${text} [Lrange ${line} 0 1]]
}
3 {
switch -- ${prev} {
adjust -
from -
to { return [EntryIndex ${text}] }
clear -
present {}
range { return [DisplayHints <start>] }
}
}
4 {
switch -- [Lindex ${line} 2] {
range { return [DisplayHints <end>] }
}
}
}
}
xview -
yview { return [WidgetXviewYview ${text} ${line} ${pos} ${prev}] }
}
return ""
}

# proc CheckbuttonObj {text start end line pos} {
# the fallback routines do the job pretty well.
# }

# proc FrameObj {text start end line pos} {
# the fallback routines do the job pretty well.
# }

# proc LabelObj {text start end line pos} {
# the fallback routines do the job pretty well.
# }

proc ListboxObj {text start end line pos} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
if {1 == $pos} {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
switch -- ${sub} {
activate -
bbox -
index -
see {
switch -- ${pos} {
2 {
return [DisplayHints <index>]
}
}
}
insert {
switch -- ${pos} {
2 {
return [DisplayHints <index>]
}
default {
return [DisplayHints ?element?]
}
}
}
cget {}
configure {}
curselection {}
delete -
get {
switch -- ${pos} {
2 {
return [DisplayHints <first>]
}
3 {
return [DisplayHints ?last?]
}
}
}
nearest {
switch -- ${pos} {
2 {
return [DisplayHints <y>]
}
}
}
size {}

scan { return [WidgetScan ${text} ${pos}] }

xview -
yview { return [WidgetXviewYview ${text} ${line} ${pos} ${prev}] }

selection {
switch -- ${pos} {
2 {
return [CompleteFromList ${text} {
anchor clear includes set
}]
}
3 {
switch -- ${prev} {
anchor -
includes {
return [CompleteFromList ${text} {
active anchor end @x @y <number>
}]
}
clear -
set { return [DisplayHints <first>] }
}
}
4 {
switch -- [Lindex ${line} 2] {
clear -
set { return [DisplayHints ?last?] }
}
}
}
}
}
}

proc MenuIndex text {
return [CompleteFromList ${text} {
<number> active end last none <@number> <labelPattern>
}]
}

proc MenuItem {text start end line pos virtualpos} {
switch -- ${virtualpos} {
2 {
return [CompleteFromList ${text} {
cascade checkbutton command radiobutton separator
}]
}
default {
switch -- [PreviousWord ${start} ${line}] {
-activebackground -
-activeforeground -
-background -
-foreground -
-selectcolor {
return [DisplayHints <color>]
}

-accelerator { return [DisplayHints <accel>] }
-bitmap { return [CompleteFromBitmaps ${text}] }

-columnbreak -
-hidemargin -
-indicatoron {
return [CompleteBoolean ${text}]
}
-command {
return [BraceOrCommand ${text} \
${start} ${end} ${line} ${pos} ${text}]
}
-font {
set names [font names]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
return [DisplayHints <fontname>]
}
}
-image -
-selectimage { return [CompleteFromImages ${text}] }

-label { return [DisplayHints <label>] }
-menu {
set names [WidgetChildren [Lindex ${line} 0]]
if {[string length ${names}]} {
return [CompleteFromList ${text} ${names}]
} else {
return [DisplayHints <menu>]
}
}

-offvalue -
-onvalue { return [DisplayHints <value>] }

-state {
return [CompleteFromList ${text} {
normal active disabled
}]
}
-underline { return [DisplayHints <integer>] }
-value { return [DisplayHints <value>] }
-variable {
return [VarCompletion ${text} #0]
}

default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} {
-activebackground -activeforeground
-accelerator -background -bitmap -columnbreak
-command -font -foreground -hidemargin -image
-indicatoron -label -menu -offvalue -onvalue
-selectcolor -selectimage -state -underline
-value -variable
}]]
}
}
}
}
}

proc MenuObj {text start end line pos} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
if {1 == $pos} {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
switch -- ${sub} {
activate -
index -
invoke -
postcascade -
type -
yposition {
switch -- ${pos} {
2 {
return [MenuIndex ${text}]
}
}
}
configure {}
cget {}

add {
return [MenuItem ${text} ${start} ${end} ${line} ${pos} ${pos}]
}
clone {
switch -- ${pos} {
2 { return [DisplayHints <newPathname>] }
3 {
return [CompleteFromList ${text} {
normal menubar tearoff
}]
}
}
}
delete {
switch -- ${pos} {
2 -
3 { return [MenuIndex ${text}] }
}
}
insert {
switch -- ${pos} {
2 { return [MenuIndex ${text}] }
default {
return [MenuItem ${text} ${start} ${end} \
${line} ${pos} [expr ${pos} - 1]]
}
}
}
entrycget -
entryconfigure {
switch -- ${pos} {
2 { return [MenuIndex ${text}] }
default {
return [MenuItem ${text} ${start} \
${end} ${line} ${pos} ${pos}]
}
}
}
post {
switch -- ${pos} {
2 { return [DisplayHints <x>] }
3 { return [DisplayHints <y>] }
}
}
# ??? XXX
unpost {}
}
}

proc PhotoObj {text start end line pos} {
set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]
set copy_opts { -from -to -shrink -zoom -subsample }
set read_opts { -from -to -shrink -format }
set write_opts { -from -format }
switch -- ${pos} {
1 {
return [CompleteFromList ${text} {
blank cget configure copy get put read redither write
}]
}
2 {
switch -- ${sub} {
blank {}
cget {}
configure {}
redither {}
copy { return [CompleteFromImages ${text}] }
get { return [DisplayHints <x>] }
put { return [DisplayHints <data>] }
read {}
write {}
}
}
3 {
switch -- ${sub} {
blank {}
cget {}
configure {}
redither {}
copy { return [CompleteFromList ${text} ${copy_opts}] }
get { return [DisplayHints <y>] }
put { return [CompleteFromList ${text} -to] }
read { return [CompleteFromList ${text} ${read_opts}] }
write { return [CompleteFromList ${text} ${write_opts}] }
}
}
default {
switch -- ${sub} {
blank {}
cget {}
configure {}
redither {}
get {}
copy {
switch -- ${prev} {
-from -
-to { return [DisplayHints [list <x1 y1 x2 y2>]] }
-zoom -
-subsample { return [DisplayHints [list <x y>]] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${copy_opts}]]
}
}
}
put {
switch -- ${prev} {
-to {
return [DisplayHints [list <x1 y1 x2 y2>]]
}
}
}
read {
switch -- ${prev} {
-from { return [DisplayHints [list <x1 y1 x2 y2>]] }
-to { return [DisplayHints [list <x y>]] }
-format { return [DisplayHints <formatName>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${read_opts}]]
}
}
}
write {
switch -- ${prev} {
-from { return [DisplayHints [list <x1 y1 x2 y2>]] }
-format { return [DisplayHints <formatName>] }
default {
return [CompleteFromList ${text} \
[RemoveUsedOptions ${line} ${write_opts}]]
}
}
}
}
}
}
}

# proc RadiobuttonObj {text start end line pos} {
# the fallback routines do the job pretty well.
# }

proc ScaleObj {text start end line pos} {

set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]

switch -- ${pos} {
1 {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
2 {
switch -- ${sub} {
coords { return [DisplayHints ?value?] }
get { return [DisplayHints ?x?] }
identify { return [DisplayHints <x>] }
set { return [DisplayHints <value>] }
}
}
3 {
switch -- ${sub} {
get { return [DisplayHints ?y?] }
identify { return [DisplayHints <y>] }
}
}
}
}

proc ScrollbarObj {text start end line pos} {

set sub [Lindex ${line} 1]
set prev [PreviousWord ${start} ${line}]

# note that the `prefix moveto|scroll'
# construct is hard to complete.
#
switch -- ${pos} {
1 {
return [TrySubCmds ${text} [Lindex ${line} 0]]
}
2 {
switch -- ${sub} {
activate {
return [CompleteFromList ${text} {
arrow1 slider arrow2
}]
}

fraction -
identify { return [DisplayHints <x>] }
delta { return [DisplayHints <deltaX>] }
set { return [DisplayHints <first>] }
}
}
3 {
switch -- ${sub} {

fraction -
identify { return [DisplayHints <y>] }
delta { return [DisplayHints <deltaY>] }
set { return [DisplayHints <last>] }
}
}
}
}

proc TextObj {text start end line pos} {
# TODO ...
return [CompleteFromOptionsOrSubCmds \
${text} ${start} ${end} ${line} ${pos}]
}

}; # namespace tclreadline
}
###########################################################################

set tcl_library .
set tcl_remove_quartus_column_name false
set tcl_force_remove_feeder_cells  false
set tcl_cmd_args {}
set sh_continue_on_error [expr \![alta::is_release_cmd]]
set sh_verbose_on_error  false
set sh_no_debug          true
set sh_echo_on_source    false
set sh_quiet_on_source   false

fconfigure stdout -translation auto
fconfigure stderr -translation auto
fconfigure stdin -translation auto


###########################################################################


if { "[info commands tcl_unknown]" == "" } {
rename unknown tcl_unknown
}

proc unknown { args } {
# Bus selector shall be used directly without \\ protected, otherwise it will be
# mistaken as a command.
if { [llength $args] == 1 && [regexp {^[0-9\*\?]+$} $args] } {
return "\[$args\]"

} elseif { [llength $args] >= 1 } {
# try abbreviation
set cmd [info commands [lindex $args 0]*]
if { [llength $cmd] == 1 } {
# find exact one
return [uplevel 1 [lreplace $args 0 0 $cmd]]
} elseif { [llength $cmd] > 1 } {
# match multiple commands
set cmd_candidates [alta::abbreviate_list [lsort $cmd]]
error "Can not find command $args, candidates are $cmd_candidates"
} else {
# no macthing
return [uplevel 1 tcl_unknown $args]
}
}
}

if { "[info commands tcl_source]" == "" } {
rename source tcl_source
}

# Block error on unrecognized QUARTUS package
if { "[info commands tcl_package]" == "" } {
rename package tcl_package
}

proc package { args } {
set code [catch { eval tcl_package $args } msg]
if { $code == 1 } {
if { [regexp "require.*quartus" $args] == 1 } {
return ""
} else {
error "$msg"
}
}
return "$msg"
}

# Tcl original lsearch can not handle xxx[num] stuff
if { "[info commands tcl_lsearch]" == "" } {
rename lsearch tcl_lsearch
}

proc lsearch { from_list to } {
set idx 0
foreach from [alta::tcl_esc $from_list] {
if { "$from" == "$to" } { return $idx }
incr idx
}
return -1
}


###########################################################################


proc bg_exec_handler {userdata what} {
puts $userdata$what
}

proc bg_exec {title prog pCount {readHandler {bg_exec_handler ""}} \
{timeout 0} {toExit ""} {eofHandler ""} {errHandler ""}} {
upvar 1 $pCount myCount
set p [expr {[lindex [lsort -dict [list 8.4.7 [info patchlevel]]] 0] == "8.4.7"\
?"| $prog 2>@1":"| $prog 2>@stdout"}]
set pH [open $p r]
set myCount [expr {[info exists myCount]?[incr myCount]:1}]; # precaution < 8.6
fconfigure $pH -blocking 0 -buffering line
set tID [expr {$timeout?[after $timeout [list bgExecTimeout $pH $pCount $toExit]]:{}}]
fileevent $pH readable \
[list bgExecGenericHandler $pH $pCount $readHandler $tID $eofHandler $errHandler]
if {[lindex $readHandler 1] != ""} {
eval $readHandler {": $title"}
}
alta::ensure_child_process_exitable_each
return $pH
}

proc bg_exec_queue {titles progs max_count} {
global bg_exec_count
set bg_exec_count 0
set id 0
foreach prog $progs {
set title [lindex $titles $id]
incr id
bg_exec "$title" "$prog" bg_exec_count [list bg_exec_handler "*$id* "]
while {$bg_exec_count >= $max_count} {
vwait bg_exec_count
}
}
while {$bg_exec_count > 0} {
vwait bg_exec_count
}
}

proc bgExecGenericHandler {chan pCount readHandler tID eofHandler errHandler} {
upvar 1 $pCount myCount
if {[catch {gets $chan line} result]} {
# read error -> abort processing. NOTE eof-handler NOT fired!
after cancel $tID
catch {close $chan}
incr myCount -1
if {[lindex $readHandler 1] != ""} {
eval $readHandler {": error!"}
}
if {[llength $errHandler]} {
catch {uplevel $errHandler $chan $result}
}
return
} elseif {$result >= 0} {
# we got a whole line
#lappend readHandler $line; # readhandler doesn't get the chan...
if {[catch {eval $readHandler {"$line"}}]} {
# user-readHandler ended with errorcode which means here
# "terminate the processing". NOTE eof-handler NOT fired!
after cancel $tID
catch {close $chan}
incr myCount -1
if {[lindex $readHandler 1] != ""} {
eval $readHandler {": terminated!"}
}
}
}; # not enough data (yet)
if {[eof $chan]} {
after cancel $tID; # terminate Timeout, no longer needed!
catch {close $chan}; # automatically deregisters the fileevent handler
incr myCount -1
if {[lindex $readHandler 1] != ""} {
eval $readHandler {": done"}
}
if {[llength $eofHandler]} {
catch {uplevel $eofHandler $chan}; # not called on timeout or user-break
}
}
}

proc bgExecTimeout {chan pCount toExit} {
upvar 1 $pCount myCount
if {[string length $toExit]} {
# The PIDs are one arg (list)
if {[catch {uplevel [list {*}$toExit [pid $chan]]}]} {
# user-timeoutHandler ended with error which means here
# "we didn't kill the processes" (such a kill would have
# normally triggered an EOF, so no other cleanup would be
# required then), so end the processing explicitely and do
# the cleanup. NOTE eof-handler NOT fired!
catch {close $chan}
incr myCount -1
}
} else {
# No user-timeoutHandler exists.
# So we must cleanup anyway (at least some level of compatibility...)
#  NOTE eof-handler NOT fired!
catch {close $chan}
incr myCount -1
}
}


###########################################################################


namespace eval alta {

proc tcl_version {} {
return [info patchlevel]
}

proc platform {} {
global tcl_platform
return $tcl_platform(platform)
}

proc fatal { msg } {
error "$msg" "" "FATAL_EXIT"
}

proc error_exit {} {
error "" "" "ERROR_EXIT"
}

proc assert { cond } {
global sh_no_debug
if { ! $sh_no_debug && ! [uplevel 1 eval [list expr $cond]] } {
uplevel 1 [list fatal "Assertion failed: $cond"]
}
}

# Place holder, workaround tcl error when eval a empty script
proc skip {args} {}

# Make sure foreach loop won't drop escape character
proc tcl_esc { vals } {
return [string map {\\ \\\\} $vals]
}

# Use list as stack for push and pop
proc stack_push { vals_ref val } {
upvar 1 $vals_ref vals
lappend vals $val
}
proc stack_pop { vals_ref } {
upvar 1 $vals_ref vals
set val [lindex $vals end]
set vals [lrange $vals 0 end-1]
return $val
}
proc stack_top { vals_ref } {
upvar 1 $vals_ref vals
return [lindex $vals end]
}

# Similar to lappend, but append a whole list instead
proc lreplaces { from_list from to } {
set to_list {}
foreach from0 [alta::tcl_esc $from_list] {
if { "$from0" == "$from" } {
lappend to_list $to
} else { lappend to_list $from0 }
}
return $to_list
}

proc lconcat { to_list_ref from_list } {
upvar 1 $to_list_ref to_list
foreach from [tcl_esc $from_list] {
lappend to_list $from
}
return $to_list
}

proc lintersect { from_list to_list } {
set result_list {}
foreach from [tcl_esc $from_list] {
if { [lsearch [tcl_esc $to_list] $from] >= 0} {
lappend result_list $from
}
}
return $result_list
}

proc lcombine { from_list to_list } {
set result_list $to_list
foreach from [tcl_esc $from_list] {
if { [lsearch [tcl_esc $to_list] $from] < 0 } {
lappend result_list $from
}
}
return $result_list
}

proc lexclude { from_list to_list } {
set result_list {}
foreach from [tcl_esc $from_list] {
if { [lsearch [tcl_esc $to_list] $from] < 0 } {
lappend result_list $from
}
}
foreach to [tcl_esc $to_list] {
if { [lsearch [tcl_esc $from_list] $to] < 0} {
lappend result_list $to
}
}
return $result_list
}

# Flatten a pure nested list: {{{a b c}}} => {a b c}
proc straighten_list { vals {max_depth -1}} {
set depth 0
while { [llength $vals] == 1 } {
if { [expr $max_depth >= 0 && $depth >= $max_depth] } { break }
set new_vals [lindex $vals 0]
if { "$new_vals" == "$vals" } { break }
set vals $new_vals
incr depth
}
return $vals
}

# Flatten a mixed nested list: {{a b} c} => {a b c}
proc flatten_list { vals } {
while { true } {
set new_vals {}
foreach val1 $vals { foreach val2 $val1 { foreach val3 $val2 {
lappend new_vals $val3
}}}
if { "$new_vals" == "$vals" } { break }
set vals $new_vals
}
return $vals
}

proc boolean { val } {
return [expr $val ? true : false]
}
proc not { val } {
return [boolean [expr {! $val}]]
}
proc and { args } {
set ret true
foreach val [tcl_esc $args] {
set ret [expr $ret && $val]
}
return [boolean $ret]
}
proc or { args } {
set ret false
foreach val [tcl_esc $args] {
set ret [expr $ret || $val]
}
return [boolean $ret]
}
proc xor { args } {
set ret false
foreach val [tcl_esc $args] {
set ret [expr ! $ret && $val || $ret && ! $val]
}
return [boolean $ret]
}
proc nand { args } {
return [not [and $args]]
}
proc nor { args } {
return [not [or $args]]
}
proc nxor { args } {
return [not [xor $args]]
}

# Return true if all arg items are empty string or null
proc is_null { args_ref } {
upvar 1 $args_ref args
if { ! [info exists args] } { return true }
foreach arg [tcl_esc $args] {
if { "$arg" != "" && "$arg" != "NULL" } { return false }
}
return true
}

# Return true is all arg items are either is_null or logic false
proc is_false { args_ref } {
upvar 1 $args_ref args
if { ! [info exists args] } { return true }
foreach arg [tcl_esc $args] {
if { ! [is_null arg] || $arg != false} {
return false
}
}
return true
}

proc is_true { args_ref } {
upvar 1 $args_ref args
return [expr ! [is_false args]]
}

proc get_float_with_unit { value_with_unit value_ref unit_ref } {
upvar 1 $value_ref value
upvar 1 $unit_ref  unit
set units {"" p n u m}
if { [string compare -nocase [string index $value_with_unit end] "s"] == 0 } {
set value_with_unit [string range $value_with_unit 0 end-1]
}
foreach ux $units {
set unit_len [string length $ux]
set value [string range $value_with_unit 0 end-$unit_len]
set unit  [string range $value_with_unit end-[expr $unit_len-1] end]
if { [check_is_float $value] && "$ux" == "$unit"} {
return true
}
}
return false
}

proc check_is_float_with_unit { str } { return [get_float_with_unit $str value unit] }
proc check_is_float { str } { return [string is double  -strict $str] }
proc check_is_int   { str } { return [string is integer -strict $str] }

proc array_has_key { arr_ref key } {
upvar 1 $arr_ref arr
return [info exists arr($key)]
}
proc array_find_key { arr_ref key } {
upvar 1 $arr_ref arr
if { [array_has_key arr $key] } {
return $arr($key)
} else {
return {}
}
}
proc array_clear { arr_ref } {
upvar 1 $arr_ref arr
array unset arr
array set arr {}
}

proc array_puts { arr_ref } {
upvar 1 $arr_ref arr
foreach { key val } [array get arr] {
puts "$key : $val"
}
}

proc has_wildcard { str } {
return [string match {*[*?]*} $str]
}

# Return true is arg is a commond argument (starting with -)
proc is_cmd_arg { arg } {
if { ! [check_is_float_with_unit $arg] && \
[string index $arg 0] == "-" && [string length $arg] > 1 } {
return true
} else {
return false
}
}

proc abbreviate_list { args {line_limit 40} } {
set abbreviation {}
foreach arg [tcl_esc $args] {
if { [string length $abbreviation] > $line_limit } {
lappend abbreviation " ... "
break
} else {
lappend abbreviation $arg
}
}
return [join $abbreviation {, }]
}

# Prcoess cmd_args basing on cmd_templs and set results to arg_vals and return remaining args.
# both cmd_templs and arg_vals are arrays.
proc parse_cmd_args { cmd_args cmd_templs_ref arg_vals_ref \
{min_remain 0} {max_remain 1024} {error_on_unmatched_arg true} } {
upvar 1 $cmd_templs_ref cmd_templs
upvar 1 $arg_vals_ref arg_vals
array_clear arg_vals
set args_remain {}
set args_sz [llength $cmd_args]
set arg_idx 0
while { $arg_idx < $args_sz } {
set arg [lindex $cmd_args $arg_idx]
set arg_glob "${arg}*"
if { [is_cmd_arg $arg] } {
set key [array names cmd_templs -exact $arg]
if { [is_null key] } {
set key [array names cmd_templs -glob $arg_glob]
}
if { ! [is_null key] && [llength $key] == 1 } {
set val_sz  [lindex $cmd_templs($key) 0]
set val_key [lindex $cmd_templs($key) 1]
if { [is_null val_key] } {
set is_replace true
} else {
set is_replace false
}
if { $arg_idx+$val_sz >= $args_sz } {
error "$key requires $val_sz values"
}
if { $val_sz == 0 } {
set arg_vals($key) true
} elseif { $is_replace } {
set arg_vals($key) [straighten_list [lrange $cmd_args $arg_idx+1 $arg_idx+$val_sz] 1]
} else {
lappend arg_vals($val_key) [list $key [straighten_list [lrange $cmd_args $arg_idx+1 $arg_idx+$val_sz] 1]]
}
set arg_idx [expr {$arg_idx + $val_sz + 1}]
} elseif { $error_on_unmatched_arg } {
if { [is_null key] } {
error "Has no argument matching $arg"
} elseif { [llength $key] != 1 } {
set key_candidates [alta::abbreviate_list [lsort $key]]
error "Has no argument matching $arg, candidates are $key_candidates"
}
} else {
# keep this unrecognized key
lappend args_remain $arg
incr arg_idx
}
} else {
# positional argument value, keep it
lappend args_remain $arg
incr arg_idx
}
}
set remain_sz [llength $args_remain]
if { [llength $min_remain] > 1 } {
if { [lsearch $min_remain $remain_sz] < 0 } {
error "Require $min_remain positional arguments, but got $remain_sz"
}
} elseif { $remain_sz < $min_remain || $remain_sz > $max_remain } {
error "Require $min_remain to $max_remain positional arguments, but got $remain_sz"
}
return [straighten_list $args_remain 1]
}

# Mimic C's enum and static const variable
proc const_var {name} {
uplevel 1 [list trace var $name w {error constant ;#}]
}

proc const_set {name value} {
uplevel 1 [list set $name $value]
uplevel 1 [list trace var $name w {error constant ;#}]
}

proc const_array_set {name value} {
uplevel 1 [list array set $name $value]
uplevel 1 [list trace var $name w {error constant ;#}]
}

# SWIG pointer object accessors
set OBJ_TYPES []
array set OBJ_NAME_BY_TYPE   {}
array set OBJ_CMD_BY_TYPE    {}
array set OBJ_COLUMN_BY_TYPE {}
foreach {obj_type obj_name obj_cmd obj_column} [tcl_esc [OBJ_ACCESSORS_CMD]] {
lappend OBJ_TYPES $obj_type
set OBJ_NAME_BY_TYPE($obj_type)   $obj_name
set OBJ_CMD_BY_TYPE($obj_type)    $obj_cmd
set OBJ_COLUMN_BY_TYPE($obj_type) $obj_column
}

proc get_object_name { obj_type } {
return [array_find_key alta::OBJ_NAME_BY_TYPE $obj_type]
}

proc get_object_cmd  { obj_type } {
return [array_find_key alta::OBJ_CMD_BY_TYPE  $obj_type]
}

proc get_object_column  { obj_type } {
return [array_find_key alta::OBJ_COLUMN_BY_TYPE  $obj_type]
}

proc get_object_type { obj obj_key_ref } {
upvar 1 $obj_key_ref obj_key
if [regexp {^_[0-9A-Fa-f]+_p_([A-Za-z_][0-9A-Za-z_]*)$} $obj ignores obj_key] {
return true
} else {
return false
}
}

proc is_object_of_type { obj obj_type } {
if { [get_object_type $obj obj_key] && $obj_key == $obj_type } {
return true
} else {
return false
}
}

# Categorize objects to map basing on object type
proc collect_objects_by_type { objs colls_ref others_ref target_types
{warn_unrecognized true} } {
upvar 1 $colls_ref  colls
upvar 1 $others_ref others
set others {}
array set colls {}
foreach obj_type_group [tcl_esc $target_types] {
set obj_type_master [lindex $obj_type_group 0]
set colls($obj_type_master) {}
}
foreach obj [tcl_esc $objs] {
set found false
if { [get_object_type $obj obj_type] } {
foreach obj_type_group [tcl_esc $target_types] {
set obj_type_master [lindex $obj_type_group 0]
if { [lsearch $obj_type_group $obj_type] >= 0 } {
lappend colls($obj_type_master) $obj
set found true
}
}
}
if { ! $found } {
if { $warn_unrecognized } {
warn "Unrecognized object $obj, must be $target_types"
}
lappend others $obj
}
}
}

# Find objects matching listed target_types
proc find_objects_by_type { objs others_ref target_types
{warn_unrecognized true} } {
upvar 1 $others_ref others
set find_net_pin false
set found_objs {}
foreach obj_type_group [tcl_esc $target_types] {
set others $objs
foreach obj_type [tcl_esc $obj_type_group] {
if { [is_null objs] } { break }
set obj_name [get_object_name $obj_type]
if { "$obj_name" != "clock" } { set find_net_pin true; }
set others0 {}
lconcat found_objs [find_${obj_name}s $objs others0 false false false false false false false]
set others [lintersect $others $others0]
}
set objs $others
}
global tcl_remove_quartus_column_name
if { $tcl_remove_quartus_column_name && [is_null found_objs] && $find_net_pin} {
set others {}
set found_nets [find_nets $objs others false false false false false false false]
set found_objs [find_net_pin_cmd $found_nets];
}
if { $warn_unrecognized && ! [is_null others] } {
foreach obj [tcl_esc $others] {
warn "Unrecognized object $obj, must be $target_types"
}
}
return $found_objs
}

# Find objects matching listed target_types, and then categorize to map basing on object type
proc find_and_collect_objects_by_type {objs colls_ref others_ref find_types {coll_types {}}
{warn_unrecognized true} } {
upvar 1 $colls_ref  colls
upvar 1 $others_ref others
if { [is_null coll_types] } {
set coll_types $find_types
}
set keeper [lsearch $find_types Keeper]
if { $keeper >= 0} {
set find_types [lreplace $find_types $keeper $keeper {Register Term}]
}
set keeper [lsearch $coll_types Keeper]
if { $keeper >= 0} {
set coll_types [lreplace $coll_types $keeper $keeper Register]
if { [lsearch $coll_types {Pin Term}] < 0 } {
set pin [lsearch $coll_types Pin]
if { $pin >= 0 } {
set coll_types [lreplace $coll_types $pin $pin {Pin Term}]
} else {
lappend coll_types {Pin Term}
}
}
}
set objs [flatten_list $objs]
set found_objs [find_objects_by_type $objs others $find_types $warn_unrecognized]
array set colls {}
collect_objects_by_type $found_objs colls ignores $coll_types true
}


###########################################################################


proc get_objects_from_args { arg_vals_ref obj_names arg_key \
{ is_required false } { is_empty_ok true } \
{ is_singular false } } {
upvar 1 $arg_vals_ref arg_vals
if { [string index $arg_key 0] == "-" } {
set key [string range $arg_key 1 end]
set obj_args [array_find_key arg_vals $arg_key]
} else {
set key $arg_key
set obj_args $arg_vals
}

set found_objs {}
if { ! [is_null obj_args] } {
set found_objs {}
set others {}
foreach obj_name [tcl_esc $obj_names] {
lconcat found_objs [find_${obj_name}s $obj_args others false false false false false false false]
set obj_args $others
}
#foreach obj [tcl_esc $others] {
#  warn "Unrecognized object $obj, must be $obj_names"
#}
}
if { [is_null found_objs] && $is_required || \
!$is_empty_ok && [llength $found_objs] == 0 } {
warn "Empty -$key specified, objects $obj_args are not recognized"
} elseif { $is_singular && [llength $found_objs] > 1 } {
warn "Multiple ${key}s specified"
}
return $found_objs
}

proc get_object_from_args { arg_vals_ref obj_name arg_key
{ is_required false }  { is_empty_ok true }} {
upvar 1 $arg_vals_ref arg_vals
set is_singular true
set found_objs [get_objects_from_args arg_vals $obj_name $arg_key \
$is_required $is_empty_ok $is_singular]
if { [llength $found_objs] > 0 } {
return [lindex $found_objs 0]
} else {
return ""
}
}


###########################################################################


array set cmd_usages {}
proc define_cmd_and_usage { cmd cmd_usage } {
global cmd_usages
set cmd_usages($cmd) $cmd_usage
namespace export $cmd
}

proc define_cmd { cmd cmd_usage={} } {
namespace export $cmd
}

proc define_cmd_alias { alias cmd } {
eval "proc $alias { args } { eval \"$cmd \$args\" }"
namespace export $alias
}

proc cmd_usage_error { cmd } {
global cmd_usages
if [info exists cmd_usages($cmd)] {
help $cmd
} else {
error "Usage: $cmd argument error"
}
}


###########################################################################


set command_message_header {""}
proc set_current_command { cmd } {
global command_message_header
stack_push command_message_header "\[$cmd\] "
}
proc reset_current_command {} {
global command_message_header
stack_pop command_message_header
}
proc current_command_header {} {
global command_message_header
return [stack_top command_message_header]
}

proc error_cmd { msg } {
if { "$msg" != "" } {
tcl_error "[current_command_header]$msg"
}
}

proc warn { msg } {
if { "$msg" != "" } {
tcl_warn "[current_command_header]$msg"
}
}

proc error_if_not_float_with_unit { str {msg ""} {cond ""} } {
if { [check_is_float_with_unit $str] &&
([is_null cond] || [uplevel 1 eval expr $cond]) } {
} else {
if { [is_null msg] } {
error "Expect a float value, but got $str"
} else {
error "$msg, but got $str"
}
}
}
proc error_if_not_float { str {msg ""}  {cond ""} } {
if { [check_is_float $str] &&
([is_null cond] || [uplevel 1 eval expr $cond]) } {
} else {
if { [is_null msg] } {
error "Expect a float value, but got $str"
} else {
error "$msg, but got $str"
}
}
}
proc error_if_not_int { str {msg ""} {cond ""} } {
if { [check_is_int $str] &&
([is_null cond] || [uplevel 1 eval expr $cond]) } {
} else {
if { [is_null msg] } {
error "Expect an integer value, but got $str"
} else {
error "$msg, but got $str"
}
}
}
proc error_if_not_floats_with_unit { strs {msg ""} } {
foreach str [tcl_esc $strs] { error_if_not_float_with_unit $str $msg }
}
proc error_if_not_floats { strs {msg ""} } {
foreach str [tcl_esc $strs] { error_if_not_float $str $msg }
}
proc error_if_not_ints { strs {msg ""} } {
foreach str [tcl_esc $strs] { error_if_not_int $str $msg }
}

proc error_if_not_scalar { scalar {msg ""} } {
if { [llength $scalar] != 1 } {
if { [is_null msg] } {
error "Expect a scalar value, but got size of [llength $scalar]"
} else {
error "$msg, but got size of [llength $scalar]"
}
}
}
proc error_if_not_size { vals min_sz max_sz {msg ""} } {
if { [llength $vals] < $min_sz || [length $vals] > $max_sz] } {
if { [is_null msg] } {
error "Expect a list size between $min_sz and $max_sz, but got size of [llength $vals]"
} else {
error "$msg, but got size of [llength $vals]"
}
}
}

proc warn_unsupported { features {msg ""} } {
if { [is_null msg] } {
warn "unsupported feature: $features"
} else {
warn "$msg, unsupported feature: $features"
}
}
proc error_unsupported { features {msg ""} } {
if { [is_null msg] } {
error "Unsupported feature: $features"
} else {
error "$msg, unsupported feature: $features"
}
}

proc proc_tect { proc_name args body {pre {skip}} {post {skip}}} {
set proc_body \
"proc $proc_name { $args } { \
set_current_command \"$proc_name\"; \
global sh_continue_on_error; \
global sh_verbose_on_error; \
global errorCode errorInfo; \
set is_redirect \[check_redirect args\]; \
set ret true; \
set code \[catch { eval $pre; $body; eval $post } ret \]; \
if { \$is_redirect } { end_redirect }; \
if { \$code == 1 } { \
if { \"\$errorCode\" == \"ERROR_EXIT\" } { reset_current_command; error_exit }; \
error_cmd \$ret; \
if { \$sh_verbose_on_error } { tcl_print_err \"\$errorInfo \n\"}; \
if { ! \$sh_continue_on_error } { exit -1; }
if { \"\$errorCode\" == \"FATAL_EXIT\" } { reset_current_command; error_exit }; \
set ret false; \
}; \
eval $post; \
reset_current_command; \
return \$ret \
}"

eval $proc_body
}

proc proc_arched { proc_name args body } {
proc_tect $proc_name "$args" "$body" { \
set devs [llength [get_device_infos_cmd]]; \
if { $devs == 0 } { \
load_architect -no_build; \
} \
}
}

proc proc_linked { proc_name args body } {
proc_tect $proc_name "$args" "$body" {design_assert_linked_cmd}
}

proc proc_packed { proc_name args body } {
proc_tect $proc_name "$args" "$body" {design_assert_packed_cmd}
}

proc proc_linked_or_packed { proc_name args body } {
proc_tect $proc_name "$args" "$body" {design_assert_linked_or_packed_cmd}
}

proc proc_placed { proc_name args body } {
proc_tect $proc_name "$args" "$body" {design_assert_placed_cmd}
}

proc proc_routed { proc_name args body } {
proc_tect $proc_name "$args" "$body" {design_assert_routed_cmd}
}

proc proc_toptile { proc_name args body } {
proc_tect $proc_name "$args" "$body" {toptile_assert_built_cmd}
}
proc proc_packed_toptile { proc_name args body } {
proc_tect $proc_name "$args" "$body" {design_assert_packed_cmd; toptile_assert_built_cmd}
}

proc check_redirect {args_ref} {
upvar 1 $args_ref args
set type  [lindex $args end-1]
set fname [lindex $args end]
set is_append    false
set is_overwrite false
set is_err       false
if { [is_null type] || [is_null fname] } {
return false
}

if { $type == ">" } {
} elseif { $type == ">>" } {
set is_append    true
} elseif { $type == ">!" } {
set is_overwrite true
} elseif { $type == ">>!" } {
set is_append    true
set is_overwrite true
} elseif { $type == ">&" } {
set is_err       true
} elseif { $type == ">>&" } {
set is_append    true
set is_err       true
} elseif { $type == ">!&" || \
$type == ">&!" } {
set is_overwrite true
set is_err       true
} elseif { $type == ">>!&" || \
$type == ">>&!" } {
set is_append    true
set is_overwrite true
set is_err       true
} else {
return false
}
set args [lrange $args 0 end-2]
return [begin_redirect $fname $is_append $is_overwrite $is_err]
}


###########################################################################


proc echo_source { filename {is_echo true} {is_quiet false} {prompt {"> " "> "}} {progress_inc 0} } {
set fp [open $filename]
info script $filename
set line_no 0
set cmd {}
set ecd {}
set prompt1 ""
set prompt2 ""
if { [llength $prompt] >= 1} {
set prompt1 [lindex $prompt 0]
} elseif { [llength $prompt] >= 2} {
set prompt2 [lindex $prompt 1]
}

while { [gets $fp line] >= 0 } {
incr line_no
if { $progress_inc > 0 && [expr $line_no%$progress_inc] == 0 } {
puts "...$line_no"
}
set cmd "${cmd}$line\n"
if { $ecd == {} } {
set ecd "${ecd}${prompt1}$line\n"
} else {
set ecd "${ecd}${prompt2}$line\n"
}

if { [info complete $cmd] } {
if { $is_echo } {
if { $is_quiet } { set was_silent [tcl_silent true]; }
tcl_print "$ecd"; tcl_flush;
if { $is_quiet } { tcl_silent $was_silent; }
}
set code [catch [list uplevel 1 $cmd] ret]
if { $code == 1 } {
if { "$ret" != "" } { tcl_error "$ret" }
tcl_print "while evaluationg {$filename:$line_no [string trimright $cmd \n]}\n"
error ""
}
set cmd {}
set ecd {}
}
}
close $fp
}

proc check_variable_exist { args } {
foreach arg [tcl_esc $args] {
if { ![upleve 1 info exist $arg] } {
tcl_error "The required variable $arg is not defined"
}
}
}

proc check_variable_null { args } {
foreach arg [tcl_esc $args] {
if { [[upleve 1 is_null $arg] } {
tcl_error "The required variable $arg is not defined or is empty"
}
}
}

define_cmd_and_usage "date_time" {}
proc date_time {} {
print_date_time
}

define_cmd_and_usage "cat" {[-n] file}
proc_tect cat { args } {
array set templs {
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
set fp [open $filename]
fcopy $fp stdout
close $fp
}

define_cmd_and_usage "print" {file}
proc_tect print { args } {
array set templs {
-nonewline  0
}
set message [parse_cmd_args $args templs arg_vals 1 1]

set is_nonewline [array_has_key arg_vals -nonewline]
tcl_print $message
if { ! $is_nonewline } { tcl_print "\n" }
}

define_cmd_and_usage "source" {[-echo] [-quiet] [-prompt prompt] [-progress progress_inc] filename}
proc_tect source { args } {
global sh_echo_on_source
global sh_quiet_on_source
array set templs {
-echo       0
-quiet      0
-prompt     1
-progress   1
}
set filename [parse_cmd_args $args templs arg_vals 1 1]

set is_echo   [expr [array_has_key arg_vals -echo  ] || $sh_echo_on_source ]
set is_quiet  [expr [array_has_key arg_vals -quiet ] || $sh_quiet_on_source]
set prompt {"> "  "> "}
if { [array_has_key arg_vals -prompt] } {
set prompt [array_find_key arg_vals -prompt]
}
set progress_inc 0
if { [array_has_key arg_vals -progress] } {
set progress_inc [array_find_key arg_vals -progress]
}

if { ! $is_echo && ! $is_quiet && $progress_inc == 0 } {
uplevel 1 [list tcl_source $filename]
} else {
uplevel 1 [list alta::echo_source $filename $is_echo $is_quiet $prompt $progress_inc]
}
}

define_cmd_and_usage "help" {[cmd]}
proc_tect help { args } {
global cmd_usages
set arg_sz [llength $args]
if { $arg_sz == 0 } { set args "*" }
foreach arg [tcl_esc $args] {
set cmds [array names cmd_usages -glob $arg]
if { [is_null cmds] } {
set cmds [array names cmd_usages -glob $arg*]
}
if { ! [is_null cmds] } {
foreach cmd [tcl_esc [lsort $cmds]] {
print_cmd_usage $cmd $cmd_usages($cmd)
}
} else {
error "Can not find such command: $args"
}
}
}

proc print_cmd_usage { cmd cmd_usage } {
set line_sz 100
set indent "  "
set indent_sz [string length $indent]
tcl_print $cmd
set line_col [string length $cmd]
while {1} {
if { [regexp {(^ *)([\[\]<>a-zA-Z0-9_\|\-]+)(.*)} \
$cmd_usage head blank arg tail] } {
set arg_sz [string length $arg]
if { $line_col + $arg_sz < $line_sz } {
tcl_print " $arg"
set line_col [expr $line_col + $arg_sz + 1]
} else {
tcl_print "\n"
tcl_print "$indent $arg"
set line_col [expr $indent_sz + $arg_sz + 1]
}
set cmd_usage $tail
} else {
tcl_print "\n"
break
}
}
}

define_cmd_and_usage "help_variable" {[cmd]}
proc_tect help_variable { args } {
set tcl_vars [get_tcl_variables_cmd]
set arg_sz [llength $args]
if { $arg_sz == 0 } { set args "*" }
foreach arg [tcl_esc $args] {
set vars [lsearch -glob -all -inline $tcl_vars $arg]
if { ! [is_null vars] } {
foreach var [tcl_esc [lsort $vars]] {
if { [string match cc_tclvar_test_* $var] } { continue }
set gvar ::$var
eval set val $$gvar
tcl_print "$var \t= $val\n"
}
} else {
error "Can not find such variable: $args"
}
}
}


####################################################################################
# is_object_of_instance, of_pin ...
foreach obj_type [tcl_esc $OBJ_TYPES] {
set obj_name [get_object_name $obj_type]
set proc_body " \
proc is_object_of_${obj_name} { obj } { \
return \[is_object_of_type \$obj $obj_type\] \
}"
eval $proc_body
}

# Define get_ cmds and find_ names
foreach obj_type [tcl_esc $OBJ_TYPES] {
set obj_name   [get_object_name   $obj_type]
set obj_cmd    [get_object_cmd    $obj_type]
set obj_column [get_object_column $obj_type]
if { ! [is_null obj_name] } {
set proc_bodys \
"\
proc find_${obj_name} { arg val_ref {is_nocase false} {is_regexp false} {is_exact false} \
{is_leaf_only false} {is_hier false} {is_exclude false} } { \
global tcl_remove_quartus_column_name; \
set remove_column \[expr \$tcl_remove_quartus_column_name && $obj_column]; \
upvar 1 \$val_ref val; \
if { \[is_object_of_type \$arg $obj_type\] } { \
set val \$arg; \
return true \
} elseif { \[get_object_type \$arg obj_key\] } { \
return false \
} else { \
set is_wildcard false; \
if { ! \$is_regexp && ! \$is_exact && \[has_wildcard \$arg\] } { \
set is_wildcard true \
}; \
set match_flags \[list \"\$arg\" \$is_nocase \$is_regexp \$is_wildcard \$is_exclude \$remove_column\]; \
set val \[find_${obj_name}_cmd \$match_flags \$is_leaf_only \$is_hier\]; \
if { \[is_null val\] } { \
return false \
} else { \
return true \
} \
} \
}; \
proc find_${obj_name}s { args others_ref {is_nocase false} {is_regexp false} {is_exact false} \
{is_leaf_only false} {is_hier false} {is_exclude false} {warn_unrecognized true} } { \
upvar 1 \$others_ref others; \
set others {}; \
set args \[straighten_list \$args\]; \
if { \[llength \$args\] == 1 } { \
if { \[find_${obj_name} \$args val \$is_nocase \$is_regexp \$is_exact \$is_leaf_only \$is_hier \$is_exclude\] } { \
return \$val \
} else { \
lappend others \$args; \
return {} \
} \
} else { \
set vals {}; \
foreach arg \[tcl_esc \$args\] { \
lconcat vals \[find_${obj_name}s \$arg this_others \$is_nocase \$is_regexp \$is_exact \
\$is_leaf_only \$is_hier \$is_exclude \$warn_unrecognized\]; \
lconcat others \$this_others \
}; \
return \$vals; \
} \
} \
"
eval $proc_bodys
}
if { ! [is_null obj_cmd] && ! [is_null obj_name] } {
set proc_bodys \
"\
define_cmd_and_usage \"get_${obj_cmd}s\" {\[-quiet\] \[-nocase\] \[-exact\] \[-nowarn\] \[-regexp\] \[-exclude\] ${obj_cmd}_list}; \
proc_linked get_${obj_cmd}s { args } { \
array set templs { \
-quiet            0 \
-nocase           0 \
-exact            0 \
-regexp           0 \
-leaf             0 \
-hierarchical     0 \
-exclude          0 \
-nowarn           0 \
-no_duplicates    0 \
-compatibility_mode 0 \
}; \
set arg \[parse_cmd_args \$args templs arg_vals\]; \
set is_warn \[not \[or \[array_has_key arg_vals -quiet\] \[array_has_key arg_vals -nowarn\]\]\]; \
set is_nocase \[array_has_key arg_vals -nocase\]; \
set is_regexp \[array_has_key arg_vals -regexp\]; \
set is_exact  \[array_has_key arg_vals -exact\]; \
set is_leaf_only \[array_has_key arg_vals -leaf\]; \
set is_hier      \[array_has_key arg_vals -hierachical\]; \
set is_exclude   \[array_has_key arg_vals -exclude\]; \
if { \[llength \$arg\] == 0 } { \
set arg \"*\" \
}; \
set found_objs \[find_${obj_name}s \$arg ignores \$is_nocase \$is_regexp \$is_exact \$is_leaf_only \$is_hier \$is_exclude \$is_warn\]; \
set find_net_pin [expr \"${obj_name}\" != \"clock\"]
global tcl_remove_quartus_column_name; \
if { \$tcl_remove_quartus_column_name && \[is_null found_objs\] && \$find_net_pin } { \
set found_nets \[find_nets \$arg ignores \$is_nocase \$is_regexp \$is_exact \$is_leaf_only true \$is_exclude \$is_warn\]; \
set found_objs \[find_net_pin_cmd \$found_nets\]; \
}; \
if { \$is_warn && \[is_null found_objs\] } { \
warn \"Can not find ${obj_name} \$args\"; \
}; \
return \$found_objs; \
} \
"
eval $proc_bodys

}
}

define_cmd_and_usage "get_keepers" {[-no_duplicates] [-nocase] [-nowarn] keeper_list}
proc_tect get_keepers { args } {
array set templs {
-nocase           0
-nowarn           0
-no_duplicates    0
};
set obj_list [parse_cmd_args $args templs arg_vals 1 1024]
set is_warn [not [array_has_key arg_vals -nowarn]]
set is_nocase [array_has_key arg_vals -nocase]

global tcl_remove_quartus_column_name;
set keepers {}
foreach obj $obj_list {
set     found_objs [find_terms $obj others $is_nocase false false false false false false]
lconcat found_objs [find_regs  $obj others $is_nocase false false false false false false]
if { $tcl_remove_quartus_column_name && [is_null found_objs] } {
set found_nets [find_nets $obj others $is_nocase false false false true false false]
set found_objs [find_net_pin_cmd $found_nets]
}
if { [is_null found_objs] } {
if { $is_warn } {
warn "Unrecognized keeper $obj"
}
} else {
lconcat keepers $found_objs
}
}
return $keepers
}

define_cmd_and_usage "all_clocks" {}
proc_linked_or_packed all_clocks { args } {
return [get_clocks *]
}

define_cmd_and_usage "all_inputs" {}
proc_linked_or_packed all_inputs { args } {
set inputs []
foreach term [get_ports *] {
if {[[$term port] isAnyInput]} {
lappend inputs $term
}
}
return $inputs
}

define_cmd_and_usage "all_outputs" {}
proc_linked_or_packed all_outputs { args } {
set outputs []
foreach term [get_ports *] {
if {[[$term port] isAnyOutput]} {
lappend outputs $term
}
}
return $outputs
}

define_cmd_and_usage "all_registers" {}
proc_linked_or_packed all_registers { args } {
return [get_registers *]
}

define_cmd_and_usage "seed_rand" {[number]}
proc_tect seed_rand { args } {
array set templs {
}
set seed [parse_cmd_args $args templs arg_vals 0 1]
if { [llength $seed] == 0 } {
set seed 0
}
seed_rand_cmd $seed
}

}; # namespace alta
namespace eval alta {

proc adjust_crit_weight { var_str ratio } {
set rr $ratio
foreach pp "pa pl rt" {
set CC ::${pp}_${var_str}; eval set cc $$CC
eval global $CC
set $CC \
"[lindex $cc 0] [lindex $cc 1] [expr [lindex $cc 2]*$rr] [expr [lindex $cc 3]*$rr]"
}
}

if { 0 } {
define_cmd_and_usage "set_property" \
{[-fit_factor factor] [-par_factor factor] [-fmax_factor factor] \
[-pack_effort level] [-place_effort level] [-route_effort level] \
[-hold_effort level]}

proc_tect set_property { args } {
array set templs {
-fit_factor   1
-par_factor   1
-fmax_factor  1
-pack_effort  1
-place_effort 1
-route_effort 1
-hold_effort  1
}
parse_cmd_args $args templs arg_vals 0 0

# Fitability : 9
if { [array_has_key arg_vals -fit_factor] } {
set factor [array_find_key arg_vals -fit_factor]
error_if_not_int $factor "-fit_factor factor must be a 0 to 10 integer" \
{$factor >= 0 && $factor <= 10}
if { $factor >= 10 } {
set ::pa_routability_level 0
} elseif { $factor >= 6 } {
set ::pa_routability_level 0
} elseif { $factor >= 3 } {
set ::pa_routability_level 1
} else {
set ::pa_routability_level 2
}
}

# Routability : 5
if { [array_has_key arg_vals -par_factor] } {
set factor [array_find_key arg_vals -par_factor]
error_if_not_int $factor "-par_factor factor must be a 0 to 10 integer" \
{$factor >= 0 && $factor <= 10}
if { $factor >= 10 } { # ZZZ
set ::pl_routability_level 3
set ::rt_routability_level 3
adjust_crit_weight critical_crit_weight 1.5
} elseif { $factor >= 6 } {
set ::pl_routability_level 2
set ::rt_routability_level 2
} elseif { $factor >= 3 } {
set ::pl_routability_level 1
set ::rt_routability_level 1
} else {
set ::pl_routability_level 0
set ::rt_routability_level 0
}
}

# Performance : 9
if { [array_has_key arg_vals -fmax_factor] } {
set factor [array_find_key arg_vals -fmax_factor]
error_if_not_int $factor "-fmax_factor factor must be a 0 to 10 integer" \
{$factor >= 0 && $factor <= 20}
set ta_report_auto_constraints 1
set ::ta_auto_constraint 1
if { $factor >= 10 } { # ZZZ
set ext_rate [expr $factor-10+2]
set ::pr_criticality_ratio 1.0
set ::pr_auto_crit_ratio "[lindex $::pr_auto_crit_ratio 0] \
[expr [lindex $::pr_auto_crit_ratio 1]/$ext_rate]"
} elseif { $factor >= 9 } {
set ::pr_criticality_ratio 1.0
} elseif { $factor >= 7 } {
set ::pr_criticality_ratio 0.75
} elseif { $factor >= 5 } {
set ::pr_criticality_ratio 0.50
} elseif { $factor >= 3 } {
set ::pr_criticality_ratio 0.25
} elseif { $factor >= 1} {
set ::pr_criticality_ratio 0.0
} else { # ZZZ
set ::pr_criticality_ratio 0.0
set ::ta_auto_constraint 2
adjust_crit_weight clock_crit_weight 1.5
}
}

# Pack effort : 0
#  pa_effort_level : 0<->2 :  0
if { [array_has_key arg_vals -pack_effort] } {
set level [array_find_key arg_vals -pack_effort]
error_if_not_int $level "-pack_effort level must be a 0 to 5 integer" \
{$level >= 0 && $level <= 5}
if { $level >= 5 } {
set ::pa_effort_level 2
} elseif { $level >= 4 } {
set ::pa_effort_level 2
} elseif { $level >= 2 } {
set ::pa_effort_level 1
} else {
set ::pa_effort_level 0
}
}

# Place effort : 2
#  pl_effort_level : 0<->4 :  2
if { [array_has_key arg_vals -place_effort] } {
set level [array_find_key arg_vals -place_effort]
error_if_not_int $level "-place_effort level must be a 0 to 5 integer" \
{$level >= 0 && $level <= 5}
if { $level >= 5 } {
set ::pl_effort_level 4
} elseif { $level >= 4 } {
set ::pl_effort_level 4
} elseif { $level >= 3 } {
set ::pl_effort_level 3
} elseif { $level >= 2 } {
set ::pl_effort_level 2
} elseif { $level >= 1 } {
set ::pl_effort_level 1
} else {
set ::pl_effort_level 0
}
}

# Route effort : 1
#  rt_effort_level : 0<->3 :  1
if { [array_has_key arg_vals -route_effort] } {
set level [array_find_key arg_vals -route_effort]
error_if_not_int $level "-route_effort level must be a 0 to 5 integer" \
{$level >= 0 && $level <= 5}
if { $level >= 5 } {
set ::rt_effort_level 3
} elseif { $level >= 4 } {
set ::rt_effort_level 3
} elseif { $level >= 2 } {
set ::rt_effort_level 2
} elseif { $level >= 1 } {
set ::rt_effort_level 1
} else {
set ::rt_effort_level 0
}
}

# Hold fix : 1
#  rt_hold_fix_level  : 0
if { [array_has_key arg_vals -hold_effort] } {
set level [array_find_key arg_vals -hold_effort]
error_if_not_int $level "-hold_effort level must be a 0 to 5 integer" \
{$level >= 0 && $level <= 5}
if { $level >= 5 } { # ZZZ
set ::rt_hold_fix_level 3
set ::rt_net_hold_fix_auto true
} elseif { $level >= 4 } {
set ::rt_hold_fix_level 3
} elseif { $level >= 3 } {
set ::rt_hold_fix_level 2
} elseif { $level >= 2 } {
set ::rt_hold_fix_level 1
} elseif { $level >= 1 } {
set ::rt_hold_fix_level 0
} else {
set ::rt_hold_fix_level -1
}
}
}
}

define_cmd_and_usage "set_mode" \
{[-fitting auto|basic|routing|routing_more|timing|timing_more] \
[-fitter basic|semi|hybrid|full] \
[-effort basic|high|highest] \
[-holdx  default|basic|IO|advanced|aggressive] \
[-tuning basic|sharp|sharpest|soft|softest] \
[-skew basic|advanced|aggressive|boosted] \
[-skope all|core|logic] \
[-target base|near|medium|far] \
[-preset basic|usera1|usera2|usera3|userb1|userb2|userb3]}

proc_tect set_mode { args } {
array set templs {
-fitting   1
-fitter    1
-effort    1
-holdx     1
-tuning    1
-skew      1
-skope     1
-target    1
-preset    1
}
parse_cmd_args $args templs arg_vals 0 0

set setting_dir "[prog_home]/etc/settings"

if { [array_has_key arg_vals -fitting] } {
set fitting [array_find_key arg_vals -fitting]
if { $fitting == "auto" } {
set utilization [alta::get_design_utilization_cmd]
if { $utilization < [expr 0.50] } {
set fitting timing
} elseif { $utilization > [expr 1.00] } {
set fitting routing
} else {
set fitting basic
}
}
if { $fitting == "basic" } {
uplevel #0 source \"${setting_dir}/fitting_basic0.tcl\"
} elseif { $fitting == "routing" } {
uplevel #0 source \"${setting_dir}/fitting_routingA.tcl\"
} elseif { $fitting == "routing_more" } {
uplevel #0 source \"${setting_dir}/fitting_routingB.tcl\"
} elseif { $fitting == "timing" } {
uplevel #0 source \"${setting_dir}/fitting_timing1.tcl\"
} elseif { $fitting == "timing_more" } {
uplevel #0 source \"${setting_dir}/fitting_timing2.tcl\"
} else {
warn "Unknow -fitting $fitting"
}
}

if { [array_has_key arg_vals -fitter] } {
set fitter [array_find_key arg_vals -fitter]
if { $fitter == "basic" } {
uplevel #0 source \"${setting_dir}/fitter_basic0.tcl\"
} elseif { $fitter == "semi" } {
uplevel #0 source \"${setting_dir}/fitter_semi1.tcl\"
} elseif { $fitter == "hybrid" } {
uplevel #0 source \"${setting_dir}/fitter_hybrid2.tcl\"
} elseif { $fitter == "full" } {
uplevel #0 source \"${setting_dir}/fitter_full3.tcl\"
} else {
warn "Unknow -fitter $fitter"
}
}

if { [array_has_key arg_vals -effort] } {
set effort [array_find_key arg_vals -effort]
if { $effort == "basic" } {
uplevel #0 source \"${setting_dir}/effort_basic0.tcl\"
} elseif { $effort == "high" } {
uplevel #0 source \"${setting_dir}/effort_high1.tcl\"
} elseif { $effort == "highest" } {
uplevel #0 source \"${setting_dir}/effort_highest2.tcl\"
} else {
warn "Unknow -effort $effort"
}
}

if { [array_has_key arg_vals -skew] } {
set skew [array_find_key arg_vals -skew]
if { $skew == "basic" } {
uplevel #0 source \"${setting_dir}/skew_basic0.tcl\"
} elseif { $skew == "advanced" } {
uplevel #0 source \"${setting_dir}/skew_advanced1.tcl\"
} elseif { $skew == "aggressive" } {
uplevel #0 source \"${setting_dir}/skew_aggressive2.tcl\"
} elseif { $skew == "boosted" } {
uplevel #0 source \"${setting_dir}/skew_boosted3.tcl\"
} else {
warn "Unknow -skew $skew"
}
}

if { [array_has_key arg_vals -skope] } {
set skope [array_find_key arg_vals -skope]
if { $skope == "all" } {
uplevel #0 source \"${setting_dir}/skope_all.tcl\"
} elseif { $skope == "core" } {
uplevel #0 source \"${setting_dir}/skope_core.tcl\"
} elseif { $skope == "logic" } {
uplevel #0 source \"${setting_dir}/skope_logic.tcl\"
} else {
warn "Unknow -skope $skope"
}
}

if { [array_has_key arg_vals -holdx] } {
set holdx [array_find_key arg_vals -holdx]
if { $holdx == "default" } {
uplevel #0 source \"${setting_dir}/holdx_default0.tcl\"
} elseif { $holdx == "basic" } {
uplevel #0 source \"${setting_dir}/holdx_basic1.tcl\"
} elseif { $holdx == "IO" } {
uplevel #0 source \"${setting_dir}/holdx_io2.tcl\"
} elseif { $holdx == "advanced" } {
uplevel #0 source \"${setting_dir}/holdx_advanced3.tcl\"
} elseif { $holdx == "aggressive" } {
uplevel #0 source \"${setting_dir}/holdx_aggressive4.tcl\"
} else {
warn "Unknow -holdx $holdx"
}
}

if { [array_has_key arg_vals -tuning] } {
set tuning [array_find_key arg_vals -tuning]
if { $tuning == "basic" } {
uplevel #0 source \"${setting_dir}/tuning_basic0.tcl\"
} elseif { $tuning == "sharp" } {
uplevel #0 source \"${setting_dir}/tuning_sharp1.tcl\"
} elseif { $tuning == "sharpest" } {
uplevel #0 source \"${setting_dir}/tuning_sharpest2.tcl\"
} elseif { $tuning == "soft" } {
uplevel #0 source \"${setting_dir}/tuning_softA.tcl\"
} elseif { $tuning == "softest" } {
uplevel #0 source \"${setting_dir}/tuning_softestB.tcl\"
} else {
warn "Unknow -tuning $tuning"
}
}

if { [array_has_key arg_vals -target] } {
set target [array_find_key arg_vals -target]
if { $target == "near" } {
uplevel #0 source \"${setting_dir}/target_near0.tcl\"
} elseif { $target == "basic" } {
uplevel #0 source \"${setting_dir}/target_basic1.tcl\"
} elseif { $target == "medium" } {
uplevel #0 source \"${setting_dir}/target_medium2.tcl\"
} elseif { $target == "far" } {
uplevel #0 source \"${setting_dir}/target_far3.tcl\"
} else {
warn "Unknow -target $target"
}
}

if { [array_has_key arg_vals -preset] } {
set preset [array_find_key arg_vals -preset]
if { $preset == "basic" } {
uplevel #0 source \"${setting_dir}/preset_basic0.tcl\"
} elseif { [string range "$preset" 0 3] == "user" } {
uplevel #0 source \"${setting_dir}/preset_${preset}.tcl\"
} else {
warn "Unknow -preset $preset"
}
}
}

define_cmd_and_usage "set_seed_rand" {seed}

proc_tect set_seed_rand { args } {
array set templs {
}
set seed [parse_cmd_args $args templs arg_vals 1 1]

if { $seed == 0 } {
} elseif { $seed > 100 } {
} else {
set ::pa_randomize false
set ::pl_randomize false
set ::rt_randomize false
}
seed_rand $seed
}

define_cmd_and_usage "check_design" \
{-rule led_guide}

proc_tect check_design { args } {
array set templs {
-rule      1
}
parse_cmd_args $args templs arg_vals 0 0

set setting_dir "[prog_home]/etc/settings"

set rule "base"
if { [array_has_key arg_vals -rule] } {
set rule [array_find_key arg_vals -rule]
}

if { $rule == "base" || $rule == "led_guide" } {
uplevel #0 source \"${setting_dir}/rule_${rule}.tcl\"
} else {
warn "Unknown -rule $rule"
}
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "load_architect" {}
proc_tect load_architect {args} {
set arch_dir     "[prog_home]/etc/arch"
set ar_file      "alta.ar"
set ar_file      "$arch_dir/$ar_file"

array set templs {
-type                1
-no_route            0
-no_build            0
-route_segs          0
}
set coords [parse_cmd_args $args templs arg_vals {0 4}]
if { [llength $coords] == 0 } {
set coords {0 0 0 0}
}
set device_type "X"
if { [array_has_key arg_vals -type] } {
set device_type [array_find_key arg_vals -type]
}

if { [llength [get_device_infos_cmd]] > 0 } {
delete_architect
}
set ret [read_architect $ar_file]
if { !$ret } { fatal "Failed to load device $device_type" }
if { [array_has_key arg_vals -no_build] } {
return $ret
}
set ret [build_top_array_cmd $device_type \
[lindex $coords 0] [lindex $coords 1] \
[lindex $coords 2] [lindex $coords 3] \
$arch_dir]
if { !$ret } { fatal "Failed to build device $device_type" }

set top_array [get_top_array_cmd]
set class_dir   [$top_array  class_dir]
set family_dir  [$top_array family_dir]
set source_dir  [$top_array source_dir]

set device_info [$top_array device_info]
set char_derate [$device_info char_derate]
set core_type   [$device_info core]
set org_timing_derate $::ar_timing_derate
set ::ar_timing_derate [expr $org_timing_derate * $char_derate]

set ar_lib   "alta_lib.ar"
set pr_lib   "primitive.ar"
set ar_wire  "alta_wire.ar"
set route_table "route.$core_type.bar.gz"
set ar_lib   "$source_dir/$ar_lib"
set pr_lib   "$source_dir/$pr_lib"
set ar_wire  "$source_dir/$ar_wire"
set route_table "$class_dir/route/$route_table"

puts "Loading architect libraries..."
read_architect $ar_lib
read_architect $pr_lib
# wire timing info must be read after array is built
read_architect $ar_wire
print_usage_cmd
if { ![array_has_key arg_vals -no_route] } {
puts "Loading route table..."
if { [array_has_key arg_vals -route_segs] } {
load_route_table -route_segs $route_table
} else {
load_route_table $route_table
}
print_usage_cmd
}
set ::ar_timing_derate $org_timing_derate
}

define_cmd_and_usage "delete_architect" {}
proc_tect delete_architect { args } {
delete_architect_cmd
}

define_cmd_and_usage "build_tile" {}
proc_tect build_tile {args} {
build_tile_cmd
}

define_cmd_and_usage "delete_tile" {}
proc_tect delete_tile { args } {
delete_tile_cmd
}

define_cmd_and_usage "build_top_array" {[lx ly ux uy]}
proc_tect build_top_array {args} {
set arch_dir "[prog_home]/etc/arch"
array set templs {
-type 1
}
set coords [parse_cmd_args $args templs arg_vals 0 4]
if { [llength $coords] == 0 } {
set coords {0 0 0 0}
}
set chip_type "X"
if { [array_has_key arg_vals -type] } {
set chip_type [array_find_key arg_vals -type]
}

set ret [build_top_array_cmd $chip_type [lindex $coords 0] [lindex $coords 1] \
[lindex $coords 2] [lindex $coords 3] \
$arch_dir]
if { !$ret } { error "Failed to build device" }
return $ret
}

define_cmd_and_usage "delete_top_array" {}
proc_tect delete_top_array { args } {
delete_top_array_cmd
}

define_cmd_and_usage "get_current_device_type" { [-core] }
proc_tect get_current_device_type { args } {
array set templs {
-core 0
}
parse_cmd_args $args templs arg_vals 0 0
set cmd device_type
if { [array_has_key arg_vals -core] } {
set cmd core_type
}
set device_type ""
set top_array [get_top_array_cmd]
if { ! [is_null top_array] } {
set device_type [$top_array $cmd]
}
return $device_type
}

define_cmd_and_usage "get_device_pin_names" {}
proc_toptile get_device_pin_names {args} {
array set templs {
-all 0
}
parse_cmd_args $args templs arg_vals 0 0
set user_pin_only true
if { [array_has_key arg_vals -all] } {
set user_pin_only false
}
return [get_device_pin_names_cmd $user_pin_only]
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "generate_pll" \
{ module_name -pll_type type_name \
-input_freq frequency -output_freqs frequencies -fb_mode feedback_mode \
[-compensation_mode compensation_mode] \
[-output_phases phase_shifts] [-output_duties duty_cycles] \
[-use_diff_clkout0] [-use_ext_clkout0] \
}
define_cmd_and_usage "generate_memory" \
{ module_name -mem_type type_name \
-data_widths widths -address_depths depths \
[-port_dirs port_directions] [-clk_mode clock_mode] [-write_modes write_modes] \
[-output_regs output_registers] [-byte_enables byte_enables] \
[-init_file memory_init_file] [-init_port init_port] }

proc ip_not_specified_error { args } {
error "[lindex $args 0] not specified. Use [lindex $args 1] to specify."
}
proc check_not_specified_error { args } {
foreach item [lindex $args 1] {
if { "$item" == "" } { error "[lindex $args 0] cannot be empty" }
}
}

proc ip_mismatch_error { args } {
error "Argument [lindex $args 0] and [lindex $args 1] do not match."
}

proc_tect generate_pll { args } {
array set templs {
-pll_type          1
-input_freq        1
-output_freqs      1
-fb_mode           1
-compensation_mode 1
-output_phases     1
-output_duties     1
-use_diff_clkout0  0
-use_ext_clkout0   0
}
set module_name [parse_cmd_args $args templs arg_vals 1 1]

if { [array_has_key arg_vals -pll_type] } {
set type_name [array_find_key arg_vals -pll_type]
} else {
set type_name "alta_pll"
}
if { [array_has_key arg_vals -input_freq] } {
set input_freq [array_find_key arg_vals -input_freq]
} else {
ip_not_specified_error "Input frequency" -input_freq
}
if { [array_has_key arg_vals -output_freqs] } {
set output_freqs [array_find_key arg_vals -output_freqs]
} else {
ip_not_specified_error "Output frequencies" -output_freqs
}
check_not_specified_error "Output frequency" $output_freqs
if { [array_has_key arg_vals -fb_mode] } {
set fb_mode [array_find_key arg_vals -fb_mode]
} else {
ip_not_specified_error "Feedback mode" -fb_mode
}
set compensation_mode "normal"
if { [array_has_key arg_vals -compensation_mode] } {
set compensation_mode [array_find_key arg_vals -compensation_mode]
}
set output_phases {}
if { [array_has_key arg_vals -output_phases] } {
set output_phases [array_find_key arg_vals -output_phases]
}
set output_phases [lreplaces $output_phases {} {0}]
set output_duties {}
if { [array_has_key arg_vals -output_duties] } {
set output_duties [array_find_key arg_vals -output_duties]
}
set output_duties [lreplaces $output_duties {} {50}]
set use_diff_clkout0 false
if { [array_has_key arg_vals -use_diff_clkout0] } {
set use_diff_clkout0 true
}
set use_ext_clkout0 [array_has_key arg_vals -use_ext_clkout0]

set ret [generate_pll_cmd $module_name $type_name \
$input_freq $fb_mode $compensation_mode \
$output_freqs $output_phases $output_duties \
$use_diff_clkout0 $use_ext_clkout0]
if { !$ret } { fatal "Failed to generate PLL IP, check IP settings" }
return $ret
}

proc_tect generate_memory { args } {
array set templs {
-mem_type       1
-data_widths    1
-address_depths 1
-port_dirs      1
-clk_mode       1
-write_modes    1
-output_regs    1
-byte_enables   1
-init_file      1
-init_port      1
}
set module_name [parse_cmd_args $args templs arg_vals 1 1]

if { [array_has_key arg_vals -mem_type] } {
set mem_type [array_find_key arg_vals -mem_type]
} else {
ip_not_specified_error "Memory type" -mem_type
}
if { [array_has_key arg_vals -data_widths] } {
set data_widths [array_find_key arg_vals -data_widths]
} else {
ip_not_specified_error "Data widths" -data_widths
}
check_not_specified_error "Data width" $data_widths
if { [array_has_key arg_vals -address_depths] } {
set address_depths [array_find_key arg_vals -address_depths]
} else {
ip_not_specified_error "Address depths" -address_depths
}
check_not_specified_error "Address depth" $address_depths

# optional arguments:
set port_count [llength $data_widths]
if { $port_count == 1 } {
set port_dirs "inout"
} elseif { $port_count == 2 } {
set port_dirs { "input" "output" }
} else {
error "$port_count data ports specified. Only single and dual port memories are supported."
}
set clk_mode "read_write"
set write_modes { "normal" "normal" }
set output_regs { "no" "no" }
set byte_enables { "no" "no" }
set init_file ""
set init_port "a"

if { [array_has_key arg_vals -port_dirs] } {
set port_dirs [array_find_key arg_vals -port_dirs]
}
if { $port_count == 1 } {
set port_dirs [lreplaces $port_dirs {} {inout}]
} elseif { $port_count == 2 } {
if { [lsearch $port_dirs "input"] >= 0 } {
set port_dirs [lreplaces $port_dirs {} {output}]
}
if { [lsearch $port_dirs "output"] >= 0 } {
set port_dirs [lreplaces $port_dirs {} {input}]
}
if { [lsearch $port_dirs "inout"] >= 0 } {
set port_dirs [lreplaces $port_dirs {} {inout}]
}
}
if { [array_has_key arg_vals -clk_mode] } {
set clk_mode [array_find_key arg_vals -clk_mode]
}
if { [array_has_key arg_vals -write_modes] } {
set write_modes [array_find_key arg_vals -write_modes]
}
set write_modes [lreplaces $write_modes {} {normal}]
if { [array_has_key arg_vals -output_regs] } {
set output_regs [array_find_key arg_vals -output_regs]
}
set output_regs [lreplaces $output_regs {} {no}]
if { [array_has_key arg_vals -byte_enables] } {
set byte_enables [array_find_key arg_vals -byte_enables]
}
set byte_enables [lreplaces $byte_enables {} {no}]
if { [array_has_key arg_vals -init_file] } {
set init_file [array_find_key arg_vals -init_file]
}
if { [array_has_key arg_vals -init_port] } {
set init_port [array_find_key arg_vals -init_port]
}

if { [llength $address_depths] < $port_count } {
ip_mismatch_error -data_widths -address_depths
} elseif { [llength $port_dirs] < $port_count } {
ip_mismatch_error -data_widths -port_dirs
} elseif { [llength $write_modes] < $port_count } {
ip_mismatch_error -data_widths -write_modes
} elseif { [llength $output_regs] < $port_count } {
ip_mismatch_error -data_widths -output_regs
} elseif { [llength $byte_enables] < $port_count } {
ip_mismatch_error -data_widths -byte_enables
}

set ret  [generate_memory_cmd $module_name $mem_type \
$data_widths $address_depths $port_dirs \
$clk_mode $write_modes $output_regs $byte_enables \
$init_file $init_port]
if { !$ret } { fatal "Failed to generate memory IP, check IP settings" }
return $ret
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "read_architect" {filename}
proc_tect read_architect { args } {
array set templs {
}
set filename [parse_cmd_args $args templs arg_vals 1 1]

set ret [read_architect_cmd $filename]
if { !$ret } { ret "Encounter error while loading device database $filename" }
return $ret
}

define_cmd_and_usage "read_ip" {filename}
proc_tect read_ip { args } {
array set templs {
}
set filename [parse_cmd_args $args templs arg_vals 1 1]

set ret [read_architect_cmd $filename true]
if { !$ret } { error "encounter error while loading ip file $filename" }
return true
}

define_cmd "write_ip" {[filename]}
proc_tect write_ip { args } {
array set templs {
}
set filename [parse_cmd_args $args templs arg_vals 0 1]

if { ! [is_null filename] } {
write_ip_cmd $filename
} else {
write_ip_cmd
}
return true
}

define_cmd_and_usage "read_sdf" {filename}
proc_linked_or_packed read_sdf { args } {
array set templs {
-derate    1
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
set derate 1.0
if { [array_has_key arg_vals -derate] } {
set derate [array_find_key arg_vals -derate]
}

set ret [read_sdf_cmd $filename $derate]
if { !$ret } { error "Failed to read SDF file" }
return $ret
}

define_cmd_and_usage "link_design" {top_module}
proc_tect link_design { args } {
array set templs {}
set module_name [parse_cmd_args $args templs arg_vals 1 1]

set ret [link_design_cmd $module_name]
if { !$ret } { error "Failed to link design" }
return $ret
}

proc_tect link_chip { args } {
array set templs {}
set module_name [parse_cmd_args $args templs arg_vals 1 1]

set ret [link_chip_cmd $module_name]
if { !$ret } { error "Failed to link chip" }
return $ret
}

define_cmd "write_design" {[-linked|-packed] filename}
proc_tect write_design { args } {
array set templs {
-linked  0
-packed  0
-placed  0
-routed  0
-linked_with_pack 0
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
if { [array_has_key arg_vals -linked] } {
write_linked_design_cmd $filename
} elseif { [array_has_key arg_vals -packed] } {
write_packed_design_cmd $filename
} elseif { [array_has_key arg_vals -placed] } {
write_placed_design_cmd $filename
} elseif { [array_has_key arg_vals -routed] } {
write_routed_design_cmd $filename
} elseif { [array_has_key arg_vals -linked_with_pack] } {
write_linked_with_pack_design_cmd $filename
} else {
write_linked_design_cmd $filename
}
}

define_cmd_and_usage "write_routed_design" {filename}
proc_packed write_routed_design { args } {
array set templs {
-physical 0
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
set physical 0
if { [array_has_key arg_vals -physical] } {
set physical 1
}
write_routed_design_cmd $filename $physical
}

define_cmd "dump_design" {[-linked|-packed|-chip] [-library|-instance|-pin|-leaf|-net]}
proc_tect dump_design { args } {
array set templs {
-chip    0
-linked  0
-packed  0
-library  0
-instance 0
-pin      0
-leaf     0
-net      0
}
parse_cmd_args $args templs arg_vals 0 0
set library  [array_has_key arg_vals -library ]
set instance [array_has_key arg_vals -instance]
set pin      [array_has_key arg_vals -pin     ]
set leaf     [array_has_key arg_vals -leaf    ]
set net      [array_has_key arg_vals -net     ]
if { ! $library && ! $instance && ! $pin && ! $leaf && ! $net } {
set library  true
set instance true
set pin      true
set leaf     true
set net      true
}
if { [array_has_key arg_vals -chip] } {
dump_chip_design_cmd $library $instance $pin $leaf $net
} elseif { [array_has_key arg_vals -linked] } {
dump_linked_design_cmd $library $instance $pin $leaf $net
} else {
dump_packed_design_cmd $library $instance $pin $leaf $net
}
}

define_cmd "dump_coord" {[-place|-route] [-max_fanout]}
proc_packed dump_coord { args } {
array set templs {
-route      0
-place      0
-max_fanout 1
}
parse_cmd_args $args templs arg_vals 0 0
set max_fanout 50
if { [array_has_key arg_vals -max_fanout] } {
set max_fanout [array_find_key arg_vals -max_fanout]
}
if { [array_has_key arg_vals -route] } {
dump_route_coord_cmd $max_fanout
} else {
dump_place_coord_cmd
}
}

define_cmd "dump_place_info" {}
proc_packed_toptile dump_place_info { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0
dump_place_info_cmd
}

define_cmd "load_place_info" {filename}
proc_packed_toptile load_place_info { args } {
array set templs {
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
load_place_info_cmd $filename
}

define_cmd_and_usage "set_location_assignment" {-to location target}
proc_packed_toptile set_location_assignment { args } {
array set templs {
-disable   0
-to        1
-diff      0
}

set io_pad_name [parse_cmd_args $args templs arg_vals 1 1]
if { [array_has_key arg_vals -disable] } {
return
}

error_if_not_scalar $io_pad_name "can not assignment multiple IOs"

set tos [get_objects_from_args arg_vals {term inst} "-to" true true]
# error_if_not_scalar $to "have to specify exactly one port or cell"

set is_diff false
if { [array_has_key arg_vals -diff] } {
set is_diff true
}

if { [llength $tos] == 1 } {
set to [lindex $tos 0]
set_location_assignment_cmd $to $io_pad_name $is_diff
}
}

define_cmd "dump_location_assignments" {[target_list]}
proc_packed_toptile dump_location_assignments { args } {
array set templs {
}

set args [parse_cmd_args $args templs arg_vals 0 1]
if { [is_null args] } {
set args "*"
}
set tos [get_objects_from_args args {term inst} "to" false true false]

foreach to [tcl_esc $tos] {
set io_pad_name [get_location_assignment_cmd $to]
if { "$io_pad_name" != "" } {
tcl_print "set_location_assignment -to [$to name] ${io_pad_name}\n"
} elseif { [get_instance_assignment_cmd "VIRTUAL_PIN" false $to] == "" } {
warn "Location for IO [$to name] has not set yet"
}
}

return true
}

define_cmd "dump_io_standard_assignments" {[target_list]}
proc_packed_toptile dump_io_standard_assignments { args } {
array set templs {
}

set args [parse_cmd_args $args templs arg_vals 0 1]
if { [is_null args] } {
set args "*"
}
set tos [get_objects_from_args args {term inst} "to" false true false]

foreach to [tcl_esc $tos] {
set io_pad_name [get_io_standard_assignment_cmd $to]
if { "$io_pad_name" != "" } {
tcl_print "set_instance_assignment -name IO_STANDARD -to [$to name] \"${io_pad_name}\"\n"
}
}

return true
}

define_cmd "set_global_assignment" {-name assignment_type [-to target] value}
proc_toptile set_global_assignment { args } {
array set templs {
-disable    0
-name       1
-to         1
-extension  0
-section_id 1
-entity     1
-library    1
}
set value [parse_cmd_args $args templs arg_vals 1 1]
if { [array_has_key arg_vals -disable] } {
return
}

set name ""
if { [array_has_key arg_vals -name] } {
set name [array_find_key arg_vals -name]
} else {
error "Assignment type not specified, use -name to specify"
}
set to ""
if { [array_has_key arg_vals -to] } {
set to [array_find_key arg_vals -to]
}

set extension [array_has_key arg_vals -extension]

if { [info exist ::quartus(qip_path)] } {
if { [string toupper $name] == "SDC_FILE" } {
# SDC in qip files could be very complex. So do not use it directly. Only issue a message
# here and use the sdc from write_sdc command instead
tcl_info "Detected SDC file $value in IP [info script]"
} elseif { [string toupper $name] == "QIP_FILE" } {
set qip_path $::quartus(qip_path)
read_qip $value
set ::quartus(qip_path) $qip_path
}
return
}

set_global_assignment_cmd $name $extension $value $to
}

define_cmd "set_instance_assignment" {-name assignment_type [-to targets] [-extension] value}
proc_packed_toptile set_instance_assignment { args } {
array set templs {
-disable    0
-name       1
-to         1
-extension  0
}

set value [parse_cmd_args $args templs arg_vals 1 1]
if { [array_has_key arg_vals -disable] } {
return
}

set name ""
if { [array_has_key arg_vals -name] } {
set name [array_find_key arg_vals -name]
} else {
error "Assignment type not specified, use -name to specify"
}

set tos [get_objects_from_args arg_vals {term inst} "-to" true true]

set extension [array_has_key arg_vals -extension]

if { [info exist ::quartus(qip_path)] } {
return
}

foreach to [tcl_esc $tos] {
if { ! [is_null to] } {
set_instance_assignment_cmd $name $extension $value $to
}
}
}

define_cmd "remove_instance_assignment" {-name assignment_type [-to target]}
proc_packed_toptile remove_instance_assignment { args } {
array set templs {
-name     1
-to       1
}
set value ""
parse_cmd_args $args templs arg_vals 0 0
set name ""
if { [array_has_key arg_vals -name] } {
set name [array_find_key arg_vals -name]
} else {
error "Assignment type not specified, use -name to specify"
}
set to ""
if { [array_has_key arg_vals -to] } {
set to [array_find_key arg_vals -to]
} else {
error "Target not specified, use -to to specify"
}

set_instance_assignment_cmd $name true $value $to
}

define_cmd "remove_global_assignment" {-name assignment_type [-to target]}
proc_toptile remove_global_assignment { args } {
array set templs {
-name     1
-to       1
}
set value ""
parse_cmd_args $args templs arg_vals 0 0
set name ""
if { [array_has_key arg_vals -name] } {
set name [array_find_key arg_vals -name]
} else {
error "Assignment type not specified, use -name to specify"
}
set to ""
if { [array_has_key arg_vals -to] } {
set to [array_find_key arg_vals -to]
}

set_global_assignment_cmd $name true $value $to
}

define_cmd "dump_global_assignments" {}
proc_packed_toptile dump_global_assignments { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

set names [get_global_names_cmd]
foreach name [tcl_esc $names] {
set tos [get_global_tos_cmd $name]
foreach to [tcl_esc $tos] {
set extension ""
set value [get_global_assignment_cmd $name false $to]
if { "$value" == "" } {
set value [get_global_assignment_cmd $name true $to]
set extension " -extension"
}
if { "$value" != "" } {
if { "$to" == "" } {
tcl_print "set_global_assignment${extension} -name ${name} \"${value}\"\n"
} else {
tcl_print "set_global_assignment${extension} -name ${name} -to \"${to}\" \"${value}\"\n"
}
}
}
}

return true
}

define_cmd "dump_instance_assignments" {[target_list]}
proc_packed_toptile dump_instance_assignments { args } {
array set templs {
}

set args [parse_cmd_args $args templs arg_vals 0 1]
if { [is_null args] } {
set args "*"
}
set tos [get_objects_from_args args {inst term} "to" false true false]

set names [get_instance_names_cmd]
foreach name [tcl_esc $names] {
foreach to [tcl_esc $tos] {
set extension ""
set value [get_instance_assignment_cmd $name false $to]
if { "$value" == "" } {
set value [get_instance_assignment_cmd $name true $to]
set extension " -extension"
}
if { "$value" != "" } {
tcl_print "set_instance_assignment${extension} -name ${name} -to [$to name] \"${value}\"\n"
}
}
}

return true
}

define_cmd "read_qip" {filename}
proc_packed_toptile read_qip { args } {
array set templs {
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
set ::quartus(qip_path) [file dirname $filename]
if { [file exists $filename] } {
source $filename
} else {
warn "File $filename is not found"
}
unset ::quartus(qip_path)
}

define_cmd "place_pseudo" {[-user_io] [-place_io] [-place_pll] [-place_gclk] [-warn_io]}
proc_packed_toptile place_pseudo { args } {
array set templs {
-user_io    0
-place_io   0
-place_pll  0
-place_gclk 0
-warn_io    0
}

parse_cmd_args $args templs arg_vals 0 0
set user_io    [array_has_key arg_vals -user_io   ]
set place_io   [array_has_key arg_vals -place_io  ]
set place_pll  [array_has_key arg_vals -place_pll ]
set place_gclk [array_has_key arg_vals -place_gclk]
set warn_io    [array_has_key arg_vals -warn_io   ]

set ret [place_pseudo_cmd $user_io $place_io $warn_io $place_pll $place_gclk]
if { !$ret } { fatal "Failed to pseudo place design" }

dump_location_assignments >&! $::alta_work/io.asf
dump_io_standard_assignments >>&! $::alta_work/io.asf

return true
}

const_set DESIGN_INSERT_INST_ARGS { name pin [x y z] }
define_cmd_and_usage "insert_buffer" $DESIGN_INSERT_INST_ARGS
proc_linked_or_packed insert_buffer { args } {
return [eval insert_inst buffer $args]
}
define_cmd_and_usage "insert_inverter" $DESIGN_INSERT_INST_ARGS
proc_linked_or_packed insert_inverter { args } {
return [eval insert_inst inverter $args]
}
proc_linked_or_packed insert_inst { inst_type args } {
array set templ {
}
set args [parse_cmd_args $args templs arg_vals 2 5]
set name [lindex $args 0]
set pin  [lindex $args 1]
set x 9999
set y 9999
set z 0
if { [llength $args] > 2 } {
set x [lindex $args 2]
}
if { [llength $args] > 3 } {
set y [lindex $args 3]
}
if { [llength $args] > 4 } {
set z [lindex $args 4]
}
return [insert_${inst_type}_cmd $name $pin $x $y $z]
}

define_cmd_and_usage "invert_pins" { pin_list }
proc_linked_or_packed invert_pins { args } {
array set templs {
}
set pin_list [parse_cmd_args $args templs arg_vals 1 1]
invert_pins_cmd [find_objects_by_type $pin_list others Pin true]
}

define_cmd_and_usage "set_config" {[-pin name|-loc location] config_name config_value}
proc_toptile set_config {args} {
array set templs {
-pin 1
-loc 3
}
set args [parse_cmd_args $args templs arg_vals 2 2]
set name  [lindex $args 0]
set value [lindex $args 1]
set pin {}
set loc {0 0 0}
if { [array_has_key arg_vals -pin] } {
set pin [array_find_key arg_vals -pin]
return [set_config_cmd $name $value $loc $pin]
} elseif { [array_has_key arg_vals -loc] } {
set loc [array_find_key arg_vals -loc]
return [set_config_cmd $name $value $loc]
} else {
error "Either -pin or -loc must be specified"
return false
}
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "read_verilog" {[-slice|-design] filename}

proc_tect read_verilog { args } {
array set templs {
-slice        0
-slice_gray   0
-design       0
-design_raw   0
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
set raw_defparam [array_has_key arg_vals -raw_defparam]
if { [array_has_key arg_vals -slice] } {
set ret [read_slice_library_cmd $filename true]
} elseif { [array_has_key arg_vals -slice_gray] } {
set ret [read_slice_library_cmd $filename false]
} elseif { [array_has_key arg_vals -design_raw] } {
set ret [read_design_cmd $filename true]
} else {
set ret [read_design_cmd $filename false]
}

if { !$ret } { error "Failed to read verilog file" }
return $ret
}

}; # namespace alta
set sdc_remove_quartus_column_name false

namespace eval alta {

proc convert_to_nx { values_with_unit msg } {
error_if_not_floats_with_unit $values_with_unit $msg
set values {}
foreach value_with_unit $values_with_unit {
lappend values [convert_to_ns $value_with_unit $msg]
}
return $values
}
proc convert_to_ns { value_with_unit msg } {
error_if_not_float_with_unit $value_with_unit $msg
get_float_with_unit $value_with_unit value unit
if { [string compare -nocase "$unit" "n"] == 0 } {
return $value
}
if { [string compare -nocase "$unit" "p"] == 0 } {
return [expr $value / 1000.]
}
if { [string compare -nocase "$unit" "u"] == 0 } {
return [expr $value * 1000.]
}
# In MHz
if { [string compare -nocase "$unit" "m"] == 0 } {
return [expr 1000. / $value]
}
return $value
}

proc get_name_from_args { arg_vals_ref } {
upvar 1 $arg_vals_ref arg_vals
global tcl_remove_quartus_column_name
set name [array_find_key arg_vals -name]
if { [is_null name] } {
set name ""
} elseif { $tcl_remove_quartus_column_name } {
set name [trim_quartus_name_cmd $name]
}
return $name
}

proc get_rise_fall { rise fall } {
if { $rise && $fall } {
return "rf"
} elseif { $rise } {
return "r"
} elseif { $fall } {
return "f"
} else {
return "rf"
}
}

proc get_rise_fall_from_args { arg_vals_ref } {
upvar 1 $arg_vals_ref arg_vals
set rise [array_has_key arg_vals -rise]
set fall [array_has_key arg_vals -fall]
return [get_rise_fall $rise $fall]
}

proc get_min_max { min max } {
if { $min && $max } {
return "min_max"
} elseif { $min } {
return "min"
} elseif { $max } {
return "max"
} else {
return ""
}
}

proc get_min_max_from_args { arg_vals_ref } {
upvar 1 $arg_vals_ref arg_vals
set min [array_has_key arg_vals -min]
set max [array_has_key arg_vals -max]
if { $min && $max } {
error "Both -min and -max are specified"
} elseif { !$min && !$max } {
# if none of -min or -max is specified, set both min and max to true
set min 1
set max 1
}
return [get_min_max $min $max]
}

define_cmd_and_usage "read_sdc" {[-quiet] [-quartus] filename}
proc_tect read_sdc { args } {
array set templs {
-quiet        0
-quartus      0
}
set filename [parse_cmd_args $args templs arg_vals 1 1]
set is_quiet   [array_has_key arg_vals -quiet]
set is_quartus [array_has_key arg_vals -quartus]
if { $is_quartus || $::sdc_remove_quartus_column_name } {
set org_remove_quartus_column_name $::tcl_remove_quartus_column_name
set ::tcl_remove_quartus_column_name true
}
if { $is_quiet } {
source $filename
} else {
source -echo -prompt {} $filename
}
if { $is_quartus || $::sdc_remove_quartus_column_name } {
set ::tcl_remove_quartus_column_name $org_remove_quartus_column_name
}
}

define_cmd_and_usage "set_time_format" {-unit time_unit -decimal_places decimal_place}
proc_tect set_time_format { args } {
array set templs {
-unit           1
-decimal_places 1
}
parse_cmd_args $args templs arg_vals 0 0

set time_uint [array_find_key arg_vals -unit]
if { ! [is_null time_unit] } {
set_units -time $time_unit
}
}

define_cmd_and_usage "set_units" {-time time_unit}
proc_tect set_units { args } {
array set templs {
-time  0
}
set value [parse_cmd_args $args templs arg_vals 1 1]
if { [array_has_key arg_vals -time] } {
if { [string equal -nocase $value "us"] ||  [string equal -nocase $value "u"] } {
set_time_unit_cmd 1E-6
} elseif { [string equal -nocase $value "ns"] ||  [string equal -nocase $value "n"] } {
set_time_unit_cmd 1E-9
} elseif { [string equal -nocase $value "ps"] ||  [string equal -nocase $value "p"] } {
set_time_unit_cmd 1E-12
} else {
error "Unrecognized time unit $value"
}
} else {
error "No time unit specified"
}
}

define_cmd "set_timing_derate" \
{[-net_delay|-cell_delay] [-early] [-fall] [-late] [-rise] derating_factor}
proc_tect set_timing_derate { args } {
array set templs {
-early      0
-late       0
-min        0
-max        0
-rise       0
-fall       0
-net_delay  0
-cell_delay 0
}
set derating_factor [parse_cmd_args $args templs arg_vals 1 1]

set min [expr [array_has_key arg_vals -early] || [array_has_key arg_vals -min]]
set max [expr [array_has_key arg_vals -late ] || [array_has_key arg_vals -max]]
if { ! $min  && ! $max } {
set min true
set max true
}
set min_max [get_min_max $min $max]

set rise [array_has_key arg_vals -rise]
set fall [array_has_key arg_vals -fall]
if { ! $rise && ! $fall } {
set rise true
set fall true
}
set trans [get_rise_fall $rise $fall]

set is_net  [array_has_key arg_vals -net_delay ]
set is_cell [array_has_key arg_vals -cell_delay]
if { ! $is_net && ! $is_cell } {
set is_net  true
set is_cell true
}

if { $is_net } {
set_timing_derate_cmd $trans $min_max true $derating_factor
}
if { $is_cell } {
set_timing_derate_cmd $trans $min_max false $derating_factor
}
return true
}

#define_cmd_and_usage "set_hierarchy_separator" {[|/@#.]}
define_cmd_and_usage "set_hierarchy_separator" {.}
proc_tect set_hierarchy_separator { args } {
array set templs {}
set divider [parse_cmd_args $args templs arg_vals 1 1]
#set valid_dividers "|/@#."
# TODO, only allow . as divider for the time being
set valid_dividers "."
if { [string length $divider] == 1 &&
[string first $divider $valid_dividers] >=0 } {
set_design_divider_cmd $divider
} else {
error "$divider is not a valid hierachical seperator, must be one of these characters: $valid_dividers"
}
}


#########################################################################################

proc get_clk_name { args_ref objs_ref } {
upvar 1 $args_ref arg_vals
upvar 1 $objs_ref obj_list
set clk_name [get_name_from_args arg_vals]
if { [is_null clk_name] } {
if { [llength $obj_list] == 0 } {
error "Clock name is missing and cannot be inferred"
} else {
set first_obj [lindex $obj_list 0]
set clk_name [$first_obj full_name]
}
}
return $clk_name
}

define_cmd_and_usage "create_clock" \
{[-name clock_name] -period period_value [-add] [-waveform waveform] [-duty_cycle duty_percent] pin}
proc_linked_or_packed create_clock { args } {
array set templs {
-name       1
-period     1
-waveform   1
-duty_cycle 1
-add        0
}
set obj_list [parse_cmd_args $args templs arg_vals 0 1024]

set clk_name [get_clk_name arg_vals obj_list]

if { ! [array_has_key arg_vals -period] } {
error "Clock period must be specified"
} else {
set period_value [array_find_key arg_vals -period]
set period_value [convert_to_ns $period_value "period must be a float value" ]
if { $period_value <= 0 } {
error "period must be a positive value"
}
}

set waveform {}
if { [array_has_key arg_vals -waveform] } {
set waveform [array_find_key arg_vals -waveform]
set waveform [convert_to_nx $waveform "waveform values must be floats"]
}

set duty_percent 50.0
if { [array_has_key arg_vals -duty_cycle] } {
set duty_percent [array_find_key arg_vals -duty_cycle]
error_if_not_float $duty_percent "duty_cycle must be between 0 and 100" \
{$duty_percent > 0 && $duty_percent < 100}
}

set add false
if { [array_has_key arg_vals -add] } {
set add true
}

if { [is_null obj_list] } {
array set colls {
Pin      {}
Register {}
}
} else {
set types {Keeper {Pin Term}}
find_and_collect_objects_by_type $obj_list colls ignores $types {} true
}

set clk [create_clock_cmd $clk_name $period_value $duty_percent $waveform $add \
$colls(Pin) $colls(Register)]
if { ! $clk } {
error "failed to create clock $clk_name"
}
return clk;
}

define_cmd_and_usage "create_generated_clock" \
{-name clock_name -source master_pin [-master_clock clock] \
[-add] [-invert] [-edges edge_list] [-edge_shift edge_shift_list] [-phase phase_shift] \
[-divide_by divide_factor | -multiply_by multiply_factor] [-duty_cycle duty_percent] pin_list}
proc_linked_or_packed create_generated_clock { args } {
array set templs {
-name         1
-source       1
-master_clock 1
-divide_by    1
-multiply_by  1
-edges        1
-duty_cycle   1
-edge_shift   1
-phase        1
-combinational 1
-invert       0
-add          0
}
set obj_list [parse_cmd_args $args templs arg_vals 1 1024]

set clk_name [get_clk_name arg_vals obj_list]

set source_pin NULL
set source_reg NULL
set source_pin_or_reg [get_object_from_args arg_vals {pin term reg} "-source" true]
if { [is_object_of_type $source_pin_or_reg Register] } {
set source_pin NULL
set source_reg $source_pin_or_reg
} else {
set source_pin $source_pin_or_reg
set source_reg NULL
}

set master_clock [get_object_from_args arg_vals clock "-master_clock" false]

set divide_factor 0
if { [array_has_key arg_vals -divide_by] } {
set divide_factor [array_find_key arg_vals -divide_by]
error_if_not_int $divide_factor "-divide_by factor must be a positive integer" \
{$divide_factor > 0}
}

set multiply_factor 0
if { [array_has_key arg_vals -multiply_by] } {
set multiply_factor [array_find_key arg_vals -multiply_by]
error_if_not_int $multiply_factor "-multiply_by factor must be a positive integer" \
{$multiply_factor > 0}
}

set duty_percent 50.0
if { [array_has_key arg_vals -duty_cycle] } {
set duty_percent [array_find_key arg_vals -duty_cycle]
error_if_not_float $duty_percent "-duty_cycle percent must be between 0 and 100" \
{$duty_percent > 0 && $duty_percent < 100}
}

set edges {}
if { [array_has_key arg_vals -edges] } {
set edges [array_find_key arg_vals -edges]
set edges [convert_to_nx $edges "Edges values must be floats"]
}

set edge_shift {}
if { [array_has_key arg_vals -edge_shift] } {
set edge_shift [array_find_key arg_vals -edge_shift]
set edge_shift [convert_to_nx $edge_shift "-edge_shift values must be floats"]
}

set phase_shift 0.0
if { [array_has_key arg_vals -phase] } {
set phase_shift [array_find_key arg_vals -phase]
error_if_not_float $phase_shift "-phase must be a floating point number"
}

set combinational false
if { [array_has_key arg_vals -combinational] } {
warn_unsupported "-combinational"
set combinational true
}

set invert [array_has_key arg_vals -invert]
set add    [array_has_key arg_vals -add   ]

set types {Keeper {Pin Term}}
find_and_collect_objects_by_type $obj_list colls ignores $types {} true

set gen_clk [create_generated_clock_cmd $clk_name $source_pin $source_reg $master_clock \
$multiply_factor $divide_factor $duty_percent \
$edges $edge_shift $phase_shift $combinational $invert $add \
$colls(Pin) $colls(Register)]
if { ! $gen_clk } {
error "failed to create generated clock $clk_name"
}
return $gen_clk
}

define_cmd_and_usage "remove_clock" \
{-all | clock_list}
proc_linked_or_packed remove_clock { args } {
array set templs {
-all 0
}
set clock_list [parse_cmd_args $args templs arg_vals 1 1]
set all [array_has_key arg_vals -all]
return [remove_clock_cmd $all [get_clocks $clock_list]]
}


#const_set SDC_PATH_CONSTRAINT_ARGS \
{[-reset_path] [-setup] [-hold] [-rise] [-fall] \
[-from from_list | -rise_from rise_from_list | -fall_from fall_from_list] \
[-through through_list | -rise_through rise_through_list | -fall_through fall_through_list]* \
[-to to_list | -rise_to rise_to_list | -fall_to fall_to_list]}
const_set SDC_PATH_CONSTRAINT_ARGS \
{[-from from_list] | [-to to_list]}
set SDC_PATH_CONSTRAINT_TEMPLS { \
-reset_path   0 \
-setup        0 \
-hold         0 \
-rise         0 \
-fall         0 \
-from         1 \
-rise_from    1 \
-fall_from    1 \
-to           1 \
-rise_to      1 \
-fall_to      1 \
-through      {1 -throughs} \
-rise_through {1 -throughs} \
-fall_through {1 -throughs} \
-from_clock      1 \
-to_clock        1 \
-rise_from_clock 1 \
-rise_to_clock   1 \
-fall_from_clock 1 \
-fall_to_clock   1 \
-name         1
}
proc parse_path_args { arg_vals_ref from_ref to_ref thrus_ref min_max_ref trans_ref reset_ref name_ref } {
upvar 1 $arg_vals_ref arg_vals
upvar 1 $from_ref  from
upvar 1 $to_ref    to
upvar 1 $thrus_ref thrus
upvar 1 $min_max_ref min_max
upvar 1 $trans_ref   trans
upvar 1 $reset_ref   reset
upvar 1 $name_ref name

set setup true
set hold true
if { [array_has_key arg_vals -setup] && ! [array_has_key arg_vals -hold] } {
set hold false
}
if { [array_has_key arg_vals -hold] && ! [array_has_key arg_vals -setup] } {
set setup false
}
set min_max [get_min_max $hold $setup]

set rise false
if { [array_has_key arg_vals -rise] } {
error_unsupported "-rise"
set rise true
}
set fall false
if { [array_has_key arg_vals -fall] } {
error_unsupported "-fall"
set fall true
}
set trans [get_rise_fall $rise $fall]

set reset false
if { [array_has_key arg_vals -reset] } {
error_unsupported "-reset"
set reset true
}

set from NULL
set from_args ""
set from_clks ""
set from_trans "rf"
set has_from_arg false
if { [array_has_key arg_vals -from] } {
set has_from_arg true
set from_args [array_find_key arg_vals -from]
} elseif { [array_has_key arg_vals -rise_from] } {
set has_from_arg true
set from_trans "r"
if { ![is_null from_args] } {
error "Options -from, -rise_from and -fall_from are mutually exclusive"
}
set from_args [array_find_key arg_vals -rise_from]
} elseif { [array_has_key arg_vals -fall_from] } {
set has_from_arg true
set from_trans "f"
if { ![is_null from_args] } {
error "Options -from, -rise_from and -fall_from are mutually exclusive"
}
set from_args [array_find_key arg_vals -fall_from]
}
if { [array_has_key arg_vals -from_clock] } {
set has_from_arg true
set from_clks [array_find_key arg_vals -from_clock]
} elseif { [array_has_key arg_vals -rise_from_clock] } {
set has_from_arg true
set from_trans "r"
if { ![is_null from_clks] } {
error "Options -from_clock, -rise_from_clock and -fall_from_clock are mutually exclusive"
}
set from_clks [array_find_key arg_vals -rise_from_clock]
} elseif { [array_has_key arg_vals -fall_from_clock] } {
set has_from_arg true
set from_trans "f"
if { ![is_null from_clks] } {
error "Options -from_clock, -rise_from_clock and -fall_from_clock are mutually exclusive"
}
set from_clks [array_find_key arg_vals -fall_from_clock]
}
if { $has_from_arg } {
#set types {Instance Register {Pin Term} Clock}
set types {Keeper {Pin Term} Instance Clock}
array_clear colls
find_and_collect_objects_by_type $from_args colls ignores $types {} true
if { ! [is_null from_clks] } {
lappend colls(Clock) {*}[get_clocks $from_clks]
}
set from [new_path_from_cmd $colls(Instance) $colls(Register) $colls(Pin) $colls(Clock) $from_trans]
}

set to NULL
set to_args ""
set to_clks ""
set to_trans "rf"
set has_to_arg false
if { [array_has_key arg_vals -to] } {
set has_to_arg true
set to_args [array_find_key arg_vals -to]
} elseif { [array_has_key arg_vals -rise_to] } {
set has_to_arg true
set to_trans "r"
if { ![is_null to_args] } {
error "Options -to, -rise_to and -fall_to are mutually exclusive"
}
set to_args [array_find_key arg_vals -rise_to]
} elseif { [array_has_key arg_vals -fall_to] } {
set has_to_arg true
set to_trans "f"
if { ![is_null to_args] } {
error "Options -to, -rise_to and -fall_to are mutually exclusive"
}
set to_args [array_find_key arg_vals -fall_to]
}
if { [array_has_key arg_vals -to_clock] } {
set has_to_arg true
set to_clks [array_find_key arg_vals -to_clock]
} elseif { [array_has_key arg_vals -rise_to_clock] } {
set has_to_arg true
set to_trans "r"
if { ![is_null to_clks] } {
error "Options -to_clock, -rise_to_clock and -fall_to_clock are mutually exclusive"
}
set to_clks [array_find_key arg_vals -rise_to_clock]
} elseif { [array_has_key arg_vals -fall_to_clock] } {
set has_to_arg true
set to_trans "f"
if { ![is_null to_clks] } {
error "Options -to_clock, -rise_to_clock and -fall_to_clock are mutually exclusive"
}
set to_clks [array_find_key arg_vals -fall_to_clock]
}
if { $has_to_arg } {
#set types {Instance Register {Pin Term} Clock}
set types {Keeper {Pin Term} Instance Clock}
array_clear colls
find_and_collect_objects_by_type $to_args colls ignores $types {} true
if { ! [is_null to_clks] } {
lappend colls(Clock) {*}[get_clocks $to_clks]
}
set to [new_path_to_cmd $colls(Instance) $colls(Register) $colls(Pin) $colls(Clock) $to_trans]
}
set name [get_name_from_args arg_vals]

set thrus {}
if { [array_has_key arg_vals -throughs] } {
foreach through [tcl_esc $arg_vals(-throughs)] {
set through_key [lindex $through 0]
set thru_args [lrange $through 1 end]
set thru_trans "rf"
if { $through_key == "-through" } {
} elseif { $through_key == "-rise_through" } {
set thru_trans "r"
} elseif { $through_key == "-fall_through" } {
set thru_trans "f"
}
if { ! [is_null thru_args] } {
set types {{Pin Term} Instance}
array_clear colls
find_and_collect_objects_by_type $thru_args colls ignores $types {} true
lappend thrus [new_path_thru_cmd $colls(Instance) $colls(Pin) $thru_trans]
}
}
}
}

#define_cmd_and_usage "set_false_path" \
[concat $SDC_PATH_CONSTRAINT_ARGS {}]
define_cmd_and_usage "set_false_path" \
[concat $SDC_PATH_CONSTRAINT_ARGS {}]
proc_tect set_false_path { args } {
array set templs $alta::SDC_PATH_CONSTRAINT_TEMPLS
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

parse_path_args arg_vals from to thrus min_max trans reset name
return [set_false_path_cmd $from $to $thrus $min_max $trans $name]
}

#define_cmd_and_usage "set_multicycle_path" \
[concat $SDC_PATH_CONSTRAINT_ARGS {[-start] [-end] path_multiplier}]
define_cmd_and_usage "set_multicycle_path" \
[concat $SDC_PATH_CONSTRAINT_ARGS {path_multiplier}]
proc_linked_or_packed set_multicycle_path { args } {
array set templs $alta::SDC_PATH_CONSTRAINT_TEMPLS
array set templs {
-start        0
-end          0
}
set path_multipliers [parse_cmd_args $args templs arg_vals 1 1]

if { [array_has_key arg_vals -start] && [array_has_key arg_vals -end] } {
error "-start and -end options cannot be used at the same time"
}
set start false
set end true
if { [array_has_key arg_vals -start] } {
set start true
set end false
}
if { [array_has_key arg_vals -end] } {
set start false
set end true
}

error_if_not_ints $path_multipliers "path_multiplier must be an integer"

if { [llength $path_multipliers] == 1 } {
parse_path_args arg_vals from to thrus min_max trans reset name
return [set_multicycle_path_cmd $from $to $thrus $min_max $trans $name $start $end $path_multipliers]
} elseif { [llength $path_multipliers] == 2 } {
parse_path_args arg_vals from to thrus min_max trans reset name
set_multicycle_path_cmd $from $to $thrus [get_min_max false true] $trans $name $start $end [lindex $path_multipliers 0]
parse_path_args arg_vals from to thrus min_max trans reset name
return [set_multicycle_path_cmd $from $to $thrus [get_min_max true false] $trans $name $start $end [lindex $path_multipliers 1]]
}
}

define_cmd_and_usage "set_max_delay" \
[concat $SDC_PATH_CONSTRAINT_ARGS {delay_value}]
proc_linked_or_packed set_max_delay { args } {
eval set_min_max_delay max $args
}
define_cmd_and_usage "set_min_delay" \
[concat $SDC_PATH_CONSTRAINT_ARGS {delay_value}]
proc_linked_or_packed set_min_delay { args } {
eval set_min_max_delay min $args
}

proc_linked_or_packed set_min_max_delay { min_or_max args } {
array set templs $alta::SDC_PATH_CONSTRAINT_TEMPLS
set delay [parse_cmd_args $args templs arg_vals 1 1]
set delay [convert_to_ns $delay "delay must be a float value"]
parse_path_args arg_vals from to thrus min_max trans reset name
return [set_${min_or_max}_delay_cmd $from $to $thrus $trans $name $delay]
}

define_cmd_and_usage "set_input_delay" \
{-clock clock_name  [-add_delay] [-clock_fall] [-rise] [-fall] [-min] [-max] \
[-reference_pin pin_name] delay pin_list}
proc_linked_or_packed set_input_delay { args } {
eval set_input_output_delay input $args
}
define_cmd_and_usage "set_output_delay" \
{-clock clock_name  [-add_delay] [-clock_fall] [-rise] [-fall] [-min] [-max] \
[-reference_pin pin_name] delay pin_list}
proc_linked_or_packed set_output_delay { args } {
eval set_input_output_delay output $args
}

proc set_input_output_delay { input_or_output args } {
array set templs {
-add_delay     0
-rise          0
-fall          0
-min           0
-max           0
-clock_fall    0
-clock         1
-reference_pin 1
-name          1
}
set args [parse_cmd_args $args templs arg_vals 2 2]

set trans [get_rise_fall_from_args arg_vals]

set min_max [get_min_max_from_args arg_vals]

set clock_fall [array_has_key arg_vals -clock_fall]

set clock [get_object_from_args arg_vals {clock} -clock true]

set ref_pin [get_object_from_args arg_vals {pin term} -reference_pin false]

set name [get_name_from_args arg_vals]

set delay [lindex $args 0]
set delay [convert_to_ns $delay "delay must be a float value"]

set pin_list [lindex $args 1]
set pins [get_objects_from_args pin_list {pin term} "target pin" true false]

set add_delay [array_has_key arg_vals -add_delay]

return [set_${input_or_output}_delay_cmd $clock $pins $delay $min_max $trans $clock_fall $ref_pin $add_delay $name]
}

define_cmd_and_usage "set_clock_latency" \
{[-clock clock_list] [-early] [-fall] [-late] [-rise] -source delay targets}
proc_linked_or_packed set_clock_latency { args } {
array set templs {
-source     0
-early      0
-late       0
-min        0
-max        0
-rise       0
-fall       0
-clock      1
}
set delay_targets [parse_cmd_args $args templs arg_vals 2 2]

set latency_value [convert_to_ns [lindex $delay_targets 0] "delay must be a float value" ]

set types {Keeper {Pin Term} Clock}
array_clear colls
find_and_collect_objects_by_type [lrange $delay_targets 1 1000] colls ignores $types {} true
set clocks $colls(Clock)
set clk_pins $colls(Pin)
set clk_regs $colls(Register)
if { [is_null clocks] && [is_null clk_pins] && [is_null clk_regs] } {
error "no valid clocks or clock targets are specified"
}

set min [expr [array_has_key arg_vals -early] || [array_has_key arg_vals -min]]
set max [expr [array_has_key arg_vals -late ] || [array_has_key arg_vals -max]]
if { ! $min  && ! $max } {
set min true
set max true
}
set min_max [get_min_max $min $max]

set rise [array_has_key arg_vals -rise]
set fall [array_has_key arg_vals -fall]
if { ! $rise && ! $fall } {
set rise true
set fall true
}
set trans [get_rise_fall $rise $fall]

set name [get_name_from_args arg_vals]

set pin_clks [get_objects_from_args arg_vals {clock} "-clock" false]
if { [is_null clk_pins] && [is_null clk_regs] && ! [is_null pin_clks] } {
warn "meaningless -clock if no clock target is specified"
set pin_clks {}
}

return [set_clock_latency_cmd $clocks $clk_pins $clk_regs $pin_clks \
$latency_value $min_max $trans $name]
}

define_cmd_and_usage "set_clock_uncertainty" \
{[-add] [-fall_from fall_from_clock] [-fall_to fall_to_clock] \
[-from from_clock] [-hold] [-rise_from rise_from_clock] [-rise_to rise_to_clock] [-setup] \
[-to to_clock] [-enable_same_physical_edge] uncertainty}
proc_linked_or_packed set_clock_uncertainty { args } {
array set templs {
-enable_same_physical_edge 0
-add        0
-hold       0
-setup      0
-min        0
-max        0
-from       1
-to         1
-rise_from  1
-fall_from  1
-rise_to    1
-fall_to    1
}
set uncertainty [parse_cmd_args $args templs arg_vals 1 1]

set uncertainty_value [convert_to_ns $uncertainty "uncertainty must be a float value"]
if { $uncertainty_value < 0 } {
error "uncertainty must be a positive value"
}

set add   [array_has_key arg_vals -add]
set same_edge [array_has_key arg_vals -enable_same_physical_edge]

set min [expr [array_has_key arg_vals -hold ] || [array_has_key arg_vals -min]]
set max [expr [array_has_key arg_vals -setup] || [array_has_key arg_vals -max]]
if { ! $min && ! $max } {
set min true
set max true
}
set min_max [get_min_max $min $max]

set name [get_name_from_args arg_vals]

set from {}
set is_rise_from false
set is_fall_from false
if { [array_has_key arg_vals -from] } {
set from [get_objects_from_args arg_vals {clock} "-from" false]
set is_rise_from true
set is_fall_from true
}
if { [array_has_key arg_vals -rise_from] } {
if { ![is_null from] } {
error "Options -from, -rise_from and -fall_from are mutually exclusive"
}
set from [get_objects_from_args arg_vals {clock} "-rise_from" false]
set is_rise_from true
}
if { [array_has_key arg_vals -fall_from] } {
if { ![is_null from] } {
error "Options -from, -rise_from and -fall_from are mutually exclusive"
}
set from [get_objects_from_args arg_vals {clock} "-fall_from" false]
set is_fall_from true
}

set to {}
set is_rise_to false
set is_fall_to false
if { [array_has_key arg_vals -to] } {
set to [get_objects_from_args arg_vals {clock} "-to" false]
set is_rise_to true
set is_fall_to true
}
if { [array_has_key arg_vals -rise_to] } {
if { ![is_null to] } {
error "Options -to, -rise_to and -fall_to are mutually exclusive"
}
set to [get_objects_from_args arg_vals {clock} "-rise_to" false]
set is_rise_to true
}
if { [array_has_key arg_vals -fall_to] } {
if { ![is_null to] } {
error "Options -to, -rise_to and -fall_to are mutually exclusive"
}
set to [get_objects_from_args arg_vals {clock} "-fall_to" false]
set is_fall_to true
}

if { [is_null from] && [is_null to] } {
error "no valid from/to clocks are specified"
}

return [set_clock_uncertainty_cmd $from $is_rise_from $is_fall_from $to $is_rise_to $is_fall_to \
$uncertainty_value $add $same_edge $min_max $name]
}

define_cmd_and_usage "set_clock_groups" {[-asynchronous] [-exclusive] -group <names>}
proc_linked_or_packed set_clock_groups { args } {
array set templs {
-asynchronous 0
-exclusive    0
-group        {1 -groups}
}
parse_cmd_args $args templs arg_vals 0 0
set name [get_name_from_args arg_vals]
set clock_groups {}
if { [array_has_key arg_vals -groups] } {
foreach group [tcl_esc $arg_vals(-groups)] {
set group_args [lrange $group 1 end]
set clks [get_objects_from_args group_args {clock} "clock names" true false]
if { ! [is_null clks] } {
lappend clock_groups [new_clock_group_cmd $clks]
}
}
} else {
error "Option -group is not found"
}
return [set_clock_groups_cmd $clock_groups $name]
}

define_cmd_and_usage "get_clock_pin" { clk_name }
proc_linked_or_packed get_clock_pin { args } {
return [[get_clocks $args] clk_pin]
}

define_cmd "dump_constraints" {}
proc_tect dump_constraints { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

dump_constraints_cmd
}


########################################################
# Quartus SDC extension
define_cmd_and_usage "derive_pll_clocks" {[-create_base_clocks] [-use_tan_name]}
proc_linked_or_packed derive_pll_clocks { args } {
array set templs {
-create_base_clocks 0
-use_tan_name       0
}
parse_cmd_args $args templs arg_vals 0 0
set create_base_clocks [array_has_key arg_vals -create_base_clocks]
set use_net_name [array_has_key arg_vals -use_tan_name]
derive_pll_clocks_cmd $create_base_clocks $use_net_name
}

define_cmd "derive_clock_uncertainty" {}
proc_linked_or_packed derive_clock_uncertainty { args } {
return true
}

define_cmd "set_active_clocks" {}
proc_linked_or_packed set_active_clocks { args } {
return true
}

define_cmd "get_active_clocks" {}
proc_linked_or_packed get_active_clocks { args } {
return true
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "report_timing" \
{[-verbose] [-summary|-brief] [-setup] [-hold] [-fmax] [-xfer] [-coverage] \
[-from from_list] [-to to_list] [-file file_name]}

proc_linked_or_packed report_timing {args} {
array set templs {
-verbose         1
-summary         0
-brief           0
-setup           0
-hold            0
-fmax            0
-xfer            0
-coverage        0
-from            1
-to              1
-file            1
-from_clock      1
-to_clock        1
-rise_from_clock 1
-rise_to_clock   1
-fall_from_clock 1
-fall_to_clock   1
-through         {1 -throughs}
-false_path      0
-less_than_slack 1
-npaths          1
-nworst          1
-pairs_only      0
}
parse_cmd_args $args templs arg_vals 0 0
set verbose 1
if { [array_has_key arg_vals -verbose] } {
set verbose [array_find_key arg_vals -verbose]
}
set summary 0
if { [array_has_key arg_vals -brief] } {
set summary 2
} elseif { [array_has_key arg_vals -summary] } {
set summary 1
}
set setup [array_has_key arg_vals -setup]
set hold  [array_has_key arg_vals -hold ]
set fmax  [array_has_key arg_vals -fmax ]
set xfer  [array_has_key arg_vals -xfer ]
set coverage [array_has_key arg_vals -coverage ]
if { !$setup && !$hold && !$fmax && !$xfer && !$coverage } {
set setup true; set hold true;
}
set report_file [array_find_key arg_vals -file]

set false_path [array_has_key arg_vals -false_path]
set pairs_only [array_has_key arg_vals -pairs_only]
set npaths 1
set nworst -1
if { [array_has_key arg_vals -nworst] } {
set nworst [array_find_key arg_vals -nworst]
set npaths $nworst
}
if { [array_has_key arg_vals -npaths] } {
set npaths [array_find_key arg_vals -npaths]
}
# To match previous behavior
if { $verbose == 2 } {
set npaths -1
set nworst 0
}
set less_than_slack false
set less_than_limit 0
if { [array_has_key arg_vals -less_than_slack] } {
set less_than_slack true
set less_than_limit [array_find_key arg_vals -less_than_slack]
}

parse_path_args arg_vals from to thrus min_max trans reset name
report_timing_cmd $verbose $summary \
$setup $hold $fmax $xfer $coverage \
$from $to $thrus $report_file \
$false_path $pairs_only $npaths $nworst \
$less_than_slack $less_than_limit
}

define_cmd_and_usage "update_timing" {[-full]}

proc_linked_or_packed update_timing {args} {
array set templs {
-full 0
}
parse_cmd_args $args templs arg_vals 0 0
set is_full [array_has_key arg_vals -full]
update_timing_cmd $is_full
}

define_cmd_and_usage "set_timing_corner" {fast|slow}

proc_linked_or_packed set_timing_corner {args} {
array set templs {
}
set corner [parse_cmd_args $args templs arg_vals 1 1]
if { $corner == "fast" } {
set corner 0
} else {
set corner 1
}
set_ta_corner_cmd $corner
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "place_design" {[lx ly ux uy]}
proc_packed_toptile place_design {args} {
array set templs {
-dump         1
-load         1
-replace      1
-local_only   1
-incremental  0
-dry_run      0
-force        0
}

set coords [parse_cmd_args $args templs arg_vals 0 4]
set dump ""
if { [array_has_key arg_vals -dump] } {
set dump [array_find_key arg_vals -dump]
}
set load ""
if { [array_has_key arg_vals -load] } {
set load [array_find_key arg_vals -load]
}
set replace ""
if { [array_has_key arg_vals -replace] } {
set replace [array_find_key arg_vals -replace]
}
if { [llength $coords] == 0 } {
#   set coords [[get_top_array_cmd] chip_bbox]
set coords [[get_top_array_cmd] logic_bbox]
} elseif { [llength $coords] != 4 } {
fatal "requires 4 positional arguments, but get [llength $coords]"
}

set local_only 0
if { [array_has_key arg_vals -local_only] } {
set local_only [array_find_key arg_vals -local_only]
}
set dry_run     [array_has_key arg_vals -dry_run    ]
set incremental [array_has_key arg_vals -incremental]
set force       [array_has_key arg_vals -force      ]

set ret [place_design_cmd $dump $load $replace $local_only \
$incremental $dry_run $force \
[lindex $coords 0] [lindex $coords 1] \
[lindex $coords 2] [lindex $coords 3]]
if { !$ret } { fatal "Failed to place design" }
return $ret
}

}; # namespace alta
set rt_route_has_conflict false
set rt_incremental_route  true
set rt_dump_post_result false

namespace eval alta {

define_cmd_and_usage "route_design" {}
define_cmd_and_usage "place_and_route_design" {[-seed_rand] [-retry retry_cnt]}

define_cmd "dump_estimated_delay" {}
define_cmd "load_route_table"  {}
define_cmd "build_route_table" {}
define_cmd "dump_route_table"  {}
define_cmd "dump_route_list"   {}
define_cmd "dump_route_timing" {}
define_cmd "check_route"       {}
define_cmd "probe_design"      {}
define_cmd "route_delay"       {}

proc_packed_toptile route_design { args } {
global rt_route_has_conflict
global rt_incremental_route
global rt_dump_post_result
set rt_route_has_conflict false
array set templs {
-dump          1
-load          1
-replace       1
-check_only    0
-incremental   0
-force         0
-dump_nodes    0
-load_nodes    0
}

parse_cmd_args $args templs arg_vals 0 0
set dump ""
if { [array_has_key arg_vals -dump] } {
set dump [array_find_key arg_vals -dump]
}
set load ""
if { [array_has_key arg_vals -load] } {
set load [array_find_key arg_vals -load]
}
set replace ""
set retry 0
if { [array_has_key arg_vals -replace] } {
set replace [array_find_key arg_vals -replace]
set retry 3
}
set check_only  [array_has_key arg_vals -check_only ]
set incremental [array_has_key arg_vals -incremental]
set force       [array_has_key arg_vals -force      ]
set dump_nodes  [array_has_key arg_vals -dump_nodes ]
set load_nodes  [array_has_key arg_vals -load_nodes ]
if { $rt_incremental_route } {
set dump_nodes true
set load_nodes true
}
if { $rt_dump_post_result && $load != "" && $dump == "" } {
set dump $::alta_work/post_route.tx
}

set place_result $::alta_work/place.tx
set ret [route_design_cmd $dump $load $replace $check_only $incremental \
$force $dump_nodes $load_nodes]
for {} { $retry >= 1 } { incr retry -1 } {
if { $ret != 0 } { break; }
if { ! [file exist $replace] } { break; }
place_design -replace $replace -incremental -load $place_result -dump $place_result
if { $retry == 1 } {
set ret [route_design_cmd $dump "" ""       false true false]
} else {
set ret [route_design_cmd $dump "" $replace false true false]
}
}
if { $ret == 0 } { set rt_route_has_conflict true; }
if { $ret <= 0 } { fatal "Failed to route design"; return false; }
return true;
}

proc_packed_toptile place_and_route_design { args } {
global rt_route_has_conflict
global sh_continue_on_error
global pl_report_timing
if { ! [info exist pl_report_timing] } {
set pl_report_timing false
}
set sh_continue_on_error_org $sh_continue_on_error

array set templs {
-org_place    0
-load_place   0
-load_route   0
-seed_rand    0
-retry        1
-quiet        0
}

parse_cmd_args $args templs arg_vals 0 0
set org_place  [array_has_key arg_vals -org_place]
set load_place [array_has_key arg_vals -load_place]
set load_route [array_has_key arg_vals -load_route]
set seed_rand  [array_has_key arg_vals -seed_rand]
set is_quiet   [array_has_key arg_vals -quiet]
set retry 0
if { [array_has_key arg_vals -retry] } {
set retry [array_find_key arg_vals -retry]
}

set place_result $::alta_work/place.tx
set route_result $::alta_work/route.tx
set replace_file $::alta_work/replace.tx
if { $load_place && ! [file exists "$place_result"] } {
set load_place false
}
if { $load_route && ! [file exists "$route_result"] } {
set load_route false
}
if { ! $load_place } { set load_route false }

set SEEDS {101 211 311 401 503 601 701 809 907}
for {set nn 0} {$nn < [expr $retry+1]} {incr nn} {
set ret true
set force ""
if { $nn != 0 } {
set force "-force"
}

if { $load_place } {
if { ! $is_quiet } {
puts "place_design -load $place_result $force"
}
if { ! [eval place_design -load $place_result $force] } {
set ret false; break
}
} elseif { $org_place } {
if { ! $is_quiet } {
puts "place_design -dump $place_result -local_only 1 $force"
}
if { ! [eval place_design -dump $place_result -local_only 1 $force] } {
set ret false; break
}
} else {
if { ! [eval place_design -dump $place_result $force] } {
set ret false; break
}
}
if { ! $is_quiet } {
puts ""; puts "*** Post Placement Timing Report ***"
report_timing -summary;
if { $pl_report_timing } {
report_timing -verbose 2 -setup -file $::alta_work/setup_place.rpt.gz
report_timing -verbose 2 -setup -brief -file $::alta_work/setup_place_summary.rpt.gz
report_timing -verbose 2 -hold -file $::alta_work/hold_place.rpt.gz
report_timing -verbose 2 -hold -brief -file $::alta_work/hold_place_summary.rpt.gz
}
puts "*** End Timing Report ***"; puts ""
}

if { $load_route } {
if { ! $is_quiet } {
puts "route_design -load $route_result $force"
}
if { ! [eval route_design -load $route_result $force] } {
set ret false
}
set rt_route_has_conflict false
} else {
if { $nn != $retry } {
set sh_continue_on_error true
}
set rt_route_has_conflict false
if { ! $is_quiet } {
puts "route_design -dump $route_result -replace $replace_file $force"
}
if { ! [eval route_design -dump $route_result -replace $replace_file $force] } {
set ret false
}
set sh_continue_on_error $sh_continue_on_error_org
}
if { ! $rt_route_has_conflict } {
if { ! $is_quiet } {
puts ""; puts "*** Post Routing Timing Report ***"
report_timing -summary
puts "*** End Timing Report ***"; puts ""
}
break
}

if { $seed_rand } {
seed_rand
} else {
seed_rand [lindex $SEEDS $nn]
}
}
return $ret
}

proc_toptile build_route_table { args } {
array set templs {
-max_dist 1
}

parse_cmd_args $args templs arg_vals 0 0
set max_dist_inner  -1
set max_dist_outter -1
if { [array_has_key arg_vals -max_dist] } {
set max_dists [array_find_key arg_vals -max_dist]
if { [llength $max_dists] == 2} {
set max_dist_inner  [lindex $max_dists 0]
set max_dist_outter [lindex $max_dists 1]
} else {
set max_dist_inner  $max_dists
set max_dist_outter $max_dists
}
}

set ret [build_route_table_cmd $max_dist_inner $max_dist_outter]
if { !$ret } { error "Failed to build route table" }
return $ret
}

proc_toptile dump_estimated_delay {args} {
array set templs {
}
dump_estimated_delay_cmd
}

proc_toptile dump_route_table {args} {
array set templs {
-ar_format 0
-route_segs 0
}

set filename [parse_cmd_args $args templs arg_vals 0 1]
if { [llength $filename] == 0 } {
set filename ""
}
set ar_format [array_has_key arg_vals -ar_format]
set route_segs [array_has_key arg_vals -route_segs]

set ret [dump_route_table_cmd $filename $ar_format $route_segs]
if { !$ret } { error "Failed to dump route table" }
return $ret
}

proc_toptile load_route_table {args} {
array set templs {
-ar_format  0
-route_segs 0
}

set filename [parse_cmd_args $args templs arg_vals 1 1]
set ar_format [array_has_key arg_vals -ar_format]
set route_segs [array_has_key arg_vals -route_segs]

set ret [load_route_table_cmd $filename $ar_format $route_segs]
if { !$ret } { error "Failed to load route table $filename" }
return $ret
}

proc_toptile dump_route_list {args} {
array set templs {
-level 1
}

parse_cmd_args $args templs arg_vals 0 0

set level 0
if { [array_has_key arg_vals -level] } {
set level [array_find_key arg_vals -level]
}

dump_route_list_cmd $level
}

proc_toptile check_route {args} {
array set templs {
-lut  0
-from 5
-to   5
}

parse_cmd_args $args templs arg_vals 0 0
if { [array_has_key arg_vals -from] } {
set from [array_find_key arg_vals -from]
} else {
error "Missing from point"
}
if { [array_has_key arg_vals -to] } {
set to   [array_find_key arg_vals -to]
} else {
error "Missing to point"
}
set check_all_lut_inputs [array_has_key arg_vals -lut]

set ::rt_target_alpha_ratio "0.0 0.0"
return [check_route_cmd \
[lindex $from 0] [lindex $from 1] [lindex $from 2] [lindex $from 3] [lindex $from 4] \
[lindex $to 0] [lindex $to 1] [lindex $to 2] [lindex $to 3] [lindex $to 4] \
$check_all_lut_inputs]
}

proc_packed_toptile probe_design {args} {
array set templs {
-froms 1
-tos   1
-load  1
-force 0
}
parse_cmd_args $args templs arg_vals 0 0

set froms {}
if { [array_has_key arg_vals -froms] } {
set froms [array_find_key arg_vals -froms]
} else {
error "Missing probe from info"
}
set from_cnt [llength $froms]
if { $from_cnt == 0 } {
error "Empty probe from info"
}
set tos {}
if { [array_has_key arg_vals -tos] } {
set tos [array_find_key arg_vals -tos]
} else {
error "Missing probe to info"
}
set to_cnt [llength $tos  ]
if { $to_cnt == 0 } {
error "Empty probe to info"
}
if { $from_cnt != $to_cnt } {
error "From count $from_cnt does not match to count $to_cnt"
}

set load ""
if { [array_has_key arg_vals -load] } {
set load [array_find_key arg_vals -load]
}
set force [array_has_key arg_vals -force]

if { $load == "" } {
set place_result $::alta_work/place.tx
set route_result $::alta_work/route.tx
if { ! [eval place_design -load $place_result -dry_run] } { return false }
set load $route_result
} else {
set route_result $load
}
return [probe_net_cmd $froms $tos $route_result $force]
}

proc_packed_toptile route_delay { args } {
array set templs {
-quiet 0
-load  1
}
parse_cmd_args $args templs arg_vals 0 0
set is_quiet [array_has_key arg_vals -quiet]

set load ""
if { [array_has_key arg_vals -load] } {
set load [array_find_key arg_vals -load]
}

if { $load == "" } {
set route_result $::alta_work/route.tx
} else {
set route_result $load
}
route_delay_cmd $route_result

if { ! $is_quiet } {
puts ""; puts "*** Post Routing Hold Report (fast corner) ***"
report_timing -summary -hold
puts "*** End Hold Report ***"; puts ""
}
}

}; # namespace alta
set use_block_erase false

namespace eval alta {

define_cmd_and_usage "bitgen" \
{ program_mode [security_mode] [-cfgbits config_file_name] \
[-prg prg_file_name] [-svf svf_file_name] \
[-verilog verilog_file_name] [-devoe] [-devclrn] \
[-erase true|false] [-program true|false] [-verify true|false] \
[-cfm 0|1] [-word_size size] }
proc_toptile bitgen {args} {
array set templs {
-bin     1
-cfgbits 1
-rawbits 2
-tcl     1
-prg     1
-svf     1
-verilog 1
-devoe   0
-devclrn 0
-erase   1
-program 1
-verify  1
-cfm     1
-word_size 1
-download_chip 1
}

set modes [parse_cmd_args $args templs arg_vals 0 2]
set binFile     {}
set cfgbitsFile {}
set prgFile     {}
set svfFile     {}
set verilogFile {}
set rawbitsFile {}
set rawmaskFile {}
set prg_mode    {}
set sec_mode    {}
set dedicate_devoe   false
set dedicate_devclrn false
set erase            true
set program          true
set verify           true
set cfm              -1
set word_size        8
set download_chip    ALTA576S1B256
if { [llength $modes] >= 1 } {
set prg_mode [lindex $modes 0]
}
if { [llength $modes] >= 2 } {
set sec_mode [lindex $modes 1]
}
if { [array_has_key arg_vals -bin] } {
set binFile [array_find_key arg_vals -bin]
}
if { [array_has_key arg_vals -cfgbits] } {
set cfgbitsFile [array_find_key arg_vals -cfgbits]
}
if { [array_has_key arg_vals -tcl] } {
set prgFile [array_find_key arg_vals -tcl]
}
if { [array_has_key arg_vals -prg] } {
set prgFile [array_find_key arg_vals -prg]
}
if { [array_has_key arg_vals -svf] } {
set svfFile [array_find_key arg_vals -svf]
}
if { [array_has_key arg_vals -verilog] } {
set verilogFile [array_find_key arg_vals -verilog]
}
if { [array_has_key arg_vals -rawbits] } {
set rawbits [array_find_key arg_vals -rawbits]
set rawbitsFile [lindex $rawbits 0]
set rawmaskFile [lindex $rawbits 1]
}
if { [array_has_key arg_vals -devoe] } {
set dedicate_devoe true
}
if { [array_has_key arg_vals -devclrn] } {
set dedicate_devclrn true
}
if { [array_has_key arg_vals -erase] } {
set erase [array_find_key arg_vals -erase]
}
if { [array_has_key arg_vals -program] } {
set program [array_find_key arg_vals -program]
}
if { [array_has_key arg_vals -verify] } {
set verify [array_find_key arg_vals -verify]
}
if { [array_has_key arg_vals -cfm] } {
set cfm [array_find_key arg_vals -cfm]
}
if { [array_has_key arg_vals -word_size] } {
set word_size [array_find_key arg_vals -word_size]
}
if { $binFile == {} && $cfgbitsFile == {} && $prgFile == {} && $svfFile == {} && $verilogFile == {} && $rawbitsFile == {} } {
error "Need to specify at least one type of bit stream file (bin, cfgbits, prg, svf, or verilog)"
}
if { [string tolower $prg_mode] == "download" } {
if { $svfFile == {} } {
error "Only svf is supported in download mode"
}
set tempBin $::alta_work/cfg.bin
if { [file exists $binFile] } {
set download_cfg $binFile
} else {
bitgen_cmd $tempBin {} {} {} {} {} {} normal [string tolower $sec_mode] $dedicate_devoe $dedicate_devclrn $erase $program $verify $cfm $word_size
set download_cfg $tempBin
}
if { [array_has_key arg_vals -download_chip] } {
set download_chip [array_find_key arg_vals -download_chip]
}
set chip_info [get_device_info_cmd $download_chip]
if { $chip_info == "NULL" } {
error "Wrong download chip $download_chip specified"
}
set insert_size      true
set insert_signature true
generate_ufm_cmd $download_cfg $svfFile $insert_size $insert_signature $chip_info
if { [file exists $svfFile] } {
tcl_info "Using config file $download_cfg to generate download file $svfFile"
}
file delete -force $tempBin
return
}

bitgen_cmd $binFile $cfgbitsFile $prgFile $svfFile $verilogFile $rawbitsFile $rawmaskFile [string tolower $prg_mode] [string tolower $sec_mode] \
$dedicate_devoe $dedicate_devclrn $erase $program $verify $cfm $word_size
}

define_cmd_and_usage "generate_ufm" { input_file output_file }
proc_toptile generate_ufm {args} {
array set templs {
-insert_size      0
-insert_signature 0
-chip_type        1
}
set args [parse_cmd_args $args templs arg_vals 2 2]
set input_file  [lindex $args 0]
set output_file [lindex $args 1]
set insert_size      [expr [array_has_key arg_vals -insert_size      ] ? true : false]
set insert_signature [expr [array_has_key arg_vals -insert_signature ] ? true : false]
set chip_type [expr {[array_has_key arg_vals -chip_type] ? [array_find_key arg_vals -chip_type] : ""}]
set chip_info [get_device_info_cmd $chip_type]
if { ![is_null chip_type] && $chip_info == "NULL" } {
warn "Wrong chip type $chip_type specified. Using default type."
}
generate_ufm_cmd $input_file $output_file $insert_size $insert_signature $chip_info
}

define_cmd_and_usage "clamp"  { pin_name [-low|-high|-tri|-hold] }
proc_toptile clamp {args} {
array set templs {
-low  0
-high 0
-tri  0
-hold 0
}
set args [parse_cmd_args $args templs arg_vals 1 1]
if { [array size arg_vals] != 1 } {
error "Need to specify one and only one clamp mode: -low, -high, -tri, or -hold"
}
# same order as in enum CLAMP_MODE
if { [array_has_key arg_vals -tri] } {
set mode 0
}
if { [array_has_key arg_vals -high] } {
set mode 1
}
if { [array_has_key arg_vals -low] } {
set mode 2
}
if { [array_has_key arg_vals -hold] } {
set mode 3
}
clamp_cmd [lindex $args 0] $mode
}

define_cmd_and_usage "generate_clamp" { output_file }
proc_toptile generate_clamp {args} {
array set templs {
-verilog 0
}
set output_file [parse_cmd_args $args templs arg_vals 1 1]
set verilog false
if { $output_file == {} } {
error "No output specified"
}
if { [array_has_key arg_vals -verilog] } {
set verilog true
}
generate_clamp_cmd $output_file $verilog
}

# Always return the core device type, since all types with the same core have same device id
proc_arched get_chip_type {args} {
array set templs {
-build 0
-cfg   1
-jtag  0
-type  1
}
parse_cmd_args $args templs arg_vals 0 0
set device_infos [get_device_infos_cmd true]
set build [array_has_key arg_vals -build]
set dev_id ""
if { [array_has_key arg_vals -jtag] } {
set dev_id [format %d [jtag_device_id_cmd]]
} elseif { [array_has_key arg_vals -cfg] } {
set cfg_file [array_find_key arg_vals -cfg]
set dev_id [get_device_id_from_cfg_file_cmd $cfg_file]
}
set chip_type ""
set type [array_find_key arg_vals -type]
foreach chip_info $device_infos {
if { [is_null type] && $dev_id == [$chip_info device_id] || $type == [$chip_info type] } {
set chip_type $type
if [is_null chip_type] {
set chip_type [$chip_info core]
}
if { $build && [$chip_info core] != [get_current_device_type -core] } {
delete_top_array
build_top_array -type $chip_type
}
break
}
}
return $chip_type
}

define_cmd_and_usage "generate_binary" \
{ output_file -inputs input_files [-address output_address] [-bits bitsFile] \
[-lineBits bitsPerLine] [-slave | -master] [-cold_boot -warm_boot] [-reverse] }
proc_tect generate_binary {args} {
array set templs {
-slave     0
-master    0
-no_boot   0
-cold_boot 0
-warm_boot 0
-inputs    1
-address   1
-bits      1
-lineBits  1
-reverse   0
}

set BOOT_DISABLE "8'hFF"
set BOOT_ENABLE  "8'h55"

set output_file [parse_cmd_args $args templs arg_vals 1 1]
if { $output_file == {} } {
error "No output specified"
}
if { [ array_has_key arg_vals -inputs ] } {
set input_files [array_find_key arg_vals -inputs]
} else {
error "No input is specified"
}
set current_type [get_current_device_type -core]
set chip_type ""
foreach input $input_files {
set chip_type [get_chip_type -cfg $input -build]
if { ![is_null chip_type] } {
if { [is_null current_type] } {
tcl_print "Device $chip_type is identified from file $input\n"
}
break
}
}
if { [is_null chip_type] } {
error "Cannot identify device type from input files"
}
set cold_boot $BOOT_ENABLE
set warm_boot $BOOT_ENABLE
if { [[get_device_info_cmd $chip_type] family] == "AG" } {
# AG1200/AG3K has external CBSEL pins for cold boot. So do not enable by default
set cold_boot $BOOT_DISABLE
# AG1200/AG3K has a bug so that warm boot cannot be enabled by default
set warm_boot $BOOT_DISABLE
}
if { [ array_has_key arg_vals -no_boot ] } {
set cold_boot $BOOT_DISABLE
set warm_boot $BOOT_DISABLE
}
if { [ array_has_key arg_vals -cold_boot ] } {
set cold_boot $BOOT_ENABLE
}
if { [ array_has_key arg_vals -warm_boot ] } {
set warm_boot $BOOT_ENABLE
}
set slave_mode  [expr [array_has_key arg_vals -slave ] ? true : false]
set master_mode [expr [array_has_key arg_vals -master] ? true : false]

if { $master_mode } {
set features [list $cold_boot $warm_boot]
} else {
set features {}
}
set address {}
if { [ array_has_key arg_vals -address ] } {
set address [array_find_key arg_vals -address]
}
set bitsFile {}
if { [ array_has_key arg_vals -bits ] } {
set bitsFile [array_find_key arg_vals -bits]
}
set bitsPerLine 8
if { [ array_has_key arg_vals -lineBits ] } {
set bitsPerLine [array_find_key arg_vals -lineBits]
}
set reverseByte [array_has_key arg_vals -reverse]
generate_binary_cmd $output_file $bitsFile $bitsPerLine $reverseByte $features $input_files $address

# restore previous device if necessary
if { ![is_null current_type] && $current_type != $chip_type } {
delete_top_array
build_top_array -type $current_type
}
}

define_cmd_and_usage "generate_programming_file" \
{ input_file \
[-prg prg_file_name] [-svf svf_file_name] [-as as_file_name] [-hybrid hybrid_file_name] \
[-verilog verilog_file_name] [-erase true|false] [-program true|false] \
[-verify true|false] }
define_cmd_alias generate_svf generate_programming_file
proc_toptile generate_programming_file {args} {
array set templs {
-from_binary 0
-from_ascii  0
-offset      1
-tcl         1
-prg         1
-as          1
-svf         1
-hybrid      1
-verilog     1
-erase       1
-program     1
-verify      1
}
set args [parse_cmd_args $args templs arg_vals 1 1]
set inputFile $args
set offset      0
set prgFile     {}
set asFile      {}
set svfFile     {}
set hybridFile  {}
set verilogFile {}
set erase       true
set program     true
set verify      true
if { [array_has_key arg_vals -offset] } {
set offset [array_find_key arg_vals -offset]
}
if { [array_has_key arg_vals -tcl] } {
set prgFile [array_find_key arg_vals -tcl]
}
if { [array_has_key arg_vals -prg] } {
set prgFile [array_find_key arg_vals -prg]
}
if { [array_has_key arg_vals -as] } {
set asFile [array_find_key arg_vals -as]
}
if { [array_has_key arg_vals -svf] } {
set svfFile [array_find_key arg_vals -svf]
}
if { [array_has_key arg_vals -hybrid] } {
# Only write hybrid file when the prepare function exists
set prepare_proc "hybrid_prepare_[get_current_device_type]"
if { [info procs $prepare_proc] != "" } {
set hybridFile [array_find_key arg_vals -hybrid]
}
}
if { [array_has_key arg_vals -verilog] } {
set verilogFile [array_find_key arg_vals -verilog]
}
if { [array_has_key arg_vals -erase] } {
set erase [array_find_key arg_vals -erase]
}
if { [array_has_key arg_vals -program] } {
set program [array_find_key arg_vals -program]
}
if { [array_has_key arg_vals -verify] } {
set verify [array_find_key arg_vals -verify]
}
generate_programming_file_cmd $inputFile $offset $prgFile $asFile $svfFile \
$hybridFile $verilogFile $erase $program $verify
}

define_cmd_and_usage "generate_mcu_file" { input_file output_file [-chip_type type] [-address address] }
proc_tect generate_mcu_file {args} {
array set templs {
-chip_type 1
-address   1
}
set args [parse_cmd_args $args templs arg_vals 2 2]
set input_file  [lindex $args 0]
set output_file [lindex $args 1]
set chip_type [get_current_device_type]
if { [is_null chip_type] } {
if { [array_has_key arg_vals -chip_type] } {
set chip_type [array_find_key arg_vals -chip_type]
set chip_type [get_chip_type -build -type $chip_type]
if { [is_null chip_type] } {
error "Wrong chip type $chip_type specified."
}
} else {
error "No chip loaded. Use -chip_type to specify a valid chip type."
}
}
set address -1
if { [ array_has_key arg_vals -address ] } {
set address [array_find_key arg_vals -address]
}
generate_mcu_file_cmd $input_file $output_file [format %d $address]
}

define_cmd_and_usage "usb_flush" {}
proc_tect usb_flush {args} {
usb_flush_cmd
}

define_cmd_and_usage "usb_connect" {}
proc_tect usb_connect {args} {
if { ! [usb_connect_cmd] } {
error "Cable connection failed!"
}
}

define_cmd_and_usage "usb_close" {}
proc_tect usb_close {args} {
if { ! [usb_close_cmd] } {
error "Encountered errors!"
}
}

define_cmd_and_usage "runtest" { count [-tck] [-sec] }
proc_tect runtest {args} {
array set templs {
-tck 0
-sec 0
}
set num [parse_cmd_args $args templs arg_vals 1 1]
set is_tck [array_has_key arg_vals -tck]
set is_sec [array_has_key arg_vals -sec]
runtest_cmd $num $is_tck $is_sec
}

define_cmd_and_usage "sir" { ir_length [-tdi tdi] }
proc_tect sir {args} {
array set templs {
-tdi  1
-tdo  1
-mask 1
}
set ir_length [parse_cmd_args $args templs arg_vals 1 1]
set tdi  [array_find_key arg_vals -tdi]
set tdo  [array_find_key arg_vals -tdo]
set mask [array_find_key arg_vals -mask]

sir_cmd $ir_length $tdi $tdo $mask
}

define_cmd_and_usage "sdr" { dr_length [-tdi tdi] [-tdo tdo] [-mask mask] }
proc_tect sdr {args} {
array set templs {
-tdi  1
-tdo  1
-mask 1
-wait 0
}
set args [parse_cmd_args $args templs arg_vals 1 2]
set tdi  [array_find_key arg_vals -tdi]
set tdo  [array_find_key arg_vals -tdo]
set mask [array_find_key arg_vals -mask]
set dr_length [lindex $args 0]
set waitBytes 0
if { [llength $args] > 1 } {
set waitBytes [lindex $args 1]
} elseif { [array_has_key arg_vals -wait] } {
set waitBytes 1
}

sdr_cmd $dr_length $tdi $tdo $mask $waitBytes
}

define_cmd_and_usage "read_flash" { file_name [size] [-k|-m] [-offset offset] [-from from] [-to to] }
proc_arched read_flash {args} {
array set templs {
-k      0
-m      0
-bin    0
-offset 1
-from   1
-to     1
}
set args [parse_cmd_args $args templs arg_vals 1 2]
set file_name [lindex $args 0]
set size 0
if { [llength $args] > 1 } {
set size [format %d [lindex $args 1]]
}
set unit 1
if { [array_has_key arg_vals -k] } {
set unit 1024
}
if { [array_has_key arg_vals -m] } {
set unit [expr 1024 * 1024]
}
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [format %d [array_find_key arg_vals -offset]]
}
set from 0
if { [array_has_key arg_vals -from] } {
set from [format %d [array_find_key arg_vals -from]]
error_if_not_int $from "from address must be an integer" { $from >= 0 }
set offset [expr $unit * $from]
}
if { [array_has_key arg_vals -to] } {
set to [format %d [array_find_key arg_vals -to]]
error_if_not_int $to "to address must be an integer" { $to >= 0 }
set size [expr $to - $from + 1]
}
error_if_not_int $size "read size must be a positive integer" { $size > 0 }
read_flash_cmd $file_name $offset [expr $size * $unit]
}

define_cmd_and_usage "write_flash" { file_name [size] [-k|-m] [-offset offset] }
proc_arched write_flash {args} {
array set templs {
-k      0
-m      0
-bin    0
-offset 1
}
set args [parse_cmd_args $args templs arg_vals 1 2]
set file_name [lindex $args 0]
set size 0
if { [llength $args] > 1 } {
set size [format %d [lindex $args 1]]
}
set unit 1
if { [array_has_key arg_vals -k] } {
set unit 1024
}
if { [array_has_key arg_vals -m] } {
set unit [expr 1024 * 1024]
}
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [format %d [array_find_key arg_vals -offset]]
}
error_if_not_int $size "read size must be a positive integer" { $size >= 0 }
write_flash_cmd $file_name $offset [expr $size * $unit]
}

define_cmd_and_usage "erase_flash" { [-from from] [-to to] }
proc_arched erase_flash {args} {
array set templs {
-from 1
-to   1
}
set args [parse_cmd_args $args templs arg_vals 0 0]
set from -1
set to   -1
if { [array_has_key arg_vals -from] } {
set from [format %d [array_find_key arg_vals -from]]
}
error_if_not_int $from "from address must be an integer"
if { $from >= 0 } {
if { [array_has_key arg_vals -to] } {
set to [format %d [array_find_key arg_vals -to]]
}
error_if_not_int $to "to address must be an integer" { $to >= 0 }
}
erase_flash_cmd $from $to
}

define_cmd_and_usage "read_config_reg" {address}
proc_arched read_config_reg {args} {
array set templs {
}
parse_cmd_args $args templs arg_vals 1 1
set reg_addr [format %d [lindex $args 0]]
return "0x[format %X [read_config_reg_cmd $reg_addr]]"
}

define_cmd_and_usage "write_config_reg" {address value}
proc_arched write_config_reg {args} {
array set templs {
-last 0
}
parse_cmd_args $args templs arg_vals 2 2
set reg_addr [format %d [lindex $args 0]]
set reg_val  [format %d [lindex $args 1]]
set last_frame [array_has_key arg_vals -last]
write_config_reg_cmd $reg_addr $reg_val $last_frame
}

proc_arched read_decoders {args} {
array set templs {
}
parse_cmd_args $args templs arg_vals 1 1
set filename [lindex $args 0]
get_chip_type -build -jtag
read_decoders_cmd $filename
}

define_cmd_and_usage "jtag_device_id" {[-id]}
proc_tect jtag_device_id {args} {
array set templs {
-id 0
}
parse_cmd_args $args templs arg_vals 0 0
set device_id [jtag_device_id_cmd]
if {[array_has_key arg_vals -id]} {
return $device_id
} elseif { $device_id == "0x00000000" || $device_id == "0xFFFFFFFF" } {
error "JTAG device ID not found"
return false
} else {
tcl_print "JTAG device ID: $device_id\n"
return true
}
}

define_cmd_and_usage "jtag_flash_id" { [-cmd FLASH_ID_CMD] [-dummy_bytes dummy_bytes] [-data_bytes data_bytes] [-id] }
proc_arched jtag_flash_id { args } {
array set templs {
-id          0
-cmd         1
-dummy_bytes 1
-data_bytes  1
}
parse_cmd_args $args templs arg_vals 0 0
set cmd "0x4B"
set dummy_bytes 4
set data_bytes  8
if { [array_has_key arg_vals -cmd] } {
set cmd [array_find_key arg_vals -cmd]
}
if { [array_has_key arg_vals -dummy_bytes] } {
set dummy_bytes [array_find_key arg_vals -dummy_bytes]
}
if { [array_has_key arg_vals -data_bytes] } {
set data_bytes [array_find_key arg_vals -data_bytes]
}
if { $dummy_bytes < 3 } {
error "Dummy bytes cannot be less than 3"
}
set flash_id [jtag_flash_id_cmd [format %d $cmd] $dummy_bytes $data_bytes]
if { [array_has_key arg_vals -id] } {
return $flash_id
} else {
tcl_print "JTAG flash ID: $flash_id\n"
return true
}
}

define_cmd_and_usage "jtag_state" { state [-force] }
proc_tect jtag_state {args} {
array set templs {
-force 0
}
set args [parse_cmd_args $args templs arg_vals 1 1]
set force [array_has_key arg_vals -force]
jtag_state_cmd $args $force
}

define_cmd_and_usage "as_device_id" {[-id]}
proc_tect as_device_id {args} {
array set templs {
-id 0
}
parse_cmd_args $args templs arg_vals 0 0
set device_id [as_device_id_cmd]
if {[array_has_key arg_vals -id]} {
return $device_id
} elseif { $device_id == "0x00" || $device_id == "0xFF" } {
error "Configuration device ID not found"
return false
} else {
tcl_print "Configuration device ID: $device_id\n"
return true
}
}

define_cmd_and_usage "as_read_id" {[-id]}
proc_tect as_read_id {args} {
set device_id [as_read_id_cmd]
tcl_print "Configuration device read ID: $device_id\n"
}

define_cmd_and_usage "as_read_status" { [-cmd command] [-wait] }
proc_tect as_read_status {args} {
array set templs {
-cmd 1
-wait 0
}
set args [parse_cmd_args $args templs arg_vals 0 0]
set cmd 0x05
if { [array_has_key arg_vals -cmd] } {
set cmd [array_find_key arg_vals -cmd]
}
set wait [array_has_key arg_vals -wait]
return [as_read_status_cmd $cmd $wait]
}

define_cmd_and_usage "as_write_status" { low_byte [high_byte] }
proc_tect as_write_status {args} {
set args [parse_cmd_args $args templs arg_vals 1 2]
set  low_byte [lindex $args 0]
set high_byte 0
if { [llength $args] > 1 } {
set high_byte [lindex $args 1]
}
as_write_status_cmd $low_byte $high_byte
}

define_cmd_and_usage "as_write" { file_name [-offset offset] }
proc_tect as_write {args} {
array set templs {
-bin 0
-offset 1
}
set file_name [parse_cmd_args $args templs arg_vals 1 1]
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [array_find_key arg_vals -offset]
}
set has_signature false
as_write_cmd $file_name $offset $has_signature
}

define_cmd_and_usage "as_verify" { file_name [-offset offset] }
proc_tect as_verify {args} {
array set templs {
-bin 0
-offset 1
}
set file_name [parse_cmd_args $args templs arg_vals 1 1]
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [array_find_key arg_vals -offset]
}
set has_signature false
as_verify_cmd $file_name $offset $has_signature
}

define_cmd_and_usage "as_erase" { size [-offset offset] }
proc_tect as_erase {args} {
array set templs {
-offset 1
}
set args [parse_cmd_args $args templs arg_vals 0 1]
set size -1
if { [llength $args] >= 1 } {
set size [lindex $args 0]
}
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [array_find_key arg_vals -offset]
}
as_erase_cmd $size $offset
}

define_cmd_and_usage "as_read" { file_name size [-k|-m] [-offset offset] }
proc_tect as_read {args} {
array set templs {
-k 0
-m 0
-bin 0
-offset 1
}
set args [parse_cmd_args $args templs arg_vals 2 2]
set file_name [lindex $args 0]
set size      [lindex $args 1]
error_if_not_int $size "read size must be a positive integer" { $size > 0 }
set unit 1
if { [array_has_key arg_vals -k] } {
set unit 1024
}
if { [array_has_key arg_vals -m] } {
set unit [expr 1024 * 1024]
}
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [array_find_key arg_vals -offset]
}
as_read_cmd $file_name $offset [expr $size * $unit]
}

proc hybrid_prepare {arg_vals_ref} {
upvar 1 $arg_vals_ref arg_vals
set device_type ""
if [array_has_key arg_vals -device] {
set device_type [array_find_key arg_vals -device]
} else {
error "No device specified"
}

set prepare_proc "hybrid_prepare_$device_type"
if { [info procs $prepare_proc] == "" } {
error "Hybrid program is not supported for device $device_type"
}
global use_block_erase
set use_block_erase $::bitgen_use_block_erase
set ::bitgen_use_block_erase [$prepare_proc]
return [as_device_id]
}

proc hybrid_finish {args} {
# Issue AS_START JTAG command
sir 10 -tdi 3f7
runtest -tck 100
usb_close
global use_block_erase
set ::bitgen_use_block_erase $use_block_erase
}

define_cmd_and_usage "hybrid_write" { file_name -device device }
proc_tect hybrid_write {args} {
array set templs {
-device 1
}
set file_name [parse_cmd_args $args templs arg_vals 1 1]

if { [hybrid_prepare arg_vals] } {
set offset 0
set has_signature true
as_write_cmd  $file_name $offset $has_signature
as_verify_cmd $file_name $offset $has_signature
usb_flush
}
hybrid_finish
}

define_cmd_and_usage "hybrid_erase" { size -device device [-offset offset] }
proc_tect hybrid_erase {args} {
array set templs {
-device 1
-offset 1
}
set args [parse_cmd_args $args templs arg_vals 0 1]
set size -1
if { [llength $args] >= 1 } {
set size [lindex $args 0]
}
set offset 0
if { [array_has_key arg_vals -offset] } {
set offset [array_find_key arg_vals -offset]
}

if { [hybrid_prepare arg_vals] } {
as_erase_cmd $size $offset
}
hybrid_finish
}

# Do not provide hybrid_read command for security reason

}; # namespace alta
namespace eval alta {

proc prepare_design { top_module design_file design_flatten primitive_lib verilog_lib check_hier qsf_file} {
set ret [prefiltVerilog $design_file $design_flatten $check_hier]
if { $ret != 0 } {
set design_file $design_flatten
}

read_verilog -slice $primitive_lib
read_verilog -slice $verilog_lib
read_verilog -design_raw $design_file
link_design $top_module
ensureConstraints
pre_flatten $qsf_file
set org_db_remove_feeder_cells $::db_remove_feeder_cells
set ::db_remove_feeder_cells $::tcl_force_remove_feeder_cells
write_design -linked_with_pack $design_flatten
reset_design
set ::db_remove_feeder_cells $org_db_remove_feeder_cells
return $design_flatten
}

proc pre_flatten { qsf_file } {
if  { ! [file exists $qsf_file] } {
return
}
set fp [open $qsf_file]
array set templs {
-name 1
-to   1
-section_id 1
}
while { [gets $fp line] >= 0 } {
set args [parse_cmd_args $line templs arg_vals 0 1024 false]
if { [llength $args] >= 2 && [string tolower [lindex $args 0]] == "set_instance_assignment" } {
if { [string toupper [array_find_key arg_vals -name]] == "POST_FIT_CONNECT_TO_SLD_NODE_ENTITY_PORT" } {
set pin [lindex $args 1]
set net [array_find_key arg_vals -to]
set sec [array_find_key arg_vals -section_id]
set design_pin [get_pin_cmd $sec|$pin]
set design_net [get_net_cmd $net]
if { ! [is_null design_pin] && ! [is_null design_net] } {
connect_to_net $design_pin $design_net
tcl_info "Connecting $sec|$pin to $net"
}
}
}
}
}

proc ensure_packed_design { alta_asf alta_pinmap alta_cellmap} {
set_packed_cmd
ensurePackedDesign
source $alta_asf
readPinmap $alta_pinmap
readCellmap $alta_cellmap
return true
}

proc read_db_design { top_module slice_filtered design_filtered alta_asf alta_pinmap alta_cellmap } {
puts "Read DB design..."
read_verilog -slice  $slice_filtered
read_verilog -design $design_filtered
print_usage_cmd

if { ! [is_null top_module] } {
puts "Process design..."
link_design $top_module
if { [design_is_empty_cmd] } {
warn "Design $top_module is empty, check your setup"
return false
}
ensure_packed_design $alta_asf $alta_pinmap $alta_cellmap
ensureIoBuffers    false
ensureConstBuffers false
ensureGclkBuffers  false
ensureCaecums      false
print_usage_cmd
} else {
return false
}

return true
}


define_cmd_and_usage "read_design_and_pack" {[-top top_module] [-sdc sdc_file] design_verilog}
proc_tect read_design_and_pack {args } {
array set templs {
-top        1
-sdc        1
-gclk_level 1
-dump       1
}
set design_file [parse_cmd_args $args templs arg_vals 1 1]
set top_module ""
if { ! [array_has_key arg_vals -top] } {
fatal "Top module not specified"
} else {
set top_module [array_find_key arg_vals -top]
}
set sdc_file ""
if { [array_has_key arg_vals -sdc] } {
set sdc_file [array_find_key arg_vals -sdc]
}
set gclk_level 2
if { [array_has_key arg_vals -gclk_level] } {
set gclk_level [array_find_key arg_vals -gclk_level]
}

# Flatten/filter design first and then re-read it
set ret [read_design -hierachy 1 -primitive -top $top_module $design_file]
if { !$ret } { fatal "Failed to read design $design_file" }

if { $gclk_level == 0 } {
set ::db_gclk_max_utilization false
} elseif { $gclk_level >= 1 } {
set ::db_gclk_max_utilization    true
}
ensureNormalize    true
ensureIoBuffers    true
ensureConstBuffers true
ensureGclkBuffers  true
ensureInvertedNets true
ensureCaecums      true

set pack_result    $::alta_work/pack.tx
set design_flatten $::alta_work/flatten.vx
if { ! [is_null sdc_file] } {
read_sdc -quartus -quiet $sdc_file
}
if { [array_has_key arg_vals -dump] } {
set dump_file [array_find_key arg_vals -dump]
dump_design -linked >! $dump_file
}
set ret [pack_design -result $pack_result]
if { !$ret } { fatal "Failed to pack design" }
write_design -linked_with_pack $design_flatten
reset_design

set ret [read_design -top $top_module -pack $pack_result $design_flatten]
if { !$ret } { fatal "Failed to read packed design" }
if { ! [is_null sdc_file] } {
read_sdc -quartus -quiet $sdc_file
}

return true
}

define_cmd_and_usage "read_design" {[-top top_module] [-primitive] [-no_pack] [-hierachy level] \
[-lib verilog_lib] [-pack pack_result] [-ve ve_file] [-qsf qsf_file] design_verilog}
proc_tect read_design { args } {
if { ! [info exists ::alta_work] } {
set ::alta_work "./alta_db"
}
if { [file isdirectory $::alta_work] == 0 } {
file delete -force $::alta_work
}
file mkdir $::alta_work
reset_design

set top_array [get_top_array_cmd]
set class_dir [$top_array class_dir]

set primitive_lib "primitive.v"
set verilog_lib   "alta_lib.v"
set primitive_lib "$class_dir/$primitive_lib"
set verilog_lib   "$class_dir/$verilog_lib"

array set templs {
-primitive  0
-no_pack    0
-hierachy   1
-lib        1
-top        1
-pack       1
-ve         1
-qsf        1
-filter     1
}
set design_file [parse_cmd_args $args templs arg_vals 1 1]

set is_primitive [array_has_key arg_vals -primitive]
set is_no_pack   [array_has_key arg_vals -no_pack]
set is_hierachy 0
if { [array_has_key arg_vals -hierachy] } {
set is_hierachy [array_find_key arg_vals -hierachy]
}
if { [array_has_key arg_vals -lib] } {
set verilog_lib [array_find_key arg_vals -lib]
}
set top_module ""
if { [array_has_key arg_vals -top] } {
set top_module [array_find_key arg_vals -top]
}
set pack_result ""
if { [array_has_key arg_vals -pack] } {
set pack_result [array_find_key arg_vals -pack]
}
set ve_file "$top_module.ve"
if { [array_has_key arg_vals -ve] } {
set ve_file [array_find_key arg_vals -ve]
}
set qsf_file "$top_module.qsf"
if { [array_has_key arg_vals -qsf] } {
set qsf_file [array_find_key arg_vals -qsf]
}
set filter_result [array_find_key arg_vals -filter]

if { $is_hierachy > 0 } {
puts "Preparing design..."
set design_flatten $::alta_work/flatten.vx
set design_file [prepare_design $top_module $design_file $design_flatten $primitive_lib $verilog_lib \
[expr $is_hierachy < 2] $qsf_file ]
print_usage_cmd
}
if { $is_primitive } {
puts "Loading primitive design..."
read_verilog -slice $primitive_lib
read_verilog -slice $verilog_lib
read_verilog -design $design_file
if { ! [is_null top_module] } {
link_design $top_module
if { [design_is_empty_cmd] } {
warn "Design $top_module is empty, check your setup"
return false
}
} else {
return false
}
print_usage_cmd
return true

} elseif { $is_no_pack } {
puts "Loading full design..."
read_verilog -slice $verilog_lib
read_verilog -design $design_file
if { ! [is_null top_module] } {
link_design $top_module
if { [design_is_empty_cmd] } {
warn "Design $top_module is empty, check your setup"
return false
}
} else {
return false
}
print_usage_cmd
return true

} else {
set slice_filtered  $::alta_work/alta_lib.v
set design_packed   $::alta_work/packed.vx
set design_filtered $::alta_work/filtered.vx
set alta_asf        $::alta_work/alta.asf
set alta_pinmap     $::alta_work/alta.pinmap
set alta_cellmap    $::alta_work/alta.cellmap
puts "Pseudo pack design..."
if { ! [is_null pack_result] } {
set ret [pack_pseudo_cmd $design_file $ve_file $design_packed $pack_result]
if { !$ret } { error "Failed to pseudo pack design" }
} else {
set ret [pack_pseudo_cmd $design_file $ve_file $design_packed]
if { !$ret } { error "Failed to pseudo pack design" }
}
print_usage_cmd

if { [is_null filter_result] } {
puts "Filter verilog..."
set ret [filterVerilog $verilog_lib $slice_filtered $design_packed $design_filtered]
print_usage_cmd
if { !$ret } { error "Failed to process input verilog" }
return [read_db_design "$top_module" $slice_filtered $design_filtered $alta_asf $alta_pinmap $alta_cellmap]

} else {
return [read_db_design "$top_module" $verilog_lib $filter_result $alta_asf $alta_pinmap $alta_cellmap]
}
}
}

define_cmd_and_usage "load_db" {}
proc_tect load_db { args } {
if { ! [info exists ::alta_work] } {
set ::alta_work "./alta_db"
}
reset_design

array set templs {
-top        1
}
parse_cmd_args $args templs arg_vals 0 0

set top_module ""
if { [array_has_key arg_vals -top] } {
set top_module [array_find_key arg_vals -top]
}

set slice_filtered  $::alta_work/alta_lib.v
set design_filtered $::alta_work/filtered.vx
set alta_asf        $::alta_work/alta.asf
set alta_aqf        $::alta_work/alta.aqf
set alta_pinmap     $::alta_work/alta.pinmap
set alta_cellmap    $::alta_work/alta.cellmap
if { ! [read_db_design "$top_module" $slice_filtered $design_filtered $alta_asf $alta_pinmap $alta_cellmap] } {
return false
}
if { [file exists "$alta_aqf"] } {
source "$alta_aqf"
}

return true
}

define_cmd_and_usage "reset_design" {}
proc_tect reset_design { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0
clear_ta_cmd
clear_constraints_cmd
clear_design_cmd
}

define_cmd_and_usage "pack_design" {-result result_file}
proc_linked pack_design { args } {
array set templs {
-check_only  0
-result      1
}
parse_cmd_args $args templs arg_vals 0 0

set check_only [array_has_key arg_vals -check_only]
set result_file ""
if { ! [array_has_key arg_vals -result] } {
error "Result file not specified"
} else {
set result_file [array_find_key arg_vals -result]
}

return [pack_design_cmd $check_only $result_file]
}

}; # namespace alta
namespace eval alta {

define_cmd_and_usage "check_critical_io" {[-input inputs] [-output outputs]}
proc_linked_or_packed check_critical_io { args } {
array set templs {
-input      1
-output     1
}
parse_cmd_args $args templs arg_vals 0 0

set  input [array_find_key arg_vals -input ]
set output [array_find_key arg_vals -output]

set types {Term}
find_and_collect_objects_by_type $input  colls ignores $types {} true
set critical_inputs $colls(Term)
find_and_collect_objects_by_type $output colls ignores $types {} true
set critical_outputs $colls(Term)

return [check_critical_io_cmd $critical_inputs $critical_outputs]
}

define_cmd_and_usage "check_spi_flash_pin" {[-spi pins]}
proc_linked_or_packed check_spi_flash_pin { args } {
array set templs {
-spi        1
}
parse_cmd_args $args templs arg_vals 0 0

set spi [array_find_key arg_vals -spi]

set types {Term}
find_and_collect_objects_by_type $spi colls ignores $types {} true
set spi_pins $colls(Term)

return [check_spi_flash_pin_cmd $spi_pins]
}

define_cmd_and_usage "check_176_pin_assignment" {}
proc_linked_or_packed check_176_pin_assignment { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_176_pin_assignment_cmd]
}

define_cmd_and_usage "check_phy_tx" {-out out_pins -ctrl ctrl_pins -clk clk_pins}
proc_linked_or_packed check_phy_tx { args } {
array set templs {
-out        1
-ctrl       1
-clk        1
}
parse_cmd_args $args templs arg_vals 0 0

set out_pins {}
if { ! [array_has_key arg_vals -out] } {
error "PHY output pins must be specified"
} else {
set out [array_find_key arg_vals -out]
set types {Term}
find_and_collect_objects_by_type $out colls ignores $types {} true
set out_pins $colls(Term)
}

set ctrl_pins {}
if { ! [array_has_key arg_vals -ctrl] } {
error "PHY output control pins must be specified"
} else {
set ctrl [array_find_key arg_vals -ctrl]
set types {Term}
find_and_collect_objects_by_type $ctrl colls ignores $types {} true
set ctrl_pins $colls(Term)
}

set clk_pins {}
if { ! [array_has_key arg_vals -clk] } {
error "PHY output clock pins must be specified"
} else {
set clk [array_find_key arg_vals -clk]
set types {Term}
find_and_collect_objects_by_type $clk colls ignores $types {} true
set clk_pins $colls(Term)
}

return [check_phy_tx_cmd $out_pins $ctrl_pins $clk_pins]
}

define_cmd_and_usage "check_phy_rx" {-in in_pins -ctrl ctrl_pins -clk clk_pins}
proc_linked_or_packed check_phy_rx { args } {
array set templs {
-in         1
-ctrl       1
-clk        1
}
parse_cmd_args $args templs arg_vals 0 0

set in_pins {}
if { ! [array_has_key arg_vals -in] } {
error "PHY input pins must be specified"
} else {
set in [array_find_key arg_vals -in]
set types {Term}
find_and_collect_objects_by_type $in colls ignores $types {} true
set in_pins $colls(Term)
}

set ctrl_pins {}
if { ! [array_has_key arg_vals -ctrl] } {
error "PHY input control pins must be specified"
} else {
set ctrl [array_find_key arg_vals -ctrl]
set types {Term}
find_and_collect_objects_by_type $ctrl colls ignores $types {} true
set ctrl_pins $colls(Term)
}

set clk_pins {}
if { ! [array_has_key arg_vals -clk] } {
error "PHY input clock pins must be specified"
} else {
set clk [array_find_key arg_vals -clk]
set types {Term}
find_and_collect_objects_by_type $clk colls ignores $types {} true
set clk_pins $colls(Term)
}

return [check_phy_rx_cmd $in_pins $ctrl_pins $clk_pins]
}

define_cmd_and_usage "check_sdram_output" \
{-data data_pins -ctrl ctrl_pins -clk clk_pins -clock clocks}
proc_linked_or_packed check_sdram_output { args } {
array set templs {
-data       1
-ctrl       1
-clk        1
-clock      1
}
parse_cmd_args $args templs arg_vals 0 0

set data_pins {}
if { ! [array_has_key arg_vals -data] } {
error "SDRAM data pins must be specified"
} else {
set data [array_find_key arg_vals -data]
set types {Term}
find_and_collect_objects_by_type $data colls ignores $types {} true
set data_pins $colls(Term)
}

set ctrl_pins {}
if { ! [array_has_key arg_vals -ctrl] } {
error "SDRAM control pins must be specified"
} else {
set ctrl [array_find_key arg_vals -ctrl]
set types {Term}
find_and_collect_objects_by_type $ctrl colls ignores $types {} true
set ctrl_pins $colls(Term)
}

set clk_pins {}
if { ! [array_has_key arg_vals -clk] } {
error "SDRAM clock pins must be specified"
} else {
set clk [array_find_key arg_vals -clk]
set types {Term}
find_and_collect_objects_by_type $clk colls ignores $types {} true
set clk_pins $colls(Term)
}

set clocks {}
if { ! [array_has_key arg_vals -clock] } {
error "SDRAM clocks must be specified"
} else {
set clock [array_find_key arg_vals -clock]
set types {Clock}
find_and_collect_objects_by_type $clock colls ignores $types {} true
set clocks $colls(Clock)
}

return [check_sdram_output_cmd $data_pins $ctrl_pins $clk_pins $clocks]
}

define_cmd_and_usage "check_sdram_input" {-data data_pins}
proc_linked_or_packed check_sdram_input { args } {
array set templs {
-data       1
}
parse_cmd_args $args templs arg_vals 0 0

set data_pins {}
if { ! [array_has_key arg_vals -data] } {
error "SDRAM data pins must be specified"
} else {
set data [array_find_key arg_vals -data]
set types {Term}
find_and_collect_objects_by_type $data colls ignores $types {} true
set data_pins $colls(Term)
}

return [check_sdram_input_cmd $data_pins]
}

define_cmd_and_usage "check_pll_phase_lock" {}
proc_linked_or_packed check_pll_phase_lock { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_pll_phase_lock_cmd]
}

define_cmd_and_usage "check_pll_phase_xref" {}
proc_linked_or_packed check_pll_phase_xref { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_pll_phase_xref_cmd]
}

define_cmd_and_usage "check_clock_skew" {}
proc_linked_or_packed check_clock_skew { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_clock_skew_cmd]
}

define_cmd_and_usage "check_half_cycle" {}
proc_linked_or_packed check_half_cycle { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_half_cycle_cmd]
}

define_cmd_and_usage "check_global_route" {}
proc_linked_or_packed check_global_route { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_global_route_cmd]
}

define_cmd_and_usage "check_unconstraint_path" {}
proc_linked_or_packed check_unconstraint_path { args } {
array set templs {
}
parse_cmd_args $args templs arg_vals 0 0

return [check_unconstraint_path_cmd]
}

}; # namespace alta
namespace eval alta {
proc hybrid_prepare_AG1280Q48 {args} {
set sh_continue_on_error false
#
# Header
#
usb_connect
runtest -tck 1
if { ! [jtag_device_id] } {
exit
}
sir 10 -tdi 3e3
runtest -tck 1500
sir 10 -tdi 3f8
runtest -tck 100
#
# IdCode
#
sir 10 -tdi 6
runtest -tck 100
sdr 32 -tdi 00000000 -tdo 00120010 -mask ffffffff
#
# Program
#
sir 10 -tdi 3fc
runtest -tck 100
sdr 8 -tdi 00
sir 10 -tdi 3fa
runtest -tck 100
#
#  Array header, write group 1, chain 0, length 200, idleClk 2
#
#
#  Data stream, 7 frames * 1 lines/frame * 32 bits/line
#
#
#  Array header, write group 1, chain 1, length 97, idleClk 2
#
#
#  Data stream, 4 frames * 1 lines/frame * 32 bits/line
#
#
#  Array header, write group 0, chain 0, length 373760, idleClk 2
#
#
#  Data stream, 11680 frames * 1 lines/frame * 32 bits/line
#
#
#  Register header, write address 2, last frame
#
#
#  Reg data: 00000F8F
#
sdr 374368 \
-tdi  f1f00000403f0054000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c18fffffffffffffffffffffffffff000f0306000bd0c18ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c3dfffffffffffffffffffffffffff000f030f400ba043dffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003e0c19fffffffffffffffffffffffffff000f03064003c0c19ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c8418fffffffffffffffffffffffffff000ec1060003c0c18ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c19fffffffffffffffffffffffffff000f0306400380419ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c1efffffffffffffffffffffffffff000f03078003c0c1effff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc0038041ffffffffffffffffffffffffffff000e0107c003c0c1fffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00380010fffffffffffffffffffffffffff000e0004000380010ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00380010fffffffffffffffffffffffffff000e0004000380010ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00380010fffffffffffffffffffffffffff000e0004000380010ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00380010fffffffffffffffffffffffffff000e0004000380010ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c1ffffffffffffffffffffffffffff000f0307c003c0c1fffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c1efffffffffffffffffffffffffff000f01078003c0c1effff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c19fffffffffffffffffffffffffff000f03064003c0c19ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c18fffffffffffffffffffffffffff000f0306000380418ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc003c0c19fffffffffffffffffffffffffff000f01064003c0c19ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe003c0c3dfffffffffffffffffffffffffff001f030f4103e0c3dffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc803c0c18fffffffffffffffffffffffffff004f0306040390418ffff000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000df000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000df000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000df000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000df000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000df000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000df000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000050000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000050000000df000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000df000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00000000800000000ffffffffffffffffff000000000000000000001000000003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe00000fffd00000fffffffffffffffffffff800003ffe00000fffb000000003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe00000fffd00010fffffffffffffffffffff800003ffe00000fffb000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00000000800000000ffffffffffffffffff000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000df000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000050000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000050000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000ff000000000000000000000000000000000000000000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000058000000ff000000000000000000000000014000000050001000000003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000008000000ff000000000000000000000000000000000000000000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffff6161c000000008000000ff000000000000000000000000000000000000001000000000003c0c3d000f030f4003c0c3dfffffffffffffffffffffffffff000f030f4003c0c3d000f030f4003c0c3dffffe1e1c000000008000000ff000000000000000000000000000000000000001000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0c19ffff6161c000000058000000df000000000000000000000000014000000050001000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffffe1e1c000000008000000ff000000000000000000000000000000000000000000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffff6161c000000008000000ff000000000000000000000000000000000000001000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0c19ffffe1e1c000000008000000df000000000000000000000000000000000000001000000000003c0c1e000f03078003c0c1efffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffffffffc000000058000000ff000000000000000000000000014000000050001000000000003c0c1f000f0307c003c0c1ffffffffffffffffffffffffffff000f0307c003c0c1f000f0307c003c0c1ffffe0001c000000008000000df00000000000000000000000000000000000000000000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010000e0004000380010fffe0001c000000008000000ff00000000000000000000000000000000000000100000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010000e0004000380010fffe0001c000000008000000ff00000000000000000000000000000000000000100000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010000e0004000380010fffe0001c000000058000000ff00000000000000000000000001400000005000100000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010000e0004000380010fffe0001c000000008000000ff000000000000000000000000000000000000000000000000003c0c1f000f0307c003c0c1ffffffffffffffffffffffffffff000f0307c003c0c1f000f0307c003c0c1fffffff81c000000008000000ff000000000000000000000000000000000000001000000000003c0c1e000f03078003c0c1efffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffffff81c000000008000000ff000000000000000000000000000000000000001000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0c19ffff6161c000000058000000df000000000000000000000000014000000050001000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffffe1e1c000000008000000df000000000000000000000000000000000000000000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffff6161c000000008000000ff000000000000000000000000000000000000001000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0c19ffffe1e1c000000008000000ff000000000000000000000000000000000000001000000000003c0c3d000f030f4003c0c3dfffffffffffffffffffffffffff000f030f4003c0c3d000f030f4003c0c3dffffffffc000000058000000ff000000000000000000000000014000000050001000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18ffffffffc000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000df0000000000000000000000000140000000500000001400000005000000014000000050000000df00000000000000000000000001400000005000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000001000000003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fffb000000003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fffb0000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff00000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000400000000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000df00000000000000000000000000000400000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000df0000000000000000000000000140000000500000001400000005000000014000000050000000df00000000000000000000000001400000005000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000001000000003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fffb000000003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fffb0000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff00000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000df00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000009000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000000000000000000000800a000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000800000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000002000000000000000000100000000000000005000000014000000050000000df0000000000000000000000000140000000500000001400000005000000014020000050000000df00000000000000000000000001400000005000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000020000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000001000000003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fffb000000003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fffb0000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000000000000000000000800000000ffffffffffffffffff00000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000140000000000000000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000df00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000002800000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000030000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005000000014000000058000000df00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000010908000000df00000000000000000000000b0e00410107d000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000420048220000ff0000000000000000000000801f0018000fc000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000102058000000ff0000000000000000002000325f400025065000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000030008000000ff0000000000000000008000001e00088016a000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000450788000000df00000000000000000000200000000000278000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000001348000000df0000000000000000000004000022000b07c000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000010fd8000000ff0000000000000000000008000140041007d000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000788000000ff00000000000000000000200000011203170000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000200018100000ff00000000000000000080008019800082c38000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000207d8020000ff0000000000000000001000081f00080807c000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000058000000ff00000000000000000000008019500000a7d000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000002200000788012000ff000000000000000000c000081e080006078000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000800018000000df0000000000000000000400820402000007a000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000080147d8000000ff00000000000000000000400a03200001405000100000000000000005000000014000000058000000df00000000000000000000000001400000005000000014000000050000000140000007f8100000df00000000000000000000010c01400000007000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000058020000ff0000000000000000000000010200000007e000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000488000000ff00000000000000000000000c3e000000032000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000000498000000df0000000000000000000000801f000000031000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000014000000378000000ff0000000000000000000000001f50000007f000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000014048000000ff000000000000000000c0008c9608000144e000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000308000000ff0000000000000000000000841f80000004a000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000318000000ff00000000000000000002400899000000049000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014020000050000000140000027f8000000ff0000000000000000000001081fc0000024f000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000002000000000000000000010348000000ff0000000000000000000000001e400001006880000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000480000000ff00000000000000000000000201000000033000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000490000000ff000000000000000000c0000117400000031000100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000002370000000ff0000000000000000008801148141000027f000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000010040000000ff0000000000000000000000001e80190104e000000000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000044000000000000302000000ff0000000000000000000000008102000004a000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000311000000ff0000000000000000000000040d600000049000100000000000000005000000014000000050000000df00000000000000000000000001400000005000000014000000050000000140080007f0000000df0000000000000000000020020150000004f000100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000812340000000df0000000000000000000004021e88000120700000000000000000000000000000000000000800000000ffffffffffffffffff00000000000000000000000000000000000000000000400090a800000000ffffffffffffffffff010800120040000080001000000003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00004fffd00000fffffffffffffffffffff800033ffe00942fffb000000003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00408fffd00010fffffffffffffffffffff800103ffe00004fffb0000000000000000000000000000000000800000000ffffffffffffffffff00000000000000000000000000000000000000000000420080a800000000ffffffffffffffffff01000002004044009000100000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000207a0000000ff0000000000000000000000021f408000033008100000000000000000000000000000000000000000df0000000000000000000000000000000000000000000000000000000000000000100790000000df00000000000000000000000201001000031010100000000000000005000000014000000050000000ff0000000000000000000000000140000000500000001400000005000000014000010350000000ff0000000000000000000000001f40000007f000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000004480000000ff0000000000000000000000001e80000124e000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000105a0000000ff0000000000000000000200001100200004a008100000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000001283d0000000ff0000000000000000000040045b404000049010100000000000000005000000014000000050000000ff00000000000000000000000001400000005000000014000000058800000160000107d0000000ff0000000000000000000000080140000014f000100000000000000000000000000000000000000000ff000000000000000000000000000000000000000000000000000000000000020c0a2780000000ff0000000000000000000031061e000001007000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000000708000000ff0000000000000000000000941e000000032000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000b47c8012000ff0000000000000000000000003f011000031024100000000000000005000000014000000058000000ff000000000000000000000000014000000050000000140000000500000001400000c7d8000000ff00000000000000000000000c3f40000017f000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000002200420388000000ff0000000000000000000000401a00000104e000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000040000000000000000000447e8000000ff0000000000000000000000341e00020004b000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000010000000000000000000907d8000000ff0000000000000000000000003f000800049000100000000000000005000000014000000058000000df00000000000000000000000001400000005000000014000000050000000140000007d8000000df0000000000000000000008043f40040004f000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000132688000000ff0000000000000000000020000c000201106024000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000082788000000ff0000000000000000000000409e004000032000300000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000000000000307c8000000df00000000000000000000000c01001000031002100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000000016400100758000000ff0000000000000000000000000140000007f000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000034788220000df000000000000000000c000000000000114f000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000020028000000ff0000000000000000000040005900000004b000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000000000400058000000ff0000000000000000000200041b000000049000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001500000005000000014009000058400000ff000000000000000000000008194000000cf000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000010000000000000000000000004c000000ff0000000000000000000000251e409881006000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000107e8000000ff00000000000000000080000c0e00000004b000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000000002200224748000000ff0000000000000000001000803f009000031000100000000000000005000000014000000058000000df00000000000000000000000001400000005000000014000000050000000164000127d8002000df000000000000000000a0000a1f4000000b7020100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000220788010000df0000000000000000000000409e00000104b004000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000002107b8000000ff0000000000000000000000828e020002c18400100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000000000247c8000000ff0000000000000000000000081f20002000c200100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000050000000140001026d8000000ff0000000000000000000009041f42010b01d000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000000000000030718000000df0000000000000000000020083e200800098000000000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000000090000000090798000000df00000000000000000000000404400000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000004330090020fd8000000ff00000000000000000000010893400000000000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000001400000005000112375480010cd8080000ff0000000000000000000014090d400000005000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000000e0010000788020000ff00000000000000000000004412000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000143e1400030f9a000000df0000000000000000001000051e000000000000100000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000001000f00004007d9000000df0000000000000000008001081f000000000000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000050201021740008127d8000000ff0000000000000000000010081d400000005000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000000400a0e0008000488000000ff00000000000000000000090612000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000008800883e0000000008000000ff0000000000000000000000001a000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000004194000000008000000ff00000000000000000000010c2d000000000000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000052000081f4000000058000000ff0000000000000000000001151f400000005000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000008001001e4110000008000000ff0000000000000000000000001e000000000000000000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000141e0000030f9a000000df00000000000000000000100d1e000000000000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000001010f30004007c9000000ff0000000000000000000008401f000000000000100000000000000005000000014000000058000000df00000000000000000000000001400000005000000014000000050000421740002007da000000df00000000000000000000280417400000005000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000000000a0e3000020189000000ff00000000000000000000008826000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000440a0000000008040000ff00000000000000000000000000000000000000100000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000000083f0030000008040000df00000000000000000000000000000000000000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000058800911f4000000058000000ff00000000000000000000000001400000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000004140000000008000000ff00000000000000000000000000000000000000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000024000000000008000000ff00000000000000000000008400401000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000009177000000008000000ff00000000000000000000000897404000000000100000000000000005000000014000000058000000ff000000000000000000000000014000000050000000140000000500141401c000000058000000ff00000000000000000000000c01400000005000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000001003e0000000008000000ff0000000000000000009001005e000000000000000000000000000000000000000000000000000000ff000000000000000000000000000000000000000000000000000000000c0e0000000000000000ff00000000000000000000000400400000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000012170000000000000000ff00000000000000000000004897400000000000100000000000000005000000014000000050000000ff000000000000000000000000014000000050000000140000000500010a214000000050000000ff00000000000000000050020c81400000005000100000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000c0000000000000000ff0000000000000000000020401e000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000001140e0000000000000000ff00000000000000000000000c9e000000000000100000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000009b0000000000000000ff0000000000000000000000400f000000000000100000000000000005000000014000000050000000df000000000000000000000000014000000050000000140000000500200d174000000050000000df00000000000000000000104517400000005000100000000000000000000000000000000000000000df00000000000000000000000000000000000000000000000000000003001c0000000000000000df0000000000000000000008080e00000000000000000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000001008802400001102800000000ffffffffffffffffff000000000000000000001000000003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fffb000000003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fff800003ffe00000fff800103ffe00040fffd00010fffffffffffffffffffff800103ffe00000fffb0000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000000000000000000001000002004000008800000000ffffffffffffffffff01000002000000000000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000200000800000430000040000ff00000000000000000000000000000000000000100000000000000000000000000000000000000000df000000000000000000000000000000000000000000000000000080002c130090000840040000df00000000000000000000000000000000000000100000000000000005000000014000000050000000ff000000000000000000000000014000000050000000140000000580004a374001000050000000ff00000000000000000000000001400000005000100000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000800000e0008000780000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000280030a0000030f90000000ff00000000000000000002880c1e00a000000000100000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000031081f00004007d0220000ff0000000000000000000020404f000000000000100000000000000005000000014000000050000000ff00000000000000000000000001400000005000000014000000051020083f400800a7d0000000ff00000000000000000000140517400000005000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000800214140000800480000000ff0000000000000000000000280e000000000000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000020000000010c2e0100010798000000ff0000000000000000000000541200a000000000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000008000000000000f0010220fc8000000ff00000000000000000004400101000000000000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000055001043d4000010cd8000000ff0000000000000000000002028d400000005000100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000081c0000000788000000ff0000000000000000000020001e000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000404e0000030f88000000ff00000000000000000000002400400000000000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000004400c1f00004007d8000000ff00000000000000000000000897400000000000100000000000000005000000014000000058000000df00000000000000000000000001400000005000000014000000050000001f48000007d8000000df00000000000000000000800c01400000005000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000000004d1e2000010c98000000ff0000000000000000000101003e000000000000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000080008b1e0000000008080000ff00000000000000000000190400400000000000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000080000196290000008020000df00000000000000000000000897400000000000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000058000081f4000000058040000ff00000000000000000080011401400000005000100000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000004001001e0030000008040000df0000000000000000000800005e000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000042000000d0788000000ff0000000000000000000201141e000000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000000018174000000bc8000000ff0000000000000000000040004f000000000000100000000000000005000000014000000058000000ff000000000000000000000000014000000050000000158000000500001401d4001305d8040000ff00000000000000000000140517400000005500100000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000001003e0000004388040000ff0000000000000000000000880e000000000000000000000000000000000000000000000008000000ff00000000000000000000000000000000000000000000000000000000040c2400010798000000ff00000000000000000054000404400000000000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000000008a1f0000000fd8000000ff00000000000000000000410893400000000000100000000000000005000000014000000058000000df0000000000000000000000000140000000500000001400000005800002236000420758000000df0000000000000000009001110d40a000005000100000000000000000000000000000000008000000df0000000000000000000000000000000000000000000000000000080108041000018688000000df00000000000000000004400412000000000000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000000000000000000000c001400000008000000ff0000000000000000000000525a140000000000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000000000000000003100214000000008000000ff0000000000000000000000001f000000000000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000000014000000050000140fc200000058000000ff0000000000000000000000141f400000005000100000000000000000000000000000000008000000df00000000000000000000000000000000000000000000000000000001003e6000000008000000df0000000000000000000000211e300000000000000000000000000000000000000000000008000000df000000000000000000000000000000000000000200e000014978000102042000104218000000df0000000000000000000000101c020043078000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000c9b00900006c000009030400030658000000ff0000000000000000000000445f2000000fd000100000000000000005000000014000000058000000ff0000000000000000000000000140000000588000c1740004507d800010136000050378080000ff00000000000000000000148a1f40200407d014100000000000000000000000000000000008000000ff000000000000000000000000000000000000000803c0000000f81000851e0830088788020000ff0000000000000000000000011e0108c0019002200000000000000000000000000000000008000000df000000000000000000000000000000000000440101e00000202100400c22040883018c400000df0000000000000000001015001a020014818200100000000000000000000000000000000008000000df000000000000000000000000000000000000028248d40904184d0423001721100483c8000000df00000000000000000080000e1f20000011c800100000000000000005000000014000000058000000ff000000000000000000000000014000000050014001f40001486500008c1340000141d8000000ff000000000000000000100812934000408dd000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000043e0000002780000002c231c060188000000ff0000000000000000008020801e220002018880000000000000000000000000000000000008000000ff000000000000000000000000000000000000000329041100300802020019400042a388000000ff0000000000000000000000101e0000c3000004500000000000000000000000000000000008000000ff00000000000000000000000000000000000044000014000100dc0060000740088004c8018000ff0000000000000000000022445d000800084022100000000000000005000000014000000058000000ff0000000000000000000000000140000000500010881e2000104d100208194000020358000000ff00000000000000000000008a1f690000005000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000400000012230802020063000050c88000000ff0000000000000000000440011e001000078000000000000000000000000000000000000008000000df000000000000000000000000000000000000002811e4002451380400041e00080b038c400000df000000000000000000040010161100008b0014100000000000000000000000000000000008000000ff0000000000000000000000000000000000000200c1f4008000040041083f00008026c8000000ff0000000000000000000040445f02100004c000100000000000000005000000014000000058000000df000000000000000000000000014000000050420001348080423d0423101940050c85da000000df00000000000000000000008a1f40010087d000100000000000000000000000000000000008000000ff000000000000000000000000000000000000042043e2000890600040001e0000001709000000ff0000000000000000000000011e000800178000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000002e000002400044002080008040b88000000ff00000000000000000000000020020003078000100000000000000000000000000000000008000000df0000000000000000000000000000000000000008c1f00004101c0000885340322106c8000000df00000000000000000090010c132008c043c000100000000000000005000000014000000058000000ff000000000000000000000000014000000050000501f40000307d0000541940004285d8014000ff00000000000000000000000a1740000307d000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000061e0000401480000021ec000000f08000000ff0000000000000000000000210e220004178000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000105e400045030000000000010050788400000ff00000000000000000000011207c00004838000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000240d40000086c00304c47004a0816cc000000ff0000000000000000009240011f0118900cc000100000000000000005000000014000000058000000ff000000000000000000000000014000000050000001f40080203500000c9d60088347d8000000ff0000000000000000000000881fc500a40b50c0100000000000000000000000000000000008000000ff000000000000000000000000000000000000240043e0000850c80000201a100004078c400000ff0000000000000000009240001e201801048804000000000000000000000000000000000000000000ff000000000000000000000000000000000000000211e220000820000083086118450780000000ff0000000000000000000020001f400020c08000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000000c1f40001227c000008134202000fd0000000ff0000000000000000000008000140900201d000100000000000000005000000014000000050000000ff00000000000000000000000001400000005000000134800450050002541964000087d0000000ff0000000000000000000002001f64010444f000500000000000000000000000000000000000000000ff000000000000000000000000000000000000000043e2110000f80020009e8000004490132000ff00000000000000000000200000400805079002000000000000000000000000000000000000000000ff000000000000000000000000000000000000000011e0000108a1002208242201001200000000ff0000000000000000000120009f000a03401000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000001c1f40000204d0000840300080b0650000000ff0000000000000000000048040140004005d000100000000000000005000000014000000050000000df000000000000000000000000014000000050000001340089486500240913400804c370000000df00000000000000000000200001400908007000100000000000000000000000000000000000000000df000000000000000000000000000000000000030043e0000002780001041e0002080790000000df0000000000000000000010001e41100347800000000000000000000000000000000000000800000000ffffffffffffffffff00000000000000000010000028000000000000000000400100a800000000ffffffffffffffffff010010024040420090001000000003ffe00000fff800003ffe00000fffd00000fffffffffffffffffffff800003ffe00000fff802403ffe00000fff800103ffe00100fffd00000fffffffffffffffffffff840113ffe00000fffb000000003ffe00000fff800003ffe00000fffd00010fffffffffffffffffffff800003ffe00000fff910103ffe00040fff800023ffe00040fffd00010fffffffffffffffffffff800023ffe00040fffb0000000000000000000000000000000000800000000ffffffffffffffffff000000000000000000100000240400000801080002004000008800000000ffffffffffffffffff01080002004000008000100000000000000000000000000000000000000000ff000000000000000000000000000000000000000411e0020140310a801504000042c380020000ff0000000000000000000000101a280024018014100000000000000000000000000000000000000000df0000000000000000000000000000000000000000c1f41000180d8001000300000001c0100000df0000000000000000000000445f00000143c000100000000000000005000000014000000050000000ff000000000000000000000000014000000050000001360802147d0280489962001109d0000000ff00000000000000000000008a1f54004489d024100000000000000000000000000000000000000000ff000000000000000000000000000000000000024043e021002019c000041e0000020180000000ff0000000000000000000000011e000000018000000000000000000000000000000000000000000000ff000000000000000000000000000000000000000011e4310030b88000340c0008008380000000ff0000000000000000000224400e0088048b0000100000000000000000000000000000000000000000ff0000000000000000000000000000000000000010c1f600a0404c1022009b00012227c0000000ff00000000000000000000400c2700120404c000100000000000000005000000014000000050000000ff00000000000000000000000001400000005000000134008c40350000088d40080007d0000000ff000000000000000000021028874000a4275000100000000000000000000000000000000000000000ff000000000000000000000000000000000000000043e000001248000014120000c34780000000ff00000000000000000000420406000801048000000000000000000000000000000000000008000000ff000000000000000000000000000000000000001011e00000002100410c061400430188000000ff00000000000000000002810c1e040001401000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000c1f00004384dc080005100000083c8120000ff0000000000000000000000011f20002205d000100000000000000005000000014000000058000000ff0000000000000000000000000140000000500000013620014c658800081f60004109d8020000ff0000000000000000000402043f401004007000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000043e400000079000024901000020188100000ff00000000000000000000600012004021478000000000000000000000000000000000000008000000ff000000000000000000000000000000000000001120e0200050180004340e0010020288020000ff0000000000000000000028111e010104078000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000011b20000824cc0200213008a110fc8100000ff0000000000000000000000840f00182143c000100000000000000005000000014000000058000000df000000000000000000000000014000000050000401740000007d2280080d40000297d8000000df00000000000000000004a0029742002045d000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000c9c000007080802815120000200508000000ff0000000000000000000011080e209003038000000000000000000000000000000000000008000000ff0000000000000000000000000000000000000000c2e00004100880002c480010008818011000ff0000000000000000000022120c000000908000100000000000000000000000000000000008000000df000000000000000000000000000000000000001001b00000247c0800001900400a06d8000000df0000000000000000000000410700000a01d000100000000000000005000000014000000058000000ff00000000000000000000000001400000005000004176110450058440490b6080050778000000ff0000000000000000000000083f40000a44f040100000000000000000000000000000000008000000df000000000000000000000000000000000000001089c0200000f81000041c0810084698000000df00000000000000000000010400000001079004000000000000000000000000000000000008000000ff000000000000000000000000000000000000000011e400514030800800000000041218000000ff00000000000000000000400500000000909000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000002c1f40000180d08201d1b0000050658000000ff0000000000000000000100181740000601d000100000000000000005000000014000000058000000ff000000000000000000000000014000000050000001350080107d08200c274000050378200000ff00000000000000000000001001c0081444f000100000000000000000000000000000000008000000ff000000000000000000000000000000000009000043e0800a24198010201a0098888788020000ff0000000000000000000000861ec09101078000000000000000000000000000000000000008000000ff000000000000000000000000000000000000000000040000002080810a1e100000a008000000ff0000000000000000000402104e000810068000100000000000000000000000000000000008000000ff000000000000000000000000000000000000000000140000b84d4100003f02000a06d8000000ff0000000000000000000060441f00008347c000100000000000000005000000014000000058000000df0000000000000000000000000140000000580020001e200150658802001f6000044778002000df00000000000000000004008a1f40000844d020100000000000000000000000000000000008000000df0000000000000000000000000000000000008200000000000879046000000400090698010000df0000000000000000000040011e011003078004000000000000000000000000000000000008000000ff000000000000000000000000000000000000001011e000044c30002200180010100388000000ff00000000000000000000408500400000038000100000000000000000000000000000000008000000ff0000000000000000000000000000000000000000c1f40000006c02402e1530400383c8000000ff0000000000000000000128081740002316c000100000000000000005000000014000000058000000ff000000000000000000000000014000000050020041f40000213500000a1562081427580a0000ff00000000000000000000001101c0040405d000100000000000000000000000000000000008000000df0000000000000000000000000000000000000020092000005048002440260002010708000000df0000000000000000000440841e8090c1870000000000000000000000000000000000210788000000df000000000000000000000000000000210400100025c000002900000000000000150788080000df000000000000000000800022004000000000001000000000000000000000000000000247d8000000ff0000000000000000000000000000000227c8840881f231008004000000000000000fd8020000ff00000000000000000010000857400000000000100000000000000005000000014000000078000000ff000000000000000000000000014000220852200543f6080010150000000140000017f8000000ff00000000000000000040040201400000005000100000000000000000000000000000000788000000ff000000000000000000000000000000010788040001e041012440000000000000010498000000ff0000000000000000000820291e000000000000000000000000000000000000000000010788000000df00000000000000000088080c5e0000820481000803e0000048f8080000000000150788000000df0000000000000000004020501a0000000000001000000000000000000000000000000047d8220000df000000000000000000002100130008090fc84400c1f22000405c800000000000000fc8000000df0000000000000000000810060d000000000000100000000000000005000000014000001378000000ff0000000000000000000020041f400000c7d0000009340004507d0028000140000007f8000000ff0000000000000000000020043f400000005000100000000000000000000000000000010488000000ff0000000000000000000002011e0000000790000041e240880178000000000000012498000000ff0000000000000000000004281e000000000000000000000000000000000000000000010008000000ff00000000000000000000004a820000810f90002081e000005278000000000000150788100000ff00000000000000000000010206000000000000100000000000000000000000000000001058000000ff0000000000000000000000001f00082207c0260844f00092007c000000000000000fd8020000ff0000000000000000000000083f0000000000001000000000000000050000000140000007d8000000ff0000000000000000000000940f40000503d0001123f4000000050000000140000007f8000000ff00000000000000000080200809400000005000100000000000000000000000000000000788000000ff0000000000000000000000003e2400088789000001e000000078000000000000018488000000ff00000000000000000040108610000000000000000000000000000000000000000000100788000000df000000000000000000002104002240000c80001089e800021070044000000000030019000000df00000000000000000000002a3c0000000000001000000000000000000000000000000317c8000000ff00000000000000000000020a01001a2307c8800041f22000227c00000000220020804c000000ff0000000000000000000440001f0000000000001000000000000000050000000140000003d8000000df0000000000000000000008001f42020107d0800082f40000507d802000014008000058000000df0000000000000000000020101f400000005000100000000000000000000000000000078788000000ff000000000000000000002000002008000f980250416680004178400400000004000788120000ff0000000000000000000011043e000000000000000000000000000000000000000000000808000000ff0000000000000000000000040000000207000004418000004078000000000800210b88000000ff00000000000000000000000000000000000000100000000000000000000000000000010058000000df0000000000000000000000010100001187c00000a1f4000210ec0000000020000203c8000000df000000000000000000000000000000000000001000000000000000050000000140000007d8000000ff0000000000000000000000022d4000020fd0001081f40804327d000000016800010f58080000ff00000000000000000000000001400000005000100000000000000000000000000000000788000000ff000000000000000000c00000123000090790030001e401000078000000000000220708020000ff00000000000000000000000000000000000000000000000000000000000000000000030008000000ff0000000000000000000000501a0000021790002020814000ca78000000000000230798000000ff0000000000000000000024525e000000000000100000000000000000000000000000044058000000ff0000000000000000000000049f00000506c0020284100000007c0000000000000087c8000000ff0000000000000000000000000f000000000000100000000000000005000000014000000078000000ff0000000000000000001049081f4000020fd0008083f40090107d000000014000000058200000ff00000000000000000000200437600000005000100000000000000000000000000000000788220000ff0000000000000000008220043e0090410780021041e220000430000000002400000788020000ff0000000000000000000010880e100000000000000000000000000000000000000000010780000000ff0000000000000000000000941a0000430f800010b000000200e8000000000000150780020000ff000000000000000000000000000000000000001000000000000000000000000000000047d0000000ff0000000000000000000000003f00000007c0000000100000307c000000000000000fd0040000ff00000000000000000000000000000000000000100000000000000005000000014000000370000000ff0000000000000000002000041f40804497d02020c2160000d07d0022000140000007f0000000ff00000000000000000080000001400800005000100000000000000000000000000000014480000000ff0000000000000000008000883e241880038c0608004040880478000000000000011490000000ff00000000000000000040000000000100000000000000000000000000000000000000402380000000ff000000000000000000000000000000101410000201e010103079000000000000420380000000ff000000000000000000000031002000000000001000000000000000000000000000000307c0000000ff0000000000000000000000000000000307c00000e1f22184047d0000000000000113c0000000ff000000000000000000044004131000000000001000000000000000050000000140000007d0000000df0000000000000000000000000140020a87d0004309f40008c17d002800014000024750000000df00000000000000000000000017400000005000100000000000000000000000000000430f80000000df000000000000000000000000002208004788820041a000801058000000000000050700000000df00000000000000000000008c2e00000000000000000000000000000000000000004000009800000000ffffffffffffffffff000000000000000000000000000000000001004002404020009800000000ffffffffffffffffff000800000000000000001000000003ffe00000fff800003ffe44004fffd00000fffffffffffffffffffff800003ffe00000fff800013ffe00000fff808013ffe02000fffd00000fffffffffffffffffffff800023ffe00000fffb000000003ffe00000fff800003ffe00040fffd00010fffffffffffffffffffff800103ffe00040fff800103ffe00040fff800103ffe00040fffd00010fffffffffffffffffffff800103ffe00000fffb0000000000000000000000000004022009800000000ffffffffffffffffff01000002004000008010000020040000080100000200400110a800000000ffffffffffffffffff01000002000000000000100000000000000000000000000000000000000000ff0000000000000000000000240c0000020700000043e000008080000000000000150780020000ff00000000000000000080000000000000000000100000000000000000000000000000014050000000df0000000000000000000000083b00302187c0000881f00000307c000000000000000fd0040000df000000000000000000400000000000000000001000000000000000050000000140000007d0000000ff0000000000000000000000900148004347d0000831f40000007d0000000140000017f0000000ff00000000000000000000000001400000005000100000000000000000000000003000000780011000ff000000000000000000000004402000000780000081c005000078000000003000010490000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff000000000000000000000000000008930780c000500000003078000000000010150780000000ff00000000000000000000000c4e001000000000100000000000000000000000000000012050000000ff000000000000000000000000000000001548062281f40001087c000000000080000fd0000000ff0000000000000000000241001b0020000000001000000000000000050000000140088007d0000000ff0000000000000000000000000140004007d0000001f41100007d0000000140000007f0000000ff00000000000000000000088c17400000005000100000000000000000000000000000000780000000ff000000000000000000003000000000031000000001e40088000000000000000c220180000000ff0000000000000000000020011c000000000000000000000000000000000000000000010788000000ff0000000000000000000020103c000000c180000131e0100080d8040004004010150788002000ff00000000000000000080000c0e0000000000001000000000000000000000000000002247d8000000ff000000000000000000000424090000420050000101f00190307c004000414080000fd8010000ff0000000000000000004440205b000000000000100000000000000005000000014000000078000000ff000000000000000000800094014400030bd1000043f60000d07d0000001f60000047f8000000ff00000000000000000000001297400000005000100000000000000000000000000000000788000000ff000000000000000000080000202000080018000881a0510004780000001e0800010488000000ff0000000000000000000000101c000000000000000000000000000000000000000000000028000000ff000000000000000000000004000000140780000090000010205800000800c02015078c000000ff00000000000000000000200200400000000000100000000000000000000000000000120058000000ff0000000000000000000000283f703a0183c0001041f40084127c000040010080000fda000000ff00000000000000000000102857400000000000100000000000000005000000014000000058000000df0000000000000000000000001f40088347d0000001f40080d07d000000014010000ff8000000df00000000000000000004105241400000005000100000000000000000000000000000000058000000ff0000000000000000000000001e000020078c000001e409100478044000010080010488000000ff0000000000000000000042001e000000000000000000000000000000000000000000004008000000ff0000000000000000001000823e01102497800040892a00003178200000400000150788020000ff0000000000000000000001031a000080000000100000000000000000000000000000010058000000df0000000000000000008000081f22000007c0261040d48088807c800004014000000fd8040000df0000000000000000000024081f0008000000001000000000000000050000000140000007d8220000ff0000000000000000000001081f4000030750000001f64001097d8280001f4000800ff8000000ff00000000000000000020000a19409000005000100000000000000000000000003000000788000000df0000000000000000000000043c3090408480000061e4030020701000001e4008010498000000df0000000000000000008000411e000000000000000000000000000000000000000000010788000000ff0000000000000000000020801e00000001900000844000900038000000008000150798000000ff000000000000000000002002004200000000001000000000000000000000000000000047d8000000ff00000000000000000000020c3f00002327d0000841100000b17c000088012400000fd8000000ff00000000000000000000048857600000000000100000000000000005000000014000010378000000ff00000000000000000014410a1b40004407d0001142154009307d0028000140000007f8000000ff0000000000000000000008530140100000500010000000000000000000000000000c001488000000ff0000000000000000008000011e240c0007802400000009800178044000014000010c88220000ff0000000000000000000020001e002000000000000000000000000000000000000000010788000000ff000000000000000000000002520000010780022001e04000b0380001128e0000950798100000ff0000000000000000000002001f4000000000001000000000000000000000000000000047d8000000ff0000000000000000000000000d40001225c00004c5f20000027c0000001f0008000fd8020000ff00000000000000000000200001400000000000100000000000000005000000014000004378000000df0000000000000000000020043f41002207d0400001f61000007d02004c3fd2080107f8080000df0000000000000000000014001f400000005000100000000000000000000000000000010488000000df0000000000000000000004001e3019011780040050c0810131780040001e4004000c88020000df00000000000000000000000000c00000000000000000000000000000000000000000010788000000ff0000000000000000000000509e0002010400000085a000040178028000000000110388000000ff000000000000000000004000000000000000001000000000000000000000000000000047d8000000ff0000000000000000000000040b0008120848800841f00000307c0000000000090247c8000000ff00000000000000000000a80000000000000000100000000000000005000000014000000378000000ff0000000000000000000001023f4008420050021143f42000520d0000000140010407d8000000ff00000000000000000000020001400000005000100000000000000000000000000000011488000000df0000000000000000000000081e0000811008804001e200020000000000000008114788000000df000000000000000000002000000000000000000000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff000000000003c0c3d000f030f4003c0c3dfffffffffffffffffffffffffff000f030f4003c0c3d000f030f4003c0c3d000f030f4003c0c3dfffffffffffffffffffffffffff000f030f4003c0c3dffff000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0419000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19ffff000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19ffff000000000003c0c1e000f03078003c0c1efffffffffffffffffffffffffff000f03060003c0c18000f03060003c0418000f03078003c0c1efffffffffffffffffffffffffff000f03078003c0c1effff000000000003c0c1f000f0307c003c0c1ffffffffffffffffffffffffffff000f0307c003c0c1f000f0307c003c0c1f000f0307c003c0c1ffffffffffffffffffffffffffff000f0307c003c0c1fffff00000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010000e0004000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010ffff00000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010000e0004000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010ffff00000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010800e0004000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010ffff00000000000380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010200e0004300380010000e0004000380010fffffffffffffffffffffffffff000e0004000380010ffff000000000003c0c1f000f0307c003c0c1ffffffffffffffffffffffffffff000f0307c003c0c1f018f0307c003c0c1f000f0307c0038041ffffffffffffffffffffffffffff000f0107c003c0c1fffff000000000003c0c1e000f03078003c0c1efffffffffffffffffffffffffff000f03060003c0c18000f03070503c0c1c000f03078003c0c1efffffffffffffffffffffffffff000f03078003c0c1effff000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0419000f01064003c0c19fffffffffffffffffffffffffff000f03064003c0c19ffff000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18000f0306000380418fffffffffffffffffffffffffff000f01060003c0c18ffff000000000003c0c19000f03064003c0c19fffffffffffffffffffffffffff000f03064003c0c19000f03064003c0c19000f03064003f0c19fffffffffffffffffffffffffff000f03064003c0c19ffff000000000003c0c3d000f030f4003c0c3dfffffffffffffffffffffffffff000f030f4003c0c3d000f030f4003c043d000f010f4603c0c3dfffffffffffffffffffffffffff000f030f4003c0c3dffff000000000003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18000f03060003c0c18000f03060003c0c18fffffffffffffffffffffffffff000f03060003c0c18ffff04ffcda0000000450000000000000000000000000000000004060000840000450000005294a5294a5294a5294a5294a5294a5210852148421085214a04e3000004000045 \
-tdo  0 \
-mask 0
sir 10 -tdi 3e5
runtest -tck 100
sir 10 -tdi 3fc
runtest -tck 100
sdr 8 -tdi 00
#
# Verify
#
sir 10 -tdi 3fa
runtest -tck 100
#
#  Array header, read group 1, chain 0, length 200, idleClk 2
#
sdr 64 \
-tdi  04e3000004000005 \
-tdo  0 \
-mask 0
sir 10 -tdi 3fd
runtest -tck 100
sdr 204 \
-tdi  0 \
-tdo  0A5294A5294A5294A5294A5294A5294A4210A429084210A4294 \
-mask 1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE
sir 10 -tdi 3fa
runtest -tck 100
#
#  Array header, read group 1, chain 1, length 97, idleClk 2
#
sdr 64 \
-tdi  0406000084000005 \
-tdo  0 \
-mask 0
sir 10 -tdi 3fd
runtest -tck 100
sdr 100 \
-tdi  0 \
-tdo  0000000000000000000000000 \
-mask 3FFFFFFFFFFFFFFFFFFFFFFFE
sir 10 -tdi 3fa
runtest -tck 100
#
#  Array header, read group 0, chain 0, length 355077, idleClk 2
#
sdr 64 \
-tdi  0420d6a000000005 \
-tdo  0 \
-mask 0
sir 10 -tdi 3fd
runtest -tck 100
sdr 355080 \
-tdi  0 \
-tdo  07FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C0017A1831FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80174087BFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8007C1833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781833FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800790831FFFFFFFFFFFFFFFFFFFFFFFFFFE001D820C000781831FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800700833FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F00078183DFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80070083FFFFFFFFFFFFFFFFFFFFFFFFFFFE001C020F80078183FFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80078183FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F80078183FFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E020F00078183DFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781833FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000700831FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E020C800781833FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE003E061E8207C187BFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF900781831FFFFFFFFFFFFFFFFFFFFFFFFFFE009E060C080720831FFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001BE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001BE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001BE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001BE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001BE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001BE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000A0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000A0000001BE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001BE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000001000000001FFFFFFFFFFFFFFFFFE0000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF67FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF67FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000001000000001FFFFFFFFFFFFFFFFFE0000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001BE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000A0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000A0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000000000001FE0000000000000000000000000000000000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE0000000000000000000000000000000000000027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A00027FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000000010000001FE000000000000000000000000000000000000000000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFEC2C38000000010000001FE00000000000000000000000000000000000000200078187A001E061E80078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80078187A001E061E80078187BFFFFC3C38000000010000001FE000000000000000000000000000000000000002000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800781833FFFEC2C380000000B0000001BE0000000000000000000000000280000000A0002000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFFC3C38000000010000001FE000000000000000000000000000000000000000000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFEC2C38000000010000001FE000000000000000000000000000000000000002000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800781833FFFFC3C38000000010000001BE00000000000000000000000000000000000000200078183C001E060F00078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFFFFFF80000000B0000001FE0000000000000000000000000280000000A000200078183E001E060F80078183FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F80078183E001E060F80078183FFFFC00038000000010000001BE000000000000000000000000000000000000000000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020001C0008000700021FFFC00038000000010000001FE000000000000000000000000000000000000002000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020001C0008000700021FFFC00038000000010000001FE000000000000000000000000000000000000002000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020001C0008000700021FFFC000380000000B0000001FE0000000000000000000000000280000000A0002000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020001C0008000700021FFFC00038000000010000001FE00000000000000000000000000000000000000000078183E001E060F80078183FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F80078183E001E060F80078183FFFFFFF038000000010000001FE00000000000000000000000000000000000000200078183C001E060F00078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFFFF038000000010000001FE000000000000000000000000000000000000002000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800781833FFFEC2C380000000B0000001BE0000000000000000000000000280000000A0002000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFFC3C38000000010000001BE000000000000000000000000000000000000000000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFEC2C38000000010000001FE000000000000000000000000000000000000002000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800781833FFFFC3C38000000010000001FE00000000000000000000000000000000000000200078187A001E061E80078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80078187A001E061E80078187BFFFFFFFF80000000B0000001FE0000000000000000000000000280000000A0002000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781831FFFFFFFF8000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001BE0000000000000000000000000280000000A0002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000000000000000001BE00000000000000000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE0000000000000000000027FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF67FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF600000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000008000000002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000000000000000001BE00000000000000000000000000000800000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001BE0000000000000000000000000280000000A0002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000000000000000001BE00000000000000000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE0000000000000000000027FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF67FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF600000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000000000000000001BE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000120000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010014001FE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000010000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000004000000000000000000200000000A0000000280000000A0000001BE0000000000000000000000000280000000A0000000280000000A0000000280400000A0000001BE0000000000000000000000000280000000A0002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000040000000000001BE00000000000000000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE0000000000000000000027FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF67FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF600000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000002800000000000000002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000000000000000001BE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000050000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000060000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001BE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE000000000000000000000000000000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000021210000001BE0000000000000000000000161C0082020FA0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000840090440001FE0000000000000000000001003E0030001F8000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280002040B0000001FE000000000000000000400064BE80004A0CA0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000060010000001FE0000000000000000010000003C0011002D40000000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000000000000000008A0F10000001BE000000000000000000004000000000004F00002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000002690000001BE000000000000000000000800004400160F8000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A000000028000021FB0000001FE000000000000000000001000028008200FA0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000F10000001FE000000000000000000004000000224062E00000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000400030200001FE000000000000000001000100330001058700002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000040FB0040001FE0000000000000000002000103E0010100F8000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000000B0000001FE00000000000000000000010032A000014FA0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000004400000F10024001FE0000000000000000018000103C10000C0F00000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000001000030000001BE000000000000000000080104080400000F40002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000010028FB0000001FE0000000000000000000080140640000280A000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A000000028000000FF0200001BE0000000000000000000002180280000000E0002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000000000000000B0040001FE000000000000000000000002040000000FC0000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000910000001FE0000000000000000000000187C0000000640002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000000930000001BE0000000000000000000001003E000000062000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000006F0000001FE0000000000000000000000003EA000000FE0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000028090000001FE0000000000000000018001192C10000289C0000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000610000001FE0000000000000000000001083F0000000940002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000630000001FE00000000000000000004801132000000092000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280400000A000000028000004FF0000001FE0000000000000000000002103F80000049E0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000004000000000000000000020690000001FE0000000000000000000000003C80000200D1000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000900000001FE000000000000000000000004020000000660002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000920000001FE0000000000000000018000022E800000062000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000046E0000001FE000000000000000001100229028200004FE0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000020080000001FE0000000000000000000000003D00320209C0000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000088000000000000604000001FE000000000000000000000001020400000940002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000000622000001FE0000000000000000000000081AC00000092000200000000A0000000280000000A0000001BE0000000000000000000000000280000000A0000000280000000A000000028010000FE0000001BE00000000000000000000400402A0000009E0002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000001024680000001BE0000000000000000000008043D10000240E000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000008001215000000001FFFFFFFFFFFFFFFFFE0210002400800001000027FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00009FFFA00001FFFFFFFFFFFFFFFFFFFFF000067FFC01285FFF67FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00811FFFA00021FFFFFFFFFFFFFFFFFFFFF000207FFC00009FFF600000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000008401015000000001FFFFFFFFFFFFFFFFFE020000040080880120002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000040F40000001FE0000000000000000000000043E8100000660102000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000000000000200F20000001BE00000000000000000000000402002000062020200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0000000280000206A0000001FE0000000000000000000000003E8000000FE0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000008900000001FE0000000000000000000000003D00000249C0000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000000020B40000001FE000000000000000000040000220040000940102000000000000000000000000000000001FE00000000000000000000000000000000000000000000000000000000000000002507A0000001FE000000000000000000008008B6808000092020200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000B10000002C000020FA0000001FE0000000000000000000000100280000029E0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000000418144F00000001FE00000000000000000000620C3C00000200E0000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000000E10000001FE0000000000000000000001283C0000000640002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000168F90024001FE0000000000000000000000007E022000062048200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A000000028000018FB0000001FE0000000000000000000000187E8000002FE0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000004400840710000001FE0000000000000000000000803400000209C0000000000000000000000000000010000001FE0000000000000000000000000000000000000000000008000000000000000000088FD0000001FE0000000000000000000000683C0004000960002000000000000000000000000010000001FE0000000000000000000000000000000000000000000002000000000000000000120FB0000001FE0000000000000000000000007E001000092000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A000000028000000FB0000001BE0000000000000000000010087E80080009E0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000264D10000001FE0000000000000000000040001800040220C0480000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000104F10000001FE0000000000000000000000813C0080000640006000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000060F90000001BE00000000000000000000001802002000062004200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A00000002C800200EB0000001FE000000000000000000000000028000000FE0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000068F10440001BE0000000000000000018000000000000229E0000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000040050000001FE000000000000000000008000B20000000960002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000000000008000B0000001FE00000000000000000004000836000000092000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A00000002A0000000A0000000280120000B0800001FE0000000000000000000000103280000019E0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000200000000000000000000000098000001FE00000000000000000000004A3C81310200C0000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000020FD0000001FE0000000000000000010000181C0000000960002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000004400448E90000001FE0000000000000000002001007E012000062000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A00000002C800024FB0004001BE0000000000000000014000143E80000016E0402000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000440F10020001BE0000000000000000000000813C0000020960080000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000420F70000001FE0000000000000000000001051C0400058308002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000000000000048F90000001FE0000000000000000000000103E400040018400200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A000000028000204DB0000001FE0000000000000000000012083E84021603A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000000000000060E30000001BE0000000000000000000040107C4010001300000000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000000120000000120F30000001BE000000000000000000000008088000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000008660120041FB0000001FE00000000000000000000021126800000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0002246EA9000219B0100001FE0000000000000000000028121A80000000A0002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000001C0020000F10040001FE000000000000000000000088240000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000000000287C2800061F34000001BE00000000000000000020000A3C0000000000002000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000000002001E0000800FB2000001BE0000000000000000010002103E000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0402042E8001024FB0000001FE0000000000000000000020103A80000000A0002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000080141C0010000910000001FE00000000000000000000120C240000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000011001107C0000000010000001FE000000000000000000000000340000000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000008328000000010000001FE0000000000000000000002185A000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A4000103E80000000B0000001FE00000000000000000000022A3E80000000A0002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000010002003C8220000010000001FE0000000000000000000000003C0000000000000000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000000000283C0000061F34000001BE00000000000000000000201A3C0000000000002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000002021E6000800F92000001FE0000000000000000000010803E000000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000842E8000400FB4000001BE0000000000000000000050082E80000000A0002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000141C6000040312000001FE0000000000000000000001104C0000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000088140000000010080001FE000000000000000000000000000000000000002000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000000000107E0060000010080001BE00000000000000000000000000000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000B1001223E80000000B0000001FE0000000000000000000000000280000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000008280000000010000001FE000000000000000000000000000000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000048000000000010000001FE000000000000000000000108008020000000002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000122EE000000010000001FE0000000000000000000000112E808000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0028280380000000B0000001FE0000000000000000000000180280000000A0002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000002007C0000000010000001FE000000000000000001200200BC0000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000000000000000000000181C0000000000000001FE000000000000000000000008008000000000002000000000000000000000000000000001FE00000000000000000000000000000000000000000000000000000000242E0000000000000001FE0000000000000000000000912E800000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A0002144280000000A0000001FE000000000000000000A004190280000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000000180000000000000001FE0000000000000000000040803C0000000000000000000000000000000000000000000001FE00000000000000000000000000000000000000000000000000000002281C0000000000000001FE0000000000000000000000193C0000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000000001360000000000000001FE0000000000000000000000801E000000000000200000000A0000000280000000A0000001BE0000000000000000000000000280000000A0000000280000000A00401A2E80000000A0000001BE00000000000000000000208A2E80000000A0002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000000000600380000000000000001BE0000000000000000000010101C000000000000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000002011004800002205000000001FFFFFFFFFFFFFFFFFE0000000000000000000027FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF67FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000007FFC00001FFF000207FFC00081FFFA00021FFFFFFFFFFFFFFFFFFFFF000207FFC00001FFF600000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000002000004008000011000000001FFFFFFFFFFFFFFFFFE020000040000000000002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000400001000000860000080001FE000000000000000000000000000000000000002000000000000000000000000000000001BE0000000000000000000000000000000000000000000000000001000058260120001080080001BE00000000000000000000000000000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000B0000946E80020000A0000001FE0000000000000000000000000280000000A0002000000000000000000000000000000001FE00000000000000000000000000000000000000000000000000001000001C0010000F00000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000000050006140000061F20000001FE0000000000000000000510183C0140000000002000000000000000000000000000000001FE00000000000000000000000000000000000000000000000000000062103E0000800FA0440001FE0000000000000000000040809E000000000000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000000280000000A2040107E8010014FA0000001FE00000000000000000000280A2E80000000A0002000000000000000000000000000000001FE0000000000000000000000000000000000000000000000000001000428280001000900000001FE0000000000000000000000501C0000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000000000004000000002185C0200020F30000001FE0000000000000000000000A8240140000000002000000000000000000000000010000001FE00000000000000000000000000000000000000000000010000000000001E0020441F90000001FE00000000000000000008800202000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000AA002087A80000219B0000001FE0000000000000000000004051A80000000A0002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000010380000000F10000001FE0000000000000000000040003C0000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000809C0000061F10000001FE000000000000000000000048008000000000002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000880183E0000800FB0000001FE0000000000000000000000112E800000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000A0000003E9000000FB0000001BE0000000000000000000100180280000000A0002000000000000000000000000010000001FE000000000000000000000000000000000000000000000000000000009A3C4000021930000001FE0000000000000000000202007C0000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000010001163C0000000010100001FE000000000000000000003208008000000000002000000000000000000000000010000001BE000000000000000000000000000000000000000000000000000010000032C520000010040001BE0000000000000000000000112E800000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000B0000103E80000000B0080001FE0000000000000000010002280280000000A0002000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000008002003C0060000010080001BE000000000000000000100000BC0000000000000000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000084000001A0F10000001FE0000000000000000000402283C0000000000002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000000302E8000001790000001FE0000000000000000000080009E000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A00000002B0000000A00002803A800260BB0080001FE00000000000000000000280A2E80000000AA002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000002007C0000008710080001FE0000000000000000000001101C0000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000008184800020F30000001FE000000000000000000A80008088000000000002000000000000000000000000010000001FE00000000000000000000000000000000000000000000000000000001143E0000001FB0000001FE00000000000000000000821126800000000000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000000280000000B00000446C000840EB0000001BE0000000000000000012002221A81400000A0002000000000000000000000000010000001BE0000000000000000000000000000000000000000000000000000100210082000030D10000001BE000000000000000000088008240000000000000000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000000018002800000010000001FE0000000000000000000000A4B42800000000002000000000000000000000000010000001FE0000000000000000000000000000000000000000000000000000006200428000000010000001FE0000000000000000000000003E000000000000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000000280000000A0000281F84000000B0000001FE0000000000000000000000283E80000000A0002000000000000000000000000010000001BE00000000000000000000000000000000000000000000000000000002007CC000000010000001BE0000000000000000000000423C6000000000000000000000000000000000000010000001BE000000000000000000000000000000000000000401C0000292F0000204084000208430000001BE000000000000000000000020380400860F00002000000000000000000000000010000001FE00000000000000000000000000000000000000019360120000D8000012060800060CB0000001FE000000000000000000000088BE4000001FA000200000000A0000000280000000B0000001FE0000000000000000000000000280000000B1000182E80008A0FB00002026C0000A06F0100001FE0000000000000000000029143E8040080FA0282000000000000000000000000010000001FE00000000000000000000000000000000000000100780000001F020010A3C1060110F10040001FE0000000000000000000000023C0211800320044000000000000000000000000010000001BE000000000000000000000000000000000000880203C000004042008018440811060318800001BE000000000000000000202A00340400290304002000000000000000000000000010000001BE000000000000000000000000000000000000050491A81208309A0846002E4220090790000001BE00000000000000000100001C3E400000239000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0028003E8000290CA0001182680000283B0000001FE000000000000000000201025268000811BA0002000000000000000000000000010000001FE000000000000000000000000000000000000000087C0000004F00000005846380C0310000001FE0000000000000000010041003C4400040311000000000000000000000000000010000001FE0000000000000000000000000000000000000006520822006010040400328000854710000001FE0000000000000000000000203C000186000008A000000000000000000000000010000001FE00000000000000000000000000000000000088000028000201B800C0000E8011000990030001FE000000000000000000004488BA001000108044200000000A0000000280000000B0000001FE0000000000000000000000000280000000A00021103C4000209A2004103280000406B0000001FE0000000000000000000001143ED2000000A0002000000000000000000000000010000001FE00000000000000000000000000000000000000008000000244610040400C60000A1910000001FE0000000000000000000880023C0020000F00000000000000000000000000000010000001BE000000000000000000000000000000000000005023C80048A2700800083C0010160718800001BE0000000000000000000800202C2200011600282000000000000000000000000010000001FE000000000000000000000000000000000000040183E8010000080082107E0001004D90000001FE000000000000000000008088BE042000098000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0840002690100847A08462032800A190BB4000001BE0000000000000000000001143E8002010FA0002000000000000000000000000010000001FE000000000000000000000000000000000000084087C4001120C00080003C0000002E12000001FE0000000000000000000000023C0010002F00000000000000000000000000000010000001FE000000000000000000000000000000000000000005C000004800088004100010081710000001FE000000000000000000000000400400060F00002000000000000000000000000010000001BE000000000000000000000000000000000000001183E000082038000110A68064420D90000001BE00000000000000000120021826401180878000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000A03E8000060FA0000A8328000850BB0028001FE0000000000000000000000142E8000060FA0002000000000000000000000000010000001FE0000000000000000000000000000000000000000C3C0000802900000043D8000001E10000001FE0000000000000000000000421C4400082F00000000000000000000000000000010000001FE00000000000000000000000000000000000000020BC80008A0600000000000200A0F10800001FE0000000000000000000002240F8000090700002000000000000000000000000010000001FE000000000000000000000000000000000000000481A8000010D80060988E0094102D98000001FE0000000000000000012480023E023120198000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000003E80100406A0000193AC011068FB0000001FE0000000000000000000001103F8A014816A1802000000000000000000000000010000001FE000000000000000000000000000000000000480087C00010A190000040342000080F18800001FE0000000000000000012480003C4030020910080000000000000000000000000000000001FE000000000000000000000000000000000000000423C44000104000010610C2308A0F00000001FE0000000000000000000040003E8000418100002000000000000000000000000000000001FE000000000000000000000000000000000000000183E8000244F8000010268404001FA0000001FE0000000000000000000010000281200403A000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000002690008A00A0004A832C800010FA0000001FE0000000000000000000004003EC8020889E000A000000000000000000000000000000001FE000000000000000000000000000000000000000087C4220001F00040013D0000008920264001FE0000000000000000000040000080100A0F20040000000000000000000000000000000001FE000000000000000000000000000000000000000023C000021142004410484402002400000001FE0000000000000000000240013E0014068020002000000000000000000000000000000001FE000000000000000000000000000000000000000383E80000409A000108060010160CA0000001FE000000000000000000009008028000800BA000200000000A0000000280000000A0000001BE0000000000000000000000000280000000A000000268011290CA0048122680100986E0000001BE0000000000000000000040000280121000E0002000000000000000000000000000000001BE000000000000000000000000000000000000060087C0000004F00002083C0004100F20000001BE0000000000000000000020003C8220068F0000000000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000200000500000000000000000008002015000000001FFFFFFFFFFFFFFFFFE0200200480808401200027FFC00001FFF000007FFC00001FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF004807FFC00001FFF000207FFC00201FFFA00001FFFFFFFFFFFFFFFFFFFFF080227FFC00001FFF67FFC00001FFF000007FFC00001FFFA00021FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF220207FFC00081FFF000047FFC00081FFFA00021FFFFFFFFFFFFFFFFFFFFF000047FFC00081FFF600000000000000000000000001000000001FFFFFFFFFFFFFFFFFE000000000000000000200000480800001002100004008000011000000001FFFFFFFFFFFFFFFFFE021000040080000100002000000000000000000000000000000001FE000000000000000000000000000000000000000823C00402806215002A080000858700040001FE000000000000000000000020345000480300282000000000000000000000000000000001BE000000000000000000000000000000000000000183E82000301B000200060000000380200001BE000000000000000000000088BE000002878000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A00000026C100428FA05009132C4002213A0000001FE0000000000000000000001143EA8008913A0482000000000000000000000000000000001FE000000000000000000000000000000000000048087C0420040338000083C0000040300000001FE0000000000000000000000023C0000000300000000000000000000000000000000000001FE000000000000000000000000000000000000000023C862006171000068180010010700000001FE0000000000000000000448801C0110091600002000000000000000000000000000000001FE000000000000000000000000000000000000002183EC01408098204401360002444F80000001FE0000000000000000000080184E002408098000200000000A0000000280000000A0000001FE0000000000000000000000000280000000A0000002680118806A0000111A8010000FA0000001FE0000000000000000000420510E8001484EA0002000000000000000000000000000000001FE000000000000000000000000000000000000000087C000002490000028240001868F00000001FE0000000000000000000084080C0010020900000000000000000000000000000010000001FE000000000000000000000000000000000000002023C0000000420082180C2800860310000001FE0000000000000000000502183C0800028020002000000000000000000000000010000001FE000000000000000000000000000000000000000183E00008709B810000A20000010790240001FE0000000000000000000000023E4000440BA000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A00000026C400298CB1000103EC0008213B0040001FE0000000000000000000804087E80200800E0002000000000000000000000000010000001FE000000000000000000000000000000000000000087C8000000F2000049202000040310200001FE00000000000000000000C000240080428F00000000000000000000000000000010000001FE000000000000000000000000000000000000002241C04000A0300008681C0020040510040001FE0000000000000000000050223C0202080F00002000000000000000000000000010000001FE0000000000000000000000000000000000000000236400010499804004260114221F90200001FE0000000000000000000001081E003042878000200000000A0000000280000000B0000001BE0000000000000000000000000280000000A0000802E8000000FA4500101A8000052FB0000001BE0000000000000000000940052E8400408BA0002000000000000000000000000010000001FE000000000000000000000000000000000000000193800000E10100502A240000400A10000001FE0000000000000000000022101C4120060700000000000000000000000000000010000001FE000000000000000000000000000000000000000185C000082011000058900020011030022001FE000000000000000000004424180000012100002000000000000000000000000010000001BE00000000000000000000000000000000000000200360000048F8100000320080140DB0000001BE0000000000000000000000820E00001403A000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0000082EC2208A00B08809216C1000A0EF0000001FE0000000000000000000000107E80001489E0802000000000000000000000000010000001BE00000000000000000000000000000000000000211380400001F0200008381020108D30000001BE000000000000000000000208000000020F20080000000000000000000000000010000001FE000000000000000000000000000000000000000023C800A28061001000000000082430000001FE00000000000000000000800A000000012120002000000000000000000000000010000001FE000000000000000000000000000000000000000583E80000301A10403A3600000A0CB0000001FE0000000000000000000200302E80000C03A000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A00000026A010020FA1040184E80000A06F0400001FE0000000000000000000000200380102889E0002000000000000000000000000010000001FE000000000000000000000000000000000012000087C100144833002040340131110F10040001FE00000000000000000000010C3D8122020F00000000000000000000000000000010000001FE00000000000000000000000000000000000000000008000000410102143C2000014010000001FE0000000000000000000804209C0010200D00002000000000000000000000000010000001FE000000000000000000000000000000000000000000280001709A8200007E0400140DB0000001FE00000000000000000000C0883E0001068F8000200000000A0000000280000000B0000001BE0000000000000000000000000280000000B00040003C4002A0CB1004003EC000088EF0004001BE0000000000000000000801143E80001089A0402000000000000000000000000010000001BE00000000000000000000000000000000000104000000000010F208C000000800120D30020001BE0000000000000000000080023C0220060F00080000000000000000000000000010000001FE000000000000000000000000000000000000002023C000089860004400300020200710000001FE00000000000000000000810A008000000700002000000000000000000000000010000001FE000000000000000000000000000000000000000183E8000000D804805C2A6080070790000001FE0000000000000000000250102E8000462D8000200000000A0000000280000000B0000001FE0000000000000000000000000280000000A0040083E80000426A0000142AC410284EB0140001FE000000000000000000000022038008080BA0002000000000000000000000000010000001BE000000000000000000000000000000000000004012400000A0900048804C0004020E10000001BE0000000000000000000881083D0121830E00000000000000000000000000420F10000001BE00000000000000000000000000000042080020004B80000052000000000000002A0F10100001BE000000000000000001000044008000000000002000000000000000000000048FB0000001FE000000000000000000000000000000044F91081103E462010008000000000000001FB0040001FE000000000000000000200010AE800000000000200000000A0000000280000000F0000001FE0000000000000000000000000280004410A4400A87EC1000202A000000028000002FF0000001FE0000000000000000008008040280000000A0002000000000000000000000000F10000001FE000000000000000000000000000000020F10080003C082024880000000000000020930000001FE0000000000000000001040523C0000000000000000000000000000000000020F10000001BE000000000000000001101018BC0001040902001007C0000091F01000000000002A0F10000001BE0000000000000000008040A0340000000000002000000000000000000000008FB0440001BE000000000000000000004200260010121F90880183E4400080B9000000000000001F90000001BE00000000000000000010200C1A000000000000200000000A0000000280000026F0000001FE0000000000000000000040083E8000018FA0000012680008A0FA005000028000000FF0000001FE0000000000000000000040087E80000000A0002000000000000000000000020910000001FE0000000000000000000004023C0000000F20000083C4811002F0000000000000024930000001FE0000000000000000000008503C0000000000000000000000000000000000020010000001FE000000000000000000000095040001021F20004103C00000A4F00000000000002A0F10200001FE0000000000000000000002040C00000000000020000000000000000000000020B0000001FE0000000000000000000000003E0010440F804C1089E0012400F8000000000000001FB0040001FE0000000000000000000000107E000000000000200000000A000000028000000FB0000001FE0000000000000000000001281E80000A07A0002247E80000000A000000028000000FF0000001FE0000000000000000010040101280000000A0002000000000000000000000000F10000001FE0000000000000000000000007C4800110F12000003C0000000F0000000000000030910000001FE00000000000000000080210C200000000000000000000000000000000000200F10000001BE000000000000000000004208004480001900002113D0000420E0088000000000060032000001BE000000000000000000000054780000000000002000000000000000000000062F90000001FE000000000000000000000414020034460F91000083E4400044F8000000004400410098000001FE0000000000000000000880003E000000000000200000000A0000000280000007B0000001BE0000000000000000000010003E8404020FA1000105E80000A0FB0040000280100000B0000001BE0000000000000000000040203E80000000A00020000000000000000000000F0F10000001FE000000000000000000004000004010001F3004A082CD000082F0800800000008000F10240001FE0000000000000000000022087C0000000000000000000000000000000000001010000001FE000000000000000000000008000000040E0000088300000080F0000000001000421710000001FE0000000000000000000000000000000000000020000000000000000000000200B0000001BE000000000000000000000002020000230F80000143E8000421D8000000004000040790000001BE00000000000000000000000000000000000000200000000A000000028000000FB0000001FE0000000000000000000000045A8000041FA0002103E8100864FA00000002D000021EB0100001FE0000000000000000000000000280000000A0002000000000000000000000000F10000001FE000000000000000001800000246000120F20060003C8020000F0000000000000440E10040001FE000000000000000000000000000000000000000000000000000000000000060010000001FE0000000000000000000000A0340000042F2000404102800194F0000000000000460F30000001FE0000000000000000000048A4BC00000000000020000000000000000000000880B0000001FE0000000000000000000000093E00000A0D8004050820000000F8000000000000010F90000001FE0000000000000000000000001E000000000000200000000A0000000280000000F0000001FE0000000000000000002092103E8000041FA0010107E8012020FA0000000280000000B0400001FE0000000000000000000040086EC0000000A0002000000000000000000000000F10440001FE0000000000000000010440087C0120820F00042083C440000860000000004800000F10040001FE0000000000000000000021101C2000000000000000000000000000000000020F00000001FE000000000000000000000128340000861F0000216000000401D00000000000002A0F00040001FE000000000000000000000000000000000000002000000000000000000000008FA0000001FE0000000000000000000000007E0000000F8000000020000060F8000000000000001FA0080001FE00000000000000000000000000000000000000200000000A0000000280000006E0000001FE0000000000000000004000083E8100892FA04041842C0001A0FA004400028000000FE0000001FE0000000000000000010000000280100000A0002000000000000000000000028900000001FE0000000000000000010001107C48310007180C100080811008F0000000000000022920000001FE000000000000000000800000000002000000000000000000000000000000804700000001FE000000000000000000000000000000202820000403C0202060F2000000000000840700000001FE000000000000000000000062004000000000002000000000000000000000060F80000001FE000000000000000000000000000000060F800001C3E4430808FA000000000000022780000001FE00000000000000000008800826200000000000200000000A000000028000000FA0000001BE000000000000000000000000028004150FA0008613E8001182FA005000028000048EA0000001BE0000000000000000000000002E80000000A0002000000000000000000000861F00000001BE000000000000000000000000004410008F1104008340010020B00000000000000A0E00000001BE0000000000000000000001185C000000000000000000000000000000008000013000000001FFFFFFFFFFFFFFFFFE000000000000000000000000000000000002008004808040013000000001FFFFFFFFFFFFFFFFFE0010000000000000000027FFC00001FFF000007FFC88009FFFA00001FFFFFFFFFFFFFFFFFFFFF000007FFC00001FFF000027FFC00001FFF010027FFC04001FFFA00001FFFFFFFFFFFFFFFFFFFFF000047FFC00001FFF67FFC00001FFF000007FFC00081FFFA00021FFFFFFFFFFFFFFFFFFFFF000207FFC00081FFF000207FFC00081FFF000207FFC00081FFFA00021FFFFFFFFFFFFFFFFFFFFF000207FFC00001FFF600000000000000000008044013000000001FFFFFFFFFFFFFFFFFE020000040080000100200000400800001002000004008002215000000001FFFFFFFFFFFFFFFFFE020000040000000000002000000000000000000000000000000001FE000000000000000000000048180000040E00000087C0000101000000000000002A0F00040001FE0000000000000000010000000000000000000020000000000000000000000280A0000001BE000000000000000000000010760060430F80001103E0000060F8000000000000001FA0080001BE00000000000000000080000000000000000000200000000A000000028000000FA0000001FE000000000000000000000120029000868FA0001063E8000000FA000000028000002FE0000001FE0000000000000000000000000280000000A0002000000000000000006000000F00022001FE000000000000000000000008804000000F00000103800A0000F0000000006000020920000001FE000000000000000000000000000000000000000000000000000000000000000000000001FE000000000000000000000000000011260F018000A000000060F00000000000202A0F00000001FE0000000000000000000000189C00200000000020000000000000000000000240A0000001FE000000000000000000000000000000002A900C4503E8000210F8000000000100001FA0000001FE00000000000000000004820036004000000000200000000A000000028011000FA0000001FE000000000000000000000000028000800FA0000003E8220000FA000000028000000FE0000001FE0000000000000000000011182E80000000A0002000000000000000000000000F00000001FE000000000000000000006000000000062000000003C801100000000000000018440300000001FE000000000000000000004002380000000000000000000000000000000000020F10000001FE000000000000000000004020780000018300000263C0200101B00800080080202A0F10004001FE0000000000000000010000181C0000000000002000000000000000000000448FB0000001FE0000000000000000000008481200008400A0000203E0032060F8008000828100001FB0020001FE000000000000000000888040B6000000000000200000000A0000000280000000F0000001FE0000000000000000010001280288000617A2000087EC0001A0FA0000003EC000008FF0000001FE0000000000000000000000252E80000000A0002000000000000000000000000F10000001FE00000000000000000010000040400010003000110340A20008F00000003C1000020910000001FE000000000000000000000020380000000000000000000000000000000000000050000001FE000000000000000000000008000000280F0000012000002040B00000100180402A0F18000001FE0000000000000000000040040080000000000020000000000000000000002400B0000001FE0000000000000000000000507EE074030780002083E8010824F8000080020100001FB4000001FE000000000000000000002050AE800000000000200000000A0000000280000000B0000001BE0000000000000000000000003E8011068FA0000003E80101A0FA000000028020001FF0000001BE0000000000000000000820A48280000000A00020000000000000000000000000B0000001FE0000000000000000000000003C0000400F18000003C8122008F0088000020100020910000001FE0000000000000000000084003C0000000000000000000000000000000000008010000001FE0000000000000000002001047C0220492F0000811254000062F04000008000002A0F10040001FE0000000000000000000002063400010000000020000000000000000000000200B0000001BE0000000000000000010000103E4400000F804C2081A9011100F9000008028000001FB0080001BE0000000000000000000048103E001000000000200000000A000000028000000FB0440001FE0000000000000000000002103E8000060EA0000003EC800212FB0500003E8001001FF0000001FE0000000000000000004000143281200000A0002000000000000000006000000F10000001BE0000000000000000000000087861208109000000C3C8060040E02000003C8010020930000001BE0000000000000000010000823C0000000000000000000000000000000000020F10000001FE0000000000000000000041003C000000032000010880012000700000000100002A0F30000001FE000000000000000000004004008400000000002000000000000000000000008FB0000001FE0000000000000000000004187E0000464FA000108220000162F8000110024800001FB0000001FE000000000000000000000910AEC00000000000200000000A0000000280000206F0000001FE000000000000000000288214368000880FA00022842A801260FA005000028000000FF0000001FE0000000000000000000010A60280200000A0002000000000000000000018002910000001FE0000000000000000010000023C4818000F0048000000130002F0088000028000021910440001FE0000000000000000000040003C0040000000000000000000000000000000020F10000001FE000000000000000000000004A40000020F00044003C0800160700002251C00012A0F30200001FE0000000000000000000004003E8000000000002000000000000000000000008FB0000001FE0000000000000000000000001A8000244B8000098BE4000004F80000003E0010001FB0040001FE00000000000000000000400002800000000000200000000A0000000280000086F0000001BE0000000000000000000040087E8200440FA0800003EC200000FA0400987FA410020FF0100001BE0000000000000000000028003E80000000A0002000000000000000000000020910000001BE0000000000000000000008003C6032022F000800A181020262F00080003C8008001910040001BE000000000000000000000000018000000000000000000000000000000000020F10000001FE0000000000000000000000A13C000402080000010B40000802F0050000000000220710000001FE000000000000000000008000000000000000002000000000000000000000008FB0000001FE000000000000000000000008160010241091001083E0000060F8000000000012048F90000001FE00000000000000000001500000000000000000200000000A0000000280000006F0000001FE0000000000000000000002047E80108400A0042287E84000A41A000000028002080FB0000001FE0000000000000000000004000280000000A0002000000000000000000000022910000001BE0000000000000000000000103C0001022011008003C400040000000000000010228F10000001BE000000000000000000004000000000000000000000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE00078187A001E061E80078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80078187A001E061E80078187A001E061E80078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80078187BFFFE000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800780832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781833FFFE000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781833FFFE00078183C001E060F00078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000780830001E060F00078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F00078183DFFFE00078183E001E060F80078183FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F80078183E001E060F80078183E001E060F80078183FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F80078183FFFFE000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020001C0008000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020001C0008000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021001C0008000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE000700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700020401C0008600700020001C0008000700021FFFFFFFFFFFFFFFFFFFFFFFFFFE001C0008000700021FFFE00078183E001E060F80078183FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F80078183E031E060F80078183E001E060F80070083FFFFFFFFFFFFFFFFFFFFFFFFFFFE001E020F80078183FFFFE00078183C001E060F00078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060E0A0781838001E060F00078183DFFFFFFFFFFFFFFFFFFFFFFFFFFE001E060F00078183DFFFE000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800780832001E020C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781833FFFE000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781830001E060C000700831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E020C000781831FFFE000781832001E060C800781833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781832001E060C800781832001E060C8007E1833FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C800781833FFFE00078187A001E061E80078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80078187A001E061E80078087A001E021E8C078187BFFFFFFFFFFFFFFFFFFFFFFFFFFE001E061E80078187BFFFE000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781830001E060C000781830001E060C000781831FFFFFFFFFFFFFFFFFFFFFFFFFFE001E060C000781831FFFE0 \
-mask 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFF84000000000000000000000000001FFE3FFE17FF8FFF840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7C2000000000000000000000000001FFE1F9F0FFF87E7C20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7DE000000000000000000000000001FFE1F9F7FFF87E7DE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFC2000000000000000000000000001FFE3FFF0FFF8FFFC20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF87E784000000000000000000000000001FFE1F9E17FF87E7840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE0008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE0008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE00013D3C7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF8FFF85FFE3FFE17FF8FFF84000000000000000000000000001FFE3FFE17FF8FFF85FFE3FFE17FF8FFF8400003C3C7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF87E7CDFFE1F9F37FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CDFFE1F9F37FF87E7CC00013D3C7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE00003C3C7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE00013D3C7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF8FFFCDFFE3FFF37FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCDFFE3FFF37FF8FFFCC00003C3C7FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF87E7C3FFE1F9F0FFF87E7C2000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE0003FFFC7FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE0003FFFC7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE0003FFFC7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE0003FFFC7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE0003FFFC7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FF87E7DFFFE1F9F7FFF87E7DE000000000000000000000000001FFE1F9F7FFF87E7DFFFE1F9F7FFF87E7DE000000FC7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF8FFFC3FFE3FFF0FFF8FFFC2000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE000000FC7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF87E7CDFFE1F9F37FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CDFFE1F9F37FF87E7CC00013D3C7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE00003C3C7FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE00013D3C7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF8FFFCDFFE3FFF37FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCDFFE3FFF37FF8FFFCC00003C3C7FFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FF87E785FFE1F9E17FF87E784000000000000000000000000001FFE1F9E17FF87E785FFE1F9E17FF87E784000000007FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE000000007FFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC0003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFFE000000000000000000000FFFFF8003FFFFE00080003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE000FFFFF8003FFFFE000FFFFF8003FFFFE0005FFFDE000000000000000000000FFFFF8003FFFFE00087FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFE000000000000000001FFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF5FFFFFFFD7FFFFFFF4FFFFFFE01FFFFFFFFFFFFFFFFFFFFFFFFFD7FFFFFFF5FFFC7FFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFE41FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE7FF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCE00007FF87E785FFE1F9E17FF87E784000000000000000000000000001FFE1F9E17FF87E785FFE1F9E17FF87E785FFE1F9E17FF87E784000000000000000000000000001FFE1F9E17FF87E78400007FF8FFFCDFFE3FFF37FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCDFFE3FFF37FF8FFFCDFFE3FFF37FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCC00007FF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CE00007FF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCE00007FF87E7CDFFE1F9F37FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CDFFE1F9F37FF87E7CDFFE1F9F37FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CC00007FF8FFFC3FFE3FFF0FFF8FFFC2000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCFFFE3FFF0FFF8FFFC2000000000000000000000000001FFE3FFF0FFF8FFFC200007FF87E7DFFFE1F9F7FFF87E7DE000000000000000000000000001FFE1F9F7FFF87E7DFFFE1F9F7FFF87E7DFFFE1F9F7FFF87E7DE000000000000000000000000001FFE1F9F7FFF87E7DE00007FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE00007FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE00007FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE00007FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE00007FF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDFFFE3FFF7FFF8FFFDE000000000000000000000000001FFE3FFF7FFF8FFFDE00007FF87E7C3FFE1F9F0FFF87E7C2000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CFFFE1F9F0FFF87E7C2000000000000000000000000001FFE1F9F0FFF87E7C200007FF8FFFCDFFE3FFF37FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCDFFE3FFF37FF8FFFCDFFE3FFF37FF8FFFCC000000000000000000000000001FFE3FFF37FF8FFFCC00007FF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CE00007FF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCFFFE3FFF3FFF8FFFCE000000000000000000000000001FFE3FFF3FFF8FFFCE00007FF87E7CDFFE1F9F37FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CDFFE1F9F37FF87E7CDFFE1F9F37FF87E7CC000000000000000000000000001FFE1F9F37FF87E7CC00007FF8FFF85FFE3FFE17FF8FFF84000000000000000000000000001FFE3FFE17FF8FFF85FFE3FFE17FF8FFF85FFE3FFE17FF8FFF84000000000000000000000000001FFE3FFE17FF8FFF8400007FF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CFFFE1F9F3FFF87E7CE000000000000000000000000001FFE1F9F3FFF87E7CE00000
#
# Footer
#
sir 10 -tdi 3f9
runtest -tck 100
usb_flush

set use_block_erase false
return $use_block_erase
}

proc hybrid_prepare_AG1280Q32 {args} {
return [hybrid_prepare_AG1280Q48 $args]
}
};
namespace import alta::*
#set sh_echo_on_source true
  