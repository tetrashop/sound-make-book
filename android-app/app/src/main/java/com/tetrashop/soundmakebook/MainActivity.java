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
    private boolean ttsReady = false;
    private String ttsStatus = "initializing";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // راه‌اندازی TextToSpeech با لیسینر پیشرفته
        textToSpeech = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                if (status == TextToSpeech.SUCCESS) {
                    // تنظیم زبان فارسی
                    int result = textToSpeech.setLanguage(new Locale("fa", "IR"));
                    if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                        // اگر فارسی نبود، انگلیسی را امتحان کن
                        result = textToSpeech.setLanguage(Locale.US);
                        if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                            ttsStatus = "unsupported";
                            showToast("هیچ زبانی برای TTS پشتیبانی نمی‌شود");
                        } else {
                            ttsStatus = "ready_en";
                            ttsReady = true;
                        }
                    } else {
                        ttsStatus = "ready_fa";
                        ttsReady = true;
                    }

                    // تنظیم پارامترهای صدا
                    if (ttsReady) {
                        textToSpeech.setPitch(1.0f);
                        textToSpeech.setSpeechRate(1.0f);

                        // تنظیم لیسینر برای اطلاع از پایان پخش
                        textToSpeech.setOnUtteranceProgressListener(new UtteranceProgressListener() {
                            @Override
                            public void onStart(String utteranceId) {
                                // پخش شروع شد
                            }

                            @Override
                            public void onDone(String utteranceId) {
                                // پخش تمام شد - می‌توان به JS اطلاع داد
                                runOnUiThread(() -> {
                                    String script = "window.onSpeechDone && window.onSpeechDone('" + utteranceId + "');";
                                    webView.evaluateJavascript(script, null);
                                });
                            }

                            @Override
                            public void onError(String utteranceId) {
                                // خطا در پخش
                                runOnUiThread(() -> {
                                    String script = "window.onSpeechError && window.onSpeechError('" + utteranceId + "');";
                                    webView.evaluateJavascript(script, null);
                                });
                            }
                        });
                    }
                } else {
                    ttsStatus = "failed";
                    showToast("TTS اولیه‌سازی نشد");
                }
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
            runOnUiThread(() -> {
                if (!ttsReady) {
                    // TTS آماده نیست
                    String msg = "TTS آماده نیست. وضعیت: " + ttsStatus;
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('" + msg + "');", null);
                    return;
                }

                if (textToSpeech == null) {
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('TTS مقدار null است');", null);
                    return;
                }

                // بررسی خالی نبودن متن
                if (text == null || text.trim().isEmpty()) {
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('متن خالی است');", null);
                    return;
                }

                // قطع پخش قبلی
                if (textToSpeech.isSpeaking()) {
                    textToSpeech.stop();
                }

                // تنظیم پارامترها
                Bundle params = new Bundle();
                params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId);

                // پخش صدا
                int result = textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId);
                if (result == TextToSpeech.ERROR) {
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('خطا در پخش صدا');", null);
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
        public String getTtsStatus() {
            return ttsStatus;
        }

        @JavascriptInterface
        public void detectLanguage(String text) {
            String lang = "fa";
            if (text.matches(".*[a-zA-Z].*")) {
                lang = "en";
            }
            final String result = lang;
            runOnUiThread(() -> {
                String script = "window.onLanguageDetected && window.onLanguageDetected('" + result + "');";
                webView.evaluateJavascript(script, null);
            });
        }
    }

    private void showToast(final String msg) {
        runOnUiThread(() -> Toast.makeText(this, msg, Toast.LENGTH_LONG).show());
    }

    @Override
    protected void onDestroy() {
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
        super.onDestroy();
    }
}
