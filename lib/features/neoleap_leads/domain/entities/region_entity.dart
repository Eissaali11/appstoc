class RegionEntity {
  final String name;
  final String emoji;
  final double latitude;
  final double longitude;
  final bool isSelected;

  const RegionEntity({
    required this.name,
    required this.emoji,
    required this.latitude,
    required this.longitude,
    this.isSelected = false,
  });

  static const List<RegionEntity> saudiRegions = [
    RegionEntity(name: 'أبها', emoji: '⛰️', latitude: 18.2164, longitude: 42.5053),
    RegionEntity(name: 'أبو عريش', emoji: '🌴', latitude: 16.9678, longitude: 42.8314),
    RegionEntity(name: 'الأحساء (الهفوف)', emoji: '🌴', latitude: 25.3800, longitude: 49.5900),
    RegionEntity(name: 'الباحة', emoji: '🪨', latitude: 20.0129, longitude: 41.4677),
    RegionEntity(name: 'الجبيل', emoji: '🏭', latitude: 26.9598, longitude: 49.5687),
    RegionEntity(name: 'الخرج', emoji: '🌾', latitude: 24.1500, longitude: 47.3000),
    RegionEntity(name: 'الخبر', emoji: '🌊', latitude: 26.2777, longitude: 50.2083),
    RegionEntity(name: 'الدرعية', emoji: '🏰', latitude: 24.6858, longitude: 46.5422),
    RegionEntity(name: 'الدمام', emoji: '🏢', latitude: 26.4207, longitude: 50.0888),
    RegionEntity(name: 'الدوادمي', emoji: '🏜️', latitude: 24.5000, longitude: 44.4000),
    RegionEntity(name: 'الرس', emoji: '🌴', latitude: 25.8674, longitude: 43.4973),
    RegionEntity(name: 'الرياض', emoji: '🇸🇦', latitude: 24.7136, longitude: 46.6753),
    RegionEntity(name: 'الزلفي', emoji: '⛰️', latitude: 26.2900, longitude: 44.8200),
    RegionEntity(name: 'الطائف', emoji: '🌹', latitude: 21.2854, longitude: 40.4062),
    RegionEntity(name: 'الظهران', emoji: '🧪', latitude: 26.2750, longitude: 50.1375),
    RegionEntity(name: 'القريات', emoji: '🫒', latitude: 31.3300, longitude: 37.3400),
    RegionEntity(name: 'القطيف', emoji: '🌊', latitude: 26.5592, longitude: 50.0224),
    RegionEntity(name: 'القنفذة', emoji: '🏖️', latitude: 19.1275, longitude: 41.0789),
    RegionEntity(name: 'المدينة المنورة', emoji: '🕌', latitude: 24.4672, longitude: 39.6111),
    RegionEntity(name: 'المجمعة', emoji: '🏫', latitude: 25.9000, longitude: 45.3333),
    RegionEntity(name: 'بريدة', emoji: '🌴', latitude: 26.3260, longitude: 43.9750),
    RegionEntity(name: 'بلجرشي', emoji: '🌳', latitude: 19.8500, longitude: 41.5600),
    RegionEntity(name: 'بيشة', emoji: '🌾', latitude: 20.0005, longitude: 42.6052),
    RegionEntity(name: 'تبوك', emoji: '❄️', latitude: 28.3835, longitude: 36.5662),
    RegionEntity(name: 'جازان', emoji: '🌊', latitude: 16.8892, longitude: 42.5706),
    RegionEntity(name: 'جدة', emoji: '🏙️', latitude: 21.5433, longitude: 39.1728),
    RegionEntity(name: 'حائل', emoji: '🏜️', latitude: 27.5114, longitude: 41.7208),
    RegionEntity(name: 'حفر الباطن', emoji: '🐫', latitude: 28.4328, longitude: 45.9708),
    RegionEntity(name: 'خميس مشيط', emoji: '⛰️', latitude: 18.3064, longitude: 42.7308),
    RegionEntity(name: 'رابغ', emoji: '⛵', latitude: 22.7986, longitude: 39.0349),
    RegionEntity(name: 'رفحاء', emoji: '🏜️', latitude: 29.4000, longitude: 43.5000),
    RegionEntity(name: 'سكاكا', emoji: '🏰', latitude: 29.9697, longitude: 40.2064),
    RegionEntity(name: 'شرورة', emoji: '🏜️', latitude: 17.4800, longitude: 47.1200),
    RegionEntity(name: 'شقراء', emoji: '🏫', latitude: 25.2444, longitude: 45.2464),
    RegionEntity(name: 'صبيا', emoji: '🌾', latitude: 17.1500, longitude: 42.6333),
    RegionEntity(name: 'طريف', emoji: '❄️', latitude: 31.6725, longitude: 38.6631),
    RegionEntity(name: 'عرعر', emoji: '🐫', latitude: 30.9753, longitude: 41.0381),
    RegionEntity(name: 'عنيزة', emoji: '🌴', latitude: 26.0850, longitude: 43.9900),
    RegionEntity(name: 'مكة المكرمة', emoji: '🕋', latitude: 21.3891, longitude: 39.8579),
    RegionEntity(name: 'نجران', emoji: '🏰', latitude: 17.4933, longitude: 44.1277),
    RegionEntity(name: 'وادي الدواسر', emoji: '🐫', latitude: 20.4500, longitude: 44.7800),
    RegionEntity(name: 'ينبع', emoji: '⚓', latitude: 24.0891, longitude: 38.0637),
  ];
}
