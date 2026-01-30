# Quick Start Guide - TogoSchool UI Components

## 🚀 Quick Reference for New Professional Components

### Import Required Packages

```dart
// For Professional Cards
import 'package:togoschool/components/professional_card.dart';

// For Modern Buttons
import 'package:togoschool/components/modern_button.dart';

// For Modern AppBar
import 'package:togoschool/components/modern_app_bar.dart';

// For Theme
import 'package:togoschool/core/theme/app_theme.dart';
```

## 📦 Component Cheat Sheet

### 1. StatsCard
**Purpose**: Display key metrics with icon and value

```dart
StatsCard(
  icon: Icons.book,           // Required
  title: "Courses",           // Required
  value: "12",                // Required
  color: AppTheme.primaryColor, // Required
  onTap: () {},               // Optional
)
```

### 2. ProgressCard
**Purpose**: Show progress with percentage bar

```dart
ProgressCard(
  title: "Mathematics",       // Required
  subtitle: "Chapter 3",      // Required
  progress: 0.75,             // Required (0.0 to 1.0)
  progressColor: Colors.blue, // Optional
  icon: Icons.school,         // Optional
)
```

### 3. ProfessionalCard
**Purpose**: Container with modern styling

```dart
ProfessionalCard(
  child: Text('Content'),     // Required
  padding: EdgeInsets.all(16), // Optional
  margin: EdgeInsets.all(8),   // Optional
  onTap: () {},               // Optional
  elevation: 10,              // Optional
  borderRadius: 16,           // Optional
)
```

### 4. ShimmerCard
**Purpose**: Loading skeleton with animation

```dart
ShimmerCard(
  height: 100,                // Optional
  width: double.infinity,     // Optional
  borderRadius: 16,           // Optional
)
```

### 5. ModernButton
**Purpose**: Primary action button

```dart
ModernButton(
  text: "Submit",             // Required
  onPressed: () {},           // Required
  isLoading: false,           // Optional
  icon: Icons.send,           // Optional
  backgroundColor: Colors.blue, // Optional
  outlined: false,            // Optional (for outlined style)
)
```

### 6. ModernIconButton
**Purpose**: Icon-only button

```dart
ModernIconButton(
  icon: Icons.favorite,       // Required
  onPressed: () {},           // Required
  backgroundColor: Colors.red, // Optional
  iconColor: Colors.white,    // Optional
  size: 48,                   // Optional
  tooltip: "Favorite",        // Optional
)
```

### 7. ModernAppBar
**Purpose**: Clean app bar

```dart
ModernAppBar(
  title: "My Page",           // Required
  actions: [                  // Optional
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () {},
    ),
  ],
  centerTitle: true,          // Optional
)
```

### 8. GradientAppBar
**Purpose**: App bar with gradient

```dart
GradientAppBar(
  title: "Dashboard",         // Required
  gradient: LinearGradient(   // Optional
    colors: [Colors.blue, Colors.purple],
  ),
)
```

## 🎨 Color Constants

```dart
// Primary Colors
AppTheme.primaryColor       // #6366F1 (Indigo)
AppTheme.secondaryColor     // #8B5CF6 (Purple)
AppTheme.accentColor        // #EC4899 (Pink)

// Status Colors
AppTheme.successColor       // #10B981 (Green)
AppTheme.warningColor       // #F59E0B (Amber)
AppTheme.errorColor         // #EF4444 (Red)

// Background Colors
AppTheme.backgroundColor    // #F8FAFC (Light Gray)
AppTheme.surfaceColor       // #FFFFFF (White)
AppTheme.cardColor          // #FFFFFF (White)
```

## 📏 Spacing Constants

```dart
AppSpacing.xs    // 4px
AppSpacing.sm    // 8px
AppSpacing.md    // 16px
AppSpacing.lg    // 24px
AppSpacing.xl    // 32px
AppSpacing.xxl   // 48px
```

## 🔧 Common Patterns

### Pattern 1: Stats Grid

