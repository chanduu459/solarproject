-- Solar Installation Tracker Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Workers table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS workers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    phone TEXT UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('owner', 'worker')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- Jobs table
CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    worker_id UUID REFERENCES workers(id) ON DELETE SET NULL,
    panel_type TEXT NOT NULL,
    panel_quantity INTEGER NOT NULL DEFAULT 1,
    scheduled_date TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    estimated_cost DECIMAL(10, 2),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- Attendance table
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out_time TIMESTAMPTZ,
    check_in_latitude DECIMAL(10, 8),
    check_in_longitude DECIMAL(11, 8),
    check_out_latitude DECIMAL(10, 8),
    check_out_longitude DECIMAL(11, 8),
    check_in_address TEXT,
    check_out_address TEXT,
    status TEXT DEFAULT 'checked_in' CHECK (status IN ('checked_in', 'checked_out')),
    working_hours INTEGER,
    notes TEXT,
    UNIQUE(worker_id, job_id, check_in_time)
);

-- Work updates table (progress tracking)
CREATE TABLE IF NOT EXISTS work_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    progress_percentage INTEGER NOT NULL CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    notes TEXT,
    image_urls TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

-- Installation images table
CREATE TABLE IF NOT EXISTS installation_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    image_type TEXT NOT NULL CHECK (image_type IN ('before', 'during', 'after')),
    image_url TEXT NOT NULL,
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address TEXT,
    notes TEXT
);

-- Job completion table
CREATE TABLE IF NOT EXISTS job_completion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL UNIQUE REFERENCES jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    safety_confirmed BOOLEAN DEFAULT FALSE,
    safety_confirmed_at TIMESTAMPTZ,
    customer_signature_url TEXT,
    customer_name TEXT,
    signed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    final_latitude DECIMAL(10, 8),
    final_longitude DECIMAL(11, 8)
);

-- Issue reports table
CREATE TABLE IF NOT EXISTS issue_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    issue_type TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved')),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES workers(id),
    resolution_notes TEXT,
    image_urls TEXT[],
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

-- Daily reports table
CREATE TABLE IF NOT EXISTS daily_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    total_jobs INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    pending_jobs INTEGER DEFAULT 0,
    issues_reported INTEGER DEFAULT 0,
    total_hours_worked INTEGER DEFAULT 0,
    total_distance DECIMAL(10, 2),
    job_ids UUID[],
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(worker_id, report_date)
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_jobs_worker_id ON jobs(worker_id);
CREATE INDEX IF NOT EXISTS idx_jobs_customer_id ON jobs(customer_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled_date ON jobs(scheduled_date);

CREATE INDEX IF NOT EXISTS idx_attendance_worker_id ON attendance(worker_id);
CREATE INDEX IF NOT EXISTS idx_attendance_job_id ON attendance(job_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);

CREATE INDEX IF NOT EXISTS idx_work_updates_job_id ON work_updates(job_id);
CREATE INDEX IF NOT EXISTS idx_work_updates_worker_id ON work_updates(worker_id);
CREATE INDEX IF NOT EXISTS idx_work_updates_created_at ON work_updates(created_at);

CREATE INDEX IF NOT EXISTS idx_installation_images_job_id ON installation_images(job_id);
CREATE INDEX IF NOT EXISTS idx_installation_images_worker_id ON installation_images(worker_id);
CREATE INDEX IF NOT EXISTS idx_installation_images_image_type ON installation_images(image_type);

CREATE INDEX IF NOT EXISTS idx_job_completion_job_id ON job_completion(job_id);
CREATE INDEX IF NOT EXISTS idx_job_completion_worker_id ON job_completion(worker_id);

CREATE INDEX IF NOT EXISTS idx_issue_reports_job_id ON issue_reports(job_id);
CREATE INDEX IF NOT EXISTS idx_issue_reports_worker_id ON issue_reports(worker_id);
CREATE INDEX IF NOT EXISTS idx_issue_reports_status ON issue_reports(status);
CREATE INDEX IF NOT EXISTS idx_issue_reports_reported_at ON issue_reports(reported_at);

CREATE INDEX IF NOT EXISTS idx_daily_reports_worker_id ON daily_reports(worker_id);
CREATE INDEX IF NOT EXISTS idx_daily_reports_report_date ON daily_reports(report_date);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_completion ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_reports ENABLE ROW LEVEL SECURITY;

-- Workers table policies
CREATE POLICY "Workers can view their own profile"
    ON workers FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Owners can view all workers"
    ON workers FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

CREATE POLICY "Workers can update their own profile"
    ON workers FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Owners can insert workers"
    ON workers FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- Customers table policies
CREATE POLICY "Owners can manage customers"
    ON customers FOR ALL
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

CREATE POLICY "Workers can view customers for their assigned jobs"
    ON customers FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM jobs 
        WHERE jobs.customer_id = customers.id 
        AND jobs.worker_id = auth.uid()
    ));

