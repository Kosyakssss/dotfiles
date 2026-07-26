---
name: convert-flac-album-to-aac
description: Clean up downloaded FLAC albums and convert them to verified AAC-LC M4A albums in the user's Music AAC library. Use when Codex needs to identify a downloaded lossless album, repair or complete its metadata and cover art to match the existing library, transcode it through a temporary directory, validate every output track, and finalize the album without deleting the source.
---

# Convert a FLAC album to AAC

Create a clean, consistent album in `${HOME}/Music AAC`. Treat metadata repair and verification as required parts of conversion.

## Inspect

1. Locate the exact downloaded album. Prefer read-only inspection of recently modified directories under `${HOME}/Soulseek Downloads` and `${HOME}/Downloads`.
2. Require lossless source audio. Do not transcode MP3, AAC, or another lossy source.
3. Inspect every FLAC file with `ffprobe`. Record titles, artists, featured artists, album artist, album, release date, track and disc positions, genre, composer, identifiers, duration, sample rate, and embedded artwork.
4. Sample finished albums in `${HOME}/Music AAC` to confirm current naming and tag conventions. Do not assume old conventions remain current.
5. Check whether the intended final directory or its `.tmp` directory exists. Never overwrite either without explicit user direction.

## Repair metadata

Use reliable release-specific evidence. Prefer MusicBrainz release identifiers already present in the source, Cover Art Archive, official artist or label data, and major music services. Cross-check uncertain credits or release variants.

Normalize the output to these conventions:

- Directory: `Album Artist - Album`
- File: zero-padded track number, ` - `, title, `.m4a`
- Codec: AAC-LC in an M4A container
- Audio target: 256 kb/s
- Required tags: title, track artist, album artist, album, verified release date, library-consistent genre, `track/total`, and `disc/total`
- Preserve reliable featured-artist and composer credits.
- Use the canonical artist spelling and script used by the release.
- Prefer a correct square front cover of at least 1000×1000. Do not upscale a poor source image when a reliable original is available.

Do not copy broken tags merely because they exist. Do not invent missing facts. Report unresolved ambiguity before encoding when it would change the release, track list, or credits.

## Stage and encode

Create the album as `Album Artist - Album.tmp`. Keep cover downloads inside that temporary directory or in a runtime temporary directory.

Run:

```sh
scripts/transcode_album.sh \
  SOURCE_DIR \
  TEMP_OUTPUT_DIR \
  COVER_FILE \
  ALBUM_ARTIST \
  ALBUM \
  RELEASE_DATE \
  GENRE \
  TRACK_METADATA_JSON
```

Omit `TRACK_METADATA_JSON` when all source title, artist, track, and composer tags are already correct. When any are missing or wrong, create a JSON array without modifying the FLAC files:

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

Include one entry for every source track. Use an empty string for a verified absent composer.

The script refuses an existing output directory, writes core tags explicitly, applies repaired per-track data when provided, embeds the cover, and decodes each completed audio stream.

## Validate and finalize

Before renaming the temporary directory:

1. Confirm the source and output track counts match.
2. Decode every output audio stream with FFmpeg and require no errors.
3. Compare each source/output duration; allow at most 0.10 seconds difference.
4. Require one AAC audio stream with profile `LC`.
5. Require one attached cover stream with the expected dimensions.
6. Check every required tag, featured artist, composer when applicable, track total, disc total, and filename.
7. Confirm the directory contains only intended `.m4a` files after removing temporary cover material.
8. Rename the `.tmp` directory to its final name only after all checks pass.
9. Recheck the final path and track count.

Keep the original FLAC album intact. Never delete it as part of this workflow.

Report the final path, track count, album size, repaired metadata, validation result, and source status.
