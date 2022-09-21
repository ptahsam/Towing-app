import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Mechanic
{
  late String? id;
  late String? mechanic_id;
  late String? mechanic_name;
  late String? mechanic_phoneno;
  late String? mechanic_specialisation;
  late String? charge_amount;
  late String? location_latitude;
  late String? location_longitude;
  late String? status;

  Mechanic({this.id, this.mechanic_id, this.mechanic_name, this.mechanic_phoneno, this.mechanic_specialisation, this.charge_amount, this.location_latitude, this.location_longitude, this.status});

  Mechanic.fromSnapshot(DataSnapshot dataSnapshot)
  {
    id = dataSnapshot.key;
    mechanic_id = dataSnapshot.value["mechanic_id"];
    mechanic_name = dataSnapshot.value["mechanic_name"];
    mechanic_phoneno = dataSnapshot.value["mechanic_phoneno"];
    mechanic_specialisation = dataSnapshot.value["mechanic_specialisation"];
    charge_amount = dataSnapshot.value["charge_amount"];
    location_latitude = dataSnapshot.value["location_latitude"];
    location_longitude = dataSnapshot.value["location_longitude"];
    status = dataSnapshot.value["status"];
  }
}