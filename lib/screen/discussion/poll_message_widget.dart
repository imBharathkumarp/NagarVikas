import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'forum_logic.dart';

class PollMessageWidget extends StatefulWidget {
  final Map<String, dynamic> pollData;
  final bool isMe;
  final ThemeProvider themeProvider;
  final String currentUserId;
  final VoidCallback? onVotesUpdated;

  const PollMessageWidget({
    super.key,
    required this.pollData,
    required this.isMe,
    required this.themeProvider,
    required this.currentUserId,
    this.onVotesUpdated,
  });

  @override
  _PollMessageWidgetState createState() => _PollMessageWidgetState();
}

class _PollMessageWidgetState extends State<PollMessageWidget>
    with SingleTickerProviderStateMixin {
  late DatabaseReference _pollRef;
  Map<String, dynamic>? _pollDetails;
  Map<String, List<String>> _votes = {}; // option -> list of user IDs
  Set<String> _userVotes = {}; // options voted by current user
  int _totalVotes = 0;
  bool _hasVoted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pollRef =
        FirebaseDatabase.instance.ref("polls/${widget.pollData['pollId']}");
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadPollData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPollData() {
    _pollRef.onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _pollDetails = data;
          _loadVotes(data);
        });
      }
    });
  }

  void _loadVotes(Map<String, dynamic> pollData) {
    _votes.clear();
    _userVotes.clear();
    _totalVotes = 0;

    if (pollData['votes'] != null) {
      final votesMap = Map<String, dynamic>.from(pollData['votes']);

      // Process votes for each option
      for (String option in pollData['options']) {
        _votes[option] = [];
        if (votesMap[option] != null) {
          final optionVotes = Map<String, dynamic>.from(votesMap[option]);
          _votes[option] = optionVotes.keys.toList();
          _totalVotes += optionVotes.length;

          // Check if current user voted for this option
          if (optionVotes.containsKey(widget.currentUserId)) {
            _userVotes.add(option);
          }
        }
      }
    }

    _hasVoted = _userVotes.isNotEmpty;
  }

  void _vote(String option) async {
    if (_pollDetails == null) return;

    final allowMultiple = _pollDetails!['allowMultipleAnswers'] ?? false;

    try {
      if (allowMultiple) {
        // Toggle vote for this option
        if (_userVotes.contains(option)) {
          // Remove vote
          await _pollRef
              .child('votes/$option/${widget.currentUserId}')
              .remove();
        } else {
          // Add vote
          await _pollRef.child('votes/$option/${widget.currentUserId}').set({
            'votedAt': ServerValue.timestamp,
            'voterName': widget.pollData['senderName'] ?? 'Unknown User',
          });
        }
      } else {
        // Single choice - remove all previous votes and add new one
        final updates = <String, dynamic>{};

        // Remove from all options
        for (String opt in _pollDetails!['options']) {
          if (_userVotes.contains(opt)) {
            updates['votes/$opt/${widget.currentUserId}'] = null;
          }
        }

        // Add to selected option
        updates['votes/$option/${widget.currentUserId}'] = {
          'votedAt': ServerValue.timestamp,
          'voterName': widget.pollData['senderName'] ?? 'Unknown User',
        };

        await _pollRef.update(updates);
      }

      if (widget.onVotesUpdated != null) {
        widget.onVotesUpdated!();
      }
    } catch (e) {
      print('Error voting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record vote. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show All Voters
  void _showAllVoters() {
    if (_totalVotes == 0) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: widget.themeProvider.isDarkMode
                  ? Colors.grey[850]
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.poll,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Poll Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              '${_totalVotes} ${_totalVotes == 1 ? 'vote' : 'votes'} total',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
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

                // Voters list organized by options
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: _votes.entries
                          .where((entry) => entry.value.isNotEmpty)
                          .map((entry) {
                        final option = entry.key;
                        final voters = entry.value;
                        final percentage = _getVotePercentage(option);

                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: widget.themeProvider.isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.themeProvider.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Option header
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(11)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: widget.themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2196F3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${(percentage * 100).toInt()}% (${voters.length})',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Voters for this option
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  children: voters.map((voterId) {
                                    return FutureBuilder<String>(
                                      future: _getVoterName(voterId),
                                      builder: (context, snapshot) {
                                        final voterName =
                                            snapshot.data ?? 'Loading...';
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 8),
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                widget.themeProvider.isDarkMode
                                                    ? Colors.grey[700]
                                                    : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color:
                                                      ForumLogic.getAvatarColor(
                                                          voterName),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    voterName.isNotEmpty
                                                        ? voterName[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  voterName,
                                                  style: TextStyle(
                                                    color: widget.themeProvider
                                                            .isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (voterId ==
                                                  widget.currentUserId)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF2196F3)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    'You',
                                                    style: TextStyle(
                                                      color: Color(0xFF2196F3),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getVoterName(String userId) async {
    try {
      // Try to get from poll votes first (which might have cached voter names)
      if (_pollDetails != null && _pollDetails!['votes'] != null) {
        final votesMap = Map<String, dynamic>.from(_pollDetails!['votes']);
        for (String option in votesMap.keys) {
          final optionVotes = Map<String, dynamic>.from(votesMap[option] ?? {});
          if (optionVotes.containsKey(userId) &&
              optionVotes[userId]['voterName'] != null) {
            return optionVotes[userId]['voterName'];
          }
        }
      }

      // Fallback to users database
      final userSnapshot = await FirebaseDatabase.instance
          .ref('users/$userId/displayName')
          .get();

      if (userSnapshot.exists) {
        return userSnapshot.value.toString();
      }

      return 'Unknown User';
    } catch (e) {
      print('Error getting voter name: $e');
      return 'Unknown User';
    }
  }

  double _getVotePercentage(String option) {
    if (_totalVotes == 0) return 0.0;
    return (_votes[option]?.length ?? 0) / _totalVotes;
  }

  Color _getOptionColor(String option, bool isSelected) {
    if (isSelected) {
      return Color(0xFF2196F3);
    } else if (_hasVoted) {
      // Show muted colors for unselected options when user has voted
      return widget.themeProvider.isDarkMode
          ? Colors.grey[600]!
          : Colors.grey[400]!;
    } else {
      // Default color for unvoted state
      return widget.themeProvider.isDarkMode
          ? Colors.grey[700]!
          : Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pollDetails == null) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2196F3),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final question = _pollDetails!['question'] ?? '';
    final options = List<String>.from(_pollDetails!['options'] ?? []);
    final allowMultiple = _pollDetails!['allowMultipleAnswers'] ?? false;
    final createdAt = _pollDetails!['createdAt'];

    final timeString = ForumLogic.formatTime(createdAt);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              minWidth: 280,
            ),
            decoration: BoxDecoration(
              gradient: widget.isMe
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                    )
                  : null,
              color: widget.isMe
                  ? null
                  : (widget.themeProvider.isDarkMode
                      ? Colors.grey[800]
                      : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft:
                    widget.isMe ? Radius.circular(18) : Radius.circular(4),
                bottomRight:
                    widget.isMe ? Radius.circular(4) : Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.themeProvider.isDarkMode
                      ? Colors.black26
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poll header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? Colors.white.withOpacity(0.2)
                              : Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.poll,
                          size: 16,
                          color: widget.isMe ? Colors.white : Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Poll',
                          style: TextStyle(
                            color: widget.isMe
                                ? Colors.white70
                                : (widget.themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (allowMultiple)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.isMe
                                ? Colors.white.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Multiple',
                            style: TextStyle(
                              color:
                                  widget.isMe ? Colors.white70 : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Question
                  Text(
                    question,
                    style: TextStyle(
                      color: widget.isMe
                          ? Colors.white
                          : (widget.themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Options
                  ...options.map((option) {
                    final isSelected = _userVotes.contains(option);
                    final voteCount = _votes[option]?.length ?? 0;
                    final percentage = _getVotePercentage(option);
                    final optionColor = _getOptionColor(option, isSelected);

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _vote(option),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: optionColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF2196F3)
                                    : optionColor.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Progress bar background
                                if (_hasVoted)
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 800),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.65 *
                                                percentage,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Color(0xFF2196F3)
                                                  .withOpacity(0.2)
                                              : optionColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Option content
                                Row(
                                  children: [
                                    // Selection indicator
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Color(0xFF2196F3)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Color(0xFF2196F3)
                                              : (widget.themeProvider.isDarkMode
                                                  ? Colors.grey[500]!
                                                  : Colors.grey[400]!),
                                          width: 2,
                                        ),
                                        borderRadius: allowMultiple
                                            ? BorderRadius.circular(4)
                                            : BorderRadius.circular(9),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              allowMultiple
                                                  ? Icons.check
                                                  : Icons.circle,
                                              color: Colors.white,
                                              size: allowMultiple ? 12 : 8,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 12),

                                    // Option text
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: widget.isMe
                                              ? (isSelected
                                                  ? Colors.white
                                                  : Colors.white70)
                                              : (widget.themeProvider.isDarkMode
                                                  ? (isSelected
                                                      ? Colors.white
                                                      : Colors.grey[300])
                                                  : (isSelected
                                                      ? Colors.black87
                                                      : Colors.grey[700])),
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    // Vote count and percentage
                                    if (_hasVoted) ...[
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.isMe
                                              ? Colors.white.withOpacity(0.2)
                                              : (widget.themeProvider.isDarkMode
                                                  ? Colors.grey[700]
                                                  : Colors.grey[100]),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${(percentage * 100).toInt()}% ($voteCount)',
                                          style: TextStyle(
                                            color: widget.isMe
                                                ? Colors.white70
                                                : (widget.themeProvider
                                                        .isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600]),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  SizedBox(height: 12),

                  // Poll footer
                  Row(
                    children: [
                      Icon(
                        Icons.how_to_vote,
                        size: 14,
                        color: widget.isMe
                            ? Colors.white70
                            : (widget.themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                      ),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: _totalVotes > 0 ? () => _showAllVoters() : null,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: _totalVotes > 0
                              ? BoxDecoration(
                                  color: widget.isMe
                                      ? Colors.white.withOpacity(0.1)
                                      : Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: widget.isMe
                                        ? Colors.white.withOpacity(0.3)
                                        : Color(0xFF2196F3).withOpacity(0.3),
                                    width: 1,
                                  ),
                                )
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _totalVotes == 0
                                    ? 'No votes yet'
                                    : _totalVotes == 1
                                        ? '1 vote'
                                        : '$_totalVotes votes',
                                style: TextStyle(
                                  color: widget.isMe
                                      ? Colors.white70
                                      : (widget.themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                  fontSize: 12,
                                  fontWeight: _totalVotes > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (_totalVotes > 0) ...[
                                SizedBox(width: 4),
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: widget.isMe
                                      ? Colors.white70
                                      : (widget.themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Spacer(),
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: TextStyle(
                            color: widget.isMe
                                ? Colors.white70
                                : (widget.themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
