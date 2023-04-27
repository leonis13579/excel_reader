import 'dart:io';

import 'package:excel/excel.dart';
import 'package:excel_reader/logic/document.dart';
import 'package:excel_reader/logic/report.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class ExcelAnilizerService {
  final List<Document> _utDocuments = [];
  final List<Document> _accountingDocumnets = [];

  final Report _report = Report();

  Report startAnalization(PlatformFile selectedExcelFile) {
    final excelFile = Excel.decodeBytes(File(selectedExcelFile.path!).readAsBytesSync());

    for (final table in excelFile.tables.entries) {
      if (table.key == 'TDSheet') {
        _serializeAccountingDatabase(table.value);
      } else {
        _serializeUtDatabase(table.value);
      }
    }

    debugPrint('У УТ получено отчетов - ${_utDocuments.length}, в бухгалтерии получено отчетов - ${_accountingDocumnets.length}');

    _analizeDocuments();

    debugPrint(
        'Корректных отчетов - ${_report.correctDocuments.length}, отчетов с некорректной суммой - ${_report.documentsWithNotCorrectSumm.length}, отчетов в УТ, отсутствующих в бухгалтерии - ${_report.notFoundDocumentInAccounting.length}');

    final dirPathElems = selectedExcelFile.path!.split('/');
    dirPathElems.removeLast();

    _createReport(dirPathElems.join('/'));

    return _report;
  }

  void _serializeUtDatabase(Sheet utDatabaseSheet) {
    late final int numberColumnIndex;
    late final int dateColumnIndex;
    late final int summColumnIndex;
    late final int remunerationColumnIndex;
    late final int companyColumnIndex;
    late final int counterpartyColumnIndex;

    for (int i = 0; i < utDatabaseSheet.row(0).length; i++) {
      switch ((utDatabaseSheet.row(0)[i]?.value as SharedString).toString()) {
        case 'Дата':
          dateColumnIndex = i;
          break;
        case 'Номер':
          numberColumnIndex = i;
          break;
        case 'Сумма':
          summColumnIndex = i;
          break;
        case 'Контрагент':
          counterpartyColumnIndex = i;
          break;
        case 'Вознаграждение':
          remunerationColumnIndex = i;
          break;
        case 'Организация':
          companyColumnIndex = i;
          break;
      }
    }

    for (int i = 0; i < utDatabaseSheet.maxRows; i++) {
      if (i == 0) continue;

      _utDocuments.add(Document(
        number: (utDatabaseSheet.row(i)[numberColumnIndex]!.value as SharedString).toString(),
        company: (utDatabaseSheet.row(i)[companyColumnIndex]!.value as SharedString).toString(),
        counterparty: (utDatabaseSheet.row(i)[counterpartyColumnIndex]!.value as SharedString).toString(),
        date: DateFormat('dd.MM.yyyy').parse((utDatabaseSheet.row(i)[dateColumnIndex]!.value as SharedString).toString()),
        summ: utDatabaseSheet.row(i)[summColumnIndex]?.value is int
            ? (utDatabaseSheet.row(i)[summColumnIndex]?.value as int).toDouble()
            : utDatabaseSheet.row(i)[summColumnIndex]?.value as double?,
        remuneration: utDatabaseSheet.row(i)[remunerationColumnIndex]?.value is int
            ? (utDatabaseSheet.row(i)[remunerationColumnIndex]?.value as int).toDouble()
            : utDatabaseSheet.row(i)[remunerationColumnIndex]?.value as double?,
      ));
    }
  }

  void _serializeAccountingDatabase(Sheet accountingDatabaseSheet) {
    final String companyName = (accountingDatabaseSheet.row(0)[0]!.value as SharedString).toString();

    late final int numberColumnIndex;
    late final int dateColumnIndex;
    late final int totalColumnIndex;
    late final int remunerationColumnIndex;
    late final int counterpartyColumnIndex;

    for (int i = 0; i < accountingDatabaseSheet.row(3).length; i++) {
      switch ((accountingDatabaseSheet.row(3)[i]?.value as SharedString).toString()) {
        case 'Дата':
          dateColumnIndex = i;
          break;
        case 'Номер':
          numberColumnIndex = i;
          break;
        case 'Сумма':
          totalColumnIndex = i;
          break;
        case 'Информация':
          counterpartyColumnIndex = i;
          break;
        case 'Вознаграждение':
          remunerationColumnIndex = i;
          break;
      }
    }

    for (int i = 0; i < accountingDatabaseSheet.maxRows; i++) {
      if (i < 4) continue;

      if (accountingDatabaseSheet.row(i)[0]?.value is int) {
        _accountingDocumnets.add(Document.fromTotal(
          number: (accountingDatabaseSheet.row(i)[numberColumnIndex]!.value as SharedString).toString(),
          company: companyName,
          counterparty: (accountingDatabaseSheet.row(i)[counterpartyColumnIndex]!.value as SharedString).toString(),
          date: DateFormat('dd.MM.yyyy').parse((accountingDatabaseSheet.row(i)[dateColumnIndex]!.value as SharedString).toString()),
          total: accountingDatabaseSheet.row(i)[totalColumnIndex]?.value is int
              ? (accountingDatabaseSheet.row(i)[totalColumnIndex]?.value as int).toDouble()
              : accountingDatabaseSheet.row(i)[totalColumnIndex]?.value as double?,
          remuneration: accountingDatabaseSheet.row(i)[remunerationColumnIndex]?.value is int
              ? (accountingDatabaseSheet.row(i)[remunerationColumnIndex]?.value as int).toDouble()
              : accountingDatabaseSheet.row(i)[remunerationColumnIndex]?.value as double?,
        ));
      }
    }
  }

  void _analizeDocuments() {
    for (final document in _utDocuments) {
      if (document.total != null && document.total! > 0) {
        final Document? sameDocumentInAccounting = _accountingDocumnets.firstWhereOrNull((accountingDocument) => document.isSameDocument(accountingDocument));

        if (sameDocumentInAccounting == null) {
          _report.notFoundDocumentInAccounting.add(document);
          continue;
        }

        if (document.summ == sameDocumentInAccounting.summ &&
            document.remuneration == sameDocumentInAccounting.remuneration &&
            document.total == sameDocumentInAccounting.total) {
          _report.correctDocuments.add(document);
          continue;
        }

        _report.documentsWithNotCorrectSumm.putIfAbsent(
            document,
            () => SummReport(
                  accountingTotal: sameDocumentInAccounting.total!,
                  utTotal: document.total!,
                  delta: document.total! - sameDocumentInAccounting.total!,
                  utRemuneration: document.remuneration ?? 0,
                  accountingRemuneration: sameDocumentInAccounting.remuneration ?? 0,
                ));
      }
    }
  }

  void _createReport(String dirPath) {
    if (_report.documentsWithNotCorrectSumm.isNotEmpty || _report.notFoundDocumentInAccounting.isNotEmpty) {
      final reportExcel = Excel.createExcel();
      final defaultSheetName = reportExcel.tables.keys.single;

      if (_report.documentsWithNotCorrectSumm.isNotEmpty) {
        const notCorrectSummSheetName = 'Не совпадающие по сумме';
        reportExcel.copy(defaultSheetName, notCorrectSummSheetName);

        final notCorrectSummSheet = reportExcel.sheets[notCorrectSummSheetName];

        if (notCorrectSummSheet != null) {
          notCorrectSummSheet.appendRow([
            'Номер отчета',
            'Общая сумма по УТ',
            'Общая сумма по бухгалтерии',
            'Дельта в бухгалтерии',
            'Вознаграждение в УТ',
            'Вознаграждение в бухгалтерии',
          ]);
          notCorrectSummSheet.row(0).forEach((cell) {
            if (cell != null) cell.cellStyle = CellStyle(bold: true);
          });

          for (final entity in _report.documentsWithNotCorrectSumm.entries) {
            notCorrectSummSheet.appendRow([
              entity.key.number,
              entity.value.delta != 0 ? entity.value.utTotal : '',
              entity.value.delta != 0 ? entity.value.accountingTotal : '',
              entity.value.delta != 0 ? entity.value.delta : '',
              entity.value.utRemuneration != entity.value.accountingRemuneration ? entity.value.utRemuneration : '',
              entity.value.utRemuneration != entity.value.accountingRemuneration ? entity.value.accountingRemuneration : '',
            ]);
          }
        }
      }

      if (_report.notFoundDocumentInAccounting.isNotEmpty) {
        const notFoundSheetName = 'Отсутствующие в базе бухгалтерии';
        reportExcel.copy(defaultSheetName, notFoundSheetName);

        final notFoundSheet = reportExcel.sheets[notFoundSheetName];

        if (notFoundSheet != null) {
          notFoundSheet.appendRow(['Номер отчета']);
          notFoundSheet.row(0).forEach((cell) {
            if (cell != null) cell.cellStyle = CellStyle(bold: true);
          });

          for (final document in _report.notFoundDocumentInAccounting) {
            notFoundSheet.appendRow([document.number]);
          }
        }
      }

      reportExcel.delete(defaultSheetName);

      final filePath = '$dirPath/Сверка_УТ_и_бухгалтерии.xlsx';
      if (File(filePath).existsSync()) {
        File(filePath).deleteSync();
      }

      final bytes = reportExcel.save();

      if (bytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
      }
    }
  }
}
