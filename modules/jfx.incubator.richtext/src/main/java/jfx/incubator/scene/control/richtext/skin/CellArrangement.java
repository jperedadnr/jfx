/*
 * Copyright (c) 2022, 2026, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */
// This code borrows heavily from the following project, with permission from the author:
// https://github.com/andy-goryachev/FxEditor

package jfx.incubator.scene.control.richtext.skin;

import java.util.ArrayList;
import javafx.collections.ObservableList;
import javafx.geometry.Point2D;
import javafx.scene.Node;
import javafx.scene.layout.Pane;
import javafx.scene.layout.Region;
import javafx.scene.shape.PathElement;
import javafx.scene.text.HitInfo;
import javafx.scene.text.TextFlow;
import jfx.incubator.scene.control.richtext.TextPos;

/**
 * Manages TextCells in a sliding window, comprised of the visible area and some number of screenfuls
 * before and after the visible area, for the purposes of layout.
 * The purpose is to estimating the average paragraph height, and to support relative navigation.
 * <p>
 * Uses {@code Vflow.content} coordinates.
 */
public class CellArrangement {
    private final ArrayList<TextCell> cells = new ArrayList<>(32);
    private final double flowWidth;
    private final double flowHeight;
    private final int lineCount;
    private final double contentPaddingTop; // snapped
    private final double contentPaddingBottom; // snapped
    private final Origin origin;
    private final RowMap rowMap;
    private final int originRow;
    private final int rowCount;
    private int visibleCount;
    private int bottomCount;
    private double unwrappedWidth;
    private double topHeight;
    private double bottomHeight;
    private Node[] left;
    private Node[] right;

    /**
     * Creates a new CellArrangement instance.
     * @param f the VFlow
     * @param contentPaddingTop the top content padding, in pixels
     * @param contentPaddingBottom the bottom content padding, in pixels
     * @param rowMap the RowMap
     */
    public CellArrangement(VFlow f, double contentPaddingTop, double contentPaddingBottom, RowMap rowMap) {
        this.flowWidth = f.getWidth();
        this.flowHeight = f.getViewPortHeight();
        this.origin = f.getOrigin();
        this.lineCount = f.getParagraphCount();
        this.rowCount = f.getRowCount();
        this.originRow = Math.min(rowMap.getViewRow(origin.index()), Math.max(0, rowCount - 1));
        this.contentPaddingTop = contentPaddingTop;
        this.contentPaddingBottom = contentPaddingBottom;
        this.rowMap = rowMap;
    }

    // TODO not called right now, use it to skip reflow when not necessary
    // (may need to include left and right content padding or a sum thereof */
    boolean isValid(VFlow f, double padLeft, double padTop) {
        return
            (f.getWidth() == flowWidth) &&
            (f.getHeight() == flowHeight) &&
            (f.topCellIndex() == origin.index()) &&
            (contentPaddingTop == padTop) &&
            (contentPaddingBottom == contentPaddingBottom);
    }

    @Override
    public String toString() {
        return
            "CellArrangement{" +
            "origin=" + origin +
            ", topCount=" + topCount() +
            ", bottomCount=" + bottomCount +
            ", visible=" + getVisibleCellCount() +
            ", topHeight=" + topHeight +
            ", bottomHeight=" + bottomHeight +
            ", lineCount=" + lineCount +
            ", rowCount=" + rowCount +
            ", average=" + averageHeight() +
            ", unwrapped=" + getUnwrappedWidth() +
            "}";
    }

    void addCell(TextCell cell) {
        cells.add(cell);
    }

    void setUnwrappedWidth(double w) {
        unwrappedWidth = w;
    }

    /**
     * returns snapped(ceil) size
     * @return the unwrapped width of the text flow, in pixels
     */
    public double getUnwrappedWidth() {
        return unwrappedWidth;
    }

    /**
     * returns the number of visible cells in the arrangement
     * @return the number of visible cells in the arrangement
     */
    public int getVisibleCellCount() {
        return visibleCount;
    }

    void setVisibleCellCount(int n) {
        visibleCount = n;
    }

