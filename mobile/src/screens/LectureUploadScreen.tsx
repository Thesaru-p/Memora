import React, { useEffect, useRef, useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';

interface Props {
  onBack: () => void;
  onSuccess: (subjectName: string) => void;
}

export const LectureUploadScreen: React.FC<Props> = ({ onBack, onSuccess }) => {
  const [subject, setSubject] = useState('');
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [pipelineStage, setPipelineStage] = useState('');
  const [error, setError] = useState('');
  const stageTimers = useRef<ReturnType<typeof setTimeout>[]>([]);

  useEffect(() => {
    return () => stageTimers.current.forEach(clearTimeout);
  }, []);

  const handleUpload = async () => {
    if (!subject.trim() || !title.trim() || !notes.trim()) {
      setError('Subject, lecture title, and lecture notes are required.');
      return;
    }

    setError('');
    setLoading(true);
    setPipelineStage('1/3 Extracting atomic concepts with Nemotron 3.5 Super VL...');

    stageTimers.current.forEach(clearTimeout);
    stageTimers.current = [];
    stageTimers.current.push(setTimeout(() => {
      setPipelineStage('2/3 Building Object-Spatial Knowledge Graph in Jac...');
    }, 1200));

    stageTimers.current.push(setTimeout(() => {
      setPipelineStage('3/3 Calculating Ebbinghaus stability & scheduling Day-1 quiz...');
    }, 2200));

    try {
      await api.ingestLecture(subject, title, notes);
      // Navigate directly instead of waiting for Alert's native action. This
      // is reliable in Expo Web as well as on Android/iOS.
      onSuccess(subject);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not process the lecture.');
    } finally {
      stageTimers.current.forEach(clearTimeout);
      stageTimers.current = [];
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <TouchableOpacity style={styles.backBtn} onPress={onBack}>
        <Text style={styles.backBtnText}>← Back</Text>
      </TouchableOpacity>

      <Text style={styles.pageTitle}>Add a lecture</Text>
      <Text style={styles.pageSubtitle}>Give your study coach a topic and a few notes. It will turn them into a review plan.</Text>

      <View style={styles.infoCard}>
        <Text style={styles.infoIcon}>✨</Text>
        <View style={styles.infoCopy}>
          <Text style={styles.infoTitle}>What happens next?</Text>
          <Text style={styles.infoText}>Memora extracts key concepts, links prerequisites, and schedules a Day-1 review.</Text>
        </View>
      </View>

      {/* Input Form */}
      <View style={styles.inputGroup}>
        <Text style={styles.label}>SUBJECT</Text>
        <TextInput style={styles.input} value={subject} onChangeText={setSubject} placeholderTextColor="#64748B" />
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>WHAT DID YOU LEARN?</Text>
        <TextInput
          style={styles.input}
          placeholder="e.g. Virtual Memory & Page Replacement"
          placeholderTextColor="#64748B"
          value={title}
          onChangeText={setTitle}
        />
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>NOTES OR TRANSCRIPT</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          placeholder="Paste lecture summary, key formulas, or OCR text..."
          placeholderTextColor="#64748B"
          multiline
          numberOfLines={8}
          value={notes}
          onChangeText={setNotes}
        />
      </View>

      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      {loading ? (
        <View style={styles.loadingBox}>
          <ActivityIndicator size="large" color="#6366F1" />
          <Text style={styles.loadingText}>{pipelineStage}</Text>
        </View>
      ) : (
        <TouchableOpacity style={styles.submitBtn} onPress={handleUpload}>
          <Text style={styles.submitBtnText}>Create my study plan →</Text>
        </TouchableOpacity>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  backBtn: { marginTop: 24, marginBottom: 12 },
  backBtnText: { color: '#818CF8', fontSize: 16, fontWeight: '700' },
  pageTitle: { fontSize: 22, fontWeight: '800', color: '#FFFFFF' },
  pageSubtitle: { fontSize: 13, color: '#94A3B8', marginTop: 4, marginBottom: 20 },
  infoCard: { flexDirection: 'row', backgroundColor: '#172554', borderRadius: 14, padding: 14, marginBottom: 20, borderWidth: 1, borderColor: '#3730A3' },
  infoIcon: { fontSize: 22, marginRight: 10 },
  infoCopy: { flex: 1 },
  infoTitle: { color: '#E0E7FF', fontSize: 13, fontWeight: '800' },
  infoText: { color: '#A5B4FC', fontSize: 12, lineHeight: 17, marginTop: 3 },
  inputGroup: { marginBottom: 16 },
  label: { fontSize: 11, fontWeight: '800', color: '#94A3B8', letterSpacing: 1, marginBottom: 6 },
  input: { backgroundColor: '#1E293B', borderRadius: 10, padding: 14, color: '#FFFFFF', fontSize: 15, borderWidth: 1, borderColor: '#334155' },
  textArea: { height: 140, textAlignVertical: 'top' },
  errorText: { color: '#FCA5A5', backgroundColor: '#450A0A', borderRadius: 10, padding: 12, marginBottom: 12, fontSize: 13 },
  submitBtn: { backgroundColor: '#6366F1', paddingVertical: 14, borderRadius: 12, alignItems: 'center', marginTop: 8, marginBottom: 40 },
  submitBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 16 },
  loadingBox: { backgroundColor: '#1E293B', borderRadius: 12, padding: 20, alignItems: 'center', marginVertical: 16 },
  loadingText: { color: '#C7D2FE', fontSize: 13, fontWeight: '600', marginTop: 12, textAlign: 'center' },
});
