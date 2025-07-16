
-- First, completely disable RLS temporarily to clean everything up
ALTER TABLE public.group_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chama_groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies completely (force drop)
DO $$ 
DECLARE 
    policy_record RECORD;
BEGIN
    -- Drop all policies on group_members
    FOR policy_record IN 
        SELECT policyname FROM pg_policies WHERE tablename = 'group_members' AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.group_members';
    END LOOP;
    
    -- Drop all policies on chama_groups
    FOR policy_record IN 
        SELECT policyname FROM pg_policies WHERE tablename = 'chama_groups' AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.chama_groups';
    END LOOP;
    
    -- Drop all policies on contributions
    FOR policy_record IN 
        SELECT policyname FROM pg_policies WHERE tablename = 'contributions' AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.contributions';
    END LOOP;
    
    -- Drop all policies on loans
    FOR policy_record IN 
        SELECT policyname FROM pg_policies WHERE tablename = 'loans' AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.loans';
    END LOOP;
END $$;

-- Drop and recreate security definer functions to ensure they're clean
DROP FUNCTION IF EXISTS public.is_group_member(uuid, uuid);
DROP FUNCTION IF EXISTS public.get_user_groups(uuid);

-- Create security definer functions to avoid infinite recursion
CREATE OR REPLACE FUNCTION public.is_group_member(_user_id uuid, _group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE user_id = _user_id 
      AND group_id = _group_id 
      AND status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.get_user_groups(_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE SECURITY DEFINER
AS $$
  SELECT group_id
  FROM public.group_members
  WHERE user_id = _user_id 
    AND status = 'active';
$$;

-- Re-enable RLS
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chama_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;

-- Create simple, non-recursive RLS policies for group_members table
CREATE POLICY "group_members_select_policy" 
  ON public.group_members 
  FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY "group_members_insert_policy" 
  ON public.group_members 
  FOR INSERT 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "group_members_update_policy" 
  ON public.group_members 
  FOR UPDATE 
  USING (user_id = auth.uid());

-- Create RLS policies for chama_groups table
CREATE POLICY "chama_groups_select_policy" 
  ON public.chama_groups 
  FOR SELECT 
  USING (
    created_by = auth.uid() OR 
    id = ANY(SELECT public.get_user_groups(auth.uid()))
  );

CREATE POLICY "chama_groups_all_policy" 
  ON public.chama_groups 
  FOR ALL 
  USING (created_by = auth.uid());

-- Create RLS policies for contributions table
CREATE POLICY "contributions_select_policy" 
  ON public.contributions 
  FOR SELECT 
  USING (
    member_id = auth.uid() OR 
    group_id = ANY(SELECT public.get_user_groups(auth.uid()))
  );

CREATE POLICY "contributions_insert_policy" 
  ON public.contributions 
  FOR INSERT 
  WITH CHECK (
    member_id = auth.uid() AND 
    group_id = ANY(SELECT public.get_user_groups(auth.uid()))
  );

-- Create RLS policies for loans table
CREATE POLICY "loans_select_policy" 
  ON public.loans 
  FOR SELECT 
  USING (
    borrower_id = auth.uid() OR 
    group_id = ANY(SELECT public.get_user_groups(auth.uid()))
  );

CREATE POLICY "loans_insert_policy" 
  ON public.loans 
  FOR INSERT 
  WITH CHECK (
    borrower_id = auth.uid() AND 
    group_id = ANY(SELECT public.get_user_groups(auth.uid()))
  );
