import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';
import { KnowledgeGraphData, GraphNode } from '../types';

interface Props {
  subjectName: string;
  onBack: () => void;
}

export const KnowledgeGraphScreen: React.FC<Props> = ({ subjectName, onBack }) => {
  const [graphData, setGraphData] = useState<KnowledgeGraphData | null>(null);
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchGraph = async () => {
      try {
        if (!subjectName) throw new Error('No lecture subject is loaded.');
        const res = await api.getGraphData(subjectName);
        setGraphData(res);
        if (res.nodes.length > 0) {
          setSelectedNode(res.nodes[0]);
        }
        setLoading(false);
      } catch (e) {
        console.error(e);
        setError(e instanceof Error ? e.message : 'Could not load the knowledge graph.');
        setLoading(false);
      }
    };
    fetchGraph();
  }, [subjectName]);

  if (loading || !graphData) {
    return (
      <View style={[styles.container, styles.center]}>
        {error ? <Text style={styles.errorText}>{error}</Text> : <ActivityIndicator size="large" color="#6366F1" />}
        {!error && <Text style={styles.loadingText}>Fetching Object-Spatial Knowledge Graph...</Text>}
        {error && <TouchableOpacity style={styles.backAction} onPress={onBack}><Text style={styles.backActionText}>Return</Text></TouchableOpacity>}
      </View>
    );
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'STRONG':
        return '#10B981';
      case 'FADING':
        return '#F59E0B';
      case 'CRITICAL':
        return '#EF4444';
      default:
        return '#818CF8';
    }
  };

  return (
    <ScrollView style={styles.container}>
      <TouchableOpacity style={styles.backBtn} onPress={onBack}>
        <Text style={styles.backBtnText}>← Back</Text>
      </TouchableOpacity>

      <Text style={styles.pageTitle}>Knowledge Graph: {graphData.subject}</Text>
      <Text style={styles.pageSubtitle}>
        Persistent Jac graph topology. Color-coded by Ebbinghaus retention decay.
      </Text>

      {/* Concept Nodes List / Graph Canvas */}
      <View style={styles.canvasCard}>
        <Text style={styles.canvasHeader}>CONCEPTS &amp; RETENTION STATUS</Text>
        <Text style={styles.canvasHint}>Tap any concept to inspect memory parameters:</Text>

        <View style={styles.nodeGrid}>
          {graphData.nodes.map((node) => {
            const isSelected = selectedNode?.id === node.id;
            const color = getStatusColor(node.status);
            return (
              <TouchableOpacity
                key={node.id}
                style={[
                  styles.nodePill,
                  { borderColor: color },
                  isSelected && { backgroundColor: '#1E1B4B', borderWidth: 2 },
                ]}
                onPress={() => setSelectedNode(node)}
              >
                <View style={[styles.colorDot, { backgroundColor: color }]} />
                <Text style={styles.nodeLabel}>{node.label}</Text>
                <Text style={[styles.retentionBadge, { color }]}>{node.retention_pct}%</Text>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Selected Node Details Card */}
        {selectedNode && (
          <View style={styles.detailCard}>
            <View style={styles.detailHeader}>
              <Text style={styles.detailTitle}>{selectedNode.label}</Text>
              <Text style={[styles.statusBadge, { color: getStatusColor(selectedNode.status) }]}>
                ● {selectedNode.status}
              </Text>
            </View>

            <Text style={styles.detailSummary}>{selectedNode.summary}</Text>

            <View style={styles.statsRow}>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Retention</Text>
                <Text style={[styles.statNum, { color: getStatusColor(selectedNode.status) }]}>
                  {selectedNode.retention_pct}%
                </Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Mastery Level</Text>
                <Text style={styles.statNum}>{Math.round(selectedNode.mastery_score * 100)}%</Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Node ID</Text>
                <Text style={styles.statSmall}>{selectedNode.id}</Text>
              </View>
            </View>
          </View>
        )}
      </View>

      {/* Prerequisite Edges Section */}
      <View style={[styles.canvasCard, { marginBottom: 40 }]}>
        <Text style={styles.canvasHeader}>PREREQUISITE RELATIONSHIPS (EDGES)</Text>
        {graphData.edges.map((edge, idx) => (
          <View key={idx} style={styles.edgeRow}>
            <Text style={styles.edgeSource}>{edge.source.replace('c_', '')}</Text>
            <Text style={styles.edgeArrow}>—[depends_on]→</Text>
            <Text style={styles.edgeTarget}>{edge.target.replace('c_', '')}</Text>
          </View>
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0B0F19', padding: 16 },
  center: { justifyContent: 'center', alignItems: 'center' },
  loadingText: { color: '#C7D2FE', marginTop: 12 },
  errorText: { color: '#FCA5A5', backgroundColor: '#450A0A', padding: 12, borderRadius: 10, textAlign: 'center' },
  backAction: { backgroundColor: '#6366F1', paddingVertical: 12, paddingHorizontal: 18, borderRadius: 10, marginTop: 16 },
  backActionText: { color: '#FFFFFF', fontWeight: '700' },
  backBtn: { marginTop: 24, marginBottom: 12 },
  backBtnText: { color: '#818CF8', fontSize: 16, fontWeight: '700' },
  pageTitle: { fontSize: 22, fontWeight: '800', color: '#FFFFFF' },
  pageSubtitle: { fontSize: 13, color: '#94A3B8', marginTop: 4, marginBottom: 20 },
  canvasCard: { backgroundColor: '#1E293B', borderRadius: 16, padding: 18, marginBottom: 16 },
  canvasHeader: { fontSize: 11, fontWeight: '800', color: '#94A3B8', letterSpacing: 1 },
  canvasHint: { fontSize: 12, color: '#64748B', marginTop: 2, marginBottom: 14 },
  nodeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 },
  nodePill: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#0F172A', paddingVertical: 10, paddingHorizontal: 12, borderRadius: 20, borderWidth: 1, width: '100%', marginBottom: 6 },
  colorDot: { width: 10, height: 10, borderRadius: 5, marginRight: 10 },
  nodeLabel: { color: '#FFFFFF', fontSize: 13, fontWeight: '700', flex: 1 },
  retentionBadge: { fontSize: 13, fontWeight: '800' },
  detailCard: { backgroundColor: '#0F172A', borderRadius: 12, padding: 16, marginTop: 10, borderWidth: 1, borderColor: '#334155' },
  detailHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  detailTitle: { fontSize: 16, fontWeight: '800', color: '#FFFFFF' },
  statusBadge: { fontSize: 12, fontWeight: '800' },
  detailSummary: { fontSize: 13, color: '#CBD5E1', lineHeight: 18, marginBottom: 12 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, borderTopColor: '#1E293B', paddingTop: 10 },
  statItem: { alignItems: 'flex-start' },
  statLabel: { fontSize: 10, color: '#64748B' },
  statNum: { fontSize: 14, fontWeight: '800', color: '#FFFFFF', marginTop: 2 },
  statSmall: { fontSize: 10, color: '#94A3B8', marginTop: 4 },
  edgeRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#0F172A' },
  edgeSource: { color: '#818CF8', fontSize: 12, fontWeight: '600', flex: 1 },
  edgeArrow: { color: '#64748B', fontSize: 11, marginHorizontal: 4 },
  edgeTarget: { color: '#A5B4FC', fontSize: 12, fontWeight: '600', flex: 1, textAlign: 'right' },
});
