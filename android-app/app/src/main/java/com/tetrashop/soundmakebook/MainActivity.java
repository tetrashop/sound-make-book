package com.tetrashop.soundmakebook;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.WebViewAssetLoader.AssetsPathHandler;
import android.webkit.WebChromeClient;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;

public class MainActivity extends AppCompatActivity {
    private WebView webView;
    private Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        final WebViewAssetLoader assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new AssetsPathHandler(this))
                .build();

        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
webView.setWebChromeClient(new WebChromeClient());
        webSettings.setAllowFileAccess(false);
        webSettings.setAllowContentAccess(false);
        webSettings.setAllowFileAccessFromFileURLs(false);
        webSettings.setAllowUniversalAccessFromFileURLs(false);

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

    // تابع برای اجرای دستور eSpeak و پخش صدا
    private void speakWithEspeak(final String text) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    // اجرای دستور eSpeak و خروجی گرفتن به صورت مستقیم برای پخش
                    // نکته: در محیط اندروید معمولی، دسترسی به espeak وجود ندارد.
                    // این روش فقط در صورتی کار می‌کند که فایل باینری espeak در مسیر خاصی قرار داده شود.
                    // برای سادگی، فعلاً یک پیام تست جاوااسکریپت برمی‌گردانیم تا مشخص شود این بخش نیاز به توسعه دارد.
                    final String resultMessage = "در این نسخه از برنامه، پشتیبانی از eSpeak نیاز به راه‌اندازی اولیه دارد. لطفاً از روش TTS سیستم استفاده کنید.";
                    mainHandler.post(new Runnable() {
                        @Override
                        public void run() {
                            webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('" + resultMessage + "');", null);
                        }
                    });
                } catch (Exception e) {
                    final String errorMessage = "خطا در اجرای eSpeak: " + e.getMessage();
                    mainHandler.post(new Runnable() {
                        @Override
                        public void run() {
                            webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('" + errorMessage + "');", null);
                        }
                    });
                }
            }
        }).start();
    }
public class WebAppInterface {
    private TextToSpeech textToSpeech;
    private boolean ttsReady = false;
    private String ttsStatus = "initializing";

    public WebAppInterface() {
        textToSpeech = new TextToSpeech(MainActivity.this, new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                if (status == TextToSpeech.SUCCESS) {
                    // تنظیم زبان فارسی
                    int result = textToSpeech.setLanguage(new Locale("fa", "IR"));
                    if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                        ttsStatus = "fa_missing";
                        // fallback به انگلیسی
                        textToSpeech.setLanguage(Locale.US);
                        ttsReady = true;
                    } else {
                        ttsStatus = "fa_ready";
                        ttsReady = true;
                    }
                    textToSpeech.setPitch(1.0f);
                    textToSpeech.setSpeechRate(1.0f);
                } else {
                    ttsStatus = "failed";
                }
            }
        });
    }

    @JavascriptInterface
    public void speak(String text, String utteranceId) {
        runOnUiThread(() -> {
            if (!ttsReady) {
                webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('TTS not ready: " + ttsStatus + "');", null);
                return;
            }
            if (text == null || text.trim().isEmpty()) {
                webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('متن خالی است');", null);
                return;
            }
            Bundle params = new Bundle();
            params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId);
            textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId);
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
            webView.evaluateJavascript("window.onLanguageDetected && window.onLanguageDetected('" + result + "');", null);
        });
    }
}
}
