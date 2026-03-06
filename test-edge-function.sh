#!/bin/bash

# Test script for Supabase Edge Function
# This script tests the hubspot edge function's createNote action

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Edge function URL
EDGE_FUNCTION_URL="https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot"

echo -e "${YELLOW}Testing Supabase Edge Function: hubspot${NC}"
echo "URL: $EDGE_FUNCTION_URL"
echo ""

# Generate current timestamp in milliseconds
TIMESTAMP=$(date +%s000)

# Test payload - matches what extension sends
TEST_PAYLOAD=$(cat <<EOF
{
  "action": "createNote",
  "data": {
    "contactId": 646496038119,
    "body": "Test note from script - $(date)",
    "note": "Test note from script - $(date)",
    "noteBody": "Test note from script - $(date)",
    "timestamp": $TIMESTAMP,
    "createTodo": false
  }
}
EOF
)

echo -e "${YELLOW}Sending test request...${NC}"
echo "Payload:"
echo "$TEST_PAYLOAD" | jq '.' 2>/dev/null || echo "$TEST_PAYLOAD"
echo ""

# Make the request
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$EDGE_FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "$TEST_PAYLOAD")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
# Extract response body (all but last line)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

echo -e "${YELLOW}Response:${NC}"
echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 200 ]; then
  echo -e "${GREEN}✅ Success!${NC}"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
elif [ "$HTTP_CODE" -eq 400 ]; then
  echo -e "${RED}❌ Bad Request (400)${NC}"
  echo "This usually means:"
  echo "  - Missing required fields"
  echo "  - Invalid field names"
  echo "  - Validation failed"
  echo ""
  echo "Response:"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
elif [ "$HTTP_CODE" -eq 500 ]; then
  echo -e "${RED}❌ Server Error (500)${NC}"
  echo "This usually means:"
  echo "  - HubSpot token not configured"
  echo "  - HubSpot API error"
  echo "  - Edge function error"
  echo ""
  echo "Response:"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
  echo -e "${RED}❌ Unexpected Status: $HTTP_CODE${NC}"
  echo "Response:"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
fi

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Check Supabase Dashboard → Edge Functions → hubspot → Logs"
echo "2. Verify the function code matches EDGE_FUNCTION_TEMPLATE.md"
echo "3. Check HUBSPOT_ACCESS_TOKEN is set in Supabase secrets"
echo "4. Review EDGE_FUNCTION_ACCESS_GUIDE.md for more help"
