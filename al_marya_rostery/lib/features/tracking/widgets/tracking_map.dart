import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/tracking_model.dart';

/// Live tracking map widget with driver, staff, and user markers
class TrackingMapWidget extends StatefulWidget {
  final LiveOrderTracking tracking;
  final VoidCallback? onRecenter;

  const TrackingMapWidget({super.key, required this.tracking, this.onRecenter});

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _previousDriverLocation;
  AnimationController? _animationController;
  Animation<LatLng>? _driverAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _updateMapData();
  }

  @override
  void didUpdateWidget(TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracking != widget.tracking) {
      _updateMapData();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMapData() {
    _updateMarkers();
    _updatePolylines();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // User location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: LatLng(
          widget.tracking.userLocation.lat,
          widget.tracking.userLocation.lng,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: widget.tracking.address.fullAddress,
        ),
      ),
    );

    // Staff location marker (if available)
    if (widget.tracking.staffLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('staff'),
          position: LatLng(
            widget.tracking.staffLocation!.lat,
            widget.tracking.staffLocation!.lng,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Staff Location',
            snippet: widget.tracking.staff?.name ?? 'Preparing your order',
          ),
        ),
      );
    }

    // Driver location marker (animated if available)
    if (widget.tracking.driverLocation != null) {
      final driverLatLng = LatLng(
        widget.tracking.driverLocation!.lat,
        widget.tracking.driverLocation!.lng,
      );

      // Animate driver marker movement
      if (_previousDriverLocation != null &&
          _previousDriverLocation != driverLatLng) {
        _animateDriverMarker(_previousDriverLocation!, driverLatLng);
      } else {
        _addDriverMarker(driverLatLng);
      }

      _previousDriverLocation = driverLatLng;
    }

    setState(() {
      _markers = markers;
    });
  }

  void _addDriverMarker(LatLng position) {
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        rotation: widget.tracking.driverLocation?.heading ?? 0,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: widget.tracking.driver?.name ?? 'Driver',
          snippet: widget.tracking.isPickedUp
              ? 'On the way with your order'
              : 'Heading to pickup',
        ),
      ),
    );
  }

  void _animateDriverMarker(LatLng from, LatLng to) {
    _driverAnimation = LatLngTween(begin: from, end: to).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _animationController!.forward(from: 0.0).then((_) {
      _addDriverMarker(to);
    });

    _driverAnimation!.addListener(() {
      final animatedPosition = _driverAnimation!.value;
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');
      _addDriverMarker(animatedPosition);
      setState(() {});
    });
  }

  void _updatePolylines() {
    final polylines = <Polyline>{};
    final primaryColor = Theme.of(context).primaryColor;

    // Create route polyline
    final points = <LatLng>[];

    if (widget.tracking.driverLocation != null) {
      points.add(
        LatLng(
          widget.tracking.driverLocation!.lat,
          widget.tracking.driverLocation!.lng,
        ),
      );
    }

    // If not picked up yet, route through staff location
    if (!widget.tracking.isPickedUp && widget.tracking.staffLocation != null) {
      points.add(
        LatLng(
          widget.tracking.staffLocation!.lat,
          widget.tracking.staffLocation!.lng,
        ),
      );
    }

    // Add user location
    points.add(
      LatLng(
        widget.tracking.userLocation.lat,
        widget.tracking.userLocation.lng,
      ),
    );

    if (points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: primaryColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBoundsToMarkers();
  }

  void _fitBoundsToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    final bounds = _calculateBounds();
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLngBounds _calculateBounds() {
    double? minLat, maxLat, minLng, maxLng;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _recenterMap() {
    if (widget.tracking.driverLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            widget.tracking.driverLocation!.lat,
            widget.tracking.driverLocation!.lng,
          ),
          15,
        ),
      );
    } else {
      _fitBoundsToMarkers();
    }
    widget.onRecenter?.call();
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition =
        widget.tracking.driverLocation ??
        widget.tracking.staffLocation ??
        widget.tracking.userLocation;

    return Stack(
      children: [
        // Google Map
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(initialPosition.lat, initialPosition.lng),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: true,
          ),
        ),

        // Recenter button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            onPressed: _recenterMap,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),

        // Driver stationary indicator
        if (widget.tracking.isDriverStationary)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_circle, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver is currently stationary',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom LatLng Tween for smooth animations
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