    /**
     * finds text position inside the sliding window, in cell coordinates
     * @param cellX the x coordinate within the cell
     * @param cellY the y coordinate within the cell
     * @return the text position
     */
    public TextPos getTextPos(double cellX, double cellY) {
        if (lineCount == 0) {
            return TextPos.ZERO;
        }

        int topIx = topIndex();
        int btmIx = bottomIndex();

        int ix = binarySearch(cellY, topIx, btmIx - 1);
        TextCell cell = getCellForRow(ix);
        if (cell != null) {
            Region r = cell.getContent();
            double y = cellY - cell.getY() - r.snappedTopInset();
            if (y < 0) {
                return TextPos.ofLeading(cell.getIndex(), 0);
            } else if (y < cell.getCellHeight()) {
                if (r instanceof TextFlow f) {
                    Point2D p = new Point2D(cellX - r.getLayoutX(), y - r.getLayoutY());
                    HitInfo h = f.getHitInfo(p);
                    return toTextPos(cell, h.getInsertionIndex(), h.getCharIndex(), h.isLeading());
                } else {
                    return TextPos.ofLeading(cell.getIndex(), 0);
                }
            }

            int cix = 0;
            if (r instanceof TextFlow) {
                // the cell's text length, which may exclude view-only decorations added by subclasses
                cix = cell.getTextLength();
            }
            return TextPos.ofLeading(cell.getIndex(), cix);
        }

        return TextPos.ZERO;
    }

    /**
     * Converts a text flow hit within the given cell to a {@code TextPos}.
     * <p>
     * The subclasses may override this method to remap hits on view-only decorations
     * (text flow indexes past the cell's own text) to their real document positions.
     *
     * @param cell the hit cell
     * @param insertionIndex the insertion index within the cell's text flow
     * @param charIndex the character index within the cell's text flow
     * @param leading whether the hit is on the leading edge of the character
     * @return the text position
     */
    protected TextPos toTextPos(TextCell cell, int insertionIndex, int charIndex, boolean leading) {
        return new TextPos(cell.getIndex(), insertionIndex, charIndex, leading);
    }

    /**
     * Creates a {@code CaretInfo} instance from the given caret path.
     * <p>
     * The subclasses may use this method to build the caret geometry for positions
     * they resolve themselves, for example on view-only decorations.
     *
     * @param lineSpacing the line spacing
     * @param path the caret path, must not be empty
     * @return the CaretInfo instance
     */
    protected final CaretInfo createCaretInfo(double lineSpacing, PathElement[] path) {
        return CaretInfo.create(lineSpacing, path);
    }

    /**
     * returns the cell contained in this layout, or null
     * @param modelIndex the model index of the cell
     * @return the cell contained in this layout, or null
     */
    public TextCell getCell(int modelIndex) {
        if (rowMap.isHidden(modelIndex)) {
            return null;
        }
        return getCellForRow(rowMap.getViewRow(modelIndex));
    }

    /**
     * Returns the cell at the given view row contained in this layout, or null
     * @param row the view row
     * @return the cell at the given view row contained in this layout, or null
     */
    protected TextCell getCellForRow(int row) {
        int ix = row - originRow;
        if (ix < 0) {
            if ((ix + topCount()) >= 0) {
                // cells in the top part come after bottom part, and in reverse order
                return cells.get(bottomCount - ix - 1);
            }
        } else if (ix < bottomCount) {
            // cells in the normal (bottom) part
            return cells.get(ix);
        }
        return null;
    }

    /**
     * returns a visible cell, or null
     * @param modelIndex the model index of the cell
     * @return a visible cell, or null
     */
    public TextCell getVisibleCell(int modelIndex) {
        if (rowMap.isHidden(modelIndex)) {
            return null;
        }
        int row = rowMap.getViewRow(modelIndex);
        int ix = row - originRow;
        if ((ix >= 0) && (ix < visibleCount)) {
            return cells.get(ix);
        }
        return null;
    }

    /**
     * returns a TextCell from the visible or bottom margin parts, or null
     * @param ix the index of the cell
     * @return a TextCell from the visible or bottom margin parts, or null
     */
    public TextCell getCellAt(int ix) {
        if (ix < visibleCount) {
            return cells.get(ix);
        }
        return null;
    }

    /**
     * Creates a CaretInfo.
     * @param target the target region (vflow.content)
     * @param p the text position
     * @return the new CaretInfo
     */
    public CaretInfo getCaretInfo(Region target, TextPos p) {
        if (p != null) {
            int ix = p.index();
            TextCell cell = getCell(ix);
            if (cell != null) {
                int charIndex = p.charIndex();
                boolean leading = p.isLeading();
                PathElement[] path = cell.getCaretShape(target, charIndex, leading);
                if (path != null) {
                    double lineSpacing = cell.getLineSpacing();
                    return CaretInfo.create(lineSpacing, path);
                }
            }
        }
        return null;
    }

