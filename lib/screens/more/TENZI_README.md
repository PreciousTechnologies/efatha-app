# Tenzi za Rohoni - Swahili Hymnal Feature 🎵

## Overview
A beautifully designed digital hymnal feature for the Efatha Church App, providing access to traditional Swahili Christian hymns.

## Features

### 🎯 Core Functionality
- **30 Sample Hymns** - Popular Swahili hymns with lyrics
- **Smart Search** - Search by hymn number, title, or lyrics content
- **Category Filtering** - Filter by worship theme (Praise, Prayer, Thanksgiving, etc.)
- **Favorites** - Save your favorite hymns for quick access
- **Recent Hymns** - Auto-tracks last 20 hymns viewed
- **Quick Jump** - Jump directly to any hymn by number

### 🎨 Enhanced UI/UX
- **Beautiful Gradient Header** - Purple gradient matching app theme
- **Tab Navigation** - Three tabs: All Hymns, Favorites, Recent
- **Category Chips** - Horizontal scrolling category selector
- **Floating Action Button** - Quick jump to hymn number
- **Card Design** - Modern card-based hymn list with gradients
- **Responsive Search** - Real-time search with clear button
- **Detail View** - Full-screen hymn view with lyrics display

### 📚 Categories
1. All (Default view)
2. Praise & Worship
3. Prayer
4. Thanksgiving
5. Salvation
6. Holy Spirit
7. Faith
8. Love
9. Christmas
10. Easter

## File Structure

```
lib/screens/more/
  ├── tenzi_screen.dart          # Main hymnal screen
  └── more_screen.dart           # Navigation integration

assets/data/
  └── tenzi.json                 # Hymn database (30 hymns)
```

## Data Structure

Each hymn contains:
```json
{
  "number": 1,
  "title": "Mungu ni Mwema",
  "category": "Praise & Worship",
  "firstLine": "Mungu ni mwema, ni mwema kweli...",
  "lyrics": "Full hymn lyrics..."
}
```

## Usage

### Navigation
Access from More screen → "Tenzi za Rohoni" menu item

### Search
- Type hymn number (e.g., "1")
- Type title keywords (e.g., "Mungu")
- Type lyrics content (e.g., "mwema")

### Favorites
- Tap heart icon on any hymn card
- View all favorites in "Favorites" tab
- Persists across app sessions

### Recent
- Automatically tracks viewed hymns
- Shows last 20 hymns in chronological order
- Quick access to recently used hymns

### Quick Jump
- Tap "Jump to #" floating button
- Enter hymn number
- Instantly navigate to that hymn

## Technical Details

### State Management
- StatefulWidget with setState
- TabController for tab navigation
- SharedPreferences for persistence

### Persistence
- Favorites stored in SharedPreferences
- Recent hymns tracked with timestamps
- Automatic save on each action

### Performance
- Lazy loading of hymn list
- Efficient search filtering
- Optimized card rendering

## Future Enhancements

### Planned Features
- [ ] Audio recordings for each hymn
- [ ] Transpose functionality for music keys
- [ ] Playlist creation
- [ ] Share hymns via social media
- [ ] Print-friendly format
- [ ] Offline mode with full database
- [ ] Multiple language versions
- [ ] Chord charts for musicians
- [ ] Hymn of the day notification
- [ ] Search history

### Content Expansion
- [ ] Add more hymns (target: 500+)
- [ ] Include tune information
- [ ] Add composer credits
- [ ] Scripture references
- [ ] Historical context

## Copyright Notice

**Important**: The current implementation includes sample hymns for demonstration purposes. For production use:

1. Obtain proper licensing for hymn content
2. Contact copyright holders for permissions
3. Include proper attribution
4. Consider public domain hymns
5. Consult legal counsel for copyright compliance

## Dependencies

```yaml
shared_preferences: ^2.2.2  # For favorites & recent persistence
```

## Color Scheme

Primary Purple: `#6B4CE6` to `#9B7FED`
- Matches app's main theme
- Used in headers, buttons, and accents
- Gradient effects throughout

## Accessibility

- High contrast text
- Large touch targets (minimum 48x48)
- Clear visual hierarchy
- Readable font sizes (14-28pt)
- Icon + text labels

## Testing Checklist

- [x] Search functionality
- [x] Category filtering
- [x] Favorites persistence
- [x] Recent tracking
- [x] Quick jump dialog
- [x] Tab navigation
- [x] Card interactions
- [x] Detail view
- [ ] Audio playback (future)
- [ ] Share functionality (future)

## Known Limitations

1. Sample data only (30 hymns)
2. No audio functionality yet
3. No offline full database
4. Copyright considerations for real content
5. No print functionality yet

## Credits

Built for Efatha Church App by GitHub Copilot
Design inspired by modern hymnal apps
Swahili hymn content requires proper licensing

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Maintainer**: Efatha Church Development Team
