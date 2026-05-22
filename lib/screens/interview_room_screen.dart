import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/interview_provider.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../widgets/ai_avatar_widget.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/custom_button.dart';
import 'results_screen.dart';

class InterviewRoomScreen extends StatefulWidget {
  const InterviewRoomScreen({super.key});

  @override
  State<InterviewRoomScreen> createState() => _InterviewRoomScreenState();
}

class _InterviewRoomScreenState extends State<InterviewRoomScreen>
    with TickerProviderStateMixin {
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _isTyping = false;

  CameraController? _cameraCtrl;
  bool _cameraOn = true;
  bool _micOn = true;
  bool _isSpeaking = false;
  bool _isListeningVoice = false;
  String _currentAnswer = '';
  String? _hintText;
  bool _showHint = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  Key _timerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _textController.addListener(() {
      if (_textController.text != _currentAnswer) {
        setState(() => _currentAnswer = _textController.text);
        context.read<InterviewProvider>().updateTranscript(_textController.text);
      }
    });

    _init();
  }

  Future<void> _init() async {
    await _tts.init();
    await _stt.init();
    await _initCamera();

    if (!mounted) return;

    final question = context.read<InterviewProvider>().currentQuestion;
    if (question != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _speakQuestion(question.questionText);
    }
    _fadeCtrl.forward();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraCtrl = CameraController(front, ResolutionPreset.medium);
      await _cameraCtrl!.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _speakQuestion(String text) async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
    if (!mounted) return;
    setState(() => _isSpeaking = false);
  }

  Future<void> _startListening() async {
    if (!_micOn) return;

    setState(() => _isTyping = false);
    _textFocus.unfocus();

    if (!_stt.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Speech recognition not available. Please type your answer.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Type',
              textColor: Colors.white,
              onPressed: () => setState(() => _isTyping = true),
            ),
          ),
        );
      }
      return;
    }

    await _tts.stop();
    setState(() {
      _isListeningVoice = true;
      _currentAnswer = '';
      _textController.clear();
    });
    context.read<InterviewProvider>().setListening(true);

    await _stt.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _currentAnswer = text;
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        });
        context.read<InterviewProvider>().updateTranscript(text);
      },
      onStop: () {
        if (!mounted) return;
        setState(() => _isListeningVoice = false);
        context.read<InterviewProvider>().setListening(false);
      },
    );
  }

  Future<void> _stopListening() async {
    await _stt.stopListening();
    if (!mounted) return;
    setState(() => _isListeningVoice = false);
    context.read<InterviewProvider>().setListening(false);
  }

  Future<void> _submitAnswer() async {
    _textFocus.unfocus();
    setState(() => _isTyping = false);

    final interviewProvider = context.read<InterviewProvider>();

    final typedAnswer = _textController.text.trim();
    if (typedAnswer.isNotEmpty) {
      _currentAnswer = typedAnswer;
    }

    final answer = _currentAnswer.trim();
    if (answer.isEmpty) {
      _currentAnswer = 'No answer provided by candidate.';
    }

    await _stopListening();
    if (!mounted) return;

    setState(() {
      _hintText = null;
      _showHint = false;
      _timerKey = UniqueKey();
      _textController.clear();
    });

    await interviewProvider.submitAnswer(_currentAnswer);
    if (!mounted) return;

    setState(() => _currentAnswer = '');

    if (interviewProvider.questionNumber >= _maxQuestions()) {
      await _endInterview();
    } else {
      await interviewProvider.generateNextQuestion();
      if (!mounted) return;

      final nextQ = interviewProvider.currentQuestion;
      if (nextQ != null) await _speakQuestion(nextQ.questionText);
    }
  }

  int _maxQuestions() {
    final duration =
        context.read<InterviewProvider>().currentInterview?.durationMinutes ?? 10;
    return (duration / 2).ceil();
  }

  Future<void> _endInterview() async {
    await _tts.stop();
    await _stt.stopListening();
    if (!mounted) return;

    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final interviewProvider = context.read<InterviewProvider>();
    await interviewProvider.endInterview(uid);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    }
  }

  Future<void> _getHint() async {
    final hint = await context.read<InterviewProvider>().getHint();
    if (!mounted) return;
    setState(() {
      _hintText = hint;
      _showHint = true;
    });
  }

  void _showExitDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text('End Interview?',
            style: TextStyle(
                color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain)),
        content: Text('Are you sure you want to end the interview early?',
            style: TextStyle(
                color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _endInterview();
            },
            child: const Text('End Interview', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _tts.dispose();
    _stt.dispose();
    _fadeCtrl.dispose();
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final cardColor   = isDark ? AppColors.darkCard     : AppColors.lightCard;
    final textColor   = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final subColor    = isDark ? AppColors.darkTextSub  : AppColors.lightTextSub;
    final hintColor   = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final primColor   = isDark ? AppColors.darkPrimary  : AppColors.lightPrimary;
    final borderColor = isDark ? AppColors.darkBorder   : AppColors.lightBorder;

    final interviewProvider = context.watch<InterviewProvider>();
    final question    = interviewProvider.currentQuestion;
    final isGenerating = interviewProvider.status == InterviewStatus.generating;
    final isEvaluating = interviewProvider.status == InterviewStatus.evaluating;
    final isError      = interviewProvider.status == InterviewStatus.error;
    final isThinking   = isGenerating || isEvaluating;

    if (isError) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 64),
                const SizedBox(height: 16),
                Text('Something went wrong',
                    style: TextStyle(
                        color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(interviewProvider.errorMessage ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subColor, fontSize: 14)),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Try Again',
                  onTap: () => interviewProvider.reset(),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back', style: TextStyle(color: subColor)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,  // ✅ FIX: keyboard overflow
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [

              // ── Top Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: _showExitDialog,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        'Q${interviewProvider.questionNumber + 1} • '
                            '${interviewProvider.currentInterview?.topic ?? ""}',
                        style: TextStyle(
                            color: primColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    if (!isThinking)
                      CountdownTimerWidget(
                        key: _timerKey,
                        seconds: 120,
                        onTimeUp: _submitAnswer,
                      ),
                  ],
                ),
              ),

              // ── Main Content ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(  // ✅ FIX: scroll when keyboard opens
                  child: Row(
                    children: [
                      // Left — AI side
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AiAvatarWidget(
                              isSpeaking: _isSpeaking,
                              isThinking: isThinking,
                            ),
                            const SizedBox(height: 24),

                            if (question != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: Container(
                                    key: ValueKey(question.id),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: primColor.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.question_mark,
                                                color: primColor, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Question',
                                                style: TextStyle(
                                                    color: primColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold)),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () => _speakQuestion(
                                                  question.questionText),
                                              child: Icon(Icons.volume_up,
                                                  color: subColor, size: 18),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _TypewriterText(
                                          text: question.questionText,
                                          textColor: textColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            if (_showHint && _hintText != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.warning.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lightbulb,
                                          color: AppColors.warning, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_hintText!,
                                            style: const TextStyle(
                                                color: AppColors.warning,
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Right — Camera
                      if (_cameraOn &&
                          _cameraCtrl != null &&
                          _cameraCtrl!.value.isInitialized)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 120,
                              height: 160,
                              child: CameraPreview(_cameraCtrl!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Answer Input Area ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isListeningVoice
                          ? AppColors.micActive
                          : _isTyping
                          ? primColor
                          : borderColor,
                      width: (_isListeningVoice || _isTyping) ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        child: Row(
                          children: [
                            if (_isListeningVoice)
                              const Icon(Icons.mic,
                                  color: AppColors.micActive, size: 13),
                            if (_isTyping && !_isListeningVoice)
                              Icon(Icons.keyboard, color: primColor, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              _isListeningVoice
                                  ? 'Listening... (you can also edit below)'
                                  : 'Your Answer  —  speak or type',
                              style: TextStyle(
                                  color: _isListeningVoice
                                      ? AppColors.micActive
                                      : hintColor,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocus,
                          maxLines: 3,
                          minLines: 2,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Tap mic to speak, or type here...',
                            hintStyle:
                            TextStyle(color: hintColor, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.all(4),
                          ),
                          onTap: () {
                            setState(() => _isTyping = true);
                            if (_isListeningVoice) _stopListening();
                          },
                          onChanged: (val) {
                            setState(() => _currentAnswer = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Bottom Controls ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _ControlBtn(
                      icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                      color: _cameraOn ? primColor : subColor,
                      onTap: () => setState(() => _cameraOn = !_cameraOn),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _ControlBtn(
                      icon: Icons.lightbulb_outline,
                      color: AppColors.warning,
                      onTap: _getHint,
                      label: '-2pts',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isListeningVoice
                            ? _stopListening
                            : _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isListeningVoice
                                ? AppColors.micActive.withOpacity(0.15)
                                : cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isListeningVoice
                                  ? AppColors.micActive
                                  : primColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListeningVoice
                                    ? Icons.mic
                                    : Icons.mic_none,
                                color: _isListeningVoice
                                    ? AppColors.micActive
                                    : primColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isListeningVoice ? 'Stop' : 'Speak',
                                style: TextStyle(
                                  color: _isListeningVoice
                                      ? AppColors.micActive
                                      : primColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ControlBtn(
                      icon: Icons.send,
                      color: AppColors.success,
                      onTap: isEvaluating ? null : _submitAnswer,
                      isLoading: isEvaluating,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? label;
  final bool isLoading;
  final bool isDark;

  const _ControlBtn({
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
    this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: isLoading
            ? Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            if (label != null)
              Text(label!, style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final Color textColor;

  const _TypewriterText({
    required this.text,
    required this.textColor,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.text.length * 25 + 200),
    );
    _anim = IntTween(begin: 0, end: widget.text.length).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _ctrl.duration =
          Duration(milliseconds: widget.text.length * 25 + 200);
      _anim = IntTween(begin: 0, end: widget.text.length).animate(_ctrl);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        widget.text.substring(0, _anim.value),
        style: TextStyle(color: widget.textColor, fontSize: 14, height: 1.6),
      ),
    );
  }
}