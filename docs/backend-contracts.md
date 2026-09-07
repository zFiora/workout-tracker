# Backend contracts — Password Reset & Profile (Sex / Date of Birth)

This is a handoff spec for the `.NET` API repo (deployed on Railway, base URL
`https://workout-tracker-api-production-99ed.up.railway.app`, see
`lib/core/api/api_config.dart` in the Flutter app). The Flutter client has
already been built against everything in this document. Two things need
backend work:

1. **Forgot / reset password** — two new endpoints, entirely new.
2. **Sex + Date of Birth on the user's profile** — two new fields on an
   existing endpoint.

Everything else (auth, templates, history, measurements, friends) is
unchanged — not included here.

---

## 0. Conventions already in use (for consistency)

Match these exactly — the client's `ApiClient` (`lib/core/api/api_client.dart`)
is hard-coded to them:

- **Auth header:** `Authorization: Bearer <jwt>` on every protected endpoint.
- **Error envelope:** any non-2xx response should return a JSON body with a
  `message` field:
  ```json
  { "message": "Human-readable error." }
  ```
  The client reads `message` and shows it directly in the UI. Other fields
  are ignored (safe to add more, e.g. `code`, but not required).
- **401 semantics:** a 401 on any endpoint *other than* login /
  change-password causes the client to drop its local session and force
  re-login. Only return 401 for "this token is invalid/expired" — use 400/422
  for "wrong current password" etc. so the client doesn't wrongly nuke a
  valid session.
- **Content type:** `application/json` for all request/response bodies
  except the avatar upload (multipart).
- **Dates:** ISO-8601 (`DateTime.parse` on the client). New date-only field
  (`dateOfBirth`) is documented separately below — it's date-only, not
  datetime.

Existing endpoints referenced below, unchanged, included only as context:

| Method | Path | Body | Notes |
|---|---|---|---|
| POST | `/api/auth/login` | `{ identity, password }` | `identity` = email or username |
| POST | `/api/auth/register` | `{ email, username, password, displayName }` | |
| POST | `/api/auth/refresh` | — (auth header only) | |
| POST | `/api/auth/change-password` | `{ currentPassword, newPassword }` | auth required |
| GET/PATCH | `/api/users/me` | — / `{ displayName?, username? }` | returns `AccountModel` shape below |
| GET/PUT | `/api/macro-profile` | see §2 | auth required |

`login`/`register`/`refresh` all return:
```json
{ "token": "<jwt>", "user": { "id": "..." } }
```

`GET /api/users/me` returns (fields the client reads — extra fields ignored):
```json
{
  "id": "string",
  "displayName": "string",
  "username": "string",
  "email": "string",
  "avatarBase64": "string|null",
  "currentStreak": 0,
  "bestStreak": 0,
  "lastWorkoutDate": "iso8601|null"
}
```

---

## 1. Forgot password — `POST /api/auth/forgot-password`

**Auth:** none (public, unauthenticated — like login/register).

**Request:**
```json
{ "email": "user@example.com" }
```

**Response — always 200, always the same body, whether or not the email is
registered:**
```json
{ "message": "If that email is registered, we've sent a reset link." }
```

This is a hard requirement, not a nicety — the Flutter UI (`forgotPasswordPage.dart`)
already shows this exact generic message regardless of the response, but the
**backend itself must not leak existence via status code, response shape,
response time, or body content**. Concretely:

- Do the same amount of work (hash lookup + a constant-time no-op branch)
  whether the user exists or not, so timing doesn't leak it either.
- Never return 404 for "email not found" here.
- Rate-limit by IP and by email (e.g. 3–5 requests / 15 min) to stop
  enumeration-by-timing and mail-bombing a victim's inbox. Return 200 with
  the same generic message even when rate-limited (don't reveal rate-limit
  state either) — just skip sending the email that time, or queue it.

**Server-side behavior when the email *is* registered:**

1. Generate a cryptographically random token (e.g. 32 bytes from
   `RandomNumberGenerator`/`crypto/rand`, base64url-encoded — **not** a GUID,
   not sequential, not derived from user data).
2. Store only a **hash** of the token (e.g. SHA-256) alongside the user id
   and an expiry timestamp — never store the raw token server-side (same
   principle as password hashing: if the DB leaks, the token shouldn't be
   directly usable).
