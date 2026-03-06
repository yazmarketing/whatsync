# How to Update the Supabase Edge Function

## Where is the Edge Function?

The edge function is deployed on Supabase and is accessible at:
```
https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot
```

## Where to Find/Update the Code:

### Option 1: Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard:**
   - Visit: https://supabase.com/dashboard
   - Login to your account
   - Select your project: `dizxmubrpwwfrjepcttb`

2. **Navigate to Edge Functions:**
   - In the left sidebar, click on **"Edge Functions"**
   - Find the function named **"hubspot"**
   - Click on it to view/edit the code

3. **Update the Code:**
   - Look for the `createNote` action handler
   - Replace it with the working code (see below)

### Option 2: Local Supabase Project

If you have a local Supabase project:

1. **Navigate to your Supabase project folder:**
   ```bash
   cd /path/to/your/supabase/project
   ```

2. **Find the edge function:**
   ```
   supabase/functions/hubspot/index.ts
   ```

3. **Edit the file:**
   - Open `supabase/functions/hubspot/index.ts`
   - Find the `createNote` handler
   - Update it with the working code

4. **Deploy:**
   ```bash
   supabase functions deploy hubspot
   ```

## Code to Update:

Find the section that handles `action === 'createNote'` and replace it with:

```typescript
if (action === 'createNote') {
  // Extract data - handles multiple field name options
  const { contactId, note, noteBody, body, timestamp } = data;
  
  // Pick the first non-empty value from multiple field name options
  const noteText = (note ?? noteBody ?? body)?.toString().trim();
  
  // Validate required fields
  if (!contactId || !timestamp || !noteText) {
    console.log('Validation failed:', {
      contactId: !!contactId,
      timestamp: !!timestamp,
      noteText: !!noteText,
      note: note,
      noteBody: noteBody,
      body: body
    });
    return new Response(
      JSON.stringify({ error: 'Missing required: contactId, timestamp, or note text' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }
  
  // Format payload for HubSpot Engagements API
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
      body: noteText   // Single canonical value
    }
  };
  
  console.log('Creating note with payload:', JSON.stringify(hubspotPayload, null, 2));
  
  // Get HubSpot access token from environment
  const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
  
  if (!hubspotToken) {
    return new Response(
      JSON.stringify({ error: 'HubSpot access token not configured' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
  
  try {
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
    return new Response(
      JSON.stringify({ success: true, data: result }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Error calling HubSpot API:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}
```

## What This Code Does:

1. **Handles Multiple Field Names:**
   - Accepts `note`, `noteBody`, or `body`
   - Uses the first non-empty value: `(note ?? noteBody ?? body)?.toString().trim()`

2. **Validates Required Fields:**
   - Checks for `contactId`, `timestamp`, and `noteText`
   - Logs validation details for debugging

3. **Formats for HubSpot:**
   - Creates the correct payload structure
   - Uses Engagements API format

4. **Calls HubSpot API:**
   - Sends properly formatted request
   - Handles errors appropriately

## After Updating:

1. **Save the changes** in Supabase Dashboard
2. **The function will auto-deploy** (or deploy manually if using CLI)
3. **Test by clicking "Create note"** in the extension
4. **Check the console logs** to verify it's working

## Verification:

After updating, when you create a note, you should see in the console:
- ✅ `[Background] ✅ Edge function response received`
- ✅ `[Content] ✅ Note created successfully!`
- ✅ Modal closes automatically

If you still see errors, check the Supabase function logs in the dashboard for detailed error messages.
