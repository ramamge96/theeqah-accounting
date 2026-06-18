class AppSettings {
  // معلومات الشركة
  String companyName;
  String? logoPath; // مسار الشعار
  String? phoneNumber;

  // إعدادات الفواتير
  String defaultCurrency;
  double defaultTaxRate;
  String invoicePrefix;

  // إعدادات الطباعة
  String paperSize; // A4, Letter
  String exportFormat; // PDF, Image

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
      defaultTaxRate: (map['defaultTaxRate'] as num?)?.toDouble() ?? 15.0,
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      paperSize: map['paperSize'] ?? 'A4',
      exportFormat: map['exportFormat'] ?? 'PDF',
      showHeaderOnInvoice: map['showHeaderOnInvoice'] ?? true,
      showFooterOnInvoice: map['showFooterOnInvoice'] ?? true,
      passwordHash: map['passwordHash'],
    );
  }
}