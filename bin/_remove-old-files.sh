#!/usr/bin/env bash

GIT_REPO_ROOT_DIRECTORY=`git rev-parse --show-toplevel`
GIT_REPO_DESTINATION_DIRECTORY="$GIT_REPO_ROOT_DIRECTORY/../nobiruwa.github.io.master.git/"

rsync -a --filter='P $GIT_REPO_ROOT_DIRECTORY/_site/'      \
         --filter='P $GIT_REPO_ROOT_DIRECTORY/_cache/'     \
         --filter='P $GIT_REPO_ROOT_DIRECTORY/.git/'       \
         --filter='P $GIT_REPO_ROOT_DIRECTORY/.gitignore'  \
         --filter='P $GIT_REPO_ROOT_DIRECTORY/.stack-work' \
         --delete-excluded        \
         "$GIT_REPO_ROOT_DIRECTORY/_site/" \
         "$GIT_REPO_DESTINATION_DIRECTORY"
