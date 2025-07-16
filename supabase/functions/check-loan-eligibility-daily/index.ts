
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const handler = async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    console.log('Starting daily loan eligibility check...');

    // Get all active group members
    const { data: members, error: membersError } = await supabase
      .from('group_members')
      .select(`
        user_id,
        group_id,
        chama_groups(name)
      `)
      .eq('status', 'active');

    if (membersError) {
      throw membersError;
    }

    let eligibilityChecked = 0;
    let notificationsSent = 0;

    for (const member of members) {
      try {
        // Check eligibility for each member
        const { data: eligibilityData, error: eligibilityError } = await supabase.rpc('calculate_loan_eligibility', {
          _user_id: member.user_id,
          _group_id: member.group_id
        });

        if (eligibilityError) {
          console.error(`Error checking eligibility for user ${member.user_id}:`, eligibilityError);
          continue;
        }

        const eligibility = eligibilityData[0];
        eligibilityChecked++;

        // Check if user wasn't eligible before but is now eligible
        const { data: lastNotification } = await supabase
          .from('notifications')
          .select('created_at')
          .eq('user_id', member.user_id)
          .eq('notification_type', 'loan_eligibility')
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()) // Within last 7 days
          .order('created_at', { ascending: false })
          .limit(1);

        // Only send notification if eligible and hasn't received one recently
        if (eligibility.is_eligible && (!lastNotification || lastNotification.length === 0)) {
          // Send notification
          const notificationResponse = await supabase.functions.invoke('send-notifications', {
            body: {
              userId: member.user_id,
              title: 'You\'re Eligible for a Loan!',
              message: `Great news! You're now eligible for a loan of up to KES ${eligibility.max_loan_amount.toLocaleString()} in ${member.chama_groups.name}. ${eligibility.eligibility_reasons.join('. ')}`,
              notificationType: 'loan_eligibility',
              channels: ['email', 'in_app'],
              groupId: member.group_id,
              metadata: {
                maxLoanAmount: eligibility.max_loan_amount,
                reasons: eligibility.eligibility_reasons
              }
            }
          });

          if (notificationResponse.error) {
            console.error(`Error sending notification to user ${member.user_id}:`, notificationResponse.error);
          } else {
            notificationsSent++;
          }
        }
      } catch (error) {
        console.error(`Error processing member ${member.user_id}:`, error);
      }
    }

    console.log(`Daily eligibility check completed. Checked: ${eligibilityChecked}, Notifications sent: ${notificationsSent}`);

    return new Response(JSON.stringify({ 
      success: true,
      eligibilityChecked,
      notificationsSent
    }), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });
  } catch (error) {
    console.error('Error in check-loan-eligibility-daily function:', error);
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
