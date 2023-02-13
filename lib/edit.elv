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
