import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_screen.dart';
import 'search_screen.dart';
import 'my_garden_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String name;
  final String email;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.name,
    required this.email,
    this.initialIndex = 4,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _TemporaryPage(title: 'الرئيسية'),
      const SearchScreen(),
      const MyGardenScreen(),
      const _TemporaryPage(title: 'الإشعارات'),
      AccountScreen(
        name: widget.name,
        email: widget.email,
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
        : const Color(0xFF7D8079);

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
                fontSize: 10,
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

// صفحات مؤقتة إلى أن يتم إنشاء الصفحات الحقيقية
class _TemporaryPage extends StatelessWidget {
  final String title;

  const _TemporaryPage({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        child: Center(
          child: Text(
            title,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: const Color(0xFF234525),
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}