import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:medbot_ai_app/utils/status_utils.dart';

class AuditCard extends StatelessWidget {
  final Widget child;
  final int status;
  final VoidCallback? onTap; // 可选点击回调
  const AuditCard({
    super.key,
    required this.child,
    this.status = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 110,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 221, 226, 221),
          borderRadius: BorderRadius.circular(16),
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: child,
                // child: Column(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: <Widget>[child],
                // ),
              ),
              Positioned(
                top: 10,
                right: -30,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 100,
                    height: 24,
                    color: StatusUtils.getStatusColor(status),
                    child: Text(
                      StatusUtils.getStatusText(context, status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
