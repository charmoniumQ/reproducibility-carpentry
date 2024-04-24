#!/usr/bin/env -S nix develop --command bash
R --quiet --no-save --no-restore -e 'sandpaper::serve()'
