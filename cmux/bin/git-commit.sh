#!/usr/bin/env zsh
# Conventional commit via worktrunk. Side-effect-clean (no surface/focus glue).
# Extra args pass through to `wt step commit`.
exec wt step commit "$@"
