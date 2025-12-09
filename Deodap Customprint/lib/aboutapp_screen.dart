import 'package:flutter/material.dart';

class AboutappScreen extends StatefulWidget {
  const AboutappScreen({super.key});

  @override
  State<AboutappScreen> createState() => _AboutappScreenState();
}

class _AboutappScreenState extends State<AboutappScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "About App",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0B90A1),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/deodap_logo.png'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "About Deodap",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B90A1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Deodap is a leading Indian trading and distribution company with years of experience in importing and distributing best-selling products. "
                          "We specialize in sourcing, marketing, and distributing high-quality products from both domestic and international markets.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Our Mission",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B90A1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "We strongly believe in promoting the 'Make In India' mission. Our approach is:",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "• Identify imported products with high demand in India",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Test market demand through e-commerce platforms",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Support Indian manufacturers to create similar products",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Reduce import dependency and promote local manufacturing",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Our Achievements",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B90A1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "• Successfully fulfilled over 5,000,000+ orders across e-commerce platforms\n"
                          "• Top-rated seller on Amazon, Flipkart, Meesho, and other major marketplaces\n"
                          "• Maintain our own warehouses for faster and more reliable fulfillment\n"
                          "• Direct partnerships with manufacturers for best pricing\n"
                          "• Established distribution network across India",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Our Business Model",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B90A1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Unlike traditional sellers, we maintain our own inventory to ensure:",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "• Competitive pricing for customers",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Faster delivery times",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Better quality control",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Direct connection with resellers",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Our Vision",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B90A1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "To become India's most trusted distribution partner by:",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "• Continuously expanding our product portfolio",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Investing in technology for better operations",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Supporting local manufacturers and 'Make in India'",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Creating value for our partners and customers",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Center(
                      child: Text(
                        "For more information, visit:\nhttps://deodap.in",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF0B90A1),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}