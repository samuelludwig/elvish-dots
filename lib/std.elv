# misc utils

fn dotify-string {|str dotify-length|
  if (or (<= $dotify-length 0) (<= (count $str) $dotify-length)) {
    put $str
  } else {
    put $str[..$dotify-length]'…'
  }
}

use file

fn pipesplit {|l1 l2 l3|
  var pout = (file:pipe)
  var perr = (file:pipe)
  run-parallel {
    $l1 > $pout 2> $perr
    file:close $pout[w]
    file:close $perr[w]
  } {
    $l2 < $pout
    file:close $pout[r]
  } {
    $l3 < $perr
    file:close $perr[r]
  }
}

var -read-upto-eol~ = {|eol| put (head -n1) }

use builtin
if (has-key $builtin: read-upto~) {
  set -read-upto-eol~ = {|eol| read-upto $eol }
}

fn readline {|&eol="\n" &nostrip=$false &prompt=$nil|
  if $prompt {
    print $prompt > /dev/tty
  }
  var line = (if $prompt {
      -read-upto-eol $eol < /dev/tty
    } else {
      -read-upto-eol $eol
  })
  if (and (not $nostrip) (!=s $line '') (==s $line[-1..] $eol)) {
    put $line[..-1]
  } else {
    put $line
  }
}

fn y-or-n {|&style=default prompt|
  set prompt = $prompt" [y/n] "
  if (not-eq $style default) {
    set prompt = (styled $prompt $style)
  }
  print $prompt > /dev/tty
  var resp = (readline)
  eq $resp y
}

