import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { api } from '../api/client';
import { AppHeader } from '../components/AppHeader';
import { colors } from '../theme';
import { DashboardData, ReviewSchedule } from '../types';

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
  const [error, setError] = useState('');
  const [schedule, setSchedule] = useState<ReviewSchedule | null>(null);
  const [alertError, setAlertError] = useState('');
  const [alertsLoading, setAlertsLoading] = useState(false);

  const checkAlerts = async () => {
    setAlertsLoading(true);
    setAlertError('');
    try {
      setSchedule(await api.getNotifications('Computer Networks'));
    } catch (e) {
      setAlertError(e instanceof Error ? e.message : 'Could not check reminders');
    } finally {
      setAlertsLoading(false);
    }
  };

  const loadData = async () => {
    try {
      setError('');
      setData(await api.getDashboard('Computer Networks'));
    } catch {
      setError('The learning dashboard is unavailable. Pull to retry.');
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

  const retention = data?.overall_retention_pct ?? 0;

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primaryDark} />
      }
    >
      <AppHeader streakDays={data?.study_streak_days ?? 0} />

      <View style={styles.heroCard}>
        <Text style={styles.eyebrow}>CONTINUE YOUR JOURNEY</Text>
        <Text style={styles.heroTitle}>{data?.subject_name ?? 'Loading your course…'}</Text>
        <Text style={styles.heroCopy}>
          Build confidence one concept at a time with short, well-timed reviews.
        </Text>
        <View style={styles.progressMeta}>
          <Text style={styles.progressText}>{data?.active_concepts_count ?? 0} concepts in rotation</Text>
          <Text style={styles.progressValue}>{Math.round(retention)}%</Text>
        </View>
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${Math.min(100, Math.max(0, retention))}%` }]} />
        </View>
        <TouchableOpacity style={styles.primaryButton} onPress={onStartQuiz}>
          <Text style={styles.primaryButtonText}>
            {data?.pending_quiz_available ? 'Start today’s review' : 'Review course'}
          </Text>
        </TouchableOpacity>
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}
      {!data && !error ? <ActivityIndicator color={colors.primaryDark} style={styles.loader} /> : null}

      <Text style={styles.sectionTitle}>Your learning rhythm</Text>
      <View style={styles.metricRow}>
        <View style={styles.metricCard}>
          <Text style={styles.metricLabel}>Retention</Text>
          <Text style={styles.metricValue}>{retention.toFixed(1)}%</Text>
          <Text style={styles.metricHint}>Estimated recall</Text>
        </View>
        <View style={styles.metricCard}>
          <Text style={styles.metricLabel}>Next review</Text>
          <Text style={styles.metricValue}>{data?.next_quiz_due_in_hours ?? 0}h</Text>
          <Text style={styles.metricHint} numberOfLines={1}>{data?.next_quiz_topic ?? 'No review scheduled'}</Text>
        </View>
      </View>

      <Text style={styles.sectionTitle}>Review tools</Text>
      <View style={styles.reviewCard}>
        <Text style={styles.reviewTitle}>Quiz and scheduler</Text>
        <Text style={styles.reviewCopy}>Generate a short quiz or check when your saved concepts need review.</Text>
        <TouchableOpacity style={styles.reviewButton} onPress={onStartQuiz}>
          <Text style={styles.reviewButtonText}>Generate Quiz</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.reviewButton} onPress={checkAlerts} disabled={alertsLoading}>
          <Text style={styles.reviewButtonText}>{alertsLoading ? 'Checking…' : 'Check Review Alerts'}</Text>
        </TouchableOpacity>
        {!!alertError && <Text style={styles.alertMessage}>{alertError}</Text>}
        {schedule !== null && schedule.notifications.length === 0 && (
          <Text style={styles.reviewCopy}>
            {schedule.next_review
              ? `No reviews due yet. Next: ${schedule.next_review.concept_name} in about ${schedule.next_review.hours_until_due.toFixed(1)} hours.`
              : 'No reviews scheduled for this subject yet.'}
          </Text>
        )}
        {schedule?.notifications.map((alert) => (
          <View key={alert.id} style={styles.alertItem}>
            <Text style={styles.reviewTitle}>{alert.title} · {alert.urgency}</Text>
            <Text style={styles.reviewCopy}>{alert.message}</Text>
            <TouchableOpacity onPress={onStartQuiz}><Text style={styles.alertAction}>Start Review →</Text></TouchableOpacity>
          </View>
        ))}
      </View>

      <Text style={styles.sectionTitle}>Learning tools</Text>
      <TouchableOpacity style={styles.actionCard} onPress={onOpenUpload}>
        <View style={styles.actionIcon}><Text style={styles.actionIconText}>＋</Text></View>
        <View style={styles.actionBody}>
          <Text style={styles.actionTitle}>Add learning material</Text>
          <Text style={styles.actionCopy}>Paste lecture notes and build your knowledge graph.</Text>
        </View>
        <Text style={styles.chevron}>›</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.actionCard} onPress={onOpenAnalytics}>
        <View style={styles.actionIcon}><Text style={styles.actionIconText}>▥</Text></View>
        <View style={styles.actionBody}>
          <Text style={styles.actionTitle}>View progress</Text>
          <Text style={styles.actionCopy}>See retention, reviews, and mastery trends.</Text>
        </View>
        <Text style={styles.chevron}>›</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.actionCard} onPress={onOpenGraph}>
        <View style={styles.actionIcon}><Text style={styles.actionIconText}>◉</Text></View>
        <View style={styles.actionBody}>
          <Text style={styles.actionTitle}>Explore knowledge graph</Text>
          <Text style={styles.actionCopy}>Inspect concepts and prerequisite links.</Text>
        </View>
        <Text style={styles.chevron}>›</Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: 16, paddingBottom: 28 },
  heroCard: { backgroundColor: colors.surfaceBlue, borderRadius: 20, padding: 18, marginBottom: 18 },
  eyebrow: { color: colors.primaryDark, fontSize: 10, fontWeight: '800', letterSpacing: 0.8 },
  heroTitle: { color: colors.text, fontSize: 24, fontWeight: '800', marginTop: 6 },
  heroCopy: { color: colors.muted, fontSize: 13, lineHeight: 19, marginTop: 5 },
  progressMeta: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 18 },
  progressText: { color: colors.text, fontSize: 12, fontWeight: '600' },
  progressValue: { color: colors.text, fontSize: 12, fontWeight: '800' },
  progressTrack: { height: 7, borderRadius: 4, backgroundColor: '#C8DDE9', marginTop: 8, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 4, backgroundColor: colors.primary },
  primaryButton: { backgroundColor: colors.primary, borderRadius: 10, paddingVertical: 13, alignItems: 'center', marginTop: 18 },
  primaryButtonText: { color: colors.text, fontSize: 14, fontWeight: '800' },
  loader: { marginVertical: 12 },
  error: { color: colors.danger, fontSize: 12, marginBottom: 14 },
  sectionTitle: { color: colors.text, fontSize: 18, fontWeight: '800', marginBottom: 10 },
  metricRow: { flexDirection: 'row', gap: 10, marginBottom: 22 },
  metricCard: { flex: 1, backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, padding: 14 },
  metricLabel: { color: colors.muted, fontSize: 11 },
  metricValue: { color: colors.text, fontSize: 25, fontWeight: '800', marginVertical: 3 },
  metricHint: { color: colors.muted, fontSize: 10 },
  actionCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, borderRadius: 16, padding: 14, marginBottom: 10 },
  actionIcon: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.surfaceBlueStrong, alignItems: 'center', justifyContent: 'center' },
  actionIconText: { color: colors.primaryDark, fontSize: 21, fontWeight: '800' },
  actionBody: { flex: 1, marginLeft: 12 },
  actionTitle: { color: colors.text, fontSize: 14, fontWeight: '800' },
  actionCopy: { color: colors.muted, fontSize: 11, lineHeight: 16, marginTop: 2 },
  chevron: { color: colors.primaryDark, fontSize: 26 },
  reviewCard: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, borderRadius: 16, padding: 14, marginBottom: 22, gap: 10 },
  reviewTitle: { color: colors.text, fontSize: 15, fontWeight: '800' },
  reviewCopy: { color: colors.muted, fontSize: 12, lineHeight: 18 },
  reviewButton: { backgroundColor: colors.primary, borderRadius: 10, paddingVertical: 12, alignItems: 'center' },
  reviewButtonText: { color: colors.text, fontSize: 13, fontWeight: '800' },
  alertItem: { borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 10, marginTop: 4 },
  alertMessage: { color: colors.danger, fontSize: 12 },
  alertAction: { color: colors.primaryDark, fontWeight: '800', paddingVertical: 8 },
});
