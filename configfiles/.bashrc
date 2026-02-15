[[ $- != *i* ]] && return
[ -f "$HOME"/.bash_aliases ] && . "$HOME"/.bash_aliases
[ -f ~/.fzf.bash ] && source "$HOME"/.fzf.bash

GRC_ALIASES=true
[[ -s "/etc/profile.d/grc.sh" ]] && source /etc/grc.sh

bind 'set completion-ignore-case on'

HISTSIZE=HISTFILESIZE=

export TERM=xterm-256color
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-P -c"
export EDITOR='vim'
export PATH="$HOME/.local/bin:$PATH"
export GOPATH="$HOME/.local/go"
export MAKEFLAGS="-j2"

export FZF_DEFAULT_OPTS="
	--color=fg:#ffffff,bg:#000000,hl:#ff0000
	--color=fg+:#e0def4,bg+:#26233a,hl+:#1be6ee
	--color=border:#403d52,header:#31748f,gutter:#191724
	--color=spinner:#f6c177,info:#9ccfd8,separator:#403d52
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

export LESS='-R -M -I'
export LESSPROMPT='%{?f%f:}  %{G[Line: %l/%L]}%{M[Col: %c]} (%p%%)'
export LESS_TERMCAP_md=$'\e[01;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_us=$'\e[04;35m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_se=$'\e[0m'

alias ls='lsd'
alias l='lsd -alh'
alias lh='lsd -hl'
alias ll='lsd -a'
alias s='source ~/.bashrc'
alias cat='bat --style=plain --theme=GitHub'
alias p='sudo poweroff'
alias r='sudo reboot'
alias mi='sudo make install'
alias mc='make clean'
alias lb='lsblk'
alias htop='htop -t'
alias patch='patch -p1 <'
alias grep='grep -i --color=auto'
alias gc='git clone --depth=1'
alias gs='git status'
alias gm='git commit -m'
alias ga='git add .'
alias gr='git restore'
alias gp='git push'
alias gl='git log'
alias gf='git diff'
alias yl='yt-dlp -F'
alias y='yt-dlp'
alias ya='yt-dlp -f 140'
alias yb='yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4'
alias yt='yt-dlp --skip-download --write-thumbnail'

function parse_git_branch() {
	BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
	if [ ! "${BRANCH}" == "" ]
	then
		STAT=$(parse_git_dirty)
		echo "[${BRANCH}${STAT}]"
	else
		echo ""
	fi
}

function parse_git_dirty {
	status=$(git status 2>&1 | tee)
	dirty=$(echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?")
	untracked=$(echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?")
	ahead=$(echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?")
	newfile=$(echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?")
	renamed=$(echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?")
	deleted=$(echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?")
	bits=''
	if [ "${renamed}" == "0" ]; then
		bits=">${bits}"
	fi
	if [ "${ahead}" == "0" ]; then
		bits="*${bits}"
	fi
	if [ "${newfile}" == "0" ]; then
		bits="+${bits}"
	fi
	if [ "${untracked}" == "0" ]; then
		bits="?${bits}"
	fi
	if [ "${deleted}" == "0" ]; then
		bits="x${bits}"
	fi
	if [ "${dirty}" == "0" ]; then
		bits="!${bits}"
	fi
	if [ ! "${bits}" == "" ]; then
		echo " ${bits}"
	else
		echo ""
	fi
}

export PS1="[\[\e[36m\]\h \w\[\e[m\]\[\e[35m\]\`parse_git_branch\`\[\e[m\]] "
