-- SIMPLE ADMIN FIX - Run this in Supabase SQL Editor

-- 1. Make all group creators admins
UPDATE group_members 
SET role = 'admin', status = 'active'
WHERE user_id IN (
    SELECT cg.created_by 
    FROM chama_groups cg
    WHERE cg.id = group_members.group_id
    AND cg.created_by = group_members.user_id
);

-- 2. Create function to auto-assign group creators as admins for future groups
CREATE OR REPLACE FUNCTION assign_creator_as_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if creator is already a member
    IF NOT EXISTS (
        SELECT 1 FROM group_members 
        WHERE group_id = NEW.id AND user_id = NEW.created_by
    ) THEN
        -- Insert the group creator as an admin member
        INSERT INTO group_members (
            group_id, 
            user_id, 
            role, 
            status, 
            joined_at
        ) VALUES (
            NEW.id, 
            NEW.created_by, 
            'admin', 
            'active', 
            NOW()
        );
    ELSE
        -- Update existing membership to admin
        UPDATE group_members 
        SET role = 'admin', status = 'active'
        WHERE group_id = NEW.id AND user_id = NEW.created_by;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create the trigger
DROP TRIGGER IF EXISTS trigger_assign_creator_as_admin ON chama_groups;
CREATE TRIGGER trigger_assign_creator_as_admin
    AFTER INSERT ON chama_groups
    FOR EACH ROW
    EXECUTE FUNCTION assign_creator_as_admin();

-- 4. Simple verification (just show group and role info)
SELECT 
    cg.name as group_name,
    gm.role,
    gm.status,
    CASE 
        WHEN cg.created_by = gm.user_id THEN 'Creator'
        ELSE 'Member'
    END as is_creator
FROM chama_groups cg
JOIN group_members gm ON cg.id = gm.group_id
ORDER BY cg.name, gm.role;
