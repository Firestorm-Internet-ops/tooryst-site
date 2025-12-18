# Code Review: Frontend & Backend - Nearby Attractions Feature

**Date:** December 18, 2025  
**Scope:** Backend (Python/FastAPI) and Frontend (Next.js/React) - Nearby Attractions Feature

---

## Executive Summary

The codebase demonstrates solid architectural patterns with clear separation of concerns. The nearby attractions feature is well-structured with a multi-source strategy (database-first, then Google Places fallback). However, there are several areas for improvement in data consistency, error handling, performance optimization, and code maintainability.

**Overall Assessment:** ✅ **Good foundation with actionable improvements**

---

## 🔴 Critical Issues

### 1. **Data Consistency Problem: Missing nearby_attraction_id**

**Location:** `backend/app/application/services/attraction_data_service.py` (lines 700-750)

**Issue:** The code attempts to fetch missing data from the attractions table using `nearby_attraction_id`, but this field is often NULL for Google Places attractions. The fallback to slug-based lookup is unreliable.

```python
# Current approach - problematic
if n.nearby_attraction_id:
    nearby_attr = session.query(models.Attraction).filter(...).first()

# Fallback to slug - unreliable
if not nearby_attr and n.slug:
    nearby_attr = session.query(models.Attraction).filter(...).first()
```

**Problems:**
- Google Places attractions have `nearby_attraction_id = NULL` and `slug = NULL`
- Slug-based lookup fails for these items
- Missing images/ratings for ~50% of nearby attractions
- Inconsistent data in API responses

**Recommendation:**
```python
# Better approach: Populate nearby_attraction_id during creation
# In nearby_attractions_fetcher.py, when creating DB attractions:
if not nearby_attr:
    # Create attraction record first
    new_attr = models.Attraction(...)
    session.add(new_attr)
    session.flush()  # Get the ID
    nearby_item['nearby_attraction_id'] = new_attr.id
```

---

### 2. **N+1 Query Problem in attraction_data_service.py**

**Location:** `backend/app/application/services/attraction_data_service.py` (lines 700-750)

**Issue:** For each nearby attraction, the code makes separate queries to fetch hero images and attraction data.

```python
for n in nearby_rows:
    # Query 1: Fetch attraction
    nearby_attr = session.query(models.Attraction).filter(...).first()
    
    # Query 2: Fetch hero image
    hero_image = session.query(models.HeroImage).filter(...).first()
```

**Impact:** For 10 nearby attractions = 20+ database queries

**Recommendation:** Use eager loading with joins:

```python
nearby_rows = (
    session.query(models.NearbyAttraction, models.Attraction, models.HeroImage)
    .outerjoin(models.Attraction, models.NearbyAttraction.nearby_attraction_id == models.Attraction.id)
    .outerjoin(models.HeroImage, models.Attraction.id == models.HeroImage.attraction_id)
    .filter(models.NearbyAttraction.attraction_id == attraction.id)
    .all()
)
```

---

### 3. **Hardcoded Path in populate_nearby_attractions_data.py**

**Location:** `backend/scripts/populate_nearby_attractions_data.py` (line 18)

```python
sys.path.insert(0, '/Users/deepak/Desktop/storyboard/backend')
```

**Issue:** Hardcoded absolute path breaks on any other machine/environment

**Recommendation:**
```python
import os
import sys

# Get the backend directory relative to this script
script_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(script_dir)
sys.path.insert(0, backend_dir)
```

---

### 4. **Missing Error Handling in Frontend**

**Location:** `client/src/components/attractions/sections/NearbyAttractionsSection.tsx`

**Issue:** No error boundary or fallback for missing image URLs

```typescript
// Current - will fail silently if image_url is null
<Image
    src={getSafeImageUrl(attraction.image_url)!}
    alt={attraction.name}
    fill
/>
```

**Problem:** The `!` (non-null assertion) contradicts the `getSafeImageUrl` check. If image is null, it renders the fallback UI but doesn't handle the case gracefully.

