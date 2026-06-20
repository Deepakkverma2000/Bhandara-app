import 'package:url_launcher/url_launcher.dart';

Future<void> openInGoogleMaps(double latitude, double longitude) async {
  final googleMapsUrl = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );
  final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

  if (await canLaunchUrl(googleMapsUrl)) {
    await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
  } else if (await canLaunchUrl(geoUrl)) {
    await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
  }
}

Future<void> openWhatsAppWithLocation(
  double latitude,
  double longitude,
  String label,
) async {
  final mapsLink =
      'https://maps.google.com/?q=$latitude,$longitude';
  final message = Uri.encodeComponent(
    'Bhandara Location: $label\n$mapsLink',
  );
  final whatsappUrl = Uri.parse('https://wa.me/?text=$message');

  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } else {
    await openInGoogleMaps(latitude, longitude);
  }
}
