// trial_service.dart
import 'package:shared_preferences/shared_preferences.dart';

// Enhanced offline trial verification with protection against date manipulation
Future<bool> isTrialExpired() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Check if trial was already marked as expired
  final bool isAlreadyExpired = prefs.getBool('trial_expired') ?? false;
  if (isAlreadyExpired) {
    return true;
  }

  // Get installation date or set it if first use
  final installationDateStr = prefs.getString('installation_date');
  DateTime installDate;
  
  if (installationDateStr == null) {
    // First use, set installation date with multiple verification points
    installDate = DateTime.now();
    await prefs.setString('installation_date', installDate.toIso8601String());
    
    // Store initial verification points
    await prefs.setString('verification_point_1', DateTime.now().toIso8601String());
    await prefs.setInt('launch_count', 0);
    await prefs.setString('first_launch_time', DateTime.now().toIso8601String());
    
    return false;
  } else {
    installDate = DateTime.parse(installationDateStr);
  }

  // Get current device time
  final DateTime currentTime = DateTime.now();
  
  // Store current time for future verification
  await _storeVerificationPoint(prefs, currentTime);
  
  // Verify time consistency and detect manipulation
  final bool isTimeManipulated = await _checkTimeManipulation(prefs, currentTime);
  if (isTimeManipulated) {
    await prefs.setBool('trial_expired', true);
    return true;
  }

  // Calculate trial duration
  final difference = currentTime.difference(installDate).inDays;
  
  // Check if trial expired - IMMEDIATELY expire if 30 or more days
  if (difference >= 30) {
    // Mark trial as permanently expired
    await prefs.setBool('trial_expired', true);
    return true;
  }
  
  // Update launch count
  final int launchCount = prefs.getInt('launch_count') ?? 0;
  await prefs.setInt('launch_count', launchCount + 1);
  return false;
}

// Store verification point for time manipulation detection
Future<void> _storeVerificationPoint(SharedPreferences prefs, DateTime currentTime) async {
  final int launchCount = prefs.getInt('launch_count') ?? 0;
  
  // Store verification point every 3 launches
  if (launchCount % 3 == 0) {
    final pointIndex = (launchCount ~/ 3) + 1;
    await prefs.setString('verification_point_$pointIndex', currentTime.toIso8601String());
  }
  
  // Always store the last launch time
  await prefs.setString('last_launch_time', currentTime.toIso8601String());
}

// Check for time manipulation offline
Future<bool> _checkTimeManipulation(SharedPreferences prefs, DateTime currentTime) async {
  // Get first launch time
  final firstLaunchStr = prefs.getString('first_launch_time');
  if (firstLaunchStr != null) {
    final firstLaunchTime = DateTime.parse(firstLaunchStr);
    
    // Current time cannot be before first launch time
    if (currentTime.isBefore(firstLaunchTime)) {
      return true;
    }
  }

  // Get last launch time
  final lastLaunchStr = prefs.getString('last_launch_time');
  if (lastLaunchStr != null) {
    final lastLaunchTime = DateTime.parse(lastLaunchStr);
    
    // Current time cannot be before last launch time
    if (currentTime.isBefore(lastLaunchTime)) {
      return true;
    }
    
    // Check for unrealistic time jumps (more than 24 hours between launches)
    final timeSinceLastLaunch = currentTime.difference(lastLaunchTime);
    if (timeSinceLastLaunch.inHours > 24) {
      // This could indicate date manipulation
      return true;
    }
  }

  // Check all verification points
  int i = 1;
  while (true) {
    final pointStr = prefs.getString('verification_point_$i');
    if (pointStr == null) break;
    
    final verificationPoint = DateTime.parse(pointStr);
    
    // Current time cannot be before any previous verification point
    if (currentTime.isBefore(verificationPoint)) {
      return true;
    }
    
    i++;
  }

  return false;
}
// Add this function to your trial_service.dart
Future<void> resetTrialForDevelopment() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Clear all trial-related data
  await prefs.remove('installation_date');
  await prefs.remove('trial_expired');
  await prefs.remove('launch_count');
  await prefs.remove('first_launch_time');
  await prefs.remove('last_launch_time');
  
  // Remove all verification points
  int i = 1;
  while (true) {
    final key = 'verification_point_$i';
    if (prefs.containsKey(key)) {
      await prefs.remove(key);
      i++;
    } else {
      break;
    }
  }
  
}

// Function to reset trial (for testing purposes only - remove in production)
Future<void> resetTrial() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('installation_date');
  await prefs.remove('trial_expired');
  await prefs.remove('launch_count');
  await prefs.remove('first_launch_time');
  await prefs.remove('last_launch_time');
  
  // Remove all verification points
  int i = 1;
  while (true) {
    final key = 'verification_point_$i';
    if (prefs.containsKey(key)) {
      await prefs.remove(key);
      i++;
    } else {
      break;
    }
  }
}
