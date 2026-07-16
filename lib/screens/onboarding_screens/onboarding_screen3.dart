import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen4.dart';

class OnboardingScreen3 extends StatefulWidget {
  final Map<String, dynamic> userData;
  const OnboardingScreen3({super.key, required this.userData});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  bool _isCm = true;
  int _heightCm = 170;

  final Color _neonLime = const Color(0xFFE8FF4F);
  final Color _purpleBox = const Color(0xFFB19FF4);
  Color get _cardDark => Theme.of(context).cardColor;

  String _formatFeet(int totalInches) {
    int ft = totalInches ~/ 12;
    int inches = totalInches % 12;
    return "$ft' $inches\"";
  }

  void _continueToNextScreen() {
    widget.userData['height'] = _heightCm;
    widget.userData['height_unit'] = _isCm ? 'cm' : 'ft';

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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Step 3 of 7",
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
                        "What Is Your Height?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- UNIT TOGGLE ---
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
                              "cm",
                              _isCm,
                              () => setState(() => _isCm = true),
                            ),
                            _buildToggleTab(
                              "ft",
                              !_isCm,
                              () => setState(() => _isCm = false),
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
                          "Height helps us calculate your BMI and calorie needs.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        _isCm
                            ? "$_heightCm"
                            : _formatFeet((_heightCm / 2.54).round()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isCm)
                        const Text(
                          "cm",
                          style: TextStyle(color: Colors.grey, fontSize: 20),
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
                                child: _isCm
                                    ? _CmRuler(
                                        initialValue: _heightCm,
                                        onChanged: (val) =>
                                            setState(() => _heightCm = val),
                                      )
                                    : _FtRuler(
                                        initialValue: (_heightCm / 2.54)
                                            .round(),
                                        onChanged: (val) => setState(
                                          () =>
                                              _heightCm = (val * 2.54).round(),
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

class _CmRuler extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _CmRuler({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 30,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.5,
      controller: FixedExtentScrollController(initialItem: 250 - initialValue),
      onSelectedItemChanged: (index) {
        onChanged(250 - index);
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 151, // 100 to 250 cm
        builder: (context, index) {
          int val = 250 - index;
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

class _FtRuler extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _FtRuler({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 30,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.5,
      controller: FixedExtentScrollController(initialItem: 98 - initialValue),
      onSelectedItemChanged: (index) {
        onChanged(98 - index);
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 59, // Approx 3'4" to 8'2"
        builder: (context, index) {
          int totalInches = 98 - index;
          int ft = totalInches ~/ 12;
          int inch = totalInches % 12;
          bool isMajor = inch == 0;
          return Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isMajor)
                  Text(
                    "${ft}ft",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!isMajor && inch % 3 == 0)
                  Text(
                    "${inch}in",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
