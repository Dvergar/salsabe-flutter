import 'dart:async';

import 'dart:convert';

import 'main.dart';

import 'package:http/http.dart';

class FoursquareBloc {

  Future getDummyPhoto({String place, String city, FoursquareKey foursquareKey}) async {
    // return "https://i.picsum.photos/id/15/400/200.jpg?blur=10";
    return "https://loremflickr.com/400/200/salsa,dance/all?lock=${place.hashCode}";
  }

  Future<String> getPhoto(
      {String place, String city, FoursquareKey foursquareKey}) async {

    var photo = "https://via.placeholder.com/468x60?text=Visit+Blogging.com+Now";
    var venueId = await getVenueId(place, city, foursquareKey);
    print('venueid $venueId');
    if (venueId != null) photo = await getPhotoUrl(venueId, foursquareKey);
    print('@@@@ PHOTO $place/$city - $photo');
    return photo;
  }

  Future<String> getPhotoUrl(venueId, foursquareKey) async {
    print("|$venueId|");
    var photoUrl =
        "";
    var photosJson = await getJson(
        'https://api.foursquare.com/v2/venues/$venueId/photos?client_id=${foursquareKey.clientId}&client_secret=${foursquareKey.clientSecret}&v=20200303');

    // Please refactor :3
    if (photosJson.containsKey('response') &&
        photosJson['response'].containsKey('photos') &&
        photosJson['response']['photos'].containsKey('items')) {
          print("yep");
      var photos = photosJson['response']['photos']['items'];
      if (photos.length != 0) {
        print("suffix : ${photos[0]['suffix']}");
        var imageName = photos[0]['suffix'];
        photoUrl = 'https://igx.4sqi.net/img/general/300x100$imageName';
      }
    }

    return photoUrl;
  }

  Future<String> getVenueId(place, city, foursquareKey) async {
    var venueJson = await getJson(
        'https://api.foursquare.com/v2/venues/search?near=$city&query=$place&limit=1&client_id=${foursquareKey.clientId}&client_secret=${foursquareKey.clientSecret}&v=20200303');
    var venueId;

    print("name $place $city");
    if (venueJson.containsKey('response') &&
        venueJson['response'].containsKey('venues')) {
      var venues = venueJson['response']['venues'];
      if (venues.length != 0) {
        print('$place - ${venues[0]['id']}');
        venueId = venues[0]['id'];
      }
    }

    return venueId;
  }

  Future<dynamic> getJson(String link) async {
    // var res = await http.get(Uri.encodeFull(link),
    //     headers: {"Accept": "application/json"});
    // if (res.statusCode == 200) {
    //   return json.decode(res.body);
    // }
    // return Future.error("NO RESULT");
    var client = Client();
    Response response = await client.get(link);
    return json.decode(response.body);
  }
}

final foursquareBloc = FoursquareBloc();
