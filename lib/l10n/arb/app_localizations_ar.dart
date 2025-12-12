// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Sikolah Apps';

  @override
  String get welcomeMessage => 'مرحبًا بكم في منصة التعليم المتكيف';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageEnglish => 'الإنجليزية';

  @override
  String get settingsLanguageIndonesian => 'الإندونيسية';

  @override
  String get onboardingTitle1 => 'مرحبًا بكم في التعلم المتكيف';

  @override
  String get onboardingDesc1 => 'تجربة تعلم مخصصة مدعومة بالذكاء الاصطناعي.';

  @override
  String get onboardingTitle2 => 'تتبع تقدمك';

  @override
  String get onboardingDesc2 => 'راقب إنجازاتك ونموك بمرور الوقت.';

  @override
  String get onboardingTitle3 => 'تواصل مع المعلمين';

  @override
  String get onboardingDesc3 => 'احصل على التوجيه والدعم من معلميك.';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingJoinCommunity =>
      'انضم إلى مجتمع المتعلمين والمعلمين لدينا.';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginButton => 'دخول';

  @override
  String get registerButton => 'تسجيل';

  @override
  String get registerLink => 'جديد هنا؟ إنشاء حساب';

  @override
  String get roleStudent => 'طالب';

  @override
  String get roleTeacher => 'معلم';

  @override
  String get labelNISN => 'NISN (رقم الطالب)';

  @override
  String get labelNUPTK => 'NUPTK (رقم المعلم)';

  @override
  String get labelPIN => 'الرمز السري';

  @override
  String get labelIdentifier => 'المعرف';

  @override
  String get errorEmptyNISN => 'يرجى إدخال رقم الطالب';

  @override
  String get errorEmptyNUPTK => 'يرجى إدخال رقم المعلم';

  @override
  String get errorEmptyPIN => 'يرجى إدخال الرمز السري';

  @override
  String get errorShortPIN => 'الرمز السري يجب أن يكون 4 أرقام على الأقل';

  @override
  String get registerTitle => 'تسجيل';

  @override
  String get labelName => 'الاسم الكامل';

  @override
  String get labelDateOfBirth => 'تاريخ الميلاد';

  @override
  String get errorEmptyName => 'يرجى إدخال اسمك';

  @override
  String get errorEmptyDate => 'يرجى إدخال تاريخ ميلادك';

  @override
  String get loginLink => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get registerSelectRole => 'اختر دورك';

  @override
  String get registerStudentTitle => 'تسجيل الطلاب';

  @override
  String get registerTeacherTitle => 'تسجيل المعلمين';

  @override
  String get labelConfirmPIN => 'تأكيد الرمز السري';

  @override
  String get helperPIN => 'أنشئ رمزًا سريًا من 4 أرقام للأمان';

  @override
  String get errorConfirmPIN => 'يرجى تأكيد الرمز السري';

  @override
  String get errorMatchPIN => 'الرموز السرية غير متطابقة';

  @override
  String get labelSelectDate => 'اختر التاريخ';

  @override
  String get errorNISNLength => 'رقم الطالب يجب أن يكون 10 أرقام';

  @override
  String get errorNUPTKLength => 'رقم المعلم يجب أن يكون 16 رقمًا';

  @override
  String get errorPINLength => 'الرمز السري يجب أن يكون 4 أرقام بالضبط';

  @override
  String get buttonNext => 'التالي';

  @override
  String get buttonBack => 'السابق';

  @override
  String get registrationSuccessTitle => 'تم التسجيل بنجاح';

  @override
  String registrationSuccessContent(Object identifier) {
    return 'تم تسجيل المستخدم $identifier بنجاح. يرجى تسجيل الدخول.';
  }

  @override
  String get buttonOK => 'حسناً';

  @override
  String get dashboardStudent => 'بوابة الطالب';

  @override
  String get dashboardTeacher => 'بوابة المعلم';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navSettings => 'إعدادات الملف الشخصي';

  @override
  String get navEditProfile => 'تعديل الملف الشخصي';

  @override
  String get navSwitchUser => 'تبديل المستخدم';

  @override
  String get navChangePin => 'تغيير الرمز السري';

  @override
  String get changePinTitle => 'تغيير الرمز السري';

  @override
  String get changePinCurrentLabel => 'الرمز السري الحالي';

  @override
  String get changePinNewLabel => 'الرمز السري الجديد';

  @override
  String get changePinConfirmLabel => 'تأكيد الرمز السري الجديد';

  @override
  String get changePinSuccess => 'تم تغيير الرمز السري بنجاح!';

  @override
  String get changePinErrorCurrent => 'الرمز السري الحالي غير صحيح';

  @override
  String get changePinErrorEmpty => 'يرجى ملء جميع الحقول';

  @override
  String get navLogout => 'تسجيل الخروج';

  @override
  String get navLanguage => 'اللغة';

  @override
  String get tileAITutor => 'المعلم الذكي';

  @override
  String get tileMyCourses => 'دوراتي';

  @override
  String get tileProgress => 'التقدم';

  @override
  String get tileAIAssistant => 'مساعد الذكاء الاصطناعي';

  @override
  String get tileCreateContent => 'إنشاء محتوى';

  @override
  String get tileAnalytics => 'تحليلات الطلاب';

  @override
  String get tileManageClass => 'إدارة الفصل';

  @override
  String get aiAssistantTitle => 'إعدادات مساعد الذكاء الاصطناعي';

  @override
  String get activeProvider => 'المزود النشط';

  @override
  String get allProviders => 'جميع المزودين';

  @override
  String get noApiKey => 'مفتاح API غير مكوّن';

  @override
  String get active => 'نشط';

  @override
  String get labelBaseUrl => 'الرابط الأساسي';

  @override
  String get labelApiKey => 'مفتاح API';

  @override
  String get resetUrl => 'إعادة تعيين الرابط';

  @override
  String get saveAndActivate => 'حفظ وتفعيل';

  @override
  String get providerSaved => 'تم حفظ الإعدادات وتفعيل المزود';

  @override
  String get labelModel => 'نموذج';

  @override
  String get fetchModels => 'جلب النماذج';

  @override
  String get themePlayful => 'تبديل إلى جاد';

  @override
  String get themeSerious => 'تبديل إلى مرح';

  @override
  String get featureComingSoon => 'الميزة قادمة قريباً!';

  @override
  String get ccTitle => 'إنشاء محتوى';

  @override
  String get ccSnackBarError => 'يرجى إدخال الموضوع والصف الدراسي';

  @override
  String get ccErrorApiKey =>
      'مفتاح API غير موجود. يرجى التحقق من إعدادات الملف الشخصي.';

  @override
  String get ccTopicLabel => 'الموضوع';

  @override
  String get ccTopicHint => 'مثال: البناء الضوئي';

  @override
  String get ccGradeLabel => 'الصف الدراسي';

  @override
  String get ccGradeHint => 'مثال: الصف الخامس';

  @override
  String get ccGenerateButton => 'إنشاء خطة الدرس';

  @override
  String get ccContentPlaceholder => 'المحتوى المُنشأ سيظهر هنا...';

  @override
  String ccErrorGenerating(Object error) {
    return 'خطأ في إنشاء المحتوى: $error';
  }

  @override
  String get mcTitle => 'إدارة الفصول';

  @override
  String mcSnackBarCreated(Object name, Object pin) {
    return 'تم إنشاء الفصل \"$name\"! الرمز السري: $pin';
  }

  @override
  String mcErrorCreating(Object error) {
    return 'خطأ في إنشاء الفصل: $error';
  }

  @override
  String get mcDialogTitle => 'إنشاء فصل جديد';

  @override
  String get mcClassNameLabel => 'اسم الفصل';

  @override
  String get mcClassDescLabel => 'الوصف (اختياري)';

  @override
  String get mcEnrolledStudents => 'الطلاب المسجلين:';

  @override
  String get mcNoStudents => 'لا يوجد طلاب بعد.';

  @override
  String get mcFabCreate => 'إنشاء فصل';

  @override
  String get mcNoClasses => 'لم يتم إنشاء فصول بعد.';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonCreate => 'إنشاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get usTitle => 'اختر المستخدم';

  @override
  String usEnterPin(Object name) {
    return 'أدخل الرمز السري لـ $name';
  }

  @override
  String get usLabelPin => 'الرمز السري';

  @override
  String get usVerify => 'تحقق';

  @override
  String get usIncorrectPin => 'الرمز السري غير صحيح';

  @override
  String get usSetPinTitle => 'عيّن الرمز السري';

  @override
  String get usSetPinMsg => 'يرجى تعيين رمز سري من 4 أرقام للأمان';

  @override
  String get usConfirmPin => 'تأكيد الرمز السري';

  @override
  String get usPinMismatch => 'الرموز السرية غير متطابقة';

  @override
  String get usPinLength => 'الرمز السري يجب أن يكون 4 أرقام';

  @override
  String get usSetPinButton => 'حفظ الرمز السري';

  @override
  String get usNoUsers => 'لم يتم تسجيل مستخدمين بعد';

  @override
  String get usAddUser => 'إضافة مستخدم جديد';

  @override
  String get profileTitle => 'الملف الشخصي والإعدادات';

  @override
  String get profileGeminiConfig => 'إعدادات Gemini API';

  @override
  String get profileApiKey => 'مفتاح API';

  @override
  String get profileApiKeySaved => 'تم حفظ مفتاح API';

  @override
  String get profileSelectModel => 'اختر النموذج';

  @override
  String get profileRefreshModels => 'تحديث النماذج';

  @override
  String get profileNoModels => 'لم يتم العثور على نماذج. تحقق من مفتاح API.';

  @override
  String get profileSaveModel => 'حفظ النموذج';

  @override
  String get profileModelSaved => 'تم حفظ النموذج بنجاح!';

  @override
  String get aiTutorTitle => 'المعلم الذكي';

  @override
  String get aiTutorSystemPrompt =>
      'أنت معلم ذكاء اصطناعي مفيد واسع المعرفة للطلاب. اشرح المفاهيم بوضوح وصبر باللغة التي يسأل بها الطالب.';

  @override
  String get aiTutorErrorApiKey =>
      'مفتاح API غير موجود. يرجى التحقق من إعدادات الملف الشخصي.';

  @override
  String get aiTutorHint => 'اسأل معلمك...';

  @override
  String aiTutorError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get mcCoursesTitle => 'دوراتي';

  @override
  String get mcJoinClass => 'الانضمام لفصل';

  @override
  String get mcClassNotFound => 'لم يتم العثور على فصل بهذا الرمز';

  @override
  String get mcAlreadyEnrolled => 'أنت مسجل بالفعل في هذا الفصل';

  @override
  String mcJoinedSuccess(Object name) {
    return 'تم الانضمام للفصل \"$name\"!';
  }

  @override
  String mcErrorJoining(Object error) {
    return 'خطأ في الانضمام للفصل: $error';
  }

  @override
  String get mcJoinDialogTitle => 'الانضمام لفصل';

  @override
  String get mcEnterPinLabel => 'أدخل رمز الفصل';

  @override
  String get mcCommonJoin => 'انضمام';

  @override
  String get mcNoCourses => 'لم تنضم لأي فصول بعد.';

  @override
  String mcTeacherPrefix(Object name) {
    return 'المعلم: $name';
  }

  @override
  String get languageSelectorTooltip => 'اختر اللغة';

  @override
  String get ccContentTypeLabel => 'نوع المحتوى';

  @override
  String get ccTypeLessonPlan => 'خطة الدرس';

  @override
  String get ccTypeMultipleChoice => 'اختيار من متعدد';

  @override
  String get ccTypeEssay => 'مقالي';

  @override
  String get ccQuestionCountLabel => 'عدد الأسئلة';

  @override
  String get ccQuestionCountHint => 'مثال: 5';

  @override
  String get ccGenerateMC => 'إنشاء الأسئلة';

  @override
  String get ccGenerateEssay => 'إنشاء أسئلة مقالية';

  @override
  String get ccSaveToBank => 'حفظ في بنك الأسئلة';

  @override
  String get ccEditQuestion => 'تعديل السؤال';

  @override
  String get ccQuestionLabel => 'أسئلة';

  @override
  String get ccOptionA => 'الخيار أ';

  @override
  String get ccOptionB => 'الخيار ب';

  @override
  String get ccOptionC => 'الخيار ج';

  @override
  String get ccOptionD => 'الخيار د';

  @override
  String get ccCorrectAnswer => 'الإجابة الصحيحة';

  @override
  String get ccRubric => 'نموذج التقييم';

  @override
  String get ccFeedback => 'التغذية الراجعة';

  @override
  String get ccSaved => 'تم حفظ الأسئلة!';

  @override
  String get ccNoQuestions => 'لم يتم إنشاء أسئلة بعد.';

  @override
  String get ccParseError =>
      'فشل في تحليل استجابة الذكاء الاصطناعي. حاول مرة أخرى.';

  @override
  String get qbTitle => 'بنك الأسئلة';

  @override
  String get qbEmpty => 'لا توجد أسئلة في البنك بعد.';

  @override
  String get qbDeleteConfirm => 'حذف هذا السؤال؟';

  @override
  String get qbDeleted => 'تم حذف السؤال';

  @override
  String get qbRecentQuestions => 'أحدث الأسئلة';

  @override
  String get ccErrorTimeout =>
      'يستغرق الذكاء الاصطناعي وقتًا طويلاً للاستجابة. حاول تقليل عدد الأسئلة.';

  @override
  String get mcJoiningClass => 'جاري الانضمام إلى الفصل...';
}
