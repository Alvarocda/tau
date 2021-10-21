/*
 * Copyright 2021 Canardoux.
 *
 * This file is part of the τ Sound project.
 *
 * τ Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Public License version 3 (GPL3.0),
 * as published by the Free Software Foundation.
 *
 * τ Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the GNU Public
 * License, v. 3.0. If a copy of the GPL was not distributed with this
 * file, You can obtain one at https://www.gnu.org/licenses/.
 */

import 'package:flutter/material.dart';
import 'package:tau_sound/tau_sound.dart';

///
///
/// {@category UI_Widgets}
class TauPlayerUI extends StatefulWidget {
  final TauPlayer player;
  final List<double>? speeds;
  final Duration? duration;
  final double? iconSize;
  final Color? playPauseColor;
  final bool alwaysShowPlayerSpeed;
  final SliderThemeData? sliderThemeData;
  final Future<void> Function()? onSpeedChanged;
  final Future<void> Function(TauPlayer tauPlayer) onTap;

  ///
  ///
  ///
  const TauPlayerUI({
    required this.player,
    required this.onTap,
    this.onSpeedChanged,
    this.iconSize = 45,
    this.playPauseColor,
    this.alwaysShowPlayerSpeed = false,
    this.speeds,
    this.duration,
    this.sliderThemeData,
    Key? key,
  }) : super(key: key);

  ///
  ///
  ///
  @override
  _TauPlayerUIState createState() => _TauPlayerUIState();
}

///
///
///
class _TauPlayerUIState extends State<TauPlayerUI>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Duration? _actualPlayerPosition;
  Duration? _audioDuration;
  double? _actualSpeed;
  int _speedIndex = 0;

  ///
  ///
  ///
  @override
  void initState() {
    super.initState();
    if (!widget.player.isOpen) {
      throw Exception('Player must be open before build TauPlayerUI');
    }

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    _audioDuration = widget.duration;
    widget.player.setSubscriptionDuration(Duration(milliseconds: 400));

    widget.player.onProgress!.listen((event) {
      setState(() {
        _actualPlayerPosition = event.position;
        _audioDuration ??= event.duration;
      });
    });
    if (widget.speeds != null && widget.speeds!.isNotEmpty) {
      _actualSpeed = widget.speeds![_speedIndex];
    }
  }

  ///
  ///
  ///
  @override
  void reassemble() {
    super.reassemble();
    widget.player.stop();
  }



  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          shape: CircleBorder(),
          child: InkWell(
            onTap: () async {
              await widget.onTap(widget.player);
              if (widget.player.isPaused || widget.player.isStopped) {
                await _animationController!.reverse();
              } else {
                await _animationController!.forward();
              }
              setState(() {

              });
            },
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _animationController!,
              size: widget.iconSize ?? 45,
              color: widget.playPauseColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Theme(
            data: ThemeData(
              sliderTheme: widget.sliderThemeData ??
                  SliderThemeData(
                    trackHeight: 18,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 0,
                      disabledThumbRadius: 0,
                      elevation: 25,
                    ),
                  ),
            ),
            child: Slider(
              value: _actualPlayerPosition == null
                  ? 0.0
                  : _actualPlayerPosition!.inMilliseconds.toDouble(),
              max: _audioDuration == null
                  ? 0
                  : _audioDuration!.inMilliseconds.toDouble(),

              onChanged: (double value) {
                widget.player.seekTo(
                  Duration(
                    milliseconds: value.toInt(),
                  ),
                );
              },
              onChangeEnd: (value) {
                setState(() {});
              },
            ),
          ),
        ),
        if (widget.speeds != null && widget.speeds!.isNotEmpty)
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: widget.alwaysShowPlayerSpeed
                ? 35
                : widget.player.isPlaying
                    ? 35
                    : 0,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            curve: Curves.easeIn,
            child: ElevatedButton(
              onPressed: () {
                _speedIndex++;
                if (_speedIndex == widget.speeds!.length) {
                  _speedIndex = 0;
                }
                _actualSpeed = widget.speeds![_speedIndex];
                widget.player.setSpeed(_actualSpeed!);
                if (widget.onSpeedChanged != null) {
                  widget.onSpeedChanged!();
                }
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: FittedBox(
                child: Text(
                  '${_actualSpeed}x',
                ),
              ),
            ),
          ),
        SizedBox(
          width: 10,
        ),
        if (_audioDuration != null)
          Text(
              '${_convertDurationToTime(_actualPlayerPosition)}/${_convertDurationToTime(_audioDuration)}')
        else
          Text(_convertDurationToTime(_actualPlayerPosition))
      ],
    );
  }

  ///
  ///
  ///
  String _convertDurationToTime(Duration? duration) {
    if (duration == null) {
      return '00:00';
    }
    var minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    var seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