-- Jobs table policies
CREATE POLICY "Owners can manage all jobs"
    ON jobs FOR ALL
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

CREATE POLICY "Workers can view their assigned jobs"
    ON jobs FOR SELECT
    USING (worker_id = auth.uid());

CREATE POLICY "Workers can update their assigned jobs"
    ON jobs FOR UPDATE
    USING (worker_id = auth.uid());

-- Attendance table policies
CREATE POLICY "Workers can manage their own attendance"
    ON attendance FOR ALL
    USING (worker_id = auth.uid());

CREATE POLICY "Owners can view all attendance"
    ON attendance FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- Work updates table policies
CREATE POLICY "Workers can manage their own work updates"
    ON work_updates FOR ALL
    USING (worker_id = auth.uid());

CREATE POLICY "Owners can view all work updates"
    ON work_updates FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- Installation images table policies
CREATE POLICY "Workers can manage their own images"
    ON installation_images FOR ALL
    USING (worker_id = auth.uid());

CREATE POLICY "Owners can view all images"
    ON installation_images FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- Job completion table policies
CREATE POLICY "Workers can manage their own completions"
    ON job_completion FOR ALL
    USING (worker_id = auth.uid());

CREATE POLICY "Owners can view all completions"
    ON job_completion FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- Issue reports table policies
CREATE POLICY "Workers can manage their own issue reports"
    ON issue_reports FOR ALL
    USING (worker_id = auth.uid());

CREATE POLICY "Owners can manage all issue reports"
    ON issue_reports FOR ALL
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- Daily reports table policies
CREATE POLICY "Workers can view their own daily reports"
    ON daily_reports FOR SELECT
    USING (worker_id = auth.uid());

CREATE POLICY "Owners can manage all daily reports"
    ON daily_reports FOR ALL
    USING (EXISTS (
        SELECT 1 FROM workers WHERE id = auth.uid() AND role = 'owner'
    ));

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update job progress when work update is created
CREATE OR REPLACE FUNCTION update_job_progress()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE jobs 
    SET progress_percentage = NEW.progress_percentage,
        status = CASE 
            WHEN NEW.progress_percentage = 100 THEN 'completed'
            WHEN NEW.progress_percentage > 0 THEN 'in_progress'
            ELSE status
        END,
        completed_at = CASE 
            WHEN NEW.progress_percentage = 100 THEN NOW()
            ELSE completed_at
        END
    WHERE id = NEW.job_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_job_progress
    AFTER INSERT ON work_updates
    FOR EACH ROW
    EXECUTE FUNCTION update_job_progress();

-- Function to create daily report automatically
CREATE OR REPLACE FUNCTION create_daily_report()
RETURNS TRIGGER AS $$
DECLARE
    v_report_date DATE;
    v_total_jobs INTEGER;
    v_completed_jobs INTEGER;
    v_pending_jobs INTEGER;
    v_issues_reported INTEGER;
    v_total_hours INTEGER;
    v_job_ids UUID[];
BEGIN
    v_report_date := DATE(NEW.check_in_time);
    
    -- Calculate statistics
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'completed'),
        COUNT(*) FILTER (WHERE status != 'completed'),
        ARRAY_AGG(id)
    INTO v_total_jobs, v_completed_jobs, v_pending_jobs, v_job_ids
    FROM jobs 
    WHERE worker_id = NEW.worker_id 
    AND DATE(scheduled_date) = v_report_date;
    
    SELECT COUNT(*) INTO v_issues_reported
    FROM issue_reports
    WHERE worker_id = NEW.worker_id
    AND DATE(reported_at) = v_report_date;
    
    SELECT COALESCE(SUM(working_hours), 0) INTO v_total_hours
    FROM attendance
    WHERE worker_id = NEW.worker_id
    AND DATE(check_in_time) = v_report_date;
    
    -- Insert or update daily report
    INSERT INTO daily_reports (
        worker_id, report_date, total_jobs, completed_jobs, 
        pending_jobs, issues_reported, total_hours_worked, job_ids
    ) VALUES (
        NEW.worker_id, v_report_date, v_total_jobs, v_completed_jobs,
        v_pending_jobs, v_issues_reported, v_total_hours, v_job_ids
    )
    ON CONFLICT (worker_id, report_date) 
    DO UPDATE SET
        total_jobs = EXCLUDED.total_jobs,
        completed_jobs = EXCLUDED.completed_jobs,
        pending_jobs = EXCLUDED.pending_jobs,
        issues_reported = EXCLUDED.issues_reported,
        total_hours_worked = EXCLUDED.total_hours_worked,
        job_ids = EXCLUDED.job_ids;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_daily_report
    AFTER INSERT ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION create_daily_report();
