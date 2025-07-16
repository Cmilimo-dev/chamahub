
-- Add customization columns to chama_groups table
ALTER TABLE public.chama_groups 
ADD COLUMN IF NOT EXISTS min_contribution_amount numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_contribution_amount numeric,
ADD COLUMN IF NOT EXISTS loan_interest_rate numeric DEFAULT 5.0,
ADD COLUMN IF NOT EXISTS max_loan_multiplier numeric DEFAULT 3.0,
ADD COLUMN IF NOT EXISTS allow_partial_contributions boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS contribution_grace_period_days integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS group_rules jsonb DEFAULT '{}'::jsonb;

-- Update existing groups with default values based on current contribution_amount
UPDATE public.chama_groups 
SET 
  min_contribution_amount = contribution_amount * 0.5,
  max_contribution_amount = contribution_amount * 2.0
WHERE min_contribution_amount IS NULL OR max_contribution_amount IS NULL;

-- Create group customization settings table for more complex rules
CREATE TABLE IF NOT EXISTS public.group_customization_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.chama_groups(id) ON DELETE CASCADE NOT NULL,
  setting_category TEXT NOT NULL,
  setting_key TEXT NOT NULL,
  setting_value JSONB NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(group_id, setting_category, setting_key)
);

-- Enable RLS on group customization settings
ALTER TABLE public.group_customization_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for group customization settings
CREATE POLICY "Group members can view customization settings" 
  ON public.group_customization_settings 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members 
      WHERE group_id = group_customization_settings.group_id 
      AND user_id = auth.uid() 
      AND status = 'active'
    )
  );

CREATE POLICY "Group admins can manage customization settings" 
  ON public.group_customization_settings 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members 
      WHERE group_id = group_customization_settings.group_id 
      AND user_id = auth.uid() 
      AND role IN ('admin', 'treasurer') 
      AND status = 'active'
    )
  );

-- Update loan eligibility function to use group-specific settings
CREATE OR REPLACE FUNCTION public.calculate_loan_eligibility(_user_id uuid, _group_id uuid)
RETURNS TABLE(is_eligible boolean, max_loan_amount numeric, eligibility_reasons text[])
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
DECLARE
  membership_duration_months INTEGER;
  total_contributions NUMERIC;
  active_loans_count INTEGER;
  contribution_multiplier NUMERIC;
  min_membership_months NUMERIC;
  max_active_loans NUMERIC;
  min_contributions NUMERIC;
  group_loan_multiplier NUMERIC;
  group_interest_rate NUMERIC;
  reasons TEXT[] := ARRAY[]::TEXT[];
  eligible BOOLEAN := true;
  max_amount NUMERIC := 0;
BEGIN
  -- Get group-specific loan multiplier and interest rate
  SELECT max_loan_multiplier, loan_interest_rate 
  INTO group_loan_multiplier, group_interest_rate
  FROM public.chama_groups 
  WHERE id = _group_id;

  -- Get eligibility rules for the group (with group-specific defaults)
  SELECT COALESCE(rule_value, group_loan_multiplier, 3.0) INTO contribution_multiplier
  FROM public.loan_eligibility_rules 
  WHERE group_id = _group_id AND rule_type = 'contribution_multiplier' AND is_active = true;
  
  SELECT rule_value INTO min_membership_months 
  FROM public.loan_eligibility_rules 
  WHERE group_id = _group_id AND rule_type = 'membership_duration_months' AND is_active = true;
  
  SELECT rule_value INTO max_active_loans 
  FROM public.loan_eligibility_rules 
  WHERE group_id = _group_id AND rule_type = 'max_active_loans' AND is_active = true;
  
  SELECT rule_value INTO min_contributions 
  FROM public.loan_eligibility_rules 
  WHERE group_id = _group_id AND rule_type = 'minimum_contributions' AND is_active = true;

  -- Set defaults if rules don't exist
  contribution_multiplier := COALESCE(contribution_multiplier, group_loan_multiplier, 3.0);
  min_membership_months := COALESCE(min_membership_months, 6.0);
  max_active_loans := COALESCE(max_active_loans, 1.0);
  min_contributions := COALESCE(min_contributions, 3.0);

  -- Check membership duration
  SELECT EXTRACT(MONTH FROM AGE(NOW(), joined_at)) INTO membership_duration_months
  FROM public.group_members 
  WHERE user_id = _user_id AND group_id = _group_id AND status = 'active';

  IF membership_duration_months IS NULL THEN
    eligible := false;
    reasons := array_append(reasons, 'Not a member of this group');
    RETURN QUERY SELECT eligible, max_amount, reasons;
    RETURN;
  END IF;

  IF membership_duration_months < min_membership_months THEN
    eligible := false;
    reasons := array_append(reasons, format('Membership duration (%s months) is less than required %s months', membership_duration_months, min_membership_months));
  END IF;

  -- Check total contributions
  SELECT COALESCE(SUM(amount), 0) INTO total_contributions
  FROM public.contributions 
  WHERE member_id = _user_id AND group_id = _group_id AND status = 'completed';

  IF total_contributions < min_contributions THEN
    eligible := false;
    reasons := array_append(reasons, format('Total contributions (%s) is less than required %s', total_contributions, min_contributions));
  END IF;

  -- Check active loans
  SELECT COUNT(*) INTO active_loans_count
  FROM public.loans 
  WHERE borrower_id = _user_id AND group_id = _group_id 
  AND status IN ('pending', 'approved', 'disbursed');

  IF active_loans_count >= max_active_loans THEN
    eligible := false;
    reasons := array_append(reasons, format('Has %s active loans (maximum allowed: %s)', active_loans_count, max_active_loans));
  END IF;

  -- Calculate maximum loan amount using group-specific multiplier
  IF eligible THEN
    max_amount := total_contributions * contribution_multiplier;
    reasons := array_append(reasons, format('Eligible for up to KES %s (based on %s contributions × %s multiplier at %s%% interest)', max_amount, total_contributions, contribution_multiplier, group_interest_rate));
  END IF;

  RETURN QUERY SELECT eligible, max_amount, reasons;
END;
$$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_group_customization_settings_group_id ON public.group_customization_settings(group_id);
CREATE INDEX IF NOT EXISTS idx_group_customization_settings_category ON public.group_customization_settings(setting_category);
