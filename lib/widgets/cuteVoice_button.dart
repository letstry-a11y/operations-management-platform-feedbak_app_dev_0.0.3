import 'package:flutter/material.dart';

class CuteVoiceButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const CuteVoiceButton({
    Key? key,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 让 InkWell 波纹生效
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.pinkAccent.withOpacity(0.2),
        highlightColor: Colors.pink.withOpacity(0.1),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 400),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [Color(0xFFFFD6E8), Color(0xFFFFB6C1)]
                  : [Color(0xFFB5F8D0), Color(0xFFB0E0E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.pinkAccent : Colors.tealAccent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(3, 5),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.mic : Icons.mic_none,
                color: isActive ? Colors.pinkAccent : Colors.teal,
              ),
              SizedBox(width: 8),
              Text(
                isActive ? '正在聆听...' : '点击说话',
                style: TextStyle(
                  fontSize: 16,
                  color: isActive ? Colors.pink[700] : Colors.teal[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
