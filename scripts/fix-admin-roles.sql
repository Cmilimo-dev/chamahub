-- Fix Admin Roles Script for ChamaHub
-- This script ensures proper admin role assignment

-- 1. First, let's see current group membership status
SELECT 
    cg.name as group_name,
    gm.user_id,
    p.email,
    p.full_name,
    gm.role,
    gm.status,
    cg.created_by,
    CASE 
        WHEN cg.created_by = gm.user_id THEN 'Creator'
        ELSE 'Member'
    END as is_creator
FROM chama_groups cg
JOIN group_members gm ON cg.id = gm.group_id
JOIN profiles p ON gm.user_id = p.id
ORDER BY cg.name, gm.role;

-- 2. Update all group creators to be admins
UPDATE group_members 
SET role = 'admin'
WHERE user_id IN (
    SELECT created_by 
    FROM chama_groups 
    WHERE created_by = group_members.user_id
    AND group_id IN (
        SELECT id FROM chama_groups WHERE created_by = group_members.user_id
    )
);

-- 3. Ensure group creators have active membership status
UPDATE group_members 
SET status = 'active'
WHERE user_id IN (
    SELECT created_by 
    FROM chama_groups 
    WHERE created_by = group_members.user_id
    AND group_id IN (
        SELECT id FROM chama_groups WHERE created_by = group_members.user_id
    )
);

-- 4. If you want to make a specific user admin of all groups (replace with your user ID)
-- First, find your user ID:
SELECT id, email, full_name FROM profiles WHERE email ILIKE '%your-email%';

-- Then uncomment and run this with your actual user ID:
-- UPDATE group_members 
-- SET role = 'admin', status = 'active'
-- WHERE user_id = 'your-user-id-here';

-- 5. Verify the changes
SELECT 
    cg.name as group_name,
    gm.user_id,
    p.email,
    p.full_name,
    gm.role,
    gm.status,
    cg.created_by,
    CASE 
        WHEN cg.created_by = gm.user_id THEN 'Creator (Should be Admin)'
        ELSE 'Member'
    END as creator_status
FROM chama_groups cg
JOIN group_members gm ON cg.id = gm.group_id
JOIN profiles p ON gm.user_id = p.id
ORDER BY cg.name, gm.role;
