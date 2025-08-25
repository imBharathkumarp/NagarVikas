import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';

class PollCreationWidget extends StatefulWidget {
  final Function(String, List<String>, bool) onPollCreated;
  final ThemeProvider themeProvider;

  const PollCreationWidget({
    super.key,
    required this.onPollCreated,
    required this.themeProvider,
  });

  @override
  _PollCreationWidgetState createState() => _PollCreationWidgetState();
}

class _PollCreationWidgetState extends State<PollCreationWidget> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleAnswers = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
      // Scroll to bottom to show new option
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      _showError('Please enter a question');
      return;
    }

    if (options.length < 2) {
      _showError('Please provide at least 2 options');
      return;
    }

    widget.onPollCreated(question, options, _allowMultipleAnswers);
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: widget.themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2196F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.poll,
                      color: Color(0xFF2196F3),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create Poll',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: widget.themeProvider.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question input
                    Text(
                      'Question',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.themeProvider.isDarkMode
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: TextField(
                        controller: _questionController,
                        style: TextStyle(
                          color: widget.themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 16,
                        ),
                        maxLines: 3,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: TextStyle(
                            color: widget.themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[500],
                          ),
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color: widget.themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Options section
                    Row(
                      children: [
                        Text(
                          'Options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${_optionControllers.length}/10',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Option inputs
                    ...List.generate(_optionControllers.length, (index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: widget.themeProvider.isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: widget.themeProvider.isDarkMode
                                        ? Colors.grey[600]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: TextField(
                                  controller: _optionControllers[index],
                                  style: TextStyle(
                                    color: widget.themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLength: 100,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'Option ${index + 1}',
                                    hintStyle: TextStyle(
                                      color: widget.themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ),
                            if (_optionControllers.length > 2) ...[
                              SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _removeOption(index),
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Remove option',
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    // Add option button
                    if (_optionControllers.length < 10)
                      GestureDetector(
                        onTap: _addOption,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF2196F3).withOpacity(0.3),
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add Option',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 24),

                    // Multiple answers toggle
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_box_outline_blank,
                            color: widget.themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allow Multiple Answers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: widget.themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Users can select more than one option',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _allowMultipleAnswers,
                            onChanged: (value) {
                              setState(() {
                                _allowMultipleAnswers = value;
                              });
                            },
                            activeColor: Color(0xFF2196F3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: widget.themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _createPoll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Create Poll',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}