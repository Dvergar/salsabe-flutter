import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as doom;
import 'package:intl/intl.dart';

import 'event_card.dart';

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

  Future<List<Event>> scrape() async {
    List<Event> events = [];

    var client = Client();
    Response response =
        await client.get('http://www.salsa.be/vcalendar/week.php');
    var document = parse(response.body);
    List<doom.Element> eventRows =
        document.querySelectorAll('table.Grid > tbody > tr');
    var date = "";
    
    for (var eventRow in eventRows) {
      if (eventRow.attributes['class'] == 'GroupCaption') {
        date = eventRow.text.trim();
      } else {
        var hourElement = eventRow.querySelector('th');
        if (hourElement == null) continue; // Empty row
        var hour = hourElement.text.trim();
        var description =
            eventRow.querySelector('td').text.replaceAll(RegExp(r'\s+'), " ");
        description = description.trim();

        RegExp re = new RegExp(r'(.+?) - (?:(.+?) - )?(.+?)(?: \(([^()]+)\))?$',
            caseSensitive: false, multiLine: true);
        var match = re.firstMatch(description);
        if (match != null) print('|${match.group(0)}|');

        RegExp reCity = new RegExp(r'^.+?\d+ (.+?)(?: \([^()]+\))?$',
            caseSensitive: false, multiLine: true);
        var cityMatch = reCity.firstMatch(match.group(3));
        // print(match.group(1));
        // print(match.group(2));
        // print(match.group(3));
        // print(match.group(4));
        // print(cityMatch.group(1));
        print("--------------");

        var event = Event(
            name: match.group(1),
            place: match.group(2) ?? "",
            address: match.group(3),
            city: cityMatch.group(1),
            suffix: match.group(4) ?? "N/A",
            date: date,
            hour: hour);

        events.add(event);
      }
    }

    return events;
  }

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
        future: scrape(),
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
    );
  }
}

class Event {
  String name;
  String place;
  String address;
  String city;
  String suffix;
  String date;
  String hour;

  Event(
      {this.name,
      this.place,
      this.address,
      this.city,
      this.suffix,
      this.date,
      this.hour});
}
