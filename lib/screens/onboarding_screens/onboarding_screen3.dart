import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Ensure this path matches your project structure exactly
import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen4.dart';

class OnboardingScreen3 extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OnboardingScreen3({super.key, required this.userData});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  int _height = 165;
  final int _minHeight = 100;
  final int _maxHeight = 250;

  Color get neonLime => const Color(0xFFE8FF4F);
  Color get purpleBox => const Color(0xFFB19FF4);

  void _continueToNextScreen() {
    // Logic to save data and move forward
    widget.userData['height'] = _height;
    widget.userData['height_unit'] = 'cm';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen4(userData: widget.userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Step 3 of 6",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "What Is Your Height?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        color: purpleBox,
                        child: const Center(
                          child: Text(
                            "To calculate your BMI and calorie needs, we need your height.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Height Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$_height",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "cm",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Ruler Section
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            height: 320,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 65),
                                    width: 80,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      color: purpleBox,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                RulerPicker(
                                  minValue: _minHeight,
                                  maxValue: _maxHeight,
                                  initialValue: _height,
                                  onValueChanged: (value) {
                                    setState(() => _height = value);
                                  },
                                ),
                                Positioned(
                                  right:
                                      (MediaQuery.of(context).size.width / 2) -
                                      125,
                                  child: Icon(
                                    Icons.arrow_left_sharp,
                                    color: neonLime,
                                    size: 50,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 65),
                                    width: 50,
                                    height: 2,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Continue Button - Now fully active
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _continueToNextScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonLime,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
          },
        ),
      ),
    );
  }
}

class RulerPicker extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;
  final ValueChanged<int> onValueChanged;

  const RulerPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onValueChanged,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.maxValue - widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 20,
      perspective: 0.001,
      diameterRatio: 2.0,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        widget.onValueChanged(widget.maxValue - index);
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.maxValue - widget.minValue + 1,
        builder: (context, index) {
          int value = widget.maxValue - index;
          bool isMajor = value % 5 == 0;
          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 55,
                  child: isMajor
                      ? Text(
                          "$value",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        )
                      : const SizedBox(),
                ),
                const SizedBox(width: 25),
                Container(
                  width: isMajor ? 40 : 20,
                  height: 2,
                  color: Colors.white.withOpacity(isMajor ? 0.9 : 0.5),
                ),
                const SizedBox(width: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
