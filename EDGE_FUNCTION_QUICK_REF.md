# Edge Function Quick Reference

## 🔗 Access Links

**Dashboard:** https://supabase.com/dashboard  
**Project ID:** `dizxmubrpwwfrjepcttb`  
**Function URL:** `https://dizxmubrpwwfrjepcttb.supabase.co/functions/v1/hubspot`  
**Function Name:** `hubspot`

## 🚀 Quick Access

### View Function Code
1. Supabase Dashboard → Edge Functions → `hubspot` → Code tab

### View Logs
1. Supabase Dashboard → Edge Functions → `hubspot` → Logs tab

### Test Function
```bash
./test-edge-function.sh
```

## 📋 What Extension Sends

```json
{
  "action": "createNote",
  "data": {
    "contactId": 646496038119,     // Number (required)
    "body": "Note text",            // String (PRIMARY)
    "note": "Note text",            // String (ALTERNATIVE)
    "noteBody": "Note text",       // String (ALTERNATIVE)
    "timestamp": 1768736618679,     // Number (required, ms)
    "createTodo": false             // Boolean (optional)
  }
}
```

## ✅ Edge Function Must

1. **Extract:** `const noteText = (note ?? noteBody ?? body)?.toString().trim()`
2. **Validate:** `if (!contactId || !timestamp || !noteText)`
3. **Build HubSpot payload internally** (don't expect it from extension)
4. **Use Engagements API:** `POST /engagements/v1/engagements`

## 🔍 Debugging

- **Extension logs:** Browser DevTools → Console → `[Background]` logs
- **Edge function logs:** Supabase Dashboard → Edge Functions → Logs
- **Test script:** `./test-edge-function.sh`

## 📚 Full Guides

- **Access Guide:** `EDGE_FUNCTION_ACCESS_GUIDE.md`
- **Debug Guide:** `NOTE_SAVING_DEBUG.md`
- **Template:** `EDGE_FUNCTION_TEMPLATE.md`
