import 'package:flutter/material.dart';
import 'package:nova_places_autocomplete/nova_places_autocomplete.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

///
///
///
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlaceAutocompletePrediction? _prediction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Places'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              NovaPlacesAutocomplete(
                apiKey: 'api-key',
                detailRequired: true,
                onPicked: (prediction) {
                  print(prediction);
                  setState(() {
                    _prediction = prediction;
                  });
                },
                onSearchFailed: (error) {
                  print(error);
                },
                onPickedPlaceDetail: (detail) {
                  print(detail);
                },
              ),
              const SizedBox(height: 140.0),
              if (_prediction != null) Text(_prediction!.description),
            ],
          ),
        ),
      ),
    );
  }
}
