package com.sun.javafx.text;

import com.sun.javafx.scene.text.TextLayoutFactory;

public class WebTextLayoutFactory implements TextLayoutFactory {

    /* Same strategy as GlyphLayout */
    private static final WebTextLayout reusableTL = new WebTextLayout();
    private static boolean inUse;

    private WebTextLayoutFactory() {
    }

    public com.sun.javafx.scene.text.TextLayout createLayout() {
        return new WebTextLayout();
    }

    public com.sun.javafx.scene.text.TextLayout getLayout() {
        if (inUse) {
            return new WebTextLayout();
        } else {
            synchronized(WebTextLayoutFactory.class) {
                if (inUse) {
                    return new WebTextLayout();
                } else {
                    inUse = true;
                    reusableTL.setAlignment(0);
                    reusableTL.setWrapWidth(0);
                    reusableTL.setDirection(0);
                    reusableTL.setContent(null);
                    return reusableTL;
                }
            }
        }
    }

    public void disposeLayout(com.sun.javafx.scene.text.TextLayout layout) {
        if (layout == reusableTL) {
            inUse = false;
        }
    }

    private static final WebTextLayoutFactory factory = new WebTextLayoutFactory();
    public static WebTextLayoutFactory getFactory() {
        return factory;
    }
}
