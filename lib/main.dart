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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
    // scrape();
    super.initState();
  }

  Future<List<Map<String, String>>> scrape() async {
    List<Map<String, String>> events = [];

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
        var time = hourElement.text.trim();
        var description =
            eventRow.querySelector('td').text.replaceAll(RegExp(r'\s+'), " ");
        print(description);

        events.add({'date': date, 'time': time, 'description': description});
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
        child: FutureBuilder<List<Map<String, String>>>(
          future: scrape(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) return Container();
            List<Map<String, String>> events = snapshot.data;
            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  var event = events[index];
                  return Card(
                      child: ListTile(
                    leading: Text(event['time']),
                    title: Text(event['description']),
                  ));
                });
          },
        ),
      ),
    );
  }
}
