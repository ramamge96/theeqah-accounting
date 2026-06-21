class AppSettings {
  // معلومات الشركة
  String companyName;
  String? logoPath;
  String? phoneNumber;

  // إعدادات الفواتير
  String defaultCurrency;
  double defaultTaxRate;
  String invoicePrefix;

  // إعدادات الطباعة
  String paperSize;
  String exportFormat;

  // إعدادات العرض
  bool showHeaderOnInvoice;
  bool showFooterOnInvoice;

  // الأمان
  String? passwordHash;

  AppSettings({
    this.companyName = 'اسم الشركة',
    this.logoPath,
    this.phoneNumber,
    this.defaultCurrency = 'SAR',
    this.defaultTaxRate = 15.0,
    this.invoicePrefix = 'INV-',
    this.paperSize = 'A4',
    this.exportFormat = 'PDF',
    this.showHeaderOnInvoice = true,
    this.showFooterOnInvoice = true,
    this.passwordHash,
  });

  // تحويل إلى خريطة للحفظ
  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'logoPath': logoPath,
      'phoneNumber': phoneNumber,
      'defaultCurrency': defaultCurrency,
      'defaultTaxRate': defaultTaxRate,
      'invoicePrefix': invoicePrefix,
      'paperSize': paperSize,
      'exportFormat': exportFormat,
      'showHeaderOnInvoice': showHeaderOnInvoice,
      'showFooterOnInvoice': showFooterOnInvoice,
      'passwordHash': passwordHash,
    };
  }

  // إنشاء من خريطة
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      companyName: map['companyName'] ?? 'اسم الشركة',
      logoPath: map['logoPath'],
      phoneNumber: map['phoneNumber'],
      defaultCurrency: map['defaultCurrency'] ?? 'SAR',
      defaultTaxRate: _safeDouble(map['defaultTaxRate'], 15.0),
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      paperSize: map['paperSize'] ?? 'A4',
      exportFormat: map['exportFormat'] ?? 'PDF',
      showHeaderOnInvoice: map['showHeaderOnInvoice'] ?? true,
      showFooterOnInvoice: map['showFooterOnInvoice'] ?? true,
      passwordHash: map['passwordHash'],
    );
  }

  /// تحويل آمن من أي نوع إلى double
  static double _safeDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  /// إنشاء نسخة جديدة مع تعديل بعض الحقول
  AppSettings copyWith({
    String? companyName,
    String? logoPath,
    String? phoneNumber,
    String? defaultCurrency,
    double? defaultTaxRate,
    String? invoicePrefix,
    String? paperSize,
    String? exportFormat,
    bool? showHeaderOnInvoice,
    bool? showFooterOnInvoice,
    String? passwordHash,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      logoPath: logoPath ?? this.logoPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      paperSize: paperSize ?? this.paperSize,
      exportFormat: exportFormat ?? this.exportFormat,
      showHeaderOnInvoice: showHeaderOnInvoice ?? this.showHeaderOnInvoice,
      showFooterOnInvoice: showFooterOnInvoice ?? this.showFooterOnInvoice,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}