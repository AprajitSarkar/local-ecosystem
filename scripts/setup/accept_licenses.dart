import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final process = await Process.start(
    'C:\\Users\\Aprajit\\tools\\flutter\\bin\\flutter.bat',
    ['doctor', '--android-licenses'],
    environment: {
      'JAVA_HOME': 'C:\\Users\\Aprajit\\tools\\jdk-17\\jdk-17.0.20.1+1',
      'ANDROID_HOME': 'C:\\Users\\Aprajit\\tools\\android-sdk',
      'ANDROID_SDK_ROOT': 'C:\\Users\\Aprajit\\tools\\android-sdk',
    },
    runInShell: true,
  );

  process.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
    stdout.write(data);
    process.stdin.writeln('y');
  });

  process.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
    stderr.write(data);
  });

  final exitCode = await process.exitCode;
  print('Finished with exit code $exitCode');
}
