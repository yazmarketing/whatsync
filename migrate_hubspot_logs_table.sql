-- Migration script to update hubspot_contact_logs table to new schema
-- This script will alter the existing table to match the new schema structure

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own logs" ON public.hubspot_contact_logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON public.hubspot_contact_logs;
DROP POLICY IF EXISTS "Users can update own logs" ON public.hubspot_contact_logs;

-- Drop old indexes that might reference old columns
DROP INDEX IF EXISTS public.idx_hubspot_logs_user_id;
DROP INDEX IF EXISTS public.idx_hubspot_logs_created_at;
DROP INDEX IF EXISTS public.idx_hubspot_logs_contact_id;
DROP INDEX IF EXISTS public.idx_hubspot_logs_phone;
DROP INDEX IF EXISTS public.idx_hubspot_contact_logs_user_id;
DROP INDEX IF EXISTS public.idx_hubspot_contact_logs_created_at;
DROP INDEX IF EXISTS public.idx_hubspot_contact_logs_activity_type;
DROP INDEX IF EXISTS public.idx_hubspot_contact_logs_object_id;

-- Drop trigger if it exists (for updated_at)
DROP TRIGGER IF EXISTS update_hubspot_logs_updated_at ON public.hubspot_contact_logs;

-- Add new columns if they don't exist
DO $$ 
BEGIN
    -- Add activity_type column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'hubspot_contact_logs' 
                   AND column_name = 'activity_type') THEN
        ALTER TABLE public.hubspot_contact_logs 
        ADD COLUMN activity_type TEXT NOT NULL DEFAULT 'contact_created';
    END IF;

    -- Add hubspot_object_id column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'hubspot_contact_logs' 
                   AND column_name = 'hubspot_object_id') THEN
        ALTER TABLE public.hubspot_contact_logs 
        ADD COLUMN hubspot_object_id TEXT;
    END IF;

    -- Add hubspot_object_type column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'hubspot_contact_logs' 
                   AND column_name = 'hubspot_object_type') THEN
        ALTER TABLE public.hubspot_contact_logs 
        ADD COLUMN hubspot_object_type TEXT;
    END IF;

    -- Add title column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'hubspot_contact_logs' 
                   AND column_name = 'title') THEN
        ALTER TABLE public.hubspot_contact_logs 
        ADD COLUMN title TEXT NOT NULL DEFAULT 'Contact created';
    END IF;

    -- Add description column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'hubspot_contact_logs' 
                   AND column_name = 'description') THEN
        ALTER TABLE public.hubspot_contact_logs 
        ADD COLUMN description TEXT;
    END IF;

    -- Add metadata column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'hubspot_contact_logs' 
                   AND column_name = 'metadata') THEN
        ALTER TABLE public.hubspot_contact_logs 
        ADD COLUMN metadata JSONB;
    END IF;
END $$;

-- Migrate data from old columns to new format (if old columns exist)
DO $$
BEGIN
    -- If hubspot_contact_id exists, migrate it to hubspot_object_id
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'hubspot_contact_logs' 
               AND column_name = 'hubspot_contact_id') THEN
        UPDATE public.hubspot_contact_logs
        SET 
            hubspot_object_id = COALESCE(hubspot_object_id, hubspot_contact_id),
            hubspot_object_type = COALESCE(hubspot_object_type, 'contact'),
            activity_type = COALESCE(activity_type, 'contact_created'),
            title = COALESCE(title, 'Contact created'),
            description = COALESCE(description, 
                CASE 
                    WHEN first_name IS NOT NULL OR last_name IS NOT NULL THEN
                        TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, ''))
                    WHEN email IS NOT NULL THEN email
                    WHEN phone_number IS NOT NULL THEN phone_number
                    ELSE NULL
                END
            ),
            metadata = jsonb_build_object(
                'phone_number', phone_number,
                'first_name', first_name,
                'last_name', last_name,
                'email', email,
                'company', company,
                'job_title', job_title
            )
        WHERE hubspot_object_id IS NULL OR metadata IS NULL;
    END IF;
END $$;

-- Remove old columns (optional - uncomment if you want to remove them)
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS hubspot_contact_id;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS phone_number;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS first_name;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS last_name;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS email;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS company;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS job_title;
-- ALTER TABLE public.hubspot_contact_logs DROP COLUMN IF EXISTS updated_at;

-- Recreate policies
CREATE POLICY "Users can view own logs"
  ON public.hubspot_contact_logs
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs"
  ON public.hubspot_contact_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own logs"
  ON public.hubspot_contact_logs
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_user_id ON public.hubspot_contact_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_created_at ON public.hubspot_contact_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_activity_type ON public.hubspot_contact_logs(activity_type);
CREATE INDEX IF NOT EXISTS idx_hubspot_contact_logs_object_id ON public.hubspot_contact_logs(hubspot_object_id);
