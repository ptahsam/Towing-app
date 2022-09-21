import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/AllWidgets/progressDialog.dart';
import 'package:rider_app/Assistants/assistantMethods.dart';
import 'package:rider_app/DataHandler/appData.dart';
import 'package:rider_app/Models/allServices.dart';

import '../configMaps.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({Key? key}) : super(key: key);

  @override
  _ServiceScreenState createState() => _ServiceScreenState();

}

class _ServiceScreenState extends State<ServiceScreen> {

  TextEditingController currentLocationTextEditingController = TextEditingController();

  TextEditingController truckDescriptionTextEditingController = TextEditingController();

  TextEditingController truckCapacityTextEditingController = TextEditingController();

  TextEditingController truckFeeTextEditingController = TextEditingController();

  DatabaseReference? addServiceRef;

  @override
  Widget build(BuildContext context) {

    String placeAddress = Provider.of<AppData>(context).userCurrentLocation!.placeName ?? "";
    currentLocationTextEditingController.text = placeAddress;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 175.0,
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
                        child: Text("Add a towing service", style: TextStyle(fontSize: 18.0),),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Image.asset("images/pickicon.png", height: 16.0, width: 16.0,),

                      SizedBox(width: 18.0,),

                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              controller: currentLocationTextEditingController,
                              decoration: InputDecoration(
                                hintText: "Your current location",
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
                children: [
                  SizedBox(height: 1.0,),
                  TextField(
                    controller: truckDescriptionTextEditingController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "Tow truck description",
                      labelStyle: TextStyle(
                        fontSize: 14.0,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 14.0),
                  ),

                  SizedBox(height: 1.0,),
                  TextField(
                    controller: truckCapacityTextEditingController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Towing capacity(tonnes)",
                      labelStyle: TextStyle(
                        fontSize: 14.0,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 14.0),
                  ),

                  SizedBox(height: 1.0,),
                  TextField(
                    controller: truckFeeTextEditingController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Towing fee/km",
                      labelStyle: TextStyle(
                        fontSize: 14.0,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 14.0),
                  ),


                  SizedBox(height: 10.0,),
                  RaisedButton(
                    color: Colors.blueAccent,
                    textColor: Colors.white,
                    child: Container(
                      height: 50.0,
                      child: Center(
                        child: Text(
                          "Add new tow service",
                          style: TextStyle(fontSize: 18.0, fontFamily: "San Fransisco"),
                        ),
                      ),
                    ),
                    shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                    ),
                    onPressed: ()
                    {
                      if(truckDescriptionTextEditingController.text.isEmpty)
                      {
                        displayToastMessage("Please enter truck description", context);
                      }

                      else if(truckCapacityTextEditingController.text.isEmpty)
                      {
                        displayToastMessage("Please enter truck towing capacity", context);
                      }
                      else if(truckFeeTextEditingController.text.isEmpty)
                      {
                        displayToastMessage("Please enter truck towing fee/km", context);
                      }
                      else
                      {
                        registerNewService(context);
                      }
                    },
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }

  void registerNewService(BuildContext context) async
  {

    addServiceRef = FirebaseDatabase.instance.reference().child('Towing Services').push();
    var towService = Provider.of<AppData>(context, listen: false).userCurrentLocation!;

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Creating new service, Please wait...",)
    );

    String driverid = userCurrentInfo!.id!;

    Navigator.pop(context);

    if(driverid != null)
    {
      Map serviceDataMap = {
        "driver_id" : driverid,
        "truck_description": truckDescriptionTextEditingController.text.trim(),
        "towing_capacity": truckCapacityTextEditingController.text.trim(),
        "towing_fee": truckFeeTextEditingController.text.trim(),
        "location_latitude": towService.latitude.toString(),
        "location_longitude": towService.longitude.toString(),
        "status": "",
      };

      addServiceRef!.set(serviceDataMap);
      displayToastMessage("Your have created a new service successfully.", context);
      Navigator.pop(context, "createdService");
    }
    else
    {
      Navigator.pop(context);
      displayToastMessage("Details have not been saved.", context);
    }
  }
}

displayToastMessage(String message, BuildContext context)
{
  Fluttertoast.showToast(msg: message);
}
