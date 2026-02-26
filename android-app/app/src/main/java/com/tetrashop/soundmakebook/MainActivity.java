package com.tetrashop.soundmakebook;

import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.WebViewAssetLoader.AssetsPathHandler;

public class MainActivity extends AppCompatActivity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // ایجاد WebViewAssetLoader برای سرویس فایل‌های assets با پروتکل https
        final WebViewAssetLoader assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new AssetsPathHandler(this))
                .build();

        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(false);          // غیرفعال کردن دسترسی file://
        webSettings.setAllowContentAccess(false);       // غیرفعال کردن دسترسی content://
        webSettings.setAllowFileAccessFromFileURLs(false); // غیرفعال کردن دسترسی از فایل‌ها
        webSettings.setAllowUniversalAccessFromFileURLs(false);

        // تنظیم WebViewClient برای intercept کردن درخواست‌ها و پاسخ‌دهی با assetLoader
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                return assetLoader.shouldInterceptRequest(request.getUrl());
            }

            @Override
            @SuppressWarnings("deprecation") // برای سازگاری با اندروید پایین‌تر
            public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
                return assetLoader.shouldInterceptRequest(android.net.Uri.parse(url));
            }
        });

        // بارگذاری فایل index.html با آدرس https
        // دامنه appassets.androidplatform.net توسط WebViewAssetLoader رزرو شده است 
        webView.loadUrl("https://appassets.androidplatform.net/assets/index.html");
    }
}
