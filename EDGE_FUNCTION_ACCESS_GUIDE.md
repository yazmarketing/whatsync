# Edge Function Access & Management Guide

## Quick Reference

**Edge Function URL:** `https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot`  
**Supabase Project ID:** `dizxmubrpwwfrjepcttb`  
**Function Name:** `hubspot`

---

## Method 1: Supabase Dashboard (Easiest)

### Step 1: Access Dashboard
1. Go to https://supabase.com/dashboard
2. Sign in with your account
3. Select the project with ID: `dizxmubrpwwfrjepcttb`

### Step 2: Navigate to Edge Functions
1. In the left sidebar, click **"Edge Functions"**
2. You should see a list of functions including `hubspot`
3. Click on `hubspot` to view details

### Step 3: View Function Code
1. Click on the function name
2. You'll see tabs: **"Code"**, **"Logs"**, **"Settings"**
3. Click **"Code"** to view/edit the current implementation

### Step 4: View Logs (Important for Debugging)
1. Click **"Logs"** tab
2. Filter by time range or search for specific errors
3. Look for entries related to `createNote` action
4. Check for validation errors or missing field errors

### Step 5: Update Function Code
1. Click **"Code"** tab
2. Edit the code directly in the editor
3. Click **"Deploy"** to save changes
4. Wait for deployment to complete

---

## Method 2: Supabase CLI (For Local Development)

### Prerequisites
```bash
# Install Supabase CLI if not already installed
npm install -g supabase
# OR
brew install supabase/tap/supabase
```

### Step 1: Login to Supabase
```bash
supabase login
```

### Step 2: Link to Your Project
```bash
# Navigate to your project directory
cd /Users/akhilaanil/Downloads/dev/Extension

# Link to your Supabase project
supabase link --project-ref dizxmubrpwwfrjepcttb
```

### Step 3: Download Existing Function
```bash
# Download the hubspot function
supabase functions download hubspot
```

This will create: `supabase/functions/hubspot/index.ts`

### Step 4: Edit Function Locally
```bash
# Open the function file
code supabase/functions/hubspot/index.ts
# OR
nano supabase/functions/hubspot/index.ts
```

### Step 5: Test Locally
```bash
# Serve function locally for testing
supabase functions serve hubspot --no-verify-jwt

# In another terminal, test it:
curl -X POST http://localhost:54321/functions/v1/hubspot \
  -H "Content-Type: application/json" \
  -d '{
    "action": "createNote",
    "data": {
      "contactId": 123456,
      "body": "Test note",
      "timestamp": '$(date +%s000)'
    }
  }'
```

### Step 6: Deploy Updated Function
```bash
# Deploy the function
supabase functions deploy hubspot

# Or deploy with environment variables
supabase functions deploy hubspot --no-verify-jwt
```

---

## Method 3: Direct API Access (For Verification)

### Test the Edge Function Directly

```bash
# Test createNote action
curl -X POST https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot \
  -H "Content-Type: application/json" \
  -d '{
    "action": "createNote",
    "data": {
      "contactId": 646496038119,
      "body": "Test note from curl",
      "note": "Test note from curl",
      "noteBody": "Test note from curl",
      "timestamp": '$(date +%s000)',
      "createTodo": false
    }
  }'
```

### Expected Response (Success)
```json
{
  "success": true,
  "data": {
    "engagement": {
      "id": 123456,
      ...
    }
  }
}
```

### Expected Response (Error)
```json
{
  "error": "Missing required: contactId, timestamp, or note text"
}
```

---

## Verification Checklist

### ✅ Check 1: Function Structure
The function should have this structure:

```typescript
Deno.serve(async (req) => {
  const { action, data } = await req.json();
  
  if (action === 'createNote') {
    // ... implementation
  }
  
  return new Response(...);
});
```

### ✅ Check 2: Field Extraction
Should extract fields like this:

```typescript
const { contactId, note, noteBody, body, timestamp } = data;
const noteText = (note ?? noteBody ?? body)?.toString().trim();
```

**NOT:**
```typescript
// ❌ WRONG - Don't expect HubSpot payload structure
const { engagement, associations, metadata } = data;
```

### ✅ Check 3: Validation Logic
Should validate like this:

```typescript
if (!contactId || !timestamp || !noteText) {
  // Log what's missing
  console.log("Validation data:", JSON.stringify(data, null, 2));
  return new Response(
    JSON.stringify({ error: 'Missing required fields' }),
    { status: 400 }
  );
}
```

### ✅ Check 4: HubSpot Payload Building
Should build HubSpot payload internally:

```typescript
const hubspotPayload = {
  engagement: {
    active: true,
    type: "NOTE",
    timestamp: timestamp
  },
  associations: {
    contactIds: [contactId]
  },
  metadata: {
    body: noteText
  }
};
```

