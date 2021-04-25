import 'package:skynet/skynet.dart';

String resolveSkylink(String link, {bool trusted = false}) {
  // print('resolveSkylink $link');

  // TODO Tests
  if (link.startsWith('sia://')) {
    final uri = Uri.tryParse(link);

    if (uri == null) return null;

    final host = uri.host;

    if (host.endsWith('.hns')) {
      return 'https://${host.split(".").first}.hns.${SkynetConfig.host}/${link.substring(6 + host.length + 1)}';
    } else {
      return 'https://${SkynetConfig.host}/' + link.substring(6);
    }
  }

  if (trusted) {
    return link;
  } else {
    print('disallowed link $link');
    return '';
  }
}
