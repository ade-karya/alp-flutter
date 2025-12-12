// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Sikolah Apps';

  @override
  String get welcomeMessage =>
      'Selamat datang di Platform Pembelajaran Adaptif';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageEnglish => 'Inggris';

  @override
  String get settingsLanguageIndonesian => 'Indonesia';

  @override
  String get onboardingTitle1 => 'Selamat Datang di Pembelajaran Adaptif';

  @override
  String get onboardingDesc1 =>
      'Pengalaman belajar yang dipersonalisasi didukung oleh AI.';

  @override
  String get onboardingTitle2 => 'Pantau Kemajuan Anda';

  @override
  String get onboardingDesc2 =>
      'Pantau pencapaian dan pertumbuhan Anda dari waktu ke waktu.';

  @override
  String get onboardingTitle3 => 'Terhubung dengan Guru';

  @override
  String get onboardingDesc3 =>
      'Dapatkan bimbingan dan dukungan dari pendidik Anda.';

  @override
  String get onboardingGetStarted => 'Mulai Sekarang';

  @override
  String get onboardingJoinCommunity =>
      'Bergabunglah dengan komunitas pembelajar dan pendidik kami.';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginButton => 'Masuk';

  @override
  String get registerButton => 'Daftar';

  @override
  String get registerLink => 'Belum punya akun? Buat akun baru';

  @override
  String get roleStudent => 'Siswa';

  @override
  String get roleTeacher => 'Guru';

  @override
  String get labelNISN => 'NISN';

  @override
  String get labelNUPTK => 'NUPTK';

  @override
  String get labelPIN => 'PIN';

  @override
  String get labelIdentifier => 'Pengenal';

  @override
  String get errorEmptyNISN => 'Mohon masukkan NISN Anda';

  @override
  String get errorEmptyNUPTK => 'Mohon masukkan NUPTK Anda';

  @override
  String get errorEmptyPIN => 'Mohon masukkan PIN Anda';

  @override
  String get errorShortPIN => 'PIN harus minimal 4 digit';

  @override
  String get registerTitle => 'Daftar';

  @override
  String get labelName => 'Nama Lengkap';

  @override
  String get labelDateOfBirth => 'Tanggal Lahir';

  @override
  String get errorEmptyName => 'Mohon masukkan nama Anda';

  @override
  String get errorEmptyDate => 'Mohon masukkan tanggal lahir Anda';

  @override
  String get loginLink => 'Sudah punya akun? Masuk';

  @override
  String get registerSelectRole => 'Pilih Peran Anda';

  @override
  String get registerStudentTitle => 'Pendaftaran Siswa';

  @override
  String get registerTeacherTitle => 'Pendaftaran Guru';

  @override
  String get labelConfirmPIN => 'Konfirmasi PIN';

  @override
  String get helperPIN => 'Buat 4 digit PIN untuk keamanan';

  @override
  String get errorConfirmPIN => 'Mohon konfirmasi PIN Anda';

  @override
  String get errorMatchPIN => 'PIN tidak cocok';

  @override
  String get labelSelectDate => 'Pilih tanggal';

  @override
  String get errorNISNLength => 'NISN harus 10 digit';

  @override
  String get errorNUPTKLength => 'NUPTK harus 16 digit';

  @override
  String get errorPINLength => 'PIN harus tepat 4 digit';

  @override
  String get buttonNext => 'Lanjut';

  @override
  String get buttonBack => 'Kembali';

  @override
  String get registrationSuccessTitle => 'Pendaftaran Berhasil';

  @override
  String registrationSuccessContent(Object identifier) {
    return 'Pengguna $identifier berhasil terdaftar. Silakan masuk.';
  }

  @override
  String get buttonOK => 'OK';

  @override
  String get dashboardStudent => 'Portal Siswa';

  @override
  String get dashboardTeacher => 'Portal Guru';

  @override
  String get navDashboard => 'Dasbor';

  @override
  String get navSettings => 'Pengaturan Profil';

  @override
  String get navEditProfile => 'Edit Profil';

  @override
  String get navSwitchUser => 'Ganti Pengguna';

  @override
  String get navChangePin => 'Ubah PIN';

  @override
  String get changePinTitle => 'Ubah PIN';

  @override
  String get changePinCurrentLabel => 'PIN Saat Ini';

  @override
  String get changePinNewLabel => 'PIN Baru';

  @override
  String get changePinConfirmLabel => 'Konfirmasi PIN Baru';

  @override
  String get changePinSuccess => 'PIN berhasil diubah!';

  @override
  String get changePinErrorCurrent => 'PIN saat ini salah';

  @override
  String get changePinErrorEmpty => 'Mohon isi semua kolom';

  @override
  String get navLogout => 'Keluar';

  @override
  String get navLanguage => 'Bahasa';

  @override
  String get tileAITutor => 'Tutor AI';

  @override
  String get tileMyCourses => 'Kursus Saya';

  @override
  String get tileProgress => 'Kemajuan';

  @override
  String get tileAIAssistant => 'Asisten AI';

  @override
  String get tileCreateContent => 'Buat Konten';

  @override
  String get tileAnalytics => 'Analitik Siswa';

  @override
  String get tileManageClass => 'Kelola Kelas';

  @override
  String get aiAssistantTitle => 'Pengaturan Asisten AI';

  @override
  String get activeProvider => 'Provider Aktif';

  @override
  String get allProviders => 'Semua Provider';

  @override
  String get noApiKey => 'API Key belum dikonfigurasi';

  @override
  String get active => 'Aktif';

  @override
  String get labelBaseUrl => 'URL Dasar';

  @override
  String get labelApiKey => 'API Key';

  @override
  String get resetUrl => 'Reset URL';

  @override
  String get saveAndActivate => 'Simpan & Aktifkan';

  @override
  String get providerSaved => 'Pengaturan provider disimpan dan diaktifkan';

  @override
  String get labelModel => 'Model';

  @override
  String get fetchModels => 'Ambil Model';

  @override
  String get themePlayful => 'Ubah ke Serius';

  @override
  String get themeSerious => 'Ubah ke Ceria';

  @override
  String get featureComingSoon => 'Fitur segera hadir!';

  @override
  String get ccTitle => 'Buat Konten';

  @override
  String get ccSnackBarError => 'Mohon masukkan topik dan tingkat kelas';

  @override
  String get ccErrorApiKey => 'API Key tidak ditemukan. Cek pengaturan Profil.';

  @override
  String get ccTopicLabel => 'Topik';

  @override
  String get ccTopicHint => 'cth., Fotosintesis';

  @override
  String get ccGradeLabel => 'Tingkat Kelas';

  @override
  String get ccGradeHint => 'cth., Kelas 5 SD';

  @override
  String get ccGenerateButton => 'Buat Rencana Pembelajaran';

  @override
  String get ccContentPlaceholder =>
      'Konten yang dibuat akan muncul di sini...';

  @override
  String ccErrorGenerating(Object error) {
    return 'Gagal membuat konten: $error';
  }

  @override
  String get mcTitle => 'Kelola Kelas';

  @override
  String mcSnackBarCreated(Object name, Object pin) {
    return 'Kelas \"$name\" dibuat! PIN: $pin';
  }

  @override
  String mcErrorCreating(Object error) {
    return 'Gagal membuat kelas: $error';
  }

  @override
  String get mcDialogTitle => 'Buat Kelas Baru';

  @override
  String get mcClassNameLabel => 'Nama Kelas';

  @override
  String get mcClassDescLabel => 'Deskripsi (Opsional)';

  @override
  String get mcEnrolledStudents => 'Siswa Terdaftar:';

  @override
  String get mcNoStudents => 'Belum ada siswa.';

  @override
  String get mcFabCreate => 'Buat Kelas';

  @override
  String get mcNoClasses => 'Belum ada kelas yang dibuat.';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonCreate => 'Buat';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonClose => 'Tutup';

  @override
  String get usTitle => 'Pilih Pengguna';

  @override
  String usEnterPin(Object name) {
    return 'Masukkan PIN untuk $name';
  }

  @override
  String get usLabelPin => 'PIN';

  @override
  String get usVerify => 'Verifikasi';

  @override
  String get usIncorrectPin => 'PIN Salah';

  @override
  String get usSetPinTitle => 'Atur PIN Anda';

  @override
  String get usSetPinMsg => 'Buat PIN 4 digit untuk keamanan';

  @override
  String get usConfirmPin => 'Konfirmasi PIN';

  @override
  String get usPinMismatch => 'PIN tidak cocok';

  @override
  String get usPinLength => 'PIN harus 4 digit';

  @override
  String get usSetPinButton => 'Simpan PIN';

  @override
  String get usNoUsers => 'Belum ada pengguna terdaftar';

  @override
  String get usAddUser => 'Tambah Pengguna Baru';

  @override
  String get profileTitle => 'Profil & Pengaturan';

  @override
  String get profileGeminiConfig => 'Konfigurasi Gemini API';

  @override
  String get profileApiKey => 'API Key';

  @override
  String get profileApiKeySaved => 'API Key Disimpan';

  @override
  String get profileSelectModel => 'Pilih Model';

  @override
  String get profileRefreshModels => 'Segarkan Model';

  @override
  String get profileNoModels => 'Model tidak ditemukan. Cek API Key Anda.';

  @override
  String get profileSaveModel => 'Simpan Model';

  @override
  String get profileModelSaved => 'Model berhasil disimpan!';

  @override
  String get aiTutorTitle => 'Tutor AI';

  @override
  String get aiTutorSystemPrompt =>
      'Anda adalah tutor AI yang membantu dan berpengetahuan luas untuk siswa. Jelaskan konsep dengan jelas dan sabar dalam bahasa yang diminta siswa.';

  @override
  String get aiTutorErrorApiKey =>
      'API Key tidak ditemukan. Cek pengaturan Profil Anda.';

  @override
  String get aiTutorHint => 'Tanya tutor Anda...';

  @override
  String aiTutorError(Object error) {
    return 'Error: $error';
  }

  @override
  String get mcCoursesTitle => 'Kursus Saya';

  @override
  String get mcJoinClass => 'Gabung Kelas';

  @override
  String get mcClassNotFound => 'Kelas tidak ditemukan dengan PIN tersebut';

  @override
  String get mcAlreadyEnrolled => 'Anda sudah terdaftar di kelas ini';

  @override
  String mcJoinedSuccess(Object name) {
    return 'Berhasil bergabung ke kelas \"$name\"!';
  }

  @override
  String mcErrorJoining(Object error) {
    return 'Gagal bergabung kelas: $error';
  }

  @override
  String get mcJoinDialogTitle => 'Gabung Kelas';

  @override
  String get mcEnterPinLabel => 'Masukkan PIN Kelas';

  @override
  String get mcCommonJoin => 'Gabung';

  @override
  String get mcNoCourses => 'Anda belum bergabung dengan kelas apapun.';

  @override
  String mcTeacherPrefix(Object name) {
    return 'Guru: $name';
  }

  @override
  String get languageSelectorTooltip => 'Pilih Bahasa';

  @override
  String get ccContentTypeLabel => 'Jenis Konten';

  @override
  String get ccTypeLessonPlan => 'Rencana Pelajaran';

  @override
  String get ccTypeMultipleChoice => 'Pilihan Ganda';

  @override
  String get ccTypeEssay => 'Essay';

  @override
  String get ccQuestionCountLabel => 'Jumlah Soal';

  @override
  String get ccQuestionCountHint => 'mis., 5';

  @override
  String get ccGenerateMC => 'Buat Soal';

  @override
  String get ccGenerateEssay => 'Buat Soal Essay';

  @override
  String get ccSaveToBank => 'Simpan ke Bank Soal';

  @override
  String get ccEditQuestion => 'Edit Soal';

  @override
  String get ccQuestionLabel => 'Soal';

  @override
  String get ccOptionA => 'Pilihan A';

  @override
  String get ccOptionB => 'Pilihan B';

  @override
  String get ccOptionC => 'Pilihan C';

  @override
  String get ccOptionD => 'Pilihan D';

  @override
  String get ccCorrectAnswer => 'Jawaban Benar';

  @override
  String get ccRubric => 'Rubrik Penilaian';

  @override
  String get ccFeedback => 'Umpan Balik';

  @override
  String get ccSaved => 'Soal berhasil disimpan!';

  @override
  String get ccNoQuestions => 'Belum ada soal yang dibuat.';

  @override
  String get ccParseError => 'Gagal memproses respons AI. Silakan coba lagi.';

  @override
  String get qbTitle => 'Bank Soal';

  @override
  String get qbEmpty => 'Belum ada soal di bank.';

  @override
  String get qbDeleteConfirm => 'Hapus soal ini?';

  @override
  String get qbDeleted => 'Soal dihapus';

  @override
  String get qbRecentQuestions => 'Soal Terbaru';

  @override
  String get ccErrorTimeout =>
      'AI terlalu lama merespons. Coba kurangi jumlah soal.';

  @override
  String get mcJoiningClass => 'Bergabung ke kelas...';
}
