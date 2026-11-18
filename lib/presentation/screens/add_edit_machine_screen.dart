import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_machine.dart';
import '../viewmodels/workout_viewmodel.dart';

class AddEditMachineScreen extends StatefulWidget {
  final WorkoutViewModel viewModel;
  final ExerciseMachine? initialExercise;

  const AddEditMachineScreen({
    super.key,
    required this.viewModel,
    this.initialExercise,
  });

  @override
  State<AddEditMachineScreen> createState() => _AddEditMachineScreenState();
}

class _AddEditMachineScreenState extends State<AddEditMachineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late String _selectedMuscle;
  String? _photoPath;
  bool _isSaving = false;

  final List<String> _muscles = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Core',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialExercise?.name ?? '');
    _notesController = TextEditingController(text: widget.initialExercise?.adjustmentNotes ?? '');
    _selectedMuscle = widget.initialExercise?.targetMuscle ?? 'Chest';
    if (!_muscles.contains(_selectedMuscle)) {
      _selectedMuscle = 'Chest';
    }
    _photoPath = widget.initialExercise?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await widget.viewModel.pickAndStoreImage(source);
    if (path != null) {
      setState(() {
        _photoPath = path;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await widget.viewModel.saveExercise(
      id: widget.initialExercise?.id,
      name: _nameController.text,
      targetMuscle: _selectedMuscle,
      adjustmentNotes: _notesController.text,
      photoPath: _photoPath,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialExercise != null;

    return Scaffold(
      backgroundColor: AppTheme.bgCore,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Machine Setup' : 'Add Gym Machine'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exercise / Machine Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise / Machine Name',
                  hintText: 'e.g., Incline Plate-Loaded Chest Press',
                ),
                style: const TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.w600),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a machine or exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Muscle Group Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedMuscle,
                dropdownColor: AppTheme.bgCard,
                decoration: const InputDecoration(
                  labelText: 'Target Muscle Group',
                ),
                style: const TextStyle(color: AppTheme.textMain, fontSize: 15, fontWeight: FontWeight.w600),
                items: _muscles.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMuscle = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Machine Adjustment Pin Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Machine Adjustment Notes (Seat & Pin)',
                  hintText: 'e.g., Seat height: #4 | Pin hole: 2nd from top | Backpad: 30° | Neutral grip',
                ),
                style: const TextStyle(color: AppTheme.textMain),
              ),
              const SizedBox(height: 20),

              // Machine Photo Capture & Upload
              const Text(
                'MACHINE SETUP PHOTO / ANGLE',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Photo Container Preview
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _photoPath != null ? AppTheme.neonCyan : AppTheme.borderSubtle,
                    width: _photoPath != null ? 1.5 : 1,
                  ),
                ),
                child: _photoPath != null && File(_photoPath!).existsSync()
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_photoPath!),
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black87,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.neonRed, size: 20),
                                onPressed: () {
                                  setState(() => _photoPath = null);
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 48, color: AppTheme.textDim.withAlpha(160)),
                          const SizedBox(height: 8),
                          const Text(
                            'Capture or upload machine angle photo',
                            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              // Camera and Gallery buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera, color: AppTheme.neonCyan),
                      label: const Text(
                        'Take Photo',
                        style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.neonCyan),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: AppTheme.textSecondary),
                      label: const Text(
                        'Gallery',
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEditing ? 'UPDATE MACHINE' : 'ADD MACHINE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
