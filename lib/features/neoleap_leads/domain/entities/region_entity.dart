class MainRegionGroup {
  final String id;
  final String nameAr;
  final String emoji;
  final List<RegionEntity> cities;

  const MainRegionGroup({
    required this.id,
    required this.nameAr,
    required this.emoji,
    required this.cities,
  });
}

class RegionEntity {
  final String name;
  final String emoji;
  final double latitude;
  final double longitude;
  final String parentRegionId;
  final bool isSelected;

  const RegionEntity({
    required this.name,
    required this.emoji,
    required this.latitude,
    required this.longitude,
    required this.parentRegionId,
    this.isSelected = false,
  });

  RegionEntity copyWith({
    String? name,
    String? emoji,
    double? latitude,
    double? longitude,
    String? parentRegionId,
    bool? isSelected,
  }) {
    return RegionEntity(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      parentRegionId: parentRegionId ?? this.parentRegionId,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  static const List<MainRegionGroup> mainSaudiRegions = [
    MainRegionGroup(
      id: 'riyadh',
      nameAr: 'منطقة الرياض',
      emoji: '🏛️',
      cities: [
        RegionEntity(name: 'مدينة الرياض', emoji: '🏙️', latitude: 24.7136, longitude: 46.6753, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الدرعية', emoji: '🏰', latitude: 24.6858, longitude: 46.5422, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الخرج', emoji: '🌾', latitude: 24.1500, longitude: 47.3000, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الدلم', emoji: '🌾', latitude: 23.9876, longitude: 47.1654, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الدوادمي', emoji: '🏜️', latitude: 24.5000, longitude: 44.4000, parentRegionId: 'riyadh'),
        RegionEntity(name: 'المجمعة', emoji: '🏫', latitude: 25.9000, longitude: 45.3333, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الزلفي', emoji: '⛰️', latitude: 26.2900, longitude: 44.8200, parentRegionId: 'riyadh'),
        RegionEntity(name: 'شقراء', emoji: '🏫', latitude: 25.2444, longitude: 45.2464, parentRegionId: 'riyadh'),
        RegionEntity(name: 'مرات', emoji: '🏛️', latitude: 25.0711, longitude: 45.4619, parentRegionId: 'riyadh'),
        RegionEntity(name: 'أوشيقر', emoji: '🏰', latitude: 25.3421, longitude: 45.1843, parentRegionId: 'riyadh'),
        RegionEntity(name: 'أثيثية', emoji: '🌾', latitude: 25.1833, longitude: 45.3167, parentRegionId: 'riyadh'),
        RegionEntity(name: 'ثرمداء', emoji: '🌴', latitude: 25.1235, longitude: 45.2891, parentRegionId: 'riyadh'),
        RegionEntity(name: 'جلاجل', emoji: '🌳', latitude: 25.6881, longitude: 45.4628, parentRegionId: 'riyadh'),
        RegionEntity(name: 'تمير', emoji: '🏫', latitude: 25.7102, longitude: 45.8643, parentRegionId: 'riyadh'),
        RegionEntity(name: 'حوطة سدير', emoji: '🏡', latitude: 25.5975, longitude: 45.6171, parentRegionId: 'riyadh'),
        RegionEntity(name: 'روضة سدير', emoji: '🌿', latitude: 25.6210, longitude: 45.5800, parentRegionId: 'riyadh'),
        RegionEntity(name: 'عودة سدير', emoji: '🏺', latitude: 25.6021, longitude: 45.6420, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الأرطاوية', emoji: '🐫', latitude: 26.5056, longitude: 45.3498, parentRegionId: 'riyadh'),
        RegionEntity(name: 'وادي الدواسر', emoji: '🐫', latitude: 20.4500, longitude: 44.7800, parentRegionId: 'riyadh'),
        RegionEntity(name: 'حوطة بني تميم', emoji: '🌴', latitude: 23.5200, longitude: 46.8400, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الأفلاج', emoji: '🌾', latitude: 22.2800, longitude: 46.7400, parentRegionId: 'riyadh'),
        RegionEntity(name: 'المزاحمية', emoji: '🚗', latitude: 24.4700, longitude: 46.2600, parentRegionId: 'riyadh'),
        RegionEntity(name: 'ضرما', emoji: '🏞️', latitude: 24.6083, longitude: 46.1264, parentRegionId: 'riyadh'),
        RegionEntity(name: 'رماح', emoji: '🐫', latitude: 25.1700, longitude: 47.1600, parentRegionId: 'riyadh'),
        RegionEntity(name: 'ثادق', emoji: '🌴', latitude: 25.2900, longitude: 45.8800, parentRegionId: 'riyadh'),
        RegionEntity(name: 'حريملاء', emoji: '🌳', latitude: 25.1200, longitude: 46.1200, parentRegionId: 'riyadh'),
        RegionEntity(name: 'السليل', emoji: '🌴', latitude: 20.4600, longitude: 45.5700, parentRegionId: 'riyadh'),
        RegionEntity(name: 'عفيف', emoji: '🏜️', latitude: 23.9000, longitude: 42.9200, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الحريق', emoji: '⛰️', latitude: 23.6300, longitude: 46.5100, parentRegionId: 'riyadh'),
        RegionEntity(name: 'الغاط', emoji: '🌴', latitude: 26.0200, longitude: 44.9600, parentRegionId: 'riyadh'),
        RegionEntity(name: 'القويعية', emoji: '🪨', latitude: 24.0500, longitude: 45.2600, parentRegionId: 'riyadh'),
      ],
    ),
    MainRegionGroup(
      id: 'qassim',
      nameAr: 'منطقة القصيم',
      emoji: '🌴',
      cities: [
        RegionEntity(name: 'بريدة', emoji: '🌴', latitude: 26.3260, longitude: 43.9750, parentRegionId: 'qassim'),
        RegionEntity(name: 'عنيزة', emoji: '🌴', latitude: 26.0850, longitude: 43.9900, parentRegionId: 'qassim'),
        RegionEntity(name: 'الرس', emoji: '🌴', latitude: 25.8674, longitude: 43.4973, parentRegionId: 'qassim'),
        RegionEntity(name: 'البكيرية', emoji: '🏫', latitude: 26.1400, longitude: 43.6600, parentRegionId: 'qassim'),
        RegionEntity(name: 'البدائع', emoji: '🌾', latitude: 26.0400, longitude: 43.7400, parentRegionId: 'qassim'),
        RegionEntity(name: 'المذنب', emoji: '🌾', latitude: 25.8600, longitude: 44.2100, parentRegionId: 'qassim'),
        RegionEntity(name: 'رياض الخبراء', emoji: '🌾', latitude: 26.0600, longitude: 43.5700, parentRegionId: 'qassim'),
        RegionEntity(name: 'عيون الجواء', emoji: '💧', latitude: 26.5100, longitude: 43.6400, parentRegionId: 'qassim'),
        RegionEntity(name: 'الشماسية', emoji: '🌴', latitude: 26.3000, longitude: 44.3300, parentRegionId: 'qassim'),
        RegionEntity(name: 'النبهانية', emoji: '⛰️', latitude: 25.8500, longitude: 43.0800, parentRegionId: 'qassim'),
        RegionEntity(name: 'عقلة الصقور', emoji: '🦅', latitude: 25.8300, longitude: 42.1800, parentRegionId: 'qassim'),
        RegionEntity(name: 'ضرية', emoji: '🏜️', latitude: 24.7400, longitude: 43.0100, parentRegionId: 'qassim'),
        RegionEntity(name: 'الأسياح', emoji: '💧', latitude: 26.4700, longitude: 44.2000, parentRegionId: 'qassim'),
      ],
    ),
    MainRegionGroup(
      id: 'makkah',
      nameAr: 'منطقة مكة المكرمة والغربية',
      emoji: '🕋',
      cities: [
        RegionEntity(name: 'مكة المكرمة', emoji: '🕋', latitude: 21.3891, longitude: 39.8579, parentRegionId: 'makkah'),
        RegionEntity(name: 'جدة', emoji: '🏙️', latitude: 21.5433, longitude: 39.1728, parentRegionId: 'makkah'),
        RegionEntity(name: 'الطائف', emoji: '🌹', latitude: 21.2854, longitude: 40.4062, parentRegionId: 'makkah'),
        RegionEntity(name: 'القنفذة', emoji: '🏖️', latitude: 19.1275, longitude: 41.0789, parentRegionId: 'makkah'),
        RegionEntity(name: 'رابغ', emoji: '⛵', latitude: 22.7986, longitude: 39.0349, parentRegionId: 'makkah'),
        RegionEntity(name: 'الليث', emoji: '🌊', latitude: 20.1500, longitude: 40.2700, parentRegionId: 'makkah'),
        RegionEntity(name: 'خليص', emoji: '🌴', latitude: 22.0000, longitude: 39.3100, parentRegionId: 'makkah'),
        RegionEntity(name: 'الخرمة', emoji: '🌾', latitude: 21.9200, longitude: 42.0800, parentRegionId: 'makkah'),
        RegionEntity(name: 'رنية', emoji: '🌴', latitude: 21.2600, longitude: 42.8400, parentRegionId: 'makkah'),
        RegionEntity(name: 'تربة', emoji: '🌾', latitude: 21.2200, longitude: 41.6300, parentRegionId: 'makkah'),
      ],
    ),
    MainRegionGroup(
      id: 'eastern',
      nameAr: 'المنطقة الشرقية',
      emoji: '🏭',
      cities: [
        RegionEntity(name: 'الدمام', emoji: '🏢', latitude: 26.4207, longitude: 50.0888, parentRegionId: 'eastern'),
        RegionEntity(name: 'الخبر', emoji: '🌊', latitude: 26.2777, longitude: 50.2083, parentRegionId: 'eastern'),
        RegionEntity(name: 'الظهران', emoji: '🧪', latitude: 26.2750, longitude: 50.1375, parentRegionId: 'eastern'),
        RegionEntity(name: 'الأحساء (الهفوف)', emoji: '🌴', latitude: 25.3800, longitude: 49.5900, parentRegionId: 'eastern'),
        RegionEntity(name: 'الجبيل', emoji: '🏭', latitude: 26.9598, longitude: 49.5687, parentRegionId: 'eastern'),
        RegionEntity(name: 'القطيف', emoji: '🌊', latitude: 26.5592, longitude: 50.0224, parentRegionId: 'eastern'),
        RegionEntity(name: 'حفر الباطن', emoji: '🐫', latitude: 28.4328, longitude: 45.9708, parentRegionId: 'eastern'),
        RegionEntity(name: 'الخفجي', emoji: '🛢️', latitude: 28.4400, longitude: 48.5000, parentRegionId: 'eastern'),
        RegionEntity(name: 'النعيرية', emoji: '🐫', latitude: 27.4700, longitude: 48.4900, parentRegionId: 'eastern'),
        RegionEntity(name: 'بقيق', emoji: '🛢️', latitude: 25.9300, longitude: 49.6700, parentRegionId: 'eastern'),
      ],
    ),
    MainRegionGroup(
      id: 'madinah_north',
      nameAr: 'منطقة المدينة المنورة والشرق الشمالي',
      emoji: '🕌',
      cities: [
        RegionEntity(name: 'المدينة المنورة', emoji: '🕌', latitude: 24.4672, longitude: 39.6111, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'ينبع', emoji: '⚓', latitude: 24.0891, longitude: 38.0637, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'العلا', emoji: '🏺', latitude: 26.6167, longitude: 37.9167, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'بدر', emoji: '🌴', latitude: 23.7800, longitude: 38.7900, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'تبوك', emoji: '❄️', latitude: 28.3835, longitude: 36.5662, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'حائل', emoji: '🏜️', latitude: 27.5114, longitude: 41.7208, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'سكاكا (الجوف)', emoji: '🏰', latitude: 29.9697, longitude: 40.2064, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'عرعر', emoji: '🐫', latitude: 30.9753, longitude: 41.0381, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'القريات', emoji: '🫒', latitude: 31.3300, longitude: 37.3400, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'رفحاء', emoji: '🏜️', latitude: 29.4000, longitude: 43.5000, parentRegionId: 'madinah_north'),
        RegionEntity(name: 'طريف', emoji: '❄️', latitude: 31.6725, longitude: 38.6631, parentRegionId: 'madinah_north'),
      ],
    ),
    MainRegionGroup(
      id: 'asir_south',
      nameAr: 'منطقة عسير والجنوب',
      emoji: '⛰️',
      cities: [
        RegionEntity(name: 'أبها', emoji: '⛰️', latitude: 18.2164, longitude: 42.5053, parentRegionId: 'asir_south'),
        RegionEntity(name: 'خميس مشيط', emoji: '⛰️', latitude: 18.3064, longitude: 42.7308, parentRegionId: 'asir_south'),
        RegionEntity(name: 'جازان', emoji: '🌊', latitude: 16.8892, longitude: 42.5706, parentRegionId: 'asir_south'),
        RegionEntity(name: 'نجران', emoji: '🏰', latitude: 17.4933, longitude: 44.1277, parentRegionId: 'asir_south'),
        RegionEntity(name: 'الباحة', emoji: '🪨', latitude: 20.0129, longitude: 41.4677, parentRegionId: 'asir_south'),
        RegionEntity(name: 'بيشة', emoji: '🌾', latitude: 20.0005, longitude: 42.6052, parentRegionId: 'asir_south'),
        RegionEntity(name: 'أبو عريش', emoji: '🌴', latitude: 16.9678, longitude: 42.8314, parentRegionId: 'asir_south'),
        RegionEntity(name: 'صبيا', emoji: '🌾', latitude: 17.1500, longitude: 42.6333, parentRegionId: 'asir_south'),
        RegionEntity(name: 'شرورة', emoji: '🏜️', latitude: 17.4800, longitude: 47.1200, parentRegionId: 'asir_south'),
        RegionEntity(name: 'بلجرشي', emoji: '🌳', latitude: 19.8500, longitude: 41.5600, parentRegionId: 'asir_south'),
      ],
    ),
  ];

  static List<RegionEntity> get allSaudiCities {
    final List<RegionEntity> result = [];
    for (final group in mainSaudiRegions) {
      result.addAll(group.cities);
    }
    return result;
  }
}
