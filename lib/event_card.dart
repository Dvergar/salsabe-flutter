import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = !selected;
          });
        },
        child: AnimatedContainer(
          height: selected ? 200 : 100,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(widget.event.name,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25)),
                            Text(widget.event.hour,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))
                          ],
                        ),
                        Text('at ${widget.event.place}',
                            style:
                                TextStyle(color: Colors.white, fontSize: 15)),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(Icons.place, color: Colors.white),
                                  Text(widget.event.city,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15))
                                ])),
                      ])),
            ],
          ),
        ),
      ),
    );
  }
}
