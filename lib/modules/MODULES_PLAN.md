# Modules Implementation Roadmap

## Overview
Master implementation plan for all intervention modules using the **Hybrid Phased Approach**. This roadmap orchestrates the implementation of shared infrastructure and individual modules to maximize learning, minimize waste, and deliver working features quickly.

**Strategy:** Build essential foundation → Validate with Light → Extract proven patterns → Scale with remaining modules

**Total Duration:** ~8-10 weeks for all 7 modules

---

## 🎯 Core Principles

1. **Essential First:** Implement only what's proven necessary
2. **Validate Early:** Test patterns with real module before abstracting
3. **Extract Proven:** Move working code to shared, not theoretical code
4. **Iterate & Refine:** Each module improves shared infrastructure
5. **No Premature Abstraction:** If in doubt, wait for second use case

---

## 📅 Implementation Phases

### Phase 0: Prerequisites ✅ COMPLETED
**Status:** Done (Phase 1-5 already implemented)
- MVVM + Provider architecture
- Database infrastructure
- User management with SettingsViewModel
- Action Center (reference implementation)

**Deliverable:** Solid foundation ready for modules

---

### Phase 1: Essential Shared Foundation
**Duration:** 1 day (6 hours)
**Who:** Senior developer (you)
**Status:** 🟡 Ready to start

#### What to Implement:
Follow **SHARED_PLAN.md → Phase S.1**:
- ✅ `lib/modules/shared/domain/models/intervention_activity.dart`
- ✅ `lib/modules/shared/domain/models/user_module_config.dart`
- ✅ `lib/modules/shared/domain/models/module.dart`
- ✅ `lib/modules/shared/utils/datetime_helpers.dart`
- ✅ Update `lib/shared/constants/database_constants.dart` with shared table constants
- ✅ Run `dart run build_runner build` to generate JSON serialization

#### Why These Only:
- Every module needs base models immediately (zero guesswork)
- DateTimeHelpers used by all modules for time calculations
- Database constants required for all queries
- **No UI components yet** - wait for Light to validate

#### Validation:
- [ ] Unit tests for InterventionActivity fromDatabase/toDatabase
- [ ] Unit tests for DateTimeHelpers calculations
- [ ] All tests passing, no analyzer warnings

**Deliverable:** Shared foundation ready, modules can be built on top

---

### Phase 2: Light Module Implementation (First Validation)
**Duration:** 2 weeks (10-12 hours actual work)
**Who:** Senior developer (you)
**Status:** 🔴 Blocked by Phase 1

