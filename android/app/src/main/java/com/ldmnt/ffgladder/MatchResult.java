package com.ldmnt.ffgladder;

public class MatchResult {
    private float opponentRank;
    private boolean result;

    public MatchResult(float opponentRank, boolean result) {
        this.opponentRank = opponentRank;
        this.result = result;
    }

    public void setResult(boolean result) {
        this.result = result;
    }
}
