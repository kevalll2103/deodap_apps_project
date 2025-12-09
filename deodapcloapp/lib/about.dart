import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenViewState();
}

class _AboutScreenViewState extends State<AboutScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final headingStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    final bodyStyle = TextStyle(color: Colors.black87);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          children: [
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 5,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: "DeoDap ", style: headingStyle),
                          TextSpan(
                            text:
                            "is a privately owned Indian trading and distribution company. Our management has many years experience in the fields of importing and distributing. The basic function of the company is to source, market and distribute Best Selling Products of marketplace from both the domestic and overseas markets.",
                            style: bodyStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: "We strongly believe in promoting ", style: bodyStyle),
                          TextSpan(text: "Make In India", style: headingStyle),
                          TextSpan(text: " mission and to achieve it.", style: bodyStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Our plan of action is", style: headingStyle),
                    const SizedBox(height: 8),
                    bullet("Understand the need of Imported products in India."),
                    bullet("If they are sold well in India, import and test them in the online marketplace."),
                    bullet("If there's supply gap, we encourage Indian manufacturers to produce similar lines and promote Make in India."),
                    const SizedBox(height: 12),
                    Text(
                      "We are well established with a highly professional sales, marketing, warehousing, and distribution operation. We deal with major wholesalers and independent retail operators. We continuously source potential products that can impact the Indian market.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "After fulfilling 50,00,000+ orders on marketplaces, we found an opportunity to connect with resellers directly and pass commission savings as their profit.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: "Today, we are one of the best sellers on ", style: bodyStyle),
                          TextSpan(
                            text: "Amazon, Flipkart, Meesho, ",
                            style: headingStyle,
                          ),
                          TextSpan(text: "and other major e-commerce platforms.", style: bodyStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We do not rely on vendors’ inventory. We hold our own stock to ensure competitive pricing and reliable service.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("\u2022 ", style: TextStyle(fontSize: 18, color: Colors.black)),
          Expanded(child: Text(text, style: TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
