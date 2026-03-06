# How to Disable Email Confirmation in Supabase

## The Toggle is NOT on the Template Page

The page you're currently on (Confirm sign up template) is just for editing the email content. 
The toggle to disable email confirmation is in a different location.

## Steps to Disable Email Confirmation:

### Step 1: Go to Email Provider Settings

1. **Click "Authentication" in the left sidebar** (you should already be there)
2. **Click "Sign In / Providers"** (or just **"Providers"** if you see it)
   - This is different from the "Emails" section you were in
3. **Find "Email" in the list of providers**
   - It should show as a provider option (like Google, GitHub, etc.)
4. **Click on "Email"** to open its settings

### Step 2: Find the Toggle

Once you're in the Email provider settings, look for:
- A toggle/switch labeled **"Enable email confirmations"**
- Or **"Confirm email"** 
- Or **"Require email verification"**
- It might be under a section like "Email Settings" or "Configuration"

### Step 3: Disable and Save

- **Turn the toggle OFF**
- Click **"Save"** or **"Update"**

## Alternative: Check Authentication Settings

If you don't see it in Providers:

1. Go to **Authentication > Settings** (if available)
2. Look for **"Email"** or **"Email Auth"** section
3. Find the email confirmation toggle there

## Visual Guide:

```
Left Sidebar Navigation:
├── Authentication
    ├── Users
    ├── OAuth Apps
    ├── Emails (where you were - just templates)
    ├── Sign In / Providers ← GO HERE
    │   └── Email ← Click this
    │       └── [Toggle: Enable email confirmations] ← Find this
    ├── URL Configuration
    └── ...
```

## After Disabling:

- New signups will NOT require email confirmation
- Users can login immediately after creating an account
- No confirmation emails will be sent

---

**Note:** The template page you were on is just for customizing the email content IF email confirmation is enabled. 
You need to go to the Provider settings to actually disable the feature.