3. Expiry: **15–60 minutes** is the standard window; pick one and document
   it. Store `ExpiresAtUtc`.
4. Single-use: store a `UsedAtUtc` (nullable) or `Status` column; mark it
   used the moment it's successfully redeemed by §2, and reject any further
   attempt with that token even if it hasn't expired yet.
5. Invalidate any *previous* outstanding token for that user when a new one
   is requested (prevents an old leaked link from still working).
6. Email the raw (unhashed) token to the user via your mail provider (see
   §4). The Flutter reset screen currently expects the user to **copy/paste
   a code** — it does not follow a deep link — so the email should present
   the token as a short, copyable code/string the user can paste into the
   app, not (only) a tappable URL. If you'd rather use a link + deep link
   later, that's a client-side follow-up, not a backend blocker.

## 2. Reset password — `POST /api/auth/reset-password`

**Auth:** none (the token *is* the credential for this call).

**Request:**
```json
{ "token": "<raw token from the email>", "newPassword": "newSecret123" }
```

**Success — 200:**
```json
{ "message": "Password reset." }
```
(Body content isn't read by the client beyond the error path, but return
something.)

**Failure — 400/422, `{ "message": "..." }`,** for each of:

| Condition | Suggested message |
|---|---|
| Token doesn't exist / doesn't match any hash | "This reset link is invalid." |
| Token expired | "This reset link has expired. Request a new one." |
| Token already used | "This reset link has already been used." |
| `newPassword` fails policy (see below) | "Password must be at least 8 characters." |

The Flutter `ResetPasswordPage` shows whatever `message` comes back
verbatim, so these three failure modes should be **distinguishable** (don't
collapse them all into one generic "invalid token" — the user needs to know
whether to request a new link or just retry).

**Password policy — match the client exactly:** minimum 8 characters
(`lib/common/validators/password_validator.dart` and the existing
`change-password` endpoint already enforce this). Don't silently accept a
weaker or require a stricter password than that without also updating the
client validator, or users will hit a client-side-accepted, server-rejected
password.

**On success, server-side:**
1. Verify token hash + not expired + not used.
2. Hash `newPassword` with the same algorithm/cost used at registration
   (don't introduce a second hashing scheme).
3. Update the user's password hash.
4. Mark the token used (or delete the row).
5. **Invalidate existing sessions.** At minimum, invalidate/rotate whatever
   the refresh-token mechanism relies on for that user, so a stolen session
   token from before the reset stops working — the whole point of a
   password reset is to lock out anyone who had prior access. If there's no
   session-invalidation mechanism today, this is worth adding regardless of
   this feature.
6. Optional but recommended: send a "your password was changed" notification
   email (not required for the client to function, but standard practice —
   the current reset flow doesn't require the current password, so this is
   the one signal a legitimate owner gets if it wasn't them).

Do **not** require or expose the user's current/old password anywhere in
this flow — it's a *reset*, not a change, and by definition the user may not
know their current password when using it.

---

## 3. Sex & Date of Birth — extend `/api/macro-profile`

The Flutter client already stores age/sex on the same resource as the BMR
inputs (`isMale`, `age`, `activityFactor`) and body height (`heightCm`) — a
single row per user, fetched/replaced together. Two fields need to be added
to that same resource; **don't create a second endpoint or a duplicate field
on `/api/users/me`** — the client only reads sex/DOB from `/api/macro-profile`.

**`GET /api/macro-profile`** — add two optional fields to the response:
```json
{
  "isMale": true,
  "age": 25,
  "activityFactor": 1.375,
  "heightCm": 178.0,
  "sex": "male",
  "dateOfBirth": "1998-04-12"
}
```

- `sex`: `"male" | "female" | "unspecified"`, or the field can simply be
  **absent** for a profile that's never set it — the client treats "absent"
  and `"unspecified"` identically (falls back to its own locally-cached
  value rather than overwriting it, so don't worry about inventing a value
  for existing rows — `null`/absent is the correct default for every
  pre-existing user).
- `dateOfBirth`: **date-only**, `YYYY-MM-DD`, no time/timezone component.
  Absent/`null` if never set — same "don't invent a value" rule as above.
- `isMale`/`age` stay exactly as they are today — the client still relies on
  them for the BMR calculation and keeps them in sync with `sex` internally
  (`MacroProfile.withSex` in `lib/home/measure/models/macro_profile.dart`).
  No backend change needed to those two fields.

**`PUT /api/macro-profile`** — request body the client sends today:
```json
{
  "isMale": true,
  "age": 25,
  "activityFactor": 1.375,
  "heightCm": 178.0,
  "sex": "male",
  "dateOfBirth": "1998-04-12"
}
```
`sex` and `dateOfBirth` are **omitted from the request entirely** when the
user hasn't set them yet (rather than sent as `null`) — treat "key absent"
the same as "value null": leave the stored value unchanged. This already
works with the client's behavior today (unknown keys are currently ignored,
so nothing breaks pre-implementation) — once implemented, just:
1. Parse `sex` if present → store as an enum/string column; validate against
   the three allowed values (reject anything else with 400).
2. Parse `dateOfBirth` if present → validate it's a real, past date (reject
   `dateOfBirth` in the future, and probably anything implying an age over,
   say, 120, as basic sanity checks) → store as a date column.
