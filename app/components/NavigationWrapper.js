import React, { useState } from 'react';
import { View, StyleSheet, SafeAreaView, StatusBar, Platform } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import MobileNavigation from './MobileNavigation';
import TopNavigation from './TopNavigation';
import SideMenu from './SideMenu';

const NavigationWrapper = ({ 
  children, 
  currentRoute, 
  showBottomNav = true, 
  showTopNav = true,
  containerStyle = {}
}) => {
  const [sideMenuVisible, setSideMenuVisible] = useState(false);

  const handleMenuPress = () => {
    setSideMenuVisible(true);
  };

  const handleNotificationPress = () => {
    // Navigate to notifications screen
    console.log('Notification pressed');
  };

  const handleCloseSideMenu = () => {
    setSideMenuVisible(false);
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar 
        barStyle="dark-content" 
        backgroundColor="#FFFFFF" 
        translucent={false}
      />
      
      {/* Top Navigation */}
      {showTopNav && (
        <TopNavigation
          currentRoute={currentRoute}
          onMenuPress={handleMenuPress}
          onNotificationPress={handleNotificationPress}
        />
      )}

      {/* Main Content */}
      <View style={[styles.content, containerStyle]}>
        {children}
      </View>

      {/* Bottom Navigation */}
      {showBottomNav && (
        <MobileNavigation currentRoute={currentRoute} />
      )}

      {/* Side Menu Overlay */}
      {sideMenuVisible && (
        <SideMenu
          visible={sideMenuVisible}
          onClose={handleCloseSideMenu}
          currentRoute={currentRoute}
        />
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  content: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
});

export default NavigationWrapper;
