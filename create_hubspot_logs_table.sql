-- Create table for logging HubSpot activities
-- This table stores logs of all HubSpot activities performed through the extension

CREATE TABLE IF NOT EXISTS public.hubspot_contact_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,  -- The logged-in user who performed the action
  activity_type TEXT NOT NULL,  -- 'contact_created', 'deal_created', 'ticket_created', 'note_created'
  hubspot_object_id TEXT,  -- HubSpot record ID
  hubspot_object_type TEXT,  -- 'contact', 'deal', 'ticket', 'note'
  title TEXT NOT NULL,  -- Display title (e.g., "Contact created")
  description TEXT,  -- Details (e.g., "John Doe • john@email.com")
  metadata JSONB,  -- Optional: store raw HubSpot data
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.hubspot_contact_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to allow re-running this script)
DROP POLICY IF EXISTS "Users can view own logs" ON public.hubspot_contact_logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON public.hubspot_contact_logs;
DROP POLICY IF EXISTS "Users can update own logs" ON public.hubspot_contact_logs;

-- Create policy to allow users to view their own logs
CREATE POLICY "Users can view own logs"
  ON public.hubspot_contact_logs
  FOR SELECT
  USING (auth.uid() = user_id);

-- Create policy to allow users to insert their own logs
CREATE POLICY "Users can insert own logs"
  ON public.hubspot_contact_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to update their own logs (if needed)
CREATE POLICY "Users can update own logs"
  ON public.hubspot_contact_logs
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Index for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_user_id ON public.hubspot_contact_logs(user_id);

-- Index for time-based queries
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_created_at ON public.hubspot_contact_logs(created_at DESC);

-- Index for activity type queries
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_activity_type ON public.hubspot_contact_logs(activity_type);

-- Index for hubspot object lookups
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_object_id ON public.hubspot_contact_logs(hubspot_object_id);
