package com.ldmnt.ffgladder;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.RadioGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;

public class OpponentsArrayAdapter extends ArrayAdapter<Player> {
    private OnCheckedChangedUpdateResults onCheckedChangeUpdateResults = new OnCheckedChangedUpdateResults();
    private LayoutInflater inflater;
    private ArrayList<MatchResult> results;
    private int layoutResource;

    public OpponentsArrayAdapter(Context context, int layoutResource, int textViewId, ArrayList<Player> players) {
        super(context, layoutResource, textViewId, players);
        this.layoutResource = layoutResource;
        inflater = LayoutInflater.from(context);
        results = new ArrayList<>();
    }

    public ArrayList<MatchResult> getMatchResults() {
        return results;
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        if (convertView == null) {
            convertView = inflater.inflate(layoutResource, null);
            RadioGroup radio = convertView.findViewById(R.id.radioGroup);
            radio.setTag(position);
            radio.setOnCheckedChangeListener(onCheckedChangeUpdateResults);
        }
        return super.getView(position, convertView, parent);
    }

    @Override
    public void add(@Nullable Player opponent) {
        super.add(opponent);
        results.add(new MatchResult(opponent.getRank(), true));
    }

    @Override
    public void clear() {
        super.clear();
        results.clear();
    }

    private class OnCheckedChangedUpdateResults implements RadioGroup.OnCheckedChangeListener {
        @Override
        public void onCheckedChanged(RadioGroup group, int checkedId) {
            int index = (int) group.getTag();
            if (checkedId == R.id.winButton) {
                results.get(index).setResult(true);
            }
            else if (checkedId == R.id.lossButton) {
                results.get(index).setResult(false);
            }
        }
    }
}