3. This is a **full-replace PUT** for the whole row per the existing
   contract (that's why the client always resends `heightCm` etc.) — keep
   that semantic. `sex`/`dateOfBirth` follow the same "absent = leave
   unchanged" rule as everything else already implicitly does, since the
   client always has and resends its full known state for a field once it's
   been set once.

### Suggested DB migration

Add two nullable columns to whatever table backs `/api/macro-profile`
(`Sex` as a small int/enum or string column, `DateOfBirth` as a `date`
column — not `datetime`). Nullable, no default, no backfill — matches the
client's "don't invent a DOB/sex for existing users" requirement exactly.

```sql
ALTER TABLE MacroProfiles ADD Sex INT NULL;               -- 0=unspecified,1=male,2=female, or a string column — your call
ALTER TABLE MacroProfiles ADD DateOfBirth DATE NULL;
```

(Table/column names are illustrative — match your actual schema/ORM
conventions.)

---

## 4. Email infrastructure (needed for §1)

Whatever SMTP/transactional-email provider you use, keep the credentials out
of source control — environment variables the API reads at startup, e.g.:

```
SMTP_HOST=...
SMTP_PORT=587
SMTP_USERNAME=...
SMTP_PASSWORD=...          # or an API key for a transactional provider (SendGrid/Postmark/SES/etc.)
SMTP_FROM_ADDRESS=noreply@yourapp.com
PASSWORD_RESET_TOKEN_TTL_MINUTES=30   # whatever you pick in §1
```

Railway: set these as service environment variables in its dashboard, not in
a committed `.env`/`appsettings.json`. If a local `.env`/`appsettings.Development.json`
is used for dev, make sure it's `.gitignore`d.

The reset email itself only needs to contain the raw token (as a short code
the user can paste into the app's "I have a reset code" screen) and,
optionally, a human-friendly note of the expiry window.

---

## 5. Acceptance checklist (what the Flutter client will exercise)

- [ ] `POST /api/auth/forgot-password` with a registered email → 200, generic message, email sent with a fresh token.
- [ ] Same call with an unregistered email → 200, **identical** generic message, no email sent, no way to distinguish from the above via status/timing/body.
- [ ] Repeated rapid calls → rate-limited without revealing account existence.
- [ ] `POST /api/auth/reset-password` with a valid, unexpired, unused token + an 8+ char password → 200, password updated, existing sessions invalidated.
- [ ] Same token reused a second time → 400/422 "already been used".
- [ ] Expired token → 400/422 "has expired".
- [ ] Garbage/unknown token → 400/422 "invalid".
- [ ] `newPassword` under 8 characters → 400/422, rejected server-side even if a client somehow bypassed its own validator.
- [ ] `GET /api/macro-profile` for a pre-existing user who's never set sex/DOB → `sex`/`dateOfBirth` absent or null, nothing invented.
- [ ] `PUT /api/macro-profile` with `sex`/`dateOfBirth` included → stored, and echoed back on the next `GET`.
- [ ] `PUT /api/macro-profile` **without** `sex`/`dateOfBirth` (e.g. an older client, or a request that only changes `heightCm`) → previously-stored `sex`/`dateOfBirth` values are preserved, not wiped.
