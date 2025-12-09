import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notes_service.dart';

class CallActionSheet extends StatefulWidget {
  final String phoneNumber;
  final String? contactName;
  final VoidCallback? onNotesUpdated;

  const CallActionSheet({
    Key? key,
    required this.phoneNumber,
    this.contactName,
    this.onNotesUpdated,
  }) : super(key: key);

  @override
  State<CallActionSheet> createState() => _CallActionSheetState();
}

class _CallActionSheetState extends State<CallActionSheet> 
    with TickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoadingNotes = true;
  bool _isSavingNotes = false;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _buttonController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotes();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    // Main slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Button scale animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
    

  }
  
  void _startEntryAnimation() async {
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _buttonController.forward();
  }

  Future<void> _loadNotes() async {
    final notes = await NotesService.getNotes(widget.phoneNumber);
    if (mounted) {
      setState(() {
        _notesController.text = notes;
        _isLoadingNotes = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    
    final success = await NotesService.saveNotes(widget.phoneNumber, _notesController.text);
    
    if (mounted) {
      setState(() => _isSavingNotes = false);
      
      if (success) {
        widget.onNotesUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }





  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced handle bar with animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            
            // Enhanced header with gradient background
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBrown.withOpacity(0.1),
                      AppTheme.accentBrown.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBrown.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Contact avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBrown, AppTheme.accentBrown],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBrown.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.contactName ?? 'Unknown Contact',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryBrown.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.phoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            

          
          // Enhanced notes section with animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBrown.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note_alt,
                            color: AppTheme.primaryBrown,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBrown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoadingNotes)
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryBrown,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading notes...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Add notes about this contact...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Enhanced save notes button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingNotes ? null : _saveNotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: AppTheme.primaryBrown.withOpacity(0.3),
                        ),
                        child: _isSavingNotes
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Saving...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Notes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20 + MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    ));
  }


}