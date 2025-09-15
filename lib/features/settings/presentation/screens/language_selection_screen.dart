import 'package:escort/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:escort/l10n/app_localizations.dart';
import 'package:escort/localization/supported_locales.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final names = LocaleNames.of(context);
    final locales = kSupportedMaterialLocales;
    final current = LocaleController.locale.value;

    final filtered = locales.where((l) {
      if (_query.isEmpty) return true;
      final name = names?.nameOf(_tag(l)) ?? _tag(l);
      return name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.languagePickerTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: t.languagePickerSearchHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final l = filtered[index];
                final name = names?.nameOf(_tag(l)) ?? _pretty(l);
                final selected = _equalsLangRegion(l, current);
                return ListTile(
                  title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_tag(l), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: selected ? const Icon(Icons.check, color: Colors.amber) : null,
                  onTap: () async {
                    await LocaleController.set(l);
                    if (mounted) Navigator.pop(context, l);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _tag(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
      ? l.languageCode
      : '${l.languageCode}_${l.countryCode}';

  String _pretty(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
      ? l.languageCode.toUpperCase()
      : '${l.languageCode.toUpperCase()} (${l.countryCode})';

  bool _equalsLangRegion(Locale a, Locale b) {
    if (a.languageCode != b.languageCode) return false;
    final ac = a.countryCode ?? '';
    final bc = b.countryCode ?? '';
    return ac == bc;
  }
}
