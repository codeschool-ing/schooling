#!/bin/bash
#
# EVERY SCREEN THE CATALOGUE SHOWS, AND THE KEYSTROKES THAT PRODUCE IT.
#
# `term-capture` is the camera; this is what was photographed. The two were
# separated and it cost exactly what you would expect: when the cursor had to be
# added to the tool, the screens already published could not simply be taken
# again, because nobody had written down what was typed at them. They were
# reconstructed from their own captions — which is lucky rather than a plan, and
# is why this file exists now.
#
# TWENTY-SEVEN OF THE CATALOGUE'S TWENTY-EIGHT CAPTURED SCREENS ARE HERE. The
# twenty-eighth is lesson 6's htop, and it is missing on purpose: it is a
# picture of a moment — those process ids, that load average — so there is no
# keystroke that brings it back. It also needs nothing from this change, because
# htop hides the cursor on the way in and never shows it again.
#
# IT RUNS AS `ana`, ON ana's MACHINE. The lessons quote the byte counts and the
# line numbers on these screens, so the files have to be the ones the lesson
# describes. `stage` puts them back before every capture; a screen taken against
# a file somebody edited in between is a figure that quietly disagrees with the
# paragraph beside it.
#
#	sudo -u ana tools/term-capture/screens.sh /tmp/screens
#
# THE CHECK IS THAT NOTHING ELSE MOVED. Re-taking a screen is only safe if it
# comes out as the one already published, so `screens-check.mjs` diffs each SVG
# against the figure in the lesson and allows exactly one kind of difference:
# the cursor. Anything else means the recipe here is not what was typed the
# first time, and the figure would change under a paragraph that describes it.
#
# `-repaint ''` ON EVERY VIM AND EMACS SCREEN, and it is not a detail. Ctrl-L
# repaints in vim — and CLEARS THE MESSAGE LINE while it is at it, which is the
# line every one of these figures is about. In emacs it recentres the view,
# which moves the thing being photographed. The programs here paint their whole
# screen at once, so nothing is lost by not asking.
set -u

out="${1:?usage: screens.sh OUTPUT-DIRECTORY}"
tc="${TERM_CAPTURE:-$(dirname "$0")/term-capture}"
work=/home/ana/work/edit

mkdir -p "$out"
export TERM=xterm-256color

# A capture that fails writes an SVG nobody looks at and the run carries on, so
# the count is kept and the exit status says it. `screens-check.mjs` would catch
# it too, by the screen not matching — this says which one, and at the moment it
# happened.
failed=0

# The files the lesson describes, as it describes them. `server.conf` is six
# lines and 101 bytes and the prose says so.
stage() {
	printf '# the server configuration\nlisten 8080\nworkers 4\ntimeout 30\nlog_level info\nlog_file /var/log/app.log\n' >"$work/server.conf"
	printf 'the first line\nthe second line\nthe third line\n' >"$work/notes.txt"
	printf 'apple\nbanana\ncherry\npear\n' >"$work/list.txt"
	rm -f "$work/brandnew.txt" "$work"/.*.swp
	chmod u+w "$work/server.conf" "$work/notes.txt" "$work/list.txt"

	# AND THE VIMINFO, WHICH IS WHY THESE USED TO DEPEND ON THEIR ORDER. Debian's
	# default vimrc jumps to the position you last held in a file, remembered in
	# `~/.viminfo` across runs — so a capture taken after `:%s/log/LOG/g` opened
	# on line 6 and its ruler read `6,1` where the published figure reads `1,1`.
	# Nothing announces that; the screen is simply a different screen. Four of
	# these recipes looked wrong because of it before the cause was found.
	rm -f "$HOME/.viminfo"
}

# One screen. The name is the figure's, so the check can find it.
shot() {
	name="$1"
	shift
	stage
	if (cd "$work" && "$tc" -cols 100 -rows 14 -warmup 2s -out "$out/$name.svg" \
		-save "$out/$name.json" -label "$name" "$@") >/dev/null 2>"$out/$name.err"; then
		printf '%-28s ok\n' "$name"
	else
		printf '%-28s %s\n' "$name" "$(cat "$out/$name.err")"
		failed=$((failed + 1))
	fi
}

vim_shot() { name="$1"; shift; shot "$name" -repaint '' -quit '\e:q!\r' "$@"; }

# --- lesson 12, vim -----------------------------------------------------------

vim_shot vim-modes-0                                    vim server.conf
vim_shot vim-modes-1   -send 'i'                        vim server.conf
# THE SELECTION COLOUR IS STAGED, and the lesson says so beside the figure:
# vim's default Visual is a grey that reads 4.20:1 under white text and 3.68:1
# under black, which is below AA either way. Blue is 6.12:1.
vim_shot vim-modes-2   -send 'Vjj'                      vim -c 'hi Visual ctermbg=blue ctermfg=black' server.conf
vim_shot vim-moving-0  -send 'G'                        vim server.conf
vim_shot vim-survival-0 -send 'x' -send ':q\r'          vim server.conf

