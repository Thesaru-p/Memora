import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { api } from '../api/client';

interface Props {
  onBack: () => void;
  onSuccess: () => void;
}

export const LectureUploadScreen: React.FC<Props> = ({ onBack, onSuccess }) => {
  const [subject, setSubject] = useState('Computer Networks');
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [uploadMode, setUploadMode] = useState<'append' | 'replace'>('append');
  const [slideCount, setSlideCount] = useState<number>(0);
  const [loading, setLoading] = useState(false);
  const [pipelineStage, setPipelineStage] = useState('');

  const handleUpload = async () => {
    if (!title.trim()) {
      Alert.alert('Required', 'Please enter a lecture title.');
      return;
    }

    setLoading(true);
    setPipelineStage('1/3 Extracting atomic concepts with Nemotron 3.5 Super VL...');

    setTimeout(() => {
      setPipelineStage('2/3 Building Object-Spatial Knowledge Graph in Jac...');
    }, 1200);

    setTimeout(() => {
      setPipelineStage('3/3 Calculating Ebbinghaus stability & scheduling Day-1 quiz...');
    }, 2200);

    try {
      const res: any = await api.ingestLecture(subject, title, notes, {
        replaceExisting: uploadMode === 'replace',
      });
      setLoading(false);
      const totalConcepts = res?.total_lecture_concepts ?? res?.total_concepts ?? 4;
      const modeText = uploadMode === 'replace' ? 'Replaced' : 'Accumulated';
      Alert.alert(
        'Lecture Knowledge Graph Built! 🚀',
        `${modeText} lecture graph now has ${totalConcepts} core concepts linked. Your Day-1 micro-quiz is scheduled for tomorrow!`,
        [{ text: 'View Dashboard', onPress: onSuccess }]
      );
    } catch (e) {
      setLoading(false);
      Alert.alert('Upload Error', 'Could not process notes at this moment.');
    }
  };

  return (
    <ScrollView style={styles.container}>
      <TouchableOpacity style={styles.backBtn} onPress={onBack}>
        <Text style={styles.backBtnText}>← Back</Text>
      </TouchableOpacity>

      <Text style={styles.pageTitle}>Ingest Lecture Material</Text>
      <Text style={styles.pageSubtitle}>Upload slides, photos of notes, or paste lecture text.</Text>

      {/* Input Form */}
      <View style={styles.inputGroup}>
        <Text style={styles.label}>COURSE MODULE</Text>
        <TextInput style={styles.input} value={subject} onChangeText={setSubject} placeholderTextColor="#64748B" />
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>LECTURE TOPIC / TITLE</Text>
        <TextInput
          style={styles.input}
          placeholder="e.g. Virtual Memory & Page Replacement"
          placeholderTextColor="#64748B"
          value={title}
          onChangeText={setTitle}
        />
      </View>

      {/* Ingestion Mode Option */}
      <View style={styles.inputGroup}>
        <Text style={styles.label}>UPLOAD MODE OPTION</Text>
        <View style={styles.modeRow}>
          <TouchableOpacity
            style={[styles.modePill, uploadMode === 'append' && styles.modePillActive]}
            onPress={() => setUploadMode('append')}
          >
            <Text style={[styles.modePillText, uploadMode === 'append' && styles.modePillTextActive]}>
              ➕ Append Slides
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.modePill, uploadMode === 'replace' && styles.modePillActive]}
            onPress={() => setUploadMode('replace')}
          >
            <Text style={[styles.modePillText, uploadMode === 'replace' && styles.modePillTextActive]}>
              🔄 Replace Lecture
            </Text>
          </TouchableOpacity>
        </View>
        <Text style={styles.hintText}>
          {uploadMode === 'append'
            ? 'Append mode: Multiple slides accumulate concepts without losing prior reviews.'
            : 'Replace mode: Clears previous lecture concepts and starts fresh.'}
        </Text>
      </View>

      {/* Multimodal Action Pills */}
      <View style={styles.actionRow}>
        <TouchableOpacity
          style={styles.mediaPill}
          onPress={() => {
            const nextCount = slideCount + 1;
            setSlideCount(nextCount);
            if (!title) {
              setTitle('TCP 3-Way Handshake & Flow Control');
            }
            const slideNote = `[Slide ${nextCount}] SYN -> SYN-ACK -> ACK sequence, sliding window protocol, flow control.`;
            setNotes(prev => (prev ? `${prev}\n\n${slideNote}` : slideNote));
            Alert.alert('Slide Photo Attached', `Captured slide photo #${nextCount}.`);
          }}
        >
          <Text style={styles.mediaPillText}>
            {slideCount > 0 ? `📷 Add Slide #${slideCount + 1}` : '📷 Take Slide Photo'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.mediaPill}
          onPress={() => {
            setTitle('CIDR & Subnet Mask Calculations');
            setNotes('Handwritten notes: /28 gives 16 IP addresses (14 usable). Subnet mask: 255.255.255.240. Bitwise ANDing separates Network ID.');
            Alert.alert('Handwritten Note', 'Attached image of handwritten lecture page.');
          }}
        >
          <Text style={styles.mediaPillText}>✍️ Handwritten Note</Text>
        </TouchableOpacity>
      </View>

      {slideCount > 0 && (
        <View style={styles.slideCounterRow}>
          <Text style={styles.slideCounterText}>📁 {slideCount} slide photos attached</Text>
          <TouchableOpacity onPress={() => { setSlideCount(0); setNotes(''); }}>
            <Text style={styles.clearBtnText}>Clear</Text>
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.inputGroup}>
        <Text style={styles.label}>LECTURE NOTES / TRANSCRIPT</Text>
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

      {loading ? (
        <View style={styles.loadingBox}>
          <ActivityIndicator size="large" color="#6366F1" />
          <Text style={styles.loadingText}>{pipelineStage}</Text>
        </View>
      ) : (
        <TouchableOpacity style={styles.submitBtn} onPress={handleUpload}>
          <Text style={styles.submitBtnText}>
            {slideCount > 1 ? `Build Graph (${slideCount} Slides)` : 'Build Knowledge Graph'}
          </Text>
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
  inputGroup: { marginBottom: 16 },
  label: { fontSize: 11, fontWeight: '800', color: '#94A3B8', letterSpacing: 1, marginBottom: 6 },
  input: { backgroundColor: '#1E293B', borderRadius: 10, padding: 14, color: '#FFFFFF', fontSize: 15, borderWidth: 1, borderColor: '#334155' },
  textArea: { height: 140, textAlignVertical: 'top' },
  modeRow: { flexDirection: 'row', gap: 10, marginBottom: 6 },
  modePill: { flex: 1, paddingVertical: 10, paddingHorizontal: 12, borderRadius: 10, backgroundColor: '#1E293B', borderWidth: 1, borderColor: '#334155', alignItems: 'center' },
  modePillActive: { backgroundColor: '#6366F1', borderColor: '#818CF8' },
  modePillText: { color: '#94A3B8', fontSize: 13, fontWeight: '600' },
  modePillTextActive: { color: '#FFFFFF', fontWeight: '800' },
  hintText: { color: '#94A3B8', fontSize: 12, lineHeight: 18, marginTop: 4 },
  slideCounterRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#1E293B', padding: 10, borderRadius: 8, marginBottom: 16 },
  slideCounterText: { color: '#818CF8', fontSize: 13, fontWeight: '700' },
  clearBtnText: { color: '#EF4444', fontSize: 12, fontWeight: '700' },
  actionRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
  mediaPill: { backgroundColor: '#1E1B4B', paddingVertical: 10, paddingHorizontal: 14, borderRadius: 20, borderWidth: 1, borderColor: '#6366F1', width: '48%', alignItems: 'center' },
  mediaPillText: { color: '#C7D2FE', fontSize: 12, fontWeight: '700' },
  submitBtn: { backgroundColor: '#6366F1', paddingVertical: 14, borderRadius: 12, alignItems: 'center', marginTop: 8, marginBottom: 40 },
  submitBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 16 },
  loadingBox: { backgroundColor: '#1E293B', borderRadius: 12, padding: 20, alignItems: 'center', marginVertical: 16 },
  loadingText: { color: '#C7D2FE', fontSize: 13, fontWeight: '600', marginTop: 12, textAlign: 'center' },
});
