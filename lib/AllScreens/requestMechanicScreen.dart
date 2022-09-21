import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rider_app/Models/allMechanic.dart';
import 'package:url_launcher/url_launcher.dart';

import '../configMaps.dart';

class RequestMechanicScreen extends StatefulWidget {
  const RequestMechanicScreen({Key? key}) : super(key: key);

  @override
  _RequestMechanicScreenState createState() => _RequestMechanicScreenState();

}

class _RequestMechanicScreenState extends State<RequestMechanicScreen> with TickerProviderStateMixin {

  List<Mechanic> mechanicList = [];
  var controller;

  @override
  void initState() {
    // TODO: implement initState
      controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      setState(() {});
    });
    controller.repeat(reverse: true);
    getAllMechanics();
    super.initState();
  }

  void getAllMechanics() async
  {
    final Query query = FirebaseDatabase.instance.reference().child('Mechanic Services');
    mechanicList.clear();
    query.onChildAdded.forEach((event) {
      if(event.snapshot.value != ""){
        mechanics = Mechanic.fromSnapshot(event.snapshot);
        mechanicList.add(mechanics!);
        print("Mechanics: " + mechanics!.mechanic_name!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 100.0,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                ),
              ],
            ),

            child: Padding(
              padding: EdgeInsets.only(left: 25.0, top: 40.0, right: 25.0, bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 5.0),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap:()
                        {
                          Navigator.pop(context);
                        },
                        child: Icon(
                            Icons.arrow_back
                        ),
                      ),
                      Center(
                        child: Text("Request Mechanic", style: TextStyle(fontSize: 18.0),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 5.0,),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Container(
                child: SizedBox(
                  height: 400,
                  child: mechanicList.length == 0 ? Center(child:
                  CircularProgressIndicator(
                    value: controller.value,
                    semanticsLabel: 'Loading mechanics',
                  ),) :
                  ListView.builder(
                      itemCount: mechanicList.length,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (_, index){
                        return CardUIMechanics(mechanicList[index].id,mechanicList[index].mechanic_id,mechanicList[index].mechanic_name,mechanicList[index].mechanic_phoneno,mechanicList[index].mechanic_specialisation,
                          mechanicList[index].charge_amount,mechanicList[index].location_latitude,mechanicList[index].location_longitude,
                          mechanicList[index].status,);
                      }),
                ),
              ),
          ),
        ],
      ),
    );
  }

  void callMechanic(String phoneno) async {
    String url = 'tel:' + phoneno;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget CardUIMechanics(String? id, String? mechanic_id, String? mechanic_name, String? mechanic_phoneno, String? mechanic_specialisation, String? charge_amount, String? location_latitude, String? location_longitude, String? status) {
    //getDriverLocation(location_latitude!, location_longitude!);
    return Card(
      elevation: 7,
      margin: EdgeInsets.all(5),
      color: Colors.blue,
      child: GestureDetector(
        onTap: ()
        {
          //getDriverPlaceDirection(id!, driver_id!, location_latitude!, location_longitude!);
          //print("Driver ID: " + id!);
        },
        child: Container(
          color: Colors.white,
          margin: EdgeInsets.all(1.5),
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(mechanic_name!, style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),),
              SizedBox(height: 1,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(mechanic_specialisation!, style: TextStyle(color: Colors.blueAccent, fontSize: 14),),
                  //Text(status != ""? status! : "Available", textAlign: TextAlign.right, style: TextStyle(color: Colors.green, fontSize: 14),),
                ],
              ),
              SizedBox(height: 8),
              RaisedButton(
                onPressed: (){
                  callMechanic(mechanic_phoneno!);
                },
                color: Colors.greenAccent,
                child: Padding(
                  padding: EdgeInsets.all(7.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Call", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),),
                      Icon(FontAwesomeIcons.phone, color: Colors.white, size: 18.0,),
                      //Image.asset("images/tow-truck.png", height: 40.0, width: 65.0,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
