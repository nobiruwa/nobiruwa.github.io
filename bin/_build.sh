#!/usr/bin/env bash

GIT_REPO_ROOT_DIRECTORY=`git rev-parse --show-toplevel`
GIT_REPO_DESTINATION_DIRECTORY="$GIT_REPO_ROOT_DIRECTORY/../nobiruwa.github.io.master.git/"

CUR_DIR=`pwd`

cd "$GIT_REPO_ROOT_DIRECTORY"

stack build && stack exec nobiruwa-github-io-exe clean && stack exec nobiruwa-github-io-exe build

cd "$CUR_DIR"
