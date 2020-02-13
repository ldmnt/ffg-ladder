package com.ldmnt.ffgladder;

import androidx.fragment.app.FragmentActivity;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.view.View;
import android.webkit.ValueCallback;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.AdapterView;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;


public class MainActivity extends FragmentActivity implements DownloadCallback<String> {
    private static final String LADDER_URL = "http://ffg.jeudego.org/echelle/echtxt/ech_ffg_V3.txt";
    public static final String REPORT_KEY = "com.ldmnt.ffgladder.report";
    public static final String PLAYER_SELF_KEY = "com.ldmnt.ffgladder.self";
    public static final String OPPONENTS_KEY = "com.ldmnt.ffgladder.opponents";

    private Gson gson;
    private NetworkFragment networkFragment;
    private SharedPreferences preferences;

    private boolean downloading = false;
    private Player playerSelf = null;
    private OpponentsArrayAdapter opponents;
    private ArrayList<Player> opponentPlayers;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        networkFragment = NetworkFragment.getInstance(getSupportFragmentManager(), LADDER_URL);
        preferences = this.getPreferences(Context.MODE_PRIVATE);

        this.gson = new GsonBuilder().serializeNulls().disableHtmlEscaping().create();

        WebView webView = findViewById(R.id.webView);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        String html = "<script type=\"text/javascript\" src=\"stubs.js\"></script>";
        webView.loadDataWithBaseURL("file:///android_asset/", html, "text/html", "UTF-8", null);
        webView.setWebViewClient(new LadderLoader());

