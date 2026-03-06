# Test createNote After Update

## ✅ Edge Function Updated

The edge function now accepts both formats:
- ✅ **CRM v3 Notes API format** → Uses `/crm/v3/objects/notes`
- ✅ **Extension format** → Uses `/engagements/v1/engagements`

## Test 1: Using Test Script

Run the test script:

```bash
cd /Users/akhilaanil/Downloads/dev/Extension
./test-edge-function.sh
```

This will test the extension format (contactId + body + timestamp).

## Test 2: Manual curl Test (Extension Format)

Test the format your extension uses:

```bash
curl -X POST https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot \
  -H "Content-Type: application/json" \
  -d '{
    "action": "createNote",
    "data": {
      "contactId": 650186289345,
      "body": "Test note from extension format",
      "timestamp": '$(date +%s000)'
    }
  }'
```

**Expected response:**
- Status: 200
- Response: `{"success": true, "data": {...}}`

## Test 3: Test in Extension

1. **Open your extension**
2. **Select a contact** (one that exists in HubSpot)
3. **Click "Note" button** to create a note
4. **Type a note** and click "Create note"
5. **Check browser console** (F12 → Console tab)

Look for:
- `[Background] ✅ HubSpot note created successfully!`
- No error messages

## Test 4: Verify in HubSpot

1. **Go to HubSpot** → Contacts
2. **Find the contact** you created a note for
3. **Check the contact timeline/notes**
4. **Verify the note appears**

## What to Look For

### ✅ Success Indicators

**In Browser Console:**
```
[Background] ===== CALLING EDGE FUNCTION =====
[Background] Action: createNote
[Background] ✅ Edge function call successful!
[Background] ✅ HubSpot note created successfully!
```

**In Network Tab:**
- Request to: `dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot`
- Status: 200
- Response: `{"success": true, ...}`

**In HubSpot:**
- Note appears in contact timeline
- Note has correct content
- Note has correct timestamp

### ❌ Error Indicators

If you see errors:

**"Missing required field: contactId"**
- Contact ID not being passed correctly
- Check `background.js` line 281

**"Missing required field: note text"**
- Note text is empty
- Check `content.js` note extraction

**"Missing required field: timestamp"**
- Timestamp not generated
- Check `background.js` line 258

**"HubSpot API error: ..."**
- Check edge function logs in Supabase Dashboard
- Verify `HUBSPOT_ACCESS_TOKEN` is set
- Check token hasn't expired

## Debugging Steps

### Step 1: Check Extension Sends Correct Data

Open browser console when creating a note. Look for:
```
[Background] ===== REQUEST DATA FOR EDGE FUNCTION =====
[Background] Contact ID: 650186289345
[Background] Note text (body): "Your note text here"
[Background] Timestamp: 1768744246658
```

### Step 2: Check Edge Function Receives Data

Check Supabase Dashboard → Edge Functions → hubspot → Logs

Look for:
```
Received createNote request: { contactId: ..., body: ..., timestamp: ... }
Using Engagements API format (extension format)
✅ All validations passed
HubSpot payload: { engagement: { ... } }
```

### Step 3: Check HubSpot API Response

In edge function logs, look for:
```
HubSpot response status: 200
✅ Note created successfully
```

## Common Issues & Fixes

### Issue: "Unknown action"
**Fix:** Make sure action is exactly `"createNote"` (case-sensitive)

### Issue: Note created but doesn't appear in HubSpot
**Check:**
- Contact ID is correct (numeric)
- Contact exists in HubSpot
- Token has permissions to create notes

### Issue: "HubSpot API error: 401"
**Fix:** 
- Token expired or invalid
- Update `HUBSPOT_ACCESS_TOKEN` in Supabase secrets

### Issue: "HubSpot API error: 400"
**Check:**
- Contact ID format (should be number, not string)
- Note text is not empty
- Timestamp is in milliseconds

## Quick Verification Checklist

- [ ] Edge function updated with both format handlers
- [ ] `HUBSPOT_ACCESS_TOKEN` secret is set in Supabase
- [ ] Test script runs successfully
- [ ] Creating note in extension works
- [ ] Note appears in HubSpot contact timeline
- [ ] No errors in browser console
- [ ] No errors in edge function logs

## Next Steps After Testing

If all tests pass ✅:
- Note creation is working correctly!
- The format compatibility is working

If tests fail ❌:
- Check the specific error message
- Refer to debugging steps above
- Check edge function logs in Supabase Dashboard
