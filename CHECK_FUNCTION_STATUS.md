# Check if HubSpot Edge Function Exists

## Quick Verification Steps

### Step 1: Verify You're in the Correct Project

The extension expects the function in project: **`dizxmubrpwwfrjepcttb`**

Check your current Supabase project:
- Look at the top-left of your dashboard
- It should show the project ID or name
- If it's different, switch to the correct project

**To switch projects:**
1. Click on the project name at top-left
2. Select or search for project with ID `dizxmubrpwwfrjepcttb`

---

### Step 2: Test if Function Actually Exists

Even if you don't see it in the dashboard, let's test if it responds:

```bash
cd /Users/akhilaanil/Downloads/dev/Extension
./test-edge-function.sh
```

OR manually:

```bash
curl -X POST https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot \
  -H "Content-Type: application/json" \
  -d '{"action": "createContact", "data": {}}'
```

**Possible responses:**
- **200 or 400** = Function EXISTS (you're getting a response)
- **404** = Function DOES NOT EXIST
- **500** = Function exists but has an error

---

### Step 3: Check Browser Console Logs

If contact creation is working, check what's happening:

1. Open your extension
2. Open Browser DevTools (F12)
3. Go to Console tab
4. Try creating a contact
5. Look for `[Background]` logs
6. Check the URL being called

Look for lines like:
```
[Background] ===== CALLING EDGE FUNCTION =====
[Background] URL: https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot
```

---

### Step 4: Verify Contact Creation Actually Works

**Question:** When you try to create a contact in the extension, does it actually succeed?

- ✅ **If YES** → Function exists (just not visible in dashboard, or you're in wrong project)
- ❌ **If NO** → Function doesn't exist and needs to be created

---

## Possible Scenarios

### Scenario A: Function Exists But Not Visible

**Causes:**
1. Wrong Supabase project selected
2. View/filter issue in dashboard
3. Function exists but dashboard isn't refreshing

**Solution:**
1. Verify project ID matches `dizxmubrpwwfrjepcttb`
2. Refresh the Edge Functions page
3. Try searching for "hubspot" in the dashboard search

### Scenario B: Function Doesn't Exist Yet

**Causes:**
1. Function was never created
2. Function was deleted
3. Contact creation is using a different endpoint

**Solution:**
Follow `CREATE_HUBSPOT_FUNCTION.md` to create it

### Scenario C: Different Project/Organization

**Causes:**
1. Multiple Supabase accounts
2. Function is in a different organization

**Solution:**
1. Check all your Supabase projects
2. Look for project ID `dizxmubrpwwfrjepcttb`
3. Verify you have access to it

---

## What to Do Next

### If Function Doesn't Exist (404 error or contact creation fails):

1. **Create the function** using `CREATE_HUBSPOT_FUNCTION.md`
2. The function needs to handle:
   - `createContact` (already working if contacts are created)
   - `getContacts` (for contact search)
   - `getContact` (for single contact)
   - `getCompany` (for company info)
   - `createNote` (what we need to add)

### If Function Exists But Not Visible:

1. You're in the wrong project → Switch to correct project
2. Refresh dashboard → Hard refresh (Cmd+Shift+R)
3. Check different organization → Look in all your Supabase accounts

### If Contact Creation Works But Function Not Visible:

The function definitely exists. Try:
1. **Hard refresh** the Edge Functions page (Cmd+Shift+R or Ctrl+Shift+R)
2. **Check the Logs tab** - if logs exist, the function exists
3. **Search** for "hubspot" in the dashboard search bar
4. **Check all organizations** - might be in a different Supabase account

---

## Quick Test: Is Contact Creation Working?

To verify if the edge function is actually working:

1. Open your extension
2. Try to create a contact with a phone number
3. Check browser console for errors
4. Check if contact appears in HubSpot

**If contact creation works → Function exists, just need to find it or refresh**
**If contact creation fails → Function doesn't exist, need to create it**

---

## Need to Create the Function?

If the function doesn't exist, you have two options:

### Option 1: Create from Scratch
Follow `CREATE_HUBSPOT_FUNCTION.md` - this will create a basic function with `createNote` support

### Option 2: If Contact Creation Works
The function exists somewhere. We need to:
1. Find it (check different projects/organizations)
2. Add `createNote` handler to existing function
3. Or locate the actual function code to see what's there
