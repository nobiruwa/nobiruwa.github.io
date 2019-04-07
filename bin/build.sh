#!/usr/bin/env bash

GIT_REPO_ROOT_DIRECTORY=`git rev-parse --show-toplevel`

BIN_DIR="$GIT_REPO_ROOT_DIRECTORY/bin"

"$BIN_DIR/_build.sh" && "$BIN_DIR/_remove-old-files.sh"
