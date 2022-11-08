import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/AllScreens/requestMechanicScreen.dart';
import 'package:rider_app/AllScreens/searchScreen.dart';
import 'package:rider_app/AllScreens/serviceScreen.dart';
import 'package:rider_app/AllWidgets/Divider.dart';
import 'package:rider_app/AllWidgets/progressDialog.dart';
import 'package:rider_app/Assistants/assistantMethods.dart';
import 'package:rider_app/DataHandler/appData.dart';
import 'package:rider_app/Models/allServices.dart';
import 'package:rider_app/Models/directionDetails.dart';
import 'package:rider_app/Models/ratings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';


import '../configMaps.dart';
import 'loginScreen.dart';
import 'mechanicScreen.dart';

class MainScreen extends StatefulWidget
{

  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {

  //initialize google map
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails, driverDirectionDetails;

  //list of location coordinates
  List<LatLng> pLineCoordinates = [];
  List<LatLng> pDriverCoordinates = [];

  //a list of polyline coordinates
  Set<Polyline> polylineSet = {};
  Set<Polyline> driverPolylineSet = {};

  //list of services
  List<Services> servicesList = [];
  List<Ratings> ratingsList = [];
  //List<Singleservice> singleServiceList = [];
  String truckDescription = "";
  String selectedDriverid = "";
  String driverPhoneno = "";
  double driverAverageRating = 0;
  String driverTotalRatings = "";

  //define location
  late Position currentPosition;

  //google map function to get your location coordinates
  var geoLocator = Geolocator();

  //map padding bottom
  double bottomPaddingOfMap = 0;

  String address = "";

  //Markers to show location on map
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  Set<Marker> driverMarkersSet = {};
  Set<Circle> driverCirclesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestTollContainerHeight = 0;
  double searchContainerHeight = 0;
  double addTowingContainerHeight = 0;
  double towingServicesHeight = 0;
  double requestTollTruckContainerHeight = 0;
  double savedTruckDriverContainer = 0;
  double userRequestsContainerHeight = 0;

  bool drawerOpen = true;

  //reference to firebase database
  DatabaseReference? tollRequestRef, driverRatingRef, tollServiceRef;

  //BitmapDescriptor? pinLocationIcon;

  @override
  void initState() {
    super.initState();
    getUserAccount();
    /*BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(16, 16)),
        'images/truck.png').then((onValue) {
      pinLocationIcon = onValue;
    });*/
    /*DatabaseReference dbReference = FirebaseDatabase.instance.reference().child('Towing Services');
    dbReference.once().then((DataSnapshot dataSnapshot){
      servicesList.clear();
      var keys = dataSnapshot.value.keys;
      var values = dataSnapshot.value;

      for (var key in keys)
      {
        Services services = new Services();
        services.driver_id = values [key]["driver_id"];
        services.truck_description = values [key]["truck_description"];
        services.towing_capacity = values [key]["towing_capacity"];
        services.towing_fee = values [key]["towing_fee"];
        services.location_latitude = values [key]["location_latitude"];
        services.location_longitude = values [key]["location_longitude"];
        services.status = values [key]["status"];

        servicesList.add(services);
      }
    });
     */

  }

  void getUserAccount() async
  {
   // displayMainToastMessage("Towing account", context);
    firebaseUser = await FirebaseAuth.instance.currentUser;
     await AssistantMethods.getCurrentOnlineUserInfo();
     await AssistantMethods.getTollServices();
     await AssistantMethods.getUserTowDetails(context);

     String accountType = await AssistantMethods.getUserAccountType();

    //displayMainToastMessage("Towing account ::" + accountType, context);
       if(accountType == "Normal user")
       {
         if(userRequests != null)
         {
           displayTollDetailsContainer();
           getAllServices();
         }else{
           setState(() {
             searchContainerHeight = 300.0;
           });
         }
       }else
       {
         var driverLatLng = LatLng(double.parse(userServices!.location_latitude!), double.parse(userServices!.location_longitude!));

         Marker driverLocMarker = Marker(
           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
           infoWindow: InfoWindow(title: userServices!.truck_description, snippet: "driver location"),
           position: driverLatLng,
           markerId: MarkerId("driverLocationId"),
         );

         setState(() {
           addTowingContainerHeight = 400.0;
           markersSet.add(driverLocMarker);
         });

         String userId = firebaseUser!.uid;
         final Query query = FirebaseDatabase.instance.reference().child('Towing Services')
             .orderByChild('driver_id').equalTo(userId);
         servicesList.clear();
         await query.onChildAdded.forEach((event) {
           if(event.snapshot.value != ""){
             userServices = Services.fromSnapshot(event.snapshot);

             servicesList.add(userServices!);
             /*
             var keys = event.snapshot.value.keys;
             var values = event.snapshot.value;

             for (var key in keys)
             {
               Services services = new Services();
               services.driver_id = values [key]["driver_id"];
               services.truck_description = values [key]["truck_description"];
               services.towing_capacity = values [key]["towing_capacity"];
               services.towing_fee = values [key]["towing_fee"];
               services.location_latitude = values [key]["location_latitude"];
               services.location_longitude = values [key]["location_longitude"];
               services.status = values [key]["status"];

               servicesList.add(services);
             }
             */
           }
         });
       }

       print("Towing:" + accountType,);
  }

  void resetDriverId()
  {
    tollRequestRef!.update({
      "driver_id": "waiting",
    }).then((_) {

    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(onError)));
    });

