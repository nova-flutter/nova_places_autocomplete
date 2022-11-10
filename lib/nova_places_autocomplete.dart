library nova_places_autocomplete;

import 'package:flutter/material.dart';
import 'package:nova_places_api/nova_places_api.dart';

import 'debouncer.dart';

export 'package:nova_places_api/nova_places_api.dart';

class NovaPlacesAutocomplete extends StatefulWidget {
  const NovaPlacesAutocomplete({
    super.key,
    this.debug = false,
    required this.apiKey,
    this.language = 'en',
    this.components,
    this.location,
    this.radius,
    this.offset,
    this.region,
    this.sessionToken,
    this.strictBounds,
    this.types,
    this.autofocus = false,
    this.debounceTime = 600,
    this.detailRequired = false,
    this.prefixIconBuilder,
    this.cancelIconBuilder,
    this.autocompleteOnTrailingWhitespace = false,
    this.spaceBetweenTextFieldAndSuggestions = 6,
    this.suggestionsBackgroundColor = Colors.white,
    this.controller,
    required this.onPicked,
    this.onPickedPlaceDetail,
    this.onSearchFailed,
  });

  // api
  final bool debug;
  final String apiKey;
  final String? language;
  final List<String>? components;
  final LatLngLiteral? location;
  final double? radius;
  final int? offset;
  final String? region;
  final String? sessionToken;
  final bool? strictBounds;
  final List<String>? types;

  // ui
  final bool autofocus;
  final int debounceTime;
  final bool detailRequired;
  final Builder? prefixIconBuilder;
  final Builder? cancelIconBuilder;
  final bool autocompleteOnTrailingWhitespace;
  final double spaceBetweenTextFieldAndSuggestions;
  final Color suggestionsBackgroundColor;

  // callbacks
  final NovaPlacesAutocompleteController? controller;
  final ValueChanged<PlaceAutocompletePrediction> onPicked;
  final ValueChanged<Place>? onPickedPlaceDetail;
  final ValueChanged<String>? onSearchFailed;

  @override
  State<NovaPlacesAutocomplete> createState() => _NovaPlacesAutocompleteState();
}

class _NovaPlacesAutocompleteState extends State<NovaPlacesAutocomplete> {
  late PlacesApi _placesApi;
  late Debouncer _debouncer;
  late String _sessionToken;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  late LayerLink _link;
  OverlayEntry? _overlayEntry;

  String? _prevSearchTerm;

  final _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _placesApi = PlacesApi(apiKey: widget.apiKey);
    _debouncer = Debouncer(milliseconds: widget.debounceTime);
    _sessionToken = widget.sessionToken ?? generateSessionToken();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _link = LayerLink();
    widget.controller?.attach(this);
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _placesApi.dispose();
    _debouncer.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        key: _textFieldKey,
        autofocus: widget.autofocus,
        focusNode: _focusNode,
        controller: _textController,
        onChanged: _onTextChange,
        decoration: InputDecoration(
          prefixIcon: widget.prefixIconBuilder ?? const Icon(Icons.search),
          suffixIcon: GestureDetector(
            onTap: () {
              _clearText();
            },
            child: widget.cancelIconBuilder ?? const Icon(Icons.close),
          ),
        ),
      ),
    );
  }

  void _clearText() {
    _prevSearchTerm = '';
    _textController.clear();
  }

  void _resetSearchBar() {
    _clearText();
    _focusNode.unfocus();
  }

  void _onTextChange(String value) {
    if (value.trim() == _prevSearchTerm?.trim()) {
      _debouncer.cancel();
      return;
    }

    if (!widget.autocompleteOnTrailingWhitespace &&
        value.substring(value.length - 1) == ' ') {
      _debouncer.cancel();
      return;
    }

    _debouncer.run(() {
      _handleSearchText(value.trim());
    });
  }

  ///
  Future<void> _handleSearchText(String searchTerm) async {
    _prevSearchTerm = searchTerm;

    final response = await _placesApi.placeAutocomplete(
      input: searchTerm,
      language: widget.language,
      components: widget.components,
      location: widget.location,
      radius: widget.radius,
      offset: widget.offset,
      region: widget.region,
      sessionToken: _sessionToken,
      types: widget.types,
      strictBounds: widget.strictBounds,
    );

    if (!response.isSuccess) {
      widget.onSearchFailed
          ?.call(response.errorMessage ?? 'Something went wrong');
    } else {
      if (!mounted) return;

      _hideOverlay();

      final overlayView = _buildPredictionsSearchingOverlay(
        context,
        response.predictions,
      );
      _showOverlay(context, overlayView);
    }
  }

  ///
  ///
  ///
  Widget _buildPredictionsSearchingOverlay(
    BuildContext context,
    List<PlaceAutocompletePrediction> predictions,
  ) {
    return _PredictionListView(
      predictions: predictions,
      onPredictionSelect: (prediction) async {
        _resetSearchBar();
        _hideOverlay();
        _textController.text = prediction.description;
        widget.onPicked(prediction);
        if (widget.detailRequired && widget.onPickedPlaceDetail != null) {
          if (prediction.placeId == null) return;
          final resp = await _placesApi.getPlaceDetails(
            placeId: prediction.placeId!,
            language: widget.language,
            region: widget.region,
            sessionToken: _sessionToken,
          );
          if (resp.isSuccess) {
            widget.onPickedPlaceDetail?.call(resp.result!);
          }
        }
      },
    );
  }

  ///
  ///
  ///
  void _showOverlay(BuildContext context, Widget child) {
    final currentContext = _textFieldKey.currentContext;
    if (currentContext == null) return;
    final textFieldRenderBox = currentContext.findRenderObject() as RenderBox;
    final offset = textFieldRenderBox.localToGlobal(Offset.zero);
    final textFieldSize = textFieldRenderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (ctz) {
        return Positioned(
          top: offset.dy + textFieldSize.height,
          left: offset.dx,
          width: textFieldSize.width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(
                0.0,
                textFieldSize.height +
                    widget.spaceBetweenTextFieldAndSuggestions),
            child: Material(
              color: widget.suggestionsBackgroundColor,
              child: child,
            ),
          ),
        );
      },
    );

    final overlay = Overlay.of(context)!;
    overlay.insert(_overlayEntry!);
  }

  ///
  ///
  ///
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

///
///
///
class _PredictionListView extends StatelessWidget {
  const _PredictionListView({
    Key? key,
    required this.predictions,
    required this.onPredictionSelect,
  }) : super(key: key);

  final List<PlaceAutocompletePrediction> predictions;
  final ValueChanged<PlaceAutocompletePrediction> onPredictionSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: predictions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return ListTile(
          title: Text(prediction.description),
          onTap: () {
            onPredictionSelect(prediction);
          },
        );
      },
    );
  }
}

///
///
///
class NovaPlacesAutocompleteController {
  _NovaPlacesAutocompleteState? _autocompleteSearch;

  void attach(_NovaPlacesAutocompleteState searchWidget) {
    _autocompleteSearch = searchWidget;
  }

  void detach() {
    _autocompleteSearch = null;
  }

  void clear() {
    _autocompleteSearch?._clearText();
  }

  void reset() {
    _autocompleteSearch?._resetSearchBar();
  }

  void clearOverlay() {
    _autocompleteSearch?._hideOverlay();
  }
}
