# 🌐 Internet Connectivity Guide - ALP Flutter App

## 📋 Overview

Aplikasi Anda sekarang mendukung **3 mode konektivitas**:

1. **Local P2P** (WiFi Same Network) - Original implementation
2. **Firebase Sync** (Internet) - **NEW!** ✨
3. **Hybrid Mode** - Automatic fallback between local and cloud

---

## 🔧 Implementation Overview

### Files Created

1. **`lib/core/network/firebase_sync_service.dart`**
   - Service untuk sinkronisasi data melalui Firebase Firestore
   - Menggantikan mDNS dan HTTP server dengan cloud sync
   - Real-time updates menggunakan Firestore streams

2. **`lib/core/network/network_cubit_hybrid.dart`**
   - State management untuk hybrid networking
   - Auto-detect dan fallback mechanism
   - Mode switching capability

---

## 🚀 How It Works

### For Teachers (Create Session)

```
┌─────────────────┐
│  Teacher Opens  │
│      App        │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Start Network          │
│  Mode: Hybrid           │
└────────┬────────────────┘
         │
         ├──► Local P2P Started (if same WiFi)
         │    - HTTP Server on port 3000
         │    - mDNS broadcast
         │
         └──► Firebase Session Created
              - Session Code: 123456
              - Real-time listener started
```

### For Students (Join Session)

**Option 1: Same WiFi (Local)**
```
Student → Auto-discover → Connect to teacher's IP → Sync
```

**Option 2: Internet (Firebase)**
```
Student → Enter session code → Join Firebase session → Real-time sync
```

---

## 📱 UI Implementation Example

### Teacher Screen - Display Session Code

```dart
class TeacherNetworkWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        if (state is NetworkStarted) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Show mode
                  _buildModeIndicator(state.mode),
                  SizedBox(height: 16),
                  
                  // Local IP (if available)
                  if (state.localIp != null) ...[
                    Text('Local Network:'),
                    Text(
                      'IP: ${state.localIp}:3000',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  // Firebase session code (if available)
                  if (state.firebaseSessionCode != null) ...[
                    Text('Internet Session Code:'),
                    SelectableText(
                      state.firebaseSessionCode!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Share this code with students',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Copy to clipboard
                        Clipboard.setData(
                          ClipboardData(text: state.firebaseSessionCode!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code copied!')),
                        );
                      },
                      icon: Icon(Icons.copy),
                      label: Text('Copy Code'),
                    ),
                  ],
                  
                  // Show connected students
                  SizedBox(height: 16),
                  _buildConnectedStudents(context),
                ],
              ),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildModeIndicator(NetworkMode mode) {
    IconData icon;
    String label;
    Color color;
    
    switch (mode) {
      case NetworkMode.localOnly:
        icon = Icons.wifi;
        label = 'Local WiFi Only';
        color = Colors.orange;
        break;
      case NetworkMode.firebaseOnly:
        icon = Icons.cloud;
        label = 'Internet Mode';
        color = Colors.blue;
        break;
      case NetworkMode.hybrid:
        icon = Icons.sync;
        label = 'Hybrid Mode';
        color = Colors.green;
        break;
    }
    
    return Chip(
      avatar: Icon(icon, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildConnectedStudents(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        if (state is NetworkPeersUpdated) {
          final studentCount = 
              (state.peers.length) + 
              (state.connectedStudents?.length ?? 0);
          
          return Column(
            children: [
              Text(
                'Connected Students: $studentCount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              
              // Local peers
              ...state.peers.map((peer) => ListTile(
                leading: Icon(Icons.wifi),
                title: Text(peer['name'] ?? 'Unknown'),
                subtitle: Text('Local: ${peer['host']}'),
              )),
              
              // Firebase peers
              if (state.connectedStudents != null)
                ...state.connectedStudents!.entries.map((entry) {
                  final student = entry.value as Map<String, dynamic>;
                  return ListTile(
                    leading: Icon(Icons.cloud),
                    title: Text(student['name'] ?? 'Unknown'),
                    subtitle: Text('Internet'),
                  );
                }),
            ],
          );
        }
        return Text('No students connected');
      },
    );
  }
}
```

### Student Screen - Join Options

