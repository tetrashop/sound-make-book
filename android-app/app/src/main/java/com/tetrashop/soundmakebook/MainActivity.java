package com.tetrashop.soundmakebook;

import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.JavascriptInterface;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.content.Intent;
import android.speech.RecognizerIntent;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.WebViewAssetLoader.AssetsPathHandler;

import java.util.Locale;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class MainActivity extends AppCompatActivity {
    private WebView webView;
    private TextToSpeech textToSpeech;
    private Map<String, TtsCallback> ttsCallbacks = new HashMap<>();

    // رابط برای دریافت نتیجه TTS
    interface TtsCallback {
        void onDone(String utteranceId);
        void onError(String utteranceId);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // راه‌اندازی TextToSpeech
        textToSpeech = new TextToSpeech(this, status -> {
            if (status == TextToSpeech.SUCCESS) {
                // تنظیم زبان فارسی
                int result = textToSpeech.setLanguage(new Locale("fa", "IR"));
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    runOnUiThread(() -> Toast.makeText(this, "زبان فارسی پشتیبانی نمی‌شود", Toast.LENGTH_LONG).show());
                } else {
                    textToSpeech.setPitch(1.0f);
                    textToSpeech.setSpeechRate(1.0f);
                }
            } else {
                runOnUiThread(() -> Toast.makeText(this, "TTS اولیه‌سازی نشد", Toast.LENGTH_LONG).show());
            }
        });

        // تنظیم WebViewAssetLoader
        final WebViewAssetLoader assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new AssetsPathHandler(this))
                .build();

        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(false);
        webSettings.setAllowContentAccess(false);
        webSettings.setAllowFileAccessFromFileURLs(false);
        webSettings.setAllowUniversalAccessFromFileURLs(false);

        // افزودن JavaScript Interface
        webView.addJavascriptInterface(new WebAppInterface(), "AndroidBridge");

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                return assetLoader.shouldInterceptRequest(request.getUrl());
            }

            @Override
            @SuppressWarnings("deprecation")
            public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
                return assetLoader.shouldInterceptRequest(android.net.Uri.parse(url));
            }
        });

        webView.loadUrl("https://appassets.androidplatform.net/assets/index.html");
    }

    // کلاس واسط برای جاوااسکریپت
    public class WebAppInterface {
        @JavascriptInterface
        public void speak(String text, String utteranceId) {
            // تابع تولید گفتار
            runOnUiThread(() -> {
                if (textToSpeech != null && !textToSpeech.isSpeaking()) {
                    Bundle params = new Bundle();
                    params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId);
                    textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId);
                }
            });
        }

        @JavascriptInterface
        public void stopSpeaking() {
            runOnUiThread(() -> {
                if (textToSpeech != null && textToSpeech.isSpeaking()) {
                    textToSpeech.stop();
                }
            });
        }

        @JavascriptInterface
        public void detectLanguage(String text) {
            // تشخیص زبان با روش ساده (فقط فارسی/انگلیسی)
            String lang = "fa";
            if (text.matches(".*[a-zA-Z].*")) {
                lang = "en";
            }
            // ارسال نتیجه به جاوااسکریپت
            final String result = lang;
            runOnUiThread(() -> {
                String script = "window.onLanguageDetected && window.onLanguageDetected('" + result + "');";
                webView.evaluateJavascript(script, null);
            });
        }

        @JavascriptInterface
        public void performOcr(String imageData) {
            // در این نسخه، OCR را غیرفعال می‌کنیم (می‌توان بعداً با کتابخانه‌های جاوا اضافه کرد)
            runOnUiThread(() -> {
                String script = "window.onOcrResult && window.onOcrResult('" + "OCR در این نسخه غیرفعال است" + "');";
                webView.evaluateJavascript(script, null);
            });
        }

        @JavascriptInterface
        public void saveProject(String name, String audioUrl, String settings) {
            // ذخیره‌سازی پروژه (می‌توان با SharedPreferences یا فایل انجام داد)
            // اینجا فقط یک پیغام ساده برمی‌گردانیم
            runOnUiThread(() -> {
                String script = "window.onProjectSaved && window.onProjectSaved('" + name + "');";
                webView.evaluateJavascript(script, null);
            });
        }

        @JavascriptInterface
        public void listProjects() {
            // برگرداندن لیست پروژه‌ها (فعلاً خالی)
            runOnUiThread(() -> {
                String script = "window.onProjectsListed && window.onProjectsListed('[]');";
                webView.evaluateJavascript(script, null);
            });
        }
    }

    // برای دریافت رویدادهای TTS
    @Override
    protected void onDestroy() {
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
        super.onDestroy();
    }
}
