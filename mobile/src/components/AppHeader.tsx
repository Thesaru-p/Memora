import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors } from '../theme';

interface Props {
  streakDays?: number;
}

export const AppHeader: React.FC<Props> = ({ streakDays = 0 }) => (
  <View style={styles.header}>
    <View style={styles.brandRow}>
      <View style={styles.logo} />
      <Text style={styles.brand}>Memora</Text>
    </View>
    <View style={styles.metaRow}>
      <Text style={styles.menu}>☰  Menu</Text>
      <Text style={styles.streak}>🔥 {streakDays} days</Text>
    </View>
  </View>
);

const styles = StyleSheet.create({
  header: {
    backgroundColor: colors.surfaceBlueStrong,
    borderRadius: 20,
    paddingHorizontal: 18,
    paddingVertical: 16,
    marginBottom: 18,
  },
  brandRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 12 },
  logo: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: colors.text,
    marginRight: 9,
  },
  brand: { color: colors.text, fontSize: 18, fontWeight: '800' },
  metaRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  menu: { color: colors.primaryDark, fontSize: 12, fontWeight: '700' },
  streak: { color: colors.text, fontSize: 12, fontWeight: '700' },
});
