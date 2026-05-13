#!/usr/bin/env bash
#
# One-shot: clear any stuck lock, stage, commit, push.
# Usage: ./push.sh "your commit message"
#
set -euo pipefail

cd "$(dirname "$0")"

# Clear leftover sandbox lock if present
rm -f .git/index.lock

MSG="${1:-Phase 1 scaffold: iOS sources, Firebase emulator wiring, CI, execution README}"

git add .

if git diff --cached --quiet; then
  echo "Nothing to commit. Pushing whatever is already local..."
else
  git commit -m "$MSG"
fi

git push origin main
echo "✓ Pushed to origin/main"