### ✅ Check 5: Environment Variables
Should have `HUBSPOT_ACCESS_TOKEN` set:
- In Supabase Dashboard: **Settings** → **Edge Functions** → **Secrets**
- Or via CLI: `supabase secrets set HUBSPOT_ACCESS_TOKEN=your_token`

---

## Common Issues & Fixes

### Issue: "Function not found"
**Solution:** 
- Verify project ID is correct: `dizxmubrpwwfrjepcttb`
- Check if function name is `hubspot` (lowercase)
- Ensure you're logged into the correct Supabase account

### Issue: "Missing required properties"
**Solution:**
- Check the function logs in Supabase Dashboard
- Verify the function extracts fields correctly (see Check 2)
- Ensure extension sends all required fields (see `NOTE_SAVING_DEBUG.md`)

### Issue: "HubSpot API error"
**Solution:**
- Verify `HUBSPOT_ACCESS_TOKEN` is set in Supabase secrets
- Check token hasn't expired
- Verify token has permissions to create notes

### Issue: "Cannot access function code"
**Solution:**
- Ensure you have admin/owner access to the Supabase project
- Check if you're using the correct Supabase account
- Contact project owner for access

---

## Quick Debugging Steps

### Step 1: Check Function Logs
1. Go to Supabase Dashboard
2. Navigate to **Edge Functions** → **hubspot** → **Logs**
3. Look for recent errors when creating notes
4. Check for validation errors or missing field errors

### Step 2: Test with curl
Use the curl command in Method 3 above to test the function directly and see the exact error.

### Step 3: Compare with Template
Compare your function code with `EDGE_FUNCTION_TEMPLATE.md` to ensure it matches the expected structure.

### Step 4: Check Extension Logs
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for `[Background]` logs when creating a note
4. Check what data is being sent to the edge function

---

## Recommended Function Implementation

Based on the template and extension requirements, your function should look like this:

```typescript
Deno.serve(async (req) => {
  try {
    const { action, data } = await req.json();
    
    if (action === 'createNote') {
      // Log received data for debugging
      console.log("Received createNote request:", JSON.stringify(data, null, 2));
      
      // Extract fields with fallback
      const { contactId, note, noteBody, body, timestamp } = data;
      const noteText = (note ?? noteBody ?? body)?.toString().trim();
      
      // Log extracted values
      console.log("Extracted values:", {
        contactId,
        note,
        noteBody,
        body,
        noteText,
        timestamp
      });
      
      // Validate required fields
      if (!contactId) {
        console.error("❌ Missing contactId");
        return new Response(
          JSON.stringify({ error: 'Missing required field: contactId' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!timestamp) {
        console.error("❌ Missing timestamp");
        return new Response(
          JSON.stringify({ error: 'Missing required field: timestamp' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!noteText) {
        console.error("❌ Missing note text. Checked:", { note, noteBody, body });
        return new Response(
          JSON.stringify({ error: 'Missing required field: note text (note, noteBody, or body)' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      console.log("✅ All validations passed");
      
      // Build HubSpot payload
      const hubspotPayload = {
        engagement: {
          active: true,
          type: "NOTE",
          timestamp: timestamp
        },
        associations: {
          contactIds: [contactId]
        },
        metadata: {
          body: noteText
        }
      };
      
      console.log("HubSpot payload:", JSON.stringify(hubspotPayload, null, 2));
      
      // Get HubSpot token from environment
      const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
      
      if (!hubspotToken) {
        console.error("❌ HubSpot token not configured");
        return new Response(
          JSON.stringify({ error: 'HubSpot access token not configured' }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      // Call HubSpot API
      const response = await fetch('https://api.hubapi.com/engagements/v1/engagements', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${hubspotToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(hubspotPayload)
      });
      
      const responseText = await response.text();
      console.log('HubSpot response status:', response.status);
      console.log('HubSpot response:', responseText);
      
      if (!response.ok) {
        console.error('HubSpot API Error:', responseText);
        return new Response(
          JSON.stringify({ error: `HubSpot API error: ${responseText}` }),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      const result = JSON.parse(responseText);
      console.log("✅ Note created successfully");
      return new Response(
        JSON.stringify({ success: true, data: result }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Handle other actions (createContact, getContacts, etc.)
    // ...
    
    return new Response(
      JSON.stringify({ error: 'Unknown action' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Edge function error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

---

## Next Steps

1. **Access the function** using Method 1 (Dashboard) or Method 2 (CLI)
2. **Verify the implementation** matches the checklist above
3. **Check the logs** for any recent errors
4. **Update if needed** using the recommended implementation above
5. **Test** using the curl command or by creating a note in the extension

---

## Need Help?

- **Supabase Docs:** https://supabase.com/docs/guides/functions
- **Edge Function Template:** See `EDGE_FUNCTION_TEMPLATE.md`
- **Debugging Guide:** See `NOTE_SAVING_DEBUG.md`
- **Extension Code:** See `background.js` (lines 199-363)
