import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { QuizEvaluationResult } from '../types';

interface Props {
  result: QuizEvaluationResult;
  onDone: () => void;
  onOpenAnalytics: () => void;
}

export const QuizResultsScreen: React.FC<Props> = ({ result, onDone, onOpenAnalytics }) => {
  const isPassing = result.accuracy_pct >= 70;

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Nice work — review complete</Text>
        <Text style={styles.subtitle}>Here is what your study coach learned from this session.</Text>
      </View>

      {/* Score Summary Card */}
      <View style={[styles.scoreCard, isPassing ? styles.scoreCardSuccess : styles.scoreCardNeedsWork]}>
        <Text style={styles.scoreLabel}>YOUR RECALL SCORE</Text>
        <Text style={styles.scoreNumber}>{Math.round(result.accuracy_pct)}%</Text>
        <Text style={styles.scoreDetail}>
          {result.correct_items} of {result.total_items} questions answered correctly
        </Text>
        <Text style={styles.statusPill}>
          {isPassing ? '🎉 Memory refreshed · stability boosted' : '⚠️ A few concepts need another look'}
        </Text>
      </View>

      {/* Section 1: Missed Questions & Pedagogical Explanations */}
      {result.missed_explanations && result.missed_explanations.length > 0 ? (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>
            LEARN FROM THESE ({result.missed_explanations.length})
          </Text>
          <Text style={styles.sectionSubtitle}>
            A short explanation now makes the next recall easier.
          </Text>

          {result.missed_explanations.map((item, idx) => (
            <View key={idx} style={styles.missedCard}>
              <View style={styles.badgeRow}>
                <Text style={styles.incorrectBadge}>❌ Missed</Text>
                <Text style={styles.conceptTag}>{item.concept_id}</Text>
              </View>

              <View style={styles.answerBlock}>
                <Text style={styles.answerLabel}>Your Answer:</Text>
                <Text style={styles.yourAnswerText}>{item.your_answer || '(Blank)'}</Text>
              </View>

              <View style={styles.answerBlock}>
                <Text style={styles.answerLabel}>Correct Answer:</Text>
                <Text style={styles.correctAnswerText}>{item.correct_answer}</Text>
              </View>

              <View style={styles.explanationBox}>
                <Text style={styles.explanationHeader}>💡 Why this is correct:</Text>
                <Text style={styles.explanationText}>{item.pedagogical_explanation}</Text>
              </View>
            </View>
          ))}
        </View>
      ) : (
        <View style={styles.perfectCard}>
          <Text style={styles.perfectIcon}>🌟</Text>
          <Text style={styles.perfectTitle}>Perfect Recall!</Text>
          <Text style={styles.perfectDesc}>
            All concepts were correctly retrieved. Your memory stability half-life has doubled!
          </Text>
        </View>
      )}

      {/* Section 2: Calibrated Concept Nodes in Jac Graph */}
      {result.recalibrated_concepts && result.recalibrated_concepts.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>YOUR REVIEW PLAN UPDATED</Text>
          <Text style={styles.sectionSubtitle}>
            Memora adjusted stability and the next review date for these concepts:
          </Text>

          {result.recalibrated_concepts.map((concept, idx) => (
            <View key={idx} style={styles.conceptStatCard}>
              <View style={styles.conceptStatHeader}>
                <Text style={styles.conceptName}>{concept.name}</Text>
                <Text style={[styles.statusTag, concept.status === 'STRONG' ? styles.tagStrong : styles.tagFading]}>
                  {concept.status}
                </Text>
              </View>

              <View style={styles.statGrid}>
                <View>
                  <Text style={styles.statLabel}>Stability (Half-Life)</Text>
                  <Text style={styles.statValue}>{concept.new_stability_days} days</Text>
                </View>
                <View>
                  <Text style={styles.statLabel}>Next Review Due</Text>
                  <Text style={styles.statValue}>In {concept.next_review_in_days} days</Text>
                </View>
                <View>
                  <Text style={styles.statLabel}>Mastery</Text>
                  <Text style={styles.statValue}>{Math.round(concept.mastery_score * 100)}%</Text>
                </View>
              </View>
            </View>
          ))}
        </View>
      )}

      {/* Action Buttons */}
      <View style={styles.btnRow}>
        <TouchableOpacity style={styles.analyticsBtn} onPress={onOpenAnalytics}>
          <Text style={styles.analyticsBtnText}>📈 See my progress</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.doneBtn} onPress={onDone}>
          <Text style={styles.doneBtnText}>Back to my dashboard</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  header: { marginTop: 24, marginBottom: 16 },
  title: { fontSize: 22, fontWeight: '800', color: '#FFFFFF' },
  subtitle: { fontSize: 13, color: '#94A3B8', marginTop: 2 },
  scoreCard: { borderRadius: 16, padding: 20, alignItems: 'center', marginBottom: 20 },
  scoreCardSuccess: { backgroundColor: '#064E3B', borderWidth: 1, borderColor: '#10B981' },
  scoreCardNeedsWork: { backgroundColor: '#450A0A', borderWidth: 1, borderColor: '#EF4444' },
  scoreLabel: { fontSize: 11, fontWeight: '800', color: '#D1FAE5', letterSpacing: 1 },
  scoreNumber: { fontSize: 48, fontWeight: '900', color: '#FFFFFF', marginVertical: 4 },
  scoreDetail: { fontSize: 13, color: '#E2E8F0', marginBottom: 8 },
  statusPill: { fontSize: 12, fontWeight: '700', color: '#FCD34D' },
  section: { marginBottom: 24 },
  sectionTitle: { fontSize: 12, fontWeight: '800', color: '#94A3B8', letterSpacing: 1 },
  sectionSubtitle: { fontSize: 12, color: '#64748B', marginTop: 2, marginBottom: 12 },
  missedCard: { backgroundColor: '#1E293B', borderRadius: 12, padding: 16, marginBottom: 12, borderWidth: 1, borderColor: '#334155' },
  badgeRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 },
  incorrectBadge: { color: '#F87171', fontSize: 12, fontWeight: '800' },
  conceptTag: { color: '#94A3B8', fontSize: 11 },
  answerBlock: { marginBottom: 6 },
  answerLabel: { fontSize: 11, color: '#94A3B8' },
  yourAnswerText: { fontSize: 14, color: '#EF4444', fontWeight: '600' },
  correctAnswerText: { fontSize: 14, color: '#10B981', fontWeight: '600' },
  explanationBox: { backgroundColor: '#0F172A', borderRadius: 8, padding: 12, marginTop: 8 },
  explanationHeader: { fontSize: 12, fontWeight: '700', color: '#FBBF24', marginBottom: 4 },
  explanationText: { fontSize: 12, color: '#CBD5E1', lineHeight: 18 },
  perfectCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 24, alignItems: 'center', marginBottom: 24 },
  perfectIcon: { fontSize: 36, marginBottom: 8 },
  perfectTitle: { fontSize: 18, fontWeight: '800', color: '#FFFFFF' },
  perfectDesc: { fontSize: 13, color: '#94A3B8', textAlign: 'center', marginTop: 4 },
  conceptStatCard: { backgroundColor: '#1E293B', borderRadius: 12, padding: 14, marginBottom: 8 },
  conceptStatHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  conceptName: { color: '#FFFFFF', fontSize: 14, fontWeight: '700' },
  statusTag: { fontSize: 10, fontWeight: '800', paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4 },
  tagStrong: { backgroundColor: '#064E3B', color: '#34D399' },
  tagFading: { backgroundColor: '#78350F', color: '#FBBF24' },
  statGrid: { flexDirection: 'row', justifyContent: 'space-between' },
  statLabel: { fontSize: 10, color: '#64748B' },
  statValue: { fontSize: 13, fontWeight: '700', color: '#E2E8F0', marginTop: 2 },
  btnRow: { marginBottom: 40 },
  analyticsBtn: { backgroundColor: '#1E1B4B', paddingVertical: 14, borderRadius: 12, alignItems: 'center', marginBottom: 10, borderWidth: 1, borderColor: '#6366F1' },
  analyticsBtnText: { color: '#C7D2FE', fontWeight: '700', fontSize: 15 },
  doneBtn: { backgroundColor: '#6366F1', paddingVertical: 14, borderRadius: 12, alignItems: 'center' },
  doneBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 15 },
});
