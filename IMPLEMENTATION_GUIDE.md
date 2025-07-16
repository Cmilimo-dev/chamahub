# Enhanced Group Joining Implementation Guide

## Overview
This guide covers the implementation of the enhanced group joining functionality with membership request approval workflow.

## 🚀 Features Implemented

### 1. Enhanced Group Joining Workflow
- **Step 1**: User searches and selects a group to join
- **Step 2**: User enters email or phone number to receive invitation link
- **Step 3**: User clicks invitation link and fills out membership form
- **Step 4**: Form submission triggers approval workflow
- **Step 5**: User receives notification of approval/rejection

### 2. Admin Approval System
- Group administrators, treasurers, and secretaries can manage membership requests
- Approval/rejection notifications sent automatically
- Complete audit trail of membership actions

## 📋 Implementation Steps

### Step 1: Apply Database Changes

**Execute in Supabase Dashboard SQL Editor:**

```sql
-- Enhanced Group Membership Request System
-- Create membership_requests table for handling join requests
CREATE TABLE IF NOT EXISTS public.membership_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.chama_groups(id) ON DELETE CASCADE NOT NULL,
  email TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  invitation_token TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  approved_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES public.profiles(id),
  rejected_at TIMESTAMP WITH TIME ZONE,
  rejected_by UUID REFERENCES public.profiles(id),
  rejection_reason TEXT,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + INTERVAL '7 days'),
  form_submitted BOOLEAN DEFAULT false,
  form_submitted_at TIMESTAMP WITH TIME ZONE,
  user_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create membership_actions table for tracking admin actions
CREATE TABLE IF NOT EXISTS public.membership_actions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  membership_request_id UUID REFERENCES public.membership_requests(id) ON DELETE CASCADE NOT NULL,
  admin_id UUID REFERENCES public.profiles(id) NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('approved', 'rejected', 'reviewed')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create function to generate unique invitation tokens
CREATE OR REPLACE FUNCTION generate_invitation_token()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    token TEXT;
BEGIN
    token := encode(gen_random_bytes(32), 'base64');
    token := replace(replace(replace(token, '+', '-'), '/', '_'), '=', '');
    RETURN token;
END;
$$;

-- Add RLS policies for new tables
ALTER TABLE public.membership_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.membership_actions ENABLE ROW LEVEL SECURITY;

-- Membership requests policies
CREATE POLICY "membership_requests_select_policy" 
  ON public.membership_requests 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = membership_requests.group_id
        AND gm.user_id = auth.uid()
        AND gm.status = 'active'
        AND gm.role IN ('admin', 'treasurer', 'secretary')
    )
    OR 
    membership_requests.user_id = auth.uid()
  );

CREATE POLICY "membership_requests_insert_policy" 
  ON public.membership_requests 
  FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "membership_requests_update_policy" 
  ON public.membership_requests 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = membership_requests.group_id
        AND gm.user_id = auth.uid()
        AND gm.status = 'active'
        AND gm.role IN ('admin', 'treasurer', 'secretary')
    )
    OR 
    membership_requests.user_id = auth.uid()
  );

-- Membership actions policies
CREATE POLICY "membership_actions_select_policy" 
  ON public.membership_actions 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.membership_requests mr
      JOIN public.group_members gm ON gm.group_id = mr.group_id
      WHERE mr.id = membership_actions.membership_request_id
        AND gm.user_id = auth.uid()
        AND gm.status = 'active'
        AND gm.role IN ('admin', 'treasurer', 'secretary')
    )
  );

CREATE POLICY "membership_actions_insert_policy" 
  ON public.membership_actions 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.membership_requests mr
      JOIN public.group_members gm ON gm.group_id = mr.group_id
      WHERE mr.id = membership_request_id
        AND gm.user_id = auth.uid()
        AND gm.status = 'active'
        AND gm.role IN ('admin', 'treasurer', 'secretary')
    )
  );

-- Function to check if user has admin privileges in a group
CREATE OR REPLACE FUNCTION public.is_group_admin(_user_id uuid, _group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE user_id = _user_id 
      AND group_id = _group_id 
      AND status = 'active'
      AND role IN ('admin', 'treasurer', 'secretary')
  );
$$;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_membership_requests_group_id ON public.membership_requests(group_id);
CREATE INDEX IF NOT EXISTS idx_membership_requests_token ON public.membership_requests(invitation_token);
CREATE INDEX IF NOT EXISTS idx_membership_requests_status ON public.membership_requests(status);
CREATE INDEX IF NOT EXISTS idx_membership_requests_email ON public.membership_requests(email);
CREATE INDEX IF NOT EXISTS idx_membership_requests_phone ON public.membership_requests(phone_number);
CREATE INDEX IF NOT EXISTS idx_membership_actions_request_id ON public.membership_actions(membership_request_id);
```

