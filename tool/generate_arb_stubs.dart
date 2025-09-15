import 'dart:convert';
import 'dart:io';

// Locales to generate, as BCP-47-like tags.
const List<String> _tags = [
  'af','am','ar','az','be','bg','bn','bs','ca','cs','da','de','el','en','es','et','eu','fa','fi','fil','fr','ga','gl','gu','he','hi','hr','hu','hy','id','is','it','ja','ka','kk','km','kn','ko','ky','lo','lt','lv','mk','ml','mn','mr','ms','my','nb','ne','nl','or','pa','pl','ps','pt','ro','ru','si','sk','sl','sq','sr','sv','sw','ta','te','th','tk','tr','uk','ur','uz','vi','zh','zh_HK','zh_TW'
];

void main() async {
  final arbDir = Directory('lib/l10n');
  if (!arbDir.existsSync()) {
    stderr.writeln('Directory lib/l10n not found');
    exit(1);
  }
  final templateFile = File('lib/l10n/app_en.arb');
  if (!templateFile.existsSync()) {
    stderr.writeln('Template ARB lib/l10n/app_en.arb not found');
    exit(1);
  }
  final template = json.decode(await templateFile.readAsString()) as Map<String, dynamic>;

  int created = 0;
  for (final tag in _tags) {
    if (tag == 'en') continue; // template exists
    final out = File('lib/l10n/app_$tag.arb');
    if (out.existsSync()) continue;

    final map = <String, dynamic>{...template};
    map['@@locale'] = tag;

    await out.writeAsString(const JsonEncoder.withIndent('  ').convert(map) + '\n');
    created++;
  }
  stdout.writeln('Generated $created ARB stubs in lib/l10n');
}
