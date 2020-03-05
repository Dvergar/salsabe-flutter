import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as doom;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Salsa.be'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

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
        print(description);

        RegExp re = new RegExp(r'(.+?) - (?:(.+?) - )?(.+?)(?:\(([^()]+)\))?$',
            caseSensitive: false, multiLine: true);
        var match = re.firstMatch(description);
        print(re.hasMatch(description));
        if(match != null)
          print(match.group(0));

        var event = Event(
            name: match.group(1),
            place: match.group(2) ?? "",
            address: match.group(3),
            suffix: match.group(4),
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
      body: Center(
        child: FutureBuilder<List<Event>>(
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
                      hasNewDate ? Text(date) : Container(),
                      Card(
                          child: ListTile(
                        leading: Text(event.hour),
                        title: Text(event.name),
                        subtitle: Text(event.place),
                      )),
                    ],
                  );
                });
          },
        ),
      ),
    );
  }
}

class Event {
  String name;
  String place;
  String address;
  String suffix;
  String date;
  String hour;

  Event(
      {this.name,
      this.place,
      this.address,
      this.suffix,
      this.date,
      this.hour});
}
