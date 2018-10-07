package net.u_wave.android;

import java.util.Map;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.NotificationManagerCompat;
import android.widget.RemoteViews;
import android.app.Intent;
import android.app.PendingIntent;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class NotificationPlugin implements MethodCallHandler {
  public static final String NAME = "u-wave.net/notification";
  private static final int NOTIFY_NOW_PLAYING = 0;

  private static final String ACTION_UPVOTE = "net.u_wave.android.UPVOTE";
  private static final String ACTION_DOWNVOTE = "net.u_wave.android.DOWNVOTE";
  private static final String ACTION_MUTE_UNMUTE = "net.u_wave.android.MUTE_UNMUTE";
  private static final String ACTION_DISCONNECT = "net.u_wave.android.DISCONNECT";

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), NAME);
    channel.setMethodCallHandler(new NotificationPlugin(registrar));
  }

  private final Registrar registrar;
  private final NotificationCompat.Builder notificationBuilder;
  private final RemoteViews notificationView;

  private NotificationPlugin(Registrar registrar) {
    this.registrar = registrar;

    notificationView = new RemoteViews("net.u_wave.android", R.layout.player_notification);

    // TODO hook these up via a background service.
    notificationView.setOnClickPendingIntent(R.id.upvote,
        PendingIntent.getBroadcast(this, NOTIFY_NOW_PLAYING, new Intent(ACTION_UPVOTE), PendingIntent.FLAG_UPDATE_CURRENT));
    notificationView.setOnClickPendingIntent(R.id.downvote,
        PendingIntent.getBroadcast(this, NOTIFY_NOW_PLAYING, new Intent(ACTION_DOWNVOTE), PendingIntent.FLAG_UPDATE_CURRENT));
    notificationView.setOnClickPendingIntent(R.id.muteUnmute,
        PendingIntent.getBroadcast(this, NOTIFY_NOW_PLAYING, new Intent(ACTION_MUTE_UNMUTE), PendingIntent.FLAG_UPDATE_CURRENT));
    notificationView.setOnClickPendingIntent(R.id.disconnect,
        PendingIntent.getBroadcast(this, NOTIFY_NOW_PLAYING, new Intent(ACTION_DISCONNECT), PendingIntent.FLAG_UPDATE_CURRENT));

    notificationBuilder = new NotificationCompat.Builder(registrar.context(), NAME)
      .setOngoing(true)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setCustomContentView(notificationView);
  }

  private NotificationManagerCompat getNotificationManager() {
    return NotificationManagerCompat.from(registrar.context());
  }

  private void onNowPlaying(Map<String, String> args, Result result) {
    if (args == null) {
      NotificationManagerCompat manager = getNotificationManager();
      manager.cancel(NOTIFY_NOW_PLAYING);
      result.success(null);
      return;
    }

    System.out.println("[NotificationPlugin] nowPlaying: " + args.get("artist") + " - " + args.get("title"));
    final int duration = Integer.parseInt(args.get("duration"));
    final int seek = Integer.parseInt(args.get("seek"));

    notificationView.setTextViewText(R.id.title, args.get("title"));
    notificationView.setTextViewText(R.id.artist, args.get("artist"));
    notificationView.setProgressBar(R.id.progressBar, duration, seek, false);

    NotificationManagerCompat manager = getNotificationManager();
    manager.notify(NOTIFY_NOW_PLAYING, notificationBuilder.build());

    result.success(null);
  }

  /* MethodCallHandler */
  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("nowPlaying")) {
      onNowPlaying((Map<String, String>) call.arguments, result);
    } else {
      result.notImplemented();
    }
  }
}