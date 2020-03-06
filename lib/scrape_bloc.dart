import 'package:html/dom.dart' as doom;
import 'package:html/parser.dart';
import 'package:http/http.dart';

import 'event.dart';

class ScrapeBloc {

  Future getDocument(url) async
  {
  var client = Client();
    Response response =
        await client.get(url);
    return parse(response.body);
  }

  Future<List<Event>> scrape() async {
    List<Event> events = [];

    var document = await getDocument('http://www.salsa.be/vcalendar/week.php');
  
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
        var link = eventRow.querySelector('td a').attributes['href'];
        print('Link $link');
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

        print("--------------");

        var event = Event(
            name: match.group(1),
            place: match.group(2) ?? "",
            address: match.group(3),
            city: cityMatch.group(1),
            suffix: match.group(4) ?? "N/A",
            date: date,
            hour: hour,
            link: 'http://www.salsa.be/vcalendar/$link');

        events.add(event);
      }
    }

    return events;
  }
}

final scrapeBloc = ScrapeBloc();
