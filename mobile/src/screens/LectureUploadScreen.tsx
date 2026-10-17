import React, { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { api } from '../api/client';
import { AppHeader } from '../components/AppHeader';
import { colors } from '../theme';

interface Props {
  onSuccess: () => void;
}

const subjects = ['English', 'Mathematics', 'Science', 'History', 'Geography'];

export const LectureUploadScreen: React.FC<Props> = ({ onSuccess }) => {
  const [subject, setSubject] = useState('Science');
  const [subjectMenuOpen, setSubjectMenuOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [pipelineStage, setPipelineStage] = useState('');

  const handleUpload = async () => {
    if (!title.trim() || !notes.trim()) {
      Alert.alert('Add your material', 'Enter a material title and paste the lecture notes first.');
      return;
    }

    setLoading(true);
    setPipelineStage('Extracting concepts and building your learning graph…');
    try {
      const result: any = await api.ingestLecture(subject, title, notes);
      const count = result?.total_lecture_concepts ?? result?.total_concepts ?? 0;
      Alert.alert(
        'Material ready',
        `${count} concepts were added. Your first review is scheduled in 24 hours.`,
        [{ text: 'View home', onPress: onSuccess }]
      );
    } catch (error) {
      Alert.alert('Could not process material', error instanceof Error ? error.message : 'Try again shortly.');
    } finally {
      setLoading(false);
      setPipelineStage('');
    }
  };

  const explainImageSupport = () => {
    Alert.alert('Image upload', 'Paste OCR text below for now. Native camera and gallery access will be connected with the mobile build.');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
      <AppHeader />
      <Text style={styles.pageTitle}>Material</Text>
      <Text style={styles.label}>Subject</Text>
      <TouchableOpacity style={styles.select} onPress={() => setSubjectMenuOpen((open) => !open)}>
        <Text style={styles.selectText}>{subject}</Text>
        <Text style={styles.selectArrow}>{subjectMenuOpen ? '⌃' : '⌄'}</Text>
      </TouchableOpacity>
      {subjectMenuOpen ? (
        <View style={styles.subjectMenu}>
          {subjects.map((item) => (
            <TouchableOpacity
              key={item}
              style={[styles.subjectOption, item === subject && styles.subjectOptionActive]}
              onPress={() => {
                setSubject(item);
                setSubjectMenuOpen(false);
              }}
            >
              <Text style={styles.subjectOptionText}>{item}</Text>
            </TouchableOpacity>
          ))}
        </View>
      ) : null}

      <Text style={styles.helper}>Turn your study material into a connected learning graph.</Text>
      <TouchableOpacity style={styles.uploadArea} onPress={explainImageSupport}>
        <Text style={styles.uploadIcon}>▣＋</Text>
        <Text style={styles.uploadTitle}>Click here to upload</Text>
        <Text style={styles.uploadHint}>Slides and handwritten notes</Text>
      </TouchableOpacity>

      <Text style={styles.sectionTitle}>Add more material</Text>
      <View style={styles.sourceRow}>
        <TouchableOpacity style={styles.sourceCard} onPress={explainImageSupport}>
          <Text style={styles.sourceIcon}>▣</Text>
          <Text style={styles.sourceTitle}>Camera</Text>
          <Text style={styles.sourceHint}>Capture your notes</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.sourceCard} onPress={explainImageSupport}>
          <Text style={styles.sourceIcon}>▧</Text>
          <Text style={styles.sourceTitle}>Image</Text>
          <Text style={styles.sourceHint}>Choose from gallery</Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.label}>Material title</Text>
      <TextInput
        style={styles.input}
        placeholder="e.g. Photosynthesis"
        placeholderTextColor="#91A0AA"
        value={title}
        onChangeText={setTitle}
      />
      <Text style={styles.label}>Lecture notes or transcript</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        placeholder="Paste the lecture notes or OCR text…"
        placeholderTextColor="#91A0AA"
        multiline
        value={notes}
        onChangeText={setNotes}
      />

      <Text style={styles.privacy}>✧ Your source is transformed into concepts and prerequisite links.</Text>
      {loading ? (
        <View style={styles.loadingBox}>
          <ActivityIndicator color={colors.primaryDark} />
          <Text style={styles.loadingText}>{pipelineStage}</Text>
        </View>
      ) : (
        <TouchableOpacity style={styles.submitButton} onPress={handleUpload}>
          <Text style={styles.submitButtonText}>Build learning graph</Text>
        </TouchableOpacity>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: 16, paddingBottom: 28 },
  pageTitle: { color: colors.text, fontSize: 24, fontWeight: '800', marginBottom: 10 },
  label: { color: colors.text, fontSize: 11, fontWeight: '700', marginBottom: 6, marginTop: 8 },
  select: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', width: '58%', backgroundColor: colors.surfaceBlue, borderWidth: 1, borderColor: colors.primary, borderRadius: 10, paddingHorizontal: 12, paddingVertical: 10 },
  selectText: { color: colors.text, fontSize: 13, fontWeight: '600' },
  selectArrow: { color: colors.primaryDark, fontSize: 16 },
  subjectMenu: { width: '58%', backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, borderRadius: 10, padding: 5, marginTop: 4 },
  subjectOption: { paddingHorizontal: 10, paddingVertical: 9, borderRadius: 7 },
  subjectOptionActive: { backgroundColor: colors.surfaceBlueStrong },
  subjectOptionText: { color: colors.text, fontSize: 12 },
  helper: { color: colors.muted, fontSize: 12, lineHeight: 18, marginVertical: 12 },
  uploadArea: { height: 130, backgroundColor: colors.surfaceBlueStrong, borderRadius: 18, alignItems: 'center', justifyContent: 'center', marginBottom: 16 },
  uploadIcon: { color: colors.primary, fontSize: 32, fontWeight: '700' },
  uploadTitle: { color: colors.primaryDark, fontSize: 15, fontWeight: '700', marginTop: 6 },
  uploadHint: { color: colors.muted, fontSize: 10, marginTop: 3 },
  sectionTitle: { color: colors.text, fontSize: 13, fontWeight: '800', marginBottom: 8 },
  sourceRow: { flexDirection: 'row', gap: 10, marginBottom: 14 },
  sourceCard: { flex: 1, backgroundColor: colors.surfaceBlueStrong, borderRadius: 15, padding: 14, minHeight: 92 },
  sourceIcon: { color: colors.primaryDark, fontSize: 20 },
  sourceTitle: { color: colors.text, fontSize: 13, fontWeight: '800', marginTop: 7 },
  sourceHint: { color: colors.muted, fontSize: 10, marginTop: 2 },
  input: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, borderRadius: 11, color: colors.text, fontSize: 14, paddingHorizontal: 13, paddingVertical: 11, marginBottom: 8 },
  textArea: { minHeight: 120, textAlignVertical: 'top' },
  privacy: { color: colors.muted, fontSize: 10, lineHeight: 15, marginVertical: 10 },
  submitButton: { backgroundColor: colors.primary, borderRadius: 10, paddingVertical: 14, alignItems: 'center', marginTop: 4 },
  submitButtonText: { color: colors.text, fontSize: 14, fontWeight: '800' },
  loadingBox: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surfaceBlue, borderRadius: 12, padding: 14 },
  loadingText: { flex: 1, color: colors.text, fontSize: 12, marginLeft: 10 },
});
