import React, { useEffect, useState } from 'react';
import { Platform, SafeAreaView, StatusBar, StyleSheet, View } from 'react-native';
import { DashboardScreen } from './src/screens/DashboardScreen';
import { LectureUploadScreen } from './src/screens/LectureUploadScreen';
import { QuizScreen } from './src/screens/QuizScreen';
import { QuizResultsScreen } from './src/screens/QuizResultsScreen';
import { AnalyticsScreen } from './src/screens/AnalyticsScreen';
import { KnowledgeGraphScreen } from './src/screens/KnowledgeGraphScreen';
import { QuizEvaluationResult } from './src/types';
import { BottomNav, PrimaryScreen } from './src/components/BottomNav';
import { colors } from './src/theme';

type Screen = 'DASHBOARD' | 'UPLOAD' | 'QUIZ' | 'RESULTS' | 'ANALYTICS' | 'GRAPH';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('DASHBOARD');
  const [lastQuizResult, setLastQuizResult] = useState<QuizEvaluationResult | null>(null);

  const handleFinishQuiz = (result: QuizEvaluationResult) => {
    setLastQuizResult(result);
    setCurrentScreen('RESULTS');
  };

  const primaryScreen: PrimaryScreen | null =
    currentScreen === 'DASHBOARD' ||
    currentScreen === 'UPLOAD' ||
    currentScreen === 'ANALYTICS' ||
    currentScreen === 'GRAPH'
      ? currentScreen
      : null;

  useEffect(() => {
    if (Platform.OS === 'web') {
      window.scrollTo(0, 0);
    }
  }, [currentScreen]);

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor={colors.background} />
      <View style={styles.container}>
        {currentScreen === 'DASHBOARD' && (
          <DashboardScreen
            onStartQuiz={() => setCurrentScreen('QUIZ')}
            onOpenUpload={() => setCurrentScreen('UPLOAD')}
            onOpenGraph={() => setCurrentScreen('GRAPH')}
            onOpenAnalytics={() => setCurrentScreen('ANALYTICS')}
          />
        )}

        {currentScreen === 'UPLOAD' && (
          <LectureUploadScreen
            onSuccess={() => setCurrentScreen('DASHBOARD')}
          />
        )}

        {currentScreen === 'QUIZ' && (
          <QuizScreen
            onBack={() => setCurrentScreen('DASHBOARD')}
            onFinishQuiz={handleFinishQuiz}
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
          <AnalyticsScreen />
        )}

        {currentScreen === 'GRAPH' && (
          <KnowledgeGraphScreen />
        )}

        {primaryScreen && (
          <BottomNav current={primaryScreen} onSelect={(screen) => setCurrentScreen(screen)} />
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: colors.background,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
});
