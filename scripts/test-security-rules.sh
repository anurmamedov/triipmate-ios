#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="demo-triipmate-local"
AUTH_URL="http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1"
FIRESTORE_URL="http://127.0.0.1:8080/v1/projects/$PROJECT_ID/databases/(default)/documents"
STORAGE_URL="http://127.0.0.1:9199/v0/b/$PROJECT_ID.appspot.com/o"
API_KEY="triipmate-local"
PASSWORD="LocalTest123"

USER_A_TOKEN=""
USER_B_TOKEN=""
USER_A_ID=""
USER_B_ID=""

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

create_user() {
  local email="$1"
  auth_request "accounts:signUp" "{\"email\":\"$email\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}"
}

delete_user() {
  local token="$1"
  if [[ -n "$token" ]]; then
    auth_request "accounts:delete" "{\"idToken\":\"$token\"}" >/dev/null 2>&1 || true
  fi
}

firestore_status() {
  local method="$1"
  local path="$2"
  local token="$3"
  local body="${4:-}"
  local args=(--silent --output /dev/null --write-out "%{http_code}" --request "$method" "$FIRESTORE_URL/$path" --header "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(--header "Content-Type: application/json" --data "$body")
  fi
  curl "${args[@]}"
}

storage_status() {
  local method="$1"
  local path="$2"
  local token="$3"
  local body="${4:-}"
  local args=(--silent --output /dev/null --write-out "%{http_code}" --request "$method" "$STORAGE_URL/$path" --header "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(--header "Content-Type: image/jpeg" --data-binary "$body")
  fi
  curl "${args[@]}"
}

expect_success() {
  local status="$1"
  local label="$2"
  if [[ ! "$status" =~ ^2 ]]; then
    printf 'Expected success for %s, got HTTP %s.\n' "$label" "$status" >&2
    exit 1
  fi
}

expect_rejected() {
  local status="$1"
  local label="$2"
  if [[ "$status" != "401" && "$status" != "403" ]]; then
    printf 'Expected rejection for %s, got HTTP %s.\n' "$label" "$status" >&2
    exit 1
  fi
}

profile_document() {
  local uid="$1"
  local email="$2"
  cat <<JSON
{"fields":{"firstName":{"stringValue":"Security"},"lastName":{"stringValue":"Tester"},"email":{"stringValue":"$email"},"phone":{"stringValue":"+1 4165550100"},"countryCode":{"stringValue":"+1"},"role":{"stringValue":"driver"},"profilePhotoPath":{"stringValue":"profilePhotos/$uid.jpg"},"ratingCount":{"integerValue":"0"},"completedTripCount":{"integerValue":"0"},"totalSavingsCents":{"integerValue":"0"},"isIdentityVerified":{"booleanValue":false},"isDriverVerified":{"booleanValue":false},"updatedAt":{"stringValue":"2026-07-11T00:00:00Z"}}}
JSON
}

vehicle_document() {
  cat <<JSON
{"fields":{"make":{"stringValue":"Honda"},"model":{"stringValue":"Civic"},"year":{"stringValue":"2020"},"powerType":{"stringValue":"Fuel"},"bodyType":{"stringValue":"Sedan"},"isDefault":{"booleanValue":true}}}
JSON
}

ride_document() {
  local driver_uid="$1"
  cat <<JSON
{"fields":{"driverUid":{"stringValue":"$driver_uid"},"driverDisplayName":{"stringValue":"Security Tester"},"driverProfilePhotoPath":{"nullValue":null},"from":{"mapValue":{"fields":{"city":{"stringValue":"Toronto"},"state":{"stringValue":"ON"},"displayName":{"stringValue":"Toronto, ON"},"normalizedName":{"stringValue":"toronto on"}}}},"to":{"mapValue":{"fields":{"city":{"stringValue":"Ottawa"},"state":{"stringValue":"ON"},"displayName":{"stringValue":"Ottawa, ON"},"normalizedName":{"stringValue":"ottawa on"}}}},"departureAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783900800"},"nanoseconds":{"integerValue":"0"}}}},"expectedArrivalAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783915200"},"nanoseconds":{"integerValue":"0"}}}},"estimatedDurationMinutes":{"integerValue":"240"},"availableSeats":{"integerValue":"2"},"totalSeats":{"integerValue":"3"},"pricePerSeatCents":{"integerValue":"4500"},"vehicle":{"mapValue":{"fields":{"vehicleId":{"stringValue":"vehicle-security"},"make":{"stringValue":"Honda"},"model":{"stringValue":"Civic"},"year":{"stringValue":"2020"},"powerType":{"stringValue":"Fuel"},"bodyType":{"stringValue":"Sedan"}}}},"status":{"stringValue":"published"},"notes":{"stringValue":"Security rule test"},"createdAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}},"updatedAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}}}}
JSON
}

