// lib/core/web/web_download_helper_web.dart
import 'dart:html' as html;

void triggerWebBrowserDownload(String url, String filename) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    try {
      html.window.open(url, '_blank');
    } catch (_) {}
  }
}
