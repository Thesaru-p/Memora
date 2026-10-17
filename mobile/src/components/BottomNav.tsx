import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { colors } from '../theme';

export type PrimaryScreen = 'DASHBOARD' | 'UPLOAD' | 'ANALYTICS' | 'GRAPH';

interface Props {
  current: PrimaryScreen;
  onSelect: (screen: PrimaryScreen) => void;
}

const items: Array<{ screen: PrimaryScreen; icon: string; label: string }> = [
  { screen: 'DASHBOARD', icon: '⌂', label: 'Home' },
  { screen: 'UPLOAD', icon: '▣', label: 'Learning' },
  { screen: 'ANALYTICS', icon: '▥', label: 'Progress' },
  { screen: 'GRAPH', icon: '◉', label: 'Graph' },
];

export const BottomNav: React.FC<Props> = ({ current, onSelect }) => (
  <View style={styles.container}>
    {items.map((item) => {
      const active = item.screen === current;
      return (
        <TouchableOpacity
          key={item.screen}
          accessibilityRole="button"
          accessibilityState={{ selected: active }}
          style={[styles.item, active && styles.itemActive]}
          onPress={() => onSelect(item.screen)}
        >
          <Text style={[styles.icon, active && styles.textActive]}>{item.icon}</Text>
          <Text style={[styles.label, active && styles.textActive]}>{item.label}</Text>
        </TouchableOpacity>
      );
    })}
  </View>
);

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: colors.surfaceBlueStrong,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  item: { flex: 1, alignItems: 'center', paddingVertical: 7, borderRadius: 12 },
  itemActive: { backgroundColor: '#C8E8FA' },
  icon: { color: colors.muted, fontSize: 19, lineHeight: 21 },
  label: { color: colors.muted, fontSize: 10, fontWeight: '700', marginTop: 2 },
  textActive: { color: colors.primaryDark },
});
