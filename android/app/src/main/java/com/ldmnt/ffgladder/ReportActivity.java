package com.ldmnt.ffgladder;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.widget.TableLayout;
import android.widget.TableRow;
import android.widget.TextView;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;

public class ReportActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_report);

        Gson gson = new GsonBuilder().serializeNulls().disableHtmlEscaping().create();

        Intent intent = getIntent();
        Report report = gson.fromJson(
                intent.getStringExtra(MainActivity.REPORT_KEY),
                Report.class
        );
        Player playerSelf = gson.fromJson(
                intent.getStringExtra(MainActivity.PLAYER_SELF_KEY),
                Player.class
        );
        Type listType = new TypeToken<ArrayList<Player>>(){}.getType();
        ArrayList<Player> opponentPlayers = gson.fromJson(
                intent.getStringExtra(MainActivity.OPPONENTS_KEY),
                listType
        );

        TextView initialRank = findViewById(R.id.initialRank);
        initialRank.setText(String.format("Initial rank : %.0f", playerSelf.getRank()));

        TextView finalRank = findViewById(R.id.finalRank);
        finalRank.setText(String.format("Final rank : %.1f", report.newRank));

        float[] variations = report.variations;
        LayoutInflater inflater = getLayoutInflater();
        TableLayout table = findViewById(R.id.tableReport);

        for (int i = 0; i < opponentPlayers.size(); i++) {
            Player opponent = opponentPlayers.get(i);
            float variation = variations[i];

            TableRow row = (TableRow) inflater.inflate(R.layout.report_row, null);
            TextView name = (TextView) row.getChildAt(0);
            TextView rank = (TextView) row.getChildAt(1);
            TextView var = (TextView) row.getChildAt(2);
            name.setText(opponent.getName());
            rank.setText(String.format("%.0f", opponent.getRank()));
            String sign = variation >= 0 ? "+" : "";
            var.setText(sign + String.format("%.1f", variation));

            table.addView(row);
        }
    }

    private class Report {
        public float newRank;
        public float[] variations;

        public Report(float newRank, float[] variations) {
            this.newRank = newRank;
            this.variations = variations;
        }
    }
}
