# Steps to Add createNote to Existing Edge Function

Since we can't download the function directly, here are your options:

## Option 1: Access via Supabase Dashboard (If Function Becomes Visible)

1. **Go to Supabase Dashboard**
   - Navigate to Edge Functions → `hubspot`

2. **Open Code Editor**
   - Click on `hubspot` function
   - Go to **Code** tab

3. **Find `createContact` Handler**
   - Look for `if (action === 'createContact')`

4. **Add `createNote` Handler**
   - Copy the `createNote` handler from `hubspot-edge-function.ts` (lines 58-146)
   - Paste it AFTER the `createContact` handler (before `getContacts` if it exists)

5. **Deploy**
   - Click **Deploy** button
   - Wait for deployment

## Option 2: Use Complete Function Code

I've created a complete function file: `hubspot-edge-function.ts`

This includes all handlers:
- ✅ `createContact` (already working)
- ✅ `createNote` (NEW - what we're adding)
- ✅ `getContacts` (for contact search)
- ✅ `getContact` (single contact)
- ✅ `getCompany` (company info)

**To use this:**

1. **Copy the entire code** from `hubspot-edge-function.ts`

2. **In Supabase Dashboard:**
   - Go to Edge Functions → `hubspot` → Code
   - **Replace all existing code** with the code from `hubspot-edge-function.ts`
   - Click **Deploy**

3. **Verify HUBSPOT_ACCESS_TOKEN Secret:**
   - Go to **Secrets** in left sidebar
   - Ensure `HUBSPOT_ACCESS_TOKEN` is set
   - If not, add it with your HubSpot token

## Option 3: Test First (Recommended)

Before deploying, test that the `createNote` handler works:

1. **Deploy the updated function**

2. **Test using the test script:**
   ```bash
   ./test-edge-function.sh
   ```

3. **Or test manually with curl:**
   ```bash
   curl -X POST https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot \
     -H "Content-Type: application/json" \
     -d '{
       "action": "createNote",
       "data": {
         "contactId": 650186289345,
         "body": "Test note",
         "timestamp": '$(date +%s000)'
       }
     }'
   ```

## Verification Checklist

After deploying:

- [ ] Function deployed successfully
- [ ] `HUBSPOT_ACCESS_TOKEN` secret is set
- [ ] Test script runs without errors
- [ ] Try creating a note in your extension
- [ ] Check browser console for `[Background]` logs
- [ ] Verify note appears in HubSpot

## If You Can't Access Function in Dashboard

If the function still doesn't appear in the dashboard:

1. **Check you're in the correct project:**
   - Project ID should be: `dizxmubrpwwfrjepcttb`

2. **Try different browser/incognito**

3. **Contact Supabase support** if you have access issues

4. **Alternative:** Use Supabase CLI with proper permissions:
   ```bash
   supabase login
   supabase link --project-ref dizxmubrpwwfrjepcttb
   # Then you might need to request proper permissions
   ```

## What the createNote Handler Does

The `createNote` handler:
1. ✅ Accepts `contactId`, `body`/`note`/`noteBody`, `timestamp`
2. ✅ Validates all required fields
3. ✅ Formats data for HubSpot Engagements API
4. ✅ Calls HubSpot API to create note
5. ✅ Returns success/error response

This matches exactly what your extension sends (see `background.js` lines 272-283).

## Need Help?

If you encounter issues:
- Check `hubspot-edge-function.ts` for the complete code
- See `NOTE_SAVING_DEBUG.md` for debugging tips
- Check Supabase Dashboard → Edge Functions → hubspot → Logs for errors
