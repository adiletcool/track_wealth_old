import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:track_wealth/common/constants.dart';

import 'add_operation_dialog/add_operation_dialog.dart';

class Operations extends StatefulWidget {
  @override
  _OperationsState createState() => _OperationsState();
}

class _OperationsState extends State<Operations> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? AppColor.bgDark : AppColor.grey;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: bgColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OperationButton(
            child: Icon(Icons.add_circle_rounded, size: 28),
            onTap: addOperation,
          ),
          SizedBox(width: 10),
          OperationButton(child: Icon(Icons.mode_edit, size: 28)),
        ],
      ),
    );
  }

  void addOperation() {
    showDialog(
      context: context,
      builder: (context) {
        return AddOperationDialog();
      },
    );
  }
}

class OperationButton extends StatelessWidget {
  final Widget child;
  final void Function()? onTap;
  // final
  const OperationButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: child,
      ),
    );
  }
}
