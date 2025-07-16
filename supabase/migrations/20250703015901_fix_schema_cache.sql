-- Migration: Fix schema cache issue for group_members and chama_groups relationship
-- This ensures the foreign key relationship is properly recognized by Supabase

-- Refresh the foreign key constraint to update schema cache
DO $$
BEGIN
    -- Check if the constraint exists and recreate it
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'group_members' 
        AND constraint_name = 'group_members_group_id_fkey'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.group_members DROP CONSTRAINT group_members_group_id_fkey;
    END IF;
    
    -- Recreate the foreign key constraint
    ALTER TABLE public.group_members 
    ADD CONSTRAINT group_members_group_id_fkey 
    FOREIGN KEY (group_id) REFERENCES public.chama_groups(id) ON DELETE CASCADE;
    
    -- Update statistics to refresh cache
    ANALYZE public.group_members;
    ANALYZE public.chama_groups;
    
    RAISE NOTICE 'Schema cache refreshed for group_members and chama_groups relationship';
END $$;

-- Create a simple function that uses the relationship to validate it works
CREATE OR REPLACE FUNCTION public.validate_group_member_relationship()
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- This function will fail if the relationship doesn't exist
    PERFORM 1 FROM public.group_members gm 
    JOIN public.chama_groups cg ON gm.group_id = cg.id 
    LIMIT 1;
    
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$;

-- Also ensure user_id foreign key exists
DO $$
BEGIN
    -- Check if user_id foreign key exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'group_members' 
        AND constraint_name = 'group_members_user_id_fkey'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.group_members 
        ADD CONSTRAINT group_members_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Added missing user_id foreign key constraint';
    END IF;
END $$;

-- Test the relationship
SELECT public.validate_group_member_relationship() as relationship_valid;
