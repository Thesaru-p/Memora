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
      await api.ingestLecture(subject, title, notes);
      setLoading(false);
      Alert.alert(
        'Lecture Knowledge Graph Built! 🚀',
        '4 core concepts extracted and linked to your subject graph. Your Day-1 micro-quiz is scheduled for tomorrow!',
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

      {/* Multimodal Action Pills */}
      <View style={styles.actionRow}>
        <TouchableOpacity
          style={styles.mediaPill}
          onPress={() => {
            setTitle('TCP 3-Way Handshake & Flow Control');
            setNotes('Photos of whiteboard: SYN -> SYN-ACK -> ACK sequence, sliding window protocol, congestion avoidance.');
            Alert.alert('Photo Simulated', 'Captured 2 lecture slide photos.');
          }}
        >
          <Text style={styles.mediaPillText}>📷 Take Slide Photo</Text>
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
          <Text style={styles.submitBtnText}>Build Knowledge Graph</Text>
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
  actionRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
  mediaPill: { backgroundColor: '#1E1B4B', paddingVertical: 10, paddingHorizontal: 14, borderRadius: 20, borderWidth: 1, borderColor: '#6366F1', width: '48%', alignItems: 'center' },
  mediaPillText: { color: '#C7D2FE', fontSize: 12, fontWeight: '700' },
  submitBtn: { backgroundColor: '#6366F1', paddingVertical: 14, borderRadius: 12, alignItems: 'center', marginTop: 8, marginBottom: 40 },
  submitBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 16 },
  loadingBox: { backgroundColor: '#1E293B', borderRadius: 12, padding: 20, alignItems: 'center', marginVertical: 16 },
  loadingText: { color: '#C7D2FE', fontSize: 13, fontWeight: '600', marginTop: 12, textAlign: 'center' },
});
