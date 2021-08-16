package com.sun.javafx.font;

import com.sun.javafx.tk.FontLoader;
import java.util.LinkedList;
import java.util.List;
import javafx.scene.text.Font;
import javafx.scene.text.FontPosture;
import javafx.scene.text.FontWeight;

public class WebFontLoader extends FontLoader {

    final List<String> fontNames = new LinkedList<String>();

    public void loadFont(Font font) {
    }

    public List<String> getFamilies() {
        return getFontNames();
    }

    public List<String> getFontNames() {
        if (fontNames.isEmpty()) {
            fontNames.add("Verdana");
        }
        return fontNames;
    }

    public abstract List<String> getFontNames(String family) {
        return fontNames;
    }

    public Font font(String family, FontWeight weight, 
                              FontPosture posture, float size) {
        throw new UnsupportedOperationException("[FONTLOADER]");
    }

    public Font[] loadFont(InputStream in, double size, boolean all) {
        throw new UnsupportedOperationException("[FONTLOADER]");
    }
    public Font[] loadFont(String path, double size, boolean all) {
        throw new UnsupportedOperationException("[FONTLOADER]");
    }
    public FontMetrics getFontMetrics(Font font) {
        throw new UnsupportedOperationException("[FONTLOADER]");
    }
    public int getCharWidth(char ch, Font font) {
        throw new UnsupportedOperationException("[FONTLOADER]");
    }
    public float getSystemFontSize() {
        return 12.0f;
    }

}
