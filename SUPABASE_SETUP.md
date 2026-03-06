# Supabase Email Confirmation Setup

## Problem
Supabase is sending email confirmation links with `localhost:3000` as the redirect URL, which doesn't work.

## Solution Options

### Option 1: Configure Redirect URL in Supabase Dashboard (Recommended)

1. Go to your Supabase project: https://cxzeixolbajmgyzedylt.supabase.co
2. Navigate to **Authentication** > **URL Configuration**
3. Add your redirect URLs to the **Redirect URLs** list:
   - `https://cxzeixolbajmgyzedylt.supabase.co/auth/v1/callback`
   - Or create a simple HTML page and use that URL
4. Update `config.js` with your chosen redirect URL

### Option 2: Disable Email Confirmation (For Development)

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Providers** > **Email**
3. Toggle off **"Confirm email"** (for development/testing only)
4. Users will be able to login immediately without email confirmation

### Option 3: Create a Simple Redirect Page

Create a simple HTML page that handles the redirect and shows a success message:

1. Host a simple HTML page (can be on GitHub Pages, Netlify, or any web hosting)
2. The page should extract the access token from the URL hash
3. Show a success message like "Email confirmed! You can now close this window and login."
4. Update `config.js` with your redirect page URL

### Option 4: Use Supabase's Default Callback URL

The code is now configured to use Supabase's default callback URL:
`https://cxzeixolbajmgyzedylt.supabase.co/auth/v1/callback`

Make sure this URL is added to your Supabase **Redirect URLs** list in the dashboard.

## Current Configuration

The extension is configured to use the redirect URL specified in `config.js`. 
Update the `redirectUrl` in `config.js` to match your chosen solution.
