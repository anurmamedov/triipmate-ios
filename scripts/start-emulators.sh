#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ID="demo-triipmate-local"
DATA_DIR="$ROOT_DIR/firebase-dataok"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_file() {
  [[ -f "$ROOT_DIR/$1" ]] || fail "Missing required file: $1"
}

resolve_java() {
  local java_command=""
  local candidate

  if [[ -x /usr/libexec/java_home ]] && /usr/libexec/java_home -v 21 >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 21)"
    java_command="$JAVA_HOME/bin/java"
  elif command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
    java_command="$(command -v java)"
  else
    for candidate in \
      /opt/homebrew/opt/openjdk@21/bin/java \
      /usr/local/opt/openjdk@21/bin/java; do
      if [[ -x "$candidate" ]]; then
        java_command="$candidate"
        break
      fi
    done
  fi

  [[ -n "$java_command" ]] || fail "JDK 21 is required. Install it, then run this command again."

  local version
  version="$($java_command -version 2>&1 | awk -F '[\".]' '/version/ { print $2; exit }')"
  [[ "$version" == "21" ]] || fail "JDK 21 is required, but Java $version was found at $java_command."

  if [[ -z "${JAVA_HOME:-}" ]]; then
    export JAVA_HOME="$(cd "$(dirname "$java_command")/.." && pwd)"
  fi
  export PATH="$JAVA_HOME/bin:$PATH"
}

check_setup() {
  command -v firebase >/dev/null 2>&1 || fail "Firebase CLI is required. Install it with: npm install -g firebase-tools"
  resolve_java

  require_file ".firebaserc"
  require_file "firebase.json"
  require_file "firestore.rules"
  require_file "storage.rules"
  require_file "firebase-dataok/firebase-export-metadata.json"

  printf 'Firebase CLI: %s\n' "$(firebase --version)"
  printf 'Java: %s\n' "$(java -version 2>&1 | head -n 1)"
  printf 'Project: %s\n' "$PROJECT_ID"
  printf 'Data: %s\n' "$DATA_DIR"
}

cd "$ROOT_DIR"
check_setup

if [[ "${1:-}" == "--check" ]]; then
  printf 'Local Firebase setup is ready.\n'
  exit 0
fi

if [[ $# -gt 0 ]]; then
  fail "Unknown option: $1. Use --check or run without arguments."
fi

printf 'Starting Auth, Firestore, Storage, and Emulator UI...\n'
printf 'Data will be imported now and exported when the emulators stop.\n'

exec firebase emulators:start \
  --project "$PROJECT_ID" \
  --import="$DATA_DIR" \
  --export-on-exit="$DATA_DIR"
