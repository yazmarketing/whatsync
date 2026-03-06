# Edge Function Template for createNote

## What the Client Sends to Edge Function:

```json
{
  "action": "createNote",
  "data": {
    "contactId": 646496038119,        // Number (HubSpot contact ID)
    "note": "User's note text here",   // String (note content)
    "timestamp": 1768731778429,        // Number (milliseconds since epoch)
    "createTodo": true                  // Boolean (optional)
  }
}
```

## What the Edge Function Should Send to HubSpot:

### Option 1: CRM v3 Notes API (RECOMMENDED - Modern API)

#### Endpoint:
```
POST https://api.hubapi.com/crm/v3/objects/notes
```

#### Headers:
```
Authorization: Bearer {HUBSPOT_ACCESS_TOKEN}
Content-Type: application/json
```

#### Request Body (EXACT FORMAT):
```json
{
  "properties": {
    "hs_note_body": "User's note text here",
    "hs_timestamp": 1768731778429
  },
  "associations": [
    {
      "to": {
        "id": "646496038119"
      },
      "types": [
        {
          "associationCategory": "HUBSPOT_DEFINED",
          "associationTypeId": 202
        }
      ]
    }
  ]
}
```

**Important Notes:**
- `hs_note_body` is REQUIRED (not `note` or `body`)
- `hs_timestamp` is REQUIRED (must be milliseconds or ISO string)
- `associations[0].to.id` can be string or number
- `associationTypeId: 202` is the standard note-to-contact association type

---

### Option 2: Engagements API (Legacy - Still works)

#### Endpoint:
```
POST https://api.hubapi.com/engagements/v1/engagements
```

#### Headers:
```
Authorization: Bearer {HUBSPOT_ACCESS_TOKEN}
Content-Type: application/json
```

#### Request Body (EXACT FORMAT):
```json
{
  "engagement": {
    "active": true,
    "type": "NOTE",
    "timestamp": 1768731778429
  },
  "associations": {
    "contactIds": [646496038119]
  },
  "metadata": {
    "body": "User's note text here"
  }
}
```

## Edge Function Code Template (Deno/Supabase):

### ✅ WORKING SOLUTION: Using Engagements API (Verified)

```typescript
// In your Supabase Edge Function (hubspot/index.ts)

Deno.serve(async (req) => {
  const { action, data } = await req.json();
  
  if (action === 'createNote') {
    // Extract data - handles multiple field name options
    const { contactId, note, noteBody, body, timestamp } = data;
    
    // Pick the first non-empty value from multiple field name options
    const noteText = (note ?? noteBody ?? body)?.toString().trim();
    
    // Validate required fields
    if (!contactId || !timestamp || !noteText) {
      return new Response(
        JSON.stringify({ error: 'Missing required: contactId, timestamp, or note text' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Format payload for HubSpot Engagements API
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
        body: noteText   // Single canonical value
      }
    };
    
    console.log('Creating note with payload:', JSON.stringify(hubspotPayload, null, 2));
    
    // Get HubSpot access token from environment
    const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
    
    if (!hubspotToken) {
      return new Response(
        JSON.stringify({ error: 'HubSpot access token not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    try {
      // Call HubSpot Engagements API
      const response = await fetch('https://api.hubapi.com/engagements/v1/engagements', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${hubspotToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(hubspotPayload)
      });
      
      const responseText = await response.text();
      console.log('HubSpot response status:', response.status);
      console.log('HubSpot response:', responseText);
      
      if (!response.ok) {
        console.error('HubSpot API Error:', responseText);
        return new Response(
          JSON.stringify({ error: `HubSpot API error: ${responseText}` }),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      const result = JSON.parse(responseText);
      return new Response(
        JSON.stringify({ success: true, data: result }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
      
    } catch (error) {
      console.error('Error calling HubSpot API:', error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
  }
  
  return new Response(
    JSON.stringify({ error: 'Unknown action' }),
    { status: 400, headers: { 'Content-Type': 'application/json' } }
  );
});
```

### Option 2: Using CRM v3 Notes API (Alternative)

