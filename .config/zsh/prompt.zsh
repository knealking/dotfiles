# ~/.config/zsh/prompt.zsh
# Define the target installation directory

PURE_DIR="$ZDOTDIR/plugins/pure"

# Auto-clone Pure if it hasn't been cloned yet
if [ ! -d "$PURE_DIR" ]; then
    echo "Pure prompt not found. Cloning repository..."
    git clone --depth=1 https://github.com/sindresorhus/pure.git "$PURE_DIR"
fi

# Add Pure to the fpath function autoload directory
fpath+=("$PURE_DIR")

# .zshrc
fpath+=($PURE_DIR)

autoload -U promptinit; promptinit

# optionally define some options
PURE_CMD_MAX_EXEC_TIME=10

# change the path color
zstyle :prompt:pure:path color white

# turn on git stash status
zstyle :prompt:pure:git:stash show yes

prompt pure
