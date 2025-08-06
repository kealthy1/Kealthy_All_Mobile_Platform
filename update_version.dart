import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please provide an argument: patch, minor, or major.');
    print('For decrement: patch decrement, minor decrement, major decrement.');
    exit(1);
  }

  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    print('pubspec.yaml not found in the current directory.');
    exit(1);
  }

  final lines = file.readAsLinesSync();

  // Find the version line
  final versionLineIndex =
      lines.indexWhere((line) => line.startsWith('version:'));
  if (versionLineIndex == -1) {
    print('Version not found in pubspec.yaml');
    exit(1);
  }

  final versionLine = lines[versionLineIndex];
  final currentVersion = versionLine.split(' ')[1].trim();
  final versionParts = currentVersion.split('.');

  if (versionParts.length != 3) {
    print(
        'Invalid version format in pubspec.yaml. Expected "major.minor.patch" format.');
    exit(1);
  }

  int major = int.tryParse(versionParts[0]) ?? 0;
  int minor = int.tryParse(versionParts[1]) ?? 0;
  int patch = int.tryParse(versionParts[2]) ?? 0;

  if (args.length == 2 && args[1] == 'decrement') {
    // Decrement logic
    switch (args[0]) {
      case 'patch':
        if (patch > 0) {
          patch--;
        } else {
          print('Cannot decrement patch below 0.');
          exit(1);
        }
        break;
      case 'minor':
        if (minor > 0) {
          minor--;
          patch = 0; // Reset patch
        } else {
          print('Cannot decrement minor below 0.');
          exit(1);
        }
        break;
      case 'major':
        if (major > 0) {
          major--;
          minor = 0; // Reset minor
          patch = 0; // Reset patch
        } else {
          print('Cannot decrement major below 0.');
          exit(1);
        }
        break;
      default:
        print('Invalid argument: use patch, minor, or major.');
        exit(1);
    }
  } else {
    switch (args[0]) {
      case 'patch':
        patch++;
        break;
      case 'minor':
        minor++;
        patch = 0; 
        break;
      case 'major':
        major++;
        minor = 0; 
        patch = 0; 
        break;
      default:
        print('Invalid argument: use patch, minor, or major.');
        exit(1);
    }
  }

  final newVersion = '$major.$minor.$patch';
  lines[versionLineIndex] = 'version: $newVersion';

  file.writeAsStringSync(lines.join('\n'));
  print('Version updated to $newVersion');
}
