#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="demo-triipmate-local"
AUTH_URL="http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1"
FIRESTORE_URL="http://127.0.0.1:8080/v1/projects/$PROJECT_ID/databases/(default)/documents"
STORAGE_URL="http://127.0.0.1:9199/v0/b/$PROJECT_ID.appspot.com/o"
API_KEY="triipmate-local"
EMAIL="triipmate-profile-test-$$@example.com"
PASSWORD="LocalTest123"
ID_TOKEN=""
USER_ID=""
PHOTO_PATH="profilePhotos%2Fprofile-test-$$.jpg"

json_value() {
  local key="$1"
  /usr/bin/plutil -extract "$key" raw -o - -
}

auth_request() {
  local endpoint="$1"
  local body="$2"
  curl --silent --show-error \
    --request POST \
    "$AUTH_URL/$endpoint?key=$API_KEY" \
    --header "Content-Type: application/json" \
    --data "$body"
}

profile_document() {
  local role="$1"
  local last_name="$2"
  cat <<JSON
{"fields":{"firstName":{"stringValue":"Profile"},"lastName":{"stringValue":"$last_name"},"email":{"stringValue":"$EMAIL"},"phone":{"stringValue":"+1 4165550100"},"role":{"stringValue":"$role"},"profilePhotoPath":{"stringValue":"profilePhotos/profile-test-$$.jpg"},"ratingCount":{"integerValue":"0"},"completedTripCount":{"integerValue":"0"},"totalSavingsCents":{"integerValue":"0"},"isIdentityVerified":{"booleanValue":false},"isDriverVerified":{"booleanValue":false},"updatedAt":{"stringValue":"2026-07-08T00:00:00Z"}}}
JSON
}

cleanup() {
  if [[ -n "$USER_ID" && -n "$ID_TOKEN" ]]; then
    curl --silent --request DELETE "$FIRESTORE_URL/users/$USER_ID" \
      --header "Authorization: Bearer $ID_TOKEN" >/dev/null 2>&1 || true
    curl --silent --request DELETE "$STORAGE_URL/$PHOTO_PATH" \
      --header "Authorization: Bearer $ID_TOKEN" >/dev/null 2>&1 || true
  fi
  if [[ -n "$ID_TOKEN" ]]; then
    auth_request "accounts:delete" "{\"idToken\":\"$ID_TOKEN\"}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

for port in 8080 9099 9199; do
  if ! curl --silent --output /dev/null "http://127.0.0.1:$port"; then
    printf 'Firebase emulator port %s is not available.\n' "$port" >&2
    exit 1
  fi
done

printf '1/8 Creating a disposable authenticated user...\n'
AUTH_RESPONSE="$(auth_request "accounts:signUp" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")"
ID_TOKEN="$(printf '%s' "$AUTH_RESPONSE" | json_value idToken)"
USER_ID="$(printf '%s' "$AUTH_RESPONSE" | json_value localId)"

printf '2/8 Saving and loading the passenger profile...\n'
curl --silent --show-error --fail \
  --request PATCH "$FIRESTORE_URL/users/$USER_ID" \
  --header "Authorization: Bearer $ID_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$(profile_document passenger User)" >/dev/null
PROFILE_RESPONSE="$(curl --silent --show-error --fail "$FIRESTORE_URL/users/$USER_ID" --header "Authorization: Bearer $ID_TOKEN")"
[[ "$(printf '%s' "$PROFILE_RESPONSE" | json_value fields.firstName.stringValue)" == "Profile" ]]
[[ "$(printf '%s' "$PROFILE_RESPONSE" | json_value fields.role.stringValue)" == "passenger" ]]
[[ "$(printf '%s' "$PROFILE_RESPONSE" | json_value fields.completedTripCount.integerValue)" == "0" ]]

printf '3/8 Updating personal information and driver mode...\n'
curl --silent --show-error --fail \
  --request PATCH "$FIRESTORE_URL/users/$USER_ID" \
  --header "Authorization: Bearer $ID_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$(profile_document driver Updated)" >/dev/null
UPDATED_RESPONSE="$(curl --silent --show-error --fail "$FIRESTORE_URL/users/$USER_ID" --header "Authorization: Bearer $ID_TOKEN")"
[[ "$(printf '%s' "$UPDATED_RESPONSE" | json_value fields.lastName.stringValue)" == "Updated" ]]
[[ "$(printf '%s' "$UPDATED_RESPONSE" | json_value fields.role.stringValue)" == "driver" ]]

printf '4/8 Uploading and downloading the profile photo...\n'
curl --silent --show-error --fail \
  --request POST "$STORAGE_URL?uploadType=media&name=$PHOTO_PATH" \
  --header "Authorization: Bearer $ID_TOKEN" \
  --header "Content-Type: image/jpeg" \
  --data-binary "profile-photo-test" >/dev/null
PHOTO_RESPONSE="$(curl --silent --show-error --fail "$STORAGE_URL/$PHOTO_PATH?alt=media" --header "Authorization: Bearer $ID_TOKEN")"
[[ "$PHOTO_RESPONSE" == "profile-photo-test" ]]

printf '5/8 Logging in again and reloading profile data...\n'
LOGIN_RESPONSE="$(auth_request "accounts:signInWithPassword" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")"
ID_TOKEN="$(printf '%s' "$LOGIN_RESPONSE" | json_value idToken)"
RELOADED_PROFILE="$(curl --silent --show-error --fail "$FIRESTORE_URL/users/$USER_ID" --header "Authorization: Bearer $ID_TOKEN")"
[[ "$(printf '%s' "$RELOADED_PROFILE" | json_value fields.lastName.stringValue)" == "Updated" ]]
[[ "$(printf '%s' "$RELOADED_PROFILE" | json_value fields.role.stringValue)" == "driver" ]]
RELOADED_PHOTO="$(curl --silent --show-error --fail "$STORAGE_URL/$PHOTO_PATH?alt=media" --header "Authorization: Bearer $ID_TOKEN")"
[[ "$RELOADED_PHOTO" == "profile-photo-test" ]]

printf '6/8 Confirming unauthenticated profile access is rejected...\n'
UNAUTHORIZED_STATUS="$(curl --silent --output /dev/null --write-out '%{http_code}' "$FIRESTORE_URL/users/$USER_ID")"
[[ "$UNAUTHORIZED_STATUS" == "401" || "$UNAUTHORIZED_STATUS" == "403" ]]

printf '7/8 Deleting disposable profile data...\n'
curl --silent --show-error --fail --request DELETE "$FIRESTORE_URL/users/$USER_ID" \
  --header "Authorization: Bearer $ID_TOKEN" >/dev/null
curl --silent --show-error --fail --request DELETE "$STORAGE_URL/$PHOTO_PATH" \
  --header "Authorization: Bearer $ID_TOKEN" >/dev/null

printf '8/8 Deleting the disposable Auth user...\n'
auth_request "accounts:delete" "{\"idToken\":\"$ID_TOKEN\"}" >/dev/null
ID_TOKEN=""
USER_ID=""

printf 'Profile emulator checks passed.\n'
