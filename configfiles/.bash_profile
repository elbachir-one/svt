[ -f $HOME/.bashrc ] && . $HOME/.bashrc

if [ -z "$XDG_RUNTIME_DIR" ]; then
	XDG_RUNTIME_DIR="/tmp/$(id -u)-runtime-dir"

	mkdir -pm 0700 "$XDG_RUNTIME_DIR"
	export XDG_RUNTIME_DIR
fi

if [ -t 0 ]; then
	if command -v resize >/dev/null; then
		eval "$(resize)"
	fi
fi
