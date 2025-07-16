
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "npm:resend@2.0.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface NotificationRequest {
  userId: string;
  title: string;
  message: string;
  notificationType: 'loan_eligibility' | 'contribution_reminder' | 'loan_status_update' | 'member_loan_announcement' | 'general';
  channels: ('email' | 'sms' | 'in_app')[];
  groupId?: string;
  metadata?: Record<string, any>;
}

const handler = async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const resend = new Resend(Deno.env.get('RESEND_API_KEY'));

    const notificationData: NotificationRequest = await req.json();

    // Get user profile and preferences
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', notificationData.userId)
      .single();

    if (profileError) {
      console.error('Error fetching user profile:', profileError);
      throw profileError;
    }

    const preferences = profile.notification_preferences || {};
    const enabledChannels = notificationData.channels.filter(channel => {
      switch (channel) {
        case 'email':
          return preferences.email_enabled && preferences[`${notificationData.notificationType}_alerts`] !== false;
        case 'sms':
          return preferences.sms_enabled && preferences[`${notificationData.notificationType}_alerts`] !== false;
        case 'in_app':
          return preferences.in_app_enabled;
        default:
          return false;
      }
    });

    // Create in-app notification
    if (enabledChannels.includes('in_app')) {
      const { error: notifError } = await supabase
        .from('notifications')
        .insert({
          user_id: notificationData.userId,
          title: notificationData.title,
          message: notificationData.message,
          notification_type: notificationData.notificationType,
          channels: enabledChannels,
          group_id: notificationData.groupId,
          metadata: notificationData.metadata || {}
        });

      if (notifError) {
        console.error('Error creating in-app notification:', notifError);
      }
    }

    // Send email notification
    if (enabledChannels.includes('email') && profile.email) {
      try {
        await resend.emails.send({
          from: 'Chama Savings <notifications@resend.dev>',
          to: [profile.email],
          subject: notificationData.title,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #16a34a;">${notificationData.title}</h2>
              <p>${notificationData.message}</p>
              <p style="color: #666; font-size: 14px; margin-top: 20px;">
                This notification was sent from your Chama Savings account.
              </p>
            </div>
          `,
        });
        console.log('Email sent successfully to:', profile.email);
      } catch (emailError) {
        console.error('Error sending email:', emailError);
      }
    }

    // Send SMS notification (Twilio integration would go here)
    if (enabledChannels.includes('sms') && profile.phone_number) {
      // TODO: Implement Twilio SMS sending
      console.log('SMS sending not implemented yet for:', profile.phone_number);
    }

    return new Response(JSON.stringify({ 
      success: true, 
      channelsSent: enabledChannels 
    }), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });
  } catch (error) {
    console.error('Error in send-notifications function:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  }
};

serve(handler);
