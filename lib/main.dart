import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:firebase_core/firebase_core.dart';
import 'package:somt/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Algo());
}

class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({super.key});

  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  latLng.LatLng _center = latLng.LatLng(0, 0);
  latLng.LatLng _markerLoc = latLng.LatLng(0, 0);

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void onStartLocation() async {
    print("onStartLocation()");
    Position _position = await _determinePosition();
    //_center = latLng.LatLng(_position.latitude, _position.longitude);
    setState(() {
      _markerLoc = latLng.LatLng(_position.latitude, _position.longitude);
      _center = latLng.LatLng(_position.latitude, _position.longitude);
    });

    print("_center-onStartLocation");
    print(_center);
  }

  void somthingelse() async {
    Position _position = await _determinePosition();
  }

  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Position _position = await _determinePosition();
      mapController.move(_center, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Widget");
    somthingelse();
    onStartLocation();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(center: latLng.LatLng(0, 0)),
            mapController: mapController,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: latLng.LatLng(
                        _markerLoc.latitude, _markerLoc.longitude),
                    width: 80,
                    height: 80,
                    builder: (context) => FlutterLogo(),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ···

class Algo extends StatelessWidget {
  const Algo({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Geofriends',
      home: FavoriteWidget(),
    );
  }
}
