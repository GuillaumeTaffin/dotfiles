
export XDG_CONFIG_HOME="$HOME/.config"

export EDITOR=idea
# export ANTHROPIC_MODEL="claude-opus-4-7"

export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH":"$HOME/.local/bin"

# BTCA
export PATH="/Users/guillaumetaffin/.bun/bin:$PATH"

# ZIG
export ZIG_HOME=/Users/guillaumetaffin/dev/zig
export PATH="$PATH:$ZIG_HOME"
alias gw="./gradlew"
alias gwq="./gradlew -q"

alias lg="lazygit"

alias clodo='clear && claude --model claude-opus-4-7'
# alias clodo='clear && claude --allow-dangerously-skip-permissions'

export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"
export PATH="/Users/guillaume.taffin/.bun/bin:$PATH"

# opencode
export PATH=~/.opencode/bin:$PATH

# ZSH Plugins
DOTFILES_DIR=~/.config
source $DOTFILES_DIR/dependencies/zsh-autosuggestions/zsh-autosuggestions.zsh

# STARSHIP
eval "$(starship init zsh)"

eval "$(atuin init zsh)"

# zsh-syntax-highlighting - MUST BE LAST (hooks ZLE widgets)
source $DOTFILES_DIR/dependencies/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# pnpm
export PNPM_HOME="/Users/guillaume.taffin/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

vcc() { ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -ilc claude"; }
vci() {
  if [ "$#" -gt 0 ]; then
    ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -ilc '$*'"
  else
    ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -il"
  fi
}

# Like vci, but relies on Warp's SSH wrapper to warpify the remote shell
# (enables the bottom git/diff bar). Warp only warpifies interactive sessions
# with NO remote command, so the no-arg case passes the target dir via
# LC_WCI_PWD instead (the VM's ~/.zshrc cd's into it). ControlPath=none is
# required because Lima's SSH multiplexing otherwise drops SetEnv vars.
wci() {
  if [ "$#" -gt 0 ]; then
    ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -ilc '$*'"
  else
    ssh -t -o ControlPath=none -o SetEnv=LC_WCI_PWD="$PWD" lima-cc-dev
  fi
}

vccx() { cmux ssh lima-cc-dev --ssh-option RequestTTY=force -- "cd $PWD && exec \$SHELL -ilc claude"; }
vcix() { cmux ssh lima-cc-dev --ssh-option RequestTTY=force -- "cd $PWD && exec \$SHELL -il"; }
