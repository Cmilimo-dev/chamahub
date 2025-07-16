
-- Create payment methods table for storing different payment options
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  method_type TEXT NOT NULL CHECK (method_type IN ('mobile_money', 'bank_account', 'card')),
  provider TEXT NOT NULL, -- M-Pesa, Airtel Money, KCB, Equity, etc.
  account_identifier TEXT NOT NULL, -- Phone number for mobile money, account number for banks
  account_name TEXT,
  is_primary BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  verification_code TEXT,
  verification_expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, method_type, provider, account_identifier)
);

-- Create transaction notifications table
CREATE TABLE IF NOT EXISTS public.transaction_notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  transaction_id UUID, -- Can reference contributions, loans, or other transactions
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('contribution', 'loan', 'repayment', 'withdrawal')),
  notification_type TEXT NOT NULL CHECK (notification_type IN ('pending', 'completed', 'failed', 'reminder')),
  amount NUMERIC NOT NULL,
  currency TEXT DEFAULT 'KES',
  payment_method_id UUID REFERENCES public.payment_methods(id),
  external_reference TEXT, -- Reference from payment provider
  message TEXT NOT NULL,
  channels JSONB DEFAULT '["in_app"]'::jsonb,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  group_id UUID REFERENCES public.chama_groups(id)
);

-- Create automated transaction rules table
CREATE TABLE IF NOT EXISTS public.automated_transaction_rules (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  group_id UUID REFERENCES public.chama_groups(id) ON DELETE CASCADE NOT NULL,
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('auto_contribute', 'auto_repay', 'savings_sweep')),
  trigger_condition JSONB NOT NULL, -- Amount, date, frequency conditions
  payment_method_id UUID REFERENCES public.payment_methods(id) NOT NULL,
  target_amount NUMERIC,
  is_active BOOLEAN DEFAULT true,
  next_execution_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add payment method references to existing tables
ALTER TABLE public.contributions 
ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES public.payment_methods(id),
ADD COLUMN IF NOT EXISTS external_transaction_id TEXT,
ADD COLUMN IF NOT EXISTS transaction_fees NUMERIC DEFAULT 0;

ALTER TABLE public.loan_repayments 
ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES public.payment_methods(id),
ADD COLUMN IF NOT EXISTS external_transaction_id TEXT,
ADD COLUMN IF NOT EXISTS transaction_fees NUMERIC DEFAULT 0;

-- Enable RLS on new tables
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automated_transaction_rules ENABLE ROW LEVEL SECURITY;

-- RLS policies for payment methods
CREATE POLICY "Users can view their own payment methods" 
  ON public.payment_methods 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own payment methods" 
  ON public.payment_methods 
  FOR ALL 
  USING (auth.uid() = user_id);

-- RLS policies for transaction notifications
CREATE POLICY "Users can view their own transaction notifications" 
  ON public.transaction_notifications 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "System can create transaction notifications" 
  ON public.transaction_notifications 
  FOR INSERT 
  WITH CHECK (true); -- Allow system to create notifications

-- RLS policies for automated transaction rules
CREATE POLICY "Users can manage their own transaction rules" 
  ON public.automated_transaction_rules 
  FOR ALL 
  USING (auth.uid() = user_id);

-- Create function to send transaction notifications
CREATE OR REPLACE FUNCTION public.create_transaction_notification(
  _user_id UUID,
  _transaction_type TEXT,
  _notification_type TEXT,
  _amount NUMERIC,
  _message TEXT,
  _group_id UUID DEFAULT NULL,
  _payment_method_id UUID DEFAULT NULL,
  _external_reference TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO public.transaction_notifications (
    user_id,
    transaction_type,
    notification_type,
    amount,
    message,
    group_id,
    payment_method_id,
    external_reference
  ) VALUES (
    _user_id,
    _transaction_type,
    _notification_type,
    _amount,
    _message,
    _group_id,
    _payment_method_id,
    _external_reference
  ) RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_type_provider ON public.payment_methods(method_type, provider);
CREATE INDEX IF NOT EXISTS idx_transaction_notifications_user_id ON public.transaction_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_notifications_status ON public.transaction_notifications(status);
CREATE INDEX IF NOT EXISTS idx_automated_rules_user_group ON public.automated_transaction_rules(user_id, group_id);
