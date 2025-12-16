import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naughty_list_notifier/src/shared/screen_base/presentation/screen_base.dart';

void main() {
  group('ScreenBase', () {
    testWidgets('renders with required child widget', (
      WidgetTester tester,
    ) async {
      const testChild = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: testChild)),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders default appBar when appBar is not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      expect(find.text('North Pole Network'), findsOneWidget);
    });

    testWidgets('renders custom appBar when appBar is provided', (
      WidgetTester tester,
    ) async {
      final customAppBar = AppBar(title: const Text('Custom AppBar'));

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenBase(appBar: customAppBar, child: const Text('Test')),
        ),
      );

      expect(find.text('Custom AppBar'), findsOneWidget);
      expect(find.text('North Pole Network'), findsNothing);
    });

    testWidgets(
      'default appBar shows back button when Navigator.canPop is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/': (context) => const ScreenBase(child: Text('First')),
              '/second': (context) => const ScreenBase(child: Text('Second')),
            },
            initialRoute: '/second',
          ),
        );

        // Navigate to second route
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Check for back button icon
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      },
    );

    testWidgets(
      'default appBar does not show back button when Navigator.canPop is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ScreenBase(child: Text('Test'))),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // When there's no route to pop, back button should not be shown
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      },
    );

    testWidgets('default appBar has correct title styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final titleFinder = find.text('North Pole Network');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.color, Colors.white);
    });

    testWidgets('default appBar has transparent background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.backgroundColor, Colors.transparent);
    });

    testWidgets('default appBar has transparent backgroundColor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.backgroundColor, Colors.transparent);
    });

    testWidgets('default appBar has white foregroundColor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.foregroundColor, Colors.white);
    });

    testWidgets('default appBar has elevation of 4', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.elevation, 4);
    });

    testWidgets('default appBar has centerTitle set to true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.centerTitle, true);
    });

    testWidgets('default appBar has automaticallyImplyLeading set to false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.automaticallyImplyLeading, false);
    });

    testWidgets('contains background image', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      // Pump frames to allow widget tree to build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find all Image widgets
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      // Check if background image exists
      final backgroundImages = imageFinder.evaluate().where((element) {
        final widget = element.widget;
        if (widget is Image && widget.image is AssetImage) {
          final assetImage = widget.image as AssetImage;
          return assetImage.assetName == 'assets/background.png';
        }
        return false;
      });

      expect(
        backgroundImages.isNotEmpty,
        isTrue,
        reason: 'Background image should be present in the widget tree',
      );
    });

    testWidgets('contains header image', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      // Pump frames to allow widget tree to build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find all Image widgets
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      // Check if header image exists
      final headerImages = imageFinder.evaluate().where((element) {
        final widget = element.widget;
        if (widget is Image && widget.image is AssetImage) {
          final assetImage = widget.image as AssetImage;
          return assetImage.assetName == 'assets/header.png';
        }
        return false;
      });

      expect(
        headerImages.isNotEmpty,
        isTrue,
        reason: 'Header image should be present in the widget tree',
      );
    });

    testWidgets('contains SafeArea widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MaterialApp may add its own SafeArea, so we check for at least one
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('contains beige container with correct color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final containerFinder = find.byType(Container);
      final beigeContainers = containerFinder.evaluate().where((element) {
        final widget = element.widget;
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == const Color(0xFFF5F5DC);
        }
        return false;
      });

      expect(beigeContainers.isNotEmpty, isTrue);
    });

    testWidgets('beige container has correct border radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final containerFinder = find.byType(Container);
      final beigeContainers = containerFinder.evaluate().where((element) {
        final widget = element.widget;
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.borderRadius == BorderRadius.circular(12);
        }
        return false;
      });

      expect(beigeContainers.isNotEmpty, isTrue);
    });

    testWidgets('contains DottedBorderPainter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: Text('Test'))),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MaterialApp/Scaffold may add CustomPaint widgets, so we check for at least one
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify that at least one CustomPaint uses DottedBorderPainter
      final customPaintFinder = find.byType(CustomPaint);
      final customPaints = customPaintFinder.evaluate();
      final hasDottedBorder = customPaints.any((element) {
        final widget = element.widget;
        if (widget is CustomPaint) {
          return widget.painter is DottedBorderPainter;
        }
        return false;
      });
      expect(hasDottedBorder, isTrue);
    });

    testWidgets('child widget is rendered with correct padding', (
      WidgetTester tester,
    ) async {
      const testChild = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(home: ScreenBase(child: testChild)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Content'), findsOneWidget);

      // Verify the child is wrapped in Padding
      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);
    });

    testWidgets('renders correctly with complex child widget', (
      WidgetTester tester,
    ) async {
      final complexChild = Column(
        children: [
          const Text('Title'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text('Button')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: ScreenBase(child: complexChild)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('back button navigates back when pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const Scaffold(body: Text('First Screen')),
            '/second': (context) =>
                const ScreenBase(child: Text('Second Screen')),
          },
          initialRoute: '/second',
        ),
      );

      // Wait for navigation to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Second Screen'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('First Screen'), findsOneWidget);
    });
  });

  group('DottedBorderPainter', () {
    test('shouldRepaint returns true when borderColor changes', () {
      final painter1 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      final painter2 = DottedBorderPainter(
        borderColor: Colors.blue,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when borderWidth changes', () {
      final painter1 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      final painter2 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 3,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when dashWidth changes', () {
      final painter1 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      final painter2 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 10,
        dashSpace: 4,
        radius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when dashSpace changes', () {
      final painter1 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      final painter2 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 6,
        radius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when radius changes', () {
      final painter1 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      final painter2 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 16,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when all properties are the same', () {
      final painter1 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      final painter2 = DottedBorderPainter(
        borderColor: Colors.red,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    testWidgets('DottedBorderPainter renders correctly in widget tree', (
      WidgetTester tester,
    ) async {
      final painter = DottedBorderPainter(
        borderColor: const Color(0xFF8B0000),
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(painter: painter, child: const Text('Test')),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify CustomPaint is rendered (MaterialApp/Scaffold may add additional CustomPaint widgets)
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Test'), findsOneWidget);

      // Verify our specific CustomPaint with DottedBorderPainter exists
      final customPaintFinder = find.byType(CustomPaint);
      final customPaints = customPaintFinder.evaluate();
      final hasOurPainter = customPaints.any((element) {
        final widget = element.widget;
        if (widget is CustomPaint && widget.painter is DottedBorderPainter) {
          final dottedPainter = widget.painter as DottedBorderPainter;
          return dottedPainter.borderColor == const Color(0xFF8B0000);
        }
        return false;
      });
      expect(hasOurPainter, isTrue);
    });

    testWidgets('DottedBorderPainter uses correct border color', (
      WidgetTester tester,
    ) async {
      const testColor = Color(0xFF8B0000);
      final painter = DottedBorderPainter(
        borderColor: testColor,
        borderWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(painter: painter),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the painter is applied (MaterialApp/Scaffold may add additional CustomPaint widgets)
      expect(find.byType(CustomPaint), findsWidgets);
      expect(painter.borderColor, testColor);

      // Verify our specific CustomPaint with the correct color exists
      final customPaintFinder = find.byType(CustomPaint);
      final customPaints = customPaintFinder.evaluate();
      final hasCorrectColor = customPaints.any((element) {
        final widget = element.widget;
        if (widget is CustomPaint && widget.painter is DottedBorderPainter) {
          final dottedPainter = widget.painter as DottedBorderPainter;
          return dottedPainter.borderColor == testColor;
        }
        return false;
      });
      expect(hasCorrectColor, isTrue);
    });
  });
}
