import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';

class ProfileCardContainer extends StatefulWidget {
  final List<String>? tabs;
  final Widget Function(String? selectedTab) contentBuilder;
  final String? initialTab;

  const ProfileCardContainer({
    super.key,
    this.tabs,
    required this.contentBuilder,
    this.initialTab,
  });

  @override
  State<ProfileCardContainer> createState() => _ProfileCardContainerState();
}

class _ProfileCardContainerState extends State<ProfileCardContainer> {
  String? _selectedTab;

  @override
  void initState() {
    super.initState();
    if (widget.tabs != null && widget.tabs!.isNotEmpty) {
      _selectedTab = widget.initialTab ?? widget.tabs!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabs superiores (si existen)
          if (widget.tabs != null && widget.tabs!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: widget.tabs!.map((tab) {
                  final isSelected = tab == _selectedTab;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.secondary
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Contenido
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: widget.contentBuilder(_selectedTab),
            ),
          ),
        ],
      ),
    );
  }
}