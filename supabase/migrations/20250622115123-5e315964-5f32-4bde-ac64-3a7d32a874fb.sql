
-- Fix the loans table status column conversion issue
-- First, update any existing status values to match enum values
UPDATE public.loans 
SET status = CASE 
  WHEN status = 'pending' THEN 'pending'
  WHEN status = 'approved' THEN 'approved'
  WHEN status = 'rejected' THEN 'rejected'
  WHEN status = 'completed' THEN 'completed'
  WHEN status = 'active' THEN 'active'
  WHEN status = 'disbursed' THEN 'disbursed'
  WHEN status = 'defaulted' THEN 'defaulted'
  ELSE 'pending'
END;

-- Remove the default constraint temporarily
ALTER TABLE public.loans ALTER COLUMN status DROP DEFAULT;

-- Create the enum type
CREATE TYPE loan_status_enum AS ENUM (
  'pending',
  'under_review', 
  'approved',
  'rejected',
  'disbursed',
  'active',
  'completed',
  'defaulted',
  'cancelled'
);

-- Now convert the column type
ALTER TABLE public.loans 
  ALTER COLUMN status TYPE loan_status_enum USING status::loan_status_enum;

-- Set the new default
ALTER TABLE public.loans 
  ALTER COLUMN status SET DEFAULT 'pending'::loan_status_enum;

-- Add the new columns to loans table
ALTER TABLE public.loans 
  ADD COLUMN IF NOT EXISTS loan_officer_id uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS review_notes text,
  ADD COLUMN IF NOT EXISTS rejection_reason text,
  ADD COLUMN IF NOT EXISTS disbursement_method text DEFAULT 'cash',
  ADD COLUMN IF NOT EXISTS disbursement_reference text,
  ADD COLUMN IF NOT EXISTS monthly_payment_amount numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS next_payment_date date,
  ADD COLUMN IF NOT EXISTS payments_made integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_overdue boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS days_overdue integer DEFAULT 0;

-- Fix duplicate group names
CREATE OR REPLACE FUNCTION fix_duplicate_group_names() 
RETURNS void AS $$
DECLARE
    duplicate_name text;
    counter integer;
    group_record record;
BEGIN
    FOR duplicate_name IN 
        SELECT LOWER(name) 
        FROM public.chama_groups 
        GROUP BY LOWER(name) 
        HAVING COUNT(*) > 1
    LOOP
        counter := 1;
        FOR group_record IN 
            SELECT id, name 
            FROM public.chama_groups 
            WHERE LOWER(name) = duplicate_name 
            ORDER BY created_at
        LOOP
            IF counter > 1 THEN
                UPDATE public.chama_groups 
                SET name = group_record.name || ' (' || counter || ')'
                WHERE id = group_record.id;
            END IF;
            counter := counter + 1;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT fix_duplicate_group_names();
DROP FUNCTION fix_duplicate_group_names();

-- Fix duplicate profiles
UPDATE public.profiles 
SET email = email || '_' || id::text 
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at) as rn
        FROM public.profiles 
        WHERE email IS NOT NULL
    ) t WHERE rn > 1
);

UPDATE public.profiles 
SET phone_number = phone_number || '_' || id::text 
WHERE phone_number IS NOT NULL 
AND id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY phone_number ORDER BY created_at) as rn
        FROM public.profiles 
        WHERE phone_number IS NOT NULL
    ) t WHERE rn > 1
);

-- Fix duplicate contributions
DELETE FROM public.contributions 
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
            PARTITION BY member_id, group_id, contribution_date, amount 
            ORDER BY created_at
        ) as rn
        FROM public.contributions
    ) t WHERE rn > 1
);

-- Fix duplicate active loans
UPDATE public.loans 
SET status = 'cancelled'::loan_status_enum
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
            PARTITION BY borrower_id, group_id 
            ORDER BY application_date
        ) as rn
        FROM public.loans
        WHERE status IN ('pending', 'under_review', 'approved', 'disbursed', 'active')
    ) t WHERE rn > 1
);

