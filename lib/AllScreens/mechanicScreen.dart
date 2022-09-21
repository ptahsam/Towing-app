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

class MechanicScreen extends StatefulWidget {
  const MechanicScreen({Key? key}) : super(key: key);

  @override
  _MechanicScreenState createState() => _MechanicScreenState();

}

class _MechanicScreenState extends State<MechanicScreen> {

  TextEditingController currentLocationTextEditingController = TextEditingController();

  TextEditingController mechanicNameTextEditingController = TextEditingController();

  TextEditingController mechanicPhonenoTextEditingController = TextEditingController();

  TextEditingController mechanicSpecialisationTextEditingController = TextEditingController();

  TextEditingController chargeEditingController = TextEditingController();

  DatabaseReference? addMechanicRef;

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
                        child: Text("Add a new mechanic", style: TextStyle(fontSize: 18.0),),
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
                  controller: mechanicNameTextEditingController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: "Mechanic Full name",
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
                  controller: mechanicPhonenoTextEditingController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Mechanic Phone number",
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
                  controller: mechanicSpecialisationTextEditingController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: "Mechanic Specialisation",
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
                  controller: chargeEditingController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Charges",
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
                        "Add new mechanic",
                        style: TextStyle(fontSize: 18.0, fontFamily: "San Fransisco"),
                      ),
                    ),
                  ),
                  shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(15.0),
                  ),
                  onPressed: ()
                  {
                    if(mechanicNameTextEditingController.text.isEmpty)
                    {
                      displayToastMessage("Please enter mechanic name", context);
                    }
                    else if(mechanicPhonenoTextEditingController.text.isEmpty)
                    {
                      displayToastMessage("Please enter mechanic phone number", context);
                    }
                    else if(mechanicSpecialisationTextEditingController.text.isEmpty)
                    {
                      displayToastMessage("Please enter mechanic specialisation", context);
                    }
                    else if(chargeEditingController.text.isEmpty)
                    {
                      displayToastMessage("Please enter amount charged", context);
                    }
                    else
                    {
                      registerNewMechanic(context);
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

  void registerNewMechanic(BuildContext context) async
  {

    addMechanicRef = FirebaseDatabase.instance.reference().child('Mechanic Services').push();
    var mechanicService = Provider.of<AppData>(context, listen: false).userCurrentLocation!;

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Creating new mechanic, Please wait...",)
    );

    String mechanicid = userCurrentInfo!.id!;

    Navigator.pop(context);

    if(mechanicid != null)
    {
      Map serviceDataMap = {
        "mechanic_id" : mechanicid,
        "mechanic_name": mechanicNameTextEditingController.text.trim(),
        "mechanic_phoneno": mechanicPhonenoTextEditingController.text.trim(),
        "mechanic_specialisation": mechanicSpecialisationTextEditingController.text.trim(),
        "charge_amount": chargeEditingController.text.trim(),
        "location_latitude": mechanicService.latitude.toString(),
        "location_longitude": mechanicService.longitude.toString(),
        "status": "",
      };

      addMechanicRef!.set(serviceDataMap);
      displayToastMessage("Your have created a new mechanic successfully.", context);
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
