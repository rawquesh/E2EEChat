import 'dart:io';

import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_android_app/backend/authentication/authentication_controller.dart';
import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_android_app/utils/enums.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

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
  bool _isPinSet = false;
  bool _isPinVerified = false;
  PinScreenMode _pinScreenMode = PinScreenMode.verify;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await SecureStorageManager()
        .getString(MySharedPreferenceVariables.mediaPinKey);
    setState(() {
      _isPinSet = hasPin != null;
      _pinScreenMode = _isPinSet ? PinScreenMode.verify : PinScreenMode.set;
    });
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
    return _isPinVerified || !_isPinSet
        ? _buildFilesMediaScreen()
        : _buildPinEntryScreen();
  }

  Widget _buildPinEntryScreen() {
    return Scaffold(
      body: VaultPinEntryScreen(
        onPinVerified: () {
          setState(() {
            _isPinVerified = true;
            _loadVaultFiles();
          });
        },
        mode: _pinScreenMode,
      ),
    );
  }

  Widget _buildFilesMediaScreen() {
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

class VaultPinEntryScreen extends StatefulWidget {
  final VoidCallback onPinVerified;
  final PinScreenMode mode;

  const VaultPinEntryScreen(
      {Key? key, required this.onPinVerified, required this.mode})
      : super(key: key);

  @override
  _VaultPinEntryScreenState createState() => _VaultPinEntryScreenState();
}

class _VaultPinEntryScreenState extends State<VaultPinEntryScreen>
    with MySafeState {
  late AuthenticationController authenticationController;
  late AuthenticationProvider authenticationProvider;

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int failedAttempts = 0;
  bool isLoading = false;
  String? errorMessage;
  String? firstPin;
  late PinScreenMode currentMode;

  @override
  void initState() {
    super.initState();
    authenticationProvider = context.read<AuthenticationProvider>();
    authenticationController =
        AuthenticationController(authenticationProvider: authenticationProvider);

    currentMode = widget.mode;
    MyPrint.printOnConsole(
        "VaultPinEntryScreen initialized with mode: $currentMode");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinCompleted(String pin) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (currentMode == PinScreenMode.set) {
      firstPin = pin;
      setState(() {
        currentMode = PinScreenMode.confirm;
        _pinController.clear();
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
      return;
    } else if (currentMode == PinScreenMode.confirm) {
      if (firstPin == null) {
        setState(() {
          errorMessage = "Something went wrong. Please start over.";
          currentMode = PinScreenMode.set;
          firstPin = null;
          _pinController.clear();
          isLoading = false;
        });
        return;
      }
      if (firstPin == pin) {
        final result = await authenticationController.setNewPin(firstPin!, pin,
            isVaultPin: true);
        setState(() {
          isLoading = false;
        });
        if (result) {
          widget.onPinVerified();
        } else {
          setState(() {
            errorMessage = "Failed to save PIN. Please try again.";
            currentMode = PinScreenMode.set;
            firstPin = null;
            _pinController.clear();
          });
        }
      } else {
        setState(() {
          errorMessage = "PINs do not match. Please try again.";
          currentMode = PinScreenMode.set;
          firstPin = null;
          _pinController.clear();
          isLoading = false;
        });
      }
      return;
    } else if (currentMode == PinScreenMode.verify) {
      final isCorrect = await authenticationController.verifyPin(pin,
          isVaultPin: true);
      if (isCorrect) {
        if (mounted) {
          widget.onPinVerified();
        }
      } else {
        final storedDuressPin = await SecureStorageManager()
            .getString(MySharedPreferenceVariables.duressPinKey);

        if (storedDuressPin != null && storedDuressPin == pin) {
          _wipeAppData();
          setState(
              () => errorMessage = "Duress PIN entered. All data will be wiped.");
          return;
        }

        setState(() {
          failedAttempts++;
          isLoading = false;
          if (failedAttempts >= 5) {
            errorMessage = "Too many failed attempts. All data will be wiped.";
            _wipeAppData();
          } else {
            errorMessage =
                "Incorrect PIN. ${5 - failedAttempts} attempts remaining.";
          }
          _pinController.clear();
        });
      }
      return;
    }
  }

  void _wipeAppData() async {
    authenticationController.wipeAllAuthData();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Alert'),
        content: const Text(
            'All app data has been wiped for security purposes. You will need to register again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (currentMode) {
      case PinScreenMode.set:
        return "Set Your Vault PIN";
      case PinScreenMode.confirm:
        return "Confirm Your Vault PIN";
      case PinScreenMode.verify:
        return "Enter Your Vault PIN";
      default:
        return "Vault PIN";
    }
  }

  String _getSubtitle() {
    switch (currentMode) {
      case PinScreenMode.set:
        return "Choose a 4-digit PIN for your vault";
      case PinScreenMode.confirm:
        return "Re-enter the PIN to confirm";
      case PinScreenMode.verify:
        return "Enter your PIN to access your vault";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    MyPrint.printOnConsole(
        "Building VaultPinEntryScreen with mode: $currentMode");

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 45,
      textStyle: TextStyle(
          fontSize: 16,
          color: themeData.colorScheme.onSurface,
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        color: themeData.primaryColor.withValues(alpha: 0.05),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: themeData.primaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: themeData.primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: themeData.primaryColor, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).viewInsets.bottom -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: themeData.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Icon(
                          currentMode == PinScreenMode.verify
                              ? Icons.lock
                              : Icons.security,
                          size: 40,
                          color: themeData.primaryColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getTitle(),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: themeData.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSubtitle(),
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Pinput(
                      controller: _pinController,
                      focusNode: _focusNode,
                      length: 4,
                      obscureText: true,
                      obscuringCharacter: '●',
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme:
                          errorMessage != null ? errorPinTheme : null,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onCompleted: _onPinCompleted,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              themeData.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade700),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (isLoading)
                      CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              themeData.primaryColor)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
