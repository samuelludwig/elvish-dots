#==================================================== - ELVISH CONFIG
# elvish shell config: https://elv.sh/learn/tour.html
# see a sample here: https://gitlab.com/zzamboni/dot-elvish/-/blob/master/rc.org
#===============================================

#==================================================== - INTERNAL MODULES
use re
use str
use path
use math
use epm
use platform

#use cmds
#use readline-binding
#if $platform:is-unix { use unix; edit:add-var unix: $unix: }
try { use doc } catch { }

#echo (styled "◖ Elvish V"$version"—"$platform:os"▷"$platform:arch" ◗" bold italic white)

#==================================================== - EXTERNAL MODULES
# epm:install &silent-if-installed ^
# 	github.com/iwoloschin/elvish-packages ^
# 	github.com/zzamboni/elvish-modules ^
# 	github.com/zzamboni/elvish-themes ^
# 	github.com/zzamboni/elvish-completions ^
# 	github.com/xiaq/edit.elv 
#
# use github.com/zzamboni/elvish-modules/proxy
# use github.com/zzamboni/elvish-modules/bang-bang
# use github.com/zzamboni/elvish-modules/spinners
# use github.com/href/elvish-gitstatus/gitstatus
# use github.com/iwoloschin/elvish-packages/python
# use github.com/zzamboni/elvish-completions/git
# use github.com/zzamboni/elvish-completions/cd
# use github.com/zzamboni/elvish-completions/ssh

#==================================================== - IMPORT UTIL NAMES
# var if-external~		= $cmds:if-external~
# var append-to-path~		= $cmds:append-to-path~
# var prepend-to-path~	= $cmds:prepend-to-path~
# var is-path~			= $cmds:is-path~
# var is-file~			= $cmds:is-file~
# var is-macos~			= $cmds:is-macos~
# var is-linux~			= $cmds:is-linux~
# var is-arm64~			= $cmds:is-arm64~
# var pya~				= $python:activate~
# var pyd~				= $python:deactivate~
# var pyl~				= $python:list-virtualenvs~
# set edit:completion:arg-completer[pya] = $edit:completion:arg-completer[python:activate]

#==================================================== - PATHS
set paths = [
  ~/.local/bin
	~/bin
	/usr/local/bin
	/usr/local/sbin
	$@paths
]
# var ppaths = [
# 	/Library/TeX/texbin
# 	/opt/local/bin
# 	/usr/local/opt/python@3.10/libexec/bin
# 	~/.rbenv/shims
# 	~/.pyenv/shims
# 	/opt/homebrew/bin
# 	/home/linuxbrew/.linuxbrew/bin
# ]
# var apaths = [
# 	/Library/Frameworks/GStreamer.framework/Commands
# ]
# each {|p| if (is-path $p) { prepend-to-path $p }} $ppaths
# each {|p| if (is-path $p) { append-to-path $p }} $apaths

# ENVIRONMENT

set-env XDG_CONFIG_HOME $E:HOME"/.config"
set-env XDG_DATA_HOME $E:HOME"/.local/share"

var nvim-loc = (search-external nvim)
set-env EDITOR $nvim-loc
set-env VISUAL $nvim-loc

# ALIASES & COMMANDS

fn n  {|@args| e:nvim -O $@args }
fn ll {|@args| e:exa -lgah --icons $@args }
fn gs {|@args| e:lazygit $@args }

if (has-external jet) {
  edit:add-var from-edn~ {|@in|
    put $@in | to-lines | e:jet -i edn -o json | from-json
  }
  edit:add-var to-edn~ {|@in|
    put $@in | to-json | e:jet -i json -o edn --keywordize
  }
  edit:add-var from-yaml~ {|@in|
    put $@in | to-lines | e:jet -i yaml -o json | from-json
  }
  edit:add-var to-yaml~ {|@in|
    put $@in | to-json | e:jet -i json -o yaml
  }
}

# COMPLETION

eval (carapace _carapace|slurp)

# PROMPT

eval (starship init elvish)

# EDIT STUFF

fn external_edit_command {
	var temp-file = (path:temp-file '*.elv')
	print $edit:current-command > $temp-file
	try {
		vim $temp-file[name] </dev/tty >/dev/tty 2>&1
		set edit:current-command = (slurp < $temp-file[name])[..-1]
	} catch {
		file:close $temp-file
		rm $temp-file[name]
	}
}

# HELP

fn helpme { 
  var notes = [
    ""
    "⌃N – 🚀navigate" 
    "⌃R – 🔍history"
    "⌃L – 🔍dirs"
    #"⌃B – edit cmd"
    "⌃U – ⌫line"
    "💡 curl cheat.sh/elvish\n"
  ]
  echo (styled (str:join "\n ░ " $notes) bold italic fg-yellow) 
}

helpme

