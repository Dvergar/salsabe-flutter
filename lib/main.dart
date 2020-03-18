import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'event.dart';
import 'event_card.dart';
import 'scrape_bloc.dart';

void main() => runApp(MyApp());

class FoursquareKey {
  String clientId;
  String clientSecret;
  FoursquareKey({this.clientId, this.clientSecret});
}

class MyApp extends StatelessWidget {
  Future<FoursquareKey> getKey() async {
    var keyString = await rootBundle.loadString("assets/key.txt");

    var splitKey = keyString.split(" ");
    return FoursquareKey(clientId: splitKey[0], clientSecret: splitKey[1]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getKey(),
        builder: (BuildContext context, AsyncSnapshot<FoursquareKey> snapshot) {
          return snapshot.data == null
              ? Center(child: CircularProgressIndicator())
              : MaterialApp(
                  title: 'Flutter Demo',
                  theme: ThemeData(
                    primarySwatch: Colors.blue,
                  ),
                  home: MyHomePage(
                      title: 'Salsa.be', foursquareKey: snapshot.data),
                );
        });
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.foursquareKey}) : super(key: key);

  final String title;
  final FoursquareKey foursquareKey;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selected = false;
  var currentPage = 0;

  beautifyDate(String input) {
    var splitDate = input.split("/");
    var day = splitDate[0].padLeft(2, '0');
    var month = splitDate[1].padLeft(2, '0');
    var year = splitDate[2];

    var parsedDate = DateTime.parse('$year-$month-$day');
    var output = DateFormat.yMMMMd("en_US").format(parsedDate);

    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/icon.png"),
        ),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.black),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Event>>(
        future: scrapeBloc.scrape(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) return Container();
          List<Event> events = snapshot.data;
          var date = "";
          return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                var event = events[index];
                var hasNewDate = false;
                if (date != event.date) {
                  date = event.date;
                  hasNewDate = true;
                }

                return Column(
                  children: <Widget>[
                    hasNewDate
                        ? Text(beautifyDate(date),
                            style: TextStyle(fontSize: 18))
                        : Container(),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: EventCard(
                            event: event, foursquareKey: widget.foursquareKey)),
                  ],
                );
              });
        },
      ),
      bottomNavigationBar: FancyBottomNavigation(
        tabs: [
          TabData(iconData: Icons.today, title: "Today"),
          TabData(iconData: Icons.view_week, title: "Week"),
        ],
        onTabChangedListener: (position) {
          setState(() {
            currentPage = position;
          });
        },
      ),
    );
  }
}
