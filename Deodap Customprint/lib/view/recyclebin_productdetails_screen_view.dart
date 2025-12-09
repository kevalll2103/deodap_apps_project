import 'package:flutter/material.dart';

class RecyclebinProductDetailsScreen extends StatelessWidget {
  final String orderId;
  final String productName;
  final String productImage;
  final String orderDate;
  final String productDescription;
  final String orderStatus;
  final String price;

  const RecyclebinProductDetailsScreen({
    Key? key,
    required this.orderId,
    required this.productName,
    required this.productImage,
    required this.orderDate,
    required this.productDescription,
    required this.orderStatus,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin Details'),
        backgroundColor: Colors.red.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with loading and error states
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    productImage,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Product Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Divider
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 12),

                    // Order Details
                    _buildDetailRow(
                      icon: Icons.receipt,
                      label: 'Order ID:',
                      value: orderId,
                    ),
                    const SizedBox(height: 8),

                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date:',
                      value: orderDate,
                    ),
                    const SizedBox(height: 8),

                    _buildDetailRow(
                      icon: Icons.paid,
                      label: 'Price:',
                      value: '₹$price',
                      valueStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildDetailRow(
                      icon: Icons.info,
                      label: 'Status:',
                      value: orderStatus,
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: orderStatus.toLowerCase() == 'deleted'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Divider
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 12),

                    // Product Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productDescription.isNotEmpty
                          ? productDescription
                          : 'No description available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showRecoverConfirmationDialog(context);
                      },
                      icon: const Icon(Icons.restore, size: 20),
                      label: const Text('RECOVER', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmationDialog(context);
                      },
                      icon: const Icon(Icons.delete_forever, size: 20),
                      label: const Text('DELETE', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: valueStyle ?? const TextStyle(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRecoverConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recover Order'),
          content: const Text('Are you sure you want to recover this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRecoverySuccess(context);
              },
              child: const Text('Recover', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permanently Delete'),
          content: const Text('This action cannot be undone. Are you sure you want to permanently delete this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeletionSuccess(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRecoverySuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order recovered successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    // Here you would typically call your API to recover the order
    // After successful recovery, you might want to navigate back
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context, true); // Return true to indicate recovery
    });
  }

  void _showDeletionSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order permanently deleted!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    // Here you would typically call your API to delete the order
    // After successful deletion, you might want to navigate back
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context, true); // Return true to indicate deletion
    });
  }
}