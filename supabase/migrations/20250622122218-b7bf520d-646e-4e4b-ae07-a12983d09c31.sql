
-- TARGETED SCHEMA IMPROVEMENTS FOR CHAMA APPLICATION (CORRECTED)
-- Fixed syntax errors from previous migration

-- 1. Add missing CHECK constraints for data integrity (without IF NOT EXISTS)
DO $$ 
BEGIN
    -- Add notification type constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_notification_type' AND table_name = 'notifications') THEN
        ALTER TABLE public.notifications 
        ADD CONSTRAINT chk_notification_type 
        CHECK (notification_type IN ('loan_eligibility', 'contribution_reminder', 'loan_status_update', 'member_loan_announcement', 'general', 'system'));
    END IF;

    -- Add notification status constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_notification_status' AND table_name = 'notifications') THEN
        ALTER TABLE public.notifications 
        ADD CONSTRAINT chk_notification_status 
        CHECK (status IN ('unread', 'read', 'archived'));
    END IF;

    -- Add notification priority constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_notification_priority' AND table_name = 'notifications') THEN
        ALTER TABLE public.notifications 
        ADD CONSTRAINT chk_notification_priority 
        CHECK (priority IN ('low', 'medium', 'high'));
    END IF;

    -- Add loan amount constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_loan_amount_positive' AND table_name = 'loans') THEN
        ALTER TABLE public.loans 
        ADD CONSTRAINT chk_loan_amount_positive 
        CHECK (amount > 0);
    END IF;

    -- Add interest rate constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_interest_rate_positive' AND table_name = 'loans') THEN
        ALTER TABLE public.loans 
        ADD CONSTRAINT chk_interest_rate_positive 
        CHECK (interest_rate >= 0);
    END IF;

    -- Add duration constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_duration_positive' AND table_name = 'loans') THEN
        ALTER TABLE public.loans 
        ADD CONSTRAINT chk_duration_positive 
        CHECK (duration_months > 0);
    END IF;

    -- Add contribution amount constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_contribution_amount_positive' AND table_name = 'contributions') THEN
        ALTER TABLE public.contributions 
        ADD CONSTRAINT chk_contribution_amount_positive 
        CHECK (amount > 0);
    END IF;

    -- Add group contribution amount constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_group_contribution_amount_positive' AND table_name = 'chama_groups') THEN
        ALTER TABLE public.chama_groups 
        ADD CONSTRAINT chk_group_contribution_amount_positive 
        CHECK (contribution_amount >= 0);
    END IF;

    -- Add loan interest rate constraint for groups
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_loan_interest_rate_valid' AND table_name = 'chama_groups') THEN
        ALTER TABLE public.chama_groups 
        ADD CONSTRAINT chk_loan_interest_rate_valid 
        CHECK (loan_interest_rate >= 0 AND loan_interest_rate <= 100);
    END IF;

    -- Add max loan multiplier constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'chk_max_loan_multiplier_positive' AND table_name = 'chama_groups') THEN
        ALTER TABLE public.chama_groups 
        ADD CONSTRAINT chk_max_loan_multiplier_positive 
        CHECK (max_loan_multiplier > 0);
    END IF;
END $$;

-- 2. Create missing indexes for better performance
CREATE INDEX IF NOT EXISTS idx_loans_status ON public.loans(status);
CREATE INDEX IF NOT EXISTS idx_loans_application_date ON public.loans(application_date DESC);
CREATE INDEX IF NOT EXISTS idx_contributions_date ON public.contributions(contribution_date DESC);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON public.contributions(status);
CREATE INDEX IF NOT EXISTS idx_group_members_role ON public.group_members(role);

-- 3. Add missing RLS policies for payment_methods
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'payment_methods_select_policy' AND tablename = 'payment_methods') THEN
        CREATE POLICY "payment_methods_select_policy" 
          ON public.payment_methods 
          FOR SELECT 
          USING (user_id = auth.uid());
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'payment_methods_insert_policy' AND tablename = 'payment_methods') THEN
        CREATE POLICY "payment_methods_insert_policy" 
          ON public.payment_methods 
          FOR INSERT 
          WITH CHECK (user_id = auth.uid());
    END IF;
END $$;

-- 4. Add RLS policy for loan_repayments
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'loan_repayments_select_policy' AND tablename = 'loan_repayments') THEN
        CREATE POLICY "loan_repayments_select_policy" 
          ON public.loan_repayments 
          FOR SELECT 
          USING (
            EXISTS (
              SELECT 1 FROM public.loans 
              WHERE id = loan_repayments.loan_id 
              AND (borrower_id = auth.uid() OR 
                   public.is_group_member(auth.uid(), group_id))
            )
          );
    END IF;
END $$;

-- 5. Improve notification policy for system insertions
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications" 
  ON public.notifications 
  FOR INSERT 
  WITH CHECK (
    user_id IS NOT NULL AND 
    (user_id = auth.uid() OR 
     EXISTS (
       SELECT 1 FROM public.group_members gm1, public.group_members gm2
       WHERE gm1.user_id = auth.uid() 
       AND gm2.user_id = notifications.user_id
       AND gm1.group_id = gm2.group_id
       AND gm1.role IN ('admin', 'treasurer')
       AND gm1.status = 'active'
     ))
  );

-- 6. Add validation for loan repayment schedule
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'loan_repayment_schedule_select_policy' AND tablename = 'loan_repayment_schedule') THEN
        CREATE POLICY "loan_repayment_schedule_select_policy" 
          ON public.loan_repayment_schedule 
          FOR SELECT 
          USING (
            EXISTS (
              SELECT 1 FROM public.loans 
              WHERE id = loan_repayment_schedule.loan_id 
              AND (borrower_id = auth.uid() OR 
                   public.is_group_member(auth.uid(), group_id))
            )
          );
    END IF;
END $$;

-- 7. Add trigger to update group totals when contributions change
CREATE OR REPLACE FUNCTION public.update_group_totals_on_contribution()
RETURNS TRIGGER AS $$
BEGIN
  -- Update group total savings and member contribution totals
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE public.chama_groups 
    SET 
      total_savings = (
        SELECT COALESCE(SUM(amount), 0) 
        FROM public.contributions 
        WHERE group_id = NEW.group_id AND status = 'completed'
      ),
      updated_at = NOW()
    WHERE id = NEW.group_id;
    
    -- Update member total contributions
    UPDATE public.group_members 
    SET total_contributions = (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.contributions 
      WHERE member_id = NEW.member_id AND status = 'completed'
    )
    WHERE id = NEW.member_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.chama_groups 
    SET 
      total_savings = (
        SELECT COALESCE(SUM(amount), 0) 
        FROM public.contributions 
        WHERE group_id = OLD.group_id AND status = 'completed'
      ),
      updated_at = NOW()
    WHERE id = OLD.group_id;
    
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_update_group_totals_on_contribution ON public.contributions;
CREATE TRIGGER tr_update_group_totals_on_contribution
  AFTER INSERT OR UPDATE OR DELETE ON public.contributions
  FOR EACH ROW EXECUTE FUNCTION public.update_group_totals_on_contribution();

-- 8. Add function to check if user can manage group
CREATE OR REPLACE FUNCTION public.can_manage_group(_user_id UUID, _group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE user_id = _user_id 
      AND group_id = _group_id 
      AND role IN ('admin', 'treasurer')
      AND status = 'active'
  ) OR EXISTS (
    SELECT 1 FROM public.chama_groups
    WHERE id = _group_id AND created_by = _user_id
  );
$$;
