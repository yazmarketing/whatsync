# Add createNote Action to Existing HubSpot Edge Function

## Status Confirmed ✅

- ✅ Edge function EXISTS: `https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot`
- ✅ `createContact` action works
- ❌ `createNote` action needs to be added

## Method 1: Using Supabase CLI (Recommended)

### Step 1: Install Supabase CLI (if not installed)
```bash
npm install -g supabase
# OR
brew install supabase/tap/supabase
```

### Step 2: Login to Supabase
```bash
supabase login
```

### Step 3: Link to Your Project
```bash
cd /Users/akhilaanil/Downloads/dev/Extension
supabase link --project-ref dizxmubrpwwfrjepcttb
```

### Step 4: Download Existing Function
```bash
supabase functions download hubspot
```

This creates: `supabase/functions/hubspot/index.ts`

### Step 5: Edit the Function File
Open `supabase/functions/hubspot/index.ts` and add the `createNote` handler.

**Find the section where `createContact` is handled** (look for `if (action === 'createContact')`), and add this AFTER it:

```typescript
if (action === 'createNote') {
  // Log received data for debugging
  console.log("Received createNote request:", JSON.stringify(data, null, 2));
  
  // Extract fields with fallback - handles multiple field name options
  const { contactId, note, noteBody, body, timestamp } = data || {};
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
  
  // Build HubSpot Engagements API payload
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
  
  // Call HubSpot Engagements API
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
```

### Step 6: Deploy Updated Function
```bash
supabase functions deploy hubspot
```

### Step 7: Verify Deployment
```bash
# Test the function
./test-edge-function.sh
```

---

## Method 2: Via Supabase Dashboard (If Function Becomes Visible)

If the function becomes visible in the dashboard:

1. Go to **Edge Functions** → **hubspot** → **Code** tab
2. Find where `createContact` is handled
3. Add the `createNote` handler code (same as above)
4. Click **Deploy**

---

## Method 3: Direct API Edit (If Available)

Some Supabase projects allow editing via API or other methods. Check Supabase documentation for your project setup.

---

## Verify It Works

After adding the handler:

1. **Test with script:**
   ```bash
   ./test-edge-function.sh
   ```

2. **Test in extension:**
   - Try creating a note in your extension
   - Check browser console for `[Background]` logs
   - Should see success response

3. **Check HubSpot:**
   - Go to the contact in HubSpot
   - Verify the note was created

---

## Important Notes

- The function already exists and works for `createContact`
- We're just adding another action handler (`createNote`)
- Make sure `HUBSPOT_ACCESS_TOKEN` secret is set (same token used for `createContact`)
- The `createNote` handler uses the same HubSpot token from environment

---

## Troubleshooting

### "Function not found" when downloading
- Verify project ID: `dizxmubrpwwfrjepcttb`
- Check you're logged into correct Supabase account
- Try: `supabase functions list --project-ref dizxmubrpwwfrjepcttb`

### "Permission denied" when deploying
- Ensure you have deploy permissions for the project
- Check you're using the correct account

### Function still not working after deploy
- Check Supabase Dashboard → Edge Functions → hubspot → Logs
- Look for errors related to `createNote`
- Verify the code was saved correctly
