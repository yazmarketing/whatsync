# Integration Check Update

## Summary

Updated the integration check to use the edge function's `getConnectionStatus` action instead of relying on shared HubSpot tokens or legacy database tables.

## Changes Made

### 1. Content Script (`content.js`)

**Added:** `checkHubSpotIntegrationStatus()` function
- Calls background script with action `checkHubSpotIntegration`
- Returns `true` only if response is `{status: 'active'}`

**Updated:** `checkLoginStateAndInjectNavbar()` function
- Now checks both login state AND integration status
- Only injects navbar if user is logged in AND integration status is 'active'
- If integration is not active, removes navbar

### 2. Background Script (`background.js`)

**Added:** Message handler for `checkHubSpotIntegration` action
- Handles integration status check requests from content script

**Added:** `checkHubSpotIntegrationStatusViaEdgeFunction()` function
- Calls edge function with action `getConnectionStatus`
- Returns the status response

## How It Works

1. **User logs in** → `userLoggedIn` is set to `true` in storage
2. **Navbar check triggered** → `checkLoginStateAndInjectNavbar()` is called
3. **Integration status checked** → Calls edge function with `getConnectionStatus` action
4. **Edge function response** → Should return `{status: 'active'}` or similar
5. **Navbar shown/hidden** → Only if `status === 'active'`

## Edge Function Requirements

The edge function must handle the `getConnectionStatus` action and return:

```javascript
{
  status: 'active'  // or 'inactive', 'error', etc.
}
```

**Example edge function handler:**

```typescript
if (action === 'getConnectionStatus') {
  // Check if HubSpot integration is active
  // This could check:
  // - User has valid HubSpot token
  // - Token hasn't expired
  // - Connection is healthy
  
  const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
  const isActive = !!hubspotToken; // Or more complex logic
  
  return new Response(
    JSON.stringify({ status: isActive ? 'active' : 'inactive' }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  );
}
```

## Benefits

✅ **No shared token dependency** - Integration check doesn't rely on shared HubSpot token  
✅ **No legacy table dependency** - Doesn't use `integration_settings` or `user_integrations` tables  
✅ **Centralized check** - All integration logic in edge function  
✅ **Flexible** - Can add more status checks in edge function (token expiry, connection health, etc.)

## Testing

### Test Integration Check

1. **User logged in + Integration active:**
   - Should show navbar ✅

2. **User logged in + Integration inactive:**
   - Should hide navbar ✅

3. **User logged out:**
   - Should hide navbar ✅

### Check Browser Console

When integration check runs, you should see:
```
[Background] Received HubSpot integration status check request
[Background] Checking HubSpot integration status via edge function
[Content] HubSpot integration not active, removing navbar  // (if inactive)
```

## Next Steps

1. **Update edge function** to handle `getConnectionStatus` action
2. **Test** the integration check flow
3. **Verify** navbar shows/hides based on integration status
