/*
 * Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
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
package jfx.incubator.scene.control.richtext.skin;

import jfx.incubator.scene.control.richtext.model.ContentChange;

import java.util.function.Consumer;

/**
 * Defines the mapping between visible row indices and model paragraph indices.
 * <p>A "row" is the index of a paragraph in the visible sequence: hidden paragraphs do not occupy a row.
 * When there are no hidden paragraphs (by default), row indices and model indices are identical.</p>
 * <p>The RichTextArea uses the RowMap to determine the mapping between model indices that traverse the document,
 * and view rows, which are the paragraphs rendered in the viewport. While the model is based on the document,
 * the view is a filtered representation of the model. Therefore, subclasses can implement custom mapping logic
 * and achieve features like:</p>
 * <ul>
 *     <li>Search/filter mode, showing only paragraphs with results</li>
 *     <li>Log/console, filtering out paragraphs based on log levels</li>
 *     <li>Outline/summary mode, showing headings and hiding details</li>
 *     <li>Code folding in the {@code CodeArea}</li>
 *     <li>Collapsible sections</li>
 *     <li>Any other custom mapping logic to show and hide paragraphs</li>
 * </ul>
 * <p>In all cases, since the model doesn't change, applying or removing the filter is a fast operation,
 * as the model doesn't need to be recreated. In other words, {@link RowMap} plays a role for {@code RichTextArea}
 * and {@code CodeArea} similar to {@code FilteredList} for {@code ListView}.</p>
 * <p>As the model can change at any time, notifications are sent via {@link #onContentChange(ContentChange)}
 * so the view can be updated properly.</p>
 * <p>Hidden paragraphs shouldn't have the caret, and it is possible to hide all the paragraphs, in
 * which case a placeholder could be shown.</p>
 */
public class RowMap {

    private Consumer<Boolean> onChange;

    /**
     * Creates a new RowMap instance.
     */
    public RowMap() {

    }

    /**
     * Returns the number of visible rows in the view, given the number of paragraphs in the model.
     * @param modelParagraphCount the number of paragraphs in the model
     * @return the number of visible rows in the view
     */
    public int getRowCount(int modelParagraphCount) {
        return modelParagraphCount;
    }

    /**
     * Returns the model index of the paragraph at the given row in the view.
     * @param row the row index in the view
     * @return the model index of the paragraph at the given row
     */
    public int getModelIndex(int row) {
        return row;
    }

    /**
     * Returns the number of visible paragraphs preceding the given model index.
     * For a visible paragraph, this is its view row index. For a hidden paragraph, this is the
     * view row index of the next visible paragraph.
     * @param modelIndex the model index of the paragraph
     * @return the view row index of the paragraph at the given model index
     */
    public int getViewRow(int modelIndex) {
        return modelIndex;
    }

    /**
     * Returns whether the paragraph at the given model index is hidden.
     * @param modelIndex the model index of the paragraph
     * @return true if the paragraph is hidden, false otherwise
     */
    public boolean isHidden(int modelIndex) {
        return false;
    }

    /**
     * Called when the content of the model changes.
     * @param ch the content change
     */
    public void onContentChange(ContentChange ch) {
        // No-op
    }

    /**
     * Notifies the owning flow that the mapping has changed, and the view should be updated
     * by requesting a layout pass. The {@code clearCache} parameter indicates whether the cache should be cleared.
     * <p>Implementations should update their internal state before calling this method.</p>
     * @param clearCache whether to clear the cache of the owning flow
     */
    protected final void notifyChange(boolean clearCache) {
        if (onChange != null) {
            onChange.accept(clearCache);
        }
    }

    /**
     * Disposes of any resources held by this RowMap. Subclasses can override this method to perform
     * cleanup when the RowMap is no longer needed.
     */
    protected void dispose() {
        // no-op
    }

    /**
     * Installed by the owning flow to receive notifications when the mapping changes.
     * @param onChange the callback to be invoked when the mapping changes
     */
    final void setOnChange(Consumer<Boolean> onChange) {
        this.onChange = onChange;
    }
}
