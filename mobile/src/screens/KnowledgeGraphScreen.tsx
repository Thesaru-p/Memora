import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { api } from '../api/client';
import { AppHeader } from '../components/AppHeader';
import { colors } from '../theme';
import { KnowledgeGraphData, GraphNode } from '../types';

export const KnowledgeGraphScreen: React.FC = () => {
  const [graphData, setGraphData] = useState<KnowledgeGraphData | null>(null);
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchGraph = async () => {
      try {
        const res = await api.getGraphData('Computer Networks');
        setGraphData(res);
        if (res.nodes.length > 0) {
          setSelectedNode(res.nodes[0]);
        }
        setLoading(false);
      } catch {
        setError('The knowledge graph is unavailable. Start the Jac backend and try again.');
        setLoading(false);
      }
    };
    fetchGraph();
  }, []);

  if (loading) {
    return (
      <View style={[styles.container, styles.center]}>
        <ActivityIndicator size="large" color={colors.primaryDark} />
        <Text style={styles.loadingText}>Fetching Object-Spatial Knowledge Graph...</Text>
      </View>
    );
  }

  if (!graphData) {
    return (
      <View style={styles.errorScreen}>
        <AppHeader />
        <Text style={styles.pageTitle}>Knowledge graph</Text>
        <Text style={styles.errorText}>{error}</Text>
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
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <AppHeader />
      <Text style={styles.pageTitle}>Knowledge graph</Text>
      <Text style={styles.pageSubtitle}>
        {graphData.subject} · concepts and prerequisite paths.
      </Text>

      {/* Concept Nodes List / Graph Canvas */}
      <View style={styles.canvasCard}>
        <Text style={styles.canvasHeader}>CONCEPTS</Text>
        <Text style={styles.canvasHint}>Tap a concept to inspect its memory state.</Text>

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
                  isSelected && { backgroundColor: colors.surfaceBlueStrong, borderWidth: 2 },
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
        <Text style={styles.canvasHeader}>PREREQUISITE PATHS</Text>
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
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: 16, paddingBottom: 28 },
  center: { justifyContent: 'center', alignItems: 'center' },
  errorScreen: { flex: 1, backgroundColor: colors.background, padding: 16 },
  errorText: { color: colors.danger, fontSize: 13, lineHeight: 19, marginTop: 8 },
  loadingText: { color: colors.muted, marginTop: 12 },
  pageTitle: { fontSize: 24, fontWeight: '800', color: colors.text },
  pageSubtitle: { fontSize: 13, color: colors.muted, marginTop: 4, marginBottom: 20 },
  canvasCard: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, borderRadius: 18, padding: 18, marginBottom: 16 },
  canvasHeader: { fontSize: 12, fontWeight: '800', color: colors.text, letterSpacing: 0.5 },
  canvasHint: { fontSize: 12, color: colors.muted, marginTop: 3, marginBottom: 14 },
  nodeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 },
  nodePill: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surfaceBlue, paddingVertical: 11, paddingHorizontal: 12, borderRadius: 14, borderWidth: 1, width: '100%', marginBottom: 6 },
  colorDot: { width: 10, height: 10, borderRadius: 5, marginRight: 10 },
  nodeLabel: { color: colors.text, fontSize: 13, fontWeight: '700', flex: 1 },
  retentionBadge: { fontSize: 13, fontWeight: '800' },
  detailCard: { backgroundColor: colors.surfaceBlue, borderRadius: 14, padding: 16, marginTop: 10, borderWidth: 1, borderColor: colors.border },
  detailHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  detailTitle: { fontSize: 16, fontWeight: '800', color: colors.text },
  statusBadge: { fontSize: 12, fontWeight: '800' },
  detailSummary: { fontSize: 13, color: colors.muted, lineHeight: 18, marginBottom: 12 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 10 },
  statItem: { alignItems: 'flex-start' },
  statLabel: { fontSize: 10, color: colors.muted },
  statNum: { fontSize: 14, fontWeight: '800', color: colors.text, marginTop: 2 },
  statSmall: { fontSize: 10, color: colors.muted, marginTop: 4 },
  edgeRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 9, borderBottomWidth: 1, borderBottomColor: colors.border },
  edgeSource: { color: colors.primaryDark, fontSize: 12, fontWeight: '600', flex: 1 },
  edgeArrow: { color: colors.muted, fontSize: 11, marginHorizontal: 4 },
  edgeTarget: { color: colors.text, fontSize: 12, fontWeight: '600', flex: 1, textAlign: 'right' },
});
