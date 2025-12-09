import 'package:amz/view/dropshipper/badorder_fullimagescreen.dart';
import 'package:amz/view/dropshipper/scanneddata_report.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class Scanneddata extends StatefulWidget {
  const Scanneddata({super.key});

  @override
  State<Scanneddata> createState() => _ScanneddataState();
}

class _ScanneddataState extends State<Scanneddata> {
  String selectedFilter = 'All';
  List<dynamic> scannedOrders = [];
  bool isLoading = false;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    fetchScanData();
  }

  Future<void> fetchScanData() async {
    setState(() {
      isLoading = true;
    });

    // SharedPreferences se seller_id lena
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sellerId =
        prefs.getString('userId'); // 'userId' aapne save kiya tha

    if (sellerId == null) {
      setState(() {
        isLoading = false;
      });
      return; // Agar sellerId null ho to function exit kar de
    }

    String baseUrl =
        "https://customprint.deodap.com/api_amzDD_return/get_scanned_goodbad.php?seller_id=$sellerId";

    if (selectedFilter == 'Good') {
      baseUrl += "&filter=good";
    } else if (selectedFilter == 'Bad') {
      baseUrl += "&filter=bad";
    }

    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            scannedOrders = data['scanned_orders'];
            hasInternet = true;
          });
        }
      }
    } catch (e) {
      if (e is SocketException) {
        setState(() {
          hasInternet = false;
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true, // Drag/move करने के लिए
            boundaryMargin:
                EdgeInsets.all(20), // Zooming को थोड़ा smooth बनाने के लिए
            minScale: 1.0, // Minimum zoom scale
            maxScale: 5.0, // Maximum zoom scale
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, // Image पूरी screen में adjust होगी
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0172B2),
                  Color(0xFF001645),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 40, left: 15, right: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Scanned Order Display",
                            style: GoogleFonts.oswald(
                              textStyle: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),


                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 130,
                    height: 40,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade400,
                    ),
                    child: DropdownButton<String>(
                      value: selectedFilter,
                      items: ["All", "Good", "Bad"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedFilter = newValue!;
                          fetchScanData();
                        });
                      },
                      underline: const SizedBox(),
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      backgroundColor: Colors.white,
                      color: Colors.blue.shade900,
                      onRefresh: fetchScanData,
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : hasInternet
                              ? (scannedOrders.isEmpty
                                  ? Center(
                                      child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/no_data_found.png',
                                          height: 200,
                                        ),
                                        Text(
                                          "No Order Available",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        )
                                      ],
                                    ))
                                  : ListView.builder(
                                      itemCount: scannedOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = scannedOrders[index];
                                        List<String> imageUrls =
                                            List<String>.from(order['images']);

                                        return Card(
                                          color: Colors.white,
                                          child: Column(
                                            children: [
                                              ListTile(
                                                onTap: () {
                                                  if (order[
                                                          'bad_good_return'] ==
                                                      "bad") {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            BadOrderImagesScreen(
                                                                imageUrls:
                                                                    imageUrls),
                                                      ),
                                                    );
                                                  }
                                                },
                                                leading: CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  child: Text(
                                                    "${index + 1}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                title: Text(
                                                    "Tracking ID: ${order['return_tracking_id']}"),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        "Order ID: ${order['amazon_order_id']}"),
                                                    Text(
                                                        "OTP: ${order['otp']}"),
                                                  ],
                                                ),
                                                trailing: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    order['bad_good_return'] ==
                                                            "bad"
                                                        ? Icon(
                                                            Icons
                                                                .sentiment_neutral_sharp,
                                                            color:
                                                                Colors.orange)
                                                        : Icon(
                                                            Icons
                                                                .sentiment_very_satisfied_sharp,
                                                            color:
                                                                Colors.green),
                                                    Text(
                                                        order[
                                                            'bad_good_return'],
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ],
                                                ),
                                              ),
                                              // imageUrls.isNotEmpty
                                              //     ? SizedBox(
                                              //         height: 80,
                                              //         child: ListView.builder(
                                              //           scrollDirection:
                                              //               Axis.horizontal,
                                              //           itemCount:
                                              //               imageUrls.length,
                                              //           itemBuilder:
                                              //               (context, i) {
                                              //             return GestureDetector(
                                              //               onLongPress: () =>
                                              //                   showFullImage(
                                              //                       imageUrls[
                                              //                           i]),
                                              //               child: Padding(
                                              //                 padding:
                                              //                     const EdgeInsets
                                              //                         .symmetric(
                                              //                         horizontal:
                                              //                             5.0),
                                              //                 child:
                                              //                     Image.network(
                                              //                         imageUrls[
                                              //                             i],
                                              //                         height:
                                              //                             70,
                                              //                         width:
                                              //                             70),
                                              //               ),
                                              //             );
                                              //           },
                                              //         ),
                                              //       )
                                              //     : const SizedBox.shrink(),
                                            ],
                                          ),
                                        );
                                      },
                                    ))
                              : Center(
                                  child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/no_internet_image.png',
                                      height: 150,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      "No Internet Connection",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    )
                                  ],
                                )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
