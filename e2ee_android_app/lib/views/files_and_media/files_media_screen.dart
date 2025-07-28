import 'dart:io';

import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';

// import '../../backend/common/app_theme/app_theme_controller.dart';
// import '../../backend/common/app_theme/app_theme_provider.dart';

enum FileType { image, video, document, audio, unknown }

class ChatFile {
  final String fileName;
  final FileType type;
  final String sender;
  final String dateTime;
  final String size;
  final String? thumbnailUrl;
  final bool isEncrypted;

  ChatFile({
    required this.fileName,
    required this.type,
    required this.sender,
    required this.dateTime,
    required this.size,
    this.thumbnailUrl,
    this.isEncrypted = true,
  });
}

class FilesMediaScreen extends StatefulWidget {
  const FilesMediaScreen({super.key});

  @override
  State<FilesMediaScreen> createState() => _FilesMediaScreenState();
}

class _FilesMediaScreenState extends State<FilesMediaScreen> with MySafeState {
  List<ChatFile> _vaultFiles = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  List<ChatFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadVaultFiles();
  }

  Future<void> _loadVaultFiles() async {
    setState(() {
      _isLoading = true;
    });
    final directory = await getApplicationDocumentsDirectory();
    final vaultDirectory = Directory('${directory.path}/vault');
    if (await vaultDirectory.exists()) {
      final files = await vaultDirectory.list().toList();
      final chatFiles = files.map((file) {
        final stat = file.statSync();
        return ChatFile(
          fileName: file.path.split('/').last,
          type: _getFileType(file.path),
          sender: "You",
          dateTime: stat.modified.toString(),
          size: '${(stat.size / 1024).toStringAsFixed(2)} KB',
          thumbnailUrl: file.path,
        );
      }).toList();
      setState(() {
        _vaultFiles = chatFiles;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  FileType _getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return FileType.image;
    } else if (['mp4', 'mov', 'avi'].contains(extension)) {
      return FileType.video;
    } else if (['mp3', 'wav', 'm4a'].contains(extension)) {
      return FileType.audio;
    } else if (['pdf', 'doc', 'docx', 'txt'].contains(extension)) {
      return FileType.document;
    } else {
      return FileType.unknown;
    }
  }

  IconData _iconForFileType(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.videocam;
      case FileType.document:
        return Icons.picture_as_pdf;
      case FileType.audio:
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _isSelectionMode ? 'Select Files' : "Files & Media",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.primaryColor,
          ),
        ),
        centerTitle: true,
        foregroundColor: themeData.primaryColor,
        elevation: 0,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Delete Files"),
                    content: Text(
                        "Are you sure you want to delete the selected files?"),
                    actions: [
                      TextButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text("Delete"),
                        onPressed: () {
                          _deleteSelectedFiles();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _selectedFiles.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _vaultFiles.isEmpty
              ? Center(
                  child: Text(
                    "No files or media in the vault yet.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _vaultFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final file = _vaultFiles[i];
                    final isSelected = _selectedFiles.contains(file);
                    return Card(
                      color: isSelected
                          ? themeData.primaryColor.withOpacity(0.3)
                          : themeData.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: file.type == FileType.image ||
                                file.type == FileType.video
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: file.thumbnailUrl != null
                                    ? Image.file(
                                        File(file.thumbnailUrl!),
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        _iconForFileType(file.type),
                                        color: themeData.primaryColor,
                                        size: 36,
                                      ),
                              )
                            : Icon(
                                _iconForFileType(file.type),
                                color: themeData.primaryColor,
                                size: 36,
                              ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    file.fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (file.isEncrypted)
                                    Icon(
                                      Icons.lock,
                                      color: themeData.primaryColor,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          "${file.sender} • ${file.dateTime} • ${file.size}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        trailing: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _selectedFiles.add(file);
                                    } else {
                                      _selectedFiles.remove(file);
                                    }
                                  });
                                },
                              )
                            : Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedFiles.remove(file);
                              } else {
                                _selectedFiles.add(file);
                              }
                            });
                          } else {
                            OpenFilex.open(file.thumbnailUrl);
                          }
                        }, // Open preview or file
                      ),
                    );
                  },
                ),
    );
  }

  void _deleteSelectedFiles() async {
    for (var file in _selectedFiles) {
      final fileToDelete = File(file.thumbnailUrl!);
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }
    }
    setState(() {
      _vaultFiles
          .removeWhere((element) => _selectedFiles.contains(element));
      _selectedFiles.clear();
      _isSelectionMode = false;
    });
  }
}
