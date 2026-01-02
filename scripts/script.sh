#!/bin/bash

log_jscl_file="java_jslc_files.txt"
log_base_java_file="base_java_files.txt"
log_graphics_java_file="graphics_java_files.txt"
log_decora_graphics_java_file="decora_graphics_java_files.txt"
log_prism_graphics_java_file="prism_graphics_java_files.txt"
log_metal_graphics_java_file="metal_graphics_java_files.txt"

# Detect OS and set path separator
if [[ $OSTYPE == 'cygwin' || $OSTYPE == 'msys' ]]; then
    PATH_SEP=";"
    IS_WINDOWS=true
else
    PATH_SEP=":"
    IS_WINDOWS=false
fi

# Convert Unix path to Windows path for javac
to_native_path() {
    local result
    if [ "$IS_WINDOWS" = true ]; then
        result=$(cygpath -w "$1" 2>/dev/null || echo "$1")
        # Escape backslashes for echo -e
        echo "${result//\\/\\\\}"
    else
        echo "$1"
    fi
}

# Batch convert paths (more efficient for multiple files)
batch_to_native_paths() {
    if [ "$IS_WINDOWS" = true ]; then
        while IFS= read -r line; do
            local result=$(cygpath -w "$line" 2>/dev/null || echo "$line")
            echo "${result//\\/\\\\}"
        done
    else
        cat
    fi
}

# Convert path but keep forward slashes (for module-source-path patterns)
to_mixed_path() {
    if [ "$IS_WINDOWS" = true ]; then
        cygpath -m "$1" 2>/dev/null || echo "$1"
    else
        echo "$1"
    fi
}

echo "=== Cleaning build directories ==="
rm -rf files
mkdir files

cd ..
root_path=$PWD
aux_files=$root_path/scripts/files

# ========== javafx.base module ==========
echo "=== Building javafx.base module ==="
cd $root_path/modules/javafx.base || exit
> "$aux_files/$log_base_java_file"
base_path=$PWD
rm -rf $base_path/build/

# :base:processVersionInfo
echo "Processing version info..."
# Generate VersionInfo.java from template
mkdir -p "$base_path/build/gensrc/java/com/sun/javafx/runtime"
cp $base_path/src/main/version-info/VersionInfo.java "$base_path/build/gensrc/java/com/sun/javafx/runtime"
# :base:compileJava
# Compile all Java sources in javafx.base
echo "Compiling Java sources..."
printf "%s\n" "--release" "24" "-Werror" "-Xlint:removal" "-Xlint:missing-explicit-ctor" "-implicit:none" "-d" "$(to_native_path "$base_path/build/classes/java/main")" "-encoding" "UTF-8" >> "$aux_files/$log_base_java_file"
printf "%s\n" "--module-source-path" "$(to_mixed_path "$root_path")/modules/*/src/main/java${PATH_SEP}$(to_mixed_path "$root_path")/modules/*/build/gensrc/{java,jsl-decora,jsl-prism}" >> "$aux_files/$log_base_java_file"
directory=$base_path/src/main/java
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_base_java_file"
directory="$base_path/build/gensrc/java/com/sun/javafx/runtime"
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_base_java_file"
javac @"$aux_files/$log_base_java_file"

# ========== javafx.graphics module ==========
cd $root_path/modules/javafx.graphics || exit
graphics_path=$PWD
rm -rf $graphics_path/build/

echo "=== Building javafx.graphics module ==="
# :graphics:compileJava
# Compile all Java sources in javafx.graphics
echo "Compiling Java sources..."
> "$aux_files/$log_graphics_java_file"
printf "%s\n" "--release" "24" "-Werror" "-Xlint:removal" "-Xlint:missing-explicit-ctor" "-implicit:none" "-d" "$(to_native_path "$graphics_path/build/classes/java/main")" "-encoding" "UTF-8" >> "$aux_files/$log_graphics_java_file"
printf "%s\n" "--module-source-path" "$(to_mixed_path "$root_path")/modules/*/src/main/java${PATH_SEP}$(to_mixed_path "$root_path")/modules/*/build/gensrc/{java,jsl-decora,jsl-prism}" >> "$aux_files/$log_graphics_java_file"
printf "%s\n" "--module-path" "$(to_native_path "$base_path/build/classes/java/main/javafx.base")" >> "$aux_files/$log_graphics_java_file"
printf "%s\n" "--add-modules=javafx.base" >> "$aux_files/$log_graphics_java_file"
directory=$graphics_path/src/main/java
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_graphics_java_file"
javac @"$aux_files/$log_graphics_java_file"

