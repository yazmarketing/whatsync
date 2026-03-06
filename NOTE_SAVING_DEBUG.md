# Note Saving Debug Guide

## Current Extension Implementation

### What the Extension Sends

The extension sends the following structure to the edge function:

```json
{
  "action": "createNote",
  "data": {
    "contactId": 646496038119,        // Number (required)
    "body": "Note text here",         // String (PRIMARY - required)
    "note": "Note text here",         // String (ALTERNATIVE - for compatibility)
    "noteBody": "Note text here",     // String (ALTERNATIVE - for compatibility)
    "timestamp": 1768736618679,       // Number (required, milliseconds)
    "createTodo": true                // Boolean (optional)
  }
}
```

### Field Priority

The edge function should extract note text using this priority:
```javascript
const noteText = (note ?? noteBody ?? body)?.toString().trim();
```

This means:
1. First check `note`
2. If not present, check `noteBody`
3. If not present, check `body` (PRIMARY field)

## Edge Function Validation Checklist

Your edge function should validate:

```javascript
// Extract fields
const { contactId, note, noteBody, body, timestamp } = data;

// Extract note text (priority: note > noteBody > body)
const noteText = (note ?? noteBody ?? body)?.toString().trim();

// Validate required fields
if (!contactId) {
  console.error("Missing contactId:", contactId);
  return error("Missing required field: contactId");
}

if (!timestamp) {
  console.error("Missing timestamp:", timestamp);
  return error("Missing required field: timestamp");
}

if (!noteText) {
  console.error("Missing note text. Checked:", { note, noteBody, body });
  return error("Missing required field: note text (note, noteBody, or body)");
}
```

## Common Issues & Solutions

### Issue 1: Edge Function Expects Different Field Names

**Symptom:** Error "Some required properties were not set"

**Solution:** Check what field names your edge function expects. The extension sends:
- `contactId` (not `contact_id` or `contactID`)
- `body`, `note`, `noteBody` (all three are sent)
- `timestamp` (not `time` or `created_at`)

**Fix:** Update edge function to accept these field names, or update extension to match edge function expectations.

### Issue 2: Edge Function Expects HubSpot Payload Structure

**Symptom:** Edge function tries to access `data.engagement` or `data.associations`

**Solution:** The extension sends a **flat structure**, not the HubSpot API payload. The edge function must build the HubSpot payload internally:

```javascript
// ❌ WRONG - Don't expect this from extension
const hubspotPayload = data; // This won't work!

// ✅ CORRECT - Build HubSpot payload in edge function
const { contactId, body, timestamp } = data;
const noteText = (note ?? noteBody ?? body)?.toString().trim();

const hubspotPayload = {
  engagement: {
    active: true,
    type: "NOTE",
    timestamp: timestamp
  },
  associations: {
    contactIds: [contactId]
  },
  metadata: {
    body: noteText
  }
};
```

### Issue 3: Edge Function Requires Additional Fields

**Symptom:** Error mentions missing `portalId`, `ownerId`, or other fields

**Solution:** HubSpot Engagements API doesn't require these fields for notes. If your edge function checks for them, make them optional:

```javascript
// ❌ WRONG - Don't require these
if (!data.portalId || !data.ownerId) {
  return error("Missing portalId or ownerId");
}

// ✅ CORRECT - These are optional
const portalId = data.portalId || null;
const ownerId = data.ownerId || null;
```

### Issue 4: Type Mismatches

**Symptom:** Validation passes but HubSpot API rejects the request

**Solution:** Ensure correct types:
- `contactId`: Must be a **number** (not string)
- `timestamp`: Must be a **number** (milliseconds, not seconds or ISO string)
- `body`/`note`/`noteBody`: Must be a **string** (not object or array)

## Debugging Steps

### Step 1: Check Extension Logs

Look in browser console for:
```
[Background] ===== REQUEST DATA FOR EDGE FUNCTION =====
[Background] Full request data: { ... }
[Background] ✅ VALIDATION CHECKS (what edge function should validate)
```

This shows exactly what the extension is sending.

### Step 2: Check Edge Function Logs

In your Supabase Edge Function logs, add:

```javascript
console.log("Received action:", action);
console.log("Received data:", JSON.stringify(data, null, 2));
console.log("Validation data:", {
  contactId: data.contactId,
  contactIdExists: !!data.contactId,
  contactIdType: typeof data.contactId,
  body: data.body,
  bodyExists: !!data.body,
  bodyLength: data.body?.length,
  note: data.note,
  noteExists: !!data.note,
  noteBody: data.noteBody,
  noteBodyExists: !!data.noteBody,
  timestamp: data.timestamp,
  timestampExists: !!data.timestamp,
  timestampType: typeof data.timestamp
});
```

### Step 3: Verify Field Extraction

In edge function, log the extracted values:

```javascript
const { contactId, note, noteBody, body, timestamp } = data;
const noteText = (note ?? noteBody ?? body)?.toString().trim();

console.log("Extracted values:", {
  contactId,
  note,
  noteBody,
  body,
  noteText, // This is what should be used
  timestamp
});

// Then validate
if (!contactId) {
  console.error("❌ contactId validation failed:", contactId);
  return error("Missing contactId");
}
if (!timestamp) {
  console.error("❌ timestamp validation failed:", timestamp);
  return error("Missing timestamp");
}
if (!noteText) {
  console.error("❌ noteText validation failed. Checked:", { note, noteBody, body });
  return error("Missing note text");
}
console.log("✅ All validations passed");
```

## Expected HubSpot API Payload

After validation, the edge function should send to HubSpot:

```json
{
  "engagement": {
    "active": true,
    "type": "NOTE",
    "timestamp": 1768736618679
  },
  "associations": {
    "contactIds": [646496038119]
  },
  "metadata": {
    "body": "Note text here"
  }
}
```

**Endpoint:** `POST https://api.hubapi.com/engagements/v1/engagements`
**Headers:**
- `Authorization: Bearer {HUBSPOT_ACCESS_TOKEN}`
- `Content-Type: application/json`

## Quick Fix Template

If your edge function is failing validation, use this template:

```typescript
if (action === 'createNote') {
  // Log received data
  console.log("Validation data:", JSON.stringify(data, null, 2));
  
  // Extract with fallback
  const { contactId, note, noteBody, body, timestamp } = data;
  const noteText = (note ?? noteBody ?? body)?.toString().trim();
  
  // Log each validation check
  console.log("contactId check:", !contactId, "Value:", contactId);
  console.log("timestamp check:", !timestamp, "Value:", timestamp);
  console.log("noteText check:", !noteText, "Value:", noteText);
  
  // Validate
  if (!contactId || !timestamp || !noteText) {
    const missing = [];
    if (!contactId) missing.push('contactId');
    if (!timestamp) missing.push('timestamp');
    if (!noteText) missing.push('note text (note/noteBody/body)');
    
    return new Response(
      JSON.stringify({ 
        error: `Missing required fields: ${missing.join(', ')}`,
        received: { contactId, note, noteBody, body, timestamp }
      }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }
  
  // Build HubSpot payload
  const hubspotPayload = {
    engagement: {
      active: true,
      type: "NOTE",
      timestamp: timestamp
    },
    associations: {
      contactIds: [contactId]
    },
    metadata: {
      body: noteText
    }
  };
  
  // ... rest of HubSpot API call
}
```