```dart
GridView.count(
  crossAxisCount: 3,
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  mainAxisSpacing: 16,
  crossAxisSpacing: 16,
  childAspectRatio: 0.85,
  children: [
    StatsCard(
      icon: Icons.book,
      title: "Courses",
      value: "12",
      color: AppTheme.primaryColor,
      onTap: () => navigateToCourses(),
    ),
    // Add more cards...
  ],
)
```

### Pattern 2: Loading State

```dart
Widget build(BuildContext context) {
  return isLoading
    ? GridView.count(
        crossAxisCount: 2,
        children: List.generate(
          4,
          (index) => ShimmerCard(height: 120),
        ),
      )
    : GridView.count(
        crossAxisCount: 2,
        children: dataCards,
      );
}
```

### Pattern 3: Form with Button

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: InputDecoration(
          labelText: "Name",
          prefixIcon: Icon(Icons.person),
        ),
      ),
      SizedBox(height: AppSpacing.md),
      ModernButton(
        text: "Save",
        isLoading: _isSaving,
        onPressed: _handleSave,
      ),
    ],
  ),
)
```

### Pattern 4: Card List

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ProfessionalCard(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ListTile(
        leading: Icon(Icons.article),
        title: Text(items[index].title),
        subtitle: Text(items[index].subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () => handleTap(items[index]),
      ),
    );
  },
)
```

### Pattern 5: Progress List

```dart
ListView.builder(
  itemCount: courses.length,
  itemBuilder: (context, index) {
    return ProgressCard(
      title: courses[index].name,
      subtitle: "Chapter ${courses[index].chapter}",
      progress: courses[index].progress / 100,
      progressColor: AppTheme.successColor,
      icon: Icons.book_outlined,
    );
  },
)
```

## 💡 Pro Tips

### 1. Consistent Padding
```dart
// Use AppSpacing constants
Padding(
  padding: EdgeInsets.all(AppSpacing.md),
  child: ...
)
```

### 2. Theme Colors
```dart
// Use theme colors instead of hardcoding
Container(
  color: Theme.of(context).primaryColor,
  // or
  color: AppTheme.primaryColor,
)
```

### 3. Responsive Design
```dart
// Use MediaQuery for responsive layouts
final screenWidth = MediaQuery.of(context).size.width;
final crossAxisCount = screenWidth > 600 ? 4 : 3;

GridView.count(
  crossAxisCount: crossAxisCount,
  // ...
)
```

### 4. Dark Mode Support
```dart
// Check theme brightness
final isDark = Theme.of(context).brightness == Brightness.dark;

Container(
  color: isDark ? Colors.grey[800] : Colors.white,
  // ...
)
```

### 5. Animations
```dart
// Use AnimatedContainer for smooth transitions
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  height: isExpanded ? 200 : 100,
  // ...
)
```

## ⚠️ Common Mistakes to Avoid

1. ❌ Don't hardcode colors
   ```dart
   // Bad
   color: Color(0xFF6366F1)
   
   // Good
   color: AppTheme.primaryColor
   ```

2. ❌ Don't hardcode spacing
   ```dart
   // Bad
   padding: EdgeInsets.all(16)
   
   // Good
   padding: EdgeInsets.all(AppSpacing.md)
   ```

3. ❌ Don't forget loading states
   ```dart
   // Bad
   ElevatedButton(
     onPressed: handleSubmit,
     child: Text("Submit"),
   )
   
   // Good
   ModernButton(
     text: "Submit",
     isLoading: isSubmitting,
     onPressed: handleSubmit,
   )
   ```

4. ❌ Don't create custom cards from scratch
   ```dart
   // Bad - reinventing the wheel
   Container(
     decoration: BoxDecoration(
       color: Colors.white,
       borderRadius: BorderRadius.circular(16),
       boxShadow: [...],
     ),
     // ...
   )
   
   // Good - use existing component
   ProfessionalCard(
     child: ...
   )
   ```

## 📚 Learn More

- Check [IMPROVEMENTS_SUMMARY.md](./IMPROVEMENTS_SUMMARY.md) for detailed changes
- See [GUIDE_AMELIORATIONS_FR.md](./GUIDE_AMELIORATIONS_FR.md) for French guide
- Explore component files in `lib/components/` for more options

---

**Happy Coding! 🚀**
