
-- First, let's create security definer functions to avoid infinite recursion in RLS policies

-- Function to check if a user is a member of a group
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

-- Function to get user's groups
CREATE OR REPLACE FUNCTION public.get_user_groups(_user_id uuid)
RETURNS TABLE(group_id uuid)
LANGUAGE sql
STABLE SECURITY DEFINER
AS $$
  SELECT gm.group_id
  FROM public.group_members gm
  WHERE gm.user_id = _user_id 
    AND gm.status = 'active';
$$;

-- Drop ALL existing policies that might be causing recursion or conflicts
DROP POLICY IF EXISTS "Users can view their own group memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can view their own memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can insert their own memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can update their own memberships" ON public.group_members;

DROP POLICY IF EXISTS "Users can view groups they belong to" ON public.chama_groups;
DROP POLICY IF EXISTS "Group creators can manage their groups" ON public.chama_groups;

DROP POLICY IF EXISTS "Users can view their own contributions" ON public.contributions;
DROP POLICY IF EXISTS "Users can view contributions in their groups" ON public.contributions;
DROP POLICY IF EXISTS "Users can insert contributions to their groups" ON public.contributions;

DROP POLICY IF EXISTS "Users can view their own loans" ON public.loans;
DROP POLICY IF EXISTS "Users can view loans in their groups" ON public.loans;
DROP POLICY IF EXISTS "Users can request loans in their groups" ON public.loans;

-- Create new RLS policies for group_members table
CREATE POLICY "Users can view their own memberships" 
  ON public.group_members 
  FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own memberships" 
  ON public.group_members 
  FOR INSERT 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own memberships" 
  ON public.group_members 
  FOR UPDATE 
  USING (user_id = auth.uid());

-- Create RLS policies for chama_groups table
CREATE POLICY "Users can view groups they belong to" 
  ON public.chama_groups 
  FOR SELECT 
  USING (id IN (SELECT group_id FROM public.get_user_groups(auth.uid())));

CREATE POLICY "Group creators can manage their groups" 
  ON public.chama_groups 
  FOR ALL 
  USING (created_by = auth.uid());

-- Create RLS policies for contributions table
CREATE POLICY "Users can view contributions in their groups" 
  ON public.contributions 
  FOR SELECT 
  USING (group_id IN (SELECT group_id FROM public.get_user_groups(auth.uid())));

CREATE POLICY "Users can insert contributions to their groups" 
  ON public.contributions 
  FOR INSERT 
  WITH CHECK (group_id IN (SELECT group_id FROM public.get_user_groups(auth.uid())));

-- Create RLS policies for loans table
CREATE POLICY "Users can view loans in their groups" 
  ON public.loans 
  FOR SELECT 
  USING (
    borrower_id = auth.uid() OR 
    group_id IN (SELECT group_id FROM public.get_user_groups(auth.uid()))
  );

CREATE POLICY "Users can request loans in their groups" 
  ON public.loans 
  FOR INSERT 
  WITH CHECK (
    borrower_id = auth.uid() AND 
    group_id IN (SELECT group_id FROM public.get_user_groups(auth.uid()))
  );

-- Ensure RLS is enabled on all tables
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chama_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
