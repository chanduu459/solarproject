-- Migration: Add location field to jobs table and fix trigger
-- Run this in Supabase SQL Editor to fix the image upload and timestamp issues
-- Date: March 9, 2026

-- Step 1: Add location column to jobs table (if it doesn't exist)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Step 2: Drop existing trigger
DROP TRIGGER IF EXISTS trigger_update_job_progress ON work_updates;

-- Step 3: Create/Replace function with proper started_at and completed_at logic
CREATE OR REPLACE FUNCTION update_job_progress()
RETURNS TRIGGER AS $$
DECLARE
    current_progress INTEGER;
    current_started_at TIMESTAMPTZ;
BEGIN
    -- Get current job data
    SELECT progress_percentage, started_at
    INTO current_progress, current_started_at
    FROM jobs WHERE id = NEW.job_id;

    UPDATE jobs
    SET progress_percentage = NEW.progress_percentage,
        status = CASE
            WHEN NEW.progress_percentage = 100 THEN 'completed'
            WHEN NEW.progress_percentage > 0 THEN 'in_progress'
            ELSE status
        END,
        -- Set started_at only on first update (when progress goes from 0 or NULL to > 0)
        started_at = CASE
            WHEN current_started_at IS NULL AND NEW.progress_percentage > 0 THEN NOW()
            ELSE started_at
        END,
        -- Set completed_at when reaching 100%
        completed_at = CASE
            WHEN NEW.progress_percentage = 100 AND current_progress < 100 THEN NOW()
            ELSE completed_at
        END,
        -- Update location data if provided (keep existing if NULL)
        latitude = COALESCE(NEW.latitude, latitude),
        longitude = COALESCE(NEW.longitude, longitude)
    WHERE id = NEW.job_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Recreate the trigger
CREATE TRIGGER trigger_update_job_progress
    AFTER INSERT OR UPDATE ON work_updates
    FOR EACH ROW
    EXECUTE FUNCTION update_job_progress();

-- Step 5: Verification queries (run these to confirm changes worked)
-- Check that columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'jobs'
AND column_name IN ('latitude', 'longitude', 'location');

-- Check that trigger exists
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgname = 'trigger_update_job_progress';

