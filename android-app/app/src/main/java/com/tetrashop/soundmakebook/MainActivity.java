package com.tetrashop.soundmakebook;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.WebViewAssetLoader.AssetsPathHandler;

import java.util.Locale;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "SoundMakeBook";
    private WebView webView;
    private TextToSpeech textToSpeech;
    private boolean ttsReady = false;
    private String ttsStatus = "initializing";
    private final Handler timeoutHandler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Log.d(TAG, "onCreate: initializing TTS");
        // راه‌اندازی TextToSpeech با timeout 10 ثانیه
        textToSpeech = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                timeoutHandler.removeCallbacksAndMessages(null);
                Log.d(TAG, "onInit: status = " + status);
                if (status == TextToSpeech.SUCCESS) {
                    // تنظیم زبان فارسی
                    int result = textToSpeech.setLanguage(new Locale("fa", "IR"));
                    Log.d(TAG, "setLanguage(fa) result = " + result);
                    if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                        ttsStatus = "fa_missing";
                        Log.w(TAG, "Persian not supported, falling back to English");
                        result = textToSpeech.setLanguage(Locale.US);
                        Log.d(TAG, "setLanguage(en) result = " + result);
                        if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                            ttsStatus = "tts_unavailable";
                            ttsReady = false;
                            Log.e(TAG, "No language supported! TTS unavailable");
                        } else {
                            ttsReady = true;
                        }
                    } else {
                        ttsStatus = "fa_ready";
                        ttsReady = true;
                    }
                    textToSpeech.setPitch(1.0f);
                    textToSpeech.setSpeechRate(1.0f);
                } else {
                    ttsStatus = "failed";
                    ttsReady = false;
                    Log.e(TAG, "TTS initialization failed");
                }
                sendTtsStatusToJs();
            }
        });

        // Timeout: اگر بعد از 10 ثانیه TTS آماده نشد، وضعیت را خطا اعلام کن
        timeoutHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (!ttsReady) {
                    ttsStatus = "timeout";
                    Log.e(TAG, "TTS initialization timeout");
                    sendTtsStatusToJs();
                }
            }
        }, 10000); // 10 ثانیه

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

    private void sendTtsStatusToJs() {
        runOnUiThread(() -> {
            if (webView != null) {
                String script = "window.onTtsStatusUpdate && window.onTtsStatusUpdate('" + ttsStatus + "');";
                webView.evaluateJavascript(script, null);
            }
        });
    }

    // کلاس واسط برای جاوااسکریپت
    public class WebAppInterface {
        @JavascriptInterface
        public void speak(String text, String utteranceId) {
            runOnUiThread(() -> {
                Log.d(TAG, "speak called: text='" + text + "', id='" + utteranceId + "'");
                if (!ttsReady) {
                    String errorMsg = "TTS not ready: " + ttsStatus;
                    Log.e(TAG, errorMsg);
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('" + errorMsg + "');", null);
                    return;
                }
                if (text == null || text.trim().isEmpty()) {
                    Log.e(TAG, "speak: empty text");
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('متن خالی است');", null);
                    return;
                }
                Bundle params = new Bundle();
                params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId);
                int speakResult = textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId);
                if (speakResult == TextToSpeech.ERROR) {
                    Log.e(TAG, "speak returned ERROR");
                    webView.evaluateJavascript("window.onSpeechError && window.onSpeechError('خطا در پخش صدا');", null);
                } else {
                    Log.d(TAG, "speak called successfully, result=" + speakResult);
                }
            });
        }

        @JavascriptInterface
        public void stopSpeaking() {
            runOnUiThread(() -> {
                if (textToSpeech != null && textToSpeech.isSpeaking()) {
                    textToSpeech.stop();
                    Log.d(TAG, "stopSpeaking called");
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
                Log.d(TAG, "detectLanguage returning: " + result);
                webView.evaluateJavascript("window.onLanguageDetected && window.onLanguageDetected('" + result + "');", null);
            });
        }
    }

    @Override
    protected void onDestroy() {
        timeoutHandler.removeCallbacksAndMessages(null);
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
        super.onDestroy();
    }
}
