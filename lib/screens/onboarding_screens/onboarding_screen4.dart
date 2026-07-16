import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen5.dart';

class OnboardingScreen4 extends StatefulWidget {
  final Map<String, dynamic> userData;
  const OnboardingScreen4({super.key, required this.userData});

  @override
  State<OnboardingScreen4> createState() => _OnboardingScreen4State();
}

class _OnboardingScreen4State extends State<OnboardingScreen4> {
  bool _isKg = true;
  int _weightKg = 70;

  final Color _neonLime = const Color(0xFFE8FF4F);
  final Color _purpleBox = const Color(0xFFB19FF4);
  Color get _cardDark => Theme.of(context).cardColor;

  void _continueToNextScreen() {
    widget.userData['weight'] = _weightKg;
    widget.userData['weight_unit'] = _isKg ? 'kg' : 'lbs';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen5(userData: widget.userData),
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Step 4 of 7",
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
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "What Is Your Weight?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _cardDark,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleTab(
                              "kg",
                              _isKg,
                              () => setState(() => _isKg = true),
                            ),
                            _buildToggleTab(
                              "lbs",
                              !_isKg,
                              () => setState(() => _isKg = false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        color: _purpleBox,
                        child: const Text(
                          "Weight helps us calculate your daily calorie needs accurately.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _isKg
                            ? "$_weightKg"
                            : "${(_weightKg * 2.20462).round()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isKg ? "kg" : "lbs",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 320,
                              decoration: BoxDecoration(
                                color: _purpleBox,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              height: 320,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: _isKg
                                    ? _KgRuler(
                                        initialValue: _weightKg,
                                        onChanged: (val) =>
                                            setState(() => _weightKg = val),
                                      )
                                    : _LbsRuler(
                                        initialValue: (_weightKg * 2.20462)
                                            .round(),
                                        onChanged: (val) => setState(
                                          () => _weightKg = (val / 2.20462)
                                              .round(),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              right:
                                  (MediaQuery.of(context).size.width / 2) - 80,
                              child: Icon(
                                Icons.arrow_left_sharp,
                                color: _neonLime,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _continueToNextScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _neonLime,
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

  Widget _buildToggleTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _KgRuler extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _KgRuler({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 30,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.5,
      controller: FixedExtentScrollController(initialItem: 150 - initialValue),
      onSelectedItemChanged: (index) {
        onChanged(150 - index);
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 121,
        builder: (context, index) {
          int val = 150 - index;
          bool isMajor = val % 5 == 0;
          return Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isMajor)
                  Text(
                    "$val",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  width: isMajor ? 30 : 15,
                  height: 2,
                  color: Colors.white.withOpacity(isMajor ? 1 : 0.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LbsRuler extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _LbsRuler({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 30,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.5,
      controller: FixedExtentScrollController(initialItem: 330 - initialValue),
      onSelectedItemChanged: (index) {
        onChanged(330 - index);
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 265,
        builder: (context, index) {
          int val = 330 - index;
          bool isMajor = val % 10 == 0;
          return Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isMajor)
                  Text(
                    "$val",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  width: isMajor ? 30 : 15,
                  height: 2,
                  color: Colors.white.withOpacity(isMajor ? 1 : 0.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
