
-- Fix the loans table foreign key constraint
-- The borrower_id should reference auth.users or profiles, not group_members

-- First, drop the existing incorrect foreign key constraint
ALTER TABLE public.loans DROP CONSTRAINT IF EXISTS loans_borrower_id_fkey;

-- Add the correct foreign key constraint that references auth.users
ALTER TABLE public.loans 
ADD CONSTRAINT loans_borrower_id_fkey 
FOREIGN KEY (borrower_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Update the RLS policy to ensure proper group membership validation
DROP POLICY IF EXISTS "loans_insert_policy" ON public.loans;

CREATE POLICY "loans_insert_policy" 
  ON public.loans 
  FOR INSERT 
  WITH CHECK (
    borrower_id = auth.uid() AND 
    public.is_group_member(auth.uid(), group_id)
  );

-- Also ensure the select policy uses the helper function properly
DROP POLICY IF EXISTS "loans_select_policy" ON public.loans;

CREATE POLICY "loans_select_policy" 
  ON public.loans 
  FOR SELECT 
  USING (
    borrower_id = auth.uid() OR 
    public.is_group_member(auth.uid(), group_id)
  );
