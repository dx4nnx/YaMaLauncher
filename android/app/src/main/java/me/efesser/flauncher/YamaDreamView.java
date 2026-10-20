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

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.util.PathUtils;

/**
 * YaMa's screensaver screen: the launcher's wallpapers shown full screen with
 * its transitions, dim and shadow, plus the clock in the launcher's style.
 * Settings come from screensaver.json, which the launcher keeps up to date.
 * Used by {@link YamaDream} (the real screensaver) and the preview activity.
 */
public class YamaDreamView extends FrameLayout {
    private static final String USER_AGENT = "android:app.yama.launcher:1.0 (YaMa Launcher screensaver)";

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ExecutorService loader = Executors.newSingleThreadExecutor();
    private final Random random = new Random();

    private final ImageView[] pictures = new ImageView[2];
    private final Bitmap[] bitmaps = new Bitmap[2];
    private int front = 0;
    private final TextView timeView;
    private final TextView dateView;
    private final LinearLayout clock;

    private final List<String> sources = new ArrayList<>();
    private int position = 0;
    private boolean remote = false;
    private long intervalMs = 60_000;
    private String transition = "fade";
    private SimpleDateFormat timeFormat;
    private SimpleDateFormat dateFormat;
    private boolean showTime = true;
    private boolean showDate = true;
    private boolean running = false;
    private int skips = 0;

    private final Runnable advance = new Runnable() {
        @Override
        public void run() {
            showNext();
        }
    };

    private final Runnable tick = new Runnable() {
        @Override
        public void run() {
            Date now = new Date();
            if (timeFormat != null) timeView.setText(timeFormat.format(now));
            if (dateFormat != null) dateView.setText(dateFormat.format(now));
            handler.postDelayed(this, 1000);
        }
    };

