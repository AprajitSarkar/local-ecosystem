// lib/core/audio/web_audio_web.dart
import 'dart:js' as js;

void playWebTone(List<double> frequencies, List<double> durations, {double volume = 0.2}) {
  try {
    final freqList = frequencies.join(',');
    final durList = durations.join(',');
    js.context.callMethod('eval', ['''
      (function() {
        try {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (!AudioCtx) return;
          var ctx = new AudioCtx();
          var freqs = [$freqList];
          var durs = [$durList];
          var now = ctx.currentTime;
          for (var i = 0; i < freqs.length; i++) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.value = freqs[i];
            var dur = durs[i] || 0.2;
            gain.gain.setValueAtTime(0.001, now);
            gain.gain.exponentialRampToValueAtTime($volume, now + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + dur);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + dur);
            now += dur * 0.85;
          }
        } catch(e) {}
      })();
    ''']);
  } catch (_) {}
}
