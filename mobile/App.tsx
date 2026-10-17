import React, { useState } from 'react';
import { SafeAreaView, StatusBar, StyleSheet, View } from 'react-native';
import { DashboardScreen } from './src/screens/DashboardScreen';
import { LectureUploadScreen } from './src/screens/LectureUploadScreen';
import { QuizScreen } from './src/screens/QuizScreen';
import { QuizResultsScreen } from './src/screens/QuizResultsScreen';
import { AnalyticsScreen } from './src/screens/AnalyticsScreen';
import { KnowledgeGraphScreen } from './src/screens/KnowledgeGraphScreen';
import { QuizEvaluationResult } from './src/types';

type Screen = 'DASHBOARD' | 'UPLOAD' | 'QUIZ' | 'RESULTS' | 'ANALYTICS' | 'GRAPH';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('DASHBOARD');
  const [lastQuizResult, setLastQuizResult] = useState<QuizEvaluationResult | null>(null);
  const [activeSubject, setActiveSubject] = useState('');

  const handleFinishQuiz = (result: QuizEvaluationResult) => {
    setLastQuizResult(result);
    setCurrentScreen('RESULTS');
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor="#0B0F19" />
      <View style={styles.container}>
        {currentScreen === 'DASHBOARD' && (
          <DashboardScreen
            subjectName={activeSubject}
            onStartQuiz={() => setCurrentScreen('QUIZ')}
            onOpenUpload={() => setCurrentScreen('UPLOAD')}
            onOpenGraph={() => setCurrentScreen('GRAPH')}
            onOpenAnalytics={() => setCurrentScreen('ANALYTICS')}
          />
        )}

        {currentScreen === 'UPLOAD' && (
          <LectureUploadScreen
            onBack={() => setCurrentScreen('DASHBOARD')}
            onSuccess={(subjectName) => {
              setActiveSubject(subjectName);
              setCurrentScreen('DASHBOARD');
            }}
          />
        )}

        {currentScreen === 'QUIZ' && (
          <QuizScreen
            onBack={() => setCurrentScreen('DASHBOARD')}
            onFinishQuiz={handleFinishQuiz}
            subjectName={activeSubject}
          />
        )}

        {currentScreen === 'RESULTS' && lastQuizResult && (
          <QuizResultsScreen
            result={lastQuizResult}
            onDone={() => setCurrentScreen('DASHBOARD')}
            onOpenAnalytics={() => setCurrentScreen('ANALYTICS')}
          />
        )}

        {currentScreen === 'ANALYTICS' && (
          <AnalyticsScreen subjectName={activeSubject} onBack={() => setCurrentScreen('DASHBOARD')} />
        )}

        {currentScreen === 'GRAPH' && (
          <KnowledgeGraphScreen subjectName={activeSubject} onBack={() => setCurrentScreen('DASHBOARD')} />
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#0B0F19',
  },
  container: {
    flex: 1,
    backgroundColor: '#0B0F19',
  },
});
