import 'package:excel_reader/logic/document.dart';

class Report {
  final List<Document> correctDocuments = [];
  final Map<Document, SummReport> documentsWithNotCorrectSumm = {};
  final List<Document> notFoundDocumentInAccounting = [];
}

class SummReport {
  final double utTotal;
  final double accountingTotal;
  final double delta;

  final double utRemuneration;
  final double accountingRemuneration;

  const SummReport({required this.utTotal, required this.accountingTotal, required this.delta, required this.utRemuneration, required this.accountingRemuneration});
}
