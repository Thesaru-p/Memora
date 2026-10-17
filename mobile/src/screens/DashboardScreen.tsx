import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, RefreshControl } from 'react-native';
import { api } from '../api/client';
import { DashboardData } from '../types';

interface Props {
  subjectName: string;
  onStartQuiz: () => void;
  onOpenUpload: () => void;
  onOpenGraph: () => void;
  onOpenAnalytics: () => void;
}

export const DashboardScreen: React.FC<Props> = ({
  subjectName,
  onStartQuiz,
  onOpenUpload,
  onOpenGraph,
  onOpenAnalytics,
}) => {
  const [data, setData] = useState<DashboardData | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');

  const loadData = async () => {
    try {
      if (!subjectName) return;
      setError('');
      const res = await api.getDashboard(subjectName);
      setData(res);
    } catch (e) {
      console.error(e);
      setData(null);
      setError(e instanceof Error ? e.message : 'Could not load the dashboard.');
    }
  };

  useEffect(() => {
    loadData();
  }, [subjectName]);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  if (!subjectName) {
    return (
      <View style={[styles.container, styles.emptyState]}>
        <Text style={styles.appTitle}>Memora</Text>
        <Text style={styles.emptyTitle}>No lecture loaded</Text>
        <Text style={styles.emptyText}>Upload a lecture before opening the dashboard or generating a quiz.</Text>
        <TouchableOpacity style={styles.quizStartBtn} onPress={onOpenUpload}>
          <Text style={styles.quizStartBtnText}>Add a lecture</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (error) {
    return (
      <View style={[styles.container, styles.emptyState]}>
        <Text style={styles.emptyTitle}>Dashboard error</Text>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.quizStartBtn} onPress={onRefresh}>
          <Text style={styles.quizStartBtnText}>Retry</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.secondaryBtn} onPress={onOpenUpload}>
          <Text style={styles.secondaryBtnText}>Upload a lecture</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (!data) {
    return (
      <View style={[styles.container, styles.emptyState]}>
        <Text style={styles.emptyText}>Loading dashboard…</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#6366F1" />}
    >
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Good morning 👋</Text>
          <Text style={styles.appTitle}>Memora</Text>
          <Text style={styles.subtitle}>Small reviews. Stronger memory.</Text>
        </View>
        <View style={styles.streakBadge}>
          <Text style={styles.streakText}>🔥 {data.study_streak_days} day streak</Text>
        </View>
      </View>

      <View style={styles.aiStatusCard}>
        <View style={styles.aiStatusDot} />
        <View style={styles.aiStatusCopy}>
          <Text style={styles.aiStatusTitle}>AI study coach ready</Text>
          <Text style={styles.aiStatusText}>Notes become concepts, quizzes, and review plans.</Text>
        </View>
        <Text style={styles.aiStatusLabel}>LLM READY</Text>
      </View>

      {/* Course / Subject Selector Card */}
      <View style={styles.subjectCard}>
        <Text style={styles.courseCode}>{data.code}</Text>
        <Text style={styles.subjectTitle}>{data.subject_name}</Text>
        <Text style={styles.subjectMeta}>{data.active_concepts_count} concepts active in knowledge graph</Text>
      </View>

      {/* Retention Health Dial */}
      <View style={styles.retentionCard}>
        <View style={styles.cardHeaderRow}>
          <Text style={styles.cardHeader}>MEMORY HEALTH</Text>
          <Text style={styles.cardHint}>Updated today</Text>
        </View>
        <View style={styles.dialContainer}>
          <Text style={styles.dialPercentage}>{data.overall_retention_pct}%</Text>
          <Text style={styles.dialLabel}>Estimated Recall Probability</Text>
        </View>
        <View style={styles.healthBar}>
          <View style={[styles.healthFill, { width: `${data.overall_retention_pct}%` }]} />
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
        <Text style={styles.quizPromptTitle}>Refresh: {data.next_quiz_topic}</Text>
        <Text style={styles.quizPromptDesc}>A quick active-recall session can protect today’s learning before it fades.</Text>
        <TouchableOpacity style={styles.quizStartBtn} onPress={onStartQuiz}>
          <Text style={styles.quizStartBtnText}>Start review · 3 min</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.sectionIntro}>
        <Text style={styles.sectionTitle}>Keep your learning moving</Text>
        <Text style={styles.sectionSubtitle}>Choose an action or explore your progress.</Text>
      </View>

      {/* Quick Navigation Tiles */}
      <View style={styles.grid}>
        <TouchableOpacity style={styles.tile} onPress={onOpenUpload}>
          <Text style={styles.tileIcon}>📸</Text>
          <Text style={styles.tileTitle}>Add a lecture</Text>
          <Text style={styles.tileDesc}>Notes, slides, or handwriting</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.tile} onPress={onOpenGraph}>
          <Text style={styles.tileIcon}>🕸️</Text>
          <Text style={styles.tileTitle}>Explore concepts</Text>
          <Text style={styles.tileDesc}>See what connects together</Text>
        </TouchableOpacity>

        <TouchableOpacity style={[styles.tile, { width: '100%', marginTop: 12 }]} onPress={onOpenAnalytics}>
          <Text style={styles.tileIcon}>📈</Text>
          <Text style={styles.tileTitle}>View progress</Text>
          <Text style={styles.tileDesc}>Retention trends and quiz history</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  emptyState: { justifyContent: 'center', alignItems: 'center' },
  emptyTitle: { color: '#FFFFFF', fontSize: 22, fontWeight: '800', marginTop: 16, textAlign: 'center' },
  emptyText: { color: '#94A3B8', fontSize: 14, lineHeight: 20, textAlign: 'center', maxWidth: 420, marginTop: 8, marginBottom: 18 },
  errorText: { color: '#FCA5A5', backgroundColor: '#450A0A', padding: 12, borderRadius: 10, textAlign: 'center', maxWidth: 560, marginTop: 12, marginBottom: 16 },
  secondaryBtn: { borderWidth: 1, borderColor: '#6366F1', paddingVertical: 12, paddingHorizontal: 18, borderRadius: 10, marginTop: 10 },
  secondaryBtnText: { color: '#C7D2FE', fontWeight: '700' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 32, marginBottom: 16 },
  greeting: { fontSize: 12, color: '#94A3B8', marginBottom: 2 },
  appTitle: { fontSize: 28, fontWeight: '900', color: '#FFFFFF', letterSpacing: 0.2 },
  subtitle: { fontSize: 13, color: '#94A3B8' },
  streakBadge: { backgroundColor: '#1E1B4B', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20, borderWidth: 1, borderColor: '#4F46E5' },
  streakText: { color: '#F59E0B', fontWeight: '700', fontSize: 13 },
  aiStatusCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#172554', borderRadius: 14, padding: 13, marginBottom: 16, borderWidth: 1, borderColor: '#3730A3' },
  aiStatusDot: { width: 9, height: 9, borderRadius: 5, backgroundColor: '#34D399', marginRight: 10 },
  aiStatusCopy: { flex: 1 },
  aiStatusTitle: { color: '#E0E7FF', fontSize: 13, fontWeight: '800' },
  aiStatusText: { color: '#A5B4FC', fontSize: 11, marginTop: 2 },
  aiStatusLabel: { color: '#C7D2FE', fontSize: 10, fontWeight: '800', letterSpacing: 1 },
  subjectCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 16, marginBottom: 16, borderLeftWidth: 4, borderLeftColor: '#6366F1' },
  courseCode: { fontSize: 11, fontWeight: '700', color: '#818CF8', letterSpacing: 1 },
  subjectTitle: { fontSize: 20, fontWeight: '800', color: '#FFFFFF', marginTop: 2 },
  subjectMeta: { fontSize: 12, color: '#94A3B8', marginTop: 4 },
  retentionCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 20, marginBottom: 16, alignItems: 'center' },
  cardHeaderRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', width: '100%' },
  cardHeader: { fontSize: 11, fontWeight: '800', color: '#94A3B8', letterSpacing: 1 },
  cardHint: { fontSize: 10, color: '#64748B' },
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
  sectionIntro: { marginBottom: 10 },
  sectionTitle: { color: '#FFFFFF', fontSize: 16, fontWeight: '800' },
  sectionSubtitle: { color: '#64748B', fontSize: 12, marginTop: 3 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', paddingBottom: 40 },
  tile: { backgroundColor: '#1E293B', width: '48%', borderRadius: 14, padding: 16, alignItems: 'flex-start' },
  tileIcon: { fontSize: 26, marginBottom: 8 },
  tileTitle: { fontSize: 15, fontWeight: '700', color: '#FFFFFF' },
  tileDesc: { fontSize: 11, color: '#94A3B8', marginTop: 2 },
});