vim_shot vim-editing-0 -send '/timeout\r' -send 'w' -send 'dw'  vim server.conf
vim_shot vim-editing-1 -send '2G' -send '3dd'                   vim server.conf
vim_shot vim-editing-2 -send '2G' -send 'yy' -send 'p'          vim server.conf
# `-quiet 1100ms` BECAUSE THIS FIGURE HAS A CLOCK IN IT. vim's undo message says
# how long ago the change it went back past was made, and the settle between the
# second `dd` and the `u` is that gap: under a second it reads `0 seconds ago`
# where the published figure reads `1 second ago`. The window is [1s, 2s) and
# 1100ms sits in the middle of it — 700ms was a coin toss and lost one run in
# four. Anything over two seconds would say `2 seconds ago` instead.
vim_shot vim-editing-3 -quiet 1100ms -send 'dd' -send 'dd' -send 'u'  vim server.conf

vim_shot vim-sr-0      -send '/timeout\r'                       vim server.conf
vim_shot vim-sr-1      -send 'G' -send '/timeout\r'             vim server.conf
vim_shot vim-sr-2      -send ':%s/log/LOG/g\r'                  vim server.conf

vim_shot vim-config-0  -send ':set number\r'                    vim server.conf

vim_shot vim-files-0   -send '/30\r' -send 'cwsixty\e' -send ':w\r'  vim server.conf
vim_shot vim-files-1                                            vim brandnew.txt
# ONE KEYSTROKE PER `-send`, because the first change to a read-only buffer puts
# `W10` on the message line while the rest of the word is still being typed.
# Sent as one string it came out `vm` with the `:w` swallowed — the screen said
# W10 where the lesson wants E45, which is the error `:w` gives and the one the
# paragraph is about.
vim_shot vim-files-2   -quiet 700ms -send 'cw' -send 'vm2' -send '\e' -send ':w\r'  vim /etc/hostname
vim_shot vim-files-3   -send ':ls\r'                            vim server.conf notes.txt
vim_shot vim-files-4   -send ':sp notes.txt\r'                  vim server.conf
vim_shot vim-files-5   -send ':%!sort\r'                        vim list.txt
vim_shot vim-files-6   -send ':r !date +%Y-%m-%d\r'             vim list.txt

# THE ONE SCREEN THAT CANNOT COME BACK THE SAME, and that is not a recipe being
# wrong. E325 reports the swap file's two timestamps and the process id of the
# vim that left it, so those three lines are new every time by construction.
# `screens-check.mjs` names them and holds everything else to the rule.
#
# A swap file is what a vim that was KILLED leaves behind, so that is what this
# is: a vim that makes a change and is then stopped rather than quit. The
# process is found by its exact name among this user's own, which is how
# everything in this repository stops a process it started — a pattern match
# over command lines catches things nobody meant to stop.
swap_file() {
	stage
	(cd "$work" && "$tc" -cols 100 -rows 14 -warmup 2s -repaint '' \
		-send 'Oa line nobody saved\e' -out /dev/null -label 'a vim to kill' \
		vim server.conf) >/dev/null 2>&1 &
	sleep 4
	ps -u "$(id -un)" -o pid,comm | awk '$2=="vim"{print $1}' | xargs -r kill
	sleep 1
	if (cd "$work" && "$tc" -cols 100 -rows 14 -warmup 2s -repaint '' -quit 'q\e:q!\r' \
		-out "$out/vim-survival-1.svg" -save "$out/vim-survival-1.json" \
		-label vim-survival-1 vim server.conf) >/dev/null 2>"$out/vim-survival-1.err"; then
		printf '%-28s ok\n' vim-survival-1
	else
		printf '%-28s %s\n' vim-survival-1 "$(cat "$out/vim-survival-1.err")"
		failed=$((failed + 1))
	fi
	rm -f "$work"/.*.swp
}
swap_file

# --- lesson 12, nano and emacs ------------------------------------------------

shot nano-0  -quit '^X'                                         nano notes.txt
shot nano-1  -send '^W' -send 'second' -quit '^C^X'             nano notes.txt
shot nano-2  -send 'a new word ' -send '^X' -quit '^C^X'        nano notes.txt
shot nano-3  -quit '^X'                                         nano -l +2 notes.txt

# Emacs takes longer than two seconds to paint its first screen, and a warmup
# that ends first photographs a terminal it has not written to yet.
shot emacs-0 -warmup 6s -repaint '' -quit '^X^C'                emacs -nw server.conf
shot emacs-1 -warmup 6s -repaint '' -send 'hello' -send '^X^C' -quit 'n\r' emacs -nw server.conf

if [ "$failed" -ne 0 ]; then
	echo "$failed screen(s) were not taken"
	exit 1
fi
echo 'every screen taken; now: node tools/term-capture/screens-check.mjs '"$out"
