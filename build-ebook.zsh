#!/usr/bin/env zsh

# Function to concatenate all files
concat_files() {
    local output_file=$1
    echo "# Build Information" > $output_file
    echo "" >> $output_file
    echo "- **Build Type**: $BUILD_TYPE" >> $output_file
    echo "- **Date**: $PUBDATE" >> $output_file
    echo "- **Commit Hash**: $GIT_COMMIT" >> $output_file
    echo "\n\n This ebook and its build process are open source and [available on GitHub](https://github.com/mikeal/mind)." >> $output_file
    echo "" >> $output_file

    cat \
        ./README.md \
        ./six-doors/README.md \
        ./six-doors/00-Beginning.md \
        ./six-doors/01-Dhyana.md \
        ./six-doors/02-Sequence.md \
        ./sutras/README.md \
        ./sutras/T0124_001.md \
        ./sutras/Vikalpa-Yoga.md \
    >> $output_file
}

# Set metadata variables
AUTHORS="Mikeal Rogers, M. C. Owens, Zhìyǐ, Xuanzang, Buddha"
TITLE="Mind - A Manual"
TAGS="Mediation, Mediation Manual, Buddhism, Mind, Mind-Only, Dharma"
PUBLISHER="Free Dharma"
PUBDATE=$(date +%Y-%m-%d)  # Set current date dynamically
LANGUAGE="en"

# Get the current git commit hash
GIT_COMMIT=$(git rev-parse --short HEAD)

# Check if we are in GitHub Actions environment
if [[ -n $GITHUB_ACTIONS ]]; then
    BUILD_TYPE="autobuild"
else
    BUILD_TYPE="localbuild"
fi

BUILD_INFO="$BUILD_TYPE $PUBDATE $GIT_COMMIT"

# Conversion options
MARKDOWN_EXTENSIONS="footnotes,tables,codehilite,meta,nl2br,smarty,sane_lists,wikilinks,fenced_code,toc"
PAGE_BREAKS_BEFORE="//h:h1"

# Define the concatenated markdown file
OUTPUT_FILE="build.md"

# Define the temporary cover image
TMP_COVER_IMAGE="tmp_cover.jpg"

CSS="./book.css"
FONT_FAMILY="FiraGO"
BASE_COVER_IMAGE="./images/cover.jpg"

# Create a new cover image with overlaid text
convert $BASE_COVER_IMAGE -font FiraGO-Book -gravity NorthEast -pointsize 24 -fill white -annotate +10+10 "$BUILD_INFO" $TMP_COVER_IMAGE

# Concatenate the files with build info
concat_files $OUTPUT_FILE

# Convert txt to markdown using ebook-convert with specified options
ebook-convert "$OUTPUT_FILE" "mind.epub" \
--authors "$AUTHORS" \
--title "$TITLE" \
--tags "$TAGS" \
--extra-css $CSS \
--publisher "$PUBLISHER" \
--pubdate "$PUBDATE" \
--markdown-extensions "$MARKDOWN_EXTENSIONS" \
--embed-font-family "$FONT_FAMILY" \
--no-default-epub-cover \
--page-breaks-before "$PAGE_BREAKS_BEFORE" \
--cover "$TMP_COVER_IMAGE" \
--preserve-cover-aspect-ratio \
--preserve-spaces \
--chapter "//*[name()='h1' or name()='h2' or name()='h3']" --level1-toc "//*[name()='h1']" --level2-toc "//*[name()='h2']" --level3-toc "//*[name()='h3']" \
--pretty-print

echo "Conversion complete!"
