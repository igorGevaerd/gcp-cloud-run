#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# test-api.sh — smoke test all API endpoints against the live API Gateway.
#
# Usage:
#   ./scripts/test-api.sh                        # reads outputs from Terraform
#   GATEWAY_URL=https://... API_KEY=abc ./scripts/test-api.sh  # override vars
# ---------------------------------------------------------------------------

PASS=0
FAIL=0

check() {
  local description="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $description (expected HTTP $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

# ---------------------------------------------------------------------------
# Resolve GATEWAY_URL and API_KEY — from env or Terraform outputs
# ---------------------------------------------------------------------------
if [[ -z "${GATEWAY_URL:-}" ]] || [[ -z "${API_KEY:-}" ]]; then
  echo "Reading outputs from Terraform..."
  GATEWAY_URL=$(terraform -chdir=terraform output -raw gateway_url)
  API_KEY=$(terraform -chdir=terraform output -raw api_key)
fi

# Mask the key so it never appears in terminal history or logs
echo "::add-mask::$API_KEY" 2>/dev/null || true

echo ""
echo "Gateway: $GATEWAY_URL"
echo ""

# ---------------------------------------------------------------------------
# Open routes (no API key required)
# ---------------------------------------------------------------------------
echo "Open routes:"

status=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/")
check "GET / returns 2xx" "200" "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/health")
check "GET /health returns 200" "200" "$status"

body=$(curl -s "$GATEWAY_URL/health")
if echo "$body" | grep -q '"status":"ok"'; then
  echo "  PASS  GET /health body contains \"status\":\"ok\""
  PASS=$((PASS + 1))
else
  echo "  FAIL  GET /health body missing \"status\":\"ok\" (got: $body)"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Protected routes — valid API key
# ---------------------------------------------------------------------------
echo ""
echo "Protected routes (with key):"

status=$(curl -s -o /dev/null -w "%{http_code}" -H "x-api-key: $API_KEY" "$GATEWAY_URL/random-int")
check "GET /random-int with key returns 200" "200" "$status"

body=$(curl -s -H "x-api-key: $API_KEY" "$GATEWAY_URL/random-int")
if echo "$body" | grep -q '"value"'; then
  echo "  PASS  GET /random-int body contains \"value\""
  PASS=$((PASS + 1))
else
  echo "  FAIL  GET /random-int body missing \"value\" (got: $body)"
  FAIL=$((FAIL + 1))
fi

status=$(curl -s -o /dev/null -w "%{http_code}" -H "x-api-key: $API_KEY" "$GATEWAY_URL/random-name-string")
check "GET /random-name-string with key returns 200" "200" "$status"

body=$(curl -s -H "x-api-key: $API_KEY" "$GATEWAY_URL/random-name-string")
if echo "$body" | grep -q '"name"'; then
  echo "  PASS  GET /random-name-string body contains \"name\""
  PASS=$((PASS + 1))
else
  echo "  FAIL  GET /random-name-string body missing \"name\" (got: $body)"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Protected routes — missing API key (expect 401)
# ---------------------------------------------------------------------------
echo ""
echo "Auth enforcement (no key):"

status=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/random-int")
check "GET /random-int without key returns 401" "401" "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/random-name-string")
check "GET /random-name-string without key returns 401" "401" "$status"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
