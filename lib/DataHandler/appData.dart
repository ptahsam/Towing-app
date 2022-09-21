import 'package:flutter/cupertino.dart';
import 'package:rider_app/Models/address.dart';
import 'package:rider_app/Models/allServices.dart';

class AppData extends ChangeNotifier
{
  Address? userCurrentLocation, tollDestinationLocation, userPickpupLocation;
  Services? tollServices;

  void updateUserCurrentLocationAddress(Address userCurrentLoc)
  {
    userCurrentLocation = userCurrentLoc;
    notifyListeners();
  }

  void updateUserTollDestinationAddress(Address tollDestinationLoc)
  {
    tollDestinationLocation = tollDestinationLoc;
    notifyListeners();
  }

  void updateUserPickUpAddress(Address userPickupLoc)
  {
    userPickpupLocation = userPickupLoc;
    notifyListeners();
  }

  void updateTollServices(Services alltollServices)
  {
    tollServices = alltollServices;
    notifyListeners();
  }
}