import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, RefreshControl } from 'react-native';
import { api } from '../api/client';
import { DashboardData } from '../types';

interface Props {
  onStartQuiz: () => void;
  onOpenUpload: () => void;
  onOpenGraph: () => void;
  onOpenAnalytics: () => void;
}

export const DashboardScreen: React.FC<Props> = ({
  onStartQuiz,
  onOpenUpload,
  onOpenGraph,
  onOpenAnalytics,
}) => {
  const [data, setData] = useState<DashboardData | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = async () => {
    try {
      const res = await api.getDashboard('Computer Networks');
      setData(res);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#6366F1" />}
    >
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.appTitle}>MEMORA</Text>
          <Text style={styles.subtitle}>Ebbinghaus Retention System</Text>
        </View>
        <View style={styles.streakBadge}>
          <Text style={styles.streakText}>🔥 {data?.study_streak_days || 3} Days</Text>
        </View>
      </View>

      {/* Course / Subject Selector Card */}
      <View style={styles.subjectCard}>
        <Text style={styles.courseCode}>{data?.code || 'CS-301'}</Text>
        <Text style={styles.subjectTitle}>{data?.subject_name || 'Computer Networks'}</Text>
        <Text style={styles.subjectMeta}>{data?.active_concepts_count || 4} concepts active in knowledge graph</Text>
      </View>

      {/* Retention Health Dial */}
      <View style={styles.retentionCard}>
        <Text style={styles.cardHeader}>MEMORY RETENTION HEALTH</Text>
        <View style={styles.dialContainer}>
          <Text style={styles.dialPercentage}>{data?.overall_retention_pct || 82.5}%</Text>
          <Text style={styles.dialLabel}>Estimated Recall Probability</Text>
        </View>
        <View style={styles.healthBar}>
          <View style={[styles.healthFill, { width: `${data?.overall_retention_pct || 82}%` }]} />
        </View>
        <Text style={styles.healthNote}>
          Target: &gt;80% • Keep reviewing daily to flatten the forgetting cliff!
        </Text>
      </View>

      {/* Action: Day-1 Micro Quiz Banner */}
      <View style={styles.quizAlertCard}>
        <View style={styles.alertHeader}>
          <Text style={styles.badgeUrgent}>24H REVIEW DUE</Text>
          <Text style={styles.quizDuration}>⚡ 3-4 mins</Text>
        </View>
        <Text style={styles.quizPromptTitle}>Refresh: {data?.next_quiz_topic || 'Subnet Masks & ANDing'}</Text>
        <Text style={styles.quizPromptDesc}>
          Take a 4-question micro-quiz now to stop the 50% Day-1 memory decay.
        </Text>
        <TouchableOpacity style={styles.quizStartBtn} onPress={onStartQuiz}>
          <Text style={styles.quizStartBtnText}>Start 3-Min Micro-Quiz</Text>
        </TouchableOpacity>
      </View>

      {/* Quick Navigation Tiles */}
      <View style={styles.grid}>
        <TouchableOpacity style={styles.tile} onPress={onOpenUpload}>
          <Text style={styles.tileIcon}>📸</Text>
          <Text style={styles.tileTitle}>Upload Notes</Text>
          <Text style={styles.tileDesc}>Slide photos or text</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.tile} onPress={onOpenGraph}>
          <Text style={styles.tileIcon}>🕸️</Text>
          <Text style={styles.tileTitle}>Knowledge Graph</Text>
          <Text style={styles.tileDesc}>View concept map</Text>
        </TouchableOpacity>

        <TouchableOpacity style={[styles.tile, { width: '100%', marginTop: 12 }]} onPress={onOpenAnalytics}>
          <Text style={styles.tileIcon}>📈</Text>
          <Text style={styles.tileTitle}>Memory & Performance Analytics</Text>
          <Text style={styles.tileDesc}>View Ebbinghaus decay curve & test score history</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 32, marginBottom: 16 },
  appTitle: { fontSize: 24, fontWeight: '900', color: '#6366F1', letterSpacing: 1.5 },
  subtitle: { fontSize: 13, color: '#94A3B8' },
  streakBadge: { backgroundColor: '#1E1B4B', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20, borderWidth: 1, borderColor: '#4F46E5' },
  streakText: { color: '#F59E0B', fontWeight: '700', fontSize: 13 },
  subjectCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 16, marginBottom: 16, borderLeftWidth: 4, borderLeftColor: '#6366F1' },
  courseCode: { fontSize: 11, fontWeight: '700', color: '#818CF8', letterSpacing: 1 },
  subjectTitle: { fontSize: 20, fontWeight: '800', color: '#FFFFFF', marginTop: 2 },
  subjectMeta: { fontSize: 12, color: '#94A3B8', marginTop: 4 },
  retentionCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 20, marginBottom: 16, alignItems: 'center' },
  cardHeader: { fontSize: 11, fontWeight: '800', color: '#94A3B8', letterSpacing: 1, alignSelf: 'flex-start' },
  dialContainer: { marginVertical: 12, alignItems: 'center' },
  dialPercentage: { fontSize: 44, fontWeight: '900', color: '#10B981' },
  dialLabel: { fontSize: 12, color: '#94A3B8', marginTop: 2 },
  healthBar: { width: '100%', height: 8, backgroundColor: '#334155', borderRadius: 4, overflow: 'hidden' },
  healthFill: { height: '100%', backgroundColor: '#10B981', borderRadius: 4 },
  healthNote: { fontSize: 11, color: '#64748B', marginTop: 8 },
  quizAlertCard: { backgroundColor: '#1E1B4B', borderRadius: 16, padding: 18, marginBottom: 16, borderWidth: 1, borderColor: '#6366F1' },
  alertHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  badgeUrgent: { backgroundColor: '#EF4444', color: '#FFFFFF', fontSize: 10, fontWeight: '800', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 6 },
  quizDuration: { color: '#C7D2FE', fontSize: 12, fontWeight: '600' },
  quizPromptTitle: { fontSize: 17, fontWeight: '700', color: '#FFFFFF' },
  quizPromptDesc: { fontSize: 13, color: '#C7D2FE', marginTop: 4, marginBottom: 14, lineHeight: 18 },
  quizStartBtn: { backgroundColor: '#6366F1', paddingVertical: 12, borderRadius: 10, alignItems: 'center' },
  quizStartBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 15 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', paddingBottom: 40 },
  tile: { backgroundColor: '#1E293B', width: '48%', borderRadius: 14, padding: 16, alignItems: 'flex-start' },
  tileIcon: { fontSize: 26, marginBottom: 8 },
  tileTitle: { fontSize: 15, fontWeight: '700', color: '#FFFFFF' },
  tileDesc: { fontSize: 11, color: '#94A3B8', marginTop: 2 },
});
