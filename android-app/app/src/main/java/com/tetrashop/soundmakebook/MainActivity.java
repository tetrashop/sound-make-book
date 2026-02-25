package com.tetrashop.soundmakebook;

import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.util.Log;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);
        webSettings.setAllowContentAccess(true);
        
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
                Log.d("WebView", consoleMessage.message() + " -- line " + consoleMessage.lineNumber() + " of " + consoleMessage.sourceId());
                return true;
            }
        });
        
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                showError("خطا در بارگذاری صفحه: " + description);
            }
        });

        try {
            // بررسی وجود فایل index.html در assets
            String[] files = getAssets().list("");
            boolean found = false;
            for (String file : files) {
                if (file.equals("index.html")) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                showError("فایل index.html در assets یافت نشد");
                return;
            }
            webView.loadUrl("file:///android_asset/index.html");
        } catch (Exception e) {
            showError("خطا: " + e.toString() + "\n" + Log.getStackTraceString(e));
            e.printStackTrace();
        }
    }

    private void showError(String message) {
        String html = "<html><body style='text-align:center;padding:20px;'><h2>خطا</h2><p>" + message.replace("\n", "<br>") + "</p></body></html>";
        webView.loadData(html, "text/html", "UTF-8");
    }
}
