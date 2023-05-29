import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:firebase_core/firebase_core.dart';
import 'package:somt/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Algo());
}

class LocalizationWidget extends StatefulWidget {
  const LocalizationWidget({super.key});

  @override
  State<LocalizationWidget> createState() => _LocalizationWidget();
}

class _LocalizationWidget extends State<LocalizationWidget> {
  lat_lng.LatLng _center = lat_lng.LatLng(0, 0);
  lat_lng.LatLng _markerLoc = lat_lng.LatLng(0, 0);

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
    Position position = await _determinePosition();
    //_center = lat_lng.LatLng(position.latitude, position.longitude);
    setState(() {
      _markerLoc = lat_lng.LatLng(position.latitude, position.longitude);
      _center = lat_lng.LatLng(position.latitude, position.longitude);
    });
  }

  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Position position = await _determinePosition();
      mapController.move(_center, 15);
    });
    onStartLocation();
  }

  @override
  Widget build(BuildContext context) {
    GeoPoint geopoint = GeoPoint(_markerLoc.latitude, _markerLoc.longitude);
    List<Marker> allMarkers = <Marker>[];
    final setLocation = FirebaseFirestore.instance
        .collection('localisations')
        .doc("location")
        .set({
      'location': geopoint,
    });
    final getLocation = FirebaseFirestore.instance
        .collection('localisations')
        .doc("location")
        .get();
// loop the result and add the values to the Markers list.
    getLocation.then(
      (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          allMarkers.add(Marker(
            // Adapt below for multi geolocation points
            point: lat_lng.LatLng(value.latitude, value.longitude),
            width: 80,
            height: 80,
            builder: (context) => FlutterLogo(),
          ));
        });
      },
      onError: (e) => print("Error getting document: $e"),
    );

    //updateStartingLocalization();

    return Scaffold(
      appBar: AppBar(
        title: Text("Geofriends"),
      ),
      body: Center(
          child: FlutterMap(
        options: MapOptions(center: lat_lng.LatLng(0, 0)),
        mapController: mapController,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: allMarkers),
        ],
      )),
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
      home: LocalizationWidget(),
    );
  }
}