# :graphics:generateGrammarSource
# Download ANTLR parser generator
echo "Downloading ANTLR if needed..."
antlr_jar=antlr-4.13.2-complete.jar
antlr_url=https://www.antlr.org/download/$antlr_jar
if [ ! -f "$aux_files/$antlr_jar" ]; then
    echo "  Downloading ANTLR..."
    if command -v wget &> /dev/null; then
        wget -nv -O "$aux_files/$antlr_jar" $antlr_url
    elif command -v curl &> /dev/null; then
        curl -L -o "$aux_files/$antlr_jar" $antlr_url
    else
        echo "Error: Neither wget nor curl found. Please install one or download $antlr_url manually."
        exit 1
    fi
fi
antlr_file=$aux_files/$antlr_jar

# Generate parser from JSL grammar
echo "Generating grammar sources..."
cd src/jslc/antlr || exit
java -cp $antlr_file org.antlr.v4.Tool -o $graphics_path/build/gensrc/antlr -package com.sun.scenario.effect.compiler -visitor com/sun/scenario/effect/compiler/JSL.g4
cd ../../..

# :graphics:compileJslcJava
# Compile the JSL compiler itself
echo "Compiling JSLC compiler..."
> "$aux_files/$log_jscl_file"
printf "%s\n" "--release" "24" "-nowarn" "-d" "$(to_native_path "$graphics_path/build/classes/java/jslc")" "-encoding" "UTF-8" "-cp" "$(to_native_path "$antlr_file")" >> "$aux_files/$log_jscl_file"
directory=$graphics_path/src/jslc/java
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_jscl_file"
directory=$graphics_path/build/gensrc/antlr
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_jscl_file"
javac @"$aux_files/$log_jscl_file"

# :graphics:compileDecoraCompilers
# Compile Decora effect compilers
echo "Compiling Decora shader compilers..."
> "$aux_files/$log_decora_graphics_java_file"
printf "%s\n" "--release" "24" "-nowarn" "-implicit:none" "-d" "$(to_native_path "$graphics_path/build/classes/jsl-compilers/decora")" "-encoding" "UTF-8" >> "$aux_files/$log_decora_graphics_java_file"
printf "%s\n" "-cp" "$(to_native_path "$graphics_path/build/classes/java/jslc")${PATH_SEP}$(to_native_path "$antlr_file")" >> "$aux_files/$log_decora_graphics_java_file"
printf "%s\n" "--module-path" "$(to_native_path "$base_path/build/classes/java/main")${PATH_SEP}$(to_native_path "$graphics_path/build/classes/java/main")" >> "$aux_files/$log_decora_graphics_java_file"
printf "%s\n" "--add-modules=javafx.graphics" "--add-exports=javafx.graphics/com.sun.scenario.effect=ALL-UNNAMED" "--add-exports=javafx.graphics/com.sun.scenario.effect.light=ALL-UNNAMED" "--add-exports=javafx.graphics/com.sun.scenario.effect.impl.state=ALL-UNNAMED" >> "$aux_files/$log_decora_graphics_java_file"
directory=$graphics_path/src/main/jsl-decora
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_decora_graphics_java_file"
javac @"$aux_files/$log_decora_graphics_java_file"

# :graphics:generateDecoraShaders
# Generate Decora effect shaders (GLSL, HLSL, Metal)
echo "Generating Decora shaders..."
mkdir -p $graphics_path/build/gensrc/mtl-headers
java --module-path=$base_path/build/classes/java/main${PATH_SEP}$graphics_path/build/classes/java/main \
    --add-modules=javafx.graphics --add-exports=javafx.graphics/com.sun.scenario.effect=ALL-UNNAMED --add-exports=javafx.graphics/com.sun.scenario.effect.light=ALL-UNNAMED --add-exports=javafx.graphics/com.sun.scenario.effect.impl.state=ALL-UNNAMED \
    -cp $base_path/build/classes/java/main${PATH_SEP}$antlr_file${PATH_SEP}$graphics_path/build/classes/java/jslc${PATH_SEP}$graphics_path/src/jslc/resources${PATH_SEP}$graphics_path/build/classes/jsl-compilers/decora${PATH_SEP}$graphics_path/src/main/jsl-decora \
    -Dfile.encoding=UTF-8 \
    GenAllDecoraShaders -i $graphics_path/src/main/jsl-decora -o $graphics_path/build/gensrc/jsl-decora -t -pkg com/sun/scenario/effect -all GenAllDecoraShaders

