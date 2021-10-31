import 'dart:io';

import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/replacements.dart';
import 'package:path/path.dart' as path_lib;

enum AquaticSlugType { raw, defaultType, pretty, ascii, latin }

class AquaticUtils {
  static String _capitalize(String s) {
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  static String _replaceIfStartsWith(
      String s, String pattern, String replacement) {
    if (s.startsWith(pattern)) {
      return replacement + s.substring(pattern.length);
    } else {
      return s;
    }
  }

  static bool isUri(String path) => path.startsWith(RegExp(r'[a-z]+://'));

  static String relativePath(String path) =>
      isUri(path) ? path : path_lib.relative(path);
  static String relativePathWithoutName(String path) {
    if (isUri(path)) {
      var parsed = Uri.parse(path);
      return path.substring(0, path.length - parsed.pathSegments.last.length);
    } else {
      var splitted = path_lib.split(path);
      splitted.removeLast();
      return path_lib.relative(path_lib.joinAll(splitted));
    }
  }

  static String absolutePath(String path) {
    if (isUri(path)) {
      return path;
    }
    return path_lib.isAbsolute(path)
        ? path_lib.absolute(path)
        : path_lib.relative(path);
  }

  static String basename(String path, {withoutExtension = true}) {
    if (isUri(path)) {
      var p = Uri.parse(path).pathSegments.last;
      if (withoutExtension) {
        var end = p.lastIndexOf('.');
        if (end > 0) {
          return p.substring(0, end);
        } else {
          return p;
        }
      } else {
        return p;
      }
    }

    return withoutExtension
        ? path_lib.basenameWithoutExtension(path)
        : path_lib.basename(path);
  }

  static String outputExt(String path) {
    if (isUri(path)) {
      var p = Uri.parse(path).pathSegments.last;
      var start = p.lastIndexOf('.');
      if (start > -1) {
        return p.substring(start);
      } else {
        return p;
      }
    }
    return path_lib.extension(path);
  }

  static String basepath(String path, {bool jekyllStyleCollection = false}) {
    String p;
    if (isUri(path)) {
      var segments = Uri.parse(path).pathSegments;
      p = segments[segments.length - 2];
    } else {
      p = path_lib.relative(path);
      p = p.split('/')[p.split('/').length - 2];
    }
    if (jekyllStyleCollection) {
      return _replaceIfStartsWith(p, '_', '');
    } else {
      return p;
    }
  }

  static String slugifyPath(
    String path, {
    AquaticSlugType type = AquaticSlugType.defaultType,
    bool cased = false,
  }) {
    if (isUri(path)) {
      path = Uri.parse(path).host + Uri.parse(path).path;
    } else {
      path = relativePath(path);
    }
    return slugify(path, type: type, cased: cased);
  }

  static final _rawRegexp = RegExp(r'\s+');
  static final _defaultRegexp = RegExp(r"[^\d\w]|[\._~!$&'()+,;=@]+");
  static final _prettyRegexp = RegExp(r"[^\d\w\._~!$&'()+,;=@]+");
  static final _asciiRegexp = RegExp(r"[^a-zA-Z0-9]+");
  static final _dupeRegexp = RegExp(r"-{2,}");
  static final _trimRegexp = RegExp(r"^-|-$");

  static String slugify(
    String input, {
    AquaticSlugType type = AquaticSlugType.defaultType,
    bool cased = false,
  }) {
    String output = input.trim();
    var regexp = _defaultRegexp;
    switch (type) {
      case AquaticSlugType.raw:
        regexp = _rawRegexp;
        break;
      case AquaticSlugType.pretty:
        regexp = _prettyRegexp;
        break;
      case AquaticSlugType.ascii:
        regexp = _asciiRegexp;
        break;
      case AquaticSlugType.latin:
        replacements.forEach((k, v) => output = output.replaceAll(k, v));
        break;
      case AquaticSlugType.defaultType:
        regexp = _defaultRegexp;
        break;
    }
    output = output
        .replaceAll(regexp, '-')
        .replaceAll(_dupeRegexp, '-')
        .replaceAll(_trimRegexp, '');
    if (!cased) output = output.toLowerCase();

    return output;
  }

  static String titelizeSlug(String slug) =>
      slug.split('-').map((s) => _capitalize(s)).join(' ');

  static AquaticOperation convertFileEventToOp(int event) {
    switch (event) {
      case FileSystemEvent.modify:
        return AquaticOperation.update;
      case FileSystemEvent.move:
        return AquaticOperation.update;
      case FileSystemEvent.delete:
        return AquaticOperation.delete;
      case FileSystemEvent.create:
      case FileSystemEvent.all:
      default:
        return AquaticOperation.create;
    }
  }
}

enum ReplacementType {
  all,
  first,
  last,
}

extension StringReplaceExtension on String {
  String replace(
      Pattern from, String replacement, ReplacementType replacementType) {
    String output = this;
    switch (replacementType) {
      case ReplacementType.all:
        output = output.replaceAll(from, replacement);
        break;
      case ReplacementType.first:
        output = output.replaceFirst(from, replacement);
        break;
      case ReplacementType.last:
      default:
        int length = output.lastIndexOf(from) + from.toString().length;
        if (length == output.length) {
          output = output.replaceRange(
            output.lastIndexOf(from),
            output.length,
            replacement,
          );
        } else {
          return output;
        }
        break;
    }
    return output;
  }
}
