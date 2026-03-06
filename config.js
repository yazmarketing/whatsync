// Supabase Configuration
const SUPABASE_CONFIG = {
  url: 'https://cxzeixolbajmgyzedylt.supabase.co',
  // Replace with your Supabase anon/public key from Project Settings > API
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4emVpeG9sYmFqbWd5emVkeWx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0OTUxMTksImV4cCI6MjA4NDA3MTExOX0.zYzUmVLjM3Ml7z5EKjwjA9oE4ohnuqCbCV_4n1jgGBs',
  // Redirect URL after email confirmation - Update this to your actual redirect page
  // For Chrome extensions, you can use a simple web page or disable email confirmation
  redirectUrl: 'https://cxzeixolbajmgyzedylt.supabase.co/auth/v1/callback'
};

// HubSpot Configuration
const HUBSPOT_CONFIG = {
  // Supabase Functions Edge Function URL for HubSpot token
  // Token is fetched dynamically from the edge function in background.js
  edgeFunctionUrl: 'https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot',
  apiUrl: 'https://api.hubapi.com'
};

// Session Configuration (automatic logout after prolonged inactivity)
const SESSION_CONFIG = {
  // Max session duration from last login. After this period, user is auto-logged out.
  timeoutMs: 6 * 60 * 60 * 1000, // 6 hours
  // How often background script checks for session expiration (alarm interval)
  checkIntervalMs: 5 * 60 * 1000 // 5 minutes
};