        AutoCompleteTextView inputPlayer = findViewById(R.id.inputPlayer);
        inputPlayer.setOnItemClickListener(new OnItemClickAddPlayer());
        inputPlayer.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                AutoCompleteTextView view = (AutoCompleteTextView) v;
                if (view.getText().toString().equals("")) {
                    if (hasFocus) {
                        view.setHint("");
                    }
                    else {
                        if (playerSelf == null) {
                            view.setHint(R.string.enter_player_self);
                        }
                        else {
                            view.setHint(R.string.enter_opponent);
                        }
                    }
                }
            }
        });

        opponentPlayers = new ArrayList<>();
        opponents = new OpponentsArrayAdapter(
                this,
                R.layout.opponent_list,
                R.id.playerName,
                opponentPlayers
        );
        ListView opponentsView = findViewById(R.id.opponentsView);
        opponentsView.setAdapter(opponents);
    }

    public MainActivity getContext() {
        return this;
    }

    public void simulate(View view) {
        if (playerSelf != null && opponents.getCount() > 0) {
            computeReport(
                    playerSelf.getRank(),
                    opponents.getMatchResults(),
                    new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String report) {
                            showReport(report);
                        }
                    });
        }
    }

    public void showReport(String report) {
        Intent intent = new Intent(this, ReportActivity.class);
        intent.putExtra(REPORT_KEY, report);
        intent.putExtra(PLAYER_SELF_KEY, gson.toJson(playerSelf));
        intent.putExtra(OPPONENTS_KEY, gson.toJson(opponentPlayers));
        startActivity(intent);
    }

    public void clearPlayers(View view) {
        opponents.clear();
        playerSelf = null;
        TextView textPlayerSelf = findViewById(R.id.textPlayerSelf);
        textPlayerSelf.setText(R.string.no_player_selected);
        AutoCompleteTextView inputPlayer = findViewById(R.id.inputPlayer);
        inputPlayer.setHint(R.string.enter_player_self);
    }

    private void runJavascript(String func, Object[] params, ValueCallback<String> callback) {
        WebView webView = findViewById(R.id.webView);
        String[] params_str = new String[params.length];
        for (int i = 0; i < params.length; i++) {
            params_str[i] = gson.toJson(params[i]);
        }
        String javascript = func + '(';
        for (String param : params_str) {
            javascript += param + ',';
        }
        javascript = javascript.substring(0, javascript.length() - 1) + ");";
        webView.evaluateJavascript(javascript, callback);
    }

    public void completeName(String name, int limit, final ValueCallback<ArrayList<Player>> callback) {
        Object[] params = new Object[2];
        params[0] = name;
        params[1] = limit;
        this.runJavascript("completeName", params, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                Type listType = new TypeToken<ArrayList<Player>>(){}.getType();
                ArrayList<Player> playerList = gson.fromJson(value, listType);
                callback.onReceiveValue(playerList);
            }
        });
    }

    public void computeReport(float initial_rank, ArrayList<MatchResult> results, final ValueCallback<String> callback) {
        Object[] params = new Object[2];
        params[0] = initial_rank;
        params[1] = results;
        this.runJavascript("newRankMatches", params, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                callback.onReceiveValue(value);
            }
        });
    }

    private void loadLadder(String s, final String inTimestamp) {
        WebView webView = findViewById(R.id.webView);
        webView.evaluateJavascript("loadLadder(\"" + s + "\")", new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                AutoCompleteTextView inputPlayer = findViewById(R.id.inputPlayer);
                inputPlayer.setAdapter(
                        new LadderAdapter(getContext(), android.R.layout.simple_list_item_1)
                );
                TextView textLadder = findViewById(R.id.textLadder);
                textLadder.setText("Stored ladder : " + inTimestamp);
            }
        });
    }

    public void downloadLadder(View view) {
        if (!downloading && networkFragment != null) {
            downloading = true;
            Button dlButton = findViewById(R.id.buttonDownload);
            dlButton.setText(R.string.downloading);
            networkFragment.startDownload();
        }
    }

    @Override
    public void updateFromDownload(String result) {
        result = result.replace("\r\n", "\\n");
        Date now = new Date();
        SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd");
        String ladderTimestamp = fmt.format(now);
        loadLadder(result, ladderTimestamp);

        SharedPreferences pref = this.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = pref.edit();
        editor.putString("ladder", result);
        editor.putString("ladderTimestamp", ladderTimestamp);
        editor.apply();

        Button dlButton = findViewById(R.id.buttonDownload);
        dlButton.setText(R.string.button_download);
        downloading = false;
    }

    @Override
    public NetworkInfo getActiveNetworkInfo() {
        ConnectivityManager connectivityManager =
                (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connectivityManager.getActiveNetworkInfo();
        return networkInfo;
    }

    @Override
    public void onProgressUpdate(int progressCode, int percentComplete) {
        switch(progressCode) {
            case Progress.ERROR:

                break;
            case Progress.CONNECT_SUCCESS:

                break;
            case Progress.GET_INPUT_STREAM_SUCCESS:

                break;
            case Progress.PROCESS_INPUT_STREAM_IN_PROGRESS:

                break;
            case Progress.PROCESS_INPUT_STREAM_SUCCESS:

                break;
        }
    }

    @Override
    public void finishDownloading() {
        downloading = false;
        if (networkFragment != null) {
            networkFragment.cancelDownload();
        }
    }

    private class LadderLoader extends WebViewClient {
        @Override
        public void onPageFinished(WebView view, String url) {
            String ladder = preferences.getString("ladder", "");
            String ladderTimestamp = preferences.getString("ladderTimestamp", "");
            if (!ladder.equals("") && !ladderTimestamp.equals("")) {
                loadLadder(ladder, ladderTimestamp);
            }
        }
    }

    private class OnItemClickAddPlayer implements AdapterView.OnItemClickListener {
        public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
            Player player = (Player) parent.getItemAtPosition(position);
            if (playerSelf == null) {
                playerSelf = player;
                TextView textPlayerSelf = findViewById(R.id.textPlayerSelf);
                textPlayerSelf.setText(playerSelf.toString());
            }
            else {
                opponents.add(player);
            }
            AutoCompleteTextView text = findViewById(R.id.inputPlayer);
            text.setText("");
            text.setHint(R.string.enter_opponent);
        }
    }
}