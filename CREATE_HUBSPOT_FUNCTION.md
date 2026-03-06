# Create HubSpot Edge Function - Step by Step Guide

Since the `hubspot` function doesn't exist yet, follow these steps to create it:

## Method 1: Using Supabase Dashboard Editor (Recommended)

### Step 1: Click "Deploy a new function"
In the Supabase Edge Functions dashboard, click the green **"Deploy a new function"** button (top right).

### Step 2: Choose "Via Editor"
Click on **"Via Editor"** option (first option in the "DEPLOY YOUR FIRST EDGE FUNCTION" section).

### Step 3: Name Your Function
When prompted, name your function: **`hubspot`** (all lowercase, no spaces)

### Step 4: Copy the Code
Copy and paste the complete code below into the editor:

```typescript
Deno.serve(async (req) => {
  try {
    const { action, data } = await req.json();
    
    console.log('Received request:', { action, data: data ? 'present' : 'missing' });
    
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
    
    // Handle other actions if needed (createContact, getContacts, etc.)
    // Add them here following the same pattern
    
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

### Step 5: Deploy
1. Click **"Deploy"** button in the editor
2. Wait for deployment to complete (usually takes 10-30 seconds)
3. You should see a success message

### Step 6: Set Environment Variable (IMPORTANT!)
The function needs your HubSpot access token:

1. In the left sidebar, click **"Secrets"** (under MANAGE section)
2. Click **"New secret"** or **"Add secret"**
3. Enter:
   - **Name:** `HUBSPOT_ACCESS_TOKEN`
   - **Value:** Your actual HubSpot access token
4. Click **"Save"**

**Note:** If you don't have a HubSpot access token yet, you'll need to create one in your HubSpot account first.

---

## Method 2: Using Supabase CLI

If you prefer using the CLI:

### Step 1: Install Supabase CLI (if not already installed)
```bash
npm install -g supabase
# OR
brew install supabase/tap/supabase
```

### Step 2: Login to Supabase
```bash
supabase login
```

### Step 3: Create Function Directory Structure
```bash
cd /Users/akhilaanil/Downloads/dev/Extension
mkdir -p supabase/functions/hubspot
```

### Step 4: Create Function File
Create `supabase/functions/hubspot/index.ts` with the code from Step 4 above.

### Step 5: Link to Your Project
```bash
supabase link --project-ref dizxmubrpwwfrjepcttb
```

### Step 6: Deploy Function
```bash
supabase functions deploy hubspot
```

### Step 7: Set Secret
```bash
supabase secrets set HUBSPOT_ACCESS_TOKEN=your_token_here
```

---

## Verify the Function is Working

### Option 1: Check Dashboard
1. Go back to **Edge Functions** in the dashboard
2. You should now see `hubspot` in the list
3. Click on it to view code, logs, etc.

### Option 2: Test with curl
```bash
cd /Users/akhilaanil/Downloads/dev/Extension
./test-edge-function.sh
```

### Option 3: Test in Browser Extension
1. Open your extension
2. Try creating a note
3. Check browser console for `[Background]` logs
4. Check Supabase Dashboard → Edge Functions → hubspot → Logs for function logs

---

## Troubleshooting

### Function not appearing after deployment
- Wait a few seconds and refresh the page
- Check if deployment completed successfully
- Look for error messages in the editor

### "HubSpot access token not configured" error
- Go to **Secrets** in Supabase Dashboard
- Verify `HUBSPOT_ACCESS_TOKEN` is set correctly
- Make sure the secret name is exactly `HUBSPOT_ACCESS_TOKEN` (case-sensitive)

### "Missing required field" errors
- Check the function logs in Supabase Dashboard
- Verify your extension is sending the correct data format (see `NOTE_SAVING_DEBUG.md`)

---

## Next Steps

Once the function is created and deployed:

1. ✅ Verify it appears in the Edge Functions list
2. ✅ Set the `HUBSPOT_ACCESS_TOKEN` secret
3. ✅ Test using `./test-edge-function.sh`
4. ✅ Try creating a note in your extension
5. ✅ Check logs if there are any issues

See `EDGE_FUNCTION_ACCESS_GUIDE.md` for more detailed management instructions.
