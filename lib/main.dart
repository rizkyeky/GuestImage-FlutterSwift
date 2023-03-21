import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:path_provider/path_provider.dart' show getApplicationSupportDirectory;
import 'package:path/path.dart' show dirname;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Platform.isMacOS ? const MacosApp(
      debugShowCheckedModeBanner: false,
      title: 'Guest Image',
      home: MainPage(),
    ) : const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Guest Image',
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Platform.isMacOS ? MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) => const HomePage(),
          )
        ]
      )
    ) : CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Guest Image'),
      ),
      child: HomePage(),
    );
  }

}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  File? _fileImage;
  final MethodChannel _imageChannel = const MethodChannel("com.rizkyeky.guestimage");
  bool _isLoading = false;
  // String? _predictedName;

  @override
  void initState() {
    super.initState();

    setState(() => _isLoading = true);
    initModel().whenComplete(() {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (Platform.isIOS) const SizedBox(height: 120,),
          if (Platform.isMacOS) const Expanded(
            flex: 1,
            child: Center(
              child: Text('Guest Image', 
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white
                ),
              ),
            ),
          ),
          const SizedBox(height: 16,),
          Expanded(
            flex: 7,
            child: Column(
              children: [
                SizedBox(
                  height: Platform.isIOS ? 200 : 300,
                  child: !_isLoading ? (_fileImage != null) 
                  ? Image.file(_fileImage!,) : DropArea(
                    onDrop: (file) {
                      setState(() => _fileImage = file);
                    },
                  ) : const Center(
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                ),
                if (!_isLoading) Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    direction: Platform.isMacOS ? Axis.horizontal : Axis.vertical,
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_fileImage != null) AppleButton(
                        color: CupertinoColors.systemRed,
                        onPressed: () {
                          if (_fileImage != null) {
                            setState(() {
                              _fileImage = null;
                            });
                          }
                        },
                        child: const Text('Delete',
                          style: TextStyle(
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                      if (_fileImage != null) AppleButton(
                        color: CupertinoColors.activeGreen,
                        onPressed: () {
                          processImage().then((result) {
                            if (result != null) {
                              showCupertinoDialog(context: context, 
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('Predicted Name'),
                                  content: Text(result),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    )
                                  ],
                                )
                              );
                            }
                          });
                        },
                        child: const Text('Predict',
                          style: TextStyle(
                            color: CupertinoColors.white,
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> processImage() async {
    final result = await _imageChannel
      .invokeMethod<String>('processImage', _fileImage?.path);
    return result;
  }

  Future<bool?> initModel() async {
    final path = await getModel('assets/mobilenetv2.mlmodel');
    try {
      final result = await _imageChannel
        .invokeMethod('initModel', path);
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<String> getModel(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (! await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}

class AppleButton extends StatelessWidget {
  const AppleButton({
    required this.onPressed,
    required this.child,
    this.color,
    super.key});

  final Color? color;
  final void Function() onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Platform.isMacOS ? PushButton(
      buttonSize: ButtonSize.large,
      color: color,
      onPressed: onPressed,
      child: child,
    ) : CupertinoButton.filled(
      onPressed: onPressed,
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              color: CupertinoColors.white,
            ),
          ),
        ),
        child: child
      ), 
    );
  }
}

class DropArea extends StatefulWidget {
  const DropArea({super.key,
    required this.onDrop,
  });

  final Function(File? file) onDrop;

  @override
  State<DropArea> createState() => _DropAreaState();
}

class _DropAreaState extends State<DropArea> {
  
  File? file;
  bool _dragging = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Platform.isMacOS ? DropTarget(
      onDragDone: (detail) {
        setState(() {
          if (detail.files.isNotEmpty) {
            file = File(detail.files.first.path);
            widget.onDrop(file);
          }
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: DottedBorder(
        strokeWidth: 4,
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        padding: const EdgeInsets.all(16),
        dashPattern: const [8],
        color: CupertinoColors.systemGrey5.withOpacity(
          _dragging ? 0.4 : 1
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isLoading) AppleButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final img = result.files.first;
                    if (img.path != null) {
                      setState(() {
                        file = File(result.files.first.path!);
                        widget.onDrop(file);
                      });
                    }
                  }
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: const Text('Upload'),
              ) else const SizedBox(
                width: 50,
                child: CupertinoActivityIndicator(),
              ),
              const SizedBox(height: 16,),
              const Center(child: Text("or Drop here")),
            ],
          ),
        )
      ),
    ) : DottedBorder(
      strokeWidth: 4,
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      padding: const EdgeInsets.all(16),
      dashPattern: const [8],
      color: CupertinoColors.systemGrey5.withOpacity(
        _dragging ? 0.4 : 1
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isLoading) AppleButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.isNotEmpty) {
                  final img = result.files.first;
                  if (img.path != null) {
                    setState(() {
                      file = File(result.files.first.path!);
                      widget.onDrop(file);
                    });
                  }
                }
                setState(() {
                  _isLoading = false;
                });
              },
              child: const Text('Upload',
                style: TextStyle(
                  color: CupertinoColors.white,
                ),
              ),
            ) else const SizedBox(
              width: 50,
              child: CupertinoActivityIndicator(),
            ),
            if (Platform.isMacOS) ... [
              const SizedBox(height: 16,),
              const Center(child: Text("or Drop here")),
            ]
          ],
        ),
      )
    );
  }
}