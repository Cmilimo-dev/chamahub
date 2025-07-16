import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  ScrollView, 
  StyleSheet, 
  TouchableOpacity,
  RefreshControl,
  Alert
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import NavigationWrapper from '../components/NavigationWrapper';
import { 
  Eye, 
  EyeOff, 
  Plus, 
  TrendingUp, 
  Users, 
  CreditCard,
  ArrowUpDown,
  Bell
} from 'lucide-react-native';

const HomeScreen = ({ navigation }) => {
  const [user, setUser] = useState(null);
  const [balanceVisible, setBalanceVisible] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [stats, setStats] = useState({
    totalBalance: 125000,
    totalGroups: 3,
    recentTransactions: 12,
    pendingNotifications: 5
  });

  useEffect(() => {
    // Load user data and stats
    loadUserData();
  }, []);

  const loadUserData = async () => {
    try {
      // Simulate loading user data
      setUser({
        id: 1,
        name: 'John Doe',
        email: 'john@example.com'
      });
    } catch (error) {
      console.error('Error loading user data:', error);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadUserData();
    setRefreshing(false);
  };

  const quickActions = [
    {
      title: 'Send Money',
      icon: ArrowUpDown,
      color: '#3B82F6',
      onPress: () => navigation.navigate('PaymentsScreen')
    },
    {
      title: 'Join Group',
      icon: Users,
      color: '#10B981',
      onPress: () => navigation.navigate('GroupsScreen')
    },
    {
      title: 'Apply Loan',
      icon: CreditCard,
      color: '#F59E0B',
      onPress: () => navigation.navigate('LoansScreen')
    },
    {
      title: 'Banking',
      icon: CreditCard,
      color: '#8B5CF6',
      onPress: () => navigation.navigate('BankingScreen')
    }
  ];

  const recentActivities = [
    {
      id: 1,
      type: 'contribution',
      description: 'Monthly contribution to Tech Chama',
      amount: 5000,
      date: '2 hours ago',
      status: 'completed'
    },
    {
      id: 2,
      type: 'loan',
      description: 'Loan application approved',
      amount: 25000,
      date: '1 day ago',
      status: 'approved'
    },
    {
      id: 3,
      type: 'group',
      description: 'Joined Women Empowerment Group',
      amount: null,
      date: '3 days ago',
      status: 'active'
    }
  ];

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed':
        return '#10B981';
      case 'approved':
        return '#3B82F6';
      case 'pending':
        return '#F59E0B';
      case 'active':
        return '#8B5CF6';
      default:
        return '#6B7280';
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-KE', {
      style: 'currency',
      currency: 'KES',
      minimumFractionDigits: 0
    }).format(amount);
  };

  return (
    <NavigationWrapper currentRoute="HomeScreen">
      <ScrollView 
        style={styles.container}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Welcome Section */}
        <View style={styles.welcomeSection}>
          <Text style={styles.welcomeText}>Welcome back,</Text>
          <Text style={styles.userName}>{user?.name || 'User'}</Text>
        </View>

        {/* Balance Card */}
        <View style={styles.balanceCard}>
          <View style={styles.balanceHeader}>
            <Text style={styles.balanceLabel}>Total Balance</Text>
            <TouchableOpacity 
              onPress={() => setBalanceVisible(!balanceVisible)}
              style={styles.eyeButton}
            >
              {balanceVisible ? 
                <Eye size={20} color="#6B7280" /> : 
                <EyeOff size={20} color="#6B7280" />
              }
            </TouchableOpacity>
          </View>
          <Text style={styles.balanceAmount}>
            {balanceVisible ? formatCurrency(stats.totalBalance) : '••••••'}
          </Text>
          <Text style={styles.balanceSubtext}>
            Across {stats.totalGroups} groups
          </Text>
        </View>

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.quickActionsGrid}>
            {quickActions.map((action, index) => {
              const IconComponent = action.icon;
              return (
                <TouchableOpacity
                  key={index}
                  style={[styles.quickActionCard, { borderColor: action.color + '20' }]}
                  onPress={action.onPress}
                  activeOpacity={0.7}
                >
                  <View style={[styles.quickActionIcon, { backgroundColor: action.color + '15' }]}>
                    <IconComponent size={24} color={action.color} />
                  </View>
                  <Text style={styles.quickActionText}>{action.title}</Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Stats Overview */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Overview</Text>
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{stats.totalGroups}</Text>
              <Text style={styles.statLabel}>Active Groups</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{stats.recentTransactions}</Text>
              <Text style={styles.statLabel}>This Month</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{stats.pendingNotifications}</Text>
              <Text style={styles.statLabel}>Notifications</Text>
            </View>
          </View>
        </View>

        {/* Recent Activities */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recent Activities</Text>
          <View style={styles.activitiesContainer}>
            {recentActivities.map((activity) => (
              <View key={activity.id} style={styles.activityItem}>
                <View style={styles.activityInfo}>
                  <Text style={styles.activityDescription}>
                    {activity.description}
                  </Text>
                  <Text style={styles.activityDate}>{activity.date}</Text>
                </View>
                <View style={styles.activityRight}>
                  {activity.amount && (
                    <Text style={styles.activityAmount}>
                      {formatCurrency(activity.amount)}
                    </Text>
                  )}
                  <View style={[
                    styles.activityStatus,
                    { backgroundColor: getStatusColor(activity.status) + '20' }
                  ]}>
                    <Text style={[
                      styles.activityStatusText,
                      { color: getStatusColor(activity.status) }
                    ]}>
                      {activity.status}
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </View>
        </View>

        {/* Bottom padding for navigation */}
        <View style={styles.bottomPadding} />
      </ScrollView>
    </NavigationWrapper>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  welcomeSection: {
    padding: 20,
    backgroundColor: '#FFFFFF',
    marginBottom: 16,
  },
  welcomeText: {
    fontSize: 16,
    color: '#6B7280',
    fontWeight: '500',
  },
  userName: {
    fontSize: 24,
    fontWeight: '700',
    color: '#111827',
    marginTop: 4,
  },
  balanceCard: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 16,
    padding: 20,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 3,
  },
  balanceHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  balanceLabel: {
    fontSize: 14,
    color: '#6B7280',
    fontWeight: '500',
  },
  eyeButton: {
    padding: 4,
  },
  balanceAmount: {
    fontSize: 32,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  balanceSubtext: {
    fontSize: 14,
    color: '#6B7280',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 16,
    paddingHorizontal: 16,
  },
  quickActionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 16,
    gap: 12,
  },
  quickActionCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    width: '48%',
    borderWidth: 1,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  quickActionIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  quickActionText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    textAlign: 'center',
  },
  statsGrid: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    gap: 12,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  statValue: {
    fontSize: 24,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  activitiesContainer: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  activityItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  activityInfo: {
    flex: 1,
  },
  activityDescription: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  activityDate: {
    fontSize: 12,
    color: '#6B7280',
  },
  activityRight: {
    alignItems: 'flex-end',
  },
  activityAmount: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  activityStatus: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  activityStatusText: {
    fontSize: 12,
    fontWeight: '500',
    textTransform: 'capitalize',
  },
  bottomPadding: {
    height: 20,
  },
});

export default HomeScreen;
