import 'package:flutter/material.dart';
import 'package:salsabe/scrape_bloc.dart';
import 'package:transparent_image/transparent_image.dart';

import 'event.dart';
import 'details.dart';
import 'foursquare_bloc.dart';
import 'main.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final FoursquareKey foursquareKey;

  EventCard({Key key, this.event, this.foursquareKey}) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  var selected = false;
  Details details = Details();
  bool detailsFetched = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.0),
      child: GestureDetector(
        onTap: () {
          if (!detailsFetched) {
            scrapeBloc.scrapeEvent(widget.event.link).then((details) {
              this.details = details;
              this.detailsFetched = true;
              setState(() {
                selected = true;
              });
            });
            return;
          }

          setState(() {
            selected = !selected;
          });
        },
        child: AnimatedContainer(
          height: selected ? 200 : 150,
          duration: Duration(seconds: 2),
          curve: Curves.fastOutSlowIn,
          child: Stack(
            children: <Widget>[
              ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.darken),
                  child: FutureBuilder(
                    future: foursquareBloc.getDummyPhoto(
                        place: widget.event.place,
                        city: widget.event.city,
                        foursquareKey: widget.foursquareKey),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      print("----${snapshot.data}");
                      if (!snapshot.hasData) return Container();
                      return FadeInImage.memoryNetwork(
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: kTransparentImage,
                        image: snapshot.data,
                      );
                    },
                  )),
              Container(
                  padding: EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            // EVENT NAME
                            Text(widget.event.name,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25)),
                            // HOURS
                            Text(widget.event.hour,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))
                          ],
                        ),
                        Wrap(
                          children: <Widget>[
                            Text('at ${widget.event.place}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15)),
                            AnimatedOpacity(
                              opacity: selected ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 500),
                              child: Wrap(
                                children: <Widget>[
                                  Text('- ${widget.event.shortAddress}',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15)),
                                ],
                              ),
                            )
                          ],
                        ),
                        Spacer(),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 500),
                          firstChild: Text(details.description??'',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20)),
                          secondChild: Container(),
                          crossFadeState: selected
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                        ),
                        // AnimatedOpacity(
                        //     opacity: selected ? 1.0 : 0.0,
                        //     duration: Duration(milliseconds: 500),
                        //     child: Text(details.description ?? '',
                        //         style: TextStyle(
                        //             color: Colors.white, fontSize: 25))),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            AnimatedOpacity(
                              opacity: selected ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 500),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.music_note, color: Colors.white),
                                  Text(' DJ ${details.dj}',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            Wrap(
                                // alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(Icons.place, color: Colors.white),
                                  Text(widget.event.city,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15))
                                ]),
                          ],
                        ),
                      ])),
            ],
          ),
        ),
      ),
    );
  }
}
