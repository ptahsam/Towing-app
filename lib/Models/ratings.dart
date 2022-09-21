import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Ratings
{
  late String? id;
  late String? user_rating;

  Ratings({this.id, this.user_rating});

  Ratings.fromSnapshot(DataSnapshot dataSnapshot)
  {
    id = dataSnapshot.key;
    user_rating = dataSnapshot.value["user_rating"];
  }
}