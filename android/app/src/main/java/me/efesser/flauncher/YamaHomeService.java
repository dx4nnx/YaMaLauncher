/*
 * YaMa Launcher (based on FLauncher)
 * Copyright (C) 2026
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package me.efesser.flauncher;

import android.accessibilityservice.AccessibilityService;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ResolveInfo;
import android.util.Log;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import android.os.SystemClock;
import android.provider.Settings;
import android.view.accessibility.AccessibilityEvent;

/**
 * Sends the Home button to YaMa: when the Fire TV home screen comes up, YaMa
 * is opened on top of it. Fire OS doesn't let users pick another home app,
 * so this is the usual workaround. Switched on once with ADB:
 * adb shell settings put secure enabled_accessibility_services app.yama.launcher/me.efesser.flauncher.YamaHomeService
 */
public class YamaHomeService extends AccessibilityService {
    static final String PREFS = "yama_home_button";
    static final String KEY_ENABLED = "enabled";
    static final String KEY_PAUSE_UNTIL = "pause_until";

    private static final String TAG = "YamaHome";

    private long lastLaunch = 0;
    private final Set<String> homePackages = new HashSet<>();

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        findHomePackages();
        Log.i(TAG, "Home button helper started; watching " + homePackages);
    }

    /** Every app that answers the Home button, except YaMa itself. */
    private void findHomePackages() {
        homePackages.clear();
        homePackages.add("com.amazon.tv.launcher");
        homePackages.add("com.amazon.firehomestarter");
        try {
            Intent home = new Intent(Intent.ACTION_MAIN);
            home.addCategory(Intent.CATEGORY_HOME);
            List<ResolveInfo> handlers = getPackageManager().queryIntentActivities(home, 0);
            for (ResolveInfo info : handlers) {
                if (info.activityInfo != null) homePackages.add(info.activityInfo.packageName);
            }
        } catch (Exception ignored) {
        }
        homePackages.remove(getPackageName());
    }

    static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    /** Whether the person switched the service on in the system (with ADB). */
    static boolean isServiceOn(Context context) {
        String services = Settings.Secure.getString(context.getContentResolver(),
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        return services != null && services.contains(context.getPackageName() + "/" + YamaHomeService.class.getName());
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null || event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        CharSequence pkg = event.getPackageName();
        if (pkg == null) return;
        String name = pkg.toString();
        Log.d(TAG, "Screen: " + name + " / " + event.getClassName());
        if (!homePackages.contains(name)) return;

        SharedPreferences prefs = prefs(this);
        if (!prefs.getBoolean(KEY_ENABLED, true)) {
            Log.d(TAG, "Home button redirect is switched off in YaMa");
            return;
        }
        if (System.currentTimeMillis() < prefs.getLong(KEY_PAUSE_UNTIL, 0)) return;

        long now = SystemClock.elapsedRealtime();
        if (now - lastLaunch < 1500) return;   // one bounce per press
        lastLaunch = now;

        Intent intent = new Intent(this, MainActivity.class);
        intent.setAction(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                | Intent.FLAG_ACTIVITY_NO_ANIMATION);
        try {
            startActivity(intent);
            Log.i(TAG, "Fire TV home (" + name + ") opened; switching to YaMa");
        } catch (Exception e) {
            Log.w(TAG, "Couldn't open YaMa", e);
        }
    }

    @Override
    public void onInterrupt() {
    }
}