    //tollServiceRef = FirebaseDatabase.instance.reference().child("Towing Services").child(selectedDriverid);

    /*tollServiceRef!.update({
      "status": "",
    }).then((_) {

    }).catchError((onError) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(onError)));
    });*/

    //selectedDriverid = "";
  }

  void saveDriverId()
  {
    tollRequestRef!.update({
      "driver_id": selectedDriverid,
    }).then((_) {

    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(onError)));
    });

    tollServiceRef = FirebaseDatabase.instance.reference().child("Towing Services").child(selectedDriverid);

    tollServiceRef!.update({
      "status": "Busy",
    }).then((_) {

    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(onError)));
    });

  }

  void rateDriver(double rating)
  {
    String userId = firebaseUser!.uid;
    String userRating = rating.toString();
    driverRatingRef = FirebaseDatabase.instance.reference().child("Driver Ratings").child(selectedDriverid).child(userId);

    Map driverRatingMap =
    {
      "user_rating": userRating
    };

    driverRatingRef!.set(driverRatingMap);

    displayMainToastMessage("Thank you for rating this driver", context);

  }

  void saveTollRequest()
  {
    tollRequestRef = FirebaseDatabase.instance.reference().child("Tow Requests").push();
    var pickUp = Provider.of<AppData>(context, listen: false).userCurrentLocation!;
    var tollDestination = Provider.of<AppData>(context, listen: false).tollDestinationLocation!;

    Map pickUpLocMap =
    {
     "latitude": pickUp.latitude.toString(),
     "longitude": pickUp.longitude.toString(),
    };

    Map tollDestinationLocMap =
    {
      "latitude": tollDestination.latitude.toString(),
      "longitude": tollDestination.longitude.toString(),
    };

    Map tollDestinationInfoMap =
    {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "toll_destination": tollDestinationLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo!.name!,
      "rider_id" : userCurrentInfo!.id!,
      "rider_phone": userCurrentInfo!.phone!,
      "pickup_address": pickUp.placeName!,
      "tolldestination_address": tollDestination.placeName!,
    };

    tollRequestRef!.set(tollDestinationInfoMap);
    print("Rider name:" + userCurrentInfo!.name!);

  }

  void getAllServices() async
  {

    towingServicesHeight = 200;

    final Query query = FirebaseDatabase.instance.reference().child('Towing Services');
    servicesList.clear();
    await query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        userServices = Services.fromSnapshot(event.snapshot);
        servicesList.add(userServices!);
        print("All service"+userServices!.truck_description!);
      }
    });
  }

  static const colorizeColors = [
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 18.0,
    fontFamily: 'San Fransisco',
  );

  void showUserRequestContainer(){
    setState(() {
      addTowingContainerHeight = 0;
      userRequestsContainerHeight = 350.0;
    });
  }

  void closeClientRequestContainer() {
    setState(() {
      userRequestsContainerHeight = 0.0;
      addTowingContainerHeight = 400;
    });
  }

  void cancelTollRequest()
  {
    tollRequestRef!.remove();
  }

  void setTruckDriverContainer()
  {
    setState(() {
      savedTruckDriverContainer = 350.0;
      requestTollTruckContainerHeight = 0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = true;
    });
  }

  void displayRequestTollContainer()
  {
    setState(() {
      requestTollContainerHeight = 350.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = true;
    });

    saveTollRequest();
    getAllServices();
  }

  void resetTruckDriverContainer()
  {
    setState((){
      requestTollContainerHeight = 350.0;
      savedTruckDriverContainer = 0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = true;
    });
    truckDescription = "";
    //selectedDriverid = "";
    driverPhoneno = "";

    resetDriverId();
  }

  void resetTollTruckContainer()
  {
    setState(() {
      requestTollTruckContainerHeight = 0.0;
      requestTollContainerHeight = 350.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = true;
    });
    truckDescription = "";
    //selectedDriverid = "";
    driverPhoneno = "";

    ratingsList.length = 0;

    ///singleServiceList.clear();
  }

  resetApp()
  {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestTollContainerHeight = 0;
      bottomPaddingOfMap = 290.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }

  void displayRideDetailsContainer() async
  {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 350.0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = false;
    });
  }

  void displayTollDetailsContainer() async
  {
    await getPlaceDirection();

    tollRequestRef = FirebaseDatabase.instance.reference().child("Tow Requests").child(userRequests!.id!);

    setState(() {
      requestTollContainerHeight = 350.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = true;
    });
  }

  //show your current location
  void locatePosition() async
  {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLngPosition, zoom: 18);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

     address = await AssistantMethods.searchCoordinateAddress(position, context);
     print("Your current address is ::"+ address);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text("Towing App"),
      ),
      drawer: Container
        (
        color: Colors.white,
        width: 255.0,
        child: Drawer
          (
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset("images/user.png", height: 50.0, width: 50.0,),
                      SizedBox(width: 16.0,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(userCurrentInfo != null ? userCurrentInfo!.name! : "Profile Name", style: TextStyle(fontSize: 16.0, fontFamily: "San Fransisco"),),
                          SizedBox(height: 6.0,),
                          Text(userCurrentInfo != null ? userCurrentInfo!.account_type! : "Account Type"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              DividerWidget(),

              SizedBox(height: 12.0,),

              ListTile(
                leading: Icon(FontAwesomeIcons.history),
                title: Text("History", style: TextStyle(fontSize: 15.0),),
              ),

              ListTile(
                leading: Icon(FontAwesomeIcons.userAlt),
                title: Text("Profile", style: TextStyle(fontSize: 15.0),),
              ),

              ListTile(
                leading: Icon(FontAwesomeIcons.info),
                title: Text("About", style: TextStyle(fontSize: 15.0),),
              ),

              GestureDetector(
                onTap: ()
                {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
              child:  ListTile(
                  leading: Icon(FontAwesomeIcons.signOutAlt),
                  title: Text("Sign Out", style: TextStyle(fontSize: 15.0),),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 300.0;
              });

              locatePosition();
            },

          ),

          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: ()
              {
                if(drawerOpen)
                {
                  scaffoldKey.currentState!.openDrawer();
                }
                else
                  {
                    resetApp();
                  }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(
                        0.7,
                        0.7
                      ),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close, color: Colors.black,),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //User initial location and get service container
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text(userCurrentInfo != null ? userCurrentInfo!.name! : "Hi there", style: TextStyle(fontSize: 12.0),),
                      Text("Need Towing?", style: TextStyle(fontSize: 20.0, fontFamily: "San Fransisco"),),
                      SizedBox(height: 10.0),
                      GestureDetector(
                        onTap: () async
                        {
                         var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));

                         if(res == "obtainDirection")
                         {
                           displayRideDetailsContainer();
                         }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(FontAwesomeIcons.search, color: Colors.blueAccent,),
                                SizedBox(width: 10.0,),
                                Text("Get towing service")
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.0),

                      GestureDetector(
                        onTap: () async
                        {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>RequestMechanicScreen()));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(FontAwesomeIcons.wrench, color: Colors.blueAccent,),
                                SizedBox(width: 10.0,),
                                Text("Request a mechanic")
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        children: [
                          Icon(Icons.home, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Provider.of<AppData>(context).userCurrentLocation != null
                                    ? Provider.of<AppData>(context).userCurrentLocation!.placeName!
                                    : "Add home address"
                              ),
                              SizedBox(height: 4.0,),
                              Text("Your residential home address:", style: TextStyle(color: Colors.black54, fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 10.0),

                      DividerWidget(),

                      SizedBox(height: 16.0),

                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(height: 4.0,),
                              Text("Your office address", style: TextStyle(color: Colors.black54, fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: addTowingContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 3.0),
                      Text(userCurrentInfo != null ? userCurrentInfo!.name! : "Hi there", style: TextStyle(fontSize: 12.0),),
                      Text("Towing services?", style: TextStyle(fontSize: 16.0, fontFamily: "San Fransisco"),),
                      //Text(userServices != null ? userServices!.truck_description! : "", style: TextStyle(fontSize: 16.0),),
                      Container(
                        child: SizedBox(
                          height: 150,
                          child: servicesList.length == 0 ? Center(child: Text("No services", style: TextStyle(fontSize: 20),)) : ListView.builder(
                              itemCount: servicesList.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (_, index){
                                return CardUI(servicesList[index].id,servicesList[index].driver_id,servicesList[index].truck_description,servicesList[index].towing_capacity,
                                    servicesList[index].towing_fee,servicesList[index].location_latitude,servicesList[index].location_longitude,
                                    servicesList[index].status,);
                              }),
                        ),
                      ),

                      SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: ()
                            {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>ServiceScreen()));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 6.0,
                                    spreadRadius: 0.5,
                                    offset: Offset(0.7, 0.7),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Row(
                                  children: [
                                    Icon(FontAwesomeIcons.truck, color: Colors.blueAccent,),
                                    SizedBox(width: 15.0,),
                                    Text("Add a service")
                                  ],
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: ()
                            {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>MechanicScreen()));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 6.0,
                                    spreadRadius: 0.5,
                                    offset: Offset(0.7, 0.7),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Row(
                                  children: [
                                    Icon(FontAwesomeIcons.wrench, color: Colors.blueAccent,),
                                    SizedBox(width: 15.0,),
                                    Text("Add a mechanic")
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.0),

                      Row(
                        children: [
                          Icon(Icons.home, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  Provider.of<AppData>(context).userCurrentLocation != null
                                      ? Provider.of<AppData>(context).userCurrentLocation!.placeName!
                                      : "Add service address"
                              ),
                              SizedBox(height: 4.0,),
                              Text("Your service address:", style: TextStyle(color: Colors.black54, fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 10.0),

                      DividerWidget(),

                      SizedBox(height: 10.0),

                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(height: 4.0,),
                              Text("Your office address", style: TextStyle(color: Colors.black54, fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              //Image.asset("images/tow-truck.png", height: 70.0, width: 80.0,),
                              Icon(FontAwesomeIcons.car, size: 55.0, color: Colors.blueAccent,),
                              SizedBox(width: 16.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your  vehicle", style: TextStyle(fontSize: 18.0, fontFamily: "San Fransisco"),
                                  ),
                                  Text(
                                    ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                  ),
                                ],
                              ),

                              Expanded(child: Container()),
                              Text(
                                  ((tripDirectionDetails != null) ? '\KES.${AssistantMethods.calculateFares(tripDirectionDetails!)}' : ''), style: TextStyle(fontFamily: "San Fransisco",),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0,),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt, size: 18.0, color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Cash"),
                            SizedBox(width: 6.0,),
                            Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 16.0,),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Theme.of(context).accentColor,
                          ),
                          onPressed: (){
                            displayRequestTollContainer();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Request now", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                               // Icon(FontAwesomeIcons.truck, color: Colors.white, size: 26.0,),
                                Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: userRequestsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              //Image.asset("images/tow-truck.png", height: 70.0, width: 80.0,),
                              Icon(FontAwesomeIcons.user, size: 30.0, color: Colors.blueAccent,),
                              SizedBox(width: 16.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Client name", style: TextStyle(fontSize: 16.0, fontFamily: "San Fransisco"),
                                  ),
                                  Text(
                                    ((userRequests != null) ? userRequests!.rider_name! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                  ),
                                ],
                              ),

                              Expanded(child: Container()),
                              GestureDetector(
                                  onTap: (){
                                    closeClientRequestContainer();
                                  },
                                  child: Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 10.0,),

                      Padding(
                        padding: EdgeInsets.all(5.0,),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 25.0, color: Colors.blueAccent,),
                            SizedBox(width: 16.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Client pick up location", style: TextStyle(fontSize: 16.0, fontFamily: "San Fransisco"),
                                ),
                                Text(
                                  ((userRequests != null) ? userRequests!.pickup_address! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(5.0,),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 25.0, color: Colors.redAccent,),
                            SizedBox(width: 16.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Client tolling destination", style: TextStyle(fontSize: 16.0, fontFamily: "San Fransisco"),
                                ),
                                Text(
                                  ((userRequests != null) ? userRequests!.tolldestination_address! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /*Padding(
                        padding: EdgeInsets.all(5.0,),
                        child: Row(
                          children: [
                            Icon(Icons.timelapse_sharp, size: 25.0, color: Colors.greenAccent,),
                            SizedBox(width: 16.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Trip Duration", style: TextStyle(fontSize: 16.0, fontFamily: "San Fransisco"),
                                ),
                                Text(
                                  ((tripDirectionDetails != null) ? tripDirectionDetails!.durationText! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                       */

                      SizedBox(height: 6.0,),
                      /*
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: RaisedButton(
                          onPressed: (){
                            displayRequestTollContainer();
                          },
                          color: Theme.of(context).accentColor,
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Request now", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                // Icon(FontAwesomeIcons.truck, color: Colors.white, size: 26.0,),
                                Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),

                       */
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: savedTruckDriverContainer,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              //Image.asset("images/tow-truck.png", height: 70.0, width: 80.0,),
                              Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              //Icon(FontAwesomeIcons.car, size: 55.0, color: Colors.blueAccent,),
                              SizedBox(width: 8.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ((truckDescription != null) ? truckDescription : ""), style: TextStyle(fontSize: 18.0, fontFamily: "San Fransisco"),
                                  ),
                                  Text(
                                    ((tripDirectionDetails != null) ? tripDirectionDetails!.durationText! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                  ),
                                ],
                              ),

                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! + " away" : ''), style: TextStyle(fontFamily: "San Fransisco",),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0,),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.user, size: 18.0, color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Your driver is on the way", style: TextStyle(color: Colors.blueAccent),),
                            SizedBox(width: 6.0,),
                            Icon(FontAwesomeIcons.ellipsisH, color: Colors.blueAccent, size: 11.0,),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: (){
                            resetTruckDriverContainer();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Cancel this request", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                Icon(FontAwesomeIcons.times, color: Colors.white, size: 18.0,),
                                //Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                          ),
                          onPressed: (){
                            _launchPhoneURL();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Call this Driver", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                Icon(FontAwesomeIcons.phone, color: Colors.white, size: 18.0,),
                                //Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: (){
                            lipaNaMpesa();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Make payment", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.green),),
                                Image.asset("images/mpesa.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.0,),

                      Text("Rate this Driver", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),),

                      SizedBox(height: 5.0,),

                      RatingBar.builder(
                        initialRating: 3,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                        rateDriver(rating);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: requestTollTruckContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              //Image.asset("images/tow-truck.png", height: 70.0, width: 80.0,),
                              Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              //Icon(FontAwesomeIcons.car, size: 55.0, color: Colors.blueAccent,),
                              SizedBox(width: 16.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ((truckDescription != null) ? truckDescription : ""), style: TextStyle(fontSize: 18.0, fontFamily: "San Fransisco"),
                                  ),
                                  Text(
                                    ((tripDirectionDetails != null) ? tripDirectionDetails!.durationText! : ''), style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                  ),
                                ],
                              ),

                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : ''), style: TextStyle(fontFamily: "San Fransisco",),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0,),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt, size: 18.0, color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Cash"),
                            SizedBox(width: 6.0,),
                            Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 16.0,),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          onPressed: (){
                            saveDriverId();
                            setTruckDriverContainer();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Request this driver", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                // Icon(FontAwesomeIcons.truck, color: Colors.white, size: 26.0,),
                                //Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                          ),
                          onPressed: (){
                            resetTollTruckContainer();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("View another driver", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                // Icon(FontAwesomeIcons.truck, color: Colors.white, size: 26.0,),
                                //Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.0,),

                      Text("Driver Ratings(" + driverAverageRating.toString() + ") " + ratingsList.length.toString() + " Ratings", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),),

                      RatingBar.builder(
                        initialRating: driverAverageRating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          rateDriver(rating);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestTollContainerHeight,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 8.0,),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting towing service ...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Please wait ...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Finding a driver for you ...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),

                    SizedBox(height: 22.0,),

                    GestureDetector(
                      onTap: ()
                      {
                        cancelTollRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 40.0,
                        width: 70.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          border: Border.all(width: 2.0, color: Colors.grey),
                        ),
                        child: Icon(Icons.close, size: 18.0,),
                      ),
                    ),

                    SizedBox(height: 10.0,),

                    Container(
                      width: double.infinity,
                      child: Text("Cancel request", textAlign: TextAlign.center, style: TextStyle(fontSize: 12.0),),
                    ),
                    SizedBox(height: 8.0,),
                    Flexible(
                      flex: 2,
                      child: Container(
                        child: SizedBox(
                          height: towingServicesHeight,
                          child: servicesList.length == 0 ? Align(
                              alignment: Alignment.center,
                              child: Center(child: CircularProgressIndicator()),
                          ) :
                            ListView.builder(
                                itemCount: servicesList.length,
                                scrollDirection: Axis.vertical,
                                itemBuilder: (_, index){
                                  return CardUIVertical(servicesList[index].id,servicesList[index].driver_id,servicesList[index].truck_description,servicesList[index].towing_capacity,
                                    servicesList[index].towing_fee,servicesList[index].location_latitude,servicesList[index].location_longitude,
                                    servicesList[index].status,);
                                }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchPhoneURL() async {
    String url = 'tel:' + driverPhoneno;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> getUserRequest(String id, String driver_id) async
  {
    await AssistantMethods.getAllUserRequest(id, context);


  /*
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Please wait...",)
    );

   */

    //if(userRequests != null && userRequests!.driver_id == id){
      //Navigator.push(context, MaterialPageRoute(builder: (context)=>RequestScreen()));
      showUserRequestContainer();
      /*var initialPos = Provider.of<AppData>(context, listen: false).userPickpupLocation!;
      var finalPos = Provider.of<AppData>(context, listen: false).tollDestinationLocation!;

      var pickUpLatLng = LatLng(initialPos.latitude!, initialPos.longitude!);
      var tollDestinationLatLng = LatLng(finalPos.latitude!, finalPos.longitude!);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, tollDestinationLatLng);

      setState(() {
        tripDirectionDetails = details;
      });

      Navigator.pop(context);

      print("This is Encoded Points::");
      print(details.encodedPoints);

      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decodedPolyLinePointsResult = polylinePoints.decodePolyline(details.encodedPoints!);

      pLineCoordinates.clear();

      if(decodedPolyLinePointsResult.isNotEmpty){
        decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
          pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
        });
      }

      polylineSet.clear();

      setState(() {
        Polyline polyline = Polyline(
          color: Colors.blueAccent,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        );
        polylineSet.add(polyline);
      });

      LatLngBounds latLngBounds;
      if(pickUpLatLng.latitude > tollDestinationLatLng.latitude && pickUpLatLng.longitude > tollDestinationLatLng.longitude)
      {
        latLngBounds = LatLngBounds(southwest: tollDestinationLatLng, northeast: pickUpLatLng);
      }else if(pickUpLatLng.longitude > tollDestinationLatLng.longitude)
      {
        latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, tollDestinationLatLng.longitude), northeast: LatLng(tollDestinationLatLng.latitude, pickUpLatLng.longitude));
      }
      else if(pickUpLatLng.latitude > tollDestinationLatLng.latitude)
      {
        latLngBounds = LatLngBounds(southwest: LatLng(tollDestinationLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, tollDestinationLatLng.longitude));
      }
      else{
        latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: tollDestinationLatLng);
      }

      newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

      Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: initialPos.placeName, snippet: "Client location"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId"),
      );

      Marker tollDestinationLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: finalPos.placeName, snippet: "Destination location"),
        position: tollDestinationLatLng,
        markerId: MarkerId("tollDestinationId"),
      );

      setState(() {
        markersSet.add(pickUpLocMarker);
        markersSet.add(tollDestinationLocMarker);
      });

      Circle pickUpLocCircle = Circle(
        fillColor: Colors.green,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.greenAccent,
        circleId: CircleId("pickUpId"),
      );

      Circle tollDestinationLocCircle = Circle(
        fillColor: Colors.deepPurple,
        center: tollDestinationLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.purple,
        circleId: CircleId("tollDestinationId"),
      );

      setState(() {
        circlesSet.add(pickUpLocCircle);
        circlesSet.add(tollDestinationLocCircle);
      });

       */
    //}

  }


  Future<void> getDriverPlaceDirection(String id, String driver_id, String latitude, String longitude) async
  {
    getDriverLocation(latitude, longitude);
    var initialPos = Provider.of<AppData>(context, listen: false).userCurrentLocation!;
    //var finalPos = Provider.of<AppData>(context, listen: false).tollDestinationLocation!;

    var pickUpLatLng = LatLng(initialPos.latitude!, initialPos.longitude!);
    var tollDestinationLatLng = LatLng(double.parse(latitude), double.parse(longitude));


    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Please wait...",)
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, tollDestinationLatLng);

    setState(() {
      driverDirectionDetails = details;
    });

    Navigator.pop(context);

    print("This is Driver Encoded Points::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult = polylinePoints.decodePolyline(details.encodedPoints!);

    pDriverCoordinates.clear();

    if(decodedPolyLinePointsResult.isNotEmpty){
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pDriverCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    //driverPolylineSet.clear();
/*
    setState(() {
      Polyline dpolyline = Polyline(
        color: Colors.redAccent,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pDriverCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(dpolyline);
    });

 */

    LatLngBounds latLngBounds;
    if(pickUpLatLng.latitude > tollDestinationLatLng.latitude && pickUpLatLng.longitude > tollDestinationLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: tollDestinationLatLng, northeast: pickUpLatLng);
    }else if(pickUpLatLng.longitude > tollDestinationLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, tollDestinationLatLng.longitude), northeast: LatLng(tollDestinationLatLng.latitude, pickUpLatLng.longitude));
    }
    else if(pickUpLatLng.latitude > tollDestinationLatLng.latitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(tollDestinationLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, tollDestinationLatLng.longitude));
    }
    else{
      latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: tollDestinationLatLng);
    }

    newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));

    Marker DriverPickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: initialPos.placeName, snippet: "my location"),
      position: pickUpLatLng,
      markerId: MarkerId("driverpickUpId"),
    );

    Marker DriverCurrentLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: "Driver", snippet: "driver location"),
      position: tollDestinationLatLng,
      markerId: MarkerId("driverCurLocId"),
    );

    setState(() {
     // markersSet.add(DriverPickUpLocMarker);
      markersSet.add(DriverCurrentLocMarker);
    });

    Circle DriverPickUpLocCircle = Circle(
      fillColor: Colors.green,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.greenAccent,
      circleId: CircleId("driverpickUpId"),
    );

    Circle DriverLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: tollDestinationLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purple,
      circleId: CircleId("driverLocId"),
    );

    setState(() {
      //circlesSet.add(DriverPickUpLocCircle);
      circlesSet.add(DriverLocCircle);
    });

    final dbRef = FirebaseDatabase.instance.reference().child("Towing Services").child(id).child("truck_description");
    final snapshot = await dbRef.once();
    truckDescription = snapshot.value.toString();
    selectedDriverid = id;

    final userRef = FirebaseDatabase.instance.reference().child("users").child(driver_id).child("phone");
    final datasnapshot = await userRef.once();
    driverPhoneno = datasnapshot.value.toString();

    /*final driverRatingRef = await FirebaseDatabase.instance.reference().child("Driver Ratings").child(driver_id).once();
    var ratingsNodes = [];
    driverRatingRef.value.forEach((v) => ratingsNodes.add(v));

    final Query query = FirebaseDatabase.instance.reference().child('Driver Ratings')
        .orderByKey().equalTo(driver_id);
    ratingsList.clear();
    query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        driverRatings = Ratings.fromSnapshot(event.snapshot);

        ratingsList.add(driverRatings!);
      }
    });*/






    //double userRating = 0;
    /*
    driverRatingRef.value.forEach((key,values) {
     userRating = userRating + values["user_rating"];
    });
    */
    //driverAverageRating = userRating / driverTotalRatings;

    setState(() {
      requestTollTruckContainerHeight = 350.0;
      requestTollContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 290.0;
      drawerOpen = true;
    });

  }

  Future<void> lipaNaMpesa() async {
    dynamic transactionInitialisation;
    String phoneno = userCurrentInfo!.phone!;
    String pno = phoneno.substring(1);
    try {
      transactionInitialisation = await MpesaFlutterPlugin.initializeMpesaSTKPush(
          businessShortCode: "174379",
          transactionType: TransactionType.CustomerPayBillOnline,
          amount: 1.0,
          partyA:  "254" + pno,
          partyB: "174379",
          //Lipa na Mpesa Online ShortCode
          callBackURL: Uri(scheme: "https",
              host: "mpesa-requestbin.herokuapp.com",
              path: "/1krrrkq1"),
          //This url has been generated from http://mpesa-requestbin.herokuapp.com/?ref=hackernoon.com for test purposes
          accountReference: "Towing App",
          phoneNumber:  "254" + pno,
          baseUri: Uri(scheme: "https", host: "sandbox.safaricom.co.ke"),
          transactionDesc: "Towing Payment",
          passKey:"bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919");
          //This passkey has been generated from Test Credentials from Safaricom Portal
          print("TRANSACTION RESULT: " + transactionInitialisation.toString());
          print("Phoneno" + pno);

          //lets print the transaction results to console at this step
      return transactionInitialisation;
    }
    catch (e) {
      print("CAUGHT EXCEPTION: " + e.toString());
    }
  }

  Future<void> getDriverLocation(String latitude, String longitude) async
  {
    var initialPos = Provider.of<AppData>(context, listen: false).userCurrentLocation!;
    var userLocation = LatLng(initialPos.latitude!, initialPos.longitude!);
    var driverLocation = LatLng(double.parse(latitude), double.parse(longitude));

    var details = await AssistantMethods.obtainPlaceDirectionDetails(userLocation, driverLocation);

    setState(() {
      tripDirectionDetails = details;
    });

  }

  Future<void> getPlaceDirection() async
  {
    var initialPos = Provider.of<AppData>(context, listen: false).userCurrentLocation!;
    var finalPos = Provider.of<AppData>(context, listen: false).tollDestinationLocation!;

    var pickUpLatLng = LatLng(initialPos.latitude!, initialPos.longitude!);
    var tollDestinationLatLng = LatLng(finalPos.latitude!, finalPos.longitude!);


    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",)
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, tollDestinationLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    print("This is Encoded Points::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult = polylinePoints.decodePolyline(details.encodedPoints!);

    pLineCoordinates.clear();

    if(decodedPolyLinePointsResult.isNotEmpty){
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blueAccent,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if(pickUpLatLng.latitude > tollDestinationLatLng.latitude && pickUpLatLng.longitude > tollDestinationLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: tollDestinationLatLng, northeast: pickUpLatLng);
    }else if(pickUpLatLng.longitude > tollDestinationLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, tollDestinationLatLng.longitude), northeast: LatLng(tollDestinationLatLng.latitude, pickUpLatLng.longitude));
    }
    else if(pickUpLatLng.latitude > tollDestinationLatLng.latitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(tollDestinationLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, tollDestinationLatLng.longitude));
    }
    else{
      latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: tollDestinationLatLng);
    }

    newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: initialPos.placeName, snippet: "my location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker tollDestinationLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: finalPos.placeName, snippet: "toll destination location"),
      position: tollDestinationLatLng,
      markerId: MarkerId("tollDestinationId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(tollDestinationLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.green,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.greenAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle tollDestinationLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: tollDestinationLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purple,
      circleId: CircleId("tollDestinationId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(tollDestinationLocCircle);
    });

  }

  Widget CardUI(String? id, String? driver_id, String? truck_description, String? towing_capacity, String? towing_fee, String? location_latitude, String? location_longitude, String? status) {
    return Card(
      elevation: 7,
      margin: EdgeInsets.all(5),
      color: Colors.blue,
      child: Container(
        width: 200,
        color: Colors.white,
        margin: EdgeInsets.all(1.5),
        padding: EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(FontAwesomeIcons.truck, size: 20.0, color: Colors.black54,),
            SizedBox(height: 3.0,),
            Text(truck_description!, style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),),
            SizedBox(height: 3.0,),
            Text("Towing Capacity(t) : $towing_capacity", style: TextStyle(fontSize: 13),),
            SizedBox(height: 3.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status != ""? status! : "Available", style: TextStyle(color: Colors.black54, fontSize: 12),),
                Text("Towing fee/km : $towing_fee", style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),textAlign: TextAlign.right,),
                ],
            ),
            SizedBox(height: 3.0,),
            status != ""?
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0),
                ),
                backgroundColor: Colors.blueAccent,
                textStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
              child: Container(
                height: 20.0,
                child: Center(
                  child: Text(
                    "View Request",
                    style: TextStyle(fontFamily: "San Fransisco"),
                  ),
                ),
              ),
              onPressed: ()
              {
                getUserRequest(id!, driver_id!);
              },
            ) : Text(""),
          ],
        ),
      ),
    );
  }

  Widget CardUIVertical(String? id, String? driver_id, String? truck_description, String? towing_capacity, String? towing_fee, String? location_latitude, String? location_longitude, String? status) {
    //getDriverLocation(location_latitude!, location_longitude!);
    return Card(
      elevation: 7,
      //margin: EdgeInsets.all(15),
      //color: Colors.blue,
      child: GestureDetector(
        onTap: ()
        {
          getDriverPlaceDirection(id!, driver_id!, location_latitude!, location_longitude!);
          //print("Driver ID: " + id!);
        },
        child: Container(
          color: Colors.white,
          margin: EdgeInsets.all(1.5),
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(truck_description!, style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),),
              SizedBox(height: 1,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Duration : " + tripDirectionDetails!.durationText!, style: TextStyle(color: Colors.blueAccent, fontSize: 13),),
                  Text(status != ""? status! : "Available", textAlign: TextAlign.right, style: TextStyle(color: Colors.green, fontSize: 12),),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

displayMainToastMessage(String message, BuildContext context)
{
  Fluttertoast.showToast(msg: message);
}
