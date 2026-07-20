import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/worker_model.dart';
import '../../../domain/repositories/worker_repository.dart';
import '../../../injection_container.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final WorkerRepository _repository = sl<WorkerRepository>();
  bool _isLoading = true;
  String? _errorMessage;
  WorkerModel? _worker;

  final List<_Document> _documents = [];
  final Map<String, Future<Uint8List>> _imageCache = {};
  bool _forceServerRefresh = false;

  /// Load image bytes over HTTP (document URLs are plain hosted URLs).
  Future<Uint8List> _loadImageBytes(String url) {
    return _imageCache.putIfAbsent(url, () async {
      final response = await sl<DioClient>().dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      // If we already refreshed _worker from server (after upload), use it.
      // Otherwise try AuthBloc, then fallback to repo.
      if (_worker == null) {
        if (!_forceServerRefresh) {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            _worker = authState.worker;
          }
        }
        // Always fetch fresh data from server when forced or AuthBloc
        // didn't have it, to ensure we have the latest document statuses
        _worker ??= await _repository.getProfile();
        _forceServerRefresh = false;
      }

      final worker = _worker;
      if (worker == null) {
        _errorMessage = 'Could not load worker profile. Please try again.';
        return;
      }

      _documents.clear();

      // Helper to convert string status from DB to DocumentStatus enum
      DocumentStatus mapStatus(String dbStatus, bool hasImage) {
        if (!hasImage) return DocumentStatus.notUploaded;
        switch (dbStatus) {
          case 'verified':
            return DocumentStatus.verified;
          case 'rejected':
            return DocumentStatus.rejected;
          case 'pending':
          default:
            return DocumentStatus.pending;
        }
      }

      // Build documents list from worker profile — use per-document status
      final hasCnicFront =
          worker.cnicFrontImage != null && worker.cnicFrontImage!.isNotEmpty;
      _documents.add(
        _Document(
          id: 'cnic_front',
          type: 'CNIC Front',
          description: 'Front side of your CNIC card',
          status: mapStatus(worker.cnicFrontStatus, hasCnicFront),
          uploadedAt: worker.createdAt,
          url: worker.cnicFrontImage,
        ),
      );

      final hasCnicBack =
          worker.cnicBackImage != null && worker.cnicBackImage!.isNotEmpty;
      _documents.add(
        _Document(
          id: 'cnic_back',
          type: 'CNIC Back',
          description: 'Back side of your CNIC card',
          status: mapStatus(worker.cnicBackStatus, hasCnicBack),
          uploadedAt: worker.createdAt,
          url: worker.cnicBackImage,
        ),
      );

      final hasProfilePhoto =
          worker.profileImage != null && worker.profileImage!.isNotEmpty;
      _documents.add(
        _Document(
          id: 'profile_photo',
          type: 'Profile Photo',
          description: 'A clear photo of yourself',
          status: mapStatus(worker.profilePhotoStatus, hasProfilePhoto),
          uploadedAt: worker.createdAt,
          url: worker.profileImage,
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = 'Failed to load documents: $msg';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(String type) async {
    // Show upload options
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLG),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Upload Document',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = source == 'camera'
        ? await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 80,
          )
        : await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 80,
          );
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        await _repository.uploadDocument(type, image.path);
        // Refresh from server to get updated URLs
        _worker = await _repository.getProfile();
        // Refresh AuthBloc so profile & documents screens show updated data
        if (mounted) {
          context.read<AuthBloc>().add(RefreshProfile());
        }
        await _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload failed: ${e.toString().replaceAll("Exception: ", "")}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showImagePreview(String url, String title) async {
    try {
      final bytes = await _loadImageBytes(url);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImagePreviewScreen(imageBytes: bytes, title: title),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load image for preview'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _worker = null;
              });
              _loadDocuments();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _documents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _worker = null;
                          _errorMessage = null;
                        });
                        _loadDocuments();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _worker = null;
                await _loadDocuments();
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildVerificationBanner(),
                  const SizedBox(height: AppSpacing.md),
                  _buildProgressCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(
                    'Required Documents',
                    Icons.verified_user,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._documents.map((d) => _buildDocumentCard(d)),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard() {
    final uploaded = _documents
        .where((d) => d.status != DocumentStatus.notUploaded)
        .length;
    final total = _documents.length;
    final progress = total > 0 ? uploaded / total : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$uploaded / $total',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                color: progress >= 1.0 ? AppColors.success : AppColors.primary,
                minHeight: 8,
              ),
            ),
            if (progress < 1.0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Upload all documents to start receiving bookings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    final allVerified =
        _documents.isNotEmpty &&
        _documents.every((d) => d.status == DocumentStatus.verified);
    final hasRejected = _documents.any(
      (d) => d.status == DocumentStatus.rejected,
    );

    Color bannerColor;
    IconData bannerIcon;
    String bannerTitle;
    String bannerSubtitle;

    if (allVerified) {
      bannerColor = AppColors.success;
      bannerIcon = Icons.verified;
      bannerTitle = 'Fully Verified';
      bannerSubtitle =
          'All your documents have been verified. You can now receive bookings!';
    } else if (hasRejected) {
      bannerColor = AppColors.error;
      bannerIcon = Icons.error_outline;
      bannerTitle = 'Action Required';
      final notes = _worker?.verificationNotes;
      bannerSubtitle = notes != null && notes.isNotEmpty
          ? 'Admin: $notes'
          : 'Some documents were rejected. Please re-upload them.';
    } else {
      bannerColor = AppColors.warning;
      bannerIcon = Icons.pending_outlined;
      bannerTitle = 'Verification Pending';
      bannerSubtitle =
          'Upload all documents. Verification may take 24-48 hours.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(bannerIcon, color: bannerColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bannerSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(_Document document) {
    final hasImage = document.url != null && document.url!.isNotEmpty;
    final isUploaded = document.status != DocumentStatus.notUploaded;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        side: BorderSide(
          color: _statusBorderColor(document.status).withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview section
          if (hasImage)
            GestureDetector(
              onTap: () => _showImagePreview(document.url!, document.type),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMD),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: FutureBuilder<Uint8List>(
                        future: _loadImageBytes(document.url!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Expand indicator
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSM,
                          ),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    // Status badge on image
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _buildStatusChip(document.status),
                    ),
                  ],
                ),
              ),
            ),

          // No image placeholder
          if (!hasImage)
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMD),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getDocumentIcon(document.type),
                    size: 40,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No image uploaded',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

          // Document info + actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Icon(
                    _getDocumentIcon(document.type),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUploaded
                            ? 'Uploaded ${_formatDate(document.uploadedAt)}'
                            : document.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Actions
                if (!hasImage)
                  // Upload button for documents without image
                  FilledButton.icon(
                    onPressed: () => _uploadDocument(document.id),
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (hasImage && document.status != DocumentStatus.verified)
                  // Replace button for uploaded but not verified docs
                  OutlinedButton.icon(
                    onPressed: () => _uploadDocument(document.id),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Replace'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (!hasImage)
                  const SizedBox()
                else if (document.status == DocumentStatus.verified)
                  _buildStatusChipSmall(DocumentStatus.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: AppColors.info.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        side: BorderSide(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Guidelines',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '• Ensure CNIC images are clear and readable\n'
                    '• Profile photo should be a recent, well-lit selfie\n'
                    '• All documents are reviewed within 24-48 hours\n'
                    '• You will be notified once verification is complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.6,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusBorderColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return AppColors.success;
      case DocumentStatus.pending:
        return AppColors.warning;
      case DocumentStatus.rejected:
        return AppColors.error;
      case DocumentStatus.notUploaded:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Widget _buildStatusChip(DocumentStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case DocumentStatus.verified:
        color = AppColors.success;
        label = 'Verified';
        icon = Icons.check_circle;
      case DocumentStatus.pending:
        color = AppColors.warning;
        label = 'Pending Review';
        icon = Icons.pending;
      case DocumentStatus.rejected:
        color = AppColors.error;
        label = 'Rejected';
        icon = Icons.cancel;
      case DocumentStatus.notUploaded:
        color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
        label = 'Not Uploaded';
        icon = Icons.upload;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: status == DocumentStatus.notUploaded
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChipSmall(DocumentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColors.success),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    if (type.contains('CNIC')) return Icons.badge;
    if (type.contains('Photo')) return Icons.person;
    if (type.contains('Certificate')) return Icons.workspace_premium;
    return Icons.description;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Full-screen image preview with zoom support
class _ImagePreviewScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;

  const _ImagePreviewScreen({required this.imageBytes, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

enum DocumentStatus { verified, pending, rejected, notUploaded }

class _Document {
  final String id;
  final String type;
  final String description;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final String? url;

  _Document({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.uploadedAt,
    this.url,
  });
}
