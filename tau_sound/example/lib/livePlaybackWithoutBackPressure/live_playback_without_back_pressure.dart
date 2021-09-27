/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0), as published by
 * the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tau_sound_lite/tau_sound.dart';
import 'package:flutter/services.dart' show rootBundle;

/*
 *
 * A very simple example showing how to play Live Data without back pressure.
 * A very simple example showing how to play Live Data without back pressure.
 * It feeds a live stream, without waiting that the Futures are completed for each block.
 * This is simpler because the App does not need to await the playback for each block before playing another one.
 *
 *
 * This example get the data from an asset file, which is completely stupid :
 * if an App wants to play an asset file he must use "StartPlayerFromBuffer().
 *
 * Feeding Flutter Sound without back pressure is very simple but you can have two problems :
 * - If your App is too fast feeding the audio channel, it can have problems with the Stream memory used.
 * - The App does not have any knowledge of when the provided block is really played.
 * If he does a "stopPlayer()" it will loose all the buffered data.
 *
 * This example uses the ```foodEvent``` object to resynchronize the output stream before doing a ```stop()```
 *
 */

///
const int tSampleRate = 44100;

///
const int tBlockSize = 4096;

///
typedef Fn = void Function();

/// Example app.
class LivePlaybackWithoutBackPressure extends StatefulWidget {
  @override
  _LivePlaybackWithoutBackPressureState createState() =>
      _LivePlaybackWithoutBackPressureState();
}

class _LivePlaybackWithoutBackPressureState
    extends State<LivePlaybackWithoutBackPressure> {
  TauPlayer? _mPlayer = TauPlayer();
  bool _mPlayerIsInited = false;
  StreamController<TauFood> totoController = StreamController<TauFood>();

  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your TauPlayer or TauRecorder before the completion of the Future
    _mPlayer!.open().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer!.close();
    _mPlayer = null;

    super.dispose();
  }

  // -------  Here is the code to play Live data with back-pressure ------------

  void feedHim(Uint8List data) {
    var start = 0;
    var totalLength = data.length;
    while (totalLength > 0 && _mPlayer != null && !_mPlayer!.isStopped) {
      var ln = totalLength > tBlockSize ? tBlockSize : totalLength;
      totoController.sink.add(TauFoodData(data.sublist(start, start + ln)));
      totalLength -= ln;
      start += ln;
    }
  }

  void play() async {
    assert(_mPlayerIsInited && _mPlayer!.isStopped);
    totoController = StreamController<TauFood>();
    InputNode input = InputStream(totoController.stream,
        codec: Pcm(
          AudioFormat.raw,
          depth: Depth.int16,
          endianness: Endianness.littleEndian,
          nbChannels: NbChannels.mono,
          sampleRate: tSampleRate,
        ));
    await _mPlayer!.play(
      from: input,
      to: DefaultOutputDevice(),
    );
    setState(() {});
    var data = await getAssetData('assets/samples/sample.pcm');
    feedHim(data);
    if (_mPlayer != null) {
      // We must not do stopPlayer() directely //await stopPlayer();
      totoController.sink.add(TauFoodEvent(() async {
        await _mPlayer!.stop();
        setState(() {});
      }));
    }
  }

  // --------------------- (it was very simple, wasn't it ?) -------------------

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stop();
    }
  }

  Fn? getPlaybackFn() {
    if (!_mPlayerIsInited) {
      return null;
    }
    return _mPlayer!.isStopped
        ? play
        : () {
            stopPlayer().then((value) => setState(() {}));
          };
  }

  // ----------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getPlaybackFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
              ),
              SizedBox(
                width: 20,
              ),
              Text(_mPlayer!.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ]),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Live playback without back pressure'),
      ),
      body: makeBody(),
    );
  }
}
