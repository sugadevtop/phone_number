import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_number/phone_number.dart';
import 'package:phone_number_example/models/parse_result.dart';
import 'package:phone_number_example/models/region.dart';
import 'package:phone_number_example/region_picker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final regionCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final key = GlobalKey<FormState>();

  final plugin = PhoneNumber();

  List<Region> regions;
  Region selectedRegion;
  ParseResult result;
  bool ignoreType = false;

  Future<void> parse() async {
    setState(() => result = null);
    if (key.currentState.validate()) {
      dismissKeyboard();
      try {
        final parsed = await plugin.parse(
          numberCtrl.text,
          region: selectedRegion?.code,
          ignoreType: ignoreType,
        );
        result = ParseResult(parsed);
      } catch (e) {
        result = ParseResult.error(e.code);
      }

      setState(() {});
    }
  }

  void format() async {
    if (key.currentState.validate()) {
      dismissKeyboard();
      try {
        final formatted = await plugin.format(
          numberCtrl.text,
          selectedRegion.code,
        );
        numberCtrl.text = formatted;
      } on PlatformException catch (e) {
        numberCtrl.text = e.code;
      }
      setState(() {});
    }
  }

  void reset() {
    key.currentState.reset();
    regionCtrl.text = '';
    numberCtrl.text = '';
    selectedRegion = null;
    result = null;
    setState(() {});
  }

  void chooseRegions() async {
    dismissKeyboard();
    final regions = await getRegions();
    await showModalBottomSheet<Region>(
      context: context,
      builder: (context) => RegionPicker(
        regions: regions,
        onSelectedRegion: (r) {
          regionCtrl.text = "${r.code} (+${r.prefix})";
          setState(() => selectedRegion = r);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<List<Region>> getRegions() async {
    if (regions == null) {
      final data = await plugin.allSupportedRegions();

      // Filter out regions with more than 2 characters
      regions = data.entries
          .where((e) => e.key.length <= 2)
          .map((e) => Region(e.key, e.value))
          .toList();

      regions.sort();
    }
    return regions;
  }

  void dismissKeyboard() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissKeyboard,
      child: Scaffold(
        appBar: AppBar(title: Text('Phone Number')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Form(
            key: key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: numberCtrl,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    helperText: '',
                  ),
                ),
                InkWell(
                  onTap: chooseRegions,
                  child: IgnorePointer(
                    child: TextFormField(
                      controller: regionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Region',
                        helperText: '',
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setState(() => ignoreType = v),
                      value: ignoreType,
                      tristate: false,
                    ),
                    Text('Ignore type when parsing')
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        child: Text('Format'),
                        onPressed: selectedRegion == null ? null : format,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: RaisedButton(
                        child: Text('Parse'),
                        onPressed: parse,
                      ),
                    ),
                  ],
                ),
                OutlineButton(
                  child: Text('Reset'),
                  onPressed: reset,
                ),
                SizedBox(height: 20),
                if (result != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Result(result: result),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Result extends StatelessWidget {
  final ParseResult result;

  const Result({Key key, this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Result:", style: theme.textTheme.title),
        SizedBox(height: 10),
        ...(result.hasError)
            ? [
                Text(
                  'Error! (code: ${result.errorCode})',
                  style: theme.textTheme.body2.copyWith(color: Colors.red),
                ),
              ]
            : [
                _ResultRow(name: 'Type', value: result.type),
                _ResultRow(name: 'E164', value: result.e164),
                _ResultRow(name: 'International', value: result.international),
                _ResultRow(name: 'National', value: result.national),
                _ResultRow(
                    name: 'Country code', value: result.countryCode.toString()),
              ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String name;
  final String value;

  const _ResultRow({Key key, this.name, this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text('$name', style: theme.textTheme.body1)),
          Flexible(child: Text(value, style: theme.textTheme.body2)),
        ],
      ),
    );
  }
}
