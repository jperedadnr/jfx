package com.sun.javafx.text;

import javafx.scene.shape.PathElement;
import com.sun.javafx.geom.BaseBounds;
import com.sun.javafx.geom.RectBounds;
import com.sun.javafx.geom.Shape;
import com.sun.javafx.scene.text.*;

public class WebTextLayout implements TextLayout {

    public boolean setContent(TextSpan[] spans) {
        return false;
    }

    public boolean setContent(String string, Object font) {
        return false;
    }

    public boolean setAlignment(int alignment) {
        return false;
    }

    public boolean setWrapWidth(float wrapWidth) {
        return false;
    }

    public boolean setLineSpacing(float spacing) {
        return false;
    }

    public boolean setDirection(int direction) {
        return false;
    }

    public boolean setBoundsType(int type) {
        return false;
    }

    public BaseBounds getBounds() {
        return new RectBounds(0f, 0f, 100f, 100f);
    }

    public BaseBounds getBounds(TextSpan filter, BaseBounds bounds) {
        return getBounds();
    }

    public BaseBounds getVisualBounds(int type) {
        return getBounds();
    }

    public TextLine[] getLines() {
        throw new UnsupportedOperationException("[TEXTLAYOUT] getLines");
    }

    public GlyphList[] getRuns() {
        throw new UnsupportedOperationException("[TEXTLAYOUT] getRuns");
    }

    public Shape getShape(int type, TextSpan filter) {
        throw new UnsupportedOperationException("[TEXTLAYOUT]");
    }

    public boolean setTabSize(int spaces) {
        System.err.println("[TEXTLAYOUT], setTabSize ignored");
        return false;
    }

    public Hit getHitInfo(float x, float y) {
        throw new UnsupportedOperationException("[TEXTLAYOUT]");
    }

    public PathElement[] getCaretShape(int offset, boolean isLeading,
                                       float x, float y) {
        throw new UnsupportedOperationException("[TEXTLAYOUT]");
    }

    public PathElement[] getRange(int start, int end, int type,
                                  float x, float y) {
        throw new UnsupportedOperationException("[TEXTLAYOUT]");
    }
}