if [[ $OSTYPE == 'darwin'* ]] ; then
  # :graphics:compileDecoraMSLShaders
  mkdir -p $graphics_path/build/msl/Decora/com/sun/scenario/effect/impl/hw/mtl/msl
  for FILE in $graphics_path/build/gensrc/jsl-decora/com/sun/scenario/effect/impl/hw/mtl/msl/*.metal; do
    xcrun -sdk macosx metal -Wdeprecated -std=macos-metal2.4 -I $graphics_path/build/gensrc/mtl-headers -c $FILE -o "$graphics_path/build/msl/Decora/com/sun/scenario/effect/impl/hw/mtl/msl/$(basename "$FILE" .metal).air"
  done
fi

if [[ $OSTYPE == 'cygwin' || $OSTYPE == 'msys' ]] ; then
    # :graphics:compileDecoraHLSLShaders
    # Compile HLSL shaders for DirectX (requires FXC.exe)
    echo "Processing Decora HLSL shaders..."
    mkdir -p $graphics_path/build/hlsl/Decora/com/sun/scenario/effect/impl/hw/d3d/hlsl
    for FILE in $graphics_path/build/gensrc/jsl-decora/com/sun/scenario/effect/impl/hw/d3d/hlsl/*.hlsl; do
      echo $FILE
      # FXC /nologo /T ps_3_0 /Fo "$graphics_path/build/hlsl/Decora/com/sun/scenario/effect/impl/hw/d3d/hlsl/$(basename "$FILE" .hlsl).obj" $FILE
    done

    # :graphics:processDecoraShaders (Windows - copy .obj files)
    find $graphics_path/build/hlsl/Decora/ -name "*.obj" | while read file; do
        rel_path="${file#$graphics_path/build/hlsl/Decora/}"
        target_dir="$graphics_path/build/classes/java/main/javafx.graphics/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/"
    done
fi

# :graphics:processDecoraShaders (copy .frag files)
# Copy GLSL fragment shaders to output
echo "Copying Decora fragment shaders..."
mkdir -p $graphics_path/build/classes/java/main/javafx.graphics
find $graphics_path/build/gensrc/jsl-decora/ -name "*.frag" | while read file; do
    rel_path="${file#$graphics_path/build/gensrc/jsl-decora/}"
    target_dir="$graphics_path/build/classes/java/main/javafx.graphics/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    cp "$file" "$target_dir/"
done

# :graphics:compilePrismCompilers
# Compile Prism rendering pipeline compilers
echo "Compiling Prism shader compilers..."
> "$aux_files/$log_prism_graphics_java_file"
printf "%s\n" "--release" "24" "-nowarn" "-implicit:none" "-d" "$(to_native_path "$graphics_path/build/classes/jsl-compilers/prism")" "-encoding" "UTF-8" >> "$aux_files/$log_prism_graphics_java_file"
printf "%s\n" "-cp" "$(to_native_path "$graphics_path/build/classes/java/jslc")${PATH_SEP}$(to_native_path "$antlr_file")" >> "$aux_files/$log_prism_graphics_java_file"
printf "%s\n" "--module-path" "$(to_native_path "$base_path/build/classes/java/main")${PATH_SEP}$(to_native_path "$graphics_path/build/classes/java/main")" >> "$aux_files/$log_prism_graphics_java_file"
printf "%s\n" "--add-modules=javafx.graphics" "--add-exports=javafx.graphics/com.sun.scenario.effect=ALL-UNNAMED" "--add-exports=javafx.graphics/com.sun.scenario.effect.light=ALL-UNNAMED" "--add-exports=javafx.graphics/com.sun.scenario.effect.impl.state=ALL-UNNAMED" >> "$aux_files/$log_prism_graphics_java_file"
directory=$graphics_path/src/main/jsl-prism
find "$directory" -type f -name "*.java" -not -name ".DS_Store" | batch_to_native_paths >> "$aux_files/$log_prism_graphics_java_file"
javac @"$aux_files/$log_prism_graphics_java_file"

# :graphics:generatePrismShaders
# Generate Prism rendering shaders from JSL files
echo "Generating Prism shaders..."
for FILE in $graphics_path/src/main/jsl-prism/*.jsl; do
    java --module-path=$base_path/build/classes/java/main${PATH_SEP}$graphics_path/build/classes/java/main \
      --add-modules=javafx.graphics \
      -cp $base_path/build/classes/java/main${PATH_SEP}$antlr_file${PATH_SEP}$graphics_path/build/classes/java/jslc${PATH_SEP}$graphics_path/src/jslc/resources${PATH_SEP}$graphics_path/build/classes/jsl-compilers/prism${PATH_SEP}$graphics_path/src/main/jsl-prism  \
      -Dfile.encoding=UTF-8 \
      CompileJSL -i $graphics_path/src/main/jsl-prism -o $graphics_path/build/gensrc/jsl-prism -t -pkg com/sun/prism -d3d -es2 -mtl -name $FILE
done

if [[ $OSTYPE == 'darwin'* ]] ; then
  # :graphics:compilePrismMSLShaders
  # Compile Prism MSL shaders for DirectX
  echo "Processing Prism MSL shaders..."
  mkdir -p $graphics_path/build/msl/Prism/com/sun/prism/mtl/msl
  for FILE in $graphics_path/build/gensrc/jsl-prism/com/sun/prism/mtl/msl/*.metal; do
    xcrun -sdk macosx metal -Wdeprecated -std=macos-metal2.4 -I $graphics_path/build/gensrc/mtl-headers -c $FILE -o "$graphics_path/build/msl/Prism/com/sun/prism/mtl/msl/$(basename "$FILE" .metal).air"
  done
fi

if [[ $OSTYPE == 'cygwin' || $OSTYPE == 'msys' ]] ; then
    # :graphics:compilePrismHLSLShaders
    # Compile Prism HLSL shaders for DirectX
    echo "Processing Prism HLSL shaders..."
    mkdir -p $graphics_path/build/hlsl/Prism/com/sun/prism/d3d/hlsl
    for FILE in $graphics_path/build/gensrc/jsl-prism/com/sun/prism/d3d/hlsl/*.hlsl; do
      echo $FILE
      # FXC /nologo /T ps_3_0 /Fo "$graphics_path/build/hlsl/Prism/com/sun/prism/d3d/hlsl/$(basename "$FILE" .hlsl).obj" $FILE
    done

    # :graphics:processPrismShaders (Windows - copy .obj files)
    find $graphics_path/build/hlsl/Prism/ -name "*.obj" | while read file; do
        rel_path="${file#$graphics_path/build/hlsl/Prism/}"
        target_dir="$graphics_path/build/classes/java/main/javafx.graphics/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/"
    done
fi

# :graphics:processPrismShaders (copy .frag files)
# Copy GLSL fragment shaders to output
echo "Copying Prism fragment shaders..."
find $graphics_path/build/gensrc/jsl-prism/ -name "*.frag" | while read file; do
    rel_path="${file#$graphics_path/build/gensrc/jsl-prism/}"
    target_dir="$graphics_path/build/classes/java/main/javafx.graphics/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    cp "$file" "$target_dir/"
done

if [[ $OSTYPE == 'darwin'* ]] ; then
  # :graphics:compileMetalShaders
  # Compile Metal shaders
  echo "Compile Metal shaders..."
    for FILE in $graphics_path/src/main/native-prism-mtl/msl/*.metal; do
      xcrun -sdk macosx metal -std=macos-metal2.4 -c $FILE -o "$graphics_path/build/msl/$(basename "$FILE" .metal).air"
    done

  # :graphics:linkMSLShader
  # Link Metal shaders
  echo "Compile Metal shaders..."
  mkdir -p $graphics_path/build/msl/com/sun/prism/mtl/msl
  xcrun -sdk macosx metallib $(find "$graphics_path/build/msl" -type f -name "*.air" -not -name ".DS_Store") -o $graphics_path/build/msl/com/sun/prism/mtl/msl/jfxshaders.metallib
fi

echo "=== Build complete! ==="