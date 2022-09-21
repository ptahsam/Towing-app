import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Services
{
  late String? id;
  late String? driver_id;
  late String? truck_description;
  late String? towing_capacity;
  late String? towing_fee;
  late String? location_latitude;
  late String? location_longitude;
  late String? status;

  Services({this.id, this.driver_id, this.truck_description, this.towing_capacity, this.towing_fee, this.location_latitude, this.location_longitude, this.status});

  Services.fromSnapshot(DataSnapshot dataSnapshot)
  {
    id = dataSnapshot.key;
    driver_id = dataSnapshot.value["driver_id"];
    truck_description = dataSnapshot.value["truck_description"];
    towing_capacity = dataSnapshot.value["towing_capacity"];
    towing_fee = dataSnapshot.value["towing_fee"];
    location_latitude = dataSnapshot.value["location_latitude"];
    location_longitude = dataSnapshot.value["location_longitude"];
    status = dataSnapshot.value["status"];
  }
}