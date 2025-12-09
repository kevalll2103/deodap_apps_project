// import 'package:Deodap_STrack/contactscreen.dart';
// import 'package:Deodap_STrack/exitentryscreen.dart';
// import 'package:Deodap_STrack/newentryscreen.dart';
// import 'package:Deodap_STrack/splashscreen.dart';
// import 'package:Deodap_STrack/updatescreen.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:loading_indicator/loading_indicator.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class Homescreen extends StatefulWidget {
//   const Homescreen({super.key});
//
//   @override
//   State<Homescreen> createState() => _HomescreenState();
// }
//
// class _HomescreenState extends State<Homescreen> {
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _checkAppVersion();
//   //   _scrollController = ScrollController();
//   //   fetchRecords();
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//
//     _scrollController = ScrollController();
//
//     // 👇 Add this listener right after initializing the controller
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels ==
//           _scrollController.position.maxScrollExtent &&
//           !isLoading &&
//           page < totalPage) {
//         page++;
//         fetchRecords(); // fetch next page
//       }
//     });
//
//     _checkAppVersion(); // Check update
//     fetchRecords(); // Load first page
//   }
//
//   String appVersion = "1.0.0";
//   String apiVersion = "";
//   bool isVersionMatched = false;
//   String errorMessage = ""; // 🔹 Add this line
//
//   Future<void> _checkAppVersion() async {
//     final url =
//         'https://customprint.deodap.com/api_sampleTrack/checkupdate.php'; // Replace with your actual API endpoint
//     try {
//       final response = await http.post(Uri.parse(url), body: {
//         'version': appVersion,
//       });
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         // Check if the versions match
//         if (data['status'] == 'success') {
//           setState(() {
//             apiVersion = appVersion;
//             isVersionMatched = true; // Versions match
//           });
//           // Show dialog with image URL from API
//           _checkUpdateDialog(data['image_url']);
//         } else {
//           setState(() {
//             isVersionMatched = false; // Versions don't match
//           });
//           // Handle error response
//           print('Error: ${data['message']}');
//         }
//       } else {
//         // Handle server error
//         print('Server error');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }
//
//   void _checkUpdateDialog(String imageUrl) {
//     if (!mounted) return; // Prevents calling showDialog on unmounted widget
//
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevents closing when tapping outside
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   Navigator.of(context).pop(); // Close dialog
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => Updatescreen(),
//                     ),
//                   );
//                 },
//                 child: Image.network(imageUrl),
//               ),
//               Positioned(
//                 top: 0.0,
//                 right: 0.0,
//                 child: Container(
//                   color: Colors.white,
//                   child: IconButton(
//                     icon: Icon(Icons.close, color: Colors.blue.shade900),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   String KEY_LOGIN = 'isLoggedIn';
//
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: Text(
//             'Logout....!!!',
//             style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             'Are you sure you want to logout?',
//             style: TextStyle(
//                 color: Colors.red.shade900, fontWeight: FontWeight.bold),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text(
//                 'NO',
//                 style: TextStyle(
//                     color: Colors.black, fontWeight: FontWeight.bold),
//               ),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop(); // Close the dialog
//               },
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(dialogContext).pop(); // Close the dialog
//
//                 OverlayEntry overlayEntry = OverlayEntry(
//                   builder: (context) =>
//                       Stack(
//                         children: [
//                           Container(
//                             color: Colors.black12.withOpacity(0.8),
//                             child: Center(
//                               child: CircularProgressIndicator(
//                                   color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                 );
//
//                 Overlay.of(context)!.insert(
//                     overlayEntry); // Use the original context
//                 try {
//                   await Future.delayed(Duration(seconds: 2));
//                   var shared = await SharedPreferences.getInstance();
//                   await shared.setBool(KEY_LOGIN, false);
//                   await Future.delayed(
//                       Duration(milliseconds: 100)); // Optional delay
//
//                   // Use the original context to navigate safely
//                   Navigator.of(context).pushReplacement(
//                     MaterialPageRoute(builder: (context) => Splashscreen()),
//                   );
//                 } finally {
//                   overlayEntry.remove();
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF0B90A1),
//               ),
//               child: Text(
//                 'YES',
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   List<dynamic> records = [];
//   int page = 1;
//   int totalPage = 1;
//   bool isLoading = false;
//   bool isOffline = false;
//
//   ScrollController _scrollController = ScrollController();
//   FocusNode _nameFocusNode = FocusNode();
//   TextEditingController _searchController = TextEditingController();
//
//
//   Future<void> checkConnectivity() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     setState(() {
//       isOffline = connectivityResult == ConnectivityResult.none;
//     });
//   }
//
//
//   Future<void> fetchRecords() async {
//     await checkConnectivity(); // Check internet first
//     if (isOffline) {
//       setState(() {
//         errorMessage = "No Internet Connection!";
//         records.clear();
//       });
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     var url = Uri.parse(
//         "https://tools.deodap.in/api/sample-product-api/product.php");
//
//     try {
//       var response = await http.post(url, body: {
//         "action": "list",
//         "page": page.toString(),
//         "search": _searchController.text,
//       });
//
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data["status"] == "success") {
//           // setState(() {
//           //   records = data["data"]; // Overwrite instead of adding
//           //   totalPage = data["total_page"];
//           //   errorMessage = records.isEmpty ? "No Data Found!" : "";
//           // });
//           //
//           // setState(() {
//           //   if (page == 1) {
//           //     records = data["data"].reversed.toList(); // First page: overwrite
//           //   } else {
//           //     records.addAll(data["data"].reversed); // Next pages: add newer first
//           //   }
//           //   totalPage = data["total_page"];
//           //   errorMessage = records.isEmpty ? "No Data Found!" : "";
//           // });
//            setState(() {
//            if (page == 1) {
//              records = data["data"]; // NO reverse here
//             } else {
//               records.addAll(data["data"]);
//              }
//             totalPage = data["total_page"];
//            errorMessage = records.isEmpty ? "No Data Found!" : "";
//                      });
//
//
//         }
//       } else {
//         setState(() {
//           errorMessage = "Failed to fetch data. Try again!";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = "No Internet Connection!";
//         isOffline = true;
//       });
//     }
//
//     setState(() => isLoading = false);
//   }
//
//   void searchRecords() {
//     setState(() {
//       records.clear();
//       page = 1;
//     });
//     fetchRecords();
//   }
//
//   Future<void> _refreshRecords() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     // Fetch updated records from the API
//     await fetchRecords();
//
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   @override
//   void dispose() {
//     _nameFocusNode.dispose();
//     super.dispose();
//   }
//
//   void _performSearch(String query) {
//     if (query.isNotEmpty) {
//       print("🔍 Searching for: $query");
//       searchRecords();
//     } else {
//       // Agar search bar khali ho gaya to original records wapas laao
//       setState(() {
//         records.clear();
//         page = 1;
//       });
//       fetchRecords(); // Ye original data fetch karega
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (_searchController.text.isNotEmpty) {
//           _searchController.clear();
//           FocusScope.of(context).unfocus();
//           setState(() {
//             records.clear();
//             page = 1;
//           });
//           fetchRecords();
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           centerTitle: true,
//           title: Text(
//             "Sample Inceptix",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Color(0xFF0B90A1),
//           leading: Builder(
//             builder: (BuildContext context) {
//               return IconButton(
//                 icon: Icon(Icons.menu, color: Colors.white),
//                 onPressed: () {
//                   FocusScope.of(context).unfocus();
//                   Scaffold.of(context).openDrawer();
//                 },
//               );
//             },
//           ),
//         ),
//         drawer: Drawer(
//           backgroundColor: Colors.white,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: <Widget>[
//               Expanded(
//                 child: ListView(
//                   padding: EdgeInsets.zero,
//                   children: <Widget>[
//                     Container(
//                       width: double.infinity,
//                       height: 230,
//                       color: Color(0xFF0B90A1),
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(height: 30),
//                             CircleAvatar(
//                               backgroundColor: Colors.grey,
//                               radius: 60,
//                               backgroundImage: AssetImage(
//                                   'assets/images/user_image.jpeg'),
//                             ),
//                             SizedBox(height: 10),
//                             Text(
//                               "Deodap Sample Tracking App",
//                               style: GoogleFonts.oswald(
//                                 textStyle: TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     ListTile(
//                       leading: Icon(Icons.phone, color: Colors.grey),
//                       title: Text("Contact Us",
//                           style: TextStyle(fontWeight: FontWeight.bold)),
//                       onTap: () {
//                         Navigator.pop(context);
//                         Navigator.push(context, MaterialPageRoute(builder: (
//                             context) => Contactscreen()));
//                       },
//                     ),
//                     ListTile(
//                       leading: Icon(Icons.logout, color: Colors.grey),
//                       title: Text("Logout",
//                           style: TextStyle(fontWeight: FontWeight.bold)),
//                       trailing: Icon(
//                           Icons.logout_outlined, color: Colors.red.shade900),
//                       onTap: () {
//                         Navigator.pop(context);
//                         _showLogoutDialog(context);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Text(
//                   'Version: 1.0.0',
//                   style: TextStyle(color: Colors.black54, fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         body: Stack(
//           children: [
//             Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(10),
//                   child: TextField(
//                     controller: _searchController,
//                     focusNode: _nameFocusNode,
//                     onChanged: (value) {
//                       _performSearch(value);
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search ID....',
//                       filled: true,
//                       prefixIcon: Icon(Icons.search),
//                       fillColor: Colors.grey[300],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                         borderSide: BorderSide(color: Colors.black, width: 2.0),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                         borderSide: BorderSide(color: Colors.black, width: 2.0),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                         borderSide: BorderSide(color: Colors.black, width: 2.5),
//                       ),
//                       suffixIcon: IconButton(
//                         icon: Icon(Icons.cancel, color: Colors.black),
//                         onPressed: () async {
//                           if (_searchController.text.isNotEmpty) {
//                             _searchController.clear();
//                             FocusScope.of(context).unfocus();
//                             setState(() {
//                               records.clear();
//                               page = 1;
//                             });
//                             await fetchRecords(); // 🔄 Await karo
//                             _scrollController.jumpTo(_scrollController.position.minScrollExtent);
//
//
//                           } else {
//                             FocusScope.of(context).unfocus();
//                           }
//                         },
//
//                       ),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                 ),
//                 isOffline
//                     ? Expanded(
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
//                             color: Colors.black, size: 100),
//                         SizedBox(height: 20),
//                         Text(
//                           "No Internet Connection..!",
//                           style: TextStyle(fontSize: 20, fontWeight: FontWeight
//                               .bold, color: Colors.black),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//                : Expanded(
//                   child: RefreshIndicator(
//                     onRefresh: _refreshRecords,
//                     color: Colors.white,
//                     backgroundColor: Color(0xFF0B90A1),
//                     child: isLoading
//                         ? Center(
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         backgroundColor: Color(0xFF0B90A1),
//                       ),
//                     )
//                         : records.isEmpty
//                         ? SingleChildScrollView(
//                       physics: AlwaysScrollableScrollPhysics(),
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(height: 150),
//                             Icon(Icons.warning_amber_rounded,
//                                 color: Colors.black, size: 100),
//                             SizedBox(height: 20),
//                             Text(
//                               "No Data Found!",
//                               style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                         : ListView.builder(
//                      // reverse: true,
//                       controller: _scrollController,
//                       itemCount: records.length + 1,
//                       itemBuilder: (context, index) {
//                         if (index == records.length) {
//                           return isLoading
//                               ? Center(
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               backgroundColor: Color(0xFF0B90A1),
//                             ),
//                           )
//                               : SizedBox();
//                         }
//
//                         var record = records[index]; // 👈 Define it here
//                         bool isPending = record['exit_taken_by'].toString().isEmpty;
//
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 1),
//                           child: Card(
//                             color: Colors.grey[200],
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               side: BorderSide(color: Colors.black26, width: 1),
//                             ),
//                             child: ListTile(
//                                leading: CircleAvatar(
//                                  radius: 15,
//                                  backgroundColor: Color(0xFF0B90A1),
//                                  child: Text(
//                                    "${record['id']}",
//                               style: TextStyle(
//                                       color: Colors.white, fontSize: 14),
//                                  ),
//                               ),
//
//                               // leading: CircleAvatar(
//                               //   radius: 15,
//                               //   backgroundColor: Color(0xFF0B90A1),
//                               //   child: Text(
//                               //     "${records.length - index}", // 👈 Countdown numbering
//                               //     style: TextStyle(color: Colors.white, fontSize: 14),
//                               //   ),
//                               // ),
//
//                               contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 10),
//                               subtitle: Text(
//                                 "Entry Name: ${record['received_from']}\n"
//                                     "Entry Date: ${record['received_datetime']}"
//                                     "${(record['exit_taken_by']
//                                     .toString()
//                                     .isNotEmpty && record['exit_datetime']
//                                     .toString()
//                                     .isNotEmpty)
//                                     ? "\nExit Name: ${record['exit_taken_by']}\nExit Date: ${record['exit_datetime']}"
//                                     : ""}",
//                                 style: TextStyle(
//                                     color: Colors.black87, fontSize: 12),
//                               ),
//                               trailing: Icon(
//                                 isPending ? Icons.access_time : Icons
//                                     .check_circle,
//                                 color: isPending ? Colors.orange : Colors.green,
//                               ),
//                               onTap: () {
//                                 FocusScope.of(context).unfocus();
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         Exitentryscreen(
//                                           id: record['id'].toString(),
//                                           receivedFrom: record['received_from'],
//                                           receivedDatetime: record['received_datetime'],
//                                           isPending: isPending.toString(),
//                                         ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // Floating Action Button
//             Positioned(
//               bottom: 30,
//               right: 20,
//               child: FloatingActionButton(
//                 backgroundColor: Color(0xFF0B90A1),
//                 onPressed: () async {
//                   FocusScope.of(context).unfocus();
//                   await Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => Newentryscreen()),
//                   );
//                 },
//                 child: Icon(Icons.add, color: Colors.white, size: 35),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
import 'package:Deodap_STrack/contactscreen.dart';
import 'package:Deodap_STrack/exitentryscreen.dart';
import 'package:Deodap_STrack/newentryscreen.dart';
import 'package:Deodap_STrack/splashscreen.dart';
import 'package:Deodap_STrack/updatescreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String appVersion = "1.0.0";
  String apiVersion = "";
  bool isVersionMatched = false;
  String errorMessage = "";

  final String KEY_LOGIN = 'isLoggedIn';

  List<dynamic> records = [];
  int page = 1;
  int totalPage = 1;
  bool isLoading = false;
  bool isOffline = false;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _nameFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !isLoading &&
          page < totalPage) {
        page++;
        fetchRecords();
      }
    });
    _checkAppVersion();
    fetchRecords();
  }

  Future<void> _checkAppVersion() async {
    final url = 'https://customprint.deodap.com/api_sampleTrack/checkupdate.php';
    try {
      final response = await http.post(Uri.parse(url), body: {'version': appVersion});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            apiVersion = appVersion;
            isVersionMatched = true;
          });
          _checkUpdateDialog(data['image_url']);
        } else {
          setState(() => isVersionMatched = false);
        }
      }
    } catch (_) {}
  }

  void _checkUpdateDialog(String imageUrl) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (_) => Updatescreen()));
              },
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.blue.shade900),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => isOffline = result == ConnectivityResult.none);
    }
  }

  Future<void> fetchRecords() async {
    await checkConnectivity();
    if (isOffline) {
      if (mounted) {
        setState(() {
          errorMessage = "No Internet Connection!";
          records.clear();
          isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => isLoading = true);

    final url = Uri.parse("https://tools.deodap.in/api/sample-product-api/product.php");
    try {
      final response = await http.post(url, body: {
        "action": "list",
        "page": page.toString(),
        "search": _searchController.text,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          if (mounted) {
            setState(() {
              if (page == 1) {
                records = data["data"].reversed.toList();
              } else {
                records.addAll(data["data"].reversed);
              }
              totalPage = data["total_page"];
              errorMessage = records.isEmpty ? "No Data Found!" : "";
            });
            if (page == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                }
              });
            }
          }
        }
      } else {
        if (mounted) setState(() => errorMessage = "Failed to fetch data. Try again!");
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = "No Internet Connection!";
          isOffline = true;
        });
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _refreshRecords() async {
    if (mounted) {
      setState(() {
        page = 1;
        records.clear();
      });
    }
    await fetchRecords();
  }

  void _performSearch(String query) {
    if (mounted) {
      setState(() {
        records.clear();
        page = 1;
      });
    }
    fetchRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0B90A1),
        centerTitle: true,
        title: Text("Sample Inceptix", style: TextStyle(color: Colors.white)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0B90A1)),
              accountName: Text("Deodap Sample Tracking App"),
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/images/user_image.jpeg'),
              ),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text("Contact Us"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Contactscreen())),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              trailing: Icon(Icons.logout_outlined, color: Colors.red.shade900),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              focusNode: _nameFocusNode,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search ID....',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    _performSearch('');
                    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Expanded(
            child: isOffline
                ? Center(child: Text("No Internet Connection!"))
                : RefreshIndicator(
              onRefresh: _refreshRecords,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: records.length + 1,
                itemBuilder: (context, index) {
                  if (index == records.length) {
                    return isLoading
                        ? Center(child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ))
                        : SizedBox();
                  }
                  final record = records[index];
                  final isPending = record['exit_taken_by'].toString().isEmpty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      color: Colors.grey[100],
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF0B90A1),
                          child: Text("${index + 1}", style: TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                          "Entry: ${record['received_from']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Date: ${record['received_datetime']}"
                              "${isPending ? '' : "\nExit: ${record['exit_taken_by']}\nExit Date: ${record['exit_datetime']}"}",
                        ),
                        trailing: Icon(
                          isPending ? Icons.access_time : Icons.check_circle,
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Exitentryscreen(
                                id: record['id'].toString(),
                                receivedFrom: record['received_from'],
                                receivedDatetime: record['received_datetime'],
                                isPending: isPending.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF0B90A1),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Newentryscreen())),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: Text("No"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              var prefs = await SharedPreferences.getInstance();
              await prefs.setBool(KEY_LOGIN, false);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Splashscreen()));
            },
            child: Text("Yes"),
          )
        ],
      ),
    );
  }
}
