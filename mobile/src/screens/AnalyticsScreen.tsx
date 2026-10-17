import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';
import { AnalyticsData } from '../types';

interface Props {
  onBack: () => void;
}

export const AnalyticsScreen: React.FC<Props> = ({ onBack }) => {
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
        <ActivityIndicator size="large" color="#6366F1" />
        <Text style={styles.loadingText}>Loading memory analytics...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <TouchableOpacity style={styles.backBtn} onPress={onBack}>
        <Text style={styles.backBtnText}>← Back</Text>
      </TouchableOpacity>

      <Text style={styles.pageTitle}>Memory & Performance Analytics</Text>
      <Text style={styles.pageSubtitle}>Tracking Ebbinghaus retention decay and recall trends.</Text>

      {/* Highlights Grid */}
      <View style={styles.highlightRow}>
        <View style={styles.highlightCard}>
          <Text style={styles.highlightLabel}>SUBJECT RETENTION</Text>
          <Text style={styles.highlightValue}>
            {data.mastery_distribution.overall_subject_retention_pct}%
          </Text>
          <Text style={styles.highlightSub}>Target: &gt;80%</Text>
        </View>

        <View style={styles.highlightCard}>
          <Text style={styles.highlightLabel}>HOURS SAVED</Text>
          <Text style={styles.highlightValue}>{data.hours_saved_vs_cramming}h</Text>
          <Text style={styles.highlightSub}>vs. last-minute cramming</Text>
        </View>
      </View>

      {/* Ebbinghaus Memory Retention Curve Visualizer */}
      <View style={styles.sectionCard}>
        <Text style={styles.sectionHeader}>EBBINGHAUS RETENTION CURVE OVER TIME</Text>
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
        <Text style={styles.sectionHeader}>QUIZ PERFORMANCE HISTORY</Text>
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
        <Text style={styles.sectionHeader}>CONCEPT MASTERY BREAKDOWN</Text>
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
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  center: { justifyContent: 'center', alignItems: 'center' },
  loadingText: { color: '#C7D2FE', marginTop: 12 },
  backBtn: { marginTop: 24, marginBottom: 12 },
  backBtnText: { color: '#818CF8', fontSize: 16, fontWeight: '700' },
  pageTitle: { fontSize: 22, fontWeight: '800', color: '#FFFFFF' },
  pageSubtitle: { fontSize: 13, color: '#94A3B8', marginTop: 4, marginBottom: 20 },
  highlightRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
  highlightCard: { backgroundColor: '#1E293B', width: '48%', borderRadius: 14, padding: 16 },
  highlightLabel: { fontSize: 10, fontWeight: '800', color: '#94A3B8', letterSpacing: 0.5 },
  highlightValue: { fontSize: 32, fontWeight: '900', color: '#6366F1', marginVertical: 4 },
  highlightSub: { fontSize: 11, color: '#64748B' },
  sectionCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 18, marginBottom: 16 },
  sectionHeader: { fontSize: 11, fontWeight: '800', color: '#94A3B8', letterSpacing: 1 },
  chartSubtitle: { fontSize: 12, color: '#64748B', marginTop: 4, marginBottom: 14, lineHeight: 18 },
  curveList: { marginBottom: 12 },
  pointRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  pointDayCol: { width: 60 },
  pointDayText: { color: '#E2E8F0', fontSize: 12, fontWeight: '600' },
  pointBarCol: { flex: 1, marginHorizontal: 8 },
  barBackground: { height: 10, backgroundColor: '#0F172A', borderRadius: 5, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 5 },
  pointValCol: { width: 44, alignItems: 'flex-end' },
  pointPctText: { color: '#FFFFFF', fontSize: 12, fontWeight: '700' },
  legendRow: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, borderTopColor: '#334155', paddingTop: 10, marginTop: 6 },
  legendItem: { fontSize: 10, color: '#94A3B8' },
  historyRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#334155' },
  historyDate: { color: '#FFFFFF', fontSize: 14, fontWeight: '700' },
  historyDuration: { color: '#94A3B8', fontSize: 11, marginTop: 2 },
  historyScoreBox: { alignItems: 'flex-end' },
  historyScore: { color: '#10B981', fontSize: 15, fontWeight: '800' },
  historyPct: { color: '#94A3B8', fontSize: 11 },
  masteryRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8 },
  masteryLabel: { color: '#CBD5E1', fontSize: 13 },
  masteryValue: { color: '#FFFFFF', fontSize: 13, fontWeight: '700' },
});
