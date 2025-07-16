import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Dimensions } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { 
  Home, 
  CreditCard, 
  ArrowUpDown, 
  Users, 
  Banknote,
  Menu,
  Bell
} from 'lucide-react-native';

const { width } = Dimensions.get('window');

const TopNavigation = ({ currentRoute, onMenuPress, onNotificationPress }) => {
  const navigation = useNavigation();

  const navigationTabs = [
    {
      name: 'Home',
      icon: Home,
      route: 'HomeScreen',
      color: '#3B82F6'
    },
    {
      name: 'Banking',
      icon: CreditCard,
      route: 'BankingScreen',
      color: '#10B981'
    },
    {
      name: 'Payments',
      icon: ArrowUpDown,
      route: 'PaymentsScreen',
      color: '#F59E0B'
    },
    {
      name: 'Groups',
      icon: Users,
      route: 'GroupsScreen',
      color: '#8B5CF6'
    },
    {
      name: 'Loans',
      icon: Banknote,
      route: 'LoansScreen',
      color: '#EF4444'
    }
  ];

  const handleTabPress = (route) => {
    navigation.navigate(route);
  };

  return (
    <View style={styles.container}>
      {/* Header with menu and notifications */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.menuButton}
          onPress={onMenuPress}
          activeOpacity={0.7}
        >
          <Menu size={24} color="#374151" />
        </TouchableOpacity>
        
        <Text style={styles.title}>ChamaHub</Text>
        
        <TouchableOpacity
          style={styles.notificationButton}
          onPress={onNotificationPress}
          activeOpacity={0.7}
        >
          <Bell size={24} color="#374151" />
          {/* Notification badge */}
          <View style={styles.notificationBadge}>
            <Text style={styles.badgeText}>3</Text>
          </View>
        </TouchableOpacity>
      </View>

      {/* Horizontal navigation tabs */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.tabsContainer}
        style={styles.tabsScrollView}
      >
        {navigationTabs.map((tab, index) => {
          const isActive = currentRoute === tab.route;
          const IconComponent = tab.icon;
          
          return (
            <TouchableOpacity
              key={index}
              style={[
                styles.tabButton,
                isActive && { backgroundColor: tab.color + '15' }
              ]}
              onPress={() => handleTabPress(tab.route)}
              activeOpacity={0.7}
            >
              <View style={styles.tabContent}>
                <IconComponent
                  size={20}
                  color={isActive ? tab.color : '#6B7280'}
                  strokeWidth={isActive ? 2.5 : 2}
                />
                <Text style={[
                  styles.tabLabel,
                  { color: isActive ? tab.color : '#6B7280' },
                  isActive && styles.activeTabLabel
                ]}>
                  {tab.name}
                </Text>
              </View>
              {isActive && (
                <View style={[styles.activeIndicator, { backgroundColor: tab.color }]} />
              )}
            </TouchableOpacity>
          );
        })}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 8,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    paddingTop: 16,
  },
  menuButton: {
    padding: 8,
    borderRadius: 8,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
  },
  notificationButton: {
    padding: 8,
    borderRadius: 8,
    position: 'relative',
  },
  notificationBadge: {
    position: 'absolute',
    top: 4,
    right: 4,
    backgroundColor: '#EF4444',
    borderRadius: 8,
    minWidth: 16,
    height: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 10,
    fontWeight: '600',
  },
  tabsScrollView: {
    maxHeight: 60,
  },
  tabsContainer: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  tabButton: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginHorizontal: 4,
    position: 'relative',
    minWidth: 80,
  },
  tabContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabLabel: {
    fontSize: 13,
    fontWeight: '500',
    marginLeft: 6,
    textAlign: 'center',
  },
  activeTabLabel: {
    fontWeight: '600',
  },
  activeIndicator: {
    position: 'absolute',
    bottom: -2,
    left: '50%',
    marginLeft: -12,
    width: 24,
    height: 3,
    borderRadius: 1.5,
  },
});

export default TopNavigation;
