import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../data/brewing_method_model.dart';
import '../../data/brewing_method_api_service.dart';
import '../widgets/brewing_method_card.dart';
import '../widgets/brewing_method_filter_bar.dart';

class BrewingMethodsPage extends StatefulWidget {
  const BrewingMethodsPage({super.key});

  @override
  State<BrewingMethodsPage> createState() => _BrewingMethodsPageState();
}

class _BrewingMethodsPageState extends State<BrewingMethodsPage>
    with TickerProviderStateMixin {
  final BrewingMethodApiService _apiService = BrewingMethodApiService();
  List<BrewingMethod> _allMethods = [];
  List<BrewingMethod> _filteredMethods = [];
  List<BrewingMethod> _popularMethods = [];
  bool _isLoading = true;
  String? _error;
  List<String> _selectedCategories = [];
  List<String> _selectedDifficulties = [];
  String? _searchQuery;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Refresh UI when tab changes
      }
    });
    _loadBrewingMethods();
    _loadPopularMethods();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBrewingMethods() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final methods = await _apiService.fetchBrewingMethods(limit: 100);

      setState(() {
        _allMethods = methods;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPopularMethods() async {
    try {
      final popular = await _apiService.fetchPopularBrewingMethods(limit: 8);
      setState(() {
        _popularMethods = popular;
      });
    } catch (e) {
      // Don't show error for popular methods, just log it
      debugPrint('Error loading popular methods: $e');
    }
  }

  void _applyFilters() {
    List<BrewingMethod> filtered = List.from(_allMethods);

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((method) {
        final query = _searchQuery!.toLowerCase();
        return method.name.en.toLowerCase().contains(query) ||
            method.name.ar.toLowerCase().contains(query) ||
            method.description.en.toLowerCase().contains(query) ||
            method.description.ar.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by difficulties
    if (_selectedDifficulties.isNotEmpty) {
      filtered = filtered
          .where((method) => _selectedDifficulties.contains(method.difficulty))
          .toList();
    }

    // Filter by categories
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where(
            (method) => method.categories.any(
              (cat) => _selectedCategories.any(
                (selectedCat) =>
                    cat.toLowerCase().contains(selectedCat.toLowerCase()),
              ),
            ),
          )
          .toList();
    }

    setState(() {
      _filteredMethods = filtered;
    });
  }

  void _navigateToDetail(BrewingMethod method) {
    Navigator.pushNamed(context, '/brewing-method-detail', arguments: method);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.isArabic ? 'دليل التحضير' : 'Brewing Guide',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: context.isArabic ? 'الكل' : 'All Methods',
              icon: const Icon(Icons.grid_view),
            ),
            Tab(
              text: context.isArabic ? 'المشهورة' : 'Popular',
              icon: const Icon(Icons.star),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllMethodsTab(), _buildPopularMethodsTab()],
      ),
    );
  }

  Widget _buildAllMethodsTab() {
    return Column(
      children: [
        // Filter Bar
        BrewingMethodFilterBar(
          selectedCategories: _selectedCategories,
          selectedDifficulties: _selectedDifficulties,
          searchQuery: _searchQuery,
          onCategoriesChanged: (categories) {
            setState(() {
              _selectedCategories = categories;
            });
            _applyFilters();
          },
          onDifficultiesChanged: (difficulties) {
            setState(() {
              _selectedDifficulties = difficulties;
            });
            _applyFilters();
          },
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
            _applyFilters();
          },
          onClearFilters: () {
            setState(() {
              _selectedCategories.clear();
              _selectedDifficulties.clear();
              _searchQuery = null;
            });
            _applyFilters();
          },
        ),

        // Results Count
        if (!_isLoading && _error == null && _tabController.index == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Text(
              context.isArabic
                  ? 'تم العثور على ${_filteredMethods.length} طريقة تحضير'
                  : '${_filteredMethods.length} methods found',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 14),
            ),
          ),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildPopularMethodsTab() {
    if (_popularMethods.isEmpty) {
      return _buildLoadingState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.isArabic
              ? 'طرق التحضير الأكثر شعبية'
              : 'Most Popular Brewing Methods',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ...(_popularMethods.map(
          (method) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BrewingMethodCard(
              brewingMethod: method,
              onTap: () => _navigateToDetail(method),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredMethods.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBrewingMethods,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMethods.length,
        itemBuilder: (context, index) {
          final method = _filteredMethods[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BrewingMethodCard(
              brewingMethod: method,
              onTap: () => _navigateToDetail(method),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading brewing methods...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.textMedium),
          const SizedBox(height: 16),
          Text(
            context.isArabic
                ? 'فشل في تحميل طرق التحضير'
                : 'Failed to load brewing methods',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadBrewingMethods,
            icon: const Icon(Icons.refresh),
            label: Text(context.isArabic ? 'إعادة المحاولة' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textMedium),
          const SizedBox(height: 16),
          Text(
            context.isArabic
                ? 'لم يتم العثور على طرق تحضير'
                : 'No brewing methods found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            context.isArabic
                ? 'جرب تغيير المرشحات أو البحث عن شيء آخر'
                : 'Try adjusting your filters or search for something else',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedCategories.clear();
                _selectedDifficulties.clear();
                _searchQuery = null;
              });
              _applyFilters();
            },
            icon: const Icon(Icons.clear_all),
            label: Text(context.isArabic ? 'مسح المرشحات' : 'Clear Filters'),
          ),
        ],
      ),
    );
  }
}
