/*
 * Copyright (c) 2013, 2017, Oracle and/or its affiliates. All rights reserved.
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

#include "config.h"
#include <wtf/java/JavaEnv.h>

using namespace WebCore;

extern "C" {

// This has been removed from the CSS OM, so we're just keeping this around to not crash.

// Attributes
JNIEXPORT jstring JNICALL Java_com_sun_webkit_dom_CSSCharsetRuleImpl_getEncodingImpl(JNIEnv* env, jclass clazz, jlong peer)
{
    return nullptr;
}

JNIEXPORT void JNICALL Java_com_sun_webkit_dom_CSSCharsetRuleImpl_setEncodingImpl(JNIEnv* env, jclass clazz, jlong peer, jstring value)
{
}

}