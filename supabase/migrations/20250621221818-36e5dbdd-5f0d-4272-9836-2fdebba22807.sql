
-- Fix the foreign key relationship between loans and profiles
-- Check if primary key exists before adding it
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'profiles_pkey' 
        AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);
    END IF;
END $$;

-- Update the loans table foreign key to reference profiles instead of auth.users directly
ALTER TABLE public.loans 
DROP CONSTRAINT IF EXISTS loans_borrower_id_fkey;

ALTER TABLE public.loans 
ADD CONSTRAINT loans_borrower_id_fkey 
FOREIGN KEY (borrower_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Ensure we have proper RLS policies for the profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for profiles if it doesn't exist
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" 
  ON public.profiles 
  FOR SELECT 
  USING (true);

-- Update loans RLS policies to work with the new foreign key
DROP POLICY IF EXISTS "loans_select_policy" ON public.loans;
CREATE POLICY "loans_select_policy" 
  ON public.loans 
  FOR SELECT 
  USING (
    borrower_id = auth.uid() OR 
    public.is_group_member(auth.uid(), group_id)
  );

DROP POLICY IF EXISTS "loans_insert_policy" ON public.loans;
CREATE POLICY "loans_insert_policy" 
  ON public.loans 
  FOR INSERT 
  WITH CHECK (
    borrower_id = auth.uid() AND 
    public.is_group_member(auth.uid(), group_id)
  );
