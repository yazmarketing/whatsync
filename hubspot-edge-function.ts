// Supabase Edge Function: hubspot
// Handles HubSpot API operations: createContact, createNote, getContacts, etc.

Deno.serve(async (req) => {
  try {
    const { action, data } = await req.json();
    
    console.log('Received request:', { action, data: data ? 'present' : 'missing' });
    
    // Get HubSpot token from environment
    const hubspotToken = Deno.env.get('HUBSPOT_ACCESS_TOKEN');
    
    if (!hubspotToken) {
      return new Response(
        JSON.stringify({ error: 'HubSpot access token not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Handle createContact action
    if (action === 'createContact') {
      console.log('Creating HubSpot contact:', JSON.stringify(data, null, 2));
      
      try {
        const response = await fetch('https://api.hubapi.com/crm/v3/objects/contacts', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${hubspotToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            properties: data.properties || data
          })
        });
        
        const responseText = await response.text();
        
        if (!response.ok) {
          console.error('HubSpot API Error:', responseText);
          return new Response(
            JSON.stringify({ error: `HubSpot API error: ${responseText}` }),
            { status: response.status, headers: { 'Content-Type': 'application/json' } }
          );
        }
        
        const result = JSON.parse(responseText);
        return new Response(
          JSON.stringify(result),
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
    
    // Handle createNote action
    if (action === 'createNote') {
      // Log received data for debugging
      console.log("Received createNote request:", JSON.stringify(data, null, 2));
      
      // Extract fields with fallback - handles multiple field name options
      const { contactId, note, noteBody, body, timestamp } = data || {};
      const noteText = (note ?? noteBody ?? body)?.toString().trim();
      
      // Log extracted values
      console.log("Extracted values:", {
        contactId,
        note,
        noteBody,
        body,
        noteText,
        timestamp
      });
      
      // Validate required fields
      if (!contactId) {
        console.error("❌ Missing contactId");
        return new Response(
          JSON.stringify({ error: 'Missing required field: contactId' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!timestamp) {
        console.error("❌ Missing timestamp");
        return new Response(
          JSON.stringify({ error: 'Missing required field: timestamp' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!noteText) {
        console.error("❌ Missing note text. Checked:", { note, noteBody, body });
        return new Response(
          JSON.stringify({ error: 'Missing required field: note text (note, noteBody, or body)' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      console.log("✅ All validations passed");
      
      // Build HubSpot Engagements API payload
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
      
      console.log("HubSpot payload:", JSON.stringify(hubspotPayload, null, 2));
      
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
    
    // Handle getContacts action (for contact search)
    if (action === 'getContacts') {
      const { limit = 100, properties = [], associations = [] } = data || {};
      
      let url = `https://api.hubapi.com/crm/v3/objects/contacts?limit=${limit}`;
      if (properties.length > 0) {
        url += `&properties=${properties.join(',')}`;
      }
      if (associations.length > 0) {
        url += `&associations=${associations.join(',')}`;
      }
      
      try {
        const response = await fetch(url, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${hubspotToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        const result = await response.json();
        return new Response(
          JSON.stringify(result),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } catch (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
    }
    
    // Handle getContact action (single contact)
    if (action === 'getContact') {
      const { contactId, properties = [] } = data || {};
      
      if (!contactId) {
        return new Response(
          JSON.stringify({ error: 'Missing required field: contactId' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      let url = `https://api.hubapi.com/crm/v3/objects/contacts/${contactId}`;
      if (properties.length > 0) {
        url += `?properties=${properties.join(',')}`;
      }
      
      try {
        const response = await fetch(url, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${hubspotToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        const result = await response.json();
        return new Response(
          JSON.stringify(result),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } catch (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
    }
    
    // Handle getCompany action
    if (action === 'getCompany') {
      const { companyId } = data || {};
      
      if (!companyId) {
        return new Response(
          JSON.stringify({ error: 'Missing required field: companyId' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      try {
        const response = await fetch(`https://api.hubapi.com/crm/v3/objects/companies/${companyId}`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${hubspotToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        const result = await response.json();
        return new Response(
          JSON.stringify(result),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } catch (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
    }
    
    // Unknown action
    return new Response(
      JSON.stringify({ error: `Unknown action: ${action}` }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Edge function error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
