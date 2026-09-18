import 'package:flutter/material.dart';

import '../home/ui/models/home_demo_data.dart';
import '../home/ui/views/home_screen.dart';

/// Where a successful sign-in lands: the Home dashboard (board 03 · A1).
///
/// Sign-in on the account's bound device goes straight here with no OTP and
/// without entering the registration wizard — that wizard is only ever
/// reached from "Register".
void openDashboard(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => const HomeScreen(demo: HomeDemo.installer),
    ),
  );
}

/// Walks a fixed list of screens in order, so a journey built from static
/// screens can still be clicked through end to end.
///
/// Screens call `PreviewJourney.next(context)` from their primary action.
/// Outside a journey (opened on their own from the gallery) the call simply
/// does nothing, which keeps every screen independently viewable.
class PreviewJourney extends InheritedWidget {
  const PreviewJourney({
    super.key,
    required this.steps,
    required this.index,
    required super.child,
  });

  final List<WidgetBuilder> steps;
  final int index;

  /// Pushes the next screen in the journey, if there is one.
  static void next(BuildContext context) {
    final journey = context
        .dependOnInheritedWidgetOfExactType<PreviewJourney>();
    if (journey == null) return;
    final nextIndex = journey.index + 1;
    if (nextIndex >= journey.steps.length) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PreviewJourney(
          steps: journey.steps,
          index: nextIndex,
          child: Builder(builder: journey.steps[nextIndex]),
        ),
      ),
    );
  }

  /// Opens [steps] from the beginning.
  static void start(BuildContext context, List<WidgetBuilder> steps) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PreviewJourney(
          steps: steps,
          index: 0,
          child: Builder(builder: steps.first),
        ),
      ),
    );
  }

  @override
  bool updateShouldNotify(PreviewJourney oldWidget) =>
      index != oldWidget.index || steps != oldWidget.steps;
}
