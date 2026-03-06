-- Migration script to remove username column from existing user_profiles table
-- Run this in your Supabase SQL Editor if you've already created the table

-- Drop the index on username first
DROP INDEX IF EXISTS idx_user_profiles_username;

-- Remove the username column
ALTER TABLE user_profiles DROP COLUMN IF EXISTS username;
