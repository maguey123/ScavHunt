import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../services/challenge_service.dart';
import '../map_picker_page.dart';

class ChallengesTab extends StatefulWidget {
  final String gameId;
  final Map<String, dynamic> gameData;

  const ChallengesTab({super.key, required this.gameId, required this.gameData});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  final _service = ChallengeService();

  void _showAddSheet({String? editId, Map<String, dynamic>? existing}) {
    final titleCtrl   = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl    = TextEditingController(text: existing?['description'] ?? '');
    final extraCtrl   = TextEditingController(text: existing?['extraChallenge'] ?? '');
    final pointsCtrl  = TextEditingController(
        text: (existing?['points'] ?? 100).toString());

    String type = existing?['type'] ?? 'photo';
    double? lat, lng;
    double radius = 50;
    bool released = existing?['released'] ?? true;
    bool hasTimer = existing?['releaseAfterMinutes'] != null;
    int timerMins = existing?['releaseAfterMinutes'] ?? 30;
    String? error;

    // Preload location
    final loc = existing?['location'];
    if (loc is Map) {
      lat = (loc['lat'] as num?)?.toDouble();
      lng = (loc['lng'] as num?)?.toDouble();
      radius = (loc['radius'] as num?)?.toDouble() ?? 50;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ScavColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: ScavColors.border,
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(editId == null ? 'Add Challenge' : 'Edit Challenge',
                style: const TextStyle(color: ScavColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Title
              _sheetLabel('Title *'),
              const SizedBox(height: 6),
              TextField(controller: titleCtrl,
                style: const TextStyle(color: ScavColors.textPrimary),
                decoration: const InputDecoration(hintText: 'e.g. Find the red door')),
              const SizedBox(height: 12),

              // Description
              _sheetLabel('Description *'),
              const SizedBox(height: 6),
              TextField(controller: descCtrl, maxLines: 2,
                style: const TextStyle(color: ScavColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Instructions for players')),
              const SizedBox(height: 12),

              // Type
              _sheetLabel('Type'),
              const SizedBox(height: 6),
              _TypeSelector(
                value: type,
                onChanged: (v) => setS(() => type = v),
              ),
              const SizedBox(height: 12),

              // Points
              _sheetLabel('Points'),
              const SizedBox(height: 6),
              TextField(controller: pointsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: ScavColors.textPrimary),
                decoration: const InputDecoration(hintText: '100')),
              const SizedBox(height: 12),

              // Location picker
              if (type == 'location' || type == 'location_photo') ...[
                _sheetLabel('Location'),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.map_outlined, color: ScavColors.accent, size: 18),
                  label: Text(
                    lat != null ? 'Change location' : 'Pick Location',
                    style: const TextStyle(color: ScavColors.accent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ScavColors.accent),
                    minimumSize: const Size(double.infinity, 44)),
                  onPressed: () async {
                    final r = await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MapPickerPage(
                        initialLat: lat, initialLng: lng)));
                    if (r != null) setS(() {
                      lat = r['lat']; lng = r['lng']; radius = r['radius'];
                    });
                  },
                ),
                if (lat != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '📍  ${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)} · ${radius.toStringAsFixed(0)}m radius',
                      style: const TextStyle(color: ScavColors.green, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
              ],

              // Extra challenge (for location_photo)
              if (type == 'location_photo') ...[
                _sheetLabel('Extra Challenge (shown after location confirm)'),
                const SizedBox(height: 6),
                TextField(controller: extraCtrl,
                  style: const TextStyle(color: ScavColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'e.g. Take a selfie with the statue')),
                const SizedBox(height: 12),
              ],

              // Visibility / scheduled release
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ScavColors.surfaceHi,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ScavColors.border),
                ),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Visibility', style: TextStyle(color: ScavColors.textPrimary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(released ? 'Released to players' : 'Hidden from players',
                        style: const TextStyle(color: ScavColors.textMuted, fontSize: 11)),
                    ])),
                    Switch(
                      value: released,
                      onChanged: (v) => setS(() => released = v),
                      activeColor: ScavColors.accent,
                      inactiveTrackColor: ScavColors.border,
                    ),
                  ]),
                  const Divider(height: 16, color: ScavColors.border),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('⏱  Scheduled Release', style: TextStyle(
                        color: ScavColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      const Text('Unlocks automatically after game start',
                        style: TextStyle(color: ScavColors.textMuted, fontSize: 11)),
                    ])),
                    Switch(
                      value: hasTimer,
                      onChanged: (v) => setS(() => hasTimer = v),
                      activeColor: ScavColors.accent,
                      inactiveTrackColor: ScavColors.border,
                    ),
                  ]),
                  if (hasTimer) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Slider(
                        value: timerMins.toDouble(),
                        min: 5, max: 120, divisions: 23,
                        onChanged: (v) => setS(() => timerMins = v.round()),
                      )),
                      Text('$timerMins min', style: const TextStyle(
                        color: ScavColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    Text('Players won\'t see this until $timerMins mins after game starts.',
                      style: const TextStyle(color: ScavColors.textMuted, fontSize: 11)),
                  ],
                ]),
              ),

              if (error != null) ...[
                const SizedBox(height: 10),
                ScavStatusBanner(error!, color: ScavColors.red, icon: Icons.error_outline),
              ],

              const SizedBox(height: 16),
              ScavPrimaryButton(
                label: editId == null ? 'Save Challenge' : 'Update Challenge',
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                    setS(() => error = 'Title and description are required.');
                    return;
                  }
                  if ((type == 'location' || type == 'location_photo') && lat == null) {
                    setS(() => error = 'Please pick a location for this challenge.');
                    return;
                  }

                  final data = {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'type': type,
                    'points': int.tryParse(pointsCtrl.text) ?? 100,
                    'extraChallenge': extraCtrl.text.trim().isEmpty ? null : extraCtrl.text.trim(),
                    'released': released,
                    'releaseAfterMinutes': hasTimer ? timerMins : null,
                    'location': (type == 'location' || type == 'location_photo') && lat != null
                        ? {'lat': lat, 'lng': lng, 'radius': radius}
                        : null,
                  };

                  if (editId == null) {
                    data['createdAt'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance
                        .collection('games').doc(widget.gameId)
                        .collection('challenges').add(data);
                  } else {
                    await _service.updateChallenge(
                      gameId: widget.gameId, challengeId: editId, data: data);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ScavSecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _delete(String id, String title) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: ScavColors.surfaceHi,
      title: const Text('Delete challenge?', style: TextStyle(color: ScavColors.textPrimary)),
      content: Text('Remove "$title"? This cannot be undone.',
        style: const TextStyle(color: ScavColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: ScavColors.textMuted))),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: ScavColors.red))),
      ],
    ));
    if (ok == true) await _service.deleteChallenge(widget.gameId, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScavColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ScavColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Challenge', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddSheet(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getChallenges(widget.gameId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: ScavColors.accent));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return _empty();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final title  = data['title'] ?? '';
              final desc   = data['description'] ?? '';
              final type   = data['type'] ?? 'photo';
              final points = data['points'] ?? 0;
              final released = data['released'] ?? true;
              final timerMins = data['releaseAfterMinutes'];

              return GestureDetector(
                onLongPress: () => _showActionSheet(docs[i].id, title, data),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ScavColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ScavColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: ScavColors.surfaceHi,
                        borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(challengeTypeEmoji(type),
                        style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(color: ScavColors.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(color: ScavColors.textSecondary,
                        fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, children: [
                        ScavChip('+$points', color: ScavColors.accent),
                        ScavChip(challengeTypeLabel(type), color: ScavColors.textSecondary),
                        if (!released) ScavChip('Hidden', color: ScavColors.red),
                        if (timerMins != null) ScavChip('⏱ ${timerMins}m', color: ScavColors.purple),
                      ]),
                    ])),
                    const Icon(Icons.more_horiz, color: ScavColors.textMuted, size: 20),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showActionSheet(String id, String title, Map<String, dynamic> data) {
    showModalBottomSheet(context: context, backgroundColor: ScavColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4,
          decoration: BoxDecoration(color: ScavColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.edit_outlined, color: ScavColors.textPrimary),
          title: const Text('Edit Challenge', style: TextStyle(color: ScavColors.textPrimary)),
          onTap: () { Navigator.pop(context); _showAddSheet(editId: id, existing: data); },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: ScavColors.red),
          title: const Text('Delete Challenge', style: TextStyle(color: ScavColors.red)),
          onTap: () { Navigator.pop(context); _delete(id, title); },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🎯', style: TextStyle(fontSize: 40)),
    const SizedBox(height: 12),
    const Text('No challenges yet', style: TextStyle(color: ScavColors.textSecondary,
      fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    const Text('Tap + Add Challenge to get started',
      style: TextStyle(color: ScavColors.textMuted, fontSize: 13)),
  ]));

  Widget _sheetLabel(String t) => Text(t, style: const TextStyle(
    color: ScavColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));
}

// Type selector chips
class _TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.value, required this.onChanged});

  static const _types = [
    ('photo', '📸', 'Photo'),
    ('text', '💬', 'Text'),
    ('location', '📍', 'Location'),
    ('location_photo', '📍📸', 'Loc + Photo'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
    for (final (v, emoji, label) in _types)
      GestureDetector(
        onTap: () => onChanged(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: value == v ? ScavColors.accentLo : ScavColors.surfaceHi,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: value == v ? ScavColors.accent : ScavColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: value == v ? ScavColors.accent : ScavColors.textSecondary,
              fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
  ]);
}
