
-- Create notifications table to store all types of notifications
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('loan_eligibility', 'contribution_reminder', 'loan_status_update', 'member_loan_announcement', 'general')),
  status TEXT NOT NULL DEFAULT 'unread' CHECK (status IN ('unread', 'read')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  channels JSONB NOT NULL DEFAULT '["in_app"]'::jsonb, -- email, sms, in_app
  metadata JSONB DEFAULT '{}'::jsonb,
  scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT now(),
  sent_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  group_id UUID REFERENCES public.chama_groups(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create loan eligibility rules table for configurable criteria
CREATE TABLE public.loan_eligibility_rules (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.chama_groups(id) ON DELETE CASCADE NOT NULL,
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('contribution_multiplier', 'membership_duration_months', 'max_active_loans', 'minimum_contributions')),
  rule_value NUMERIC NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(group_id, rule_type)
);

-- Add notification preferences to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
  "email_enabled": true,
  "sms_enabled": false,
  "in_app_enabled": true,
  "loan_eligibility_alerts": true,
  "contribution_reminders": true,
  "loan_status_updates": true,
  "member_loan_announcements": true
}'::jsonb;

-- Add phone number to profiles for SMS notifications
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- Enable RLS on notifications table
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for notifications
CREATE POLICY "Users can view their own notifications" 
  ON public.notifications 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" 
  ON public.notifications 
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- Enable RLS on loan eligibility rules
ALTER TABLE public.loan_eligibility_rules ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for loan eligibility rules
CREATE POLICY "Group members can view eligibility rules" 
  ON public.loan_eligibility_rules 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members 
      WHERE group_id = loan_eligibility_rules.group_id 
      AND user_id = auth.uid() 
      AND status = 'active'
    )
  );

CREATE POLICY "Group admins can manage eligibility rules" 
  ON public.loan_eligibility_rules 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members 
      WHERE group_id = loan_eligibility_rules.group_id 
      AND user_id = auth.uid() 
      AND role IN ('admin', 'treasurer') 
      AND status = 'active'
    )
  );

-- Insert default eligibility rules for existing groups
INSERT INTO public.loan_eligibility_rules (group_id, rule_name, rule_type, rule_value)
SELECT 
  id as group_id,
  'Contribution Multiplier',
  'contribution_multiplier',
  3.0
FROM public.chama_groups
ON CONFLICT (group_id, rule_type) DO NOTHING;

INSERT INTO public.loan_eligibility_rules (group_id, rule_name, rule_type, rule_value)
SELECT 
  id as group_id,
  'Minimum Membership Duration (Months)',
  'membership_duration_months',
  6.0
FROM public.chama_groups
ON CONFLICT (group_id, rule_type) DO NOTHING;

INSERT INTO public.loan_eligibility_rules (group_id, rule_name, rule_type, rule_value)
SELECT 
  id as group_id,
  'Maximum Active Loans',
  'max_active_loans',
  1.0
FROM public.chama_groups
ON CONFLICT (group_id, rule_type) DO NOTHING;

INSERT INTO public.loan_eligibility_rules (group_id, rule_name, rule_type, rule_value)
SELECT 
  id as group_id,
  'Minimum Contributions Required',
  'minimum_contributions',
  3.0
FROM public.chama_groups
ON CONFLICT (group_id, rule_type) DO NOTHING;

-- Create function to calculate loan eligibility
CREATE OR REPLACE FUNCTION public.calculate_loan_eligibility(
  _user_id UUID,
  _group_id UUID
)
RETURNS TABLE(
  is_eligible BOOLEAN,
  max_loan_amount NUMERIC,
  eligibility_reasons TEXT[]
) 
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
  reasons TEXT[] := ARRAY[]::TEXT[];
  eligible BOOLEAN := true;
  max_amount NUMERIC := 0;
BEGIN
  -- Get eligibility rules for the group
  SELECT rule_value INTO contribution_multiplier 
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
  contribution_multiplier := COALESCE(contribution_multiplier, 3.0);
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

  -- Calculate maximum loan amount
  IF eligible THEN
    max_amount := total_contributions * contribution_multiplier;
    reasons := array_append(reasons, format('Eligible for up to %s (based on %s contributions × %s multiplier)', max_amount, total_contributions, contribution_multiplier));
  END IF;

  RETURN QUERY SELECT eligible, max_amount, reasons;
END;
$$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_for ON public.notifications(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_loan_eligibility_rules_group_id ON public.loan_eligibility_rules(group_id);
