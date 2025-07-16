-- Auto Admin Assignment Trigger for ChamaHub
-- This ensures that anyone who creates a group is automatically assigned as admin

-- First, create a function that will handle the auto-assignment
CREATE OR REPLACE FUNCTION assign_creator_as_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert the group creator as an admin member
    INSERT INTO group_members (
        group_id, 
        user_id, 
        role, 
        status, 
        joined_at, 
        invited_by,
        invitation_accepted_at
    ) VALUES (
        NEW.id, 
        NEW.created_by, 
        'admin', 
        'active', 
        NOW(), 
        NEW.created_by,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_assign_creator_as_admin ON chama_groups;
CREATE TRIGGER trigger_assign_creator_as_admin
    AFTER INSERT ON chama_groups
    FOR EACH ROW
    EXECUTE FUNCTION assign_creator_as_admin();

-- Also create a function to ensure role updates maintain at least one admin
CREATE OR REPLACE FUNCTION ensure_admin_exists()
RETURNS TRIGGER AS $$
DECLARE
    admin_count INTEGER;
BEGIN
    -- Count remaining admins after this potential change
    SELECT COUNT(*) INTO admin_count
    FROM group_members 
    WHERE group_id = COALESCE(NEW.group_id, OLD.group_id) 
    AND role = 'admin' 
    AND status = 'active'
    AND user_id != COALESCE(OLD.user_id, NEW.user_id);
    
    -- If this would be the last admin being changed/removed, prevent it
    IF (OLD.role = 'admin' AND OLD.status = 'active') AND 
       (NEW IS NULL OR NEW.role != 'admin' OR NEW.status != 'active') AND 
       admin_count = 0 THEN
        RAISE EXCEPTION 'Cannot remove the last admin from a group. At least one admin must remain.';
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger to ensure at least one admin always exists
DROP TRIGGER IF EXISTS trigger_ensure_admin_exists ON group_members;
CREATE TRIGGER trigger_ensure_admin_exists
    BEFORE UPDATE OR DELETE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION ensure_admin_exists();

-- Test the triggers (optional - you can run these to verify they work)
-- SELECT 'Triggers created successfully!' as status;