ride_request_document() {
  local passenger_uid="$1"
  local status="$2"
  cat <<JSON
{"fields":{"rideId":{"stringValue":"security-ride-$$"},"passengerUid":{"stringValue":"$passenger_uid"},"passengerDisplayName":{"stringValue":"Passenger Tester"},"passengerProfilePhotoPath":{"nullValue":null},"seatsRequested":{"integerValue":"1"},"pickupNote":{"stringValue":"Main entrance"},"dropoffNote":{"stringValue":"Downtown"},"luggageNote":{"stringValue":"One bag"},"message":{"stringValue":"Can I join?"},"pricePerSeatCents":{"integerValue":"4500"},"status":{"stringValue":"$status"},"createdAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}},"updatedAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}},"decidedAt":{"nullValue":null}}}
JSON
}

conversation_document() {
  local driver_uid="$1"
  local passenger_uid="$2"
  cat <<JSON
{"fields":{"rideId":{"stringValue":"security-ride-$$"},"requestId":{"stringValue":"security-request-$$"},"participantUids":{"arrayValue":{"values":[{"stringValue":"$driver_uid"},{"stringValue":"$passenger_uid"}]}},"driverUid":{"stringValue":"$driver_uid"},"passengerUid":{"stringValue":"$passenger_uid"},"driverDisplayName":{"stringValue":"Security Driver"},"passengerDisplayName":{"stringValue":"Security Passenger"},"routeTitle":{"stringValue":"Toronto, ON to Ottawa, ON"},"lastMessagePreview":{"nullValue":null},"lastMessageAt":{"nullValue":null},"unreadCountsByUid":{"mapValue":{"fields":{"$driver_uid":{"integerValue":"0"},"$passenger_uid":{"integerValue":"0"}}}},"status":{"stringValue":"active"},"createdAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}},"updatedAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}}}}
JSON
}

message_document() {
  local sender_uid="$1"
  cat <<JSON
{"fields":{"conversationId":{"stringValue":"security-conversation-$$"},"senderUid":{"stringValue":"$sender_uid"},"body":{"stringValue":"Security message"},"status":{"stringValue":"sent"},"readByUids":{"arrayValue":{"values":[{"stringValue":"$sender_uid"}]}},"createdAt":{"mapValue":{"fields":{"seconds":{"integerValue":"1783814400"},"nanoseconds":{"integerValue":"0"}}}}}}
JSON
}

cleanup() {
  if [[ -n "$USER_A_TOKEN" ]]; then
    firestore_status DELETE "users/$USER_A_ID" "$USER_A_TOKEN" >/dev/null 2>&1 || true
    firestore_status DELETE "rides/security-ride-$$" "$USER_A_TOKEN" >/dev/null 2>&1 || true
    firestore_status DELETE "rideRequests/security-request-$$" "$USER_A_TOKEN" >/dev/null 2>&1 || true
    firestore_status DELETE "conversations/security-conversation-$$/messages/security-message-$$" "$USER_A_TOKEN" >/dev/null 2>&1 || true
    storage_status DELETE "profilePhotos%2F$USER_A_ID.jpg" "$USER_A_TOKEN" >/dev/null 2>&1 || true
  fi
  delete_user "$USER_A_TOKEN"
  delete_user "$USER_B_TOKEN"
}
trap cleanup EXIT

for port in 8080 9099 9199; do
  if ! curl --silent --output /dev/null "http://127.0.0.1:$port"; then
    printf 'Firebase emulator port %s is not available.\n' "$port" >&2
    exit 1
  fi
done

