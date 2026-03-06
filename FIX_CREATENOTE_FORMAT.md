# Fix createNote Format Mismatch

## Problem

**Extension sends (Engagements API format):**
```javascript
{
  action: 'createNote',
  data: {
    contactId: 650186289345,
    body: "Note text",
    note: "Note text",
    noteBody: "Note text",
    timestamp: 1768744246658,  // milliseconds
    createTodo: false
  }
}
```

**Existing Edge Function expects (CRM v3 Notes API format):**
```javascript
{
  action: 'createNote',
  data: {
    properties: {
      hs_note_body: 'This is the note content',
      hs_timestamp: new Date().toISOString()  // ISO string
    },
    associations: [
      {
        to: { id: 'CONTACT_ID_HERE' },
        types: [{ associationCategory: 'HUBSPOT_DEFINED', associationTypeId: 202 }]
      }
    ]
  }
}
```

**These formats don't match!** 

## Solution

Update the edge function's `createNote` handler to accept BOTH formats and convert appropriately.

## Updated Edge Function Handler

Replace the existing `createNote` handler in your edge function with this code that handles both formats:

```typescript
// Handle createNote action - supports both formats
if (action === 'createNote') {
  console.log("Received createNote request:", JSON.stringify(data, null, 2));
  
  let hubspotPayload;
  let contactId;
  
  // Check which format we received
  if (data.properties && data.associations) {
    // Format 1: CRM v3 Notes API format (existing format)
    console.log("Using CRM v3 Notes API format");
    hubspotPayload = {
      properties: {
        hs_note_body: data.properties.hs_note_body || '',
        hs_timestamp: data.properties.hs_timestamp || new Date().toISOString()
      },
      associations: data.associations
    };
    
    // Extract contact ID from associations
    if (data.associations && data.associations.length > 0) {
      contactId = data.associations[0].to?.id;
    }
  } else {
    // Format 2: Extension format (Engagements API format)
    console.log("Using Engagements API format (extension format)");
    
    // Extract fields with fallback
    const { contactId: cId, note, noteBody, body, timestamp } = data || {};
    const noteText = (note ?? noteBody ?? body)?.toString().trim();
    contactId = cId;
    
    // Validate required fields
    if (!contactId) {
      console.error("❌ Missing contactId");
      return new Response(
        JSON.stringify({ error: 'Missing required field: contactId' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    if (!noteText) {
      console.error("❌ Missing note text");
      return new Response(
        JSON.stringify({ error: 'Missing required field: note text' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Use provided timestamp or generate one
    const noteTimestamp = timestamp || Date.now();
    
    // Build HubSpot Engagements API payload
    hubspotPayload = {
      engagement: {
        active: true,
        type: "NOTE",
        timestamp: noteTimestamp
      },
      associations: {
        contactIds: [contactId]
      },
      metadata: {
        body: noteText
      }
    };
  }
  
  console.log("HubSpot payload:", JSON.stringify(hubspotPayload, null, 2));
  
  // Get HubSpot token
  const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
  if (!hubspotToken) {
    return new Response(
      JSON.stringify({ error: 'HubSpot access token not configured' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
  
  // Determine which API endpoint to use
  let apiEndpoint;
  if (data.properties && data.associations) {
    // Use CRM v3 Notes API
    apiEndpoint = 'https://api.hubapi.com/crm/v3/objects/notes';
  } else {
    // Use Engagements API
    apiEndpoint = 'https://api.hubapi.com/engagements/v1/engagements';
  }
  
  try {
    const response = await fetch(apiEndpoint, {
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
    console.log("✅ Note created successfully");
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
```

## What This Does

1. ✅ Checks which format was sent
2. ✅ If `properties` and `associations` exist → Uses CRM v3 Notes API
3. ✅ If `contactId` and `body`/`note` exist → Uses Engagements API (extension format)
4. ✅ Converts extension format to proper HubSpot API payload
5. ✅ Calls appropriate HubSpot API endpoint
6. ✅ Returns success/error response

## Testing

After updating, test both formats:

**Test 1: Extension format (your extension uses this)**
```bash
curl -X POST https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot \
  -H "Content-Type: application/json" \
  -d '{
    "action": "createNote",
    "data": {
      "contactId": 650186289345,
      "body": "Test note from extension",
      "timestamp": '$(date +%s000)'
    }
  }'
```

**Test 2: Existing format (for backward compatibility)**
```bash
curl -X POST https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot \
  -H "Content-Type: application/json" \
  -d '{
    "action": "createNote",
    "data": {
      "properties": {
        "hs_note_body": "Test note from CRM v3 format",
        "hs_timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
      },
      "associations": [{
        "to": { "id": "650186289345" },
        "types": [{"associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 202}]
      }]
    }
  }'
```

Both should work! ✅
