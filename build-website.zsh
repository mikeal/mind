#!/usr/bin/env zsh

## THIS SCRIPT PRESUMES ./build-ebook.sh HAS BEEN RUN FIRST
## without it, the build.md file will not exist and the script will fail

# Function to extract the first header from a markdown file
extract_title() {
    local input_file=$1
    # Use grep to find the first header (line starting with '#' or '##'), then use sed to remove the leading '# ' or '## '.
    local title=$(grep -m 1 "^#\{1,2\} " "$input_file" | sed 's/^#\{1,2\} //')
    echo "$title"
}

# Function to convert markdown files to HTML
convert_md_to_html() {
    local input_file=$1
    local output_file=$2
    local css_file=$3

    local title=$(extract_title "$input_file")

    if [[ -z "$css_file" ]]; then
        if [[ "$input_file" == "README.md" || "$input_file" == "build.md" ]]; then
            css_file="site.css"
        else
            local depth=$(echo "$output_file" | awk -F'/' '{print NF-1}')
            css_file=$(printf '../%.0s' $(seq 1 $depth))site.css
        fi
    fi

    # Enable markdown extensions and generate table of contents
    pandoc "$input_file" -o "$output_file" \
        --css="$css_file" \
        --toc \
        --highlight-style=pygments \
        --section-divs \
        --metadata title="$title" \
        --template=./template.html \
        --from=markdown+footnotes+hard_line_breaks+smart+pipe_tables+fenced_code_blocks
}

# Convert all markdown files in sutras directory to HTML
for md_file in $(find sutras -name '*.md'); do
    html_file="website/${md_file%.md}.html"
    mkdir -p $(dirname "$html_file")
    convert_md_to_html "$md_file" "$html_file"
done

# Convert README.md to index.html with additional metadata
convert_md_to_html "README.md" "website/index.html"

# Prepend header to build.md and convert it to single-page-book.html
tmp_file="build_tmp.md"
echo "# Mind [A Manual] - Single Page Book" | cat - build.md > "$tmp_file"
convert_md_to_html "$tmp_file" "website/book.html" "site.css"
rm "$tmp_file"

# Function to extract TOC from an HTML file
extract_toc() {
    local input_file=$1
    local toc=$(sed -n '/<nav id="TOC"/,/<\/nav>/p' "$input_file")
    echo "$toc"
}

# Extract TOC from book.html
toc=$(extract_toc "website/book.html")

# Function to replace TOC in index.html
replace_toc() {
    local input_file=$1
    local new_toc=$2

    # Remove the existing TOC
    sed -i '/<nav id="TOC"/,/<\/nav>/d' "$input_file"

    # Insert the new TOC
    sed -i "/<body>/a$new_toc" "$input_file"
}

# Replace TOC in index.html
replace_toc "website/index.html" "$toc"

cleanup_toc_placeholder() {
    local input_file=$1
    sed -i '/<p>\[TOC\]<\/p>/d' "$input_file"
}

cleanup_toc_placeholder "website/index.html"
cleanup_toc_placeholder "website/book.html"

echo "Website generation complete!"
