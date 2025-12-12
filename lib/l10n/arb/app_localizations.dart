import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('id'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Sikolah Apps'**
  String get appTitle;

  /// Welcome message on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Adaptive Learning Platform'**
  String get welcomeMessage;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get settingsLanguageIndonesian;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Adaptive Learning'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Personalized learning experience powered by AI.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Track Your Progress'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Monitor your achievements and growth over time.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Connect with Teachers'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Get guidance and support from your educators.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join our community of learners and educators.'**
  String get onboardingJoinCommunity;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get registerLink;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @labelNISN.
  ///
  /// In en, this message translates to:
  /// **'NISN'**
  String get labelNISN;

  /// No description provided for @labelNUPTK.
  ///
  /// In en, this message translates to:
  /// **'NUPTK'**
  String get labelNUPTK;

  /// No description provided for @labelPIN.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get labelPIN;

  /// No description provided for @labelIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Identifier'**
  String get labelIdentifier;

  /// No description provided for @errorEmptyNISN.
  ///
  /// In en, this message translates to:
  /// **'Please enter your NISN'**
  String get errorEmptyNISN;

  /// No description provided for @errorEmptyNUPTK.
  ///
  /// In en, this message translates to:
  /// **'Please enter your NUPTK'**
  String get errorEmptyNUPTK;

  /// No description provided for @errorEmptyPIN.
  ///
  /// In en, this message translates to:
  /// **'Please enter your PIN'**
  String get errorEmptyPIN;

  /// No description provided for @errorShortPIN.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get errorShortPIN;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get labelName;

  /// No description provided for @labelDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get labelDateOfBirth;

  /// No description provided for @errorEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get errorEmptyName;

  /// No description provided for @errorEmptyDate.
  ///
  /// In en, this message translates to:
  /// **'Please enter your date of birth'**
  String get errorEmptyDate;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get loginLink;

  /// No description provided for @registerSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get registerSelectRole;

  /// No description provided for @registerStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Registration'**
  String get registerStudentTitle;

  /// No description provided for @registerTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Registration'**
  String get registerTeacherTitle;

  /// No description provided for @labelConfirmPIN.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get labelConfirmPIN;

  /// No description provided for @helperPIN.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN for security'**
  String get helperPIN;

  /// No description provided for @errorConfirmPIN.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your PIN'**
  String get errorConfirmPIN;

  /// No description provided for @errorMatchPIN.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get errorMatchPIN;

  /// No description provided for @labelSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get labelSelectDate;

  /// No description provided for @errorNISNLength.
  ///
  /// In en, this message translates to:
  /// **'NISN must be 10 digits'**
  String get errorNISNLength;

  /// No description provided for @errorNUPTKLength.
  ///
  /// In en, this message translates to:
  /// **'NUPTK must be 16 digits'**
  String get errorNUPTKLength;

  /// No description provided for @errorPINLength.
  ///
  /// In en, this message translates to:
  /// **'PIN must be exactly 4 digits'**
  String get errorPINLength;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get buttonNext;

  /// No description provided for @buttonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get buttonBack;

  /// No description provided for @registrationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registrationSuccessTitle;

  /// No description provided for @registrationSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'User {identifier} registered successfully. Please login.'**
  String registrationSuccessContent(Object identifier);

  /// No description provided for @buttonOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get buttonOK;

  /// No description provided for @dashboardStudent.
  ///
  /// In en, this message translates to:
  /// **'Student Portal'**
  String get dashboardStudent;

  /// No description provided for @dashboardTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher Portal'**
  String get dashboardTeacher;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get navSettings;

  /// No description provided for @navEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get navEditProfile;

  /// No description provided for @navSwitchUser.
  ///
  /// In en, this message translates to:
  /// **'Switch User'**
  String get navSwitchUser;

  /// No description provided for @navChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get navChangePin;

  /// No description provided for @changePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinTitle;

  /// No description provided for @changePinCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get changePinCurrentLabel;

  /// No description provided for @changePinNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get changePinNewLabel;

  /// No description provided for @changePinConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New PIN'**
  String get changePinConfirmLabel;

  /// No description provided for @changePinSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully!'**
  String get changePinSuccess;

  /// No description provided for @changePinErrorCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current PIN is incorrect'**
  String get changePinErrorCurrent;

  /// No description provided for @changePinErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get changePinErrorEmpty;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get navLogout;

  /// No description provided for @navLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get navLanguage;

  /// No description provided for @tileAITutor.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get tileAITutor;

  /// No description provided for @tileMyCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get tileMyCourses;

  /// No description provided for @tileProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tileProgress;

  /// No description provided for @tileAIAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get tileAIAssistant;

  /// No description provided for @tileCreateContent.
  ///
  /// In en, this message translates to:
  /// **'Create Content'**
  String get tileCreateContent;

  /// No description provided for @tileAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Student Analytics'**
  String get tileAnalytics;

  /// No description provided for @tileManageClass.
  ///
  /// In en, this message translates to:
  /// **'Manage Class'**
  String get tileManageClass;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant Settings'**
  String get aiAssistantTitle;

  /// No description provided for @activeProvider.
  ///
  /// In en, this message translates to:
  /// **'Active Provider'**
  String get activeProvider;

  /// No description provided for @allProviders.
  ///
  /// In en, this message translates to:
  /// **'All Providers'**
  String get allProviders;

  /// No description provided for @noApiKey.
  ///
  /// In en, this message translates to:
  /// **'No API Key configured'**
  String get noApiKey;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @labelBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get labelBaseUrl;

  /// No description provided for @labelApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get labelApiKey;

  /// No description provided for @resetUrl.
  ///
  /// In en, this message translates to:
  /// **'Reset URL'**
  String get resetUrl;

  /// No description provided for @saveAndActivate.
  ///
  /// In en, this message translates to:
  /// **'Save & Activate'**
  String get saveAndActivate;

  /// No description provided for @providerSaved.
  ///
  /// In en, this message translates to:
  /// **'Provider settings saved and activated'**
  String get providerSaved;

  /// No description provided for @labelModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get labelModel;

  /// No description provided for @fetchModels.
  ///
  /// In en, this message translates to:
  /// **'Fetch Models'**
  String get fetchModels;

  /// No description provided for @themePlayful.
  ///
  /// In en, this message translates to:
  /// **'Switch to Serious'**
  String get themePlayful;

  /// No description provided for @themeSerious.
  ///
  /// In en, this message translates to:
  /// **'Switch to Playful'**
  String get themeSerious;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon!'**
  String get featureComingSoon;

  /// No description provided for @ccTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Content'**
  String get ccTitle;

  /// No description provided for @ccSnackBarError.
  ///
  /// In en, this message translates to:
  /// **'Please enter both topic and grade level'**
  String get ccSnackBarError;

  /// No description provided for @ccErrorApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key not found. Please check your Profile settings.'**
  String get ccErrorApiKey;

  /// No description provided for @ccTopicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get ccTopicLabel;

  /// No description provided for @ccTopicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Photosynthesis'**
  String get ccTopicHint;

  /// No description provided for @ccGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade Level'**
  String get ccGradeLabel;

  /// No description provided for @ccGradeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 5th Grade'**
  String get ccGradeHint;

  /// No description provided for @ccGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Lesson Plan'**
  String get ccGenerateButton;

  /// No description provided for @ccContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Generated content will appear here...'**
  String get ccContentPlaceholder;

  /// No description provided for @ccErrorGenerating.
  ///
  /// In en, this message translates to:
  /// **'Error generating content: {error}'**
  String ccErrorGenerating(Object error);

  /// No description provided for @mcTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Classes'**
  String get mcTitle;

  /// No description provided for @mcSnackBarCreated.
  ///
  /// In en, this message translates to:
  /// **'Class \"{name}\" created! PIN: {pin}'**
  String mcSnackBarCreated(Object name, Object pin);

  /// No description provided for @mcErrorCreating.
  ///
  /// In en, this message translates to:
  /// **'Error creating class: {error}'**
  String mcErrorCreating(Object error);

  /// No description provided for @mcDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Class'**
  String get mcDialogTitle;

  /// No description provided for @mcClassNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get mcClassNameLabel;

  /// No description provided for @mcClassDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get mcClassDescLabel;

  /// No description provided for @mcEnrolledStudents.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Students:'**
  String get mcEnrolledStudents;

  /// No description provided for @mcNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students yet.'**
  String get mcNoStudents;

  /// No description provided for @mcFabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Class'**
  String get mcFabCreate;

  /// No description provided for @mcNoClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes created yet.'**
  String get mcNoClasses;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @usTitle.
  ///
  /// In en, this message translates to:
  /// **'Select User'**
  String get usTitle;

  /// No description provided for @usEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN for {name}'**
  String usEnterPin(Object name);

  /// No description provided for @usLabelPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get usLabelPin;

  /// No description provided for @usVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get usVerify;

  /// No description provided for @usIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get usIncorrectPin;

  /// No description provided for @usSetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Your PIN'**
  String get usSetPinTitle;

  /// No description provided for @usSetPinMsg.
  ///
  /// In en, this message translates to:
  /// **'Please set a 4-digit PIN for security'**
  String get usSetPinMsg;

  /// No description provided for @usConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get usConfirmPin;

  /// No description provided for @usPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get usPinMismatch;

  /// No description provided for @usPinLength.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 digits'**
  String get usPinLength;

  /// No description provided for @usSetPinButton.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get usSetPinButton;

  /// No description provided for @usNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users registered yet'**
  String get usNoUsers;

  /// No description provided for @usAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get usAddUser;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileTitle;

  /// No description provided for @profileGeminiConfig.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Configuration'**
  String get profileGeminiConfig;

  /// No description provided for @profileApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get profileApiKey;

  /// No description provided for @profileApiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API Key Saved'**
  String get profileApiKeySaved;

  /// No description provided for @profileSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get profileSelectModel;

  /// No description provided for @profileRefreshModels.
  ///
  /// In en, this message translates to:
  /// **'Refresh Models'**
  String get profileRefreshModels;

  /// No description provided for @profileNoModels.
  ///
  /// In en, this message translates to:
  /// **'No models found. Check your API Key.'**
  String get profileNoModels;

  /// No description provided for @profileSaveModel.
  ///
  /// In en, this message translates to:
  /// **'Save Model'**
  String get profileSaveModel;

  /// No description provided for @profileModelSaved.
  ///
  /// In en, this message translates to:
  /// **'Model saved successfully!'**
  String get profileModelSaved;

  /// No description provided for @aiTutorTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get aiTutorTitle;

  /// No description provided for @aiTutorSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are a helpful and knowledgeable AI tutor for students. Explain concepts clearly and patiently in the language the student asks in.'**
  String get aiTutorSystemPrompt;

  /// No description provided for @aiTutorErrorApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key not found. Please check your Profile settings.'**
  String get aiTutorErrorApiKey;

  /// No description provided for @aiTutorHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your tutor...'**
  String get aiTutorHint;

  /// No description provided for @aiTutorError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String aiTutorError(Object error);

  /// No description provided for @mcCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get mcCoursesTitle;

  /// No description provided for @mcJoinClass.
  ///
  /// In en, this message translates to:
  /// **'Join Class'**
  String get mcJoinClass;

  /// No description provided for @mcClassNotFound.
  ///
  /// In en, this message translates to:
  /// **'Class not found with that PIN'**
  String get mcClassNotFound;

  /// No description provided for @mcAlreadyEnrolled.
  ///
  /// In en, this message translates to:
  /// **'You are already enrolled in this class'**
  String get mcAlreadyEnrolled;

  /// No description provided for @mcJoinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined class \"{name}\"!'**
  String mcJoinedSuccess(Object name);

  /// No description provided for @mcErrorJoining.
  ///
  /// In en, this message translates to:
  /// **'Error joining class: {error}'**
  String mcErrorJoining(Object error);

  /// No description provided for @mcJoinDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Class'**
  String get mcJoinDialogTitle;

  /// No description provided for @mcEnterPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter Class PIN'**
  String get mcEnterPinLabel;

  /// No description provided for @mcCommonJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get mcCommonJoin;

  /// No description provided for @mcNoCourses.
  ///
  /// In en, this message translates to:
  /// **'You have not joined any classes yet.'**
  String get mcNoCourses;

  /// No description provided for @mcTeacherPrefix.
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String mcTeacherPrefix(Object name);

  /// No description provided for @languageSelectorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageSelectorTooltip;

  /// No description provided for @ccContentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get ccContentTypeLabel;

  /// No description provided for @ccTypeLessonPlan.
  ///
  /// In en, this message translates to:
  /// **'Lesson Plan'**
  String get ccTypeLessonPlan;

  /// No description provided for @ccTypeMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get ccTypeMultipleChoice;

  /// No description provided for @ccTypeEssay.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get ccTypeEssay;

  /// No description provided for @ccQuestionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get ccQuestionCountLabel;

  /// No description provided for @ccQuestionCountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 5'**
  String get ccQuestionCountHint;

  /// No description provided for @ccGenerateMC.
  ///
  /// In en, this message translates to:
  /// **'Generate Questions'**
  String get ccGenerateMC;

  /// No description provided for @ccGenerateEssay.
  ///
  /// In en, this message translates to:
  /// **'Generate Essay Questions'**
  String get ccGenerateEssay;

  /// No description provided for @ccSaveToBank.
  ///
  /// In en, this message translates to:
  /// **'Save to Question Bank'**
  String get ccSaveToBank;

  /// No description provided for @ccEditQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get ccEditQuestion;

  /// No description provided for @ccQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get ccQuestionLabel;

  /// No description provided for @ccOptionA.
  ///
  /// In en, this message translates to:
  /// **'Option A'**
  String get ccOptionA;

  /// No description provided for @ccOptionB.
  ///
  /// In en, this message translates to:
  /// **'Option B'**
  String get ccOptionB;

  /// No description provided for @ccOptionC.
  ///
  /// In en, this message translates to:
  /// **'Option C'**
  String get ccOptionC;

  /// No description provided for @ccOptionD.
  ///
  /// In en, this message translates to:
  /// **'Option D'**
  String get ccOptionD;

  /// No description provided for @ccCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get ccCorrectAnswer;

  /// No description provided for @ccRubric.
  ///
  /// In en, this message translates to:
  /// **'Scoring Rubric'**
  String get ccRubric;

  /// No description provided for @ccFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get ccFeedback;

  /// No description provided for @ccSaved.
  ///
  /// In en, this message translates to:
  /// **'Questions saved to bank!'**
  String get ccSaved;

  /// No description provided for @ccNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions generated yet.'**
  String get ccNoQuestions;

  /// No description provided for @ccParseError.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse AI response. Please try again.'**
  String get ccParseError;

  /// No description provided for @qbTitle.
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get qbTitle;

  /// No description provided for @qbEmpty.
  ///
  /// In en, this message translates to:
  /// **'No questions in the bank yet.'**
  String get qbEmpty;

  /// No description provided for @qbDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this question?'**
  String get qbDeleteConfirm;

  /// No description provided for @qbDeleted.
  ///
  /// In en, this message translates to:
  /// **'Question deleted'**
  String get qbDeleted;

  /// No description provided for @qbRecentQuestions.
  ///
  /// In en, this message translates to:
  /// **'Recent Questions'**
  String get qbRecentQuestions;

  /// No description provided for @ccErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'AI is taking too long to respond. Try reducing the number of questions.'**
  String get ccErrorTimeout;

  /// No description provided for @mcJoiningClass.
  ///
  /// In en, this message translates to:
  /// **'Joining class...'**
  String get mcJoiningClass;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
