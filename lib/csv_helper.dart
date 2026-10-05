import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

void downloadCsvFile(String csvContent, String fileName) {
  if (kIsWeb) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Explicitly create, configure, click, and clean up
    final html.AnchorElement anchor = html.AnchorElement(href: url);
    anchor.download = fileName;
    anchor.click();
    
    html.Url.revokeObjectUrl(url);
  } else {
    // For native Android debugging/logging
    debugPrint("CSV content generated for $fileName:\n$csvContent");
  }
}