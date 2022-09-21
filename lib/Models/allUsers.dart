import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Users
{
  late String? id;
  late String? email;
  late String? name;
  late String? phone;
  late String? account_type;

  Users({this.id, this.email, this.name, this.phone, this.account_type});

  Users.fromSnapshot(DataSnapshot dataSnapshot)
  {
    id = dataSnapshot.key;
    email = dataSnapshot.value["email"];
    name = dataSnapshot.value["name"];
    phone = dataSnapshot.value["phone"];
    account_type = dataSnapshot.value["account_type"];
  }
}