-- Add unique constraints
ALTER TABLE public.profiles ADD CONSTRAINT profiles_email_unique UNIQUE (email);
ALTER TABLE public.profiles ADD CONSTRAINT profiles_phone_unique UNIQUE (phone_number) DEFERRABLE INITIALLY DEFERRED;
CREATE UNIQUE INDEX chama_groups_name_lower_unique ON public.chama_groups (LOWER(name));
ALTER TABLE public.contributions ADD CONSTRAINT contributions_no_duplicates 
  UNIQUE (member_id, group_id, contribution_date, amount);
CREATE UNIQUE INDEX loans_active_per_user_group ON public.loans (borrower_id, group_id) 
  WHERE status IN ('pending', 'under_review', 'approved', 'disbursed', 'active');

-- Create loan_disbursements table
CREATE TABLE public.loan_disbursements (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  loan_id uuid NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  disbursement_date date NOT NULL DEFAULT CURRENT_DATE,
  amount numeric NOT NULL,
  disbursement_method text NOT NULL DEFAULT 'cash',
  reference_number text,
  disbursed_by uuid REFERENCES public.profiles(id),
  notes text,
  status text NOT NULL DEFAULT 'completed',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create loan_repayment_schedule table
CREATE TABLE public.loan_repayment_schedule (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  loan_id uuid NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  installment_number integer NOT NULL,
  due_date date NOT NULL,
  principal_amount numeric NOT NULL,
  interest_amount numeric NOT NULL,
  total_amount numeric NOT NULL,
  amount_paid numeric NOT NULL DEFAULT 0,
  payment_date date,
  status text NOT NULL DEFAULT 'pending',
  is_overdue boolean DEFAULT false,
  days_overdue integer DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  
  CONSTRAINT loan_repayment_schedule_loan_installment_unique 
    UNIQUE (loan_id, installment_number)
);

-- Create repayment schedule generation function
CREATE OR REPLACE FUNCTION generate_loan_repayment_schedule(
  p_loan_id uuid,
  p_amount numeric,
  p_interest_rate numeric,
  p_duration_months integer,
  p_start_date date DEFAULT CURRENT_DATE
) RETURNS void AS $$
DECLARE
  monthly_payment numeric;
  monthly_interest_rate numeric;
  principal_payment numeric;
  interest_payment numeric;
  remaining_balance numeric;
  i integer;
  payment_date date;
BEGIN
  monthly_interest_rate := p_interest_rate / 100 / 12;
  
  IF monthly_interest_rate = 0 THEN
    monthly_payment := p_amount / p_duration_months;
  ELSE
    monthly_payment := p_amount * (monthly_interest_rate * POWER(1 + monthly_interest_rate, p_duration_months)) / 
                      (POWER(1 + monthly_interest_rate, p_duration_months) - 1);
  END IF;
  
  remaining_balance := p_amount;
  
  FOR i IN 1..p_duration_months LOOP
    payment_date := p_start_date + (i || ' months')::interval;
    
    IF monthly_interest_rate = 0 THEN
      interest_payment := 0;
      principal_payment := monthly_payment;
    ELSE
      interest_payment := remaining_balance * monthly_interest_rate;
      principal_payment := monthly_payment - interest_payment;
    END IF;
    
    IF i = p_duration_months THEN
      principal_payment := remaining_balance;
      monthly_payment := principal_payment + interest_payment;
    END IF;
    
    INSERT INTO public.loan_repayment_schedule (
      loan_id, installment_number, due_date, principal_amount, interest_amount, total_amount
    ) VALUES (
      p_loan_id, i, payment_date, principal_payment, interest_payment, monthly_payment
    );
    
    remaining_balance := remaining_balance - principal_payment;
  END LOOP;
  
  UPDATE public.loans 
  SET monthly_payment_amount = monthly_payment, next_payment_date = p_start_date + '1 month'::interval
  WHERE id = p_loan_id;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE OR REPLACE FUNCTION auto_generate_repayment_schedule()
RETURNS trigger AS $$
BEGIN
  IF OLD.status != 'approved' AND NEW.status = 'approved' THEN
    PERFORM generate_loan_repayment_schedule(
      NEW.id, NEW.amount, NEW.interest_rate, NEW.duration_months,
      COALESCE(NEW.disbursement_date, CURRENT_DATE + interval '1 day')
    );
  END IF;
  
  IF OLD.status = 'approved' AND NEW.status = 'disbursed' THEN
    NEW.status := 'active';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER loans_status_management
  BEFORE UPDATE ON public.loans
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_repayment_schedule();

CREATE OR REPLACE FUNCTION update_loan_status_from_repayments()
RETURNS trigger AS $$
DECLARE
  total_scheduled numeric;
  total_paid numeric;
BEGIN
  SELECT COALESCE(SUM(total_amount), 0), COALESCE(SUM(amount_paid), 0)
  INTO total_scheduled, total_paid
  FROM public.loan_repayment_schedule 
  WHERE loan_id = NEW.loan_id;
  
  UPDATE public.loans 
  SET payments_made = (
    SELECT COUNT(*) FROM public.loan_repayment_schedule 
    WHERE loan_id = NEW.loan_id AND amount_paid > 0
  )
  WHERE id = NEW.loan_id;
  
  IF total_paid >= total_scheduled THEN
    UPDATE public.loans 
    SET status = 'completed', amount_repaid = total_paid
    WHERE id = NEW.loan_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_loan_on_repayment
  AFTER UPDATE ON public.loan_repayment_schedule
  FOR EACH ROW
  WHEN (OLD.amount_paid != NEW.amount_paid)
  EXECUTE FUNCTION update_loan_status_from_repayments();

-- Enable RLS and create policies
ALTER TABLE public.loan_disbursements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_repayment_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "loan_disbursements_select_policy" 
  ON public.loan_disbursements FOR SELECT 
  USING (loan_id IN (
    SELECT id FROM public.loans 
    WHERE group_id IN (
      SELECT group_id FROM public.group_members 
      WHERE user_id = auth.uid() AND status = 'active'
    )
  ));

CREATE POLICY "loan_disbursements_insert_policy" 
  ON public.loan_disbursements FOR INSERT 
  WITH CHECK (loan_id IN (
    SELECT id FROM public.loans 
    WHERE group_id IN (
      SELECT group_id FROM public.group_members 
      WHERE user_id = auth.uid() AND status = 'active' AND role IN ('admin', 'treasurer')
    )
  ));

CREATE POLICY "loan_repayment_schedule_select_policy" 
  ON public.loan_repayment_schedule FOR SELECT 
  USING (loan_id IN (
    SELECT id FROM public.loans 
    WHERE group_id IN (
      SELECT group_id FROM public.group_members 
      WHERE user_id = auth.uid() AND status = 'active'
    )
  ));

CREATE POLICY "loan_repayment_schedule_update_policy" 
  ON public.loan_repayment_schedule FOR UPDATE 
  USING (loan_id IN (
    SELECT id FROM public.loans 
    WHERE group_id IN (
      SELECT group_id FROM public.group_members 
      WHERE user_id = auth.uid() AND status = 'active' AND role IN ('admin', 'treasurer')
    )
  ));

-- Update loan_repayments table
ALTER TABLE public.loan_repayments 
  ADD COLUMN IF NOT EXISTS schedule_id uuid REFERENCES public.loan_repayment_schedule(id),
  ADD COLUMN IF NOT EXISTS late_fee numeric DEFAULT 0;

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_loans_status ON public.loans(status);
CREATE INDEX IF NOT EXISTS idx_loans_borrower_group ON public.loans(borrower_id, group_id);
CREATE INDEX IF NOT EXISTS idx_loan_schedule_due_date ON public.loan_repayment_schedule(due_date);
CREATE INDEX IF NOT EXISTS idx_loan_schedule_status ON public.loan_repayment_schedule(status);
CREATE INDEX IF NOT EXISTS idx_contributions_member_group_date ON public.contributions(member_id, group_id, contribution_date);
