---
name: convert-flac-album-to-aac
description: Convert a downloaded FLAC album to a clean AAC-LC M4A album in the user's Music AAC library, repairing metadata and artwork when needed.
---

# Convert a FLAC album to AAC

Convert a lossless album into `${HOME}/Music AAC` without changing or deleting the source.

## Prepare

1. Find the intended album under `${HOME}/Soulseek Downloads` or `${HOME}/Downloads` and confirm that its audio files are FLAC.
2. Inspect its tags, track order, disc structure, and artwork. Check existing albums in `${HOME}/Music AAC` only when needed to resolve a naming or tagging convention.
3. Research metadata only when it is missing, contradictory, or suspicious. Prefer release identifiers in the source, MusicBrainz, Cover Art Archive, and official artist or label sources. Ask before proceeding if uncertainty would change the release, track list, or credits.
4. Use a reliable square front cover, preferably at least 1000×1000. Do not upscale poor artwork when a better source is available.

Use these output conventions:

- Directory: `Album Artist - Album`
- File: `01 - Title.m4a`
- Audio: AAC-LC at 256 kb/s in an M4A container
- Tags: title, artist, album artist, album, release date, genre, track total, and disc total
- Preserve verified featured-artist and composer credits.

Do not overwrite an existing final or `.tmp` directory.

## Convert

Stage the album as `Album Artist - Album.tmp` and run:

```sh
scripts/transcode_album.sh \
  SOURCE_DIR TEMP_OUTPUT_DIR COVER_FILE \
  ALBUM_ARTIST ALBUM RELEASE_DATE GENRE [TRACK_METADATA_JSON]
```

Omit the JSON file when source title, artist, track, and composer tags are correct. Otherwise provide one entry per source file:

```json
[
  {
    "source": "01 Example.flac",
    "track": 1,
    "title": "Example",
    "artist": "Artist feat. Guest",
    "composer": "Composer"
  }
]
```

Use an empty composer only when its absence is verified. The helper refuses an existing output directory, writes the supplied metadata and cover, encodes each track, decodes each result, and checks the track count.

The helper supports single-disc albums only. For a multi-disc release, stop rather than writing incorrect track and disc totals.

## Finish

Before renaming the staged directory, use `ffprobe` to verify:

- source and output counts match;
- every output has AAC-LC audio and the intended cover;
- durations differ by no more than 0.10 seconds;
- filenames and required tags are correct;
- the directory contains only the intended M4A files.

Rename the directory only after all checks pass. Report the final path, track count, repaired metadata, validation result, and that the source remains intact.