```dart
class StudentJoinWidget extends StatefulWidget {
  @override
  _StudentJoinWidgetState createState() => _StudentJoinWidgetState();
}

class _StudentJoinWidgetState extends State<StudentJoinWidget> {
  final _sessionCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        return Column(
          children: [
            // Auto-discover (Local)
            Card(
              child: ListTile(
                leading: Icon(Icons.wifi),
                title: Text('Auto-discover (Same WiFi)'),
                subtitle: Text('Find teachers on the same network'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () => _showLocalPeers(context),
              ),
            ),
            
            SizedBox(height: 16),
            
            Text('OR', style: TextStyle(fontWeight: FontWeight.bold)),
            
            SizedBox(height: 16),
            
            // Join with code (Internet)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud),
                        SizedBox(width: 8),
                        Text(
                          'Join with Session Code',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _sessionCodeController,
                      decoration: InputDecoration(
                        labelText: 'Enter 6-digit code',
                        hintText: '123456',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isJoining ? null : _joinWithCode,
                      child: _isJoining
                          ? CircularProgressIndicator()
                          : Text('Join Session'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLocalPeers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Available Teachers'),
        content: BlocBuilder<NetworkCubit, NetworkState>(
          builder: (context, state) {
            if (state is NetworkPeersUpdated && state.peers.isNotEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: state.peers.map((peer) {
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(peer['name'] ?? 'Unknown'),
                    subtitle: Text('Role: ${peer['role']}'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.pop(context);
                      _connectToLocalPeer(context, peer);
                    },
                  );
                }).toList(),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Searching for teachers...'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinWithCode() async {
    final code = _sessionCodeController.text.trim();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final user = context.read<AuthCubit>().currentUser;
      if (user == null) return;

      final networkCubit = context.read<NetworkCubit>();
      final success = await networkCubit.joinFirebaseSession(code, user);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined session!')),
        );
        // Navigate to class screen
        // context.go('/student/class');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid or expired session code')),
        );
      }
    } finally {
      setState(() => _isJoining = false);
    }
  }

  Future<void> _connectToLocalPeer(
    BuildContext context,
    Map<String, String> peer,
  ) async {
    final networkCubit = context.read<NetworkCubit>();
    final host = peer['host'];
    
    if (host == null || host.isEmpty) return;

    final client = await networkCubit.connectToLocalPeer(host);
    
    if (client != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${peer['name']}')),
      );
      // Navigate to class screen with client
      // context.go('/student/class', extra: client);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect')),
      );
    }
  }
}
```

---

## 🔐 Firebase Setup Required

### 1. Firestore Database Rules

Update your Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Sync sessions
    match /sync_sessions/{sessionCode} {
      // Anyone can read active sessions
      allow read: if resource.data.isActive == true;
      
      // Only authenticated users can create sessions
      allow create: if request.auth != null;
      
      // Only session owner (teacher) can update/delete
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.teacherId.toString();
      
      // Submissions subcollection
      match /submissions/{submissionId} {
        // Students can create submissions
        allow create: if request.auth != null;
        
        // Teacher can read all submissions
        allow read: if request.auth != null 
          && get(/databases/$(database)/documents/sync_sessions/$(sessionCode))
             .data.teacherId.toString() == request.auth.uid;
      }
    }
  }
}
```

### 2. Firestore Indexes

Create composite indexes in Firebase Console:

- Collection: `sync_sessions`
  - Fields: `isActive` (Ascending), `createdAt` (Descending)

- Collection: `sync_sessions/{sessionCode}/submissions`
  - Fields: `submittedAt` (Descending)

---

## 🔄 Integration Steps

### Step 1: Update main.dart

Replace the old `NetworkCubit` import:

```dart
// OLD
import 'core/network/network_cubit.dart';

