# Design Context

## Register

product

## Design Direction

Stash uses the Sugarbuzz `theme-stash` palette from `/Users/patrick/Code/github/patrickhoydar/sugarbuzzdesigns/custom-apps-design-system/color-options`: terracotta and deep teal on warm stone neutrals. The mood is warm, sturdy, and labeled, with a physical storeroom feel: kraft paper, bin labels, marker ink, and clean QR tags.

## Palette

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| Canvas | `#FAF8F4` | `#1A1612` | App background |
| Canvas inset | `#F0EBE3` | `#100D0A` | Grouped/inset backgrounds |
| Surface | `#FFFFFF` | `#221E18` | Cards, list rows, sheets |
| Surface hover | `#F0EBE3` | `#2C2620` | Pressed secondary controls |
| Surface selected | `#E4DDD0` | `#38312A` | Selected rows, neutral badges |
| Text primary | `#1F1B16` | `#F5EFE6` | Main content |
| Text secondary | `#524A3D` | `#B5A993` | Supporting content |
| Text tertiary | `#7C7261` | `#847A6A` | Metadata and low-emphasis icons |
| Text placeholder | `#ADA290` | `#5C5446` | Placeholder and disabled text |
| Border | `#E4DDD0` | `#2C2620` | Default hairline |
| Border strong | `#C5BBA8` | `#463E33` | Emphasis and selected borders |
| Border subtle | `#EFE9DE` | `#221E18` | In-card dividers |
| Primary accent | `#C2410C` | `#FB923C` | Main actions, active tint, QR/storage affordances |
| Primary pressed | `#7A2808` | `#EA580C` | Pressed primary buttons |
| Primary soft | `#FBE4D5` | `#2D1B0F` | Accent badges, selected label slots |
| Primary ink | `#FFFFFF` | `#1A1612` | Text/icons on primary accent |
| Support accent | `#0F766E` | `#2DD4BF` | Review states, secondary highlights |
| Support soft | `#CCFBF1` | `#0E2926` | Support badges |
| Positive | `#4D7C0F` | `#A3E635` | Keep/success states |
| Positive soft | `#E8F2D8` | `#1A2A09` | Keep/success badges |

## Typography

Use native iOS system typography through SwiftUI. Keep the visual weight aligned with Sugarbuzz: semibold for screen titles and row titles, medium for buttons and chips, regular for body text. Use tabular-looking numeric treatment where SwiftUI provides it naturally for counts and dates; avoid decorative display type inside dense app surfaces.

## Components

- Cards: 8px radius, solid surface fill, 1px border, no decorative shadows by default.
- Buttons: 6px radius, 44px minimum touch target, primary actions use the terracotta accent.
- Chips and tags: compact capsules, fixed-size single-line text, soft accent fills.
- Lists: grouped, scan-friendly rows with strong titles, quiet metadata, and stable thumbnail dimensions.
- QR labels: keep print output black on white for scan reliability, independent of app theme.

## Interaction

Use native SwiftUI motion and controls unless there is a clear product reason to customize. Prioritize legibility while scanning bins or using the app one-handed. Avoid decorative gradients, glow, bokeh, glass cards, emoji, mascots, and oversized marketing-style hero layouts.

## Implementation Notes

The SwiftUI token mirror lives in `Stash/Design/SugarbuzzTheme.swift`. Existing token names such as `sbBuzz` remain as code-level aliases, but their values are the Stash palette.