fn getfile {
  use re
  print 'Drop a file here: ' >/dev/tty
  var fname = (read-line)
  each {|p|
    set fname = (re:replace $p[0] $p[1] $fname)
  } [['\\(.)' '$1'] ['^''' ''] ['\s*$' ''] ['''$' '']]
  put $fname
}

fn max {|a @rest &with={|v|put $v}|
  var res = $a
  var val = ($with $a)
  each {|n|
    var nval = ($with $n)
    if (> $nval $val) {
      set res = $n
      set val = $nval
    }
  } $rest
  put $res
}

fn min {|a @rest &with={|v|put $v}|
  var res = $a
  var val = ($with $a)
  each {|n|
    var nval = ($with $n)
    if (< $nval $val) {
      set res = $n
      set val = $nval
    }
  } $rest
  put $res
}

fn cond {|clauses|
  range &step=2 (count $clauses) | each {|i|
    var exp = $clauses[$i]
    if (eq (kind-of $exp) fn) { set exp = ($exp) }
    if $exp {
      put $clauses[(+ $i 1)]
      return
    }
  }
}

fn optional-input {|@input|
  if (eq $input []) {
    set input = [(all)]
  } elif (== (count $input) 1) {
    set input = [ (all $input[0]) ]
  } else {
    fail "util:optional-input: want 0 or 1 arguments, got "(count $input)
  }
  put $input
}

fn select {|p @input|
  each {|i| if ($p $i) { put $i} } (optional-input $@input)
}

fn remove {|p @input|
  each {|i| if (not ($p $i)) { put $i} } (optional-input $@input)
}

fn partial {|f @p-args|
  put {|@args|
    $f $@p-args $@args
  }
}

fn path-in {|obj path &default=$nil|
  each {|k|
    try {
      set obj = $obj[$k]
    } catch {
      set obj = $default
      break
    }
  } $path
  put $obj
}

use str

fn fix-deprecated {|f|
  var deprecated = [
    &all= all
    &str:join= str:join
    &str:split= str:split
    &str:replace= str:replace
  ]
  var sed-cmd = (str:join "; " [(keys $deprecated | each {|d| put "s/"$d"/"$deprecated[$d]"/" })])
  sed -i '' -e $sed-cmd $f
}

use re
use str
use path
use file
use platform

################################################ Platform shortcuts
fn is-macos		{ eq $platform:os 'darwin' }
fn is-linux		{ eq $platform:os 'linux' }
fn is-win		{ eq $platform:os 'windows' }
fn is-arm64		{ or (eq (uname -m) 'arm64') (eq (uname -m) 'aarch64') }

################################################ IS
# inspired by https://github.com/crinklywrappr/rivendell 
fn is-empty		{|li| == (count $li) 0 }
fn not-empty	{|li| not (== (count $li) 0) }
fn is-match		{|s re| re:match $re $s }
fn not-match	{|s re| not (re:match $re $s) }
fn is-zero		{|n| == 0 $n }
fn is-one		  {|n| == 1 $n }
fn is-even		{|n| == (% $n 2) 0 }
fn is-odd		  {|n| == (% $n 2) 1 }
fn is-pos			{|n| > $n 0 }
fn is-neg			{|n| < $n 0 }
fn is-fn		  {|x| eq (kind-of $x) fn }
fn is-map		  {|x| eq (kind-of $x) map }
fn is-list		{|x| eq (kind-of $x) list }
fn is-string	{|x| eq (kind-of $x) string }
fn is-bool		{|x| eq (kind-of $x) bool }
fn is-number	{|x| eq (kind-of $x) !!float64 }
fn is-nil		  {|x| eq $x $nil }
fn is-path		{|p| path:is-dir &follow-symlink $p }
fn is-file		{|p| path:is-regular &follow-symlink $p }

################################################ filtering functions
fn filter {|func~ @in|
	each {|item| if (func $item) { put $item }} $@in
}
fn filter-out {|func~ @in|
	each {|item| if (not (func $item)) { put $item }} $@in
}
fn filter-re {|re @in|
	each {|item| if (is-match $item $re) { put $item } } $@in
}
fn filter-re-out {|re @in|
	each {|item| if (not-match $item $re) { put $item } } $@in
}
fn if- {|cond v1 v2|
	if $cond {
		put $v1
	} else {
		put $v2
	}
}

################################################ Math shortcuts
fn dec			{|n| - $n 1 }
fn inc			{|n| + $n 1 }
fn negate		{|n| * $n -1 }
fn abs		  {|n| if- (is-neg $n) (negate $n) $n }

################################################ pipeline functions
fn flatten { |@in| # flatten input recursively
	each {|in| if (eq (kind-of $in) list) { flatten $in } else { put $in } } $@in
}

fn check-pipe { |@li| # use when taking @args
	if (is-empty $li) { all } else { all $li }
}

fn listify { |@in| # test to take either stdin or pipein
	var list

	if (is-empty $in) { 
    set list = [ (all) ] 
  } else { 
    set list = $in 
  }

	while (and (is-one (count $list)) (is-list $list) (is-list $list[0])) { 
    set list = $list[0] 
  }

	put $list
}

################################################ list functions
fn prepend  { |li args| put (put $@args $@li) }
fn append   { |li args| put (put $@li $@args) }
fn concat   { |l1 l2| put (flatten $l1) (flatten $l2) }
fn pluck    { |li n| put (flatten $li[..$n]) (flatten $li[(inc $n)..]) }
fn get      { |li n| put $li[$n] } # put A B C D | cmds:get [(all)] 1
fn first    { |li| put $li[0] }
fn firstf   { |li| first [(flatten $li)] }
fn second   { |li| put $li[1] }
fn rest     { |li| put $li[1..] }
fn last     { |li| put $li[-1] }
fn but-last { |li| put $li[..(dec (count $li))] }
fn nth      { |li n &not-found=$false|
	if (and $not-found (> $n (count $li))) {
		put $not-found
	} else {
		drop $n $li | take 1
	}
}
fn take     { |li n| put $li[..$n] }
fn drop     { |li n| put $li[$n..] }

################################################ Utils
fn if-external { |prog lambda|
	if (has-external $prog) { 
    try { 
      $lambda 
    } catch e { 
      print "\n---> Could't run: "; pprint $lambda[def]; pprint $e[reason] 
    } 
  }
}

fn append-to-path { |path|
	if (is-path $path) { 
    var @p = (filter-re-out (re:quote $path) $paths); set paths = [ $@p $path ] 
  }
}

fn prepend-to-path { |path|
	if (is-path $path) { 
    var @p = (filter-re-out (re:quote $path) $paths); set paths = [ $path $@p ] 
  }
}

fn check-paths {
	each {|p| 
    if (not (is-path $p)) { 
      echo (styled "🥺—"$p" in $paths no longer exists…" bg-red) 
    } 
  } $paths
}

fn newelves { 
	var sep = "----------------------------"
	curl "https://api.github.com/repos/elves/elvish/commits?per_page=8" |
	from-json |
	all (one) |
	each {|issue| echo $sep; echo (styled $issue[sha][0..12] bold): (styled (re:replace "\n" "  " $issue[commit][message]) yellow) }
}

fn repeat-each { |n f| # takses a number and a lambda
	range $n | each {|_| $f }
}

fn hexstring { |@n|
	if (is-empty $n) {
		put (repeat-each 32 { printf '%X' (randint 0 16) })
	} else {
		put (repeat-each $@n { printf '%X' (randint 0 16) })
	}
}

fn comp {|@fns| 
  if (== 1 (count $fns)) {
    put (first $fns)
  } else {
    var this-fn~ = (first $fns)
    var rem-fns = (rest $fns)
    var next-fn~ = (first $rem-fns)
    set rem-fns[0] = {|@args| $this-fn~ ($next-fn~ $@args) }
    comp (all $rem-fns)
  }
}