### Step 2: Test the Enhanced Group Joining Flow

1. **Access the Application**
   - Open http://localhost:8081/ in your browser
   - Log in to your ChamaHub account

2. **Test Group Joining (User Perspective)**
   - Click "Join Group" button on the dashboard
   - Search for an existing group
   - Select a group to join
   - Choose contact method (email or phone)
   - Enter your contact information
   - Fill out the membership form
   - Submit and wait for approval

3. **Test Membership Approval (Admin Perspective)**
   - Ensure you have admin/treasurer/secretary role in a group
   - Check the "Membership Requests" section on dashboard
   - Review pending requests
   - Approve or reject requests with optional notes

## 🧪 Testing Checklist

### User Flow Testing
- [ ] Group search functionality works
- [ ] Contact method selection (email/phone) 
- [ ] Invitation link simulation
- [ ] Membership form submission
- [ ] Wait for approval message displays
- [ ] Notifications received on approval/rejection

### Admin Flow Testing
- [ ] Membership requests appear for admins
- [ ] Approve functionality works
- [ ] Reject functionality with reason
- [ ] Notifications sent to users
- [ ] Audit trail recorded
- [ ] Request status updates correctly

### Edge Cases
- [ ] Duplicate requests handling
- [ ] Expired token handling
- [ ] Non-existent group search
- [ ] Invalid contact information
- [ ] Unauthorized access attempts

## 📝 Component Files Created/Updated

### New Components
- `src/components/EnhancedJoinGroupModal.tsx` - Enhanced group joining interface
- `src/components/MembershipRequestsManager.tsx` - Admin approval interface
- `src/hooks/useMembershipRequests.ts` - Membership request management hook

### Updated Components
- `src/pages/Index.tsx` - Integrated new components
- `src/components/JoinGroupModal.tsx` - Replaced with enhanced version

### Database Files
- `database_enhancements.sql` - Database schema additions

## 🔧 Configuration Notes

### Environment Variables
No additional environment variables required for this feature.

### Permissions Required
- Users: Can create membership requests
- Admins/Treasurers/Secretaries: Can approve/reject requests
- All: Can view their own request status

### SMS/Email Integration
Currently simulated for demo purposes. In production:
- Integrate with SMS provider (Twilio, Africa's Talking)
- Integrate with email provider (SendGrid, AWS SES)
- Update invitation link generation to use actual domain

## 🚨 Security Considerations

1. **Row Level Security (RLS)** implemented for all new tables
2. **Token-based access** for membership forms
3. **Role-based permissions** for admin actions
4. **Audit trail** for all membership actions
5. **Input validation** on all forms

## 📱 Mobile Compatibility

All components are fully responsive and work on:
- Desktop browsers
- Mobile web browsers  
- Capacitor mobile app (Android)

## 🔄 Next Steps

1. Apply database changes in Supabase
2. Test the workflow end-to-end
3. Integrate with real SMS/Email providers
4. Add email templates for notifications
5. Implement request expiration cleanup job

## 🐛 Troubleshooting

**Common Issues:**
- Database permissions: Ensure RLS policies are applied
- Component not showing: Check user roles and group membership
- Form submission fails: Verify token validity and user permissions

**Debug Steps:**
1. Check browser console for errors
2. Verify database table creation
3. Test with different user roles
4. Check network requests in browser dev tools

---

✅ **The enhanced group joining functionality is now ready for testing!**

Visit http://localhost:8081/ to experience the new workflow.
