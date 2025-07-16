import React from 'react';
import { 
  View, 
  Text, 
  TouchableOpacity, 
  StyleSheet, 
  Modal, 
  Dimensions,
  ScrollView,
  SafeAreaView
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { 
  Home, 
  CreditCard, 
  ArrowUpDown, 
  Users, 
  Banknote,
  Settings,
  User,
  HelpCircle,
  LogOut,
  X
} from 'lucide-react-native';

const { width, height } = Dimensions.get('window');

const SideMenu = ({ visible, onClose, currentRoute }) => {
  const navigation = useNavigation();

  const menuItems = [
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
    },
    { divider: true },
    {
      name: 'Profile',
      icon: User,
      route: 'ProfileScreen',
      color: '#6B7280'
    },
    {
      name: 'Settings',
      icon: Settings,
      route: 'SettingsScreen',
      color: '#6B7280'
    },
    {
      name: 'Help & Support',
      icon: HelpCircle,
      route: 'HelpScreen',
      color: '#6B7280'
    },
    { divider: true },
    {
      name: 'Logout',
      icon: LogOut,
      action: 'logout',
      color: '#EF4444'
    }
  ];

  const handleItemPress = (item) => {
    if (item.action === 'logout') {
      // Handle logout
      console.log('Logout pressed');
    } else if (item.route) {
      navigation.navigate(item.route);
    }
    onClose();
  };

  return (
    <Modal
      visible={visible}
      transparent={true}
      animationType="slide"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <TouchableOpacity
          style={styles.backdrop}
          onPress={onClose}
          activeOpacity={1}
        />
        
        <View style={styles.menuContainer}>
          <SafeAreaView style={styles.safeArea}>
            {/* Header */}
            <View style={styles.header}>
              <Text style={styles.headerTitle}>Menu</Text>
              <TouchableOpacity
                style={styles.closeButton}
                onPress={onClose}
                activeOpacity={0.7}
              >
                <X size={24} color="#6B7280" />
              </TouchableOpacity>
            </View>

            {/* Menu Items */}
            <ScrollView style={styles.menuList}>
              {menuItems.map((item, index) => {
                if (item.divider) {
                  return <View key={index} style={styles.divider} />;
                }

                const isActive = currentRoute === item.route;
                const IconComponent = item.icon;

                return (
                  <TouchableOpacity
                    key={index}
                    style={[
                      styles.menuItem,
                      isActive && { backgroundColor: item.color + '15' }
                    ]}
                    onPress={() => handleItemPress(item)}
                    activeOpacity={0.7}
                  >
                    <IconComponent
                      size={20}
                      color={isActive ? item.color : '#6B7280'}
                      strokeWidth={isActive ? 2.5 : 2}
                    />
                    <Text style={[
                      styles.menuItemText,
                      { color: isActive ? item.color : '#374151' },
                      isActive && styles.activeMenuItemText
                    ]}>
                      {item.name}
                    </Text>
                    {isActive && (
                      <View style={[styles.activeIndicator, { backgroundColor: item.color }]} />
                    )}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>

            {/* Footer */}
            <View style={styles.footer}>
              <Text style={styles.footerText}>ChamaHub v1.0</Text>
            </View>
          </SafeAreaView>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    flexDirection: 'row',
  },
  backdrop: {
    flex: 1,
  },
  menuContainer: {
    width: width * 0.8,
    maxWidth: 300,
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 10,
  },
  safeArea: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
  },
  closeButton: {
    padding: 4,
  },
  menuList: {
    flex: 1,
    paddingTop: 8,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    position: 'relative',
  },
  menuItemText: {
    fontSize: 16,
    fontWeight: '500',
    marginLeft: 12,
    flex: 1,
  },
  activeMenuItemText: {
    fontWeight: '600',
  },
  activeIndicator: {
    position: 'absolute',
    left: 0,
    top: '50%',
    marginTop: -12,
    width: 4,
    height: 24,
    borderRadius: 2,
  },
  divider: {
    height: 1,
    backgroundColor: '#E5E7EB',
    marginVertical: 8,
    marginHorizontal: 20,
  },
  footer: {
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: '#9CA3AF',
    fontWeight: '500',
  },
});

export default SideMenu;
