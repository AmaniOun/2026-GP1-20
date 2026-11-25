   import 'package:flutter/material.dart';
   import 'package:google_fonts/google_fonts.dart';

   import 'account_screen.dart';
   import 'home_screen.dart';
   import 'my_garden_screen.dart';
   import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String name;
  final String email;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.name,
    required this.email,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late String _name;
  late String _email;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _name = widget.name;
    _email = widget.email;
  }

  void _onProfileChanged(String name, String email) {
    if (!mounted) return;
    if (_name == name && _email == email) return;
    setState(() { _name = name; _email = email; });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(name: _name, active: _selectedIndex == 0, onSelectTab: (index) => setState(() => _selectedIndex = index)),
      const SearchScreen(),
      const MyGardenScreen(),
      const _EmptyTabPage(
        title: 'الإشعارات',
        icon: Icons.notifications_none_rounded,
        message: 'لا توجد إشعارات حالياً',
      ),
      AccountScreen(
        name: _name,
        email: _email,
        active: _selectedIndex == 4,
        onProfileChanged: _onProfileChanged,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Color(0xFFDCE4D8),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _navItem(
                index: 0,
                icon: Icons.home_outlined,
                text: 'الرئيسية',
              ),
              _navItem(
                index: 1,
                icon: Icons.search_rounded,
                text: 'البحث',
              ),
              _navItem(
                index: 2,
                icon: Icons.eco_outlined,
                text: 'حديقتي',
              ),
              _navItem(
                index: 3,
                icon: Icons.notifications_none_rounded,
                text: 'الإشعارات',
              ),
              _navItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                text: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String text,
  }) {
    final bool selected = _selectedIndex == index;

    final Color color = selected
        ? const Color(0xFF315B32)
        : const Color(0xFF656E62);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              text,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                color: color,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة فارغة بنفس تصميم صفحة الإعدادات (أيقونة + رسالة) إلى أن تُبنى الصفحة الحقيقية
class _EmptyTabPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _EmptyTabPage({
    required this.title,
    required this.icon,
    required this.message,
  });

  static const Color _green = Color(0xFF315B32);
  static const Color _darkGreen = Color(0xFF234525);
  static const Color _lightSage = Color(0xFFE8F0E4);
  static const Color _muted = Color(0xFF656E62);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F4),
        appBar: AppBar(
          toolbarHeight: 68,
          backgroundColor: const Color(0xFFFAF9F4),
          surfaceTintColor: const Color(0xFFFAF9F4),
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: _darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _lightSage,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: _green, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
