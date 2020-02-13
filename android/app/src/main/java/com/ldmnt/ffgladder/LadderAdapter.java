package com.ldmnt.ffgladder;

import android.webkit.ValueCallback;

import android.widget.ArrayAdapter;
import android.widget.Filter;
import android.widget.Filterable;

import java.util.ArrayList;


public class LadderAdapter extends ArrayAdapter<Player> implements Filterable {
    private static final int SUGGESTION_LIMIT = 4;

    public LadderAdapter(MainActivity context, int resource) {
        super(context, resource);
    }

    @Override
    public MainActivity getContext() {
        return (MainActivity) super.getContext();
    }

    @Override
    public Filter getFilter() {
        return nameFilter;
    }

    private Filter nameFilter = new Filter() {
        private ValueCallback<ArrayList<Player>> updateSuggestions = new ValueCallback<ArrayList<Player>>() {
            @Override
            public void onReceiveValue(ArrayList<Player> players) {
                clear();
                addAll(players);
                notifyDataSetChanged();
            }
        };

        @Override
        protected FilterResults performFiltering(final CharSequence constraint) {
            FilterResults results = new FilterResults();
            if (constraint != null) {
                getContext().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        getContext().completeName(constraint.toString(), SUGGESTION_LIMIT, updateSuggestions);
                    }
                });

            }
            return results;
        }

        @Override
        protected void publishResults(CharSequence constraint, FilterResults results) {}
    };
}
