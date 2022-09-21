import 'package:firebase_database/firebase_database.dart';

class Requests
{
  late String? id;
  late String? driver_id;
  late String? payment_method;
  late String? pickup_latitude;
  late String? pickup_longitude;
  late String? destination_latitude;
  late String? destination_longitude;
  late String? pickup_address;
  late String? tolldestination_address;
  late String? rider_name;
  late String? rider_id;

  Requests({this.id,this.driver_id,this.payment_method,this.pickup_latitude,this.pickup_longitude,this.pickup_address,this.destination_latitude,this.destination_longitude,this.tolldestination_address,this.rider_name,this.rider_id});

  Requests.fromSnapshot(DataSnapshot dataSnapshot)
  {
    id = dataSnapshot.key;
    driver_id = dataSnapshot.value["driver_id"];
    payment_method = dataSnapshot.value["payment_method"];
    pickup_latitude = dataSnapshot.value["pickup"]["latitude"];
    pickup_longitude = dataSnapshot.value["pickup"]["longitude"];
    destination_latitude = dataSnapshot.value["toll_destination"]["latitude"];
    destination_longitude = dataSnapshot.value["toll_destination"]["longitude"];
    pickup_address = dataSnapshot.value["pickup_address"];
    tolldestination_address = dataSnapshot.value["tolldestination_address"];
    rider_name = dataSnapshot.value["rider_name"];
    rider_id = dataSnapshot.value["rider_id"];
  }
}