import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:track_wealth/common/constants.dart';

class DashboardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, Colors.black, AppColor.white);

    return SafeArea(
      child: Container(
        color: bgColor,
        child: Shimmer.fromColors(
          highlightColor: Color(0xffcdd5d5),
          baseColor: Color(0xff595a5c),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    ShimmerContainer(width: 40, height: 35),
                    SizedBox(width: 10),
                    Expanded(child: ShimmerContainer(height: 35)),
                    SizedBox(width: 10),
                    ShimmerContainer(width: 70, height: 35),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerContainer(height: 70, width: 250),
                    Spacer(),
                    ShimmerContainer(width: 40, height: 35),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(child: ShimmerContainer())
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AmountRowShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Shimmer.fromColors(
          baseColor: Color(0xff283048),
          highlightColor: Color(0xff859398),
          child: ShimmerContainer(),
        ));
  }
}

class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;
  final Color? color;

  const ShimmerContainer({this.width, this.height, this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: roundedBoxDecoration.copyWith(color: color ?? Colors.grey.withOpacity(.3)),
      width: width,
      height: height,
      child: child,
    );
  }
}
