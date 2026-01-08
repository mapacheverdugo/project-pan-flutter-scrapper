import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/institution.dart';
import 'package:pan_scrapper/models/product.dart';

/// Immutable model representing the connection state
class ConnectionState {
  final bool isLoading;
  final List<Product> products;
  final Institution? institution;
  final List<String> selectedProductIds;

  const ConnectionState({
    this.isLoading = false,
    this.products = const [],
    this.institution,
    this.selectedProductIds = const [],
  });

  ConnectionState copyWith({
    bool? isLoading,
    List<Product>? products,
    Institution? institution,
    List<String>? selectedProductIds,
  }) {
    return ConnectionState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      institution: institution ?? this.institution,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionState &&
        other.isLoading == isLoading &&
        other.products == products &&
        other.institution == institution &&
        other.selectedProductIds == selectedProductIds;
  }

  @override
  int get hashCode =>
      Object.hash(isLoading, products, institution, selectedProductIds);
}

/// Notifier that manages the connection state
class ConnectionNotifier extends ValueNotifier<ConnectionState> {
  ConnectionNotifier(ConnectionState super.value);

  /// Sets the loading state
  void setLoading(bool loading) {
    value = value.copyWith(isLoading: loading);
  }

  /// Sets the products list and selects all products by default
  void setProducts(List<Product> products) {
    final allProductIds = products.map((product) => product.id).toList();
    value = value.copyWith(
      products: products,
      selectedProductIds: allProductIds,
      isLoading: false,
    );
  }

  /// Sets the institution
  void setInstitution(Institution institution) {
    value = value.copyWith(institution: institution);
  }

  /// Toggles the selection of a product
  void toggleProductSelection(String productId) {
    final currentSelected = List<String>.from(value.selectedProductIds);
    if (currentSelected.contains(productId)) {
      currentSelected.remove(productId);
    } else {
      currentSelected.add(productId);
    }
    value = value.copyWith(selectedProductIds: currentSelected);
  }

  /// Sets the selected product IDs
  void setSelectedProductIds(List<String> selectedProductIds) {
    value = value.copyWith(selectedProductIds: selectedProductIds);
  }

  /// Clears the state (resets to initial state)
  void clear() {
    value = const ConnectionState();
  }
}

/// Provider widget that shares ConnectionNotifier across the widget tree
class ConnectionProvider extends InheritedNotifier<ConnectionNotifier> {
  const ConnectionProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  /// Static method to access the ConnectionNotifier from the widget tree
  static ConnectionNotifier of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ConnectionProvider>();

    if (provider == null) {
      throw Exception('No ConnectionProvider found in context');
    }

    final notifier = provider.notifier;

    if (notifier == null) {
      throw Exception('No notifier found in ConnectionProvider');
    }

    return notifier;
  }
}
