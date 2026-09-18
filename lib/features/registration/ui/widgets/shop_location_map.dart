import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// OpenStreetMap's public tiles. No key is needed, and their usage policy
/// asks for an identifying package name on every request.
const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'com.example.cse_b2b';

/// Where the map opens when there is nothing better to centre on. This is a
/// view position only — it is never stored as the shop's pin.
const fallbackCentre = LatLng(31.5204, 74.3587);

/// Real map tiles under a pin the partner can place.
///
/// [pin] is the shop's position once one has been chosen. When it is null the
/// map still opens — centred on [centre] — but shows no pin, so an unplaced
/// shop is never drawn as if it had a location.
class ShopLocationMap extends StatefulWidget {
  const ShopLocationMap({
    super.key,
    this.pin,
    this.centre,
    this.onPinMoved,
    this.interactive = true,
  });

  final LatLng? pin;
  final LatLng? centre;

  /// Called with the new position each time the partner places the pin.
  /// Null makes the map read-only.
  final ValueChanged<LatLng>? onPinMoved;

  final bool interactive;

  @override
  State<ShopLocationMap> createState() => _ShopLocationMapState();
}

class _ShopLocationMapState extends State<ShopLocationMap> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final centre = pin ?? widget.centre ?? fallbackCentre;
    final canMove = widget.interactive && widget.onPinMoved != null;

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: pin == null ? 13 : 16,
        // Tapping the map is how the pin is placed; dragging it is handled by
        // the marker below.
        onTap: canMove ? (_, point) => widget.onPinMoved!(point) : null,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _userAgent),
        if (pin != null)
          MarkerLayer(
            markers: [
              Marker(
                point: pin,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: _Pin(
                  draggable: canMove,
                  onDragged: (offset) => _movePin(pin, offset),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Converts a drag in screen pixels into a new coordinate, so the pin lands
  /// exactly where it was let go.
  void _movePin(LatLng from, Offset delta) {
    final camera = _controller.camera;
    final point = camera.latLngToScreenOffset(from) + delta;
    widget.onPinMoved!(camera.offsetToCrs(point));
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.draggable, required this.onDragged});

  final bool draggable;
  final ValueChanged<Offset> onDragged;

  @override
  Widget build(BuildContext context) {
    final marker = Icon(
      LucideIcons.mapPin,
      size: 34,
      color: context.colors.error,
    );
    if (!draggable) return marker;

    return GestureDetector(
      onPanUpdate: (details) => onDragged(details.delta),
      child: marker,
    );
  }
}
