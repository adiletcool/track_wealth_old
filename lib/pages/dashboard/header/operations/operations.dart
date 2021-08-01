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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColor.grey,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OperationButton(
            child: Text('+', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            onTap: addOperation,
          ),
          SizedBox(width: 20),
          OperationButton(child: Icon(Icons.mode_edit)),
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
  const OperationButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: child,
    );
  }
}
