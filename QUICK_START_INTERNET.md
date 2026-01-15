# 🚀 Quick Start - Internet Connectivity

## TL;DR

Aplikasi Anda sekarang bisa menghubungkan perangkat melalui **Internet** menggunakan Firebase!

---

## ⚡ 3 Steps to Enable

### 1️⃣ Firebase Setup (5 minutes)

Go to [Firebase Console](https://console.firebase.google.com/)

**Update Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /sync_sessions/{sessionCode} {
      allow read: if resource.data.isActive == true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.teacherId.toString();
      
      match /submissions/{submissionId} {
        allow create: if request.auth != null;
        allow read: if request.auth != null;
      }
    }
  }
}
```

### 2️⃣ Replace NetworkCubit (1 minute)

**In `lib/main.dart`:**

```dart
// OLD
import 'core/network/network_cubit.dart';

// NEW
import 'core/network/network_cubit_hybrid.dart';
```

That's it! API is backward compatible.

### 3️⃣ Test It! (2 minutes)

**Teacher:**
```dart
// Session code will auto-generate
// Display it in your UI
BlocBuilder<NetworkCubit, NetworkState>(
  builder: (context, state) {
    if (state is NetworkStarted) {
      print('Session Code: ${state.firebaseSessionCode}');
    }
  },
);
```

**Student:**
```dart
// Join with code
final networkCubit = context.read<NetworkCubit>();
await networkCubit.joinFirebaseSession('123456', student);
```

---

## 📱 How Students Join

### Option 1: Same WiFi (Auto)
```
Student opens app → Auto-discovers teacher → Connects
```

### Option 2: Internet (Manual)
```
Teacher shares 6-digit code → Student enters code → Joins session
```

### Option 3: Hybrid (Best)
```
App tries both methods → Uses fastest available
```

---

## 🎯 Usage Example

### Teacher Screen
```dart
Widget build(BuildContext context) {
  return BlocBuilder<NetworkCubit, NetworkState>(
    builder: (context, state) {
      if (state is NetworkStarted) {
        return Card(
          child: Column(
            children: [
              // Show session code if available
              if (state.firebaseSessionCode != null)
                Text(
                  'Session Code: ${state.firebaseSessionCode}',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              
              // Show mode
              Text('Mode: ${state.mode}'),
              
              // Copy button
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: state.firebaseSessionCode!),
                  );
                },
                icon: Icon(Icons.copy),
                label: Text('Copy Code'),
              ),
            ],
          ),
        );
      }
      return CircularProgressIndicator();
    },
  );
}
```

### Student Screen
```dart
class JoinClassScreen extends StatelessWidget {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Enter code
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Enter Session Code',
            hintText: '123456',
          ),
          maxLength: 6,
          keyboardType: TextInputType.number,
        ),
        
        // Join button
        ElevatedButton(
          onPressed: () async {
            final code = _codeController.text;
            final user = context.read<AuthCubit>().currentUser!;
            final networkCubit = context.read<NetworkCubit>();
            
            final success = await networkCubit.joinFirebaseSession(
              code,
              user,
            );
            
            if (success) {
              // Navigate to class
              context.go('/student/class');
            } else {
              // Show error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid code')),
              );
            }
          },
          child: Text('Join Class'),
        ),
      ],
    );
  }
}
```

---

## 🔍 Debug Tips

### Check if Firebase is working:
```dart
// In your app
final service = FirebaseSyncService();
final code = await service.createSession(
  teacher: user,
  classData: {'test': 'data'},
);
print('Session created: $code');
```

### Check which mode is active:
```dart
BlocBuilder<NetworkCubit, NetworkState>(
  builder: (context, state) {
    if (state is NetworkStarted) {
      print('Active mode: ${state.mode}');
      print('Local IP: ${state.localIp}');
      print('Firebase code: ${state.firebaseSessionCode}');
    }
  },
);
```

### Force specific mode:
```dart
// Test local only
await networkCubit.start(user, mode: NetworkMode.localOnly);

// Test Firebase only
await networkCubit.start(user, mode: NetworkMode.firebaseOnly);

// Test hybrid (default)
await networkCubit.start(user, mode: NetworkMode.hybrid);
```

---

## 💡 Pro Tips

1. **Session Code Display**: Make it BIG (32px+) and selectable
2. **Copy Button**: Always add a copy-to-clipboard button
3. **QR Code**: Consider using `qr_flutter` (already in pubspec!)
4. **Timeout**: Set reasonable session timeouts (e.g., 24 hours)
5. **Cleanup**: Close sessions when teacher leaves

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| No session code | Check Firebase init in main.dart |
| Can't join | Verify Firestore rules deployed |
| Slow sync | Check internet connection |
| Local not working | Same WiFi? Check permissions |

---

## 📚 Full Documentation

See: `INTERNET_CONNECTIVITY_GUIDE.md` for complete details

---

## ✅ Checklist

Before going live:

- [ ] Firebase Firestore rules deployed
- [ ] Firebase indexes created (if needed)
- [ ] Tested local mode (same WiFi)
- [ ] Tested Firebase mode (different networks)
- [ ] Session code displayed prominently
- [ ] Copy button works
- [ ] Error handling for invalid codes
- [ ] Session cleanup on logout
- [ ] Tested with multiple students

---

**Time to implement: ~15 minutes total** ⚡

**Difficulty: Easy** 🟢

**Breaking changes: None** ✅

---

Questions? Check the full guide or Firebase Console logs!
