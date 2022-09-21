
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/Assistants/requestAssistant.dart';
import 'package:rider_app/DataHandler/appData.dart';
import 'package:rider_app/Models/address.dart';
import 'package:rider_app/Models/allServices.dart';
import 'package:rider_app/Models/allUsers.dart';
import 'package:rider_app/Models/directionDetails.dart';
import 'package:rider_app/Models/userRequests.dart';
import 'package:rider_app/configMaps.dart';

class AssistantMethods
{
  static Future<String> searchCoordinateAddress(Position position, context) async
  {
    String placeAddress = "";
    String st1, st2, st3, st4;
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    //String url = "http://api.positionstack.com/v1/reverse?access_key=3ab30a2f2cfba83e8ba75e2e6bb027cf&query=40.7638435,-73.9729691";
    
    var response = await RequestAssistant.getRequest(url);

    if(response != "failed")
    {
      placeAddress = response["results"][0]["formatted_address"];
      //st1 = response["results"][0]["address_components"][3]["long_name"];
      //st2 = response["results"][0]["address_components"][5]["long_name"];
      Address userCurrentAddress = new Address();

      userCurrentAddress.longitude = position.longitude;
      userCurrentAddress.latitude = position.latitude;
      userCurrentAddress.placeName = placeAddress;
      userCurrentAddress.placeFormattedAddress = placeAddress;

      Provider.of<AppData>(context, listen: false).updateUserCurrentLocationAddress(userCurrentAddress);      //st3 = response["results"][0]["address_components"][6]["long_name"];
      //st4 = response["results"][0]["address_components"][7]["long_name"];

      //placeAddress = st1 + ", " + st2 + ", " + st3 + ", " + st4;
      

    }
    else{
      placeAddress = "No data yet";
    }

    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetails(LatLng initialPosition, LatLng finalPosition) async
  {
    String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if(res == "failed")
    {
      return res;
    }else{
      DirectionDetails directionDetails = DirectionDetails();
      directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"];
      directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"];
      directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"];
      directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"];
      directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"];
      return directionDetails;
    }
  }

  static int calculateFares(DirectionDetails directionDetails)
  {
    double timeTraveledFare = (directionDetails.durationValue! / 60) * 0.20;
    double distanceTraveledFare = (directionDetails.distanceValue! / 1000) * 0.20;
    double totalFareAmount = timeTraveledFare + distanceTraveledFare;

    double totalLocalAmount = totalFareAmount * 100;

    return totalLocalAmount.truncate();
  }

  static Future<void> getCurrentOnlineUserInfo() async
  {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid;
    DatabaseReference reference = FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapShot)
    {
      if(dataSnapShot.value != null)
      {
        userCurrentInfo = Users.fromSnapshot(dataSnapShot);
      }
    });
  }

  static Future<String> getUserAccountType() async
  {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid;
    final dbRef = FirebaseDatabase.instance.reference().child("users").child(userId).child("account_type");
    final snapshot = await dbRef.once();
    String userType = snapshot.value.toString();
    return userType;
  }

  static Future<String> checkRequestService() async
  {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid;
    final dbRef = FirebaseDatabase.instance.reference().child("Tow Requests")
        .orderByChild('rider_id').equalTo(userId);
    final snapshot = await dbRef.once();
    String ridername = snapshot.value["rider_name"].toString();
    return ridername;
  }

  static Future<void> getAllUserRequest(String driver_id, context) async
  {
    print("Data Ready : " + "getting requests" + driver_id);
    final Query query = FirebaseDatabase.instance.reference().child("Tow Requests")
        .orderByChild('driver_id').equalTo(driver_id);

    query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        //print("Tow Requests" + event.snapshot.value["pickup"]["latitude"].toString());
        userRequests = Requests.fromSnapshot(event.snapshot);

        Address address = Address();
        address.placeName = userRequests!.tolldestination_address!;
        address.placeId = "";
        address.placeFormattedAddress = userRequests!.tolldestination_address!;
        address.latitude = double.parse(userRequests!.destination_latitude!);
        address.longitude = double.parse(userRequests!.destination_longitude!);
        Provider.of<AppData>(context, listen: false).updateUserTollDestinationAddress(address);

        Address newAddress = Address();
        newAddress.placeName = userRequests!.pickup_address!;
        newAddress.placeId = "";
        newAddress.placeFormattedAddress = userRequests!.pickup_address!;
        newAddress.latitude = double.parse(userRequests!.pickup_latitude!);
        newAddress.longitude = double.parse(userRequests!.pickup_longitude!);
        Provider.of<AppData>(context, listen: false).updateUserPickUpAddress(newAddress);
        print("Ready now: " + event.snapshot.toString());
      }else{
        print("Ready now : no data");
      }
    });
  }

  static Future<void> getUserTowDetails(context) async
  {
    firebaseUser = await FirebaseAuth.instance.currentUser;

    String userId = firebaseUser!.uid;
    final Query query = FirebaseDatabase.instance.reference().child("Tow Requests")
        .orderByChild('rider_id').equalTo(userId);

    query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        //print("Tow Requests" + event.snapshot.value["pickup"]["latitude"].toString());
        userRequests = Requests.fromSnapshot(event.snapshot);
        Address address = Address();
        address.placeName = userRequests!.tolldestination_address!;
        address.placeId = "";
        address.placeFormattedAddress = userRequests!.tolldestination_address!;
        address.latitude = double.parse(userRequests!.destination_latitude!);
        address.longitude = double.parse(userRequests!.destination_longitude!);
        Provider.of<AppData>(context, listen: false).updateUserTollDestinationAddress(address);

        Address newAddress = Address();
        newAddress.placeName = userRequests!.pickup_address!;
        newAddress.placeId = "";
        newAddress.placeFormattedAddress = userRequests!.pickup_address!;
        newAddress.latitude = double.parse(userRequests!.pickup_latitude!);
        newAddress.longitude = double.parse(userRequests!.pickup_longitude!);
        Provider.of<AppData>(context, listen: false).updateUserCurrentLocationAddress(newAddress);

      }
    });
  }

  static Future<void> getAllTollServices() async {
    final Query query = FirebaseDatabase.instance.reference().child('Towing Services');

    query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        userServices = Services.fromSnapshot(event.snapshot);
      }
    });
  }

  static Future<void> getTollServices() async {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid;
    final Query query = FirebaseDatabase.instance.reference().child('Towing Services')
        .orderByChild('driver_id').equalTo(userId);

    query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        userServices = Services.fromSnapshot(event.snapshot);
      }
    });
  }
}