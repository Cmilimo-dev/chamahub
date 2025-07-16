import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Dimensions } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { 
  Home, 
  CreditCard, 
  ArrowUpDown, 
  Users, 
  Banknote,
  Circle
} from 'lucide-react-native';

const { width } = Dimensions.get('window');

const MobileNavigation = ({ currentRoute }) => {
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
      <View style={styles.navigationBar}>
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
                  size={24}
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
                {isActive && (
                  <View style={[styles.activeIndicator, { backgroundColor: tab.color }]} />
                )}
              </View>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: -2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 8,
  },
  navigationBar: {
    flexDirection: 'row',
    paddingVertical: 8,
    paddingHorizontal: 4,
    backgroundColor: '#FFFFFF',
  },
  tabButton: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
    borderRadius: 12,
    marginHorizontal: 2,
    position: 'relative',
  },
  tabContent: {
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  tabLabel: {
    fontSize: 11,
    fontWeight: '500',
    marginTop: 4,
    textAlign: 'center',
  },
  activeTabLabel: {
    fontWeight: '600',
  },
  activeIndicator: {
    position: 'absolute',
    top: -2,
    width: 4,
    height: 4,
    borderRadius: 2,
  },
});

export default MobileNavigation;
