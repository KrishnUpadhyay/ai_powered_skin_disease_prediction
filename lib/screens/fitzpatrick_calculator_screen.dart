import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class FitzpatrickCalculatorScreen extends StatefulWidget {
  const FitzpatrickCalculatorScreen({super.key});

  @override
  State<FitzpatrickCalculatorScreen> createState() => _FitzpatrickCalculatorScreenState();
}

class _FitzpatrickCalculatorScreenState extends State<FitzpatrickCalculatorScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  int _totalScore = 0;
  final List<int?> _selectedAnswers = List.filled(6, null);

  final List<Map<String, dynamic>> _questions = [
    {
      "question": "What is the natural color of your eyes?",
      "options": [
        {"text": "Light blue, light gray, or light green", "score": 0},
        {"text": "Blue, gray, or green", "score": 1},
        {"text": "Hazel or light brown", "score": 2},
        {"text": "Dark brown", "score": 3},
        {"text": "Brownish black", "score": 4}
      ]
    },
    {
      "question": "What is the natural color of your hair?",
      "options": [
        {"text": "Sandy red", "score": 0},
        {"text": "Blonde", "score": 1},
        {"text": "Chestnut, dark blonde, or light brown", "score": 2},
        {"text": "Dark brown", "score": 3},
        {"text": "Black", "score": 4}
      ]
    },
    {
      "question": "What is the color of your skin in non-exposed areas?",
      "options": [
        {"text": "Reddish / Pinkish", "score": 0},
        {"text": "Very pale / Ivory", "score": 1},
        {"text": "Pale with a beige tint", "score": 2},
        {"text": "Light brown / Olive", "score": 3},
        {"text": "Dark brown or black", "score": 4}
      ]
    },
    {
      "question": "What happens when you stay in the sun too long?",
      "options": [
        {"text": "Always burns, blisters, and peels", "score": 0},
        {"text": "Often burns, peels moderately", "score": 1},
        {"text": "Burns moderately, tans gradually", "score": 2},
        {"text": "Rarely burns, tans easily", "score": 3},
        {"text": "Never burns, tans deeply", "score": 4}
      ]
    },
    {
      "question": "To what degree do you tan?",
      "options": [
        {"text": "Never tan / sunburn only", "score": 0},
        {"text": "Tan minimally and with difficulty", "score": 1},
        {"text": "Tan reasonably / moderately", "score": 2},
        {"text": "Tan deeply and easily", "score": 3},
        {"text": "Tan extremely rapidly / darkly", "score": 4}
      ]
    },
    {
      "question": "Does your face turn red in the sun?",
      "options": [
        {"text": "Always / Very severely", "score": 0},
        {"text": "Frequently", "score": 1},
        {"text": "Moderately / Sometimes", "score": 2},
        {"text": "Seldom", "score": 3},
        {"text": "Never", "score": 4}
      ]
    }
  ];

  void _onOptionSelected(int score) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = score;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentQuestionIndex < 5) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _calculateResult();
      }
    });
  }

  void _calculateResult() {
    int score = 0;
    for (var val in _selectedAnswers) {
      if (val != null) score += val;
    }
    setState(() {
      _totalScore = score;
      ApiService.fitzpatrickSkinType = _getSkinType(score);
    });
  }

  String _getSkinType(int score) {
    if (score <= 7) return "Type I";
    if (score <= 13) return "Type II";
    if (score <= 20) return "Type III";
    if (score <= 25) return "Type IV";
    if (score <= 30) return "Type V";
    return "Type VI";
  }

  Map<String, String> _getSkinTypeDetails(String type) {
    switch (type) {
      case "Type I":
        return {
          "desc": "Very fair skin, red or blonde hair, light eyes. Always burns, never tans. High risk of skin cancer.",
          "advice": "Apply SPF 50+ hourly. Max safe sun exposure: 10-15 minutes.",
          "factor": "0.5"
        };
      case "Type II":
        return {
          "desc": "Fair skin, light hair, blue or green eyes. Burns easily, tans minimally. High risk of skin cancer.",
          "advice": "Apply SPF 30+ to 50+. Max safe sun exposure: 20-30 minutes.",
          "factor": "0.7"
        };
      case "Type III":
        return {
          "desc": "Medium skin, dark blonde or brown hair. Burns moderately, tans gradually to light brown. Moderate risk.",
          "advice": "Apply SPF 30+. Max safe sun exposure: 30-45 minutes.",
          "factor": "1.0"
        };
      case "Type IV":
        return {
          "desc": "Olive skin, dark brown or black hair. Burns minimally, tans easily to moderate brown. Lower risk.",
          "advice": "Apply SPF 30+. Max safe sun exposure: 45-60 minutes.",
          "factor": "1.3"
        };
      case "Type V":
        return {
          "desc": "Dark brown skin, black hair. Rarely burns, tans easily and darkly. Lower risk, but monitoring moles is still key.",
          "advice": "Apply SPF 15+ to 30+. Max safe sun exposure: 60-90 minutes.",
          "factor": "1.6"
        };
      case "Type VI":
        default:
        return {
          "desc": "Black or deeply pigmented skin. Never burns, tans darkly. Skin cancer risk is lower, but regular checkups are vital.",
          "advice": "Apply SPF 15+ for UV defense. Max safe sun exposure: 90-120 minutes.",
          "factor": "2.0"
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCompleted = _selectedAnswers.every((element) => element != null);
    final skinType = ApiService.fitzpatrickSkinType;
    final details = skinType != null ? _getSkinTypeDetails(skinType) : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Skin Type Calculator",
          style: AppTextStyles.heading3(isDark: isDark).copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: hasCompleted && details != null
              ? _buildResultScreen(skinType!, details)
              : _buildQuizScreen(),
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final progress = (_currentQuestionIndex + 1) / 6;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress Bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Text(
              "${_currentQuestionIndex + 1} / 6",
              style: AppTextStyles.bodyBold(isDark: isDark).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 30),

        // Page View for Questions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentQuestionIndex = index;
              });
            },
            itemCount: _questions.length,
            itemBuilder: (context, qIndex) {
              final q = _questions[qIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    q["question"],
                    style: AppTextStyles.heading2(isDark: isDark).copyWith(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 25),
                  Expanded(
                    child: ListView.builder(
                      itemCount: q["options"].length,
                      itemBuilder: (context, oIndex) {
                        final option = q["options"][oIndex];
                        final isSelected = _selectedAnswers[qIndex] == option["score"];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: InkWell(
                            onTap: () => _onOptionSelected(option["score"]),
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              borderColor: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.08),
                              backgroundColor: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.02),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      option["text"],
                                      style: AppTextStyles.body(isDark: isDark).copyWith(
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (oIndex * 80).ms, duration: 300.ms);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Navigation Row
        if (_currentQuestionIndex > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  label: Text(
                    "Back",
                    style: AppTextStyles.bodyBold(isDark: isDark).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResultScreen(String type, Map<String, String> details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Icon(
              Icons.stars_rounded,
              color: AppColors.primary,
              size: 72,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 15),
          Center(
            child: Text(
              "Your Fitzpatrick Skin Type is",
              style: AppTextStyles.body(isDark: isDark).copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              type,
              style: AppTextStyles.heading1(isDark: isDark).copyWith(
                color: AppColors.primary,
                fontSize: 38,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 25),
          
          GlassCard(
            borderColor: AppColors.primary.withOpacity(0.3),
            backgroundColor: AppColors.surface.withOpacity(0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Description",
                  style: AppTextStyles.bodyBold(isDark: isDark).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details["desc"]!,
                  style: AppTextStyles.body(isDark: isDark).copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 30, color: Colors.white10),
                Text(
                  "Safe UV Exposure Guidance",
                  style: AppTextStyles.bodyBold(isDark: isDark).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details["advice"]!,
                  style: AppTextStyles.body(isDark: isDark).copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms).fadeIn(delay: 300.ms),
          const SizedBox(height: 20),

          // Scale Indicator alert
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your skin sensitivity scale factor of ${details["factor"]}x has been applied to the UV Safe Exposure timer.",
                    style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 25),

          // Medical Disclaimer
          Text(
            "Medical Disclaimer: The Fitzpatrick classification scale is a general physiological self-assessment metric. It is not a substitute for a professional diagnosis by a dermatologist. Always consult a medical clinician for personalized skin cancer risk assessments.",
            style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 35),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Text(
              "Return to Dashboard",
              style: AppTextStyles.bodyBold(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAnswers.fillRange(0, 6, null);
                _currentQuestionIndex = 0;
                _totalScore = 0;
                ApiService.fitzpatrickSkinType = null;
              });
            },
            child: Text(
              "Retake Calculator Quiz",
              style: AppTextStyles.body(isDark: isDark).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