// NEW
import 'core/network/network_cubit_hybrid.dart';
```

### Step 2: Update Network Initialization

In your `main.dart` or wherever you initialize the cubit:

```dart
BlocProvider(
  create: (context) => NetworkCubit(NetworkDiscoveryService()),
),
```

No changes needed! The interface is backward compatible.

### Step 3: Update Teacher Screen

Add session code display widget:

```dart
// In teacher home/dashboard screen
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Teacher Dashboard')),
    body: Column(
      children: [
        TeacherNetworkWidget(), // NEW: Shows session code
        // ... rest of your UI
      ],
    ),
  );
}
```

### Step 4: Update Student Screen

Add join options widget:

```dart
// In student home/dashboard screen
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Student Dashboard')),
    body: Column(
      children: [
        StudentJoinWidget(), // NEW: Join via code or discovery
        // ... rest of your UI
      ],
    ),
  );
}
```

---

## 🎯 Usage Scenarios

### Scenario 1: Same Classroom (WiFi)
```
✅ Both teacher and students on same WiFi
✅ Auto-discovery works
✅ Direct P2P connection (fast, no internet needed)
✅ Fallback to Firebase if P2P fails
```

### Scenario 2: Remote Learning (Internet)
```
✅ Teacher and students on different networks
✅ Teacher shares 6-digit session code
✅ Students join using code
✅ All sync through Firebase
✅ Real-time updates
```

### Scenario 3: Hybrid (Mixed)
```
✅ Some students in classroom (WiFi)
✅ Some students remote (Internet)
✅ Teacher broadcasts both ways
✅ Each student uses best available method
```

---

## 🐛 Testing

### Test Local Mode
```dart
// Force local-only mode
await networkCubit.start(user, mode: NetworkMode.localOnly);
```

### Test Firebase Mode
```dart
// Force Firebase-only mode
await networkCubit.start(user, mode: NetworkMode.firebaseOnly);
```

### Test Hybrid Mode
```dart
// Auto-detect and use both
await networkCubit.start(user, mode: NetworkMode.hybrid);
```

---

## 📊 Performance Comparison

| Feature | Local P2P | Firebase Sync |
|---------|-----------|---------------|
| Speed | ⚡ Very Fast | 🚀 Fast |
| Latency | < 50ms | ~100-300ms |
| Range | Same WiFi | Global |
| Offline | ❌ No | ✅ Yes (cached) |
| Scalability | ~10 devices | Unlimited |
| Setup | Zero config | Firebase project |

---

## 🔒 Security Considerations

### Session Code Security
- Codes expire after session closes
- 6-digit codes = 1,000,000 combinations
- Time-limited sessions (recommend 24 hours max)
- Consider adding session passwords for sensitive classes

### Data Privacy
- All Firebase data encrypted in transit
- Firestore rules prevent unauthorized access
- Consider deleting old sessions regularly

### Implementation for Password Protection (Optional)

```dart
// In firebase_sync_service.dart
Future<String> createSession({
  required User teacher,
  required Map<String, dynamic> classData,
  String? password, // NEW
}) async {
  final sessionData = {
    'sessionCode': sessionCode,
    'hasPassword': password != null,
    'passwordHash': password != null 
        ? _hashPassword(password) 
        : null,
    // ... rest of data
  };
  // ...
}
```

---

## 🎉 Benefits of This Implementation

1. **✅ Backward Compatible** - Existing local P2P still works
2. **✅ Zero Configuration** - Auto-detects best method
3. **✅ Future Proof** - Easy to add more sync methods
4. **✅ Scalable** - Firebase handles unlimited students
5. **✅ Reliable** - Automatic fallback mechanism
6. **✅ Real-time** - Live updates via Firestore streams

---

## 🚨 Common Issues & Solutions

### Issue 1: Session code not generating
**Solution**: Check Firebase initialization in `main.dart`

### Issue 2: Students can't join
**Solution**: Verify Firestore rules are deployed correctly

### Issue 3: Local discovery not working
**Solution**: Ensure both devices on same WiFi, check permissions

### Issue 4: Slow Firebase sync
**Solution**: Check internet connection, Firebase region settings

---

## 📞 Support

For issues or questions:
1. Check Firebase Console for errors
2. Enable debug logging: `debugPrint` messages
3. Test with Firebase Emulator Suite locally

---

## 🔮 Future Enhancements

Potential improvements you can add:

1. **QR Code Sharing** - Generate QR for session code
2. **NFC Tap to Join** - Android NFC support
3. **WebRTC** - True P2P over internet
4. **End-to-End Encryption** - Additional security layer
5. **Offline Sync Queue** - Queue actions when offline
6. **Multi-session Support** - Student in multiple classes

---

Made with ❤️ for ALP Education Platform
