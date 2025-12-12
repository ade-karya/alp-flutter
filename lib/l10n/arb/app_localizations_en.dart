// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sikolah Apps';

  @override
  String get welcomeMessage => 'Welcome to Adaptive Learning Platform';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageIndonesian => 'Indonesian';

  @override
  String get onboardingTitle1 => 'Welcome to Adaptive Learning';

  @override
  String get onboardingDesc1 =>
      'Personalized learning experience powered by AI.';

  @override
  String get onboardingTitle2 => 'Track Your Progress';

  @override
  String get onboardingDesc2 =>
      'Monitor your achievements and growth over time.';

  @override
  String get onboardingTitle3 => 'Connect with Teachers';

  @override
  String get onboardingDesc3 => 'Get guidance and support from your educators.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingJoinCommunity =>
      'Join our community of learners and educators.';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get registerLink => 'New here? Create an account';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get labelNISN => 'NISN';

  @override
  String get labelNUPTK => 'NUPTK';

  @override
  String get labelPIN => 'PIN';

  @override
  String get labelIdentifier => 'Identifier';

  @override
  String get errorEmptyNISN => 'Please enter your NISN';

  @override
  String get errorEmptyNUPTK => 'Please enter your NUPTK';

  @override
  String get errorEmptyPIN => 'Please enter your PIN';

  @override
  String get errorShortPIN => 'PIN must be at least 4 digits';

  @override
  String get registerTitle => 'Register';

  @override
  String get labelName => 'Full Name';

  @override
  String get labelDateOfBirth => 'Date of Birth';

  @override
  String get errorEmptyName => 'Please enter your name';

  @override
  String get errorEmptyDate => 'Please enter your date of birth';

  @override
  String get loginLink => 'Already have an account? Login';

  @override
  String get registerSelectRole => 'Select Your Role';

  @override
  String get registerStudentTitle => 'Student Registration';

  @override
  String get registerTeacherTitle => 'Teacher Registration';

  @override
  String get labelConfirmPIN => 'Confirm PIN';

  @override
  String get helperPIN => 'Create a 4-digit PIN for security';

  @override
  String get errorConfirmPIN => 'Please confirm your PIN';

  @override
  String get errorMatchPIN => 'PINs do not match';

  @override
  String get labelSelectDate => 'Select date';

  @override
  String get errorNISNLength => 'NISN must be 10 digits';

  @override
  String get errorNUPTKLength => 'NUPTK must be 16 digits';

  @override
  String get errorPINLength => 'PIN must be exactly 4 digits';

  @override
  String get buttonNext => 'Next';

  @override
  String get buttonBack => 'Back';

  @override
  String get registrationSuccessTitle => 'Registration Successful';

  @override
  String registrationSuccessContent(Object identifier) {
    return 'User $identifier registered successfully. Please login.';
  }

  @override
  String get buttonOK => 'OK';

  @override
  String get dashboardStudent => 'Student Portal';

  @override
  String get dashboardTeacher => 'Teacher Portal';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSettings => 'Profile Settings';

  @override
  String get navEditProfile => 'Edit Profile';

  @override
  String get navSwitchUser => 'Switch User';

  @override
  String get navChangePin => 'Change PIN';

  @override
  String get changePinTitle => 'Change PIN';

  @override
  String get changePinCurrentLabel => 'Current PIN';

  @override
  String get changePinNewLabel => 'New PIN';

  @override
  String get changePinConfirmLabel => 'Confirm New PIN';

  @override
  String get changePinSuccess => 'PIN changed successfully!';

  @override
  String get changePinErrorCurrent => 'Current PIN is incorrect';

  @override
  String get changePinErrorEmpty => 'Please fill all fields';

  @override
  String get navLogout => 'Logout';

  @override
  String get navLanguage => 'Language';

  @override
  String get tileAITutor => 'AI Tutor';

  @override
  String get tileMyCourses => 'My Courses';

  @override
  String get tileProgress => 'Progress';

  @override
  String get tileAIAssistant => 'AI Assistant';

  @override
  String get tileCreateContent => 'Create Content';

  @override
  String get tileAnalytics => 'Student Analytics';

  @override
  String get tileManageClass => 'Manage Class';

  @override
  String get aiAssistantTitle => 'AI Assistant Settings';

  @override
  String get activeProvider => 'Active Provider';

  @override
  String get allProviders => 'All Providers';

  @override
  String get noApiKey => 'No API Key configured';

  @override
  String get active => 'Active';

  @override
  String get labelBaseUrl => 'Base URL';

  @override
  String get labelApiKey => 'API Key';

  @override
  String get resetUrl => 'Reset URL';

  @override
  String get saveAndActivate => 'Save & Activate';

  @override
  String get providerSaved => 'Provider settings saved and activated';

  @override
  String get labelModel => 'Model';

  @override
  String get fetchModels => 'Fetch Models';

  @override
  String get themePlayful => 'Switch to Serious';

  @override
  String get themeSerious => 'Switch to Playful';

  @override
  String get featureComingSoon => 'Feature coming soon!';

  @override
  String get ccTitle => 'Create Content';

  @override
  String get ccSnackBarError => 'Please enter both topic and grade level';

  @override
  String get ccErrorApiKey =>
      'API Key not found. Please check your Profile settings.';

  @override
  String get ccTopicLabel => 'Topic';

  @override
  String get ccTopicHint => 'e.g., Photosynthesis';

  @override
  String get ccGradeLabel => 'Grade Level';

  @override
  String get ccGradeHint => 'e.g., 5th Grade';

  @override
  String get ccGenerateButton => 'Generate Lesson Plan';

  @override
  String get ccContentPlaceholder => 'Generated content will appear here...';

  @override
  String ccErrorGenerating(Object error) {
    return 'Error generating content: $error';
  }

  @override
  String get mcTitle => 'Manage Classes';

  @override
  String mcSnackBarCreated(Object name, Object pin) {
    return 'Class \"$name\" created! PIN: $pin';
  }

  @override
  String mcErrorCreating(Object error) {
    return 'Error creating class: $error';
  }

  @override
  String get mcDialogTitle => 'Create New Class';

  @override
  String get mcClassNameLabel => 'Class Name';

  @override
  String get mcClassDescLabel => 'Description (Optional)';

  @override
  String get mcEnrolledStudents => 'Enrolled Students:';

  @override
  String get mcNoStudents => 'No students yet.';

  @override
  String get mcFabCreate => 'Create Class';

  @override
  String get mcNoClasses => 'No classes created yet.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get usTitle => 'Select User';

  @override
  String usEnterPin(Object name) {
    return 'Enter PIN for $name';
  }

  @override
  String get usLabelPin => 'PIN';

  @override
  String get usVerify => 'Verify';

  @override
  String get usIncorrectPin => 'Incorrect PIN';

  @override
  String get usSetPinTitle => 'Set Your PIN';

  @override
  String get usSetPinMsg => 'Please set a 4-digit PIN for security';

  @override
  String get usConfirmPin => 'Confirm PIN';

  @override
  String get usPinMismatch => 'PINs do not match';

  @override
  String get usPinLength => 'PIN must be 4 digits';

  @override
  String get usSetPinButton => 'Set PIN';

  @override
  String get usNoUsers => 'No users registered yet';

  @override
  String get usAddUser => 'Add New User';

  @override
  String get profileTitle => 'Profile & Settings';

  @override
  String get profileGeminiConfig => 'Gemini API Configuration';

  @override
  String get profileApiKey => 'API Key';

  @override
  String get profileApiKeySaved => 'API Key Saved';

  @override
  String get profileSelectModel => 'Select Model';

  @override
  String get profileRefreshModels => 'Refresh Models';

  @override
  String get profileNoModels => 'No models found. Check your API Key.';

  @override
  String get profileSaveModel => 'Save Model';

  @override
  String get profileModelSaved => 'Model saved successfully!';

  @override
  String get aiTutorTitle => 'AI Tutor';

  @override
  String get aiTutorSystemPrompt =>
      'You are a helpful and knowledgeable AI tutor for students. Explain concepts clearly and patiently in the language the student asks in.';

  @override
  String get aiTutorErrorApiKey =>
      'API Key not found. Please check your Profile settings.';

  @override
  String get aiTutorHint => 'Ask your tutor...';

  @override
  String aiTutorError(Object error) {
    return 'Error: $error';
  }

  @override
  String get mcCoursesTitle => 'My Courses';

  @override
  String get mcJoinClass => 'Join Class';

  @override
  String get mcClassNotFound => 'Class not found with that PIN';

  @override
  String get mcAlreadyEnrolled => 'You are already enrolled in this class';

  @override
  String mcJoinedSuccess(Object name) {
    return 'Joined class \"$name\"!';
  }

  @override
  String mcErrorJoining(Object error) {
    return 'Error joining class: $error';
  }

  @override
  String get mcJoinDialogTitle => 'Join Class';

  @override
  String get mcEnterPinLabel => 'Enter Class PIN';

  @override
  String get mcCommonJoin => 'Join';

  @override
  String get mcNoCourses => 'You have not joined any classes yet.';

  @override
  String mcTeacherPrefix(Object name) {
    return 'Teacher: $name';
  }

  @override
  String get languageSelectorTooltip => 'Select Language';

  @override
  String get ccContentTypeLabel => 'Content Type';

  @override
  String get ccTypeLessonPlan => 'Lesson Plan';

  @override
  String get ccTypeMultipleChoice => 'Multiple Choice';

  @override
  String get ccTypeEssay => 'Essay';

  @override
  String get ccQuestionCountLabel => 'Number of Questions';

  @override
  String get ccQuestionCountHint => 'e.g., 5';

  @override
  String get ccGenerateMC => 'Generate Questions';

  @override
  String get ccGenerateEssay => 'Generate Essay Questions';

  @override
  String get ccSaveToBank => 'Save to Question Bank';

  @override
  String get ccEditQuestion => 'Edit Question';

  @override
  String get ccQuestionLabel => 'Questions';

  @override
  String get ccOptionA => 'Option A';

  @override
  String get ccOptionB => 'Option B';

  @override
  String get ccOptionC => 'Option C';

  @override
  String get ccOptionD => 'Option D';

  @override
  String get ccCorrectAnswer => 'Correct Answer';

  @override
  String get ccRubric => 'Scoring Rubric';

  @override
  String get ccFeedback => 'Feedback';

  @override
  String get ccSaved => 'Questions saved to bank!';

  @override
  String get ccNoQuestions => 'No questions generated yet.';

  @override
  String get ccParseError => 'Failed to parse AI response. Please try again.';

  @override
  String get qbTitle => 'Question Bank';

  @override
  String get qbEmpty => 'No questions in the bank yet.';

  @override
  String get qbDeleteConfirm => 'Delete this question?';

  @override
  String get qbDeleted => 'Question deleted';

  @override
  String get qbRecentQuestions => 'Recent Questions';

  @override
  String get ccErrorTimeout =>
      'AI is taking too long to respond. Try reducing the number of questions.';

  @override
  String get mcJoiningClass => 'Joining class...';
}
