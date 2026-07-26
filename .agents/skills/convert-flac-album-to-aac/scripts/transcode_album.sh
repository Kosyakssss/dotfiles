#!/bin/sh

set -eu

usage() {
    printf '%s\n' \
        "Usage: $0 SOURCE_DIR OUTPUT_DIR COVER_FILE ALBUM_ARTIST ALBUM RELEASE_DATE GENRE [TRACK_METADATA_JSON]" >&2
    exit 2
}

[ "$#" -eq 7 ] || [ "$#" -eq 8 ] || usage

source_dir=$1
output_dir=$2
cover_file=$3
album_artist=$4
album=$5
release_date=$6
genre=$7
track_metadata_json=${8-}

for command_name in ffmpeg ffprobe jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    }
done

[ -d "$source_dir" ] || {
    printf 'Source directory does not exist: %s\n' "$source_dir" >&2
    exit 1
}

[ -f "$cover_file" ] || {
    printf 'Cover file does not exist: %s\n' "$cover_file" >&2
    exit 1
}

if [ -n "$track_metadata_json" ]; then
    [ -f "$track_metadata_json" ] || {
        printf 'Track metadata file does not exist: %s\n' "$track_metadata_json" >&2
        exit 1
    }
    jq -e 'type == "array"' "$track_metadata_json" >/dev/null || {
        printf 'Track metadata must be a JSON array: %s\n' "$track_metadata_json" >&2
        exit 1
    }
fi

case $output_dir in
    *.tmp) ;;
    *)
        printf 'Output directory must end in .tmp: %s\n' "$output_dir" >&2
        exit 1
        ;;
esac

[ ! -e "$output_dir" ] || {
    printf 'Output path already exists: %s\n' "$output_dir" >&2
    exit 1
}

set -- "$source_dir"/*.flac "$source_dir"/*.FLAC
source_count=0
for input do
    [ -f "$input" ] && source_count=$((source_count + 1))
done

[ "$source_count" -gt 0 ] || {
    printf 'No FLAC files found in: %s\n' "$source_dir" >&2
    exit 1
}

mkdir "$output_dir"

read_tag() {
    tag_name=$1
    jq -r --arg name "$tag_name" '
        (.format.tags // {})
        | to_entries
        | map(select((.key | ascii_downcase | gsub("[ _]"; "")) == $name))
        | .[0].value // empty
    '
}

for input do
    [ -f "$input" ] || continue

    tags=$(ffprobe -v error -show_entries format_tags -of json "$input")
    if [ -n "$track_metadata_json" ]; then
        source_name=$(basename "$input")
        repaired=$(jq -c --arg source "$source_name" '
            [.[] | select(.source == $source)] |
            if length == 1 then .[0] else empty end
        ' "$track_metadata_json")
        [ -n "$repaired" ] || {
            printf 'Expected one metadata entry for: %s\n' "$source_name" >&2
            exit 1
        }
        title=$(printf '%s' "$repaired" | jq -r '.title // empty')
        artist=$(printf '%s' "$repaired" | jq -r '.artist // empty')
        track_value=$(printf '%s' "$repaired" | jq -r '.track // empty')
        composer=$(printf '%s' "$repaired" | jq -r '.composer // empty')
    else
        title=$(printf '%s' "$tags" | read_tag title)
        artist=$(printf '%s' "$tags" | read_tag artist)
        track_value=$(printf '%s' "$tags" | read_tag track)
        composer=$(printf '%s' "$tags" | read_tag composer)
    fi

    track=${track_value%%/*}
    [ -n "$title" ] || {
        printf 'Missing title tag: %s\n' "$input" >&2
        exit 1
    }
    [ -n "$artist" ] || {
        printf 'Missing artist tag: %s\n' "$input" >&2
        exit 1
    }
    case $track in
        ''|*[!0-9]*)
            printf 'Invalid track tag in %s: %s\n' "$input" "$track_value" >&2
            exit 1
            ;;
    esac

    safe_title=$(printf '%s' "$title" | sed 's,/,／,g; s,:,꞉,g')
    track_padded=$(printf '%02d' "$track")
    output=$output_dir/$track_padded' - '$safe_title.m4a

    ffmpeg -nostdin -v error \
        -i "$input" \
        -i "$cover_file" \
        -map 0:a:0 \
        -map 1:v:0 \
        -map_metadata -1 \
        -c:a aac \
        -profile:a aac_low \
        -b:a 256k \
        -c:v copy \
        -disposition:v:0 attached_pic \
        -metadata title="$title" \
        -metadata artist="$artist" \
        -metadata album_artist="$album_artist" \
        -metadata album="$album" \
        -metadata date="$release_date" \
        -metadata genre="$genre" \
        -metadata track="$track/$source_count" \
        -metadata disc="1/1" \
        -metadata composer="$composer" \
        -metadata:s:v title="Album cover" \
        -metadata:s:v comment="Cover (front)" \
        "$output"

    ffmpeg -nostdin -v error -i "$output" -map 0:a:0 -f null -
    printf 'Encoded and decoded: %s\n' "$(basename "$output")"
done

output_count=$(find "$output_dir" -maxdepth 1 -type f -name '*.m4a' | wc -l | tr -d ' ')
[ "$output_count" -eq "$source_count" ] || {
    printf 'Track count mismatch: source=%s output=%s\n' "$source_count" "$output_count" >&2
    exit 1
}

printf 'Staged %s verified tracks in %s\n' "$output_count" "$output_dir"
