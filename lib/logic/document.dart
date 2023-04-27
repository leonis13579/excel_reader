class Document {
  final String number;
  final String company;
  final String counterparty;
  final DateTime date;
  final double? summ;
  final double? remuneration;

  double? get total {
    if (summ == null && remuneration == null) return null;
    return (summ ?? 0) + (remuneration ?? 0);
  }

  bool isSameDocument(Document other) {
    bool numberEqual = number == other.number;
    bool companyEqual = company == other.company;
    bool counterpartyEqual = counterparty == other.counterparty || counterparty.contains(other.counterparty) || other.counterparty.contains(counterparty);
    bool dateEqual = date.isAtSameMomentAs(other.date);

    return numberEqual && companyEqual && counterpartyEqual && dateEqual;
  }

  Document({required this.number, required this.company, required this.counterparty, required this.date, required this.summ, required this.remuneration});

  Document.fromTotal({required this.number, required this.company, required this.counterparty, required this.date, required this.remuneration, required double? total})
      : summ = (total == null && remuneration == null) ? null : (total ?? 0) - (remuneration ?? 0);
}
