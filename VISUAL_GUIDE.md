# 🎨 Efatha Church App - Visual Component Guide

## Color Palette Reference

### Primary Colors (Purple - Spiritual Foundation)
```
┌─────────────────────────────────────────────────────────────┐
│ Primary Purple Deep    │ #6B46C1 │ ███████████████████████  │
│ Primary Purple Light   │ #8B5CF6 │ ███████████████████████  │
│ Primary Purple Vibrant │ #7C3AED │ ███████████████████████  │
└─────────────────────────────────────────────────────────────┘

Usage: Primary buttons, active states, FAB, gradients
```

### Accent Colors (Blue - Trust & Communication)
```
┌─────────────────────────────────────────────────────────────┐
│ Accent Blue Brand      │ #2196F3 │ ███████████████████████  │
│ Accent Blue Google     │ #4285F4 │ ███████████████████████  │
│ Accent Blue Facebook   │ #1877F2 │ ███████████████████████  │
│ Accent Blue Info       │ #3B82F6 │ ███████████████████████  │
│ Accent Teal            │ #0891B2 │ ███████████████████████  │
└─────────────────────────────────────────────────────────────┘

Usage: Auth screens, secondary actions, info badges
```

### Semantic Colors
```
┌─────────────────────────────────────────────────────────────┐
│ SUCCESS                                                      │
│ Success Green Primary  │ #10B981 │ ███████████████████████  │
│ Success Green Dark     │ #059669 │ ███████████████████████  │
│                                                              │
│ WARNING                                                      │
│ Warning Amber          │ #F59E0B │ ███████████████████████  │
│                                                              │
│ DANGER                                                       │
│ Danger Red Primary     │ #EF4444 │ ███████████████████████  │
│ Danger Red Dark        │ #DC2626 │ ███████████████████████  │
│ Danger Red Deep        │ #7C2D12 │ ███████████████████████  │
└─────────────────────────────────────────────────────────────┘

Usage: Status badges, alerts, action confirmation
```

### Neutral Colors
```
┌─────────────────────────────────────────────────────────────┐
│ BACKGROUNDS                                                  │
│ Neutral BG Lightest    │ #FFFFFF │ ███████████████████████  │
│ Neutral BG Soft        │ #F9FAFB │ ███████████████████████  │
│ Neutral BG Muted       │ #F3F4F6 │ ███████████████████████  │
│                                                              │
│ BORDERS                                                      │
│ Neutral Border Light   │ #E5E7EB │ ███████████████████████  │
│ Neutral Border Medium  │ #D1D5DB │ ███████████████████████  │
│ Neutral Border Disabled│ #E0E0E0 │ ███████████████████████  │
│                                                              │
│ TEXT                                                         │
│ Neutral Text Primary   │ #1F2937 │ ███████████████████████  │
│ Neutral Text Secondary │ #374151 │ ███████████████████████  │
│ Neutral Text Tertiary  │ #4B5563 │ ███████████████████████  │
│ Neutral Text Muted     │ #6B7280 │ ███████████████████████  │
│ Neutral Text Disabled  │ #9CA3AF │ ███████████████████████  │
│ Neutral Text Placeholder│ #999999│ ███████████████████████  │
└─────────────────────────────────────────────────────────────┘
```

## Typography Scale

