import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/challenge_service.dart';
import 'map_picker_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String gameId;
  final String joinCode;
  final String title;

  const AdminDashboardPage({
    super.key,
    required this.gameId,
    required this.joinCode,
    required this.title,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _challengeService = ChallengeService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();

  String _selectedType = 'photo';
  int _points = 100;

  void _addChallenge() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;

    await _challengeService.addChallenge(
      gameId: widget.gameId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _selectedType,
      points: _points,
    );

    _titleCtrl.clear();
    _descCtrl.clear();
    if (mounted) Navigator.pop(context);
  }

void _showAddChallengeDialog() {
  double? selectedLat;
  double? selectedLng;
  double radius = 50; // meters default
  String? errorMsg;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> _validateAndCreate() async {
            if (_titleCtrl.text.trim().isEmpty ||
                _descCtrl.text.trim().isEmpty) {
              setModalState(() =>
                  errorMsg = 'Please enter a title and description.');
              return;
            }

            // 🚫 Must select a location for location-based challenges
            if ((_selectedType == 'location' ||
                    _selectedType == 'location_photo') &&
                (selectedLat == null || selectedLng == null)) {
              setModalState(() =>
                  errorMsg = 'Please select a location before creating.');
              return;
            }

            // ✅ Passed validation, clear error
            setModalState(() => errorMsg = null);

            await _challengeService.addChallenge(
              gameId: widget.gameId,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              type: _selectedType,
              points: _points,
              location: (_selectedType == 'location' ||
                      _selectedType == 'location_photo')
                  ? {
                      'lat': selectedLat,
                      'lng': selectedLng,
                      'radius': radius,
                    }
                  : null,
            );

            _titleCtrl.clear();
            _descCtrl.clear();
            if (mounted) Navigator.pop(context);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add New Challenge',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: _descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration:
                        const InputDecoration(labelText: 'Challenge Type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'photo', child: Text('Photo')),
                      DropdownMenuItem(
                          value: 'text', child: Text('Text Response')),
                      DropdownMenuItem(
                          value: 'location', child: Text('Location Task')),
                      DropdownMenuItem(
                          value: 'location_photo',
                          child: Text('Location + Photo')),
                    ],
                    onChanged: (v) =>
                        setModalState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 10),

                  // 🗺️ Location picker
                  if (_selectedType == 'location' ||
                      _selectedType == 'location_photo')
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('Select Location on Map'),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapPickerPage(),
                              ),
                            );
                            if (result != null &&
                                result is Map<String, dynamic>) {
                              setModalState(() {
                                selectedLat = result['lat'];
                                selectedLng = result['lng'];
                                radius = result['radius'];
                              });
                            }
                          },
                        ),
                        if (selectedLat != null && selectedLng != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Selected: (${selectedLat!.toStringAsFixed(5)}, '
                              '${selectedLng!.toStringAsFixed(5)}) — ${radius.toStringAsFixed(0)}m radius',
                            ),
                          ),
                      ],
                    ),

                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _points = int.tryParse(v) ?? 100,
                  ),

                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Challenge'),
                    onPressed: _validateAndCreate,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  Future<void> _deleteChallenge(String challengeId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challenge?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('challenges')
          .doc(challengeId)
          .delete();
    }
  }

  Future<void> _openEditChallenge(
    String challengeId,
    Map<String, dynamic> data,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditChallengePage(
          gameId: widget.gameId,
          challengeId: challengeId,
          data: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Dashboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChallengeDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .snapshots(),
        builder: (context, gameSnapshot) {
          if (!gameSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final gameData = gameSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final isActive = gameData['isActive'] ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────── Header + Start Game Button ───────────
              Container(
                color: Colors.deepOrange.shade100,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Join Code: ${widget.joinCode}',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(isActive ? Icons.check : Icons.play_arrow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.green : Colors.deepOrange,
                          ),
                          onPressed: isActive
                              ? null
                              : () async {
                                  await FirebaseFirestore.instance
                                      .collection('games')
                                      .doc(widget.gameId)
                                      .update({'isActive': true});
                                },
                          label: Text(
                            isActive ? 'Game Started' : 'Start Game',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isActive)
                          const Text(
                            'Game is live!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─────────── Challenge List ───────────
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Challenges',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _challengeService.getChallenges(widget.gameId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No challenges yet. Add one!'));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>? ?? {};
                        final title = data['title'] ?? '';
                        final desc = data['description'] ?? '';
                        final points = (data['points'] ?? 0).toString();
                        final type = (data['type'] ?? '').toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text('$desc • $type • $points pts'),
                            trailing: const Icon(Icons.more_horiz),

                            // 👇 Long press reveals Edit / Delete
                            onLongPress: () async {
                              final choice = await showModalBottomSheet<String>(
                                context: context,
                                builder: (ctx) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.edit, color: Colors.blue),
                                          title: const Text('Edit Challenge'),
                                          onTap: () => Navigator.pop(ctx, 'edit'),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Delete Challenge'),
                                          onTap: () => Navigator.pop(ctx, 'delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );

                              if (choice == 'delete') {
                                await _deleteChallenge(docs[i].id, title);
                              } else if (choice == 'edit') {
                                await _openEditChallenge(docs[i].id, data);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────
/// Edit screen for an existing challenge
/// ─────────────────────────────────────────────────────────────────
class EditChallengePage extends StatefulWidget {
  final String gameId;
  final String challengeId;
  final Map<String, dynamic> data;

  const EditChallengePage({
    super.key,
    required this.gameId,
    required this.challengeId,
    required this.data,
  });

  @override
  State<EditChallengePage> createState() => _EditChallengePageState();
}

class _EditChallengePageState extends State<EditChallengePage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _pointsCtrl;
  late TextEditingController _extraCtrl;

  String _type = 'photo';

  double? _lat;
  double? _lng;
  double _radius = 50;

  @override
  void initState() {
    super.initState();
    final data = widget.data;

    _titleCtrl = TextEditingController(text: data['title'] ?? '');
    _descCtrl = TextEditingController(text: data['description'] ?? '');
    _pointsCtrl = TextEditingController(text: (data['points'] ?? 0).toString());
    _extraCtrl = TextEditingController(text: (data['extraChallenge'] ?? '').toString());

    _type = (data['type'] ?? 'photo').toString();

    // Load location (supports both GeoPoint or map storage)
    final loc = data['location'];
    if (loc != null) {
      if (loc is GeoPoint) {
        _lat = loc.latitude;
        _lng = loc.longitude;
      } else if (loc is Map) {
        final lat = loc['lat'];
        final lng = loc['lng'];
        if (lat is num) _lat = lat.toDouble();
        if (lng is num) _lng = lng.toDouble();
        if (loc['radius'] is num) _radius = (loc['radius'] as num).toDouble();
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _lat = (result['lat'] as num?)?.toDouble();
        _lng = (result['lng'] as num?)?.toDouble();
        _radius = (result['radius'] as num?)?.toDouble() ?? 50;
      });
    }
  }

  Future<void> _saveChanges() async {
    final Map<String, dynamic> update = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'points': int.tryParse(_pointsCtrl.text.trim()) ?? 0,
      'type': _type,
      'extraChallenge': _extraCtrl.text.trim().isEmpty ? null : _extraCtrl.text.trim(),
    };

    if (_type == 'location' || _type == 'location_photo') {
      if (_lat != null && _lng != null) {
        update['location'] = {
          'lat': _lat,
          'lng': _lng,
          'radius': _radius,
        };
      }
    } else {
      // Remove location for non-location types
      update['location'] = FieldValue.delete();
    }

    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .collection('challenges')
        .doc(widget.challengeId)
        .update(update);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoc = _type == 'location' || _type == 'location_photo';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Challenge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Challenge Type'),
              items: const [
                DropdownMenuItem(value: 'photo', child: Text('Photo')),
                DropdownMenuItem(value: 'text', child: Text('Text Response')),
                DropdownMenuItem(value: 'location', child: Text('Location Task')),
                DropdownMenuItem(value: 'location_photo', child: Text('Location + Photo')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'photo'),
            ),
            const SizedBox(height: 10),

            if (isLoc)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Pick Location'),
                    onPressed: _pickLocation,
                  ),
                  if (_lat != null && _lng != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selected: (${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}) — ${_radius.toStringAsFixed(0)}m radius',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 10),
            TextField(
              controller: _pointsCtrl,
              decoration: const InputDecoration(labelText: 'Points'),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _extraCtrl,
              decoration: const InputDecoration(
                labelText: 'Extra Challenge (shown after location confirm)',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
