import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/invoice_entity.dart';
import 'customer_providers.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Invoices & Billing'),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync invoices',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(invoicesStreamProvider),
          ),
        ),
        data: (invoices) {
          // Compute Metrics
          double totalReceivables = 0.0;
          double pendingDrafts = 0.0;
          double totalPaid = 0.0;

          for (final inv in invoices) {
            if (inv.status == 'sent') {
              totalReceivables += inv.amount;
            } else if (inv.status == 'draft') {
              pendingDrafts += inv.amount;
            } else if (inv.status == 'paid') {
              totalPaid += inv.amount;
            }
          }

          final filtered = invoices.where((inv) {
            if (_selectedStatus == 'all') return true;
            return inv.status == _selectedStatus;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics widgets Row
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Receivables (Sent)',
                        value: '\$${totalReceivables.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'Pending Drafts',
                        value: '\$${pendingDrafts.toStringAsFixed(2)}',
                        icon: Icons.description_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Paid',
                        value: '\$${totalPaid.toStringAsFixed(2)}',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Status Filter Segmented Button or tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusTab(
                        label: 'All Invoices',
                        status: 'all',
                        isSelected: _selectedStatus == 'all',
                        onTap: () => setState(() => _selectedStatus = 'all'),
                      ),
                      _StatusTab(
                        label: 'Draft',
                        status: 'draft',
                        isSelected: _selectedStatus == 'draft',
                        onTap: () => setState(() => _selectedStatus = 'draft'),
                      ),
                      _StatusTab(
                        label: 'Sent (Pending Payment)',
                        status: 'sent',
                        isSelected: _selectedStatus == 'sent',
                        onTap: () => setState(() => _selectedStatus = 'sent'),
                      ),
                      _StatusTab(
                        label: 'Paid',
                        status: 'paid',
                        isSelected: _selectedStatus == 'paid',
                        onTap: () => setState(() => _selectedStatus = 'paid'),
                      ),
                      _StatusTab(
                        label: 'Void',
                        status: 'void',
                        isSelected: _selectedStatus == 'void',
                        onTap: () => setState(() => _selectedStatus = 'void'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Invoices Found',
                          description: 'Generated invoice bills will appear here automatically on trip completion.',
                          icon: Icons.receipt_long_outlined,
                        )
                      : GridView.builder(
                          itemCount: filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                          itemBuilder: (context, index) {
                            final invoice = filtered[index];
                            return _InvoiceCard(invoice: invoice);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final String status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final InvoiceEntity invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    switch (invoice.status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'sent':
        statusColor = Colors.blue;
        break;
      case 'draft':
        statusColor = Colors.orange;
        break;
      case 'void':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.black;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        invoice.customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    invoice.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 14),
                const SizedBox(width: 6),
                Text('Trip Ref: ${invoice.tripId}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Due: ${invoice.dueDate.toLocal().toString().split(' ')[0]}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${invoice.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    if (invoice.status == 'draft')
                      ElevatedButton(
                        onPressed: () {
                          ref.read(invoiceListControllerProvider.notifier).updateStatus(invoice.id, 'sent');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('Send'),
                      ),
                    if (invoice.status == 'sent')
                      ElevatedButton(
                        onPressed: () {
                          ref.read(invoiceListControllerProvider.notifier).updateStatus(invoice.id, 'paid');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('Mark Paid'),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () {
                        ref.read(invoiceListControllerProvider.notifier).deleteInvoice(invoice.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