```
┌──────────────────────────────────────────────────────────────┐
│ HEADLINES (Display/Hero Text)                                │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Headline XLarge    32pt / Bold (700)   🔤 Main Titles       │
│  Headline Large     28pt / Bold (700)   🔤 Section Heads     │
│  Headline Medium    24pt / Bold (700)   🔤 Screen Titles     │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ TITLES (Card Headers & Sections)                             │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Title Large        18pt / SemiBold (600)  Card Titles       │
│  Title Medium       16pt / SemiBold (600)  Subsections       │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ BODY (Content Text)                                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Body Large         16pt / Regular (400)   Main Content      │
│  Body Medium        15pt / Regular (400)   Secondary         │
│  Body Regular       14pt / Regular (400)   Standard Text     │
│  Body Medium Weight 14pt / Medium (500)    Emphasis          │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ METADATA (Supporting Info)                                   │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Metadata Large     14pt / Medium (500)   Timestamps         │
│  Metadata           13pt / Medium (500)   Labels             │
│  Metadata Small     12pt / Medium (500)   Hints              │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ BUTTONS (Call-to-Action)                                     │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Button Large       18pt / SemiBold (600)  Large Buttons     │
│  Button Medium      16pt / SemiBold (600)  Standard Buttons  │
│  Button Small       14pt / SemiBold (600)  Small Buttons     │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ BADGES (Status Indicators)                                   │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Badge Large        12pt / SemiBold (600)  Large Status      │
│  Badge              11pt / SemiBold (600)  Standard Status   │
│  Badge Small        10pt / SemiBold (600)  Small Status      │
│  (All uppercase with letter-spacing: 0.5)                    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Component Library

### AppButton Variants

```
┌───────────────────────────────────────────────────────────┐
│                     PRIMARY BUTTON                         │
│  ╔═══════════════════════════════════════════════════╗   │
│  ║           Sign In (White Text)                    ║   │
│  ╚═══════════════════════════════════════════════════╝   │
│  Background: #6B46C1 | Radius: 8px | Height: 40-48px     │
└───────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────┐
│                    SECONDARY BUTTON                        │
│  ╔═══════════════════════════════════════════════════╗   │
│  ║           Continue (White Text)                   ║   │
│  ╚═══════════════════════════════════════════════════╝   │
│  Background: #2196F3 | Radius: 8px | Height: 40-48px     │
└───────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────┐
│                     OUTLINE BUTTON                         │
│  ╔═══════════════════════════════════════════════════╗   │
│  ║           Cancel (Purple Text)                    ║   │
│  ╚═══════════════════════════════════════════════════╝   │
│  Border: #6B46C1 1.5px | Radius: 8px | BG: Transparent   │
└───────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────┐
│                      TEXT BUTTON                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │           Learn More (Purple Text)                 │   │
│  └───────────────────────────────────────────────────┘   │
│  No border | No background | Padding minimal             │
└───────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────┐
│                    LOADING BUTTON                          │
│  ╔═══════════════════════════════════════════════════╗   │
│  ║              ⟳ Loading...                        ║   │
│  ╚═══════════════════════════════════════════════════╝   │
│  Spinner replaces text | Button disabled                  │
└───────────────────────────────────────────────────────────┘
```

### AppCard Component

```
┌───────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐ │
│  │                                                       │ │
│  │  Card Title                                           │ │
│  │  Metadata text • Secondary info                       │ │
│  │                                                       │ │
│  │  Body content goes here with proper spacing          │ │
│  │  and comfortable line height.                         │ │
│  │                                                       │ │
│  └─────────────────────────────────────────────────────┘ │
│  Radius: 12px | Padding: 16px | Elevation: 4            │
└───────────────────────────────────────────────────────────┘
```

### Status Badges

```
┌──────────────────────────────────────────────────────┐
│  SUCCESS BADGE                                        │
│  ╔═══════════════╗                                   │
│  ║   APPROVED    ║  Green: #10B981 (bg: 12% opacity) │
│  ╚═══════════════╝                                   │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│  WARNING BADGE                                        │
│  ╔═══════════════╗                                   │
│  ║    PENDING    ║  Amber: #F59E0B (bg: 12% opacity) │
│  ╚═══════════════╝                                   │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│  DANGER BADGE                                         │
│  ╔═══════════════╗                                   │
│  ║     URGENT    ║  Red: #EF4444 (bg: 12% opacity)   │
│  ╚═══════════════╝                                   │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│  INFO BADGE                                           │
│  ╔═══════════════╗                                   │
│  ║      NEW      ║  Blue: #3B82F6 (bg: 12% opacity)  │
│  ╚═══════════════╝                                   │
└──────────────────────────────────────────────────────┘
```

## Screen Layouts

### Splash Screen
```
┌─────────────────────────────────────────────────┐
│                                                  │
│         ╔═══ GRADIENT BACKGROUND ═══╗          │
│         ║  Purple Deep → Vibrant    ║          │
│         ║                           ║          │
│         ║         ⬤                 ║          │
│         ║        ⛪                 ║          │
│         ║                           ║          │
│         ║       EFATHA              ║          │
│         ║   Church Community        ║          │
│         ║                           ║          │
│         ║          ⟳                ║          │
│         ╚═══════════════════════════╝          │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Login Screen
```
┌─────────────────────────────────────────────────┐
│                                                  │
│              ⬤   (Logo Circle)                  │
│                  ⛪                             │
│                                                  │
│           Welcome to Efatha                     │
│     Connect with your church community          │
│                                                  │
│  ┌─────────────────────────────────────────┐   │
│  │  Sign In                                 │   │
│  │  ┌───────────────────────────────────┐  │   │
│  │  │ 📧 Email                          │  │   │
│  │  └───────────────────────────────────┘  │   │
│  │  ┌───────────────────────────────────┐  │   │
│  │  │ 🔒 Password               👁     │  │   │
│  │  └───────────────────────────────────┘  │   │
│  │                  Forgot Password?        │   │
│  │  ╔═══════════════════════════════════╗  │   │
│  │  ║         Sign In                   ║  │   │
│  │  ╚═══════════════════════════════════╝  │   │
│  └─────────────────────────────────────────┘   │
│                                                  │
│  ────────── Or continue with ──────────        │
│  ╔════════════╗  ╔════════════╗                │
│  ║  G Google  ║  ║  f Facebook║                │
│  ╚════════════╝  ╚════════════╝                │
│                                                  │
│      Don't have an account? Sign Up             │
└─────────────────────────────────────────────────┘
```

