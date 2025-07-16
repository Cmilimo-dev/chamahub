-- Fix calculate_loan_eligibility function to properly use member_id
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
  member_record_id UUID;
  reasons TEXT[] := ARRAY[]::TEXT[];
  eligible BOOLEAN := true;
  max_amount NUMERIC := 0;
BEGIN
  -- Get the member record ID first
  SELECT id INTO member_record_id
  FROM public.group_members 
  WHERE user_id = _user_id AND group_id = _group_id AND status = 'active';

  IF member_record_id IS NULL THEN
    eligible := false;
    reasons := array_append(reasons, 'Not a member of this group');
    RETURN QUERY SELECT eligible, max_amount, reasons;
    RETURN;
  END IF;

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

  IF membership_duration_months < min_membership_months THEN
    eligible := false;
    reasons := array_append(reasons, format('Membership duration (%s months) is less than required %s months', membership_duration_months, min_membership_months));
  END IF;

  -- Check total contributions using the correct member_id
  SELECT COALESCE(SUM(amount), 0) INTO total_contributions
  FROM public.contributions 
  WHERE member_id = member_record_id AND group_id = _group_id AND status = 'completed';

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
