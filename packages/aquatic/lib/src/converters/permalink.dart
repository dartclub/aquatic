import 'package:aquatic/aquatic.dart';
import 'package:aquatic/src/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:week_of_year/week_of_year.dart';

class PermalinkTemplate {
  final AquaticEntity entity;
  final bool jekyllStyleTemplate;

  PermalinkTemplate(
    this.entity, {
    this.jekyllStyleTemplate = true,
  });

  String _getPath() => entity.context?['path'] ?? entity.path;
  String _getSlug() => entity.context?['slug'] ?? entity.slug;
  List _getCategories() => entity.context?['categories'] ?? [];
  String _getTitle() => entity.context?['title'] as String;
  DateTime _getBuildTime() => entity.buildTime;
  DateTime _getDate() => entity.context?['date'] ?? _getBuildTime();
  String _convertDay(String day) =>
      '${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(day) + 1}';

  int _weekOfMonth() {
    var date = _getDate();
    var result = 0;

    while (date.month == _getDate().month) {
      result++;
      date = date.subtract(const Duration(days: 7));
    }

    return result;
  }

  int _weekOfYear() => _getDate().weekOfYear;

  Map<String, Function> jekyllReservedWords() => {
        'categories': () => '/' + _getCategories().join('/'),
        'path': () => AquaticUtils.relativePath(_getPath()),
        'basename': () => AquaticUtils.basename(_getPath()),
        'name': () => AquaticUtils.basename(_getPath()),
        'output_ext': () => AquaticUtils.outputExt(_getPath()),
        'collection': () => AquaticUtils.basepath(_getPath(),
            jekyllStyleCollection: jekyllStyleTemplate),
        'title': () => _getTitle(),
        'slug': () => _getSlug(),
        /* non-jekyll */
        'date': () => DateFormat.yMd().format(_getDate()),
        /* non-jekyll */
        'time': () => DateFormat.jm().format(_getDate()),
        'year': () => DateFormat('yyyy').format(_getDate()),
        'short_year': () => DateFormat('yy').format(_getDate()),
        'month': () => DateFormat('MM').format(_getDate()),
        'i_month': () => DateFormat('M').format(_getDate()),
        'short_month': () => DateFormat('MMM').format(_getDate()),
        'long_month': () => DateFormat('MMMM').format(_getDate()),
        'day': () => DateFormat('dd').format(_getDate()),
        'i_day': () => DateFormat('d').format(_getDate()),
        'y_day': () => DateFormat('D').format(_getDate()),
        'w_day': () => _convertDay(DateFormat('E').format(_getDate())),
        'week': () => _weekOfMonth().toString(),
        'w_year': () => _weekOfYear().toString(),
        'short_day': () => DateFormat('E').format(_getDate()),
        'long_day': () => DateFormat('EEEE').format(_getDate()),
        'hour': () => DateFormat('HH').format(_getDate()),
        'minute': () => DateFormat('mm').format(_getDate()),
        'second': () => DateFormat('ss').format(_getDate()),
      };

  String _readWord(String field) {
    String output = '';
    for (int index = 0; index < field.length; index++) {
      var f = field[index];
      if (RegExp(r'[a-zA-Z0-9_\\.]').hasMatch(f)) {
        output += f;
      } else if (f == ':' ||
          f == '/' ||
          f == '}' ||
          RegExp('[\n\s]').hasMatch(f)) {
        return output;
      } else {
        throw Exception(
            'illegal expression, unexpected symbol in template \'$f\'');
      }
    }
    return output;
  }

  String _getVariableFromContext(String word) {
    String _recursiveGet(List<String> vars, Map context) {
      if (vars.length > 1) {
        var sublist = vars.sublist(1);
        if (context[vars.first] is Map) {
          return _recursiveGet(sublist, context[vars.first]);
        } else {
          throw Exception('illegal context path: not type \'Map\'');
        }
      } else {
        if (context[vars.first] is String) {
          return context[vars.first];
        } else {
          throw Exception('illegal context variable: not type \'String\'');
        }
      }
    }

    if (word.isEmpty) {
      return ':';
    } else if (word.contains('.')) {
      var parts = word.split('.');
      return _recursiveGet(parts, entity.toMap());
    } else {
      return _recursiveGet([word], entity.toMap());
    }
  }

  String render(String template) {
    String output = '';
    bool bracketOpen = false;
    for (int index = 0; index < template.length; index++) {
      if (template[index] == '}') {
        bracketOpen = false;
      } else if (template[index] == ':') {
        index++;

        if (template[index] == '{') {
          index++;
          bracketOpen = true;
        }

        String word = _readWord(template.substring(index));
        index += word.length - 1;
        var callback = jekyllReservedWords()[word];

        if (callback != null) {
          output += callback();
        } else {
          output += _getVariableFromContext(word);
        }
      } else {
        output += template[index];
      }
    }
    if (bracketOpen) {
      throw Exception('illegal expression, expected \'}\'');
    }
    return output;
  }
}
