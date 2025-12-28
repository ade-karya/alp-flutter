# Wizard Theme Components - Documentation

## 📚 Overview

File `wizard_widgets.dart` berisi koleksi komponen UI yang sudah disesuaikan dengan **Wizard Theme** untuk konsistensi styling di seluruh aplikasi ALP.

## 🎨 Komponen yang Tersedia

### 1. **WizardWidgets.textField()** - TextField dengan Wizard Styling

```dart
WizardWidgets.textField(
  controller: _nameController,
  label: 'Nama Lengkap',
  hint: 'Masukkan nama Anda',
  isWizard: isWizard,
)
```

**Parameters:**
- `controller` - TextEditingController
- `label` - Label text
- `hint` - Placeholder text (optional)
- `obscureText` - Hide text untuk password (default: false)
- `keyboardType` - Input keyboard type
- `validator` - Form validation function
- `suffixIcon` - Icon di akhir field (optional)
- `maxLines` - Max lines (default: 1)
- `isWizard` - Enable wizard theme (default: true)

**Features:**
- ✅ Gold border saat focus (wizard mode)
- ✅ Transparent background dengan opacity
- ✅ Custom font family (Lato untuk wizard)
- ✅ Error state dengan red border

---

### 2. **WizardWidgets.dropdown()** - Dropdown dengan Wizard Styling

```dart
WizardWidgets.dropdown<String>(
  value: selectedValue,
  label: 'Pilih Role',
  items: [
    DropdownMenuItem(value: 'student', child: Text('Siswa')),
    DropdownMenuItem(value: 'teacher', child: Text('Guru')),
  ],
  onChanged: (value) => setState(() => selectedValue = value),
  isWizard: isWizard,
)
```

**Parameters:**
- `value` - Currently selected value
- `label` - Label text
- `items` - List of DropdownMenuItem
- `onChanged` - Callback function
- `isWizard` - Enable wizard theme

