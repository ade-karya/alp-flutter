# Panduan Koneksi Internet untuk Aplikasi ALP

## Overview

Aplikasi ALP sekarang mendukung **3 mode koneksi**:

1. **LOCAL** - Hanya jaringan lokal (WiFi/LAN) menggunakan mDNS
2. **INTERNET** - Koneksi melalui internet menggunakan Firebase
3. **HYBRID** - Gabungan keduanya (default)

---

## Arsitektur Sistem

### Mode LOCAL (Existing)
```
Teacher Device (Local WiFi)
     ↓ mDNS broadcast
Student Device (Same WiFi) ← discovers teacher
     ↓ HTTP connection
Teacher's Sync Server (port 3000)
```

### Mode INTERNET (New)
```
Teacher Device
     ↓ registers to
Firebase Firestore (Cloud)
     ↑ registers to
Student Device (Anywhere in the world)
     ↓ sync via Firestore
Real-time data sync
```

---

## File Structure

### New Files Created:
- `lib/core/network/firebase_sync_service.dart` - Firebase backend service
- `lib/core/network/firebase_sync_client.dart` - Client untuk students
- `lib/core/network/network_cubit_v2.dart` - Enhanced network manager

### Modified Approach:
Tidak mengubah file existing, buat versi baru (V2) untuk backward compatibility.

---

## Cara Penggunaan

### 1. Update `main.dart`

Tambahkan FirebaseSyncService ke provider:

```dart
return MultiRepositoryProvider(
  providers: [
    RepositoryProvider(create: (context) => GeminiOpenAIService()),
    RepositoryProvider(create: (context) => DatabaseHelper.instance),
    RepositoryProvider(create: (context) => FirebaseAuthService()),
    
    // NEW: Add Firebase Sync Service
    RepositoryProvider(create: (context) => FirebaseSyncService()),
  ],
  child: MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => ThemeCubit()),
      BlocProvider(
        create: (context) => AuthCubit(
          context.read<DatabaseHelper>(),
          context.read<FirebaseAuthService>(),
        ),
      ),
      
      // OPTION 1: Keep old NetworkCubit for local only
      BlocProvider(
        create: (context) => NetworkCubit(NetworkDiscoveryService()),
      ),
      
      // OPTION 2: Use new NetworkCubitV2 for internet support
      BlocProvider(
        create: (context) => NetworkCubitV2(
          NetworkDiscoveryService(),
          context.read<FirebaseSyncService>(),
        ),
      ),
    ],
    // ... rest of code
  ),
);
```

### 2. Untuk Teacher: Publish Class ke Internet

```dart
// In teacher screen
final firebaseService = context.read<FirebaseSyncService>();

// Share class to internet
final classId = await firebaseService.shareClass({
  'name': 'Matematika Kelas 7',
  'teacher_id': currentUser.id,
  'teacher_name': currentUser.name,
  'pin': '123456', // 6-digit PIN
  'description': 'Kelas matematika semester 1',
});

print('Class ID: $classId, PIN: 123456');
// Teacher gives PIN to students
```

### 3. Untuk Student: Join Class via Internet

```dart
final firebaseSyncClient = FirebaseSyncClient();

// Student enters PIN
final classData = await firebaseSyncClient.getClassByPin('123456');

if (classData != null) {
  // Enroll student
  final success = await firebaseSyncClient.enrollStudent(
    classId: classData['id'],
    studentId: currentUser.id,
    studentName: currentUser.name,
    studentIdentifier: currentUser.identifier,
  );
  
  if (success) {
    print('Successfully enrolled in class!');
  }
}
```

### 4. Switch Connection Mode

```dart
// In network settings screen
final networkCubit = context.read<NetworkCubitV2>();

// Switch to internet-only mode
await networkCubit.switchMode(ConnectionMode.internet, currentUser);

// Switch to local-only mode
await networkCubit.switchMode(ConnectionMode.local, currentUser);

// Switch to hybrid (both)
await networkCubit.switchMode(ConnectionMode.hybrid, currentUser);
```

### 5. Student: Get Assignments (Real-time)

```dart
final client = FirebaseSyncClient();

// Listen to assignments (real-time updates)
StreamBuilder<List<Map<String, dynamic>>>(
  stream: client.getAssignments(classId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final assignments = snapshot.data!;
      return ListView.builder(
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          return ListTile(
            title: Text(assignment['title']),
            subtitle: Text(assignment['description']),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
);
```

