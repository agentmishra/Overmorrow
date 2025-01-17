/*
Copyright (C) <2023>  <Balint Maroti>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:latlong2/latlong.dart';

import 'decoders/decode_wapi.dart';


class RadarMap extends StatefulWidget {

  final data;
  RadarMap(this.data);

  @override
  _RadarMapState createState() => _RadarMapState(data);
}

class _RadarMapState extends State<RadarMap> {
  int currentFrameIndex = 0;
  late Timer timer;

  final data;
  _RadarMapState(this.data);
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Set up a timer to update the radar frame every 5 seconds
    timer = Timer.periodic(const Duration(milliseconds: 1300), (Timer t) {
      if (isPlaying) {
        setState(() {
          // Increment the frame index (you may want to add logic to handle the end of the frames)
          currentFrameIndex =
              ((currentFrameIndex + 1) % data.current.radar.length).toInt();
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the timer when the widget is disposed
    timer.cancel();
    super.dispose();
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color main = data.current.contentColor[0] == WHITE? data.current.backcolor : WHITE;
    Color top = data.current.contentColor[0] == WHITE? WHITE : data.current.backcolor;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, bottom: 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(translation('radar', data.settings[0]), 20, color: WHITE),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                  color: WHITE,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(width: 1, color: WHITE)
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    //child: data.current.radar[0]
                    child: FlutterMap(
                      options: MapOptions(
                        onTap: (tapPosition, point) => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RadarPage(data: data,)),
                          )
                        },
                        initialCenter: LatLng(data.current.lat, data.current.lng),
                        initialZoom: 6,
                        backgroundColor: WHITE,
                        keepAlive: true,
                        maxZoom: 6,
                        minZoom: 6,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation),
                        cameraConstraint: CameraConstraint.containCenter(
                          bounds: LatLngBounds(
                            LatLng(data.current.lat - 3, data.current.lng - 3),
                            LatLng(data.current.lat + 3, data.current.lng + 3),
                          ),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: data.current.contentColor[0] == WHITE
                              ? 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
                        ),
                        TileLayer(
                          urlTemplate: data.current.radar[currentFrameIndex] + "/512/{z}/{x}/{y}/8/1_1.png",
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Hero(
                        tag: 'switch',
                        child: SizedBox(
                          height: 48,
                          width: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 10,
                              padding: const EdgeInsets.all(10),
                              backgroundColor: top,
                              //side: BorderSide(width: 3, color: main),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RadarPage(data: data,)),
                              );
                            },
                            child: Icon(Icons.open_in_full, color: main, size: 25,),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child,);
                },
                child: Hero(
                  tag: 'playpause',
                  key: ValueKey<bool> (isPlaying),
                  child: SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(10),
                          backgroundColor: WHITE,
                          side: const BorderSide(width: 1.2, color: WHITE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)
                          )
                      ),
                      onPressed: () async {
                        togglePlayPause();
                      },
                      child: Icon(isPlaying? Icons.pause : Icons.play_arrow, color: data.current.backcolor, size: 18,),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Hero(
                    tag: 'progress',
                    child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Container(
                            height: 50,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(width: 1.2, color: WHITE)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                children: [
                                  Container(
                                    color: WHITE,
                                    width: constraints.maxWidth *
                                        (max(currentFrameIndex - 1, 0) / data.current.radar.length),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) =>
                                        SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                                    child: Container(
                                      key: ValueKey<int>(currentFrameIndex),
                                      color: WHITE,
                                      width: constraints.maxWidth *
                                          (currentFrameIndex / data.current.radar.length),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

class RadarPage extends StatefulWidget {
  final data;

  const RadarPage({Key? key, this.data}) : super(key: key);

  @override
  _RadarPageState createState() => _RadarPageState(data: data);
}

class _RadarPageState extends State<RadarPage> {
  final data;

  _RadarPageState({this.data});

  int currentFrameIndex = 0;
  late Timer timer;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Set up a timer to update the radar frame every 5 seconds
    timer = Timer.periodic(const Duration(milliseconds: 1300), (Timer t) {
      if (isPlaying) {
        setState(() {
          // Increment the frame index (you may want to add logic to handle the end of the frames)
          currentFrameIndex =
              ((currentFrameIndex + 1) % data.current.radar.length).toInt();
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the timer when the widget is disposed
    timer.cancel();
    super.dispose();
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double x = MediaQuery.of(context).padding.top;
    Color main = data.current.contentColor[0] == WHITE? data.current.backcolor : WHITE;
    Color top = data.current.contentColor[0] == WHITE? WHITE : data.current.backcolor;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(data.current.lat, data.current.lng),
            initialZoom: 5,
            backgroundColor: WHITE,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate,),
          ),
          children: [
            TileLayer(
              urlTemplate: data.current.contentColor[0] == WHITE
                  ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
            ),
            TileLayer(
              urlTemplate: data.current.radar[currentFrameIndex] + "/512/{z}/{x}/{y}/8/1_1.png",
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 30, right: 15),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              elevation: 10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: top,
                ),
                padding: EdgeInsets.all(6),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child,);
                      },
                      child: Hero(
                        key: ValueKey<bool> (isPlaying),
                        tag: 'playpause',
                        child: SizedBox(
                          height: 48,
                          width: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 8,
                                padding: const EdgeInsets.all(10),
                                backgroundColor: top,
                                //side: const BorderSide(width: 5, color: WHITE),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)
                                ),
                            ),
                            onPressed: () async {
                              togglePlayPause();
                            },
                            child: Icon(isPlaying? Icons.pause : Icons.play_arrow, color: main, size: 18,),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Hero(
                          tag: 'progress',
                          child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                return Material(
                                  borderRadius: BorderRadius.circular(13),
                                  elevation: 8,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Container(
                                      height: 48,
                                      color: top,
                                      child: Stack(
                                        children: [
                                          Container(
                                            color: main,
                                            width: constraints.maxWidth *
                                                (max(currentFrameIndex - 1, 0) / data.current.radar.length),
                                          ),
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 300),
                                            transitionBuilder: (Widget child, Animation<double> animation) =>
                                                SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                                            child: Container(
                                              key: ValueKey<int>(currentFrameIndex),
                                              color: main,
                                              width: constraints.maxWidth *
                                                  (currentFrameIndex / data.current.radar.length),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 15, top: x + 15),
          child: Align(
            alignment: Alignment.topRight,
            child:  Hero(
              tag: 'switch',
              child: SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    padding: const EdgeInsets.all(10),
                    backgroundColor: top,
                    //side: BorderSide(width: 3, color: main),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(Icons.close_fullscreen, color: main, size: 25,),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
