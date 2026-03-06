# Fix: User Already Registered But No Profile in Table

## Problem
You're getting "User already registered" error, but the `user_profiles` table is empty. This means:
- The user exists in Supabase Auth (`auth.users` table)
- But the profile wasn't created in `user_profiles` table

## Solutions

### Solution 1: Delete the User and Sign Up Again (Easiest)

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project

2. **Go to Authentication > Users**
   - In the left sidebar, click **"Authentication"**
   - Click **"Users"**

3. **Find and Delete the User**
   - Find the user with email: `akhila.a@yazmedia.com`
   - Click on the user
   - Click **"Delete user"** or the trash icon
   - Confirm deletion

4. **Try Signing Up Again**
   - Now try creating the account again from the extension
   - The profile should be created this time

### Solution 2: Manually Create the Profile

1. **Get the User ID**
   - Go to **Authentication > Users**
   - Find the user and copy their **User ID** (UUID)

2. **Go to Table Editor**
   - Go to **Table Editor** in left sidebar
   - Select **`user_profiles`** table

3. **Insert Row Manually**
   - Click **"Insert"** button
   - Fill in:
     - `user_id`: (paste the User ID from step 1)
     - `first_name`: "Akhila"
     - `last_name`: "Anil"
     - `email`: "akhila.a@yazmedia.com"
   - Click **"Save"**

### Solution 3: Just Login Instead

If the user exists in Auth, you can just login:
1. Use the **"Log In"** form instead of signup
2. Enter email and password
3. The profile will be created automatically on first login (if we add that logic)

### Solution 4: Use SQL to Create Profile

1. **Go to SQL Editor** in Supabase
2. **Run this query** (replace the user_id with the actual one):

```sql
-- First, get the user_id
SELECT id, email FROM auth.users WHERE email = 'akhila.a@yazmedia.com';

-- Then insert the profile (replace USER_ID_HERE with the actual ID)
INSERT INTO user_profiles (user_id, first_name, last_name, email)
VALUES ('USER_ID_HERE', 'Akhila', 'Anil', 'akhila.a@yazmedia.com');
```

## Why This Happened

The profile creation might have failed because:
- RLS (Row Level Security) policy issue
- Network error during profile creation
- User was created but browser closed before profile was saved

## Prevention

The code has been updated to:
- Better handle "already registered" errors
- Automatically switch to login mode if user exists
- Pre-fill the email in login form
- Show clearer error messages