#### What to Implement:
Follow **LIGHT_PLAN.md** completely, with modifications:
- ✅ **Use Phase 1 foundation:** Base models, DateTimeHelpers
- ⚠️ **Implement INLINE in Light (don't extract yet):**
  - Time slider widget (will extract later)
  - Color scheme logic (will extract later)
  - Notification scheduling (will extract later)

#### Implementation Steps:
1. **Database Migration** (LIGHT_PLAN.md → Step L.1)
   - Create `migration_v5.dart` with Light-specific constraints

2. **Models** (LIGHT_PLAN.md → Steps L.2-L.3)
   - `light_config.dart` - extends UserModuleConfig pattern
   - `light_activity.dart` - extends InterventionActivity base class

3. **Repository** (LIGHT_PLAN.md → Steps L.4-L.6)
   - Interface, DataSource, Implementation

4. **ViewModel** (LIGHT_PLAN.md → Step L.7)
   - Follow Phase 5 error handling pattern

5. **Configuration Screen** (LIGHT_PLAN.md → Step L.8)
   - **Build TimeSlider inline** (custom widget in Light module)
   - **Implement color logic inline** (helper methods in Light screen)
   - Use SettingsViewModel for current user access

6. **Provider Registration** (LIGHT_PLAN.md → Step L.9)
   - Register in main.dart in correct order

7. **Testing** (LIGHT_PLAN.md → Testing Checklist)
   - Manual tests: Enable, configure, log activity, verify notifications
   - Database validation: Check encrypted data, correlations

#### Success Criteria:
- [ ] Light module fully functional
- [ ] Users can enable, configure, and log light therapy
- [ ] Notifications fire at correct times
- [ ] Activities correlate with sleep data
- [ ] TimeSlider works well (important: validates pattern)
- [ ] Color feedback helps users (important: validates approach)

**Deliverable:** Working Light module, validated UI patterns

**⚠️ Key Checkpoint:**
- If TimeSlider doesn't work well → redesign before extracting
- If color scheme confusing → refine before extracting
- **Don't extract until Light proves the patterns work!**

---

### Phase 3: Extraction to Shared (Proven Patterns)
**Duration:** 1 day (4 hours)
**Who:** Senior developer (you)
**Status:** 🔴 Blocked by Phase 2
**Trigger:** Light module working and validated

#### What to Extract:
Follow **SHARED_PLAN.md → Phase S.3**:

1. **TimeSliderWidget** (`lib/modules/shared/presentation/widgets/time_slider_widget.dart`)
   - Extract from Light's inline implementation
   - Generalize for any module (not just Light)
   - Add configuration options discovered during Light development

2. **ColorSchemeHelper** (`lib/modules/shared/utils/color_scheme_helper.dart`)
   - Extract color calculation logic from Light
   - Make pluggable (different color schemes for different modules)

3. **Optional: Notification Pattern**
   - If notification scheduling in Light is clean, extract base pattern
   - If messy, wait for Sport to validate

#### Refactor Light to Use Shared:
- Replace inline TimeSlider with `TimeSliderWidget`
- Replace inline color logic with `ColorSchemeHelper`
- Verify Light still works identically
- No functional changes, only structural

#### Success Criteria:
- [ ] Light module works identically with shared components
- [ ] TimeSliderWidget reusable (configurable, well-documented)
- [ ] ColorSchemeHelper extensible (other modules can use different schemes)
- [ ] Zero regression in Light functionality

**Deliverable:** Reusable shared components, Light refactored

---

### Phase 4: Sport Module (Validate Shared Components)
**Duration:** 2 weeks (12-14 hours actual work)
**Who:** Junior developer (guided by you) OR you
**Status:** 🔴 Blocked by Phase 3

#### What to Implement:
Follow **SPORT_PLAN.md** completely:
- ✅ **Use all shared components from Phase 3:**
  - TimeSliderWidget (with intensity-based color scheme)
  - ColorSchemeHelper (with Sport-specific colors)
  - Base models, DateTimeHelpers

- 🆕 **Sport-specific additions:**
  - Intensity validation (high/medium/low)
  - Wearable service interface (placeholder implementation)
  - Timing warnings (high-intensity >4h before bed)

#### Implementation Steps:
1. Database Migration (SPORT_PLAN.md → Step S.1)
2. Models with intensity support (SPORT_PLAN.md → Steps S.2-S.3)
3. Wearable service interface (SPORT_PLAN.md → Step S.4)
4. Repository (SPORT_PLAN.md → Step S.5)
5. ViewModel with timing validation (SPORT_PLAN.md → Step S.6)
6. Configuration screen using TimeSliderWidget (SPORT_PLAN.md → Step S.7)

#### Validation Goals:
- [ ] TimeSliderWidget works for different use case (intensity colors)
- [ ] ColorSchemeHelper extensible enough for Sport
- [ ] Shared components need refinement? → Refine them

#### Success Criteria:
- [ ] Sport module fully functional
- [ ] TimeSliderWidget proves reusable (critical validation)
- [ ] Any issues with shared components identified and fixed

**Deliverable:** Working Sport module, validated shared component reusability

**⚠️ Key Checkpoint:**
- If TimeSliderWidget doesn't fit Sport well → refactor shared component
- If ColorSchemeHelper too rigid → make more flexible
- **Fix shared components now, before 5 more modules use them!**

---

### Phase 5: Temperature Module (Dual-Type Pattern)
**Duration:** 2 weeks (12-14 hours actual work)
**Who:** Junior developer OR you
**Status:** 🔴 Blocked by Phase 4

#### What to Implement:
Follow **TEMPERATURE_PLAN.md** completely:
- ✅ **Use shared components:** TimeSliderWidget, ColorSchemeHelper, base models
- 🆕 **New pattern:** Dual-type intervention (cold vs heat)
- 🆕 **New pattern:** Type-sensitive color scheme (same time, different colors)

#### Key Features:
1. Database Migration with type validation (TEMPERATURE_PLAN.md → Step T.1)
2. Dual-type configuration model (TEMPERATURE_PLAN.md → Step T.2)
3. Type-sensitive color scheme (TEMPERATURE_PLAN.md → Step T.4)
4. Safety validation (TEMPERATURE_PLAN.md → Step T.5)

#### Potential Shared Extraction:
- If dual-type pattern clean → extract to shared for future modules
- If safety validation useful → extract validation helpers

**Deliverable:** Working Temperature module, dual-type pattern validated

---

### Phase 6: Mealtime Module (Auto-Adjustment)
**Duration:** 2 weeks (12-14 hours actual work)
**Who:** Junior developer OR you
**Status:** 🔴 Blocked by Phase 5

#### What to Implement:
Follow **MEALTIME_PLAN.md** completely:
- ✅ **Use shared components:** TimeSliderWidget, ColorSchemeHelper, base models
- 🆕 **New pattern:** Auto-adjustment based on sleep schedule changes
- 🆕 **New pattern:** Eating window overlay on time slider

#### Key Features:
1. Auto-calculation from wake/bed times (MEALTIME_PLAN.md → Step MT.2)
2. Eating window for intermittent fasting (MEALTIME_PLAN.md → Step MT.2)
3. Auto-recalculation listener (MEALTIME_PLAN.md → Step MT.5)

#### Potential Shared Extraction:
- If auto-adjustment pattern useful → extract subscription helper
- If eating window useful → extract window overlay widget

**Deliverable:** Working Mealtime module, auto-adjustment pattern validated

---

### Phase 7: Meditation Module (Content Library + Audio)
**Duration:** 2-3 weeks (16-18 hours actual work)
**Who:** Senior developer (you) - more complex
**Status:** 🔴 Blocked by Phase 6

#### What to Implement:
Follow **MEDITATION_PLAN.md** completely:
- ✅ **Use shared components:** Base models, DateTimeHelpers
- 🆕 **New pattern:** Content library (separate table)
- 🆕 **New pattern:** Audio playback integration
- 🆕 **New pattern:** Favorites and play history

#### Key Features:
1. Content library tables (MEDITATION_PLAN.md → Step M.1)
2. Audio service abstraction (MEDITATION_PLAN.md → Step M.6)
3. Player screen with controls (MEDITATION_PLAN.md → Step M.8)
4. Library browsing (MEDITATION_PLAN.md → Step M.9)

#### Potential Shared Extraction:
- If content library pattern useful → extract for Nutrition module
- If favorites pattern useful → extract favorites service

**Deliverable:** Working Meditation module, audio playback validated

---

### Phase 8: Nutrition Module (Educational Content)
**Duration:** 1-2 weeks (10-12 hours actual work)
**Who:** Junior developer
**Status:** 🔴 Blocked by Phase 7

#### What to Implement:
Follow **NUTRITION_PLAN.md** completely:
- ✅ **Use shared components:** Content library pattern (from Meditation)
- 🆕 **New pattern:** Recommendation system
- 🆕 **New pattern:** Optional food diary

#### Key Features:
1. Content library (NUTRITION_PLAN.md → Step N.1)
2. Food database (NUTRITION_PLAN.md → Step N.1)
3. Recommendation service (NUTRITION_PLAN.md → Step N.5)
4. Daily tip delivery (NUTRITION_PLAN.md → Step N.7)

**Deliverable:** Working Nutrition module, educational content delivery validated

---

### Phase 9: Journaling Module (Most Complex)
**Duration:** 3 weeks (20-22 hours actual work)
**Who:** Senior developer (you) - encryption + ML
**Status:** 🔴 Blocked by Phase 8

#### What to Implement:
Follow **JOURNALING_PLAN.md** completely:
- ✅ **Use shared components:** Base models, DateTimeHelpers
- 🆕 **New pattern:** End-to-end encryption
- 🆕 **New pattern:** ML pattern recognition
- 🆕 **New pattern:** Multiple input methods (text, voice, OCR)

#### Key Features:
1. Encryption service (JOURNALING_PLAN.md → Step J.2)
2. ML pattern service (JOURNALING_PLAN.md → Step J.5)
3. OCR service interface (JOURNALING_PLAN.md → Step J.6)
4. Multi-input entry screen (JOURNALING_PLAN.md → Step J.10)

#### Phase 1 Implementation:
- Simple keyword extraction (not complex NLP)
- OCR placeholder (manual transcription)
- Can enhance with cloud services later

**Deliverable:** Working Journaling module, encryption + simple ML validated

---

## 🎓 Junior Developer Integration

### When Juniors Can Start:
- **After Phase 3 (Extraction):** Shared components ready
- **Starting with Phase 4 (Sport):** First junior-led module

### Junior-Led Modules:
1. **Sport** (Phase 4) - Guided by you, validates shared components
2. **Temperature** (Phase 5) - Less guidance, junior more independent
3. **Mealtime** (Phase 6) - Junior fully independent
4. **Nutrition** (Phase 8) - Junior fully independent

### Senior-Led Modules:
1. **Light** (Phase 2) - Establishes patterns
2. **Meditation** (Phase 7) - Audio complexity
3. **Journaling** (Phase 9) - Encryption + ML complexity

### Parallel Work Strategy:
- **Week 3-4:** You extract to shared, Junior starts Sport planning
- **Week 5-6:** You review Sport, Junior implements Temperature
- **Week 7+:** Junior fully independent, you review PRs

---

## 📊 Timeline Summary

| Phase | Module | Duration | Who | Weeks |
|-------|--------|----------|-----|-------|
| 1 | Shared Foundation | 6h | Senior | Week 1 |
| 2 | Light | 12h | Senior | Week 1-2 |
| 3 | Extraction | 4h | Senior | Week 2 |
| 4 | Sport | 14h | Junior | Week 3-4 |
| 5 | Temperature | 14h | Junior | Week 5-6 |
| 6 | Mealtime | 14h | Junior | Week 7-8 |
| 7 | Meditation | 18h | Senior | Week 9-10 |
| 8 | Nutrition | 12h | Junior | Week 11-12 |
| 9 | Journaling | 22h | Senior | Week 13-15 |

**Total:** ~15 weeks for all modules (with parallel junior work: ~10 weeks actual)

---

## ✅ Checkpoints & Decision Points

### After Phase 2 (Light):
- ✅ **Go/No-Go:** TimeSlider work well?
  - **YES:** Proceed to extraction (Phase 3)
  - **NO:** Redesign TimeSlider in Light, delay extraction

- ✅ **Go/No-Go:** Color feedback useful?
  - **YES:** Extract to ColorSchemeHelper
  - **NO:** Simplify or remove before extracting

### After Phase 4 (Sport):
- ✅ **Go/No-Go:** Shared components reusable?
  - **YES:** Continue with remaining modules
  - **NO:** Refactor shared components before continuing

### After Phase 7 (Meditation):
- ✅ **Decision:** Content library pattern solid?
  - **YES:** Use for Nutrition
  - **NO:** Build Nutrition differently

---

## 🚨 Risk Mitigation

### Risk 1: TimeSlider doesn't fit all modules
**Mitigation:** Validate early (Light + Sport), refactor before 5 more modules use it

### Risk 2: Shared components too rigid
**Mitigation:** Build extensibility into components, use configuration patterns

### Risk 3: Junior developers blocked
**Mitigation:** Complete Phase 1-3 before juniors start, clear documentation

### Risk 4: Over-abstraction creep
**Mitigation:** Only extract after 2+ modules prove pattern, resist premature abstraction

### Risk 5: Scope creep on complex modules
**Mitigation:** Journaling/Meditation have phased implementations (simple first, enhance later)

---

## 🎯 Success Metrics

### Per Module:
- [ ] Fully functional (can enable, configure, log activities)
- [ ] Notifications working
- [ ] Correlates with sleep data
- [ ] Zero analyzer warnings
- [ ] Tests passing (unit + integration)

### Per Phase:
- [ ] Deliverable working as specified
- [ ] Documentation updated
- [ ] Junior developers unblocked (if applicable)
- [ ] Shared components validated (if extraction phase)

### Overall:
- [ ] All 7 modules functional by Week 15
- [ ] Shared infrastructure reusable and well-documented
- [ ] Junior developers can implement new modules independently
- [ ] Codebase maintainable and scalable

---

## 📚 Reference Documentation

- **[SHARED_PLAN.md](shared/SHARED_PLAN.md):** Shared infrastructure details
- **[LIGHT_PLAN.md](light/LIGHT_PLAN.md):** Light module implementation
- **[SPORT_PLAN.md](sport/SPORT_PLAN.md):** Sport module implementation
- **[TEMPERATURE_PLAN.md](temperature/TEMPERATURE_PLAN.md):** Temperature module implementation
- **[MEALTIME_PLAN.md](mealtime/MEALTIME_PLAN.md):** Mealtime module implementation
- **[MEDITATION_PLAN.md](meditation/MEDITATION_PLAN.md):** Meditation module implementation
- **[NUTRITION_PLAN.md](nutrition/NUTRITION_PLAN.md):** Nutrition module implementation
- **[JOURNALING_PLAN.md](journaling/JOURNALING_PLAN.md):** Journaling module implementation

Each *_PLAN.md contains complete implementation details. This roadmap orchestrates the order and dependencies.

---

## 🚀 Next Steps

### To Start Implementation:
1. ✅ Read this roadmap completely
2. ✅ Review SHARED_PLAN.md Phase S.1
3. ✅ Implement essential foundation (6 hours)
4. ✅ Review LIGHT_PLAN.md completely
5. ✅ Implement Light module (12 hours)
6. ✅ Validate Light thoroughly
7. ✅ Extract to shared (4 hours)
8. ✅ Hand off Sport to junior developer

**Start Date:** When ready
**First Deliverable:** Shared foundation (6 hours from start)
**First Module:** Light (Week 2 from start)
**All Modules Complete:** Week 15 from start

---

**This roadmap ensures:**
- ✅ No wasted effort on unneeded abstractions
- ✅ Validated patterns before scaling
- ✅ Junior developers productive quickly
- ✅ Maintainable, scalable codebase
- ✅ Working modules delivered incrementally
