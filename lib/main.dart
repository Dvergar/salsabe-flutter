import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as doom;
import 'package:salsabe/foursquare_bloc.dart';
import 'package:transparent_image/transparent_image.dart';

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
  Future<List<Event>> scrape() async {
    List<Event> events = [];

    var client = Client();
    Response response =
        await client.get('http://www.salsa.be/vcalendar/week.php');
    // Use html parser
    var document = parse(response.body);
    // print(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                    hasNewDate ? Text(date, style: TextStyle(
                                                    fontSize: 18)) : Container(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.0),
                        child: Container(
                          height: 100,
                          child: Stack(
                            children: <Widget>[
                              ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                      Colors.grey, BlendMode.darken),
                                  child: FutureBuilder(
                                    future: foursquareBloc.getDummyPhoto(
                                        place: event.place,
                                        city: event.city,
                                        foursquareKey: widget.foursquareKey),
                                    builder: (BuildContext context,
                                        AsyncSnapshot snapshot) {
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                  
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text(event.name,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 25)),
                                                    Text(event.hour, style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20))
                                          ],
                                        ),
                                        Text('at ${event.place}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15)),
                                        Align(
                                            alignment: Alignment.centerRight,
                                            child: Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  Icon(Icons.place,
                                                      color: Colors.white),
                                                  Text(event.city,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15))
                                                ])),
                                      ])),
                            ],
                          ),
                        ),
                      ),
                    ),
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
