
-- Fix contributions RLS policies
DROP POLICY IF EXISTS "contributions_select_policy" ON public.contributions;
DROP POLICY IF EXISTS "contributions_insert_policy" ON public.contributions;

-- Create correct policies
CREATE POLICY "contributions_select_policy" 
  ON public.contributions 
  FOR SELECT 
  USING (
    group_id IN (
      SELECT group_id FROM public.group_members 
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

CREATE POLICY "contributions_insert_policy" 
  ON public.contributions 
  FOR INSERT 
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM public.group_members 
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );
