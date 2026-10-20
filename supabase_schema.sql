-- =========================================================================
-- PRACTICAL AI & JARVIS BACKEND SCHEMA FOR SUPABASE (POSTGRESQL)
-- =========================================================================

-- Enable UUID and vector extensions (if vector search / RAG is needed)
create extension if not exists "uuid-ossp";

-- =========================================================================
-- 1. LEADS & FOLLOW-UP ENGINE (Grok Bot Workflow 01 & Sales SDRs)
-- =========================================================================
create table if not exists public.leads (
    id uuid primary key default uuid_generate_v4(),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    name text not null,
    contact_email text,
    phone text,
    source text default 'website', -- website, crm, linkedin, referral
    product_interest text,
    last_interaction_at timestamp with time zone,
    status text default 'New', -- 'New', 'Needs follow-up', 'Waiting on customer', 'Won', 'Not a fit', 'Unclear'
    draft_message text,
    suggested_action text,
    is_approved boolean default false,
    opt_out boolean default false,
    metadata jsonb default '{}'::jsonb
);

-- Index for speedy lead filtering & follow-up lookups
create index if not exists idx_leads_status on public.leads(status);
create index if not exists idx_leads_opt_out on public.leads(opt_out);

-- =========================================================================
-- 2. DAILY AD PERFORMANCE & ANOMALY PULSE (Grok Bot Workflow 02)
-- =========================================================================
create table if not exists public.ad_reports (
    id uuid primary key default uuid_generate_v4(),
    report_date date not null,
    account_id text not null,
    platform text not null default 'meta', -- meta, google, linkedin
    spend numeric(12, 2) not null default 0.00,
    impressions bigint default 0,
    reach bigint default 0,
    clicks integer default 0,
    ctr numeric(5, 4), -- e.g. 0.0245 (2.45%)
    cpc numeric(10, 2),
    leads_count integer default 0,
    purchases_count integer default 0,
    cost_per_lead numeric(10, 2),
    cost_per_acquisition numeric(10, 2),
    attributed_revenue numeric(12, 2) default 0.00,
    roas numeric(6, 2),
    is_anomaly boolean default false,
    anomaly_reason text,
    executive_summary text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_ad_reports_date on public.ad_reports(report_date desc);

-- =========================================================================
-- 3. WEEKLY OPS & AUTOMATION SWEEPS (Grok Bot Workflow 03)
-- =========================================================================
create table if not exists public.ops_sweeps (
    id uuid primary key default uuid_generate_v4(),
    sweep_date date default current_date not null,
    overdue_tasks jsonb default '[]'::jsonb, -- [{task: string, owner: string, due_date: string}]
    stalled_leads jsonb default '[]'::jsonb,
    threshold_breaches jsonb default '[]'::jsonb,
    top_priorities text[] default array[]::text[],
    human_decision_required text,
    status text default 'pending_review', -- 'pending_review', 'actioned'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =========================================================================
-- 4. J.A.R.V.I.S. VOICE INTERACTIONS & MEMORY
-- =========================================================================
create table if not exists public.jarvis_interactions (
    id uuid primary key default uuid_generate_v4(),
    session_id text not null,
    user_command text not null,
    jarvis_response text not null,
    intent text,
    tools_called text[],
    latency_ms integer,
    was_voice boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_jarvis_session on public.jarvis_interactions(session_id);

-- =========================================================================
-- 5. SMART HOME & PHYSICAL DEVICE STATE (BroadLink / Wi-Fi layer)
-- =========================================================================
create table if not exists public.smart_devices (
    id uuid primary key default uuid_generate_v4(),
    device_name text not null, -- 'Living Room AC', 'Desk Projector', 'Geyser'
    device_type text not null, -- 'ac', 'projector', 'light', 'plug'
    protocol text not null default 'wifi', -- 'ir', 'rf', 'wifi'
    is_active boolean default false,
    state jsonb default '{"power": "off"}'::jsonb, -- e.g. {"temperature": 22, "power": "on"}
    last_command_at timestamp with time zone default timezone('utc'::text, now()),
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =========================================================================
-- 6. BUSINESS PILOTS & CLIENT ENGAGEMENTS (200 AI Ideas Launchpad)
-- =========================================================================
create table if not exists public.business_pilots (
    id uuid primary key default uuid_generate_v4(),
    client_name text not null,
    industry text not null, -- 'Creator', 'Dental Clinic', 'CA Firm', 'SaaS'
    target_kpi text not null,
    pilot_fee numeric(10, 2) default 25000.00,
    monthly_retainer numeric(10, 2) default 40000.00,
    start_date date default current_date,
    end_date date default (current_date + interval '14 days'),
    status text default 'Active', -- 'Negotiating', 'Active', 'Converted', 'Completed'
    manual_minutes_baseline integer default 45,
    review_minutes_target integer default 5,
    notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =========================================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================
alter table public.leads enable row level security;
alter table public.ad_reports enable row level security;
alter table public.ops_sweeps enable row level security;
alter table public.jarvis_interactions enable row level security;
alter table public.smart_devices enable row level security;
alter table public.business_pilots enable row level security;

-- Default development policy: allow authenticated users full access
create policy "Allow authenticated full access to leads" on public.leads for all to authenticated using (true);
create policy "Allow authenticated full access to ad_reports" on public.ad_reports for all to authenticated using (true);
create policy "Allow authenticated full access to ops_sweeps" on public.ops_sweeps for all to authenticated using (true);
create policy "Allow authenticated full access to jarvis_interactions" on public.jarvis_interactions for all to authenticated using (true);
create policy "Allow authenticated full access to smart_devices" on public.smart_devices for all to authenticated using (true);
create policy "Allow authenticated full access to business_pilots" on public.business_pilots for all to authenticated using (true);
