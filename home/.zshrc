
export JAVA_VERSION="graalvm-ce-java17-22.3.0"
export GRAALVM_HOME="/Library/Java/JavaVirtualMachines/${JAVA_VERSION}/Contents/Home"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/${JAVA_VERSION}/Contents/Home"
export PATH="${JAVA_HOME}/bin:$PATH"
export PATH="${GRAALVM_HOME}/bin:$PATH"

export GROOVY_HOME=/opt/homebrew/opt/groovy/libexec

export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH":"$HOME/.local/bin"

export NODE_VERSION="18"
export PATH="/opt/homebrew/opt/node@$NODE_VERSION/bin:$PATH"

export GOPATH=/opt/homebrew/Cellar/go/1.20.4
export PATH="$PATH:$GOPATH/bin"

alias connect_baker="ssh -p 9563 baker@74.57.172.27"
alias ghostnet-client="octez-client -E https://ghostnet.tezos.marigold.dev"

# BTCA
export PATH="/Users/guillaumetaffin/.bun/bin:$PATH"

# ZIG
export ZIG_HOME=/Users/guillaumetaffin/dev/zig
export PATH="$PATH:$ZIG_HOME"
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/curl/lib"
export CPPFLAGS="-I/opt/homebrew/opt/curl/include"

alias gw="./gradlew"
alias gwq="./gradlew -q"

alias docker=podman
export XDG_CONFIG_HOME="$HOME/.config"

alias lg="lazygit"

export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# bun completions
[ -s "/Users/guillaumetaffin/.bun/_bun" ] && source "/Users/guillaumetaffin/.bun/_bun"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/Users/guillaumetaffin/.opencode/bin:$PATH

# ZSH Plugins
DOTFILES_DIR=~/dev/projects/dotfiles
source $DOTFILES_DIR/dependencies/zsh-autosuggestions/zsh-autosuggestions.zsh

# STARSHIP
eval "$(starship init zsh)"

. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# zsh-syntax-highlighting - MUST BE LAST (hooks ZLE widgets)
source $DOTFILES_DIR/dependencies/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
