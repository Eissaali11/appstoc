/// النصوص العربية للتطبيق
const Map<String, String> ar = {
  // عام
  'app_title': 'Stock',
  'confirm': 'تأكيد',
  'cancel': 'إلغاء',
  'success': 'نجح',
  'error': 'خطأ',
  'loading': 'جاري التحميل...',

  // تسجيل الدخول / الخروج
  'login': 'تسجيل الدخول',
  'logout': 'تسجيل الخروج',
  'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
  'email': 'البريد الإلكتروني',
  'password': 'كلمة المرور',
  'login_button': 'دخول',

  // القائمة الجانبية
  'drawer_dashboard': 'لوحة التحكم',
  'drawer_fixed_inventory': 'المخزون الثابت',
  'drawer_moving_inventory': 'المخزون المتحرك',
  'drawer_inventory_list': 'قائمة الأصناف',
  'drawer_submit_device': 'إدخال جهاز',
  'drawer_received_devices': 'الأجهزة المستلمة',
  'drawer_request_inventory': 'طلب مخزون',
  'drawer_notifications': 'الإشعارات',
  'drawer_profile': 'الملف الشخصي',
  'drawer_about_us': 'من نحن',
  'drawer_user_default': 'مستخدم نظام المخزون',
  'drawer_badge': 'StockPro المركز',

  // لوحة التحكم
  'dashboard': 'لوحة التحكم',
  'quick_actions': 'الإجراءات السريعة',
  'fixed': 'الثابت',
  'moving': 'المتحرك',
  'devices': 'الأجهزة',
  'request_stock': 'طلب مخزون',

  // الملف الشخصي
  'profile': 'الملف الشخصي',
  'profile_title': 'الملف الشخصي',
  'name': 'الاسم',
  'user_not_logged_in': 'المستخدم غير مسجل دخول',
  'change_language': 'اللغة',
  'language_ar': 'العربية',
  'language_en': 'English',

  // طلب المخزون
  'request_inventory': 'طلب مخزون',
  'new_request': 'طلب جديد',
  'my_requests': 'طلباتي',
  'status_approved': 'تمت الموافقة',
  'status_rejected': 'مرفوض',
  'status_pending': 'قيد الانتظار',
  'no_requests_yet': 'لا توجد طلبات مخزون سابقة',
  'items_count': 'عنصر',
  'request_details': 'تفاصيل الطلب',
  'technician_notes': 'ملاحظات الفني',
  'admin_reply': 'رد الإدارة',

  // الأجهزة المستلمة
  'received_devices': 'الأجهزة المستلمة',
  'submit_device': 'إدخال جهاز',
  'no_devices_yet': 'لا توجد أجهزة مستلمة حتى الآن',

  // من نحن
  'about_us': 'من نحن',

  // إشعارات
  'notifications': 'الإشعارات',

  // الملف الشخصي - تفاصيل
  'role': 'الدور',
  'role_technician': 'فني',
  'city': 'المدينة',
  'region': 'المنطقة',

  // لوحة التحكم - أخطاء وعناوين
  'error_occurred': 'حدث خطأ',
  'error_loading_data': 'حدث خطأ في تحميل البيانات',
  'retry': 'إعادة المحاولة',
  'please_login': 'يرجى تسجيل الدخول',
  'stats_fixed': 'المخزون الثابت',
  'stats_moving': 'المخزون المتحرك',
  'stats_pending': 'طلبات معلقة',
  'stats_total': 'إجمالي المخزون',
  'no_items': 'لا توجد أصناف',
  'no_items_filter': 'لم يتم العثور على أصناف تطابق البحث أو الفلتر',
  'no_items_in_stock': 'لا توجد أصناف في المخزون',
  'reset_filters': 'إعادة تعيين الفلاتر',

  // شريط الفلتر
  'search_hint': 'ابحث عن صنف...',
  'filter_all': 'الكل',
  'filter_fixed': 'الثابت',
  'filter_moving': 'المتحرك',
  'filter_available': 'متوفر',
  'filter_low': 'منخفض',

  // طلب المخزون - إضافي
  'request_stock_warehouse': 'طلب مخزون من المستودع',
  'loading_items': 'جاري تحميل الأصناف...',
  'notes_optional': 'ملاحظات (اختياري)',
  'add_notes': 'أضف ملاحظات',
  'send_request': 'إرسال الطلب',
  'request_min_quantity': 'يرجى إدخال كمية لصنف واحد على الأقل',
  'request_success_msg': 'تم إرسال طلب المخزون بنجاح',
  'request_fail_msg': 'فشل إرسال الطلب',
  'boxes': 'كراتين',
  'units': 'وحدات',
  'item_n950': 'جهاز N950',
  'item_i9000s': 'جهاز I9000s',
  'item_i9100': 'جهاز I9100',
  'item_roll_paper': 'ورق حراري',
  'item_stickers': 'ملصقات',
  'item_batteries': 'بطاريات جديدة',
  'item_mobily_sim': 'شرائح موبايلي',
  'item_stc_sim': 'شرائح STC',
  'item_zain_sim': 'شرائح زين',
  'carton': 'كرتون',

  // إدخال جهاز
  'submit_device_title': 'إدخال بيانات جهاز',
  'enter_device_data': 'أدخل بيانات الجهاز المستلم',
  'device_id': 'رقم الجهاز (Terminal ID)',
  'device_id_required': 'يرجى إدخال رقم الجهاز',
  'serial_number_label': 'الرقم التسلسلي (Serial Number)',
  'serial_required': 'يرجى إدخال الرقم التسلسلي',
  'accessories': 'الملحقات',
  'battery': 'بطارية',
  'charger_cable': 'كابل الشاحن',
  'charger_head': 'رأس الشاحن',
  'has_sim': 'يحتوي على شريحة SIM',
  'sim_type': 'نوع الشريحة',
  'damage_part': 'الجزء المتضرر',
  'damage_required': 'يرجى إدخال الجزء المتضرر',
  'sending': 'جاري الإرسال...',
  'submit': 'إرسال',
  'sim_mobily': 'موبايلي',
  'sim_stc': 'STC',
  'sim_zain': 'زين',
  'sim_other': 'أخرى',

  // الأجهزة المستلمة - تفاصيل
  'device_details': 'تفاصيل الجهاز',
  'device_id_short': 'رقم الجهاز',
  'serial_short': 'الرقم التسلسلي',
  'present': 'موجودة',
  'not_present': 'غير موجودة',
  'present_m': 'موجود',
  'not_present_m': 'غير موجود',
  'admin_notes': 'ملاحظات المشرف',
  'damage': 'الضرر',
  'accessory_count': 'ملحق',

  // من نحن - عناوين رئيسية
  'about_title': 'من نحن',
  'open_link_error': 'تعذر فتح الرابط. جرّب نسخ الرابط وفتحه من المتصفح.',
  'visit_website': 'تفضل بزيارة موقعنا',
  'open_website': 'فتح الموقع nuzum.life',
  'nuzum_tagline': 'نبني الأنظمة التي تبني أعمالكم',
  'website': 'الموقع',

  // شاشة البداية
  'splash_slogan': 'إدارة مخزون ذكية وسهلة',

  // تسجيل الدخول - أخطاء
  'login_failed': 'فشل تسجيل الدخول',
  'login_error_no_data': 'فشل تسجيل الدخول: لا توجد بيانات المستخدم',
  'device_submit_success': 'تم إرسال بيانات الجهاز بنجاح',
  'device_submit_fail': 'فشل إرسال بيانات الجهاز',

  // نقل المخزون / بطاقات
  'reject': 'رفض',
  'accept': 'قبول',
  'warehouse_unspecified': 'مستودع غير محدد',
  'item_type': 'نوع العنصر',
  'quantity': 'الكمية',
  'notes': 'ملاحظات',
  'sort_by_name': 'حسب الاسم',
  'sort_by_total': 'حسب الإجمالي',
  'sort_by_fixed': 'حسب الثابت',
  'sort_by_moving': 'حسب المتحرك',
  'sim_type_required': 'يجب اختيار نوع الشريحة',
  'clear_barcode': 'مسح الباركود',

  // تحديث المخزون / نقل
  'update_fixed_title': 'تحديث المخزون الثابت',
  'update_moving_title': 'تحديث المخزون المتحرك',
  'transfer_stock_tooltip': 'نقل مخزون',
  'saving': 'جاري الحفظ...',
  'save_changes': 'حفظ التغييرات',
  'update_success': 'تم تحديث المخزون بنجاح',
  'transfer_success': 'تم نقل المخزون بنجاح',
  'transfer_fail': 'فشل نقل المخزون',
  'item_type_label': 'نوع الصنف',
  'from_fixed_to_moving': 'من الثابت للمتحرك',
  'from_moving_to_fixed': 'من المتحرك للثابت',
  'transfer_reason_optional': 'سبب النقل (اختياري)',
  'execute_transfer': 'تنفيذ النقل',
  'sort_order': 'ترتيب',
  'available': 'متاح',
  'types_available': 'نوع متاح',
};
