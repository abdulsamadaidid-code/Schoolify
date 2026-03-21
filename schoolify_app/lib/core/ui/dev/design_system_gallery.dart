import 'package:flutter/material.dart';

import '../responsive/constrained_content.dart';
import '../widgets/app_surface.dart';
import '../widgets/editorial_lockup.dart';
import '../widgets/empty_state.dart';
import '../widgets/schoolify_button.dart';
import '../widgets/schoolify_card.dart';
import '../widgets/schoolify_chip.dart';
import '../widgets/schoolify_data_table.dart';
import '../widgets/schoolify_navigation_bar.dart';
import '../widgets/schoolify_text_field.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Internal preview for tokens + primitives (acceptance / QA).
class DesignSystemGallery extends StatefulWidget {
  const DesignSystemGallery({super.key});

  @override
  State<DesignSystemGallery> createState() => _DesignSystemGalleryState();
}

class _DesignSystemGalleryState extends State<DesignSystemGallery> {
  int _navIndex = 0;
  bool _chipOn = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Schoolify UI', style: theme.textTheme.titleLarge),
      ),
      body: AppSurface(
        tier: AppSurfaceTier.base,
        child: ConstrainedContent(
          child: ListView(
            children: [
              const SizedBox(height: AppSpacing.md),
              EditorialLockup(
                title: 'Design system',
                body:
                    'Tokens from docs/branding.md — editorial type, tonal surfaces, '
                    'large controls.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Buttons', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SchoolifyButton(
                    label: 'Primary',
                    onPressed: () {},
                  ),
                  SchoolifyButton(
                    label: 'Secondary',
                    variant: SchoolifyButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  SchoolifyButton(
                    label: 'Tertiary',
                    variant: SchoolifyButtonVariant.tertiary,
                    onPressed: () {},
                  ),
                  SchoolifyButton(
                    label: 'Danger',
                    variant: SchoolifyButtonVariant.danger,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Form', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              const SchoolifyTextField(
                label: 'Email',
                hint: 'you@school.edu',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Card + chip', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              SchoolifyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card title', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Surface tier lowest on tonal base — no heavy shadow.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SchoolifyChip(
                      label: 'Filter',
                      selected: _chipOn,
                      onSelected: (v) => setState(() => _chipOn = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Table', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              SchoolifyDataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Role')),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('Ada')),
                    DataCell(Text('Teacher')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Lin')),
                    DataCell(Text('Admin')),
                  ]),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Empty state', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              SchoolifyCard(
                child: EmptyState(
                  title: 'No students yet',
                  message: 'Add your first student to see them here.',
                  icon: Icons.people_outline,
                  actionLabel: 'Add student',
                  onAction: () {},
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Type ramp', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text('Display', style: theme.textTheme.displayLarge),
              Text('Headline', style: theme.textTheme.headlineMedium),
              Text('Title', style: theme.textTheme.titleLarge),
              Text('Body', style: theme.textTheme.bodyLarge),
              Text(
                'LABEL',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: AppTypography.labelMd,
                ),
              ),
              const SizedBox(height: AppSpacing.pageBottomInset),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SchoolifyNavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
