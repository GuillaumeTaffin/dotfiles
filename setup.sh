#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR/home" && stow .
cd "$SCRIPT_DIR/config" && stow .
