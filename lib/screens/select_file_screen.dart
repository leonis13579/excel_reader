import 'package:excel_reader/screens/analization_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SelectFileScreen extends StatefulWidget {
  const SelectFileScreen({super.key});

  @override
  State<SelectFileScreen> createState() => _SelectFileScreenState();
}

class _SelectFileScreenState extends State<SelectFileScreen> {
  PlatformFile? selectedFile;

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowedExtensions: ['xls', 'xlsx'], type: FileType.custom);

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
  }

  void _moveToAnalizer() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AnalizationScreen(excelFile: selectedFile!)));
  }

  void _showInfo() {
    showDialog(context: context, builder: (_) => Dialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сверка данных из УТ и Бухгалтерии'),
        actions: [IconButton(onPressed: _showInfo, icon: const Icon(Icons.info))],
      ),
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedFile != null) ...[
              Text(selectedFile!.path ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            ElevatedButton(onPressed: _selectFile, child: const Text('Выбрать файл на компьютере')),
            if (selectedFile != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _moveToAnalizer, child: const Text('Сверить данные')),
            ]
          ],
        ),
      )),
    );
  }
}
