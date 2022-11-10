## Nova Places Autocomplete [![Pub](https://img.shields.io/pub/v/nova_places_autocomplete.svg)](https://pub.dev/packages/nova_places_autocomplete)

TextField lets you search for place information using a variety of categories, including establishments, prominent points of interest, and geographic locations. You can search for places either by proximity or a text string. A Place Search returns a list of places along with summary information about each place.

This package uses [Google Places API](https://developers.google.com/maps/documentation/places/web-service/search) and requires an API key. Please check [this link](https://developers.google.com/maps/documentation/places/web-service/get-api-key) out to obtain your API key.

🍭 Remember to enable `Places API` for your API key.

### Demo
[![textfield-place-picker.gif](https://i.postimg.cc/6p1t6Dhk/textfield-place-picker.gif)](https://postimg.cc/4YtrB2qP)

### Sample Usage

```dart
import 'package:nova_places_autocomplete/nova_places_autocomplete.dart';

NovaPlacesAutocomplete(
  apiKey: 'api-key',
  detailRequired: true,
  onPicked: (prediction) {
    print(prediction);
  },
  onSearchFailed: (error) {
    print(error);
  },
  onPickedPlaceDetail: (detail) {
    print(detail);
  },
)
```