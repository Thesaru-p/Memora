import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';
import { AppHeader } from '../components/AppHeader';
import { colors } from '../theme';
import { AnalyticsData } from '../types';

export const AnalyticsScreen: React.FC = () => {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        const res = await api.getAnalytics('Computer Networks');
        setData(res);
        setLoading(false);
      } catch (e) {
        console.error(e);
      }
    };
    fetchAnalytics();
  }, []);

  if (loading || !data) {
    return (
      <View style={[styles.container, styles.center]}>
        <ActivityIndicator size="large" color={colors.primaryDark} />
        <Text style={styles.loadingText}>Loading memory analytics...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <AppHeader streakDays={data.study_streak_days} />
      <Text style={styles.pageTitle}>Progress</Text>
      <Text style={styles.pageSubtitle}>Your memory and learning statistics.</Text>

      {/* Highlights Grid */}
      <View style={styles.highlightRow}>
        <View style={styles.highlightCard}>
          <Text style={styles.highlightLabel}>RETENTION</Text>
          <Text style={styles.highlightValue}>
            {data.mastery_distribution.overall_subject_retention_pct}%
          </Text>
          <Text style={styles.highlightSub}>Target: &gt;80%</Text>
        </View>

        <View style={styles.highlightCard}>
          <Text style={styles.highlightLabel}>TIME SAVED</Text>
          <Text style={styles.highlightValue}>{data.hours_saved_vs_cramming}h</Text>
          <Text style={styles.highlightSub}>vs. last-minute cramming</Text>
        </View>
      </View>

      {/* Ebbinghaus Memory Retention Curve Visualizer */}
      <View style={styles.sectionCard}>
        <Text style={styles.sectionHeader}>THE FORGETTING CURVE</Text>
        <Text style={styles.chartSubtitle}>
          Visualizing the Day-1 forgetting cliff (drop to ~40%) and subsequent retention recovery after micro-quizzes.
        </Text>

        <View style={styles.curveList}>
          {data.retention_curve.map((pt, idx) => (
            <View key={idx} style={styles.pointRow}>
              <View style={styles.pointDayCol}>
                <Text style={styles.pointDayText}>Day {pt.day}</Text>
              </View>

              <View style={styles.pointBarCol}>
                <View style={styles.barBackground}>
                  <View
                    style={[
                      styles.barFill,
                      {
                        width: `${pt.retention_pct}%`,
                        backgroundColor:
                          pt.retention_pct >= 80 ? '#10B981' : pt.retention_pct >= 60 ? '#F59E0B' : '#EF4444',
                      },
                    ]}
                  />
                </View>
              </View>

              <View style={styles.pointValCol}>
                <Text style={styles.pointPctText}>{Math.round(pt.retention_pct)}%</Text>
              </View>
            </View>
          ))}
        </View>

        <View style={styles.legendRow}>
          <Text style={styles.legendItem}>🟢 Mastered (&gt;80%)</Text>
          <Text style={styles.legendItem}>🟡 Fading (60-80%)</Text>
          <Text style={styles.legendItem}>🔴 Critical (&lt;60%)</Text>
        </View>
      </View>

      {/* Quiz Performance History */}
      <View style={styles.sectionCard}>
        <Text style={styles.sectionHeader}>REVIEW HISTORY</Text>
        {data.quiz_history.map((q, idx) => (
          <View key={idx} style={styles.historyRow}>
            <View>
              <Text style={styles.historyDate}>{q.date} Micro-Quiz</Text>
              <Text style={styles.historyDuration}>Duration: {q.duration}</Text>
            </View>
            <View style={styles.historyScoreBox}>
              <Text style={styles.historyScore}>{q.score}/{q.total}</Text>
              <Text style={styles.historyPct}>{Math.round(q.accuracy_pct)}%</Text>
            </View>
          </View>
        ))}
      </View>

      {/* Concept Mastery Breakdown */}
      <View style={[styles.sectionCard, { marginBottom: 40 }]}>
        <Text style={styles.sectionHeader}>CONCEPT MASTERY</Text>
        <View style={styles.masteryRow}>
          <Text style={styles.masteryLabel}>Mastered Concepts</Text>
          <Text style={styles.masteryValue}>{data.mastery_distribution.mastered_count} of {data.mastery_distribution.total_concepts}</Text>
        </View>
        <View style={styles.masteryRow}>
          <Text style={styles.masteryLabel}>Fading / Review Due</Text>
          <Text style={styles.masteryValue}>{data.mastery_distribution.fading_count}</Text>
        </View>
        <View style={styles.masteryRow}>
          <Text style={styles.masteryLabel}>Critical Drop Risk</Text>
          <Text style={styles.masteryValue}>{data.mastery_distribution.critical_count}</Text>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: 16, paddingBottom: 28 },
  center: { justifyContent: 'center', alignItems: 'center' },
  loadingText: { color: colors.muted, marginTop: 12 },
  pageTitle: { fontSize: 24, fontWeight: '800', color: colors.text },
  pageSubtitle: { fontSize: 13, color: colors.muted, marginTop: 4, marginBottom: 20 },
  highlightRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
  highlightCard: { backgroundColor: colors.surfaceBlue, width: '48%', borderRadius: 16, padding: 16 },
  highlightLabel: { fontSize: 10, fontWeight: '800', color: colors.muted, letterSpacing: 0.5 },
  highlightValue: { fontSize: 32, fontWeight: '900', color: colors.text, marginVertical: 4 },
  highlightSub: { fontSize: 11, color: colors.muted },
  sectionCard: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, borderRadius: 18, padding: 18, marginBottom: 16 },
  sectionHeader: { fontSize: 12, fontWeight: '800', color: colors.text, letterSpacing: 0.5 },
  chartSubtitle: { fontSize: 12, color: colors.muted, marginTop: 4, marginBottom: 14, lineHeight: 18 },
  curveList: { marginBottom: 12 },
  pointRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  pointDayCol: { width: 60 },
  pointDayText: { color: colors.text, fontSize: 12, fontWeight: '600' },
  pointBarCol: { flex: 1, marginHorizontal: 8 },
  barBackground: { height: 10, backgroundColor: '#DCEAF2', borderRadius: 5, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 5 },
  pointValCol: { width: 44, alignItems: 'flex-end' },
  pointPctText: { color: colors.text, fontSize: 12, fontWeight: '700' },
  legendRow: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 10, marginTop: 6 },
  legendItem: { fontSize: 10, color: colors.muted },
  historyRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: colors.border },
  historyDate: { color: colors.text, fontSize: 14, fontWeight: '700' },
  historyDuration: { color: colors.muted, fontSize: 11, marginTop: 2 },
  historyScoreBox: { alignItems: 'flex-end' },
  historyScore: { color: '#10B981', fontSize: 15, fontWeight: '800' },
  historyPct: { color: colors.muted, fontSize: 11 },
  masteryRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8 },
  masteryLabel: { color: colors.muted, fontSize: 13 },
  masteryValue: { color: colors.text, fontSize: 13, fontWeight: '700' },
});
