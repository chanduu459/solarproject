# Owner Dashboard Architecture

## Overview
The owner dashboard has been refactored into a well-organized, modular structure with clear separation of concerns. Each feature is maintained in its own file or directory for easy understanding and maintenance.

## Directory Structure

```
lib/screens/owner/
├── owner_dashboard.dart          # Main navigation orchestrator
├── providers/                     # State management & business logic
│   ├── dashboard_provider.dart   # Dashboard statistics & data loading
│   └── providers_exports.dart    # Barrel file for all providers
├── tabs/                         # Main screen tabs
│   ├── dashboard_tab.dart       # Dashboard overview & statistics
│   ├── workers_tab.dart         # Worker management
│   ├── customers_tab.dart       # Customer management
│   ├── jobs_tab.dart            # Job tracking & management
│   ├── issues_tab.dart          # Issue reporting & resolution
│   └── tabs_exports.dart        # Barrel file for all tabs
├── dialogs/                     # Modal dialogs & pages
│   ├── add_worker_dialog.dart  # Add new worker
│   ├── create_job_dialog.dart  # Create new job
│   ├── add_customer_page.dart  # Add new customer (full-page)
│   └── dialogs_exports.dart    # Barrel file for all dialogs
└── widgets/                     # Reusable UI components
    ├── stat_card.dart          # Statistics display card
    ├── worker_card.dart        # Worker information card
    ├── customer_card.dart      # Customer information card
    ├── quick_action_button.dart # Quick action buttons
    └── widgets_exports.dart    # Barrel file for all widgets
```

## Features by File

### Navigation & Orchestration
**`owner_dashboard.dart`**
- Main entry point for owner dashboard
- Handles tab navigation via BottomNavigationBar
- Manages user sign-out
- Loads dashboard data on initialization
- Uses the new `dashboardProvider` for state management

### State Management
**`providers/dashboard_provider.dart`**
- `DashboardState`: Holds dashboard statistics, loading state, and errors
- `DashboardNotifier`: Manages loading of all dashboard data
- `dashboardProvider`: Riverpod provider for accessing dashboard state
- Methods:
  - `loadDashboardData()`: Load all statistics and related data
  - `_loadStatistics()`: Fetch job, attendance, and issue statistics
  - `refresh()`: Manually refresh dashboard data

### Tabs (Feature Screens)
Each tab is a complete, self-contained feature screen:

**`tabs/dashboard_tab.dart`**
- Displays overview statistics with stat cards
- Shows quick action buttons for common tasks
- Lists recent activity
- Responsive to statistics loading state

**`tabs/workers_tab.dart`**
- Lists all workers
- Shows worker details and status
- Allows worker management (add, edit, delete)
- Displays worker activity and attendance

**`tabs/customers_tab.dart`**
- Manages customer database
- View/edit customer information
- Track customer jobs and history
- Add new customers via dialog

**`tabs/jobs_tab.dart`**
- Displays all jobs with status
- Filter jobs by status or date
- Assign workers to jobs
- Track job progress and completion
- View job details and images

**`tabs/issues_tab.dart`**
- Lists all reported issues
- Filter by priority or status
- View issue details with images
- Manage issue resolution workflow

### Dialogs & Pages
Separate files for modal interactions:

**`dialogs/add_worker_dialog.dart`**
- Form to add new workers
- Validate input data
- Submit to database

**`dialogs/create_job_dialog.dart`**
- Form to create new jobs
- Select customer and worker
- Set schedule and details

**`dialogs/add_customer_page.dart`**
- Full-page form for adding customers
- Enter address, location, contact info
- Validate and save customer data

### Reusable Widgets
Shared UI components used across tabs:

**`widgets/stat_card.dart`**
- Displays a statistic with title and value
- Used for job count, workers active, completion rate, etc.

**`widgets/worker_card.dart`**
- Shows worker information
- Displays name, status, active jobs
- Quick actions (call, message, assign)

**`widgets/customer_card.dart`**
- Shows customer information
- Displays contact details and address
- Quick actions (call, create job)

**`widgets/quick_action_button.dart`**
- Large button for quick actions
- Icon + label + action callback
- Used in dashboard for common tasks

## Import Pattern

### Using Barrel Files (Recommended)
```dart
import 'tabs/tabs_exports.dart';           // All tabs
import 'dialogs/dialogs_exports.dart';     // All dialogs
import 'widgets/widgets_exports.dart';     // All widgets
import 'providers/providers_exports.dart'; // All providers
```

### Direct Imports (If needed)
```dart
import 'tabs/dashboard_tab.dart';
import 'dialogs/add_worker_dialog.dart';
import 'widgets/stat_card.dart';
import 'providers/dashboard_provider.dart';
```

## Data Flow

1. **Initialization**: `owner_dashboard.dart` loads on app start
2. **Dashboard Provider**: Calls `loadDashboardData()` on mount
3. **Statistics Loading**: Fetches data from services (JobService, AttendanceService, IssueReportService)
4. **Tab Display**: Selected tab receives statistics and displays them
5. **User Actions**: Dialogs open for data entry or management
6. **Data Updates**: Changes are saved to Supabase and provider state is updated
7. **UI Refresh**: Affected tabs refresh to show updated data

## Adding New Features

To add a new feature to the owner dashboard:

1. **Create a new tab** in `tabs/` directory
   - Extend from `StatelessWidget` or `ConsumerWidget`
   - Import data from `dashboardProvider` or create feature-specific providers
   - Use widgets from `widgets/` directory

2. **Create a dialog** (if needed) in `dialogs/` directory
   - Handle form input and validation
   - Call appropriate service methods

3. **Add reusable widgets** in `widgets/` directory
   - Keep widgets small and focused
   - Accept data and callbacks as parameters

4. **Update barrel files** to export new components
   - Add export to relevant `_exports.dart` file

5. **Update navigation** in `owner_dashboard.dart`
   - Add new tab to `screens` list
   - Add navigation item to `BottomNavigationBar`

## Best Practices

1. **Separation of Concerns**: Each file has a single responsibility
2. **Reusable Components**: Extract common UI into widgets directory
3. **State Management**: Use Riverpod for complex state, StatefulWidget for UI state
4. **Error Handling**: All async operations have try-catch blocks
5. **Loading States**: Show loading indicators during data fetching
6. **Type Safety**: Use strong typing throughout
7. **Documentation**: Add comments for complex logic
8. **Testing**: Each component can be tested independently

## Related Documentation

- [Image Upload Fix](../../IMAGE_UPLOAD_FIX.md) - Fixes for storing images in Supabase bucket
- [Database Schema](../../../database_schema.sql) - Owner and related tables
- [Services Documentation](../../../services/services.dart) - API layer documentation

