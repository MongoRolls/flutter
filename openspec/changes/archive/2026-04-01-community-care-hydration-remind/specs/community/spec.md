## ADDED Requirements

### Requirement: Care contact count limit on server

The system SHALL reject creating a new care contact relationship when the owner already has 20 distinct care contacts, returning a validation error response consistent with other `ValidationError` cases.

#### Scenario: Add contact when at limit

- **WHEN** authenticated user A already has 20 care contact rows as owner and calls `POST /api/care/contacts` to add another distinct contact not yet in the list
- **THEN** the server SHALL NOT create a new row and SHALL return a 4xx error with a validation message indicating the care contact limit

#### Scenario: Upsert existing contact under limit unchanged

- **WHEN** user calls `POST /api/care/contacts` with an existing `(ownerId, contactId)` pair to update nickname only
- **THEN** the server SHALL succeed and SHALL NOT apply the 20-contact limit as a block on that update path

---

### Requirement: Peer hydration summary API

The system SHALL expose `GET /api/care/peers/hydration` for the authenticated user as owner, returning per-peer hydration summary for a caller-local calendar date.

#### Scenario: Successful hydration fetch

- **WHEN** a logged-in user requests `GET /api/care/peers/hydration` with valid `date` and `tzOffset` query parameters
- **THEN** the response SHALL include an array of entries, each with `userId` (the contact user id), `todayMl`, `dailyGoalMl`, and `visible` (boolean), for every care contact where the current user is `ownerId`

#### Scenario: Peer opted out of sharing

- **WHEN** the contact user has hydration sharing disabled (server-side equivalent of `shareHydrationWithCareContacts = false`)
- **THEN** the entry for that peer SHALL have `visible` set to false and SHALL NOT expose concrete milliliter values to the owner

---

### Requirement: Send peer remind API

The system SHALL expose `POST /api/care/remind` so an owner can send a hydration reminder to a care contact using a server-recognized template id.

#### Scenario: Valid remind

- **WHEN** the owner sends `POST /api/care/remind` with a `contactId` (or `careContactId` per API contract) and `templateId` in the allowed set, and a `CareContact` row exists for `(owner, contact)`
- **THEN** the server SHALL accept the request, persist or enqueue the remind as designed, and return success

#### Scenario: Not a care contact

- **WHEN** the target is not a care contact of the current owner
- **THEN** the server SHALL return 404 or 403 with a stable error code

---

### Requirement: Optional hydration sharing profile flag

The system SHALL support a user-level flag (default true) that controls whether peers can see numeric hydration summary in `peers/hydration` results.

#### Scenario: Default allows sharing

- **WHEN** the flag is unset for a user
- **THEN** the system SHALL treat sharing as enabled for hydration visibility

## MODIFIED Requirements

### Requirement: REQ-CARE-03：关怀联系人管理

The system SHALL manage care contacts as follows, including server-side enforcement of the maximum contact count.

#### Scenario: Add contact under limit

- **WHEN** the user finds a target user id via friend lookup and calls `POST /api/care/contacts` with `{ contactId, nickname }` and the owner has fewer than 20 distinct care contacts
- **THEN** the server SHALL upsert the `CareContact` row and return 201

#### Scenario: Add contact when at server limit

- **WHEN** the owner already has 20 distinct care contacts and calls `POST /api/care/contacts` to add another distinct contact
- **THEN** the server SHALL return a 4xx validation error and SHALL NOT create a new row

#### Scenario: List contacts

- **WHEN** the user is logged in and calls `GET /api/care/contacts`
- **THEN** the server SHALL return all care contacts with contact `id` and `nickname`

#### Scenario: Delete contact

- **WHEN** the user calls `DELETE /api/care/contacts/:id` for an owned row
- **THEN** the server SHALL delete the row and return 204

#### Scenario: Delete foreign row

- **WHEN** the user calls `DELETE /api/care/contacts/:id` for a row whose `ownerId` is not the current user
- **THEN** the server SHALL return 404 with error code `NOT_FOUND`

#### Scenario: Offline local cache

- **WHEN** the user is not logged in or the network is unavailable and `HeartProvider` loads contacts
- **THEN** the client SHALL read the contact list from SharedPreferences local cache

---

### Requirement: REQ-CARE-04：发送关怀提醒

The client and server SHALL support sending peer hydration reminders via template selection and backend acceptance; local care records MAY remain for timeline UX.

#### Scenario: Successful send with feedback

- **WHEN** the user selects a contact and template and `POST /api/care/remind` succeeds
- **THEN** the client SHALL show success feedback (e.g. Toast) and SHOULD append a local care timeline entry when that feature is enabled

#### Scenario: Prune old care records

- **WHEN** `HeartProvider` loads care records and a record is older than 30 days
- **THEN** the client SHALL remove that record from the local list
