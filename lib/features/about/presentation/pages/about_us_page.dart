import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';

/// صفحة "من نحن" - نُظم شركة بناء الأنظمة والتطبيقات
/// [نُظم - نُظم للحلول التقنية](https://nuzum.life/)
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const String _websiteUrl = 'https://nuzum.life/';

  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.parse(_websiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(
            'من نحن',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    _buildVision(),
                    _buildMission(),
                    _buildServices(context),
                    _buildWhyNuzum(),
                    _buildStats(context),
                    _buildClients(),
                    _buildCta(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.architecture_rounded,
            size: 56,
            color: Colors.white.withOpacity(0.95),
          ),
          const SizedBox(height: 16),
          Text(
            'نُظم',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'شركة بناء الأنظمة والتطبيقات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Text(
              'نبني الأنظمة التي تبني أعمالكم',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return _SectionCard(
      icon: Icons.info_outline_rounded,
      title: 'من نحن',
      child: Text(
        'نحن شركة نُظم المتخصصة في تصميم وتطوير الأنظمة والتطبيقات الذكية التي تُحدث فرقاً حقيقياً في أعمالكم. نؤمن بأن التقنية ليست مجرد أدوات، بل هي شريك استراتيجي في نجاح مؤسستكم.',
        style: GoogleFonts.cairo(
          fontSize: 15,
          height: 1.7,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildVision() {
    return _SectionCard(
      icon: Icons.visibility_rounded,
      title: 'رؤيتنا',
      gradient: AppColors.purpleGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تمكين المؤسسات العربية من التحول الرقمي الكامل من خلال حلول تقنية مبتكرة ومستدامة.',
            style: GoogleFonts.cairo(
              fontSize: 15,
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'نسعى لأن نكون الشريك التقني الأول للمؤسسات الطموحة التي تبحث عن التميز والابتكار في منطقة الخليج والشرق الأوسط.',
            style: GoogleFonts.cairo(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMission() {
    return _SectionCard(
      icon: Icons.campaign_rounded,
      title: 'رسالتنا',
      gradient: AppColors.greenGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نقدم حلولاً تقنية متكاملة تجمع بين:',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _BulletItem(
            text: 'الابتكار في التصميم والتطوير',
            icon: Icons.lightbulb_outline_rounded,
          ),
          _BulletItem(
            text: 'الجودة في التنفيذ والتسليم',
            icon: Icons.verified_rounded,
          ),
          _BulletItem(
            text: 'المرونة في التعامل والتخصيص',
            icon: Icons.tune_rounded,
          ),
          _BulletItem(
            text: 'الاستدامة في الدعم والصيانة',
            icon: Icons.build_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    final services = [
      (
        icon: Icons.phone_android_rounded,
        title: 'تطوير تطبيقات الجوال',
        desc:
            'نصمم ونطور تطبيقات احترافية لنظامي Android و iOS باستخدام أحدث التقنيات مثل Flutter و React Native، مما يضمن تجربة مستخدم سلسة وأداء متميز.',
        color: AppColors.primary,
      ),
      (
        icon: Icons.business_center_rounded,
        title: 'الأنظمة المؤسسية',
        desc:
            'أنظمة إدارة المخزون والمستودعات، الموارد البشرية، إدارة علاقات العملاء (CRM)، المحاسبة والفوترة، ولوحات التحكم والتقارير التحليلية.',
        color: const Color(0xFF6366F1),
      ),
      (
        icon: Icons.language_rounded,
        title: 'تطوير المواقع والمنصات',
        desc:
            'مواقع وتطبيقات ويب حديثة وسريعة باستخدام React / Next.js، Node.js / Python، PostgreSQL / MongoDB.',
        color: const Color(0xFF22C55E),
      ),
      (
        icon: Icons.link_rounded,
        title: 'التكامل والربط',
        desc:
            'حلول ربط وتكامل بين الأنظمة المختلفة عبر واجهات برمجة التطبيقات (APIs)، لتوحيد بياناتكم وتبسيط عملياتكم.',
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.cloud_rounded,
        title: 'الخدمات السحابية',
        desc:
            'الانتقال السلس إلى السحابة مع ضمان الأمان والاستقرار والأداء الأمثل.',
        color: const Color(0xFF0EA5E9),
      ),
    ];

    return _SectionCard(
      icon: Icons.widgets_rounded,
      title: 'خدماتنا',
      gradient: AppColors.orangeGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in services) ...[
            _ServiceItem(
              icon: s.icon,
              title: s.title,
              desc: s.desc,
              color: s.color,
            ),
            if (s != services.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildWhyNuzum() {
    final items = [
      ('خبرة عميقة', 'فريق من المهندسين والمطورين ذوي الخبرة الواسعة'),
      ('حلول مخصصة', 'نصمم كل نظام بناءً على احتياجاتكم الفعلية'),
      ('دعم مستمر', 'دعماً فنياً على مدار الساعة لضمان استمرارية أعمالكم'),
      ('تسليم في الموعد', 'نلتزم بالجداول الزمنية مع أعلى معايير الجودة'),
      ('أسعار تنافسية', 'أفضل قيمة مقابل استثماركم'),
      ('تقنيات حديثة', 'أحدث التقنيات والمنهجيات في التطوير'),
    ];

    return _SectionCard(
      icon: Icons.emoji_events_rounded,
      title: 'لماذا نُظم؟',
      gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$2,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final stats = [
      (Icons.dashboard_rounded, '+50', 'نظام ومنصة'),
      (Icons.phone_android_rounded, '+30', 'تطبيق جوال'),
      (Icons.business_rounded, '+100', 'عميل راضٍ'),
      (Icons.people_rounded, '+20', 'مهندس ومطور'),
      (Icons.schedule_rounded, '+5', 'سنوات خبرة'),
    ];

    return _SectionCard(
      icon: Icons.analytics_rounded,
      title: 'إنجازاتنا بالأرقام',
      gradient: AppColors.greenGradient,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final s in stats)
            Container(
              width: (MediaQuery.of(context).size.width - 64) / 2 - 8,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(s.$1, size: 28, color: AppColors.success),
                  const SizedBox(height: 6),
                  Text(
                    s.$2,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    s.$3,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClients() {
    final clients = [
      'المؤسسات الحكومية',
      'الشركات الكبرى والمتوسطة',
      'الشركات الناشئة والريادية',
      'المؤسسات التعليمية والصحية',
      'قطاع التجزئة واللوجستيات',
    ];

    return _SectionCard(
      icon: Icons.handshake_rounded,
      title: 'عملاؤنا',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نفتخر بخدمة مجموعة متنوعة من العملاء تشمل:',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...clients.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'تفضل بزيارة موقعنا',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _websiteUrl,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWebsite(context),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 22),
                    label: Text(
                      'فتح الموقع nuzum.life',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'نبني الأنظمة التي تبني أعمالكم',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final List<Color>? gradient;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? [AppColors.primary, AppColors.primaryDark];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.first.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final IconData icon;

  const _BulletItem({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
