-- Migration: Add reported_by column to issue_reports table
-- Run this in Supabase SQL Editor
-- Date: March 10, 2026
-- Purpose: Store the reporter's name directly for easier display without joins

-- Step 1: Add reported_by column to issue_reports table (if it doesn't exist)
ALTER TABLE issue_reports ADD COLUMN IF NOT EXISTS reported_by TEXT;

-- Step 2: Update existing issue_reports to populate reported_by from worker's full_name
-- This ensures existing issues show the worker name instead of "Unknown"
UPDATE issue_reports ir
SET reported_by = w.full_name
FROM workers w
WHERE ir.worker_id = w.id
  AND ir.reported_by IS NULL;

-- Step 3: Create index for faster lookups (optional, but recommended)
CREATE INDEX IF NOT EXISTS idx_issue_reports_reported_by ON issue_reports(reported_by);

-- Step 4: Verify the update
SELECT
    ir.id,
    ir.issue_type,
    ir.reported_by,
    w.full_name as worker_name
FROM issue_reports ir
LEFT JOIN workers w ON ir.worker_id = w.id
ORDER BY ir.reported_at DESC
LIMIT 10;


