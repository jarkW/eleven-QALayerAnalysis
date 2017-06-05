static boolean okFlag;
static String errMsg;

static class Utils
{
    // My version for reading/setting values in JSON file - so all error checking done here    
    static public String readJSONString(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONString";
            return "";
        }
        
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        String readString = "";
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing key " + key + " in json file";
                }
                okFlag = false;
                return "";
            }
            readString = jsonFile.getString(key, "");
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read string from json file with key " + key;
            }
            okFlag = false;
            return "";
        }
        if (readString.length() == 0)
        {
            // Leave error reporting up to calling function
            return "";
        }
        return readString;
    }

    
    static public int readJSONInt(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONInt";
            return 0;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        int readInt;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing key " + key + " in json file";
                }
                okFlag = false;
                return 0;
            }
            readInt = jsonFile.getInt(key, 0);
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read int from json file with key " + key;
            }
            okFlag = false;
            return 0;
        }

        return readInt;
    }
    
    static public boolean readJSONBool(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONBool";
            return false;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        boolean readBool;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing key " + key + " in json file";
                }
                okFlag = false;
                return false;
            }
            readBool = jsonFile.getBoolean(key, false);
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read boolean from json file with key " + key;
            }
            okFlag = false;
            return false;
        }

        return readBool;
    }
    
    static public JSONObject readJSONObject(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONObject";
            return null;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONObject readObj;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing JSON object key " + key + " in json file";
                }
                okFlag = false;
                return null;
            }
            readObj = jsonFile.getJSONObject(key); 
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON object from json file with key " + key;
            }
            okFlag = false;
            return null;
        }

        return readObj;
    }
    
    static public JSONObject readJSONObjectFromJSONArray(JSONArray jsonArray, int index, boolean reportError)
    {
        okFlag = true;
        
        if (index < 0 || index >= jsonArray.size())
        {
            okFlag = false;
            errMsg = "Index " + index + " passed to read JSONArray is out of bounds - less than 0 or greater than " + str(jsonArray.size()-1);
            return null;
        }

        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONObject readObj;
        try
        {
            readObj = jsonArray.getJSONObject(index); 
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON object from json array with index " + index;
            }
            okFlag = false;
            return null;
        }

        return readObj;
    }
   
    static public JSONArray readJSONArray(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONArray";
            return null;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONArray readArray;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing JSON array key " + key + " in json file";
                }
                okFlag = false;
                return null;
            }
            readArray = jsonFile.getJSONArray(key);
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON array from json file with key " + key;
            }
            okFlag = false;
            return null;
        }

        return readArray;
    }
    
    static public JSONArray readJSONArrayFromJSONArray(JSONArray jsonArray, int index, boolean reportError)
    {
        okFlag = true;
        
        if (index < 0 || index >= jsonArray.size())
        {
            okFlag = false;
            errMsg = "Index " + index + " passed to read JSONArray is out of bounds - less than 0 or greater than " + str(jsonArray.size()-1);
            return null;
        }

        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONArray readArray;
        try
        {
            readArray = jsonArray.getJSONArray(index); 
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON array from json array with index " + index;
            }
            okFlag = false;
            return null;
        }

        return readArray;
    }
    
    static public int readIntFromJSONArray(JSONArray jsonArray, int index, boolean reportError)
    {
        okFlag = true;
        
        if (index < 0 || index >= jsonArray.size())
        {
            okFlag = false;
            errMsg = "Index " + index + " passed to read JSONArray is out of bounds - less than 0 or greater than " + str(jsonArray.size()-1);
            return 0;
        }

        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        int readInt;
        try
        {
            readInt = jsonArray.getInt(index); 
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read int from json array with index " + index;
            }
            okFlag = false;
            return 0;
        }

        return readInt;
    }
                  
    static public boolean readOkFlag()
    {
        return okFlag;
    }
        
    static public String readErrMsg()
    {
        return errMsg;
    }
    
}