```typescript
// In your Supabase Edge Function (hubspot/index.ts)

Deno.serve(async (req) => {
  const { action, data } = await req.json();
  
  if (action === 'createNote') {
    // Extract data - NOTE: We're sending 'note', not 'noteBody' or 'hs_note_body'
    const { contactId, note, timestamp, createTodo } = data;
    
    // Validate required fields
    if (!contactId) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: contactId' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    if (!note || !note.trim()) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: note (note text is empty)' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    if (!timestamp) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: timestamp' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Format payload for HubSpot CRM v3 Notes API
    const hubspotPayload = {
      properties: {
        hs_note_body: note.trim(),        // REQUIRED - use 'note' from data, map to 'hs_note_body'
        hs_timestamp: timestamp           // REQUIRED - use timestamp from data
      },
      associations: [
        {
          to: {
            id: String(contactId)         // Can be string or number
          },
          types: [
            {
              associationCategory: "HUBSPOT_DEFINED",
              associationTypeId: 202       // Standard note-to-contact association
            }
          ]
        }
      ]
    };
    
    console.log('Creating note with payload:', JSON.stringify(hubspotPayload, null, 2));
    
    // Get HubSpot access token from environment
    const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
    
    if (!hubspotToken) {
      return new Response(
        JSON.stringify({ error: 'HubSpot access token not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    try {
      // Call HubSpot CRM v3 Notes API
      const response = await fetch('https://api.hubapi.com/crm/v3/objects/notes', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${hubspotToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(hubspotPayload)
      });
      
      const responseText = await response.text();
      console.log('HubSpot response status:', response.status);
      console.log('HubSpot response:', responseText);
      
      if (!response.ok) {
        console.error('HubSpot API Error:', responseText);
        return new Response(
          JSON.stringify({ error: `HubSpot API error: ${responseText}` }),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      const result = JSON.parse(responseText);
      return new Response(
        JSON.stringify({ success: true, data: result }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
      
    } catch (error) {
      console.error('Error calling HubSpot API:', error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
  }
  
  return new Response(
    JSON.stringify({ error: 'Unknown action' }),
    { status: 400, headers: { 'Content-Type': 'application/json' } }
  );
});
```

### Option 2: Using Engagements API (Legacy)

```typescript
// Alternative: Using Engagements API (if CRM v3 doesn't work)

if (action === 'createNote') {
  const { contactId, note, timestamp, createTodo } = data;
  
  // Validate required fields
  if (!contactId || !note || !timestamp) {
    return new Response(
      JSON.stringify({ error: 'Missing required fields: contactId, note, or timestamp' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }
  
  // Format payload for HubSpot Engagements API
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
      body: note.trim()
    }
  };
  
  // ... rest of the code similar to above, but use:
  // POST https://api.hubapi.com/engagements/v1/engagements
}
```

## Common Mistakes to Avoid:

### For CRM v3 Notes API:
1. ❌ Using `note` or `body` instead of `hs_note_body` in properties
2. ❌ Using `timestamp` instead of `hs_timestamp` in properties
3. ❌ Missing `associations` array or wrong structure
4. ❌ Wrong `associationTypeId` (must be `202` for note-to-contact)
5. ❌ Missing `associationCategory: "HUBSPOT_DEFINED"`
6. ❌ Wrong endpoint (must be `/crm/v3/objects/notes`, not `/engagements/v1/engagements`)

### For Engagements API:
1. ❌ Missing `engagement.active: true`
2. ❌ Wrong `engagement.type` (must be exact string `"NOTE"`, not `"note"` or `"Note"`)
3. ❌ `associations.contactIds` not an array (must be `[contactId]`, not just `contactId`)
4. ❌ Missing `metadata.body` (must use the `note` field from our data)
5. ❌ Wrong timestamp format (must be milliseconds, not seconds)

### General:
6. ❌ Missing Authorization header
7. ❌ Wrong endpoint URL
8. ❌ Edge function expecting different field names (e.g., `noteBody` instead of `note`)

## Required Properties Checklist:

### For CRM v3 Notes API (RECOMMENDED):
- ✅ `properties.hs_note_body` = string (note text from `data.note`)
- ✅ `properties.hs_timestamp` = number (milliseconds from `data.timestamp`)
- ✅ `associations[0].to.id` = string or number (contact ID from `data.contactId`)
- ✅ `associations[0].types[0].associationCategory` = `"HUBSPOT_DEFINED"`
- ✅ `associations[0].types[0].associationTypeId` = `202`

### For Engagements API (Legacy):
- ✅ `engagement.active` = `true`
- ✅ `engagement.type` = `"NOTE"` (exact string, case-sensitive)
- ✅ `engagement.timestamp` = number (milliseconds)
- ✅ `associations.contactIds` = array of numbers `[contactId]`
- ✅ `metadata.body` = string (note text)

## Field Name Mapping (Client → Edge Function → HubSpot):

| Client Sends | Edge Function Receives | HubSpot Expects (CRM v3) |
|--------------|------------------------|--------------------------|
| `contactId: 646496038119` | `data.contactId` | `associations[0].to.id: "646496038119"` |
| `note: "text"` | `data.note` | `properties.hs_note_body: "text"` |
| `timestamp: 1768731778429` | `data.timestamp` | `properties.hs_timestamp: 1768731778429` |
| `createTodo: true` | `data.createTodo` | (Optional - not used in HubSpot API) |
