#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# This script is intended to be used *just after* running `npm version`. It will:
#
# - Save the Git tag from the last `npm version`,
LATEST_GIT_TAG=`git describe --tags`
# - Generate CHANGELOG (plain-text) and CHANGELOG.md (markdown) files,
$DIR/changelog > CHANGELOG.md
$DIR/changelog -v TYPE=plain > CHANGELOG
# - Commit those files, then squash the commit into the NPM version commit,
git add ./CHANGELOG.md ./CHANGELOG
git commit --amend -C HEAD
# - Delete the old tag and make a new one for the squashed commit.
git tag -d $LATEST_GIT_TAG
git tag $LATEST_GIT_TAG
