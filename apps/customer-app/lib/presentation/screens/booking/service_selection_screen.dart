import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_routes.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';

/// Service selection screen for booking with voice input support
class ServiceSelectionScreen extends StatefulWidget {
  final String category;

  const ServiceSelectionScreen({super.key, required this.category});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  final _problemController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<String> _selectedServices = [];
  final _imagePicker = ImagePicker();

  // Voice input
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  // Text already in the field before this listening session started, so
  // live partial results can be appended without wiping prior typing.
  String _textBeforeListening = '';

  String get _categoryName {
    switch (widget.category) {
      case 'PLUMBING':
        return 'Plumbing';
      case 'ELECTRICAL':
        return 'Electrical';
      case 'CLEANING':
        return 'Cleaning';
      case 'AC_REPAIR':
        return 'AC Repair';
      case 'CARPENTER':
        return 'Carpenter';
      case 'PAINTING':
        return 'Painting';
      case 'MECHANIC':
        return 'Mechanic';
      case 'GENERAL_HANDYMAN':
        return 'General Handyman';
      default:
        return 'Service';
    }
  }

  List<String> get _subServices {
    switch (widget.category) {
      case 'PLUMBING':
        return [
          'Pipe Repair',
          'Tap/Faucet',
          'Toilet Repair',
          'Drain Cleaning',
          'Water Heater',
          'Other',
        ];
      case 'ELECTRICAL':
        return [
          'Wiring',
          'Switch/Socket',
          'Fan Installation',
          'Light Fixtures',
          'Short Circuit',
          'Other',
        ];
      case 'CLEANING':
        return [
          'Deep Cleaning',
          'Regular Cleaning',
          'Kitchen Cleaning',
          'Bathroom Cleaning',
          'Carpet Cleaning',
          'Other',
        ];
      case 'AC_REPAIR':
        return [
          'AC Service',
          'AC Repair',
          'AC Installation',
          'Gas Refill',
          'Cleaning',
          'Other',
        ];
      default:
        return [
          'General Service',
          'Repair',
          'Installation',
          'Maintenance',
          'Other',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) {
      setState(() => _speechAvailable = available);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice input is not available on this device.',
          ),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice input.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _textBeforeListening = _problemController.text;
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        final separator = _textBeforeListening.isEmpty ? '' : ' ';
        final combined = '$_textBeforeListening$separator${result.recognizedWords}';
        _problemController.value = TextEditingValue(
          text: combined,
          selection: TextSelection.collapsed(offset: combined.length),
        );
        setState(() {});
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        // No localeId override — the UI promises "English or Urdu", so
        // use whatever the device's own speech-recognition locale is
        // rather than forcing English.
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _problemController.dispose();
    super.dispose();
  }

  void _analyzeProblem() {
    if (_problemController.text.isEmpty) return;

    context.read<BookingBloc>().add(
      AnalyzeProblemRequested(
        description: _problemController.text,
        category: widget.category,
      ),
    );
  }

  void _continueToLocation() {
    final problemDescription = _problemController.text.trim();

    // Must match the backend's createBookingSchema (min 10, max 1000 chars)
    // so we never let the user reach the final confirm step with a
    // description the server will reject.
    if (problemDescription.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            problemDescription.isEmpty
                ? 'Please describe your problem'
                : 'Please describe your problem in at least 10 characters',
          ),
        ),
      );
      return;
    }
    if (problemDescription.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem description must be under 1000 characters'),
        ),
      );
      return;
    }

    // Convert File objects to paths for passing to next screen
    final imagePaths = _selectedImages.map((f) => f.path).toList();

    Navigator.of(context).pushNamed(
      AppRoutes.locationSelection,
      arguments: {
        'category': widget.category,
        'problemDescription': problemDescription,
        'selectedServices': _selectedServices,
        'images': imagePaths,
      },
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 3 photos allowed')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final remainingSlots = 3 - _selectedImages.length;
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedFiles.isNotEmpty) {
      final filesToAdd = pickedFiles
          .take(remainingSlots)
          .map((f) => File(f.path))
          .toList();
      setState(() {
        _selectedImages.addAll(filesToAdd);
      });
      if (pickedFiles.length > remainingSlots) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 photos allowed')),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is ProblemAnalyzed) {
          setState(() {
            // Add AI detected services to selected services
            for (var service in state.detectedServices) {
              if (!_selectedServices.contains(service)) {
                _selectedServices.add(service);
              }
            }
          });
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_categoryName)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub-services selection
              Text(
                'What do you need help with?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _subServices.map((service) {
                  return FilterChip(
                    label: Text(service),
                    selected: _selectedServices.contains(service),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      });
                    },
                    backgroundColor: colorScheme.surface,
                    selectedColor: AppColors.primary.withValues(alpha: 0.1),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _selectedServices.contains(service)
                          ? AppColors.primary
                          : colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Problem description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Describe your problem',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  // Voice input button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusRound,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            size: 18,
                            color: _isListening
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isListening ? 'Stop' : 'Voice',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isListening
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Listening indicator
              if (_isListening)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      _buildPulsingDot(),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Listening... Speak now (English or اردو)',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                  border: _isListening
                      ? Border.all(color: AppColors.error, width: 2)
                      : null,
                ),
                child: TextField(
                  controller: _problemController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? 'Speak your problem...'
                        : 'E.g., My kitchen tap is leaking and water is dripping continuously...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    suffixIcon: _problemController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _problemController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {}); // Refresh for clear button and analyze button
                  },
                ),
              ),

              // Explicit trigger for the AI analysis — deliberately not
              // fired from onChanged/debounce, since that call now hits a
              // real (paid) OpenAI API and would fire repeatedly while the
              // user is still typing.
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _problemController.text.trim().length >= 10
                      ? _analyzeProblem
                      : null,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Detect Service (AI)'),
                ),
              ),

              // AI suggestions
              BlocBuilder<BookingBloc, BookingState>(
                builder: (context, state) {
                  if (state is BookingLoading) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Analyzing your problem...',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ProblemAnalyzed &&
                      state.detectedServices.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'AI detected: ${state.detectedServices.join(", ")}',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Add photos section
              Text(
                'Add photos (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add photo button
                    if (_selectedImages.length < 3)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppColors.primary),
                              const SizedBox(height: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Show selected images
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              child: Image.file(
                                file,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Text(
                'Up to 3 photos (${_selectedImages.length}/3)',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ElevatedButton(
              onPressed: _continueToLocation,
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: value),
          ),
        );
      },
      onEnd: () {
        if (_isListening && mounted) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
    );
  }
}