    void removeNodesFrom(Pane p) {
        ObservableList<Node> cs = p.getChildren();
        for (int i = getVisibleCellCount() - 1; i >= 0; --i) {
            TextCell cell = cells.get(i);
            cs.remove(cell);
        }
    }

    void setBottomCount(int ix) {
        bottomCount = ix;
    }

    /**
     * returns the bottom margin cells
     * @return the number of bottom margin cells
     */
    public int bottomCount() {
        return bottomCount;
    }

    /**
     * returns the number of cells in the arrangement
     * @return the number of cells in the arrangement
     */
    public int cellCount() {
        return cells.size();
    }

    void setBottomHeight(double h) {
        bottomHeight = h;
    }

    /**
     * returns the bottom height in pixels from the first visible cell to the last cell in the arrangement
     * @return the bottom height in pixels from the first visible cell to the last cell in the arrangement
     */
    public double bottomHeight() {
        return bottomHeight;
    }

    /**
     * returns the number of top margin cells
     * @return the number of top margin cells
     */
    public int topCount() {
        return cells.size() - bottomCount;
    }

    void setTopHeight(double h) {
        topHeight = h;
    }

    /**
     * returns the top height in pixels
     * @return the top height in pixels
     */
    public double topHeight() {
        return topHeight;
    }

    double averageHeight() {
        int sz = cells.size();
        if (sz == 0) {
            return 20; // any reasonable non-zero number would work
        }
        return (topHeight + bottomHeight) / sz;
    }

    double estimatedMax() {
        return (rowCount - topCount() - bottomCount) * averageHeight() + topHeight + bottomHeight;
    }

    /**
     * finds a model index of a cell that contains the given localY.
     * (in vflow frame of reference).
     * Should not be called with localY outside of this layout sliding window.
     */
    private int binarySearch(double localY, int low, int high) {
        while (low <= high) {
            int mid = (low + high) >>> 1;
            TextCell cell = getCellForRow(mid);
            int cmp = compare(cell, localY);
            if (cmp < 0) {
                low = mid + 1;
            } else if (cmp > 0) {
                high = mid - 1;
            } else {
                return mid;
            }
        }
        return low;
    }

    private int compare(TextCell cell, double localY) {
        double y = cell.getY();
        if (localY < y) {
            return 1;
        } else if (localY >= y + cell.getCellHeight()) {
            if (rowMap.getViewRow(cell.getIndex()) == (rowCount - 1)) {
                return 0;
            }
            return -1;
        }
        return 0;
    }

    /**
     * returns a row index of the first cell in the sliding window top margin
     * @return a row index of the first cell in the sliding window top margin
     */
    public int topIndex() {
        return originRow - topCount();
    }

    /**
     * returns a row index of the last cell in the sliding window bottom margin + 1
     * @return a row index of the last cell in the sliding window bottom margin + 1
     */
    public int bottomIndex() {
        return originRow + bottomCount;
    }

    /**
     * returns the new origin after scrolling for delta pixels within the arrangement
     * @param delta the number of pixels to scroll
     * @return the new origin after scrolling for delta pixels within the arrangement
     */
    Origin moveOrigin(double delta) {
        int topIx = topIndex();
        int btmIx = bottomIndex();
        double y = delta;

        if (delta > 0) {
            // do not scroll beyond the bottom edge
            double max = bottomHeight - flowHeight;
            if (max < 0) {
                return null;
            }
            if (y > max) {
                y = max;
            }
        }

        int ix = binarySearch(y, topIx, btmIx - 1);
        TextCell cell = getCellForRow(ix);
        double off = y - cell.getY();

        // do not scroll beyond the top edge
        if (delta < 0) {
            if (ix == 0) {
                off = Math.max(off, -contentPaddingTop);
            }
        }

        return new Origin(cell.getIndex(), off);
    }

    void addLeftNode(int index, Node n) {
        if (left == null) {
            left = new Node[visibleCount];
        }
        left[index] = n;
    }

    void addRightNode(int index, Node n) {
        if (right == null) {
            right = new Node[visibleCount];
        }
        right[index] = n;
    }

    Node getLeftNodeAt(int index) {
        return left[index];
    }

    Node getRightNodeAt(int index) {
        return right[index];
    }

    /**
     * last cell at the bottom of the arrangement
     * @return the last cell at the bottom of the arrangement
     */
    private TextCell lastBottomCell() {
        if (bottomCount == 0) {
            return null;
        }
        return cells.get(bottomCount - 1);
    }
}
