# WhatsApp Web Chrome Extension

A Chrome extension that only works on `https://web.whatsapp.com/` with Supabase authentication.

## Features

- Only activates on `web.whatsapp.com` domain
- Content script runs automatically when on WhatsApp Web
- Login/Signup interface with Supabase Auth
- User profile management with Supabase database
- Secure authentication and user data storage

## Setup Instructions

### 1. Supabase Setup

1. Go to your Supabase project: https://cxzeixolbajmgyzedylt.supabase.co
2. Navigate to **Project Settings** > **API**
3. Copy your **anon/public** key
4. Open `config.js` in this extension folder
5. Replace `YOUR_SUPABASE_ANON_KEY_HERE` with your actual anon key

### 2. Create Database Table

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `create_table.sql`
4. Run the SQL script to create the `user_profiles` table

### 3. Extension Installation

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" (toggle in the top right)
3. Click "Load unpacked"
4. Select this extension folder
5. The extension will now be active

## Usage

- The extension automatically runs when you visit `web.whatsapp.com`
- Click the extension icon to open the login/signup popup
- **Sign Up**: Create a new account with email, username, first name, last name, and password
- **Log In**: Sign in with your email and password
- User profiles are automatically saved to Supabase database
- Check the browser console (F12) to see extension logs

## Customization

Edit `content.js` to add your custom functionality for WhatsApp Web.

## File Structure

```
Extension/
├── manifest.json      # Extension configuration
├── config.js          # Supabase configuration (add your anon key here)
├── content.js         # Script that runs on web.whatsapp.com
├── popup.html         # Extension popup UI (login/signup form)
├── popup.js           # Popup script with Supabase Auth integration
├── create_table.sql   # SQL script to create user_profiles table
└── README.md          # This file
```

## Database Schema

The `user_profiles` table stores:
- `id` - UUID primary key
- `user_id` - References Supabase Auth user (unique)
- `username` - Unique username
- `first_name` - User's first name
- `last_name` - User's last name
- `email` - User's email
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp

## Notes

- This extension uses Manifest V3 (latest Chrome extension standard)
- The content script only runs on `https://web.whatsapp.com/*`
- Supabase Auth is used for authentication
- User profiles are stored in a separate `user_profiles` table
- Row Level Security (RLS) is enabled - users can only access their own profile
- Make sure to set your Supabase anon key in `config.js` before using the extension
