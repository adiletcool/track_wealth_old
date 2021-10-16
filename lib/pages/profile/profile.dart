import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/decorations.dart';
import 'package:track_wealth/pages/dashboard/portfolio/add_portfolio.dart';

class ProfilePage extends StatefulWidget {
  final List<Portfolio> portfolios;
  final TabController tabController;
  const ProfilePage({required this.portfolios, required this.tabController});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String userName;
  late final List<Portfolio> portfolios;

  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    setUserName(auth.currentUser!);
    portfolios = widget.portfolios;
  }

  void setUserName(User firebaseUser) {
    if (!["", null].contains(firebaseUser.displayName))
      userName = firebaseUser.displayName!;
    else if (!["", null].contains(firebaseUser.email))
      userName = firebaseUser.email!.split('@').first;
    else if (!["", null].contains(firebaseUser.phoneNumber))
      userName = firebaseUser.phoneNumber!;
    else
      userName = 'Default name';
  }

  List<Widget> getPortfolioCards() {
    List<Widget> portfolioCards = portfolios.map((p) => PortfolioCard(portfolio: p, isSelected: p.isSelected, tabController: widget.tabController)).toList();
    portfolioCards.add(PortfolioCard());
    return portfolioCards;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    maxLines: 2,
                  ),
                  // TODO: убать иконку, добавить logout
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: FaIcon(
                      FontAwesomeIcons.userTie,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppColor.lightGrey, thickness: 1),
                  Text(
                    'Портфели',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 15),
                  Wrap(
                    alignment: WrapAlignment.start,
                    runSpacing: 20,
                    spacing: 20,
                    children: getPortfolioCards(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PortfolioCard extends StatelessWidget {
  final Portfolio? portfolio;
  final bool isSelected;
  final TabController? tabController;

  const PortfolioCard({this.portfolio, this.tabController, this.isSelected = false});

  Widget portfolioCard() {
    return Column(
      children: [
        Text(
          portfolio!.name,
        )
      ],
    );
  }

  Widget addPortfolioCard() => Center(child: FaIcon(FontAwesomeIcons.plus));

  void addNewPortfolio(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/dashboard/add_portfolio',
      arguments: AddPortfolioArgs(title: 'Новый портфель', isFirstPortfolio: false),
    );
  }

  void onTap(BuildContext context) {
    if (portfolio != null) {
      if (portfolio!.isSelected)
        tabController!.animateTo(0);
      else
        context.read<PortfolioState>().changeSelectedPortfolio(portfolio!.name);
    } else {
      addNewPortfolio(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        decoration: roundedBoxDecoration.copyWith(
          color: AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey),
          border: Border.all(width: 1, color: isSelected ? AppColor.selected : AppColor.darkGrey),
        ),
        height: 120,
        width: MediaQuery.of(context).size.width / 2 - 30,
        child: portfolio == null ? addPortfolioCard() : portfolioCard(),
      ),
      onTap: () => onTap(context),
    );
  }
}