### Home Dashboard
```
┌─────────────────────────────────────────────────┐
│  Efatha Church               🔔  👤            │
│  Welcome back!                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│  ╔═══════════════════════════════════════════╗ │
│  ║  🎯 Sunday Service                        ║ │
│  ║  Join us this Sunday at 10:00 AM         ║ │
│  ║  ╔═══════════════╗                       ║ │
│  ║  ║  Watch Live   ║                       ║ │
│  ║  ╚═══════════════╝                       ║ │
│  ╚═══════════════════════════════════════════╝ │
│                                                  │
│  Community Highlights                           │
│  ┌────────┐  ┌────────┐  ┌────────┐          │
│  │ 👥     │  │ ❤️      │  │ 📅     │          │
│  │ 1,234  │  │   89   │  │   12   │          │
│  │ Members│  │ Prayers│  │ Events │          │
│  └────────┘  └────────┘  └────────┘          │
│                                                  │
│  Upcoming Events                                │
│  ┌─────────────────────────────────────────┐   │
│  │ 📅  Youth Fellowship Meeting           │   │
│  │     Saturday, 3:00 PM                  │   │
│  └─────────────────────────────────────────┘   │
│                                                  │
│  Prayer Requests                                │
│  ┌─────────────────────────────────────────┐   │
│  │ 👤 John Doe        2 hours ago  [HIGH] │   │
│  │ Please pray for my family...            │   │
│  └─────────────────────────────────────────┘   │
│                                                  │
├─────────────────────────────────────────────────┤
│  🏠    🎙️    📅    🙏    💝                   │
│ Home Sermons Events Prayers Give              │
└─────────────────────────────────────────────────┘
                                          ⊕
```

## Spacing Guide

```
Screen Padding:        16px (horizontal)
Card Padding:         16px (all sides)
Card Margin:          8-12px (vertical)
Button Padding:       16px × 12px (h × v)
Section Spacing:      12-24px (between sections)

Border Radius:
  - Cards:            12px
  - Buttons:          8px
  - Inputs:           12px
  - Chips/Badges:     16-20px
  - Modals:           16px
```

## Icon Usage

```
Navigation Icons:     24px
Action Icons:         20-24px
Metadata Icons:       14-16px
Large Icons:          48-64px (empty states, features)
FAB Icon:             24px
```

---

**Visual Reference Complete**  
Use this guide when implementing new features to maintain consistency!
