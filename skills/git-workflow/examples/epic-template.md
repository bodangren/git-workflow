# Epic: E2 - Core Curriculum System

**Status**: In Progress
**Owner**: PM/Product Owner
**Created**: 2025-10-21
**Target Completion**: Sprint S3 (2025-11-15)

---

## Vision

Enable educators to create and manage structured learning content with hierarchical organization, lesson delivery, and progress tracking.

## Business Value

**Priority**: High
**Impact**: Core product capability required for MVP launch
**Effort**: 3 sprints (estimated)

## Goals

- Educators can create multi-level course hierarchies
- Students can progress through lessons sequentially
- System tracks learning progress and outcomes
- Content is reusable across multiple courses

## Non-Goals

- Advanced analytics (deferred to E4)
- Social learning features (deferred to E5)
- Third-party LMS integration (future consideration)

## Dependencies

- **Depends on**: E1 - User Management (completed)
- **Blocks**: E3 - Assessment Engine (partially)

## User Stories

### Completed
- [x] #201 - Curriculum Framework (S2) - Completed 2025-10-22
  - Basic course hierarchy working
  - API endpoints functional
  - Spec updated with final design

### In Progress
- [ ] #202 - Lesson Player (S2) - In progress
  - Video playback implemented
  - Progress tracking in development
  - Expected completion: 2025-10-25

### Planned
- [ ] #210 - Assessment Engine Integration (S3)
  - Depends on #202
  - Links lessons to quizzes
  - Estimated: 150K tokens

- [ ] #211 - Progress Dashboard (S3)
  - Visualize student progress
  - Completion analytics
  - Estimated: 120K tokens

## Progress

**Overall**: 1/4 stories complete (25%)

**By Sprint**:
- S2: 1/2 complete (50%)
- S3: 0/2 complete (0%)

**Timeline**:
- Started: 2025-10-21 (S2)
- Target: 2025-11-15 (end of S3)
- Status: On track

## Acceptance Criteria (Epic-Level)

- [ ] Course creation and editing functional
- [ ] Students can navigate lesson sequences
- [ ] Progress is tracked and persisted
- [ ] All core specs updated and accurate
- [ ] Integration tests passing for full workflow
- [ ] Performance meets requirements (<2s page load)
- [ ] Deployed to production

## Risks & Mitigations

**Risk 1**: Lesson player complexity higher than estimated
- **Impact**: May delay S2 completion
- **Mitigation**: Consider splitting #202 if needed
- **Status**: Monitoring

**Risk 2**: Database performance at scale
- **Impact**: May need optimization sprint
- **Mitigation**: Early load testing planned
- **Status**: Not yet an issue

## Related Epics

- **E1 - User Management**: Provides authentication (completed)
- **E3 - Assessment Engine**: Will integrate with lesson player (planned)
- **E4 - Analytics Dashboard**: Will consume curriculum data (future)

## Technical Notes

**Architecture**:
- See `docs/specs/curriculum-management/design.md` for architecture
- Using hierarchical data model (courses > modules > lessons)
- PostgreSQL JSONB for flexible metadata

**Performance Targets**:
- Course load: <500ms
- Lesson navigation: <200ms
- Progress save: <100ms

**Specs Affected**:
- `docs/specs/curriculum-management/spec.md`
- `docs/specs/content-delivery/spec.md`
- `docs/specs/progress-tracking/spec.md`

## Success Metrics

**Technical**:
- All acceptance criteria met
- Test coverage >80%
- No critical bugs

**Business**:
- Enables first educator cohort (10 users)
- Supports 50+ courses
- Ready for beta launch

## Retrospective Notes

*Updated as issues complete*

**What's working well**:
- Spec-first approach preventing rework
- Clear hierarchy model easy to implement

**Challenges**:
- Lesson player more complex than initially scoped
- May need additional sprint for polish

**Learnings**:
- Next epic: Better estimation for multimedia features
- Next epic: Consider performance testing earlier

---

**Last Updated**: 2025-10-22
**Next Review**: Sprint S2 retrospective (2025-10-25)
