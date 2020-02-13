package com.ldmnt.ffgladder;

import android.content.Context;
import android.view.inputmethod.CompletionInfo;

import androidx.appcompat.widget.AppCompatAutoCompleteTextView;

public class AutoCompleteName extends AppCompatAutoCompleteTextView {
    AutoCompleteName(Context context) {
        super(context);
    }

    @Override
    public void onCommitCompletion (CompletionInfo completion) {

    }
}
