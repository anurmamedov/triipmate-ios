#!/usr/bin/env bash

set -euo pipefail

AUTH_URL="http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1"
TOKEN_URL="http://127.0.0.1:9099/securetoken.googleapis.com/v1/token"
API_KEY="triipmate-local"
EMAIL="triipmate-auth-test-$$@example.com"
UPDATED_EMAIL="triipmate-auth-test-updated-$$@example.com"
PASSWORD="LocalTest123"
ID_TOKEN=""

json_value() {
  local key="$1"
  /usr/bin/plutil -extract "$key" raw -o - -
}

request() {
  local endpoint="$1"
  local body="$2"
  curl --silent --show-error \
    --request POST \
    "$AUTH_URL/$endpoint?key=$API_KEY" \
    --header "Content-Type: application/json" \
    --data "$body"
}

cleanup() {
  if [[ -n "$ID_TOKEN" ]]; then
    request "accounts:delete" "{\"idToken\":\"$ID_TOKEN\"}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if ! curl --silent --fail --output /dev/null "http://127.0.0.1:9099"; then
  printf 'Auth emulator is not running on 127.0.0.1:9099.\n' >&2
  exit 1
fi

printf '1/8 Registering disposable user...\n'
REGISTER_RESPONSE="$(request "accounts:signUp" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")"
ID_TOKEN="$(printf '%s' "$REGISTER_RESPONSE" | json_value idToken)"
REFRESH_TOKEN="$(printf '%s' "$REGISTER_RESPONSE" | json_value refreshToken)"

printf '2/8 Checking duplicate-email rejection...\n'
DUPLICATE_RESPONSE="$(request "accounts:signUp" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")"
[[ "$(printf '%s' "$DUPLICATE_RESPONSE" | json_value error.message)" == "EMAIL_EXISTS" ]]

printf '3/8 Checking wrong-password rejection...\n'
WRONG_PASSWORD_RESPONSE="$(request "accounts:signInWithPassword" "{\"email\":\"$EMAIL\",\"password\":\"wrong-password\",\"returnSecureToken\":true}")"
WRONG_PASSWORD_ERROR="$(printf '%s' "$WRONG_PASSWORD_RESPONSE" | json_value error.message)"
[[ "$WRONG_PASSWORD_ERROR" == "INVALID_LOGIN_CREDENTIALS" || "$WRONG_PASSWORD_ERROR" == "INVALID_PASSWORD" ]]

printf '4/8 Refreshing the saved session token...\n'
REFRESH_RESPONSE="$(curl --silent --show-error --request POST \
  "$TOKEN_URL?key=$API_KEY" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=refresh_token" \
  --data-urlencode "refresh_token=$REFRESH_TOKEN")"
ID_TOKEN="$(printf '%s' "$REFRESH_RESPONSE" | json_value id_token)"

printf '5/8 Changing email...\n'
UPDATE_RESPONSE="$(request "accounts:update" "{\"idToken\":\"$ID_TOKEN\",\"email\":\"$UPDATED_EMAIL\",\"returnSecureToken\":true}")"
ID_TOKEN="$(printf '%s' "$UPDATE_RESPONSE" | json_value idToken)"
[[ "$(printf '%s' "$UPDATE_RESPONSE" | json_value email)" == "$UPDATED_EMAIL" ]]

printf '6/8 Confirming the old email no longer logs in...\n'
OLD_LOGIN_RESPONSE="$(request "accounts:signInWithPassword" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")"
[[ "$(printf '%s' "$OLD_LOGIN_RESPONSE" | json_value error.message)" == "INVALID_LOGIN_CREDENTIALS" ]]

printf '7/8 Logging in with the updated email and creating a reset link...\n'
NEW_LOGIN_RESPONSE="$(request "accounts:signInWithPassword" "{\"email\":\"$UPDATED_EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")"
ID_TOKEN="$(printf '%s' "$NEW_LOGIN_RESPONSE" | json_value idToken)"
RESET_RESPONSE="$(request "accounts:sendOobCode" "{\"requestType\":\"PASSWORD_RESET\",\"email\":\"$UPDATED_EMAIL\"}")"
[[ "$(printf '%s' "$RESET_RESPONSE" | json_value email)" == "$UPDATED_EMAIL" ]]

printf '8/8 Deleting the disposable user...\n'
request "accounts:delete" "{\"idToken\":\"$ID_TOKEN\"}" >/dev/null
ID_TOKEN=""

printf 'Authentication emulator checks passed.\n'
