package com.sun.javafx.sg.web;

public class Fridge {

    public static String createHTMLElement() {
System.out.println("[FRIDGE] creating html element");
        String uuid = createBckElement("div");
        return uuid;
    }

    public static void createTextElement(String id) {
System.out.println("[FRIDGE] creating text element");
        createBckTextElement(id);
    }

    public static void setInnerText(String id, String text) {
System.out.println("[FRIDGE] set innertext for " + id+ " to " + text);
        setBckInnerText(id, text);
    }

    public static void setGeometry(String id, float layoutX, float layoutY) {
        setDivLeft(id, layoutX);
        setDivTop(id, layoutY);
    }



    private static native String createBckElement(String tag);
    private static native void createBckTextElement(String id);
    private static native void setBckInnerText(String id, String text);
    private static native void setDivLeft(String id, float left);
    private static native void setDivTop(String id, float top);


}
