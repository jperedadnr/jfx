/*
 * Copyright (c) 2026, Oracle and/or its affiliates.
 * All rights reserved. Use is subject to license terms.
 *
 * This file is available and licensed under the following license:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the distribution.
 *  - Neither the name of Oracle Corporation nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.oracle.demo.richtext.headings;

import javafx.collections.SetChangeListener;
import javafx.event.Event;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.control.ScrollBar;
import javafx.scene.control.Tooltip;
import javafx.scene.layout.BorderPane;
import jfx.incubator.scene.control.richtext.TextPos;
import jfx.incubator.scene.control.richtext.model.RichParagraph;
import jfx.incubator.scene.control.richtext.skin.RowMap;
import jfx.incubator.scene.control.richtext.skin.TextCell;
import jfx.incubator.scene.control.richtext.skin.VFlow;

public class HeadingsVFlow extends VFlow {
    private static final String COLLAPSED = "\u25B8"; // ▸
    private static final String EXPANDED = "\u25BE"; // ▾

    private final HeadingsRTA control;
    private final SetChangeListener<ParagraphRange> collapsedSectionsListener = this::handleCollapsedSectionsChange;
    private HeadingsRowMap rowMap;

    public HeadingsVFlow(HeadingsRTASkin skin, ScrollBar vScrollBar, ScrollBar hScrollBar) {
        super(skin, vScrollBar, hScrollBar);
        control = (HeadingsRTA) getControl();
        control.getCollapsedSections().addListener(collapsedSectionsListener);
    }

    @Override
    protected RowMap createRowMap() {
        rowMap = new HeadingsRowMap(control);
        return rowMap;
    }

    @Override
    protected void dispose() {
        control.getCollapsedSections().removeListener(collapsedSectionsListener);
        super.dispose();
    }

    @Override
    protected TextCell createTextCell(int index, RichParagraph par, double defaultInterval) {
        TextCell cell = super.createTextCell(index, par, defaultInterval);
        if (cell != null) {
            ParagraphRange section = control.getSection(index);
            if (section != null) {
                addChevron(cell, section);
            }
        }
        return cell;
    }

    private void addChevron(TextCell cell, ParagraphRange section) {
        boolean collapsed = control.isSectionCollapsed(section);

        Label chevron = new Label(collapsed ? COLLAPSED : EXPANDED);
        chevron.getStyleClass().add("section-chevron");
        chevron.setTooltip(new Tooltip(collapsed ? "Expand this section" : "Collapse this section"));
        if (collapsed) {
            chevron.setVisible(true);
        } else {
            chevron.visibleProperty().bind(cell.hoverProperty());
        }
        chevron.setOnMousePressed(Event::consume);
        chevron.setOnMouseClicked(event -> {
            event.consume();
            control.toggleSection(section);
        });

        BorderPane.setAlignment(chevron, Pos.TOP_RIGHT);
        cell.setRight(chevron);
    }

    private void handleCollapsedSectionsChange(SetChangeListener.Change<? extends ParagraphRange> change) {
        if (change.wasAdded()) {
            moveCaretOutOfSection(change.getElementAdded());
        }
        rowMap.invalidate();
        rowMapUpdated(true);
    }

    private void moveCaretOutOfSection(ParagraphRange section) {
        TextPos p = control.getCaretPosition();
        if (p == null) {
            return;
        }
        if (section.contains(p.index())) {
            control.select(control.getParagraphEnd(section.start()));
        }
    }
}