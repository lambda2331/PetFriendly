# Walking roles and mutual reputation — frontend contract

Migrations **026–028**. Deployed to petfriendly-staging with user approval. Full workflow/security tests passed locally; cloud schema/ACL checks and 11 anonymous-access/catalog smoke checks passed. Flutter now integrates role selection and mode switching, helper onboarding/navigation, request discovery and personal walks, public preferences, owner reputation and mutual review routes. Final UI verification is tracked separately in `docs/progress.md`; a real cloud agreement flow through the new mobile screens remains an acceptance check. See `docs/helper-mode-implementation.md` for route/repository mapping and demo limits. This UI rollout does not deploy migrations again. All calls below use the existing signed-in user's SDK client and secure session storage. No additional account, provider identity, API key or payment integration is needed.

## Account role and visible mode

`my_account_mode()` returns:

```json
{
  "account_role": "both",
  "active_mode": "owner",
  "needs_role_selection": true,
  "capabilities": {
    "create_walk": true,
    "apply_walk": true,
    "create_pet": true,
    "create_community": true,
    "create_meeting": true,
    "submit_place": true
  }
}
```

- `set_account_role(role_in, mode_in?)`: `owner`, `helper` or `both`. For `both`, the optional mode is `owner`/`helper`; omitted mode preserves the existing selection. A single-role account uses its matching mode.
- `switch_account_mode(mode_in)`: switches only among modes allowed by the selected role. It does not grant new capabilities.
- Product roles never grant moderator/admin privileges. Auth `user_metadata` is not a source of authority.
- Legacy accounts and accounts awaiting onboarding initially retain both capabilities, with `needs_role_selection=true`; no invented prior user choice.
- Helper-only accounts can apply but cannot create new walking requests, pets, communities, meetings or venue submissions, including through legacy RPCs. The server still permits reading authorized public content. Hiding unrelated navigation is a frontend responsibility, not a ban on catalog/profile reads.
- Switching a role does not erase data, remove memberships or invalidate existing agreements. Participants may finish, confirm and review their existing agreements in either mode. Withdrawal, cancellation of an open own request and personal-data management remain possible.
- Owner/helper identities are the **same internal account ID**. Invalidate account-scoped UI queries after mode/role changes; clear them and drafts on logout/account switch.

## Helper onboarding

`save_walking_helper_profile` derives `user_id` from the session. It accepts:

| Parameter | Meaning / constraints |
| --- | --- |
| `city_in` | Required public city, 1–120 characters |
| `time_zone_in` | Required IANA zone, e.g. `Europe/Minsk` or `Europe/Moscow` |
| `district_in` | Public district, up to 100 characters; default empty |
| `introduction_in`, `experience_in` | Public descriptions, each up to 1,000 characters |
| `dog_sizes_in` | Distinct `small`, `medium`, `large`; empty means no stated preference |
| `service_districts_in` | Up to 10 public district labels, each 1–100 characters |
| `availability_in` | Up to 28 weekly slots; default empty |
| `accepting_in` | Public availability flag; default `true` |

Example weekly availability: `[ {"day":0,"start":540,"end":1020} ]` means Monday 09:00–17:00 in `time_zone_in`. Days are Monday=0 through Sunday=6; times are integer minutes within one day, with start < end. Overlap on the same day, overnight intervals, extra keys and string-valued times are rejected. Split overnight availability across days. Availability is a preference, not automatic assignment or a booking guarantee.

Fields are public to authorized, unblocked viewers while the user has helper capability. Explicitly explain this before saving; do not put addresses, precise coordinates or private pet instructions here. The user's own stored profile remains accessible after switching to owner-only. No pet is required.

Read `walking_helper_profiles` by `user_id` through the SDK. Authenticated table writes are revoked; use the save RPC. Person name/photo continue to use the existing public profile/private-photo pipeline.

## Requests and discovery

`pets.size` is nullable (`small`, `medium`, `large`); keep it unknown if not specified. Existing pet ownership/RLS applies. Do not infer size from breed/name.

`create_walk_request(pet_in, city_in, starts_in, duration_in, timezone_in, district_in?, description_in?, instructions_in?)` creates the existing request and private details atomically. Only an owner-capable user may create a request for their own pet. `district_in` is a public area label. Venue time zones follow the walk location. The original `create_walk` and `create_walk_at_zone` calls remain compatible and enforce the same role boundary.

`search_walk_requests(city_in, district_in?, from_in?, until_in?, size_in?, offset_in=0, limit_in=40)` returns `items`, `total`, `offset`, `limit`. Maximum page size 100, maximum offset 10,000. The time interval is inclusive at `from_in`, exclusive at `until_in`. Only future open requests in the selected city are returned, excluding the actor's own requests and unavailable/blocked owners. A size filter excludes unknown sizes. This API is for helper-capable users; public legacy request reads retain their existing visibility rules.

