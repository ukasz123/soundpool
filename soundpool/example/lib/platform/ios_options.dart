import 'package:flutter/material.dart';
import 'package:soundpool/soundpool.dart';

class IosOptionsSelector extends StatefulWidget {
  const IosOptionsSelector({Key? key}) : super(key: key);

  @override
  _IosOptionsSelectorState createState() => _IosOptionsSelectorState();
}

class _IosOptionsSelectorState extends State<IosOptionsSelector> {
  AudioSessionCategory? _category;
  AudioSessionMode _mode = AudioSessionMode.normal;
  bool _enableRate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select options for Apple devices'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CheckboxListTile(
              value: _enableRate,
              onChanged: (enable) => setState(() {
                _enableRate = enable ?? false;
              }),
              title: Text('Enable rate'),
            ),
            Divider(),
            Text('Audio System Category'),
            DropdownButton<AudioSessionCategory>(
              items: AudioSessionCategory.values
                  .map((e) => DropdownMenuItem<AudioSessionCategory>(
                        value: e,
                        child: Text(
                          e.toString(),
                        ),
                      ))
                  .toList(),
              value: _category,
              onChanged: (category) => setState(
                () {
                  _category = category;
                },
              ),
              selectedItemBuilder: (context) => AudioSessionCategory.values
                  .map(
                    (e) => Text(
                      e.toString().split('.').last,
                    ),
                  )
                  .toList(),
            ),
            Text('Audio System Mode'),
            DropdownButton<AudioSessionMode>(
              items: AudioSessionMode.values
                  .map((e) => DropdownMenuItem<AudioSessionMode>(
                        value: e,
                        child: Text(
                          e.toString(),
                        ),
                      ))
                  .toList(),
              onChanged: (mode) => setState(
                () {
                  _mode = mode!;
                },
              ),
              value: _mode,
              selectedItemBuilder: (context) => AudioSessionMode.values
                  .map(
                    (e) => Text(
                      e.toString().split('.').last,
                    ),
                  )
                  .toList(),
            ),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                child: Text('Confirm'),
                onPressed: _onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirm() {
    if (_category != null) {
      Navigator.of(context).pop(SoundpoolOptions(
        iosOptions: SoundpoolOptionsIos(
          enableRate: _enableRate,
          audioSessionCategory: _category,
          audioSessionMode: _mode,
        ),
      ));
    } else {
      Navigator.of(context).pop(SoundpoolOptions(
        iosOptions: SoundpoolOptionsIos(
          enableRate: _enableRate,
        ),
      ));
    }
  }
}
