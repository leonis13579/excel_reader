import 'package:excel_reader/logic/document.dart';
import 'package:excel_reader/logic/excel_analization_service.dart';
import 'package:excel_reader/logic/report.dart';
import 'package:excel_reader/screens/select_file_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AnalizationScreen extends StatelessWidget {
  final Report report;

  AnalizationScreen({super.key, required PlatformFile excelFile}) : report = ExcelAnilizerService().startAnalization(excelFile);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сверка данных из УТ и Бухгалтерии'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SelectFileScreen())),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            if (report.correctDocuments.isNotEmpty)
              ExpansionTile(
                title: const Text('Успешно перенесенные отчеты комиссионера'),
                trailing: Text(report.correctDocuments.length.toString()),
                childrenPadding: const EdgeInsets.all(16),
                children: report.correctDocuments.expand((document) => [_ReportDocumentWidget(document: document), const SizedBox(height: 16)]).toList(),
              ),
            if (report.documentsWithNotCorrectSumm.isNotEmpty)
              ExpansionTile(
                title: const Text('Отчеты комиссионера, перенесенные с неправильной суммой'),
                trailing: Text(report.documentsWithNotCorrectSumm.length.toString()),
                childrenPadding: const EdgeInsets.all(16),
                children: report.documentsWithNotCorrectSumm.entries
                    .expand((entry) => [_ReportDocumentWidget(document: entry.key, report: entry.value), const SizedBox(height: 16)])
                    .toList(),
              ),
            if (report.notFoundDocumentInAccounting.isNotEmpty)
              ExpansionTile(
                title: const Text('Отчеты комиссионера, которые отсутсвуют в бухгалтерии'),
                trailing: Text(report.notFoundDocumentInAccounting.length.toString()),
                childrenPadding: const EdgeInsets.all(16),
                children: report.notFoundDocumentInAccounting.expand((document) => [_ReportDocumentWidget(document: document), const SizedBox(height: 16)]).toList(),
              )
          ],
        ),
      ),
    );
  }
}

class _ReportDocumentWidget extends StatelessWidget {
  final Document document;
  final SummReport? report;

  const _ReportDocumentWidget({required this.document, this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: Text(document.number, textAlign: TextAlign.center)),
          if (report != null) ...[
            if (report!.delta != 0)
              Expanded(child: Text('Разница общей суммы между УТ и бухгалтерией составляет ${report!.delta.toStringAsFixed(2)} руб.', textAlign: TextAlign.center)),
            if (report!.utRemuneration != report!.accountingRemuneration)
              Expanded(
                  child: Text(
                      'Разница вознаграждения между УТ и бухгалтерией составляет ${(report!.utRemuneration - report!.accountingRemuneration).toStringAsFixed(2)} руб.',
                      textAlign: TextAlign.center)),
          ]
        ],
      );
    } else {
      return Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        children: [
          TableRow(children: [
            Text(document.number, textAlign: TextAlign.center),
            Text(report!.delta != 0 ? 'Разница общей суммы между УТ и бухгалтерией составляет ${report!.delta.toStringAsFixed(2)} руб.' : '',
                textAlign: TextAlign.center),
            Text(
                report!.utRemuneration != report!.accountingRemuneration
                    ? 'Разница вознаграждения между УТ и бухгалтерией составляет ${(report!.utRemuneration - report!.accountingRemuneration).toStringAsFixed(2)} руб.'
                    : '',
                textAlign: TextAlign.center),
          ])
        ],
      );
    }
  }
}