Each card contains whitelisted request fields, pet summary, public owner summary and owner rating/review count. It includes:

- `my_role`: `viewer`, `applicant`, `owner`, or `helper` (applicant is not an assigned helper).
- `applied`, `allowed_actions`, `conversation_id`.
- `helper_review_written`, `owner_review_written`: role-specific flags for this actor, including already moderated reviews to prevent duplicate submissions.

Discovery never returns private instructions, exact handover coordinates, another person's applications, or the assigned helper's identity. `conversation_id` is available only to an authorized agreement member. Creating a direct discussion uses the existing chat API and its authorization.

## My walks and actions

`my_walks(role_in?, view_in="active", offset_in=0, limit_in=40)` defaults to the active mode. Explicit `role_in` accepts `owner`, `helper`, or `all`, including historical roles after switching.

- `active`: own open requests, own open applications and assigned/ongoing agreements.
- `history`: completed/cancelled own requests or assigned agreements.
- `applications`: the actor's applications, including requests that no longer accept applications. An unselected applicant never gains the selected helper's chat or instructions.

These lists contain only the actor's relationships, never an arbitrary requested user ID. Current UI should still handle an action becoming unavailable between query and submission.

| Card action | Existing/new RPC |
| --- | --- |
| `apply` / `withdraw` | `apply_walk(request_in)` / `withdraw_walk(request_in)` |
| `assign` | `assign_walk(request_in, helper_in)`; choose an eligible applicant |
| `cancel` | `advance_walk(request_in, next_status="cancelled")`; open own requests only |
| `start` | `advance_walk(..., next_status="in_progress")`; assigned helper only |
| `finish` | `advance_walk(..., next_status="awaiting_confirmation")`; helper only |
| `confirm` | `advance_walk(..., next_status="completed")`; request owner only |
| `review_helper` | `review_walk(request_in, rating_in, body_in?)`; owner → helper |
| `review_owner` | `review_walk_owner(request_in, rating_in, body_in?)`; assigned helper → owner |

Assignment locks the request and creates one agreement and its chat atomically. Duplicate applications do not duplicate notifications. Application withdrawal is compatible with the existing open-request behavior. No additional cancellation/dispute rules were invented.

`walk_private_details(request_in)` returns `request_id` and `instructions` only to the owner or assigned helper. An applicant/outsider is denied. Blocking the owner revokes the helper's RPC and direct RLS read. The owner retains access to their own instructions. Never cache plaintext instructions on disk or log responses.

## Separate reputations and reviews

- `helper_stats()` keeps its original shape: `id`, nullable `rating`, `review_count`, `completed` **as helper**.
- `owner_stats()` returns the same shape **as request owner**.
- Reviews are derived from published, eligible completed agreements; clients cannot write totals or publication flags.
- Read helper reviews from `walk_reviews`; owner reviews from `walk_owner_reviews`. Do not merge them into one rating.
- `reply_walk_review(review_in, body_in)` remains helper-only; `reply_walk_owner_review(review_in, body_in)` is owner-only. Both require a published eligible received review and an available/unblocked author.
- One review per completed agreement **in each direction**, 1–5 stars, text up to 1,000 characters. Self-review, strangers, unselected helpers and reviews before confirmation are denied, including concurrent duplicate submissions. Changing a product role does not change authorship eligibility.
- A zero review count means “Пока нет отзывов”, not zero stars. Request failure means unavailable data, not zero experience.
- Use the existing report API with `target_kind="review"` for either review table. Moderation uses `resolve_report` with server moderator privileges and MFA. Hiding a review removes it from the rating but preserves completed-walk count. No new publication deadlines or verification claims.

## Export, deletion and integration status

The existing reauthenticated `export_my_data()` now also includes the selected product role, helper profile, written/received owner reviews, own applications and helper agreements. Existing export fields are retained.

Deleting an account cascades helper preferences, product role and authored/received owner reviews. Existing historical agreement helper links become null, preserving the existing anonymization behavior. This does not define new retention periods or solve backup deletion; those launch decisions remain deferred.

All new RPCs require an active, non-revoked session with MFA when enrolled. New table reads use RLS and block/account predicates; anonymous reads/writes and direct review/profile writes are denied. Roles do not imply identity verification or guaranteed safety.

The new frontend should consume these endpoints after migrations 026–028 are deployed. Do not silently substitute zero ratings or fabricate successful saves against an older schema. Existing Flutter screens still use the old walking flow until the designer's implementation connects this contract.
