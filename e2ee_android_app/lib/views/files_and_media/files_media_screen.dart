import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../backend/common/app_theme/app_theme_controller.dart';
// import '../../backend/common/app_theme/app_theme_provider.dart';

enum FileType { image, video, document, audio }

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

final List<ChatFile> mockFiles = [
  ChatFile(
    fileName: "vacation_photo.jpg",
    type: FileType.image,
    sender: "Sarah",
    dateTime: "2m ago",
    size: "2.1 MB",
    thumbnailUrl:
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=facearea&w=64&h=64",
  ),
  ChatFile(
    fileName: "meeting.mp4",
    type: FileType.video,
    sender: "You",
    dateTime: "1h ago",
    size: "18 MB",
    thumbnailUrl:
        "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=64&h=64",
  ),
  ChatFile(
    fileName: "report.pdf",
    type: FileType.document,
    sender: "Mike",
    dateTime: "3h ago",
    size: "310 KB",
  ),
  ChatFile(
    fileName: "summary_2025.pdf",
    type: FileType.document,
    sender: "Ben",
    dateTime: "4h ago",
    size: "349 KB",
  ),
  ChatFile(
    fileName: "test.mp4",
    type: FileType.video,
    sender: "You",
    dateTime: "1h ago",
    size: "18 MB",
    thumbnailUrl:
    "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=64&h=64",
  ),
];

class FilesMediaScreen extends StatefulWidget {
  const FilesMediaScreen({super.key});

  @override
  State<FilesMediaScreen> createState() => _FilesMediaScreenState();
}

class _FilesMediaScreenState extends State<FilesMediaScreen> with MySafeState {
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
      }
  }


  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Files & Media",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.primaryColor,
          ),
        ),
        centerTitle: true,
        foregroundColor: themeData.primaryColor,
        elevation: 0,
      ),
      body:
          mockFiles.isEmpty
              ? Center(
                child: Text(
                  "No files or media shared yet.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: mockFiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) {
                  final file = mockFiles[i];
                  return Card(
                    color: themeData.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading:
                          file.type == FileType.image ||
                                  file.type == FileType.video
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    file.thumbnailUrl != null
                                        ? Image.network(
                                          file.thumbnailUrl!,
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
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                      onTap: () {}, // Open preview or file
                    ),
                  );
                },
              ),
    );
  }
}
