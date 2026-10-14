#!/bin/sh
# Print a commit for the current working tree without changing refs or the index.
set -eu

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
parent=$(git rev-parse --verify HEAD)

snapshot_dir=$(mktemp -d "${TMPDIR:-/tmp}/independent-review-snapshot.XXXXXX")
trap 'rm -rf "$snapshot_dir"' 0
trap 'exit 1' HUP INT TERM

# Seed from the real index so staged, ignored files remain tracked. The private
# index also isolates partially staged changes from the snapshot's git add.
original_index=$(git rev-parse --git-path index)
if [ -f "$original_index" ]; then
    cp "$original_index" "$snapshot_dir/index"
fi
GIT_INDEX_FILE="$snapshot_dir/index"
export GIT_INDEX_FILE
if [ ! -f "$GIT_INDEX_FILE" ]; then
    git read-tree "$parent"
fi

git add --all -- .
tree=$(git write-tree)
git commit-tree "$tree" -p "$parent" -m 'Independent review working-tree snapshot'