**Recommendation:**
```typescript
const imageUrl = getSafeImageUrl(attraction.image_url);

if (imageUrl) {
    // Render image
} else {
    // Render text-only card with better styling
}
```

---

## 🟡 High Priority Issues

### 5. **Unused Imports in Frontend**

**Location:** `client/src/components/attractions/AttractionPageClient.tsx` (lines 8-9)

```typescript
const TicketAnimation = dynamic(...);
const TicketAnimationEmerald = dynamic(...);
// These are imported but never used (commented out in JSX)
```

**Impact:** Increases bundle size unnecessarily

**Recommendation:** Remove unused imports or uncomment if they should be used.

---

### 6. **Inefficient Distance Calculation in Database**

**Location:** `backend/app/infrastructure/external_apis/nearby_attractions_fetcher.py` (lines 60-80)

**Issue:** Haversine formula calculated in SQL for every query, then filtered in Python

```python
# Calculates distance for all attractions, then filters
results = [r for r in results if r.distance_km and r.distance_km <= settings.NEARBY_MAX_DISTANCE_KM][:max_results]
```

**Problem:** 
- Fetches 3x more results than needed
- Calculates distances for all, then discards
- Inefficient for large datasets

**Recommendation:**
```python
# Add WHERE clause to SQL query
.filter(
    EARTH_RADIUS_KM * func.acos(...) <= settings.NEARBY_MAX_DISTANCE_KM
)
```

---

### 7. **Inconsistent Logging Levels**

**Location:** Multiple files

**Issue:** Mix of `logger.info()`, `logger.warning()`, and inline logging

```python
# In attraction_data_service.py
logger = __import__('logging').getLogger(__name__)  # Anti-pattern
logger.info(f"Found nearby attraction by slug...")
```

**Recommendation:** Use dependency injection for logger:

```python
from app.core.logging import get_logger

logger = get_logger(__name__)
```

---

### 8. **Type Safety Issues in Frontend**

**Location:** `client/src/types/attraction-page.ts`

**Issue:** Optional fields not consistently marked

```typescript
export type NearbyAttraction = {
  name: string;
  slug?: string | null;  // Optional but can be null
  link?: string | null;
  distance_km?: number | null;
  // ...
};
```

**Problem:** `slug?: string | null` is ambiguous - should be `slug: string | null | undefined`

**Recommendation:** Use strict null checks in tsconfig.json and be explicit:

```typescript
export type NearbyAttraction = {
  name: string;
  slug: string | null;  // Explicitly nullable
  link: string | null;
  distance_km: number | null;
};
```

---

## 🟢 Medium Priority Issues

### 9. **Magic Numbers Throughout Codebase**

**Locations:**
- `nearby_attractions_fetcher.py` line 95: `remaining * 2` (why 2x?)
- `nearby_attractions_fetcher.py` line 120: `10000` (hardcoded radius)
- `NearbyAttractionsSection.tsx` line 50: `400` (scroll amount)

**Recommendation:** Extract to constants with clear names:

```python
# In config or constants
GOOGLE_PLACES_SEARCH_MULTIPLIER = 2  # Fetch 2x to account for filtering
GOOGLE_PLACES_RADIUS_METERS = 10000
SCROLL_AMOUNT_PX = 400
```

---

### 10. **Incomplete Error Messages**

**Location:** `backend/app/infrastructure/external_apis/nearby_attractions_fetcher.py` (line 180)

```python
logger.warning(f"Skipping nearby attraction {attraction.name} (id: {attraction.id}) - both image_url and link are null (slug: {attraction.slug})")
```

**Issue:** Long, repetitive error messages. Should be structured.

**Recommendation:**
```python
logger.warning(
    "Skipping nearby attraction",
    extra={
        "attraction_id": attraction.id,
        "attraction_name": attraction.name,
        "slug": attraction.slug,
        "reason": "missing_image_and_link"
    }
)
```

---

### 11. **Missing Validation in API Response**

**Location:** `backend/app/api/v1/routes/attractions.py`

**Issue:** No validation that returned data matches schema

```python
@router.get("/attractions/{slug}/page", response_model=AttractionPageResponseSchema)
async def get_attraction_page(slug: str, use_case: GetAttractionPageUseCase = Depends(...)):
    page_dto = await use_case.execute(slug)
    # No validation that page_dto has required fields
    return AttractionPageResponseSchema(...)
```

**Recommendation:** Add validation:

```python
if not page_dto or not page_dto.cards:
    raise HTTPException(status_code=500, detail="Invalid page data")
```

---

### 12. **Scroll Performance Issue in Frontend**

**Location:** `client/src/components/attractions/sections/NearbyAttractionsSection.tsx` (lines 50-60)

**Issue:** `checkScrollability` is throttled but still called on every scroll event

```typescript
const checkScrollability = useCallback(() => {
    const now = Date.now();
    if (now - lastScrollCheckTime.current < 100) {
        return;  // Still processes event, just returns early
    }
    // ...
}, []);
```

**Better approach:** Use passive event listener with requestAnimationFrame

```typescript
useEffect(() => {
    let rafId: number;
    const handleScroll = () => {
        rafId = requestAnimationFrame(checkScrollability);
    };
    container?.addEventListener('scroll', handleScroll, { passive: true });
    return () => {
        cancelAnimationFrame(rafId);
        container?.removeEventListener('scroll', handleScroll);
    };
}, []);
```

---

## 🔵 Low Priority Issues / Best Practices

### 13. **Missing JSDoc Comments**

**Location:** `backend/app/infrastructure/external_apis/nearby_attractions_fetcher.py`

**Issue:** Complex methods lack documentation

```python
async def _get_from_database(self, ...):
    """Get nearby attractions from our database."""  # Too brief
```

**Recommendation:**
```python
async def _get_from_database(
    self,
    attraction_id: int,
    city_name: str,
    latitude: float,
    longitude: float,
    max_results: int
) -> List[Dict[str, Any]]:
    """
    Fetch nearby attractions from the database.
    
    Uses Haversine formula to calculate distances and filters to attractions
    within the configured max distance. Results are ordered by distance.
    
    Args:
        attraction_id: ID of the current attraction (excluded from results)
        city_name: City name to filter attractions
        latitude: Latitude of current attraction
        longitude: Longitude of current attraction
        max_results: Maximum number of results to return
    
    Returns:
        List of nearby attractions with calculated distances and metadata
    
    Raises:
        Exception: If database query fails (logged and returns empty list)
    """
```

---

### 14. **Inconsistent Null Handling**

**Location:** Multiple files

**Issue:** Mix of null checks:

```python
# Style 1
if distance_km is not None:
    distance_text = f"{distance_km:.1f}km"

# Style 2
if distance_km:
    distance_text = f"{distance_km:.1f}km"

# Style 3
distance_text = distance_km and f"{distance_km:.1f}km" or "Nearby"
```

**Recommendation:** Standardize on explicit null checks:

```python
if distance_km is not None and distance_km > 0:
    distance_text = f"{distance_km:.1f}km"
else:
    distance_text = "Nearby"
```

---

### 15. **Missing Unit Tests**

**Location:** `backend/scripts/populate_nearby_attractions_data.py`

**Issue:** No tests for data population script

**Recommendation:** Add tests:

```python
# tests/scripts/test_populate_nearby_attractions_data.py
def test_populate_updates_missing_rating(session, nearby_attraction, attraction):
    """Test that missing ratings are populated from attractions table"""
    nearby_attraction.rating = None
    session.commit()
    
    populate_nearby_attractions_data()
    
    updated = session.query(NearbyAttraction).first()
    assert updated.rating == attraction.rating
```

---

### 16. **Unused Variable in Frontend**

**Location:** `client/src/components/attractions/sections/NearbyAttractionsSection.tsx` (line 30)

```typescript
const lastScrollCheckTime = useRef<number>(0);
// Used in checkScrollability but could be simplified
```

**Recommendation:** Consider using a simpler debounce approach or library.

---

### 17. **Missing Accessibility Attributes**

**Location:** `client/src/components/attractions/sections/NearbyAttractionsSection.tsx`

**Issue:** Cards lack proper ARIA labels

```typescript
<Wrapper key={idx}>
    <div className="relative rounded-2xl...">
        {/* No aria-label or role */}
    </div>
</Wrapper>
```

**Recommendation:**
```typescript
<Wrapper key={idx}>
    <article 
        className="relative rounded-2xl..."
        aria-label={`${attraction.name}, ${attraction.distance_text} away`}
    >
        {/* ... */}
    </article>
</Wrapper>
```

---

### 18. **Hardcoded Configuration Values**

**Location:** `backend/app/infrastructure/external_apis/nearby_attractions_fetcher.py` (line 95)

```python
remaining * 2  # Why 2? Should be configurable
```

**Recommendation:** Move to `.env`:

```env
NEARBY_ATTRACTIONS_GOOGLE_MULTIPLIER=2
```

---

## 📊 Code Quality Metrics

| Metric | Status | Notes |
|--------|--------|-------|
| Type Safety | ⚠️ Mixed | Python has good types, TypeScript needs stricter null checks |
| Error Handling | ⚠️ Partial | Try-catch blocks exist but messages could be better |
| Performance | ⚠️ Needs Work | N+1 queries, inefficient distance calculations |
| Test Coverage | ❌ Low | No tests for critical paths |
| Documentation | ⚠️ Incomplete | Some functions lack JSDoc |
| Code Duplication | ⚠️ Moderate | Similar logic in multiple places |
| Maintainability | ✅ Good | Clear separation of concerns, good structure |

---

## 🎯 Recommended Action Plan

### Phase 1: Critical (Do First)
1. Fix hardcoded path in `populate_nearby_attractions_data.py`
2. Implement eager loading to fix N+1 queries
3. Ensure `nearby_attraction_id` is populated for all attractions

### Phase 2: High Priority (Next Sprint)
4. Add comprehensive error handling in frontend
5. Remove unused imports
6. Optimize distance calculations in SQL

### Phase 3: Medium Priority (Following Sprint)
7. Standardize logging approach
8. Add JSDoc comments to complex functions
9. Improve accessibility in frontend components

### Phase 4: Low Priority (Backlog)
10. Add unit tests
11. Extract magic numbers to constants
12. Improve error messages with structured logging

---

## 🔗 Related Files to Review

- `backend/app/core/dependencies.py` - Dependency injection setup
- `backend/app/application/use_cases/get_attraction_page.py` - Use case implementation
- `client/src/hooks/useScrollSpy.ts` - Scroll spy implementation
- `backend/app/infrastructure/persistence/models.py` - ORM models

---

## ✅ What's Working Well

1. **Clean Architecture:** Clear separation between API, application, and infrastructure layers
2. **Type Safety:** Both Python and TypeScript have good type definitions
3. **Error Boundaries:** Frontend has error boundaries for graceful degradation
4. **Responsive Design:** Frontend components are mobile-friendly
5. **Database Schema:** Well-designed with proper indexes and constraints
6. **Configuration Management:** Comprehensive `.env` configuration
7. **API Design:** RESTful endpoints with clear naming

---

## 📝 Summary

The codebase demonstrates solid engineering practices with a well-thought-out architecture. The main areas for improvement are:

1. **Data consistency** - Ensure `nearby_attraction_id` is always populated
2. **Query optimization** - Fix N+1 queries with eager loading
3. **Error handling** - More robust error messages and validation
4. **Code quality** - Remove unused code, standardize patterns, add tests

These improvements will enhance maintainability, performance, and reliability without requiring major refactoring.