**Features:**
- ✅ Purple dropdown background (#2E004B)
- ✅ Gold border saat focus
- ✅ White text untuk wizard mode

---

### 3. **WizardWidgets.primaryButton()** - Primary Action Button

```dart
WizardWidgets.primaryButton(
  onPressed: _handleSubmit,
  label: 'Simpan',
  icon: Icons.save,
  isLoading: _isSubmitting,
  isWizard: isWizard,
)
```

**Parameters:**
- `onPressed` - Callback function
- `label` - Button text
- `icon` - Icon di sebelah text (optional)
- `isLoading` - Show loading indicator (default: false)
- `isWizard` - Enable wizard theme

**Features:**
- ✅ Deep purple background (#4A148C)
- ✅ Gold text dan border (wizard mode)
- ✅ Cinzel font untuk wizard mode
- ✅ Loading indicator built-in
- ✅ Full width by default (56px height)

---

### 4. **WizardWidgets.secondaryButton()** - Secondary/Outline Button

```dart
WizardWidgets.secondaryButton(
  onPressed: () => context.pop(),
  label: 'Batal',
  icon: Icons.cancel,
  isWizard: isWizard,
)
```

**Parameters:**
- `onPressed` - Callback function
- `label` - Button text
- `icon` - Icon di sebelah text (optional)
- `isWizard` - Enable wizard theme

**Features:**
- ✅ Transparent background dengan border
- ✅ Gold border dan text (wizard mode)
- ✅ Full width by default

---

### 5. **WizardWidgets.card()** - Container Card

```dart
WizardWidgets.card(
  isWizard: isWizard,
  padding: EdgeInsets.all(20),
  child: Column(
    children: [
      Text('Card Content'),
    ],
  ),
)
```

**Parameters:**
- `child` - Widget content
- `padding` - EdgeInsets (optional, default: 20px all)
- `isWizard` - Enable wizard theme

**Features:**
- ✅ Semi-transparent black background (alpha: 0.4)
- ✅ White border dengan opacity
- ✅ Shadow effect
- ✅ Rounded corners (16px)

---

### 6. **WizardWidgets.showWizardDialog()** - Custom Dialog

```dart
await WizardWidgets.showWizardDialog<bool>(
  context: context,
  title: 'Konfirmasi',
  content: Text('Apakah Anda yakin?'),
  isWizard: isWizard,
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text('Batal'),
    ),
    ElevatedButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text('Ya'),
    ),
  ],
)
```

**Parameters:**
- `context` - BuildContext
- `title` - Dialog title
- `content` - Dialog content widget
- `actions` - List of action buttons (optional)
- `isWizard` - Enable wizard theme

**Features:**
- ✅ Purple background (#2E004B)
- ✅ Gold title text (wizard mode)
- ✅ Gold border
- ✅ Rounded corners (20px)

---

### 7. **WizardWidgets.showSnackBar()** - SnackBar Notification

```dart
WizardWidgets.showSnackBar(
  context: context,
  message: 'Data berhasil disimpan!',
  isError: false,
  isWizard: isWizard,
)
```

**Parameters:**
- `context` - BuildContext
- `message` - Notification message
- `isError` - Error style (default: false)
- `isWizard` - Enable wizard theme

**Features:**
- ✅ Purple background untuk success (#4A148C)
- ✅ Red background untuk error
- ✅ Gold border (wizard mode)
- ✅ Floating behavior
- ✅ Rounded corners

---

## 🔧 Cara Implementasi

### Step 1: Import Widget

```dart
import 'package:alp/core/widgets/wizard_widgets.dart';
import 'package:alp/core/theme/theme_cubit.dart';
```

### Step 2: Detect Theme

```dart
final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;
```

### Step 3: Gunakan Widget

```dart
WizardWidgets.textField(
  controller: _controller,
  label: 'Label',
  isWizard: isWizard,
)
```

---

## 📝 Contoh Implementasi Lengkap

```dart
class MyFormScreen extends StatefulWidget {
  const MyFormScreen({super.key});

  @override
  State<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Your submit logic here
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        WizardWidgets.showSnackBar(
          context: context,
          message: 'Berhasil disimpan!',
          isWizard: isWizard,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        WizardWidgets.showSnackBar(
          context: context,
          message: 'Error: $e',
          isError: true,
          isWizard: isWizard,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.white,
      appBar: AppBar(
        title: Text(
          'Form Example',
          style: TextStyle(
            color: isWizard ? Colors.white : Colors.black87,
            fontFamily: isWizard ? 'Cinzel' : null,
          ),
        ),
        backgroundColor: isWizard ? Colors.transparent : Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Card Container
            WizardWidgets.card(
              isWizard: isWizard,
              child: Column(
                children: [
                  // Text Field
                  WizardWidgets.textField(
                    controller: _nameController,
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama Anda',
                    isWizard: isWizard,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Dropdown
                  WizardWidgets.dropdown<String>(
                    value: _selectedRole,
                    label: 'Role',
                    items: [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Siswa'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Guru'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRole = value);
                    },
                    isWizard: isWizard,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Primary Button
            WizardWidgets.primaryButton(
              onPressed: _handleSubmit,
              label: 'Simpan',
              icon: Icons.save,
              isLoading: _isLoading,
              isWizard: isWizard,
            ),
            SizedBox(height: 12),

            // Secondary Button
            WizardWidgets.secondaryButton(
              onPressed: () => Navigator.pop(context),
              label: 'Batal',
              icon: Icons.cancel,
              isWizard: isWizard,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 Theme Colors Reference

### Wizard Theme
- **Primary Purple:** `#4A148C`
- **Deep Purple:** `#2E004B`
- **Gold Accent:** `#FFD700`
- **Lighter Purple:** `#7B1FA2`
- **Font:** Cinzel (headers), Lato (body)

### Regular Theme
- **Primary Blue:** `Colors.blue`
- **Background:** `Colors.white`
- **Text:** `Colors.black87`

---

## ✅ Checklist Migration

Untuk migrate screen existing ke wizard widgets:

- [ ] Import `wizard_widgets.dart`
- [ ] Detect theme dengan `ThemeCubit`
- [ ] Replace `TextField` dengan `WizardWidgets.textField()`
- [ ] Replace `DropdownButton` dengan `WizardWidgets.dropdown()`
- [ ] Replace `ElevatedButton` dengan `WizardWidgets.primaryButton()`
- [ ] Replace `OutlinedButton` dengan `WizardWidgets.secondaryButton()`
- [ ] Replace `Card` dengan `WizardWidgets.card()`
- [ ] Replace `showDialog` dengan `WizardWidgets.showWizardDialog()`
- [ ] Replace `ScaffoldMessenger` dengan `WizardWidgets.showSnackBar()`
- [ ] Add `isWizard` parameter ke semua widgets
- [ ] Test di Wizard mode dan Regular mode

---

## 🚀 Status Implementation

### ✅ Sudah Diimplementasi:
- AI Assistant Settings Screen (bottom padding fix)
- Change PIN Screen (sudah menggunakan wizard theme dengan baik)

### 🔄 Pending Migration:
- Login Screen
- Registration Screen
- Student Dashboard
- Teacher Dashboard
- Create Content Screen
- Manage Class Screen
- Profile Screen
- Dan screens lainnya...

---

## 📞 Support

Jika ada pertanyaan atau issues terkait wizard widgets, silakan dokumentasikan di:
- Issue tracker
- Developer chat
- Code review comments
