import 'package:html/dom.dart' as doom;
import 'package:html/parser.dart';
import 'package:http/http.dart';

import 'event.dart';
import 'details.dart';

class ScrapeBloc {
  Future getDocument(url) async {
    var client = Client();
    Response response = await client.get(url);
    return parse(response.body);
  }

  // https://regex101.com/r/lFCDTj/2
  Future<Details> scrapeEvent(String eventUrl) async {
    var document = await getDocument(eventUrl);
    var details = document.querySelector('table.Grid > tbody > tr > td').text;

    print(details);

    return Details(
        description: RegExp(r'Added by:.+\s*(.+)\s*Salseros')
            .firstMatch(details)
            ?.group(1),
        address: RegExp(r'Address: (.+)').firstMatch(details)?.group(1),
        entrance: RegExp(r'Entrance €: (.+)').firstMatch(details)?.group(1),
        doors: RegExp(r'Doors: (.+)').firstMatch(details)?.group(1),
        dj: RegExp(r'Dj\(s\): (.+)').firstMatch(details)?.group(1),
        end: RegExp(r'End of party at : (.+)').firstMatch(details)?.group(1));
  }

  Future<List<Event>> scrape(int pageType) async {
    List<Event> events = [];

    // GET DOCUMENT
    String url;
    if (pageType == ScreenType.week.index)
      url = 'http://www.salsa.be/vcalendar/week.php';
    if (pageType == ScreenType.today.index)
      url = 'http://www.salsa.be/vcalendar/day.php';
    var document = await getDocument(url);

    // GET ELEMENTS
    List<doom.Element> eventRows =
        document.querySelectorAll('table.Grid > tbody > tr');
    var date = "";

    // PARSE ELEMENTS
    for (var eventRow in eventRows) {
      if (eventRow.attributes['class'] == 'GroupCaption') {
        // DATE
        date = eventRow.text.trim();
      } else {
        // HOUR
        var hourElement = eventRow.querySelector('th');
        if (hourElement == null) continue; // Empty row
        var hour = hourElement.text.trim();

        // LINK
        var link = eventRow.querySelector('td a').attributes['href'];

        // DESCRIPTION
        var description =
            eventRow.querySelector('td').text.replaceAll(RegExp(r'\s+'), " ");
        description = description.trim();

        // REGEX ALL
        RegExp re = new RegExp(r'(.+?) - (?:(.+?) - )?(.+?)(?: \(([^()]+)\))?$',
            caseSensitive: false, multiLine: true);
        var match = re.firstMatch(description);
        if (match != null) print('|${match.group(0)}|');

        // REGEX CITY
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
            hour: hour != "" ? hour : "N/A",
            link: 'http://www.salsa.be/vcalendar/$link');

        events.add(event);
      }
    }

    return events;
  }
}

final scrapeBloc = ScrapeBloc();

enum ScreenType {
  today,
  week,
}
