import 'package:planify/struct/appState.dart';
import 'dart:math';
import 'package:planify/functions.dart';
import 'package:planify/main.dart';
import 'package:planify/pages/onBoardingPage.dart';
import 'package:planify/struct/settings.dart';
import 'package:planify/widgets/framework/pageFramework.dart';
import 'package:planify/widgets/navigationSidebar.dart';
import 'package:planify/widgets/openBottomSheet.dart';
import 'package:planify/widgets/tappable.dart';
import 'package:planify/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planify/colors.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    bool fullScreenLayout = enableDoubleColumn(context);
    Color containerColor = appStateSettings["materialYou"]
        ? dynamicPastel(
            context, Theme.of(context).colorScheme.secondaryContainer,
            amountLight: 0.2, amountDark: 0.6)
        : getColor(context, "lightDarkAccent");

    List<Widget> developmentTeam = [
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 7),
        child: Center(
          child: TextFont(
            text: "development-team".tr(),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ),
      ),
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
        child: Tappable(
          onTap: () {
            openUrl('https://github.com/jameskokoska/planify');
          },
          onLongPress: () {
            copyToClipboard("https://github.com/jameskokoska/planify");
          },
          color: containerColor,
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 13, vertical: 15),
            child: Column(
              children: [
                TextFont(
                  text: "lead-developer".tr(),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
                TextFont(
                  text: "Développé par Gottlieb ADIBOLO au Togo",
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
                TextFont(
                  text: "https://github.com/jameskokoska/planify",
                  fontSize: 16,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  textColor: getColor(context, "textLight"),
                ),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
        child: Tappable(
          onTap: () {},
          color: containerColor,
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 13, vertical: 15),
            child: Column(
              children: [
                TextFont(
                  text: "database-designer".tr(),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
                TextFont(
                  text: "YuYing",
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    List<Widget> country = [
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 7),
        child: Center(
          child: TextFont(
            text: "Country",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ),
      ),
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
        child: Tappable(
          color: containerColor,
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 13, vertical: 15),
            child: TextFont(
              text: "Togo",
              fontSize: 18,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
      ),
    ];

    List<Widget> apisUsed = [
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 7),
        child: Center(
          child: TextFont(
            text: "APIs Used",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ),
      ),
      AboutInfoBox(
        title: "Flutter",
        link: "https://flutter.dev/",
        padding: fullScreenLayout
            ? EdgeInsetsDirectional.symmetric(horizontal: 7.5, vertical: 5)
            : null,
      ),
      AboutInfoBox(
        title: "Google Cloud APIs",
        link: "https://cloud.google.com/",
        padding: fullScreenLayout
            ? EdgeInsetsDirectional.symmetric(horizontal: 7.5, vertical: 5)
            : null,
      ),
      AboutInfoBox(
        title: "Drift SQL Database",
        link: "https://drift.simonbinder.eu/",
        padding: fullScreenLayout
            ? EdgeInsetsDirectional.symmetric(horizontal: 7.5, vertical: 5)
            : null,
      ),
      AboutInfoBox(
        title: "FL Charts",
        link: "https://github.com/imaNNeoFighT/fl_chart",
        padding: fullScreenLayout
            ? EdgeInsetsDirectional.symmetric(horizontal: 7.5, vertical: 5)
            : null,
      ),
      AboutInfoBox(
        title: "exchange-rates-api".tr(),
        link: "https://github.com/fawazahmed0/exchange-api",
        padding: fullScreenLayout
            ? EdgeInsetsDirectional.symmetric(horizontal: 7.5, vertical: 5)
            : null,
      ),
    ];

    List<Widget> fonts = [
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 7),
        child: Center(
          child: TextFont(
            text: "Fonts",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ),
      ),
      AboutInfoBox(
        title: "Fonts Used",
        list: [
          "Avenir LT Std (Black, Roman)",
          "DM Sans (Bold, Regular)",
          "Inconsolata (Bold, Regular)",
          "Inter (Bold, Regular)",
          "Metropolis (Bold, Regular)",
          "Roboto Condensed (Bold, Regular)"
        ],
        padding: EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
      ),
    ];

    List<Widget> tutorial = [
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 7),
        child: Center(
          child: TextFont(
            text: "Tutorial",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ),
      ),
      Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
        child: Tappable(
          onTap: () => openOnBoarding(context),
          color: containerColor,
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 13, vertical: 15),
            child: TextFont(
              text: "View App Introduction",
              fontSize: 18,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
      ),
    ];

    return PageFramework(
      dragDownToDismiss: true,
      title: "about".tr(),
      getExtraHorizontalPadding: (context) {
        double maxWidth = 900;
        double widthOfScreen = MediaQuery.sizeOf(context).width -
            getWidthNavigationSidebar(context);
        return enableDoubleColumn(context)
            ? max(0, (widthOfScreen - maxWidth) / 2)
            : getHorizontalPaddingConstrained(context);
      },
      listWidgets: [
        ...developmentTeam,
        SizedBox(height: 10),
        ...country,
        SizedBox(height: 10),
        ...apisUsed,
        SizedBox(height: 10),
        ...fonts,
        SizedBox(height: 10),
        ...tutorial,
      ],
    );
  }
}

void openOnBoarding(BuildContext context) {
  pushRoute(
    context,
    OnBoardingPage(
      popNavigationWhenDone: true,
      showPreviewDemoButton: false,
    ),
  );
}

class AboutInfoBox extends StatelessWidget {
  const AboutInfoBox({
    Key? key,
    required this.title,
    this.link,
    this.list,
    this.color,
    this.listTextColor,
    this.padding,
    this.showLink = true,
  }) : super(key: key);

  final String title;
  final String? link;
  final List<String>? list;
  final Color? color;
  final Color? listTextColor;
  final EdgeInsetsGeometry? padding;
  final bool showLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 5),
      child: Tappable(
        onTap: () async {
          if (link != null) openUrl(link ?? "");
        },
        onLongPress: () {
          if (link != null) copyToClipboard(link ?? "");
        },
        color: color ??
            (appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent")),
        borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 13, vertical: 15),
          child: Column(
            children: [
              TextFont(
                text: title,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
              SizedBox(height: 6),
              if (link != null && showLink)
                TextFont(
                  text: link ?? "",
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                  maxLines: 1,
                ),
              for (String item in list ?? [])
                TextFont(
                  text: item,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  textColor: listTextColor ?? getColor(context, "textLight"),
                  maxLines: 10,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
