import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';
import { QuizPayload, QuizQuestion, StudentSubmissionItem, QuizEvaluationResult } from '../types';

interface Props {
  onBack: () => void;
  onFinishQuiz: (result: QuizEvaluationResult) => void;
}

export const QuizScreen: React.FC<Props> = ({ onBack, onFinishQuiz }) => {
  const [quiz, setQuiz] = useState<QuizPayload | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [submissions, setSubmissions] = useState<StudentSubmissionItem[]>([]);
  const [timeLeft, setTimeLeft] = useState(45);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [started, setStarted] = useState(false);
  const [error, setError] = useState('');
  const [pendingSubmissions, setPendingSubmissions] = useState<StudentSubmissionItem[] | null>(null);
  const advancing = useRef(false);
  const startedAt = useRef(0);

  const fetchQuizData = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.getQuiz('Computer Networks');
      setQuiz(res);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load quiz');
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => { fetchQuizData(); }, []);

  // Timer countdown
  useEffect(() => {
    if (loading || submitting || !quiz || !started || pendingSubmissions) return;
    const interval = setInterval(() => {
      setTimeLeft((prev) => Math.max(0, prev - 1));
    }, 1000);
    return () => clearInterval(interval);
  }, [loading, submitting, quiz, currentIndex, started, pendingSubmissions]);

  useEffect(() => {
    if (started && timeLeft === 0 && !pendingSubmissions) handleNext(selectedOption || '');
  }, [timeLeft, started, pendingSubmissions]);

  const submitAnswers = async (answers: StudentSubmissionItem[]) => {
    if (!quiz) return;
    setSubmitting(true);
    setError('');
    try {
      const result = await api.submitQuiz(quiz.quiz_id, answers, Math.floor((Date.now() - startedAt.current) / 1000));
      onFinishQuiz(result);
    } catch (e) {
      setPendingSubmissions(answers);
      setError(e instanceof Error ? e.message : 'Submission failed');
    } finally {
      setSubmitting(false);
    }
  };

  const handleNext = async (answer: string) => {
    if (!quiz || advancing.current || submitting) return;
    advancing.current = true;
    const currentQ: QuizQuestion = quiz.questions[currentIndex];

    const currentSub: StudentSubmissionItem = {
      question_id: currentQ.id,
      submitted_answer: answer,
    };

    const updatedSubs = [...submissions, currentSub];
    setSubmissions(updatedSubs);
    setSelectedOption(null);
    setTimeLeft(45);

    if (currentIndex + 1 < quiz.questions.length) {
      setCurrentIndex(currentIndex + 1);
      advancing.current = false;
    } else {
      setPendingSubmissions(updatedSubs);
      await submitAnswers(updatedSubs);
    }
  };

  if (loading) {
    return (
      <View style={[styles.container, styles.center]}>
        <ActivityIndicator size="large" color="#6366F1" />
        <Text style={styles.loadingText}>Generating 3-min micro-quiz...</Text>
      </View>
    );
  }

  if (!quiz || quiz.questions.length === 0) {
    return (
      <View style={[styles.container, styles.center]}>
        <Text style={styles.errorText}>{error || 'No quiz questions available.'}</Text>
        <TouchableOpacity style={styles.backBtn} onPress={fetchQuizData}><Text style={styles.backBtnText}>Retry Quiz</Text></TouchableOpacity>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Text style={styles.backBtnText}>Return to Dashboard</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (!started) {
    return (
      <ScrollView style={styles.container}>
        <Text style={styles.previewTitle}>Your 3-Minute Review</Text>
        <Text style={styles.loadingText}>{quiz.total_questions} questions from your knowledge graph</Text>
        {(quiz.plan || []).map((concept) => (
          <View style={styles.promptCard} key={concept.concept_id}>
            <Text style={styles.promptText}>{concept.concept_name}</Text>
            <Text style={styles.loadingText}>{Math.round(concept.retrievability * 100)}% retention · {concept.status}</Text>
            <Text style={styles.loadingText}>{concept.selection_reason}</Text>
          </View>
        ))}
        <TouchableOpacity style={styles.confirmBtn} onPress={() => { startedAt.current = Date.now(); setStarted(true); }}>
          <Text style={styles.confirmBtnText}>Start Review</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}><Text style={styles.backBtnText}>Back to Dashboard</Text></TouchableOpacity>
      </ScrollView>
    );
  }

  if (pendingSubmissions) {
    return (
      <View style={[styles.container, styles.center]}>
        {submitting && <ActivityIndicator size="large" color="#6366F1" />}
        <Text style={styles.loadingText}>{submitting ? 'Updating your memory curve…' : 'Your answers are ready to submit.'}</Text>
        {!!error && <Text style={styles.errorText}>{error}</Text>}
        {!submitting && <TouchableOpacity style={styles.confirmBtn} onPress={() => submitAnswers(pendingSubmissions)}>
          <Text style={styles.confirmBtnText}>Retry Submission</Text>
        </TouchableOpacity>}
      </View>
    );
  }

  const currentQ = quiz.questions[currentIndex];

  return (
    <ScrollView style={styles.container}>
      {/* Top Header & Progress */}
      <View style={styles.topBar}>
        <TouchableOpacity onPress={onBack}>
          <Text style={styles.cancelText}>Cancel</Text>
        </TouchableOpacity>
        <Text style={styles.progressCounter}>
          Question {currentIndex + 1} of {quiz.questions.length}
        </Text>
        <View style={styles.timerPill}>
          <Text style={styles.timerText}>⏳ {timeLeft}s</Text>
        </View>
      </View>

      {/* Concept Tag */}
      <View style={styles.tagRow}>
        <Text style={styles.conceptTag}>{currentQ.concept_name}</Text>
      </View>

      {/* Prompt Card */}
      <View style={styles.promptCard}>
        <Text style={styles.promptText}>{currentQ.prompt}</Text>
      </View>

      {/* Options List */}
      <View style={styles.optionsList}>
        {currentQ.options.map((option, idx) => {
          const isSelected = selectedOption === option;
          return (
            <TouchableOpacity
              key={idx}
              style={[styles.optionItem, isSelected && styles.optionSelected]}
              onPress={() => setSelectedOption(option)}
            >
              <Text style={[styles.optionLetter, isSelected && styles.optionLetterSelected]}>
                {String.fromCharCode(65 + idx)}
              </Text>
              <Text style={[styles.optionText, isSelected && styles.optionTextSelected]}>{option}</Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Confirm Answer Button */}
      <TouchableOpacity
        style={[styles.confirmBtn, !selectedOption && styles.confirmBtnDisabled]}
        disabled={!selectedOption || submitting}
        onPress={() => handleNext(selectedOption || '')}
      >
        <Text style={styles.confirmBtnText}>
          {currentIndex + 1 === quiz.questions.length ? 'Submit Quiz' : 'Next Question →'}
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  center: { justifyContent: 'center', alignItems: 'center' },
  topBar: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 24, marginBottom: 16 },
  cancelText: { color: '#94A3B8', fontSize: 14, fontWeight: '600' },
  progressCounter: { color: '#E2E8F0', fontSize: 14, fontWeight: '700' },
  timerPill: { backgroundColor: '#1E1B4B', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12, borderWidth: 1, borderColor: '#6366F1' },
  timerText: { color: '#818CF8', fontWeight: '800', fontSize: 13 },
  tagRow: { marginBottom: 12 },
  conceptTag: { color: '#A5B4FC', backgroundColor: '#312E81', alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 6, fontSize: 11, fontWeight: '700' },
  promptCard: { backgroundColor: '#1E293B', borderRadius: 14, padding: 18, marginBottom: 20 },
  promptText: { color: '#FFFFFF', fontSize: 17, fontWeight: '700', lineHeight: 24 },
  optionsList: { marginBottom: 24 },
  optionItem: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#1E293B', borderRadius: 12, padding: 14, marginBottom: 10, borderWidth: 1, borderColor: '#334155' },
  optionSelected: { borderColor: '#6366F1', backgroundColor: '#2E1065' },
  optionLetter: { width: 28, height: 28, borderRadius: 14, backgroundColor: '#334155', color: '#E2E8F0', textAlign: 'center', lineHeight: 26, fontWeight: '800', marginRight: 12, fontSize: 13 },
  optionLetterSelected: { backgroundColor: '#6366F1', color: '#FFFFFF' },
  optionText: { color: '#CBD5E1', fontSize: 14, flex: 1, fontWeight: '500' },
  optionTextSelected: { color: '#FFFFFF', fontWeight: '700' },
  confirmBtn: { backgroundColor: '#6366F1', paddingVertical: 14, borderRadius: 12, alignItems: 'center', marginBottom: 40 },
  confirmBtnDisabled: { backgroundColor: '#334155', opacity: 0.6 },
  confirmBtnText: { color: '#FFFFFF', fontSize: 15, fontWeight: '800' },
  loadingText: { color: '#C7D2FE', marginTop: 12, fontSize: 14 },
  errorText: { color: '#EF4444', fontSize: 16, marginBottom: 16 },
  backBtn: { backgroundColor: '#6366F1', paddingHorizontal: 16, paddingVertical: 10, borderRadius: 8 },
  backBtnText: { color: '#FFFFFF', fontWeight: '700' },
  previewTitle: { color: '#FFFFFF', fontSize: 24, fontWeight: '800', marginTop: 32 },
});
