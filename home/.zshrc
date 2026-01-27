
export XDG_CONFIG_HOME="$HOME/.config"

export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH":"$HOME/.local/bin"

# BTCA
export PATH="/Users/guillaumetaffin/.bun/bin:$PATH"

# ZIG
export ZIG_HOME=/Users/guillaumetaffin/dev/zig
export PATH="$PATH:$ZIG_HOME"
alias gw="./gradlew"
alias gwq="./gradlew -q"

alias docker=podman

alias lg="lazygit"

export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# bun completions
[ -s "/Users/guillaumetaffin/.bun/_bun" ] && source "/Users/guillaumetaffin/.bun/_bun"

# opencode
export PATH=~/.opencode/bin:$PATH

# ZSH Plugins
DOTFILES_DIR=~/.config
source $DOTFILES_DIR/dependencies/zsh-autosuggestions/zsh-autosuggestions.zsh

# STARSHIP
eval "$(starship init zsh)"

. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# zsh-syntax-highlighting - MUST BE LAST (hooks ZLE widgets)
source $DOTFILES_DIR/dependencies/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
