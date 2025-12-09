import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenViewState();
}

class _AboutScreenViewState extends State<AboutScreen> {
  final ScrollController _scrollController = ScrollController();

  // Compact iOS-style typography (smaller sizes + tighter line height)
  static const TextStyle _titleStyle = TextStyle(
    color: CupertinoColors.black,
    fontSize: 22, // smaller title for compact look
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle _headingStyle = TextStyle(
    color: CupertinoColors.black,
    fontWeight: FontWeight.w500,
    fontSize: 15, // smaller
    height: 1.25,
    letterSpacing: -0.3,
    decoration: TextDecoration.none,
  );

  static const TextStyle _bodyStyle = TextStyle(
    color: Color(0xFF3C3C43),
    fontWeight: FontWeight.w400,
    fontSize: 13, // smaller
    height: 1.30,
    letterSpacing: -0.08,
    decoration: TextDecoration.none,
  );

  static const TextStyle _emphasisStyle = TextStyle(
    color: CupertinoColors.black,
    fontWeight: FontWeight.w600,
    fontSize: 13, // smaller
    height: 1.30,
    letterSpacing: -0.08,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      // iOS navigation bar with chevron-only back button
      navigationBar: CupertinoNavigationBar(
        // Hide the default back label by supplying our own leading
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => Navigator.maybePop(context),
          child: const Icon(
            CupertinoIcons.back, // chevron-only
            size: 22,
            color: CupertinoColors.activeBlue,
          ),
        ),
        middle: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 16, // compact navbar title
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0x1F000000), width: 0.0), // subtle iOS hairline
        ),
        backgroundColor: CupertinoColors.white,
      ),
      child: SafeArea(
        bottom: false,
        child: CupertinoScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large page title under navbar (kept compact)
              // const Text('About Us', style: _titleStyle),
               // const SizedBox(height: 16),

                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "DeoDap ", style: _emphasisStyle),
                      TextSpan(
                        text:
                        "is a privately owned Indian trading and distribution company. "
                            "Our management has many years of experience in importing and distributing. "
                            "The basic function of the company is to source, market, and distribute best-selling products "
                            "from both domestic and overseas markets.",
                        style: _bodyStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "We strongly believe in promoting ", style: _bodyStyle),
                      const TextSpan(text: "Make In India", style: _emphasisStyle),
                      const TextSpan(text: " and work to achieve it.", style: _bodyStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text("Our plan of action:", style: _headingStyle),
                const SizedBox(height: 8),

                _bullet("Understand the need for imported products in India."),
                _bullet("If they sell well in India, import and test them in online marketplaces."),
                _bullet("If there's a supply gap, encourage Indian manufacturers to produce similar lines and promote Make in India."),

                const SizedBox(height: 14),

                const Text(
                  "We are well established with professional sales, marketing, warehousing, and distribution operations. "
                      "We work with major wholesalers and independent retail operators, and we continuously source products "
                      "that can impact the Indian market.",
                  style: _bodyStyle,
                ),
                const SizedBox(height: 12),

                const Text(
                  "After fulfilling 50,00,000+ orders on marketplaces, we found an opportunity to connect with resellers "
                      "directly and pass commission savings as their profit.",
                  style: _bodyStyle,
                ),
                const SizedBox(height: 12),

                Text.rich(
                  TextSpan(
                    children: const [
                      TextSpan(text: "Today, we are one of the best sellers on ", style: _bodyStyle),
                      TextSpan(text: "Amazon, Flipkart, Meesho, ", style: _emphasisStyle),
                      TextSpan(text: "and other major e-commerce platforms.", style: _bodyStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "We do not rely on vendors' inventory. We hold our own stock to ensure competitive pricing and reliable service.",
                  style: _bodyStyle,
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small iOS dot
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0x993C3C43),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Text(text, style: _bodyStyle)),
        ],
      ),
    );
  }
}