printf '1/8 Creating disposable users...\n'
USER_A_EMAIL="triipmate-security-a-$$@example.com"
USER_B_EMAIL="triipmate-security-b-$$@example.com"
USER_A_RESPONSE="$(create_user "$USER_A_EMAIL")"
USER_B_RESPONSE="$(create_user "$USER_B_EMAIL")"
USER_A_TOKEN="$(printf '%s' "$USER_A_RESPONSE" | json_value idToken)"
USER_A_ID="$(printf '%s' "$USER_A_RESPONSE" | json_value localId)"
USER_B_TOKEN="$(printf '%s' "$USER_B_RESPONSE" | json_value idToken)"
USER_B_ID="$(printf '%s' "$USER_B_RESPONSE" | json_value localId)"

printf '2/8 Checking profile ownership...\n'
expect_success "$(firestore_status PATCH "users/$USER_A_ID" "$USER_A_TOKEN" "$(profile_document "$USER_A_ID" "$USER_A_EMAIL")")" "own profile write"
expect_rejected "$(firestore_status PATCH "users/$USER_A_ID" "$USER_B_TOKEN" "$(profile_document "$USER_A_ID" "$USER_A_EMAIL")")" "other user profile write"

printf '3/8 Checking vehicle ownership...\n'
expect_success "$(firestore_status PATCH "users/$USER_A_ID/vehicles/security-vehicle-$$" "$USER_A_TOKEN" "$(vehicle_document)")" "own vehicle write"
expect_rejected "$(firestore_status PATCH "users/$USER_A_ID/vehicles/security-vehicle-$$" "$USER_B_TOKEN" "$(vehicle_document)")" "other user vehicle write"

printf '4/8 Checking profile photo ownership...\n'
expect_success "$(storage_status POST "?uploadType=media&name=profilePhotos%2F$USER_A_ID.jpg" "$USER_A_TOKEN" "photo")" "own profile photo upload"
expect_rejected "$(storage_status POST "?uploadType=media&name=profilePhotos%2F$USER_A_ID.jpg" "$USER_B_TOKEN" "photo")" "other user profile photo upload"

printf '5/8 Checking ride ownership...\n'
expect_success "$(firestore_status PATCH "rides/security-ride-$$" "$USER_A_TOKEN" "$(ride_document "$USER_A_ID")")" "driver ride create"
expect_rejected "$(firestore_status PATCH "rides/security-ride-$$" "$USER_B_TOKEN" "$(ride_document "$USER_A_ID")")" "other user ride update"

printf '6/8 Checking ride request ownership and driver decision access...\n'
expect_success "$(firestore_status PATCH "rideRequests/security-request-$$" "$USER_B_TOKEN" "$(ride_request_document "$USER_B_ID" pending)")" "passenger request create"
expect_rejected "$(firestore_status PATCH "rideRequests/security-request-$$" "$USER_A_TOKEN" "$(ride_request_document "$USER_A_ID" pending)")" "driver changing request passenger"
expect_success "$(firestore_status PATCH "rideRequests/security-request-$$" "$USER_A_TOKEN" "$(ride_request_document "$USER_B_ID" accepted)")" "driver request decision"

printf '7/8 Checking conversation and message sender access...\n'
expect_success "$(firestore_status PATCH "conversations/security-conversation-$$" "$USER_A_TOKEN" "$(conversation_document "$USER_A_ID" "$USER_B_ID")")" "participant conversation create"
expect_success "$(firestore_status PATCH "conversations/security-conversation-$$/messages/security-message-$$" "$USER_B_TOKEN" "$(message_document "$USER_B_ID")")" "participant message create"
expect_rejected "$(firestore_status PATCH "conversations/security-conversation-$$/messages/security-impersonation-$$" "$USER_B_TOKEN" "$(message_document "$USER_A_ID")")" "message sender impersonation"

printf '8/8 Checking anonymous access is rejected...\n'
ANONYMOUS_STATUS="$(curl --silent --output /dev/null --write-out "%{http_code}" "$FIRESTORE_URL/users/$USER_A_ID")"
expect_rejected "$ANONYMOUS_STATUS" "anonymous profile read"

printf 'Security rule checks passed.\n'