    public YamaDreamView(Context context) {
        super(context);
        setBackgroundColor(Color.BLACK);

        for (int i = 0; i < 2; i++) {
            ImageView view = new ImageView(context);
            view.setScaleType(ImageView.ScaleType.CENTER_CROP);
            view.setAlpha(0f);
            addView(view, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            pictures[i] = view;
        }

        timeView = new TextView(context);
        dateView = new TextView(context);
        clock = new LinearLayout(context);
        clock.setOrientation(LinearLayout.VERTICAL);
        clock.setGravity(Gravity.END);
        clock.addView(timeView);
        clock.addView(dateView);
    }

    /** Reads the launcher's settings and starts the show. */
    public void start() {
        if (running) return;
        running = true;
        JSONObject config = readConfig();
        applyLook(config);
        readSources(config);
        handler.post(tick);
        if (sources.isEmpty()) {
            showFallback(config);
        } else {
            showNext();
        }
    }

    public void stop() {
        running = false;
        handler.removeCallbacksAndMessages(null);
        loader.shutdownNow();
        for (int i = 0; i < 2; i++) {
            pictures[i].setImageDrawable(null);
            if (bitmaps[i] != null) {
                bitmaps[i].recycle();
                bitmaps[i] = null;
            }
        }
    }

    private JSONObject readConfig() {
        try {
            File file = new File(PathUtils.getDataDirectory(getContext()), "screensaver.json");
            try (InputStream in = new FileInputStream(file)) {
                return new JSONObject(new String(readAll(in), StandardCharsets.UTF_8));
            }
        } catch (Exception e) {
            return new JSONObject();
        }
    }

    private void applyLook(JSONObject config) {
        // Dim and the soft top/bottom shadow, as on the home screen.
        double dim = config.optDouble("dim", 0) / 100.0;
        if (dim > 0) {
            View dimView = new View(getContext());
            dimView.setBackgroundColor(Color.argb((int) Math.round(Math.min(dim, 0.9) * 255), 0, 0, 0));
            addView(dimView, 2, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        }
        double shadow = config.optDouble("shadow", 35) / 100.0;
        if (shadow > 0) {
            int top = Color.argb((int) Math.round(Math.min(shadow * 0.75, 1) * 255), 0, 0, 0);
            int bottom = Color.argb((int) Math.round(Math.min(shadow, 1) * 255), 0, 0, 0);
            GradientDrawable gradient = new GradientDrawable(
                    GradientDrawable.Orientation.TOP_BOTTOM,
                    new int[]{top, Color.TRANSPARENT, Color.TRANSPARENT, bottom});
            View shadowView = new View(getContext());
            shadowView.setBackground(gradient);
            addView(shadowView, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        }

        JSONObject c = config.optJSONObject("clock");
        if (c == null) c = new JSONObject();
        showTime = c.optBoolean("showTime", true);
        showDate = c.optBoolean("showDate", true);
        boolean twoLines = c.optBoolean("twoLines", true);
        int color = (int) c.optLong("color", 0xFFFFFFFFL);
        float size = (float) c.optDouble("size", 24);
        boolean textShadow = c.optBoolean("shadow", true);
        timeFormat = format(c.optString("timeFormat", "H:mm"), "H:mm");
        dateFormat = format(c.optString("dateFormat", "EEEE d"), "EEEE d");

        Typeface bold = font(config.optString("font", "Poppins"), true);
        Typeface regular = font(config.optString("font", "Poppins"), false);

        // The screensaver clock is larger than the home-screen clock.
        float timeSize = size * 2.4f;
        float dateSize = size * (twoLines ? 0.9f : 1.1f);
        style(timeView, bold, timeSize, color, textShadow);
        style(dateView, regular, dateSize, (color & 0x00FFFFFF) | 0xD9000000, textShadow);
        timeView.setVisibility(showTime ? View.VISIBLE : View.GONE);
        dateView.setVisibility(showDate ? View.VISIBLE : View.GONE);
        if (!twoLines) {
            clock.setOrientation(LinearLayout.HORIZONTAL);
            clock.setGravity(Gravity.BOTTOM);
            clock.removeAllViews();
            clock.addView(dateView);
            LinearLayout.LayoutParams gap = new LinearLayout.LayoutParams(dp(18), 1);
            clock.addView(new View(getContext()), gap);
            clock.addView(timeView);
        }

        LayoutParams params = new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM | Gravity.END);
        params.setMargins(dp(48), dp(48), dp(56), dp(44));
        addView(clock, params);

        intervalMs = Math.max(15, config.optLong("interval", 60)) * 1000L;
        transition = config.optString("transition", "fade");
    }

    private void readSources(JSONObject config) {
        JSONArray local = config.optJSONArray("local");
        if (local != null) {
            for (int i = 0; i < local.length(); i++) {
                String path = local.optString(i, "");
                if (!path.isEmpty() && new File(path).isFile()) sources.add(path);
            }
        }
        if (sources.isEmpty()) {
            JSONArray urls = config.optJSONArray("remote");
            if (urls != null) {
                for (int i = 0; i < urls.length(); i++) {
                    String url = urls.optString(i, "");
                    if (url.startsWith("http")) sources.add(url);
                }
                remote = !sources.isEmpty();
            }
        }
        Collections.shuffle(sources, random);
    }

    /** Gradient or solid color, when there are no pictures to show. */
    private void showFallback(JSONObject config) {
        JSONArray colors = config.optJSONArray("colors");
        int[] values;
        if (colors != null && colors.length() >= 2) {
            values = new int[colors.length()];
            for (int i = 0; i < colors.length(); i++) values[i] = (int) colors.optLong(i, 0xFF1B2440L);
        } else {
            int color = colors != null && colors.length() == 1 ? (int) colors.optLong(0, 0xFF1B2440L) : 0xFF1B2440;
            values = new int[]{color, color};
        }
        setBackground(new GradientDrawable(GradientDrawable.Orientation.TL_BR, values));
    }

    private void showNext() {
        if (!running || sources.isEmpty()) return;
        final String source = sources.get(position % sources.size());
        position++;
        if (position >= sources.size()) {
            position = 0;
            if (sources.size() > 2) Collections.shuffle(sources, random);
        }
        final int width = getWidth() > 0 ? getWidth() : getResources().getDisplayMetrics().widthPixels;
        final int height = getHeight() > 0 ? getHeight() : getResources().getDisplayMetrics().heightPixels;
        try {
            loader.execute(() -> {
                Bitmap bitmap = load(source, width, height);
                handler.post(() -> onLoaded(bitmap));
            });
        } catch (Exception ignored) {
            // Loader already stopped.
        }
    }

    private void onLoaded(Bitmap bitmap) {
        if (!running) {
            if (bitmap != null) bitmap.recycle();
            return;
        }
        boolean portrait = bitmap != null && bitmap.getHeight() > bitmap.getWidth();
        if (bitmap == null || (remote && portrait && skips < 8)) {
            if (bitmap != null) bitmap.recycle();
            skips++;
            // Try the next picture soon instead of waiting a whole interval.
            handler.postDelayed(advance, skips < sources.size() ? 300 : intervalMs);
            return;
        }
        skips = 0;

        final int back = 1 - front;
        final ImageView incoming = pictures[back];
        final ImageView outgoing = pictures[front];
        // Swap the picture first, then free the old one (never free a bitmap
        // a view may still draw).
        Bitmap old = bitmaps[back];
        incoming.animate().cancel();
        incoming.setImageBitmap(bitmap);
        bitmaps[back] = bitmap;
        if (old != null) old.recycle();

        String effect = transition;
        if ("random".equals(effect)) {
            String[] options = {"fade", "zoom", "slideHorizontal", "slideVertical"};
            effect = options[random.nextInt(options.length)];
        }
        incoming.setAlpha(0f);
        incoming.setTranslationX(0f);
        incoming.setTranslationY(0f);
        incoming.setScaleX(1f);
        incoming.setScaleY(1f);
        switch (effect) {
            case "zoom" -> {
                incoming.setScaleX(1.12f);
                incoming.setScaleY(1.12f);
            }
            case "slideHorizontal" -> incoming.setTranslationX(getWidth() * 0.25f);
            case "slideVertical" -> incoming.setTranslationY(getHeight() * 0.25f);
            default -> { }
        }
        final long drift = Math.max(4000, intervalMs - 1600);
        incoming.animate().alpha(1f).scaleX(1f).scaleY(1f).translationX(0f).translationY(0f)
                .setDuration(1600).setInterpolator(new DecelerateInterpolator())
                .withEndAction(() -> {
                    // A very slow drift while the picture is on screen.
                    if (running && front == back) {
                        incoming.animate().scaleX(1.05f).scaleY(1.05f).setDuration(drift)
                                .setInterpolator(null).withEndAction(null).start();
                    }
                })
                .start();
        outgoing.animate().cancel();
        outgoing.animate().alpha(0f).setDuration(1600).start();
        front = back;

        if (sources.size() > 1 || remote) {
            handler.postDelayed(advance, intervalMs);
        }
    }

    private Bitmap load(String source, int width, int height) {
        try {
            byte[] data;
            if (source.startsWith("http")) {
                HttpURLConnection connection = (HttpURLConnection) new URL(source).openConnection();
                connection.setConnectTimeout(15_000);
                connection.setReadTimeout(30_000);
                connection.setRequestProperty("User-Agent", USER_AGENT);
                try (InputStream in = connection.getInputStream()) {
                    data = readAll(in);
                } finally {
                    connection.disconnect();
                }
            } else {
                try (InputStream in = new FileInputStream(source)) {
                    data = readAll(in);
                }
            }
            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            BitmapFactory.decodeByteArray(data, 0, data.length, bounds);
            int sample = 1;
            while (bounds.outWidth / (sample * 2) >= width && bounds.outHeight / (sample * 2) >= height) {
                sample *= 2;
            }
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inSampleSize = sample;
            return BitmapFactory.decodeByteArray(data, 0, data.length, options);
        } catch (Throwable e) {
            return null;
        }
    }

    private static byte[] readAll(InputStream in) throws java.io.IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[16384];
        int read;
        while ((read = in.read(buffer)) != -1) out.write(buffer, 0, read);
        return out.toByteArray();
    }

    private static SimpleDateFormat format(String pattern, String fallback) {
        try {
            return new SimpleDateFormat(pattern, Locale.getDefault());
        } catch (Exception e) {
            return new SimpleDateFormat(fallback, Locale.getDefault());
        }
    }

    private Typeface font(String family, boolean bold) {
        if (family == null || family.isEmpty() || "System".equals(family)) {
            return bold ? Typeface.DEFAULT_BOLD : Typeface.DEFAULT;
        }
        try {
            return Typeface.createFromAsset(getContext().getAssets(),
                    "flutter_assets/assets/fonts/" + family + (bold ? "-Bold.ttf" : "-Regular.ttf"));
        } catch (Exception e) {
            return bold ? Typeface.DEFAULT_BOLD : Typeface.DEFAULT;
        }
    }

    private void style(TextView view, Typeface typeface, float sizeDp, int color, boolean shadow) {
        view.setTypeface(typeface);
        view.setTextSize(TypedValue.COMPLEX_UNIT_DIP, sizeDp);
        view.setTextColor(color);
        view.setIncludeFontPadding(false);
        if (shadow) view.setShadowLayer(dp(10), 0, dp(2), 0x8A000000);
    }

    private int dp(float value) {
        DisplayMetrics metrics = getResources().getDisplayMetrics();
        return Math.round(value * metrics.density);
    }
}
