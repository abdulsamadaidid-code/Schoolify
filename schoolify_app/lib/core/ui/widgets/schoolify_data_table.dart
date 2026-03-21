import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Opinionated [DataTable] wrapper — spacing instead of row divider lines.
class SchoolifyDataTable extends StatelessWidget {
  const SchoolifyDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.columnSpacing = AppSpacing.lg,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double columnSpacing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(
            scheme.surfaceContainerLow,
          ),
          dataRowMinHeight: 52,
          headingRowHeight: 48,
          horizontalMargin: 0,
          columnSpacing: columnSpacing,
          dividerThickness: 0,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}
