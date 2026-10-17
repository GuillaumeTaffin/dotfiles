#!/usr/bin/env bash
# Resolve the flake host attribute: explicit $1 wins, otherwise map the current
# macOS account name. Sourced by bootstrap.sh and rebuild.sh.
resolve_host() {
  if [ -n "${1:-}" ]; then
    echo "$1"
    return
  fi
  case "$(id -un)" in
    guillaume.taffin) echo "work" ;;
    guillaumetaffin)  echo "perso" ;;
    *)
      echo "unknown user '$(id -un)': pass the host explicitly (work|perso)" >&2
      return 1
      ;;
  esac
}
