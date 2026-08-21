#!/bin/bash
# script to safely update Caelestia from upstream while preserving local custom features

echo "=> Fetching latest changes from upstream..."
git fetch upstream main

# Check if there are updates
UPSTREAM=${1:-'upstream/main'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "=> Up-to-date! No changes found from upstream."
    exit 0
elif [ "$LOCAL" = "$BASE" ]; then
    echo "=> Updates found! Starting automatic safe update process..."
else
    echo "=> Local custom changes detected! Starting automatic safe update process..."
fi

# 1. Stash any uncommitted local changes (including untracked files like the dock configs)
echo "=> Stashing uncommitted local changes and untracked files..."
git stash push -u -m "Auto-stash before update"

# 2. Rebase onto upstream/main
echo "=> Rebasing onto latest upstream main..."
git rebase upstream/main

if [ $? -ne 0 ]; then
    echo "=> Rebase encountered a conflict. Aborting rebase to preserve your work..."
    git rebase --abort
    git stash pop
    echo "=> ERROR: Update failed due to a merge conflict. Please resolve conflicts manually."
    exit 1
fi

# 3. Pop the stash to restore uncommitted changes
echo "=> Restoring local uncommitted changes..."
git stash pop

echo "=> Update complete!"
echo "=> Rebuilding and installing the C++ plugin to ensure new features work..."
mkdir -p build && cd build && cmake -DCMAKE_INSTALL_PREFIX=/ .. && cmake --build . && DESTDIR="$PWD/../.local-caelestia-plugin" cmake --install .

echo "=> Done! Restarting shell..."
killall -9 quickshell || true
setsid ./scripts/run-local-shell.sh > /dev/null 2>&1 &
echo "=> Shell restarted successfully."
