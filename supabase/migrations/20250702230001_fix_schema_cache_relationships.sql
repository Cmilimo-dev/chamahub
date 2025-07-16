-- Fix schema cache relationship issue between group_members and chama_groups

-- Refresh foreign key constraints to update schema cache
DO $$
BEGIN
    -- Drop and recreate group_id foreign key constraint
    ALTER TABLE public.group_members DROP CONSTRAINT IF EXISTS group_members_group_id_fkey;
    ALTER TABLE public.group_members 
    ADD CONSTRAINT group_members_group_id_fkey 
    FOREIGN KEY (group_id) REFERENCES public.chama_groups(id) ON DELETE CASCADE;
    
    -- Ensure user_id foreign key exists
    ALTER TABLE public.group_members DROP CONSTRAINT IF EXISTS group_members_user_id_fkey;
    ALTER TABLE public.group_members 
    ADD CONSTRAINT group_members_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    
    RAISE NOTICE 'Foreign key constraints refreshed for schema cache';
END $$;

-- Update table statistics to refresh schema cache
ANALYZE public.group_members;
ANALYZE public.chama_groups;
