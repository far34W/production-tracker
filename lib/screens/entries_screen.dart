// lib/screens/entries_screen.dart
//
// Scrollable list of all ProductionEntry records with real-time search,
// shift filter chips, sort control, and FAB to add new entries.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/production_entry.dart';
import '../providers/production_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_card.dart';
import 'entry_form_screen.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  final _searchCtrl = TextEditingController();
  bool _showFilter  = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilter) _buildFilterBar(),
          _buildList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_entry',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EntryFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildSearchBar() => Consumer<ProductionProvider>(
    builder: (ctx, provider, _) => Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: provider.setSearch,
              decoration: InputDecoration(
                hintText: 'Search operator or date…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10,
                ),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _showFilter ? AppTheme.primary : Colors.grey,
            ),
            onPressed: () => setState(() => _showFilter = !_showFilter),
          ),
        ],
      ),
    ),
  );

  Widget _buildFilterBar() => Consumer<ProductionProvider>(
    builder: (ctx, provider, _) => Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Shift filter chips
          Row(
            children: [
              const Text('Shift: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 4),
              _chip('All', provider.shiftFilter == null,
                  () => provider.setShiftFilter(null)),
              const SizedBox(width: 6),
              _chip('Day', provider.shiftFilter == Shift.day,
                  () => provider.setShiftFilter(Shift.day)),
              const SizedBox(width: 6),
              _chip('Night', provider.shiftFilter == Shift.night,
                  () => provider.setShiftFilter(Shift.night)),
              const Spacer(),
              // Sort
              DropdownButtonHideUnderline(
                child: DropdownButton<SortOrder>(
                  value: provider.sortOrder,
                  isDense: true,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  items: const [
                    DropdownMenuItem(
                        value: SortOrder.dateDesc,
                        child: Text('Newest first')),
                    DropdownMenuItem(
                        value: SortOrder.dateAsc,
                        child: Text('Oldest first')),
                    DropdownMenuItem(
                        value: SortOrder.operatorAsc,
                        child: Text('Operator A→Z')),
                  ],
                  onChanged: (v) { if (v != null) provider.setSortOrder(v); },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
    ),
  );

  Widget _buildList() => Expanded(
    child: Consumer<ProductionProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading && provider.allEntries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = provider.entries;

        if (entries.isEmpty) {
          return _empty(provider);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final e = entries[i];
            return EntryCard(
              key: ValueKey(e.id),
              entry: e,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EntryFormScreen(entry: e),
                ),
              ),
            );
          },
        );
      },
    ),
  );

  Widget _empty(ProductionProvider provider) {
    final filtered = provider.searchQuery.isNotEmpty ||
        provider.shiftFilter != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filtered
                ? Icons.search_off_rounded
                : Icons.assignment_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Text(
            filtered ? 'No entries match' : 'No production entries yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try clearing your filters'
                : 'Tap + to add your first shift entry',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          if (filtered) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                provider.clearFilters();
              },
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}
