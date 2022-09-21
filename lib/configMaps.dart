import 'package:firebase_auth/firebase_auth.dart';

import 'Models/allMechanic.dart';
import 'Models/allServices.dart';
import 'Models/allUsers.dart';
import 'Models/ratings.dart';
import 'Models/singleService.dart';
import 'Models/userRequests.dart';

String mapKey = "AIzaSyAaWBvoLgmrgRkYMp4T7ESuNlJ2qzGihk0";
String positionStackKey = "3ab30a2f2cfba83e8ba75e2e6bb027cf";

User? firebaseUser;

Users? userCurrentInfo;

Services? userServices;

Mechanic? mechanics;

Singleservice? singleService;

Requests? userRequests;

Ratings? driverRatings;