import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';
import { QuizPayload, QuizQuestion, StudentSubmissionItem, QuizEvaluationResult } from '../types';

interface Props {
  onBack: () => void;
  onFinishQuiz: (result: QuizEvaluationResult) => void;
  subjectName: string;
}

export const QuizScreen: React.FC<Props> = ({ onBack, onFinishQuiz, subjectName }) => {
  const [quiz, setQuiz] = useState<QuizPayload | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [submissions, setSubmissions] = useState<StudentSubmissionItem[]>([]);
  const [timeLeft, setTimeLeft] = useState(45);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    const fetchQuizData = async () => {
      try {
        const res = await api.getQuiz(subjectName);
        setQuiz(res);
        setLoading(false);
      } catch (e) {
        console.error(e);
        setError('The AI quiz could not be generated. Please upload a lecture and try again.');
        setLoading(false);
      }
    };
    fetchQuizData();
  }, []);

  // Timer countdown
  useEffect(() => {
    if (loading || submitting || !quiz) return;
    const interval = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          handleNext(selectedOption || '');
          return 45;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [loading, submitting, quiz, currentIndex, selectedOption]);

  const handleNext = async (answer: string) => {
    if (!quiz) return;
    const currentQ: QuizQuestion = quiz.questions[currentIndex];

    const currentSub: StudentSubmissionItem = {
      question_id: currentQ.id,
      concept_id: currentQ.concept_id,
      submitted_answer: answer,
      correct_answer: currentQ.correct_answer,
      explanation: currentQ.explanation,
    };

    const updatedSubs = [...submissions, currentSub];
    setSubmissions(updatedSubs);
    setSelectedOption(null);
    setTimeLeft(45);

    if (currentIndex + 1 < quiz.questions.length) {
      setCurrentIndex(currentIndex + 1);
    } else {
      // Quiz Complete -> submit to Evaluator Agent
      setSubmitting(true);
      try {
        const evalResult = await api.submitQuiz(quiz.quiz_id, updatedSubs);
        onFinishQuiz(evalResult);
      } catch (e) {
        console.error(e);
      }
    }
  };

  if (loading) {
    return (
      <View style={[styles.container, styles.center]}>
        <ActivityIndicator size="large" color="#6366F1" />
        <Text style={styles.loadingText}>Generating an AI quiz from your lecture...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={[styles.container, styles.center]}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Text style={styles.backBtnText}>Return to Dashboard</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (!quiz || quiz.questions.length === 0) {
    return (
      <View style={[styles.container, styles.center]}>
        <Text style={styles.errorText}>No quiz questions available.</Text>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Text style={styles.backBtnText}>Return to Dashboard</Text>
        </TouchableOpacity>
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

      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { width: `${((currentIndex + 1) / quiz.questions.length) * 100}%` }]} />
      </View>

      <View style={styles.coachHint}>
        <Text style={styles.coachHintIcon}>🧠</Text>
        <Text style={styles.coachHintText}>Trust your first recall. This quiz is here to strengthen memory, not judge you.</Text>
      </View>

      {/* Concept Tag */}
      <View style={styles.tagRow}>
        <Text style={styles.conceptTag}>REVIEWING · {currentQ.concept_name}</Text>
        <Text style={styles.sourceTag}>✨ Generated from your lecture by AI</Text>
      </View>

      {/* Prompt Card */}
      <View style={styles.promptCard}>
        <Text style={styles.promptLabel}>Question {currentIndex + 1}</Text>
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
          {currentIndex + 1 === quiz.questions.length ? 'Finish review' : 'Continue →'}
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
  progressTrack: { height: 6, backgroundColor: '#1E293B', borderRadius: 3, overflow: 'hidden', marginBottom: 16 },
  progressFill: { height: '100%', backgroundColor: '#818CF8', borderRadius: 3 },
  coachHint: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#172554', borderRadius: 12, padding: 11, marginBottom: 16 },
  coachHintIcon: { fontSize: 18, marginRight: 8 },
  coachHintText: { flex: 1, color: '#C7D2FE', fontSize: 11, lineHeight: 16 },
  tagRow: { marginBottom: 12 },
  conceptTag: { color: '#A5B4FC', backgroundColor: '#312E81', alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 6, fontSize: 11, fontWeight: '700' },
  sourceTag: { color: '#A7F3D0', fontSize: 11, fontWeight: '700', marginTop: 6 },
  promptCard: { backgroundColor: '#1E293B', borderRadius: 14, padding: 18, marginBottom: 20 },
  promptLabel: { color: '#818CF8', fontSize: 11, fontWeight: '800', letterSpacing: 1, marginBottom: 8 },
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
});