### 6. Student: Submit Answers

```dart
final answers = [
  {'question_id': 1, 'answer': 'B'},
  {'question_id': 2, 'answer': 'A'},
];

final submissionId = await client.submitAnswers(
  classId: classId,
  assignmentId: assignmentId,
  studentId: currentUser.id,
  answers: answers,
);

print('Submission ID: $submissionId');
```

---

## UI Changes Needed

### Add Mode Selector in Settings

```dart
// lib/features/settings/screens/network_settings_screen.dart

SegmentedButton<ConnectionMode>(
  segments: [
    ButtonSegment(
      value: ConnectionMode.local,
      label: Text('Local'),
      icon: Icon(Icons.wifi),
    ),
    ButtonSegment(
      value: ConnectionMode.internet,
      label: Text('Internet'),
      icon: Icon(Icons.cloud),
    ),
    ButtonSegment(
      value: ConnectionMode.hybrid,
      label: Text('Hybrid'),
      icon: Icon(Icons.sync),
    ),
  ],
  selected: {networkCubit.connectionMode},
  onSelectionChanged: (Set<ConnectionMode> selection) {
    networkCubit.switchMode(selection.first, currentUser);
  },
);
```

---

## Firebase Security Rules

Tambahkan di Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Active devices - anyone can read, only owner can write
    match /active_devices/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Classes - teachers create, anyone can read
    match /classes/{classId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.teacher_id == request.auth.uid;
      
      // Students subcollection
      match /students/{studentId} {
        allow read: if true;
        allow write: if request.auth != null;
      }
      
      // Assignments subcollection
      match /assignments/{assignmentId} {
        allow read: if true;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/classes/$(classId)).data.teacher_id == request.auth.uid;
      }
    }
    
    // Submissions - students write, teachers read
    match /submissions/{submissionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
  }
}
```

---

## Keuntungan Mode Internet

✅ **Jarak Jauh** - Guru dan murid tidak perlu di WiFi yang sama
✅ **Skalabilitas** - Bisa ratusan/ribuan murid
✅ **Persistent Data** - Data tersimpan di cloud
✅ **Real-time Sync** - Update otomatis tanpa refresh
✅ **Cross-platform** - Web, Android, iOS, Desktop
✅ **Offline Support** - Firebase cache data lokal

---

## Migration Plan

### Phase 1: Keep Both (Recommended)
- Gunakan `NetworkCubitV2` di samping `NetworkCubit` lama
- Biarkan user pilih mode (Local/Internet/Hybrid)
- Testing parallel

### Phase 2: Gradual Migration
- Default ke mode Hybrid
- Monitor usage
- Fix bugs

### Phase 3: Full Internet
- Make Internet mode default
- Keep Local as fallback

---

## Testing Checklist

- [ ] Teacher register device ke Firebase
- [ ] Student discover teacher via Firebase
- [ ] Teacher share class dengan PIN
- [ ] Student join class dengan PIN
- [ ] Teacher publish assignment
- [ ] Student receive assignment (real-time)
- [ ] Student submit answers
- [ ] Teacher view submissions
- [ ] Test connection dari jaringan berbeda
- [ ] Test offline behavior
- [ ] Test mode switching

---

## Troubleshooting

### "Firebase connection failed"
- Check internet connection
- Verify Firebase config in `firebase_options.dart`
- Check Firestore rules

### "No peers discovered in Internet mode"
- Verify device registration
- Check `active_devices` collection in Firestore
- Ensure `online: true` field exists

### "Can't submit answers"
- Check authentication
- Verify class enrollment
- Check Firestore permissions

---

## Next Steps

1. **Implement Mode Selector UI** di settings
2. **Add Connection Status Indicator** (online/offline)
3. **Show Peer Source** (local/internet/manual) di peer list
4. **Test dengan 2 devices** di jaringan berbeda
5. **Add Sync Progress Indicator**
6. **Implement Retry Logic** untuk failed syncs

---

## Cost Estimation (Firebase)

**Free Tier Limits:**
- 50K reads/day
- 20K writes/day
- 20K deletes/day
- 1GB storage

**Typical Usage (100 students):**
- Device registration: ~100 writes/day
- Assignment distribution: ~1000 reads/day
- Answer submission: ~500 writes/day

➡️ **Free tier cukup untuk sekolah kecil-menengah**
