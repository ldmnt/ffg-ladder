package com.ldmnt.ffgladder;

public class Player {
    private String name;
    private float rank;

    Player(String name, float rank) {
        this.name = name;
        this.rank = rank;
    }

    String getName() {
        return this.name;
    }

    float getRank() {
        return this.rank;
    }

    public String toString() {
        return String.format("%s : %.0f", this.name, this.rank);
    }
